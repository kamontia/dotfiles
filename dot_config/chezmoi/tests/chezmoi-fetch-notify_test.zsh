#!/usr/bin/env zsh

set -eu

test_tmp=$(mktemp -d -t chezmoi-fetch-notify-test.XXXXXX)
trap 'command rm -r -- "$test_tmp"' EXIT

fake_now=1700000000
fixture_number=0
remote_repo=""
writer_repo=""
local_repo=""
cache_dir=""
notification_log=""
fake_chezmoi=""
fake_osascript=${CHEZMOI_FETCH_NOTIFY_TEST_OSASCRIPT_BIN:-"${0:A:h}/fakes/osascript"}
notifier_script=${CHEZMOI_FETCH_NOTIFY_SCRIPT:?CHEZMOI_FETCH_NOTIFY_SCRIPTが未設定です}
blocking_notifier_pid=""

function arrange_test_paths() {
  fixture_number=$((fixture_number + 1))
  local fixture_dir="$test_tmp/fixture-$fixture_number"
  remote_repo="$fixture_dir/remote.git"
  writer_repo="$fixture_dir/writer"
  local_repo="$fixture_dir/local"
  cache_dir="$fixture_dir/cache"
  notification_log="$fixture_dir/notifications.log"
  fake_chezmoi="$fixture_dir/fake-chezmoi"
  mkdir -p "$fixture_dir"
}

function create_fake_chezmoi() {
  print -r -- '#!/usr/bin/env zsh' > "$fake_chezmoi"
  print -r -- 'print -r -- "$FAKE_CHEZMOI_SOURCE_PATH"' >> "$fake_chezmoi"
  chmod +x "$fake_chezmoi"
}

function arrange_synced_repository() {
  arrange_test_paths
  git init --bare -q "$remote_repo"
  git clone -q "$remote_repo" "$writer_repo" 2>/dev/null
  git -C "$writer_repo" checkout -q -b main
  git -C "$writer_repo" config user.name "Chezmoi Test"
  git -C "$writer_repo" config user.email "chezmoi-test@example.invalid"
  print -r -- 'initial' > "$writer_repo/dotfile"
  git -C "$writer_repo" add dotfile
  git -C "$writer_repo" commit -q -m 'initial'
  git -C "$writer_repo" push -q -u origin main
  git -C "$remote_repo" symbolic-ref HEAD refs/heads/main
  git clone -q "$remote_repo" "$local_repo"
  git -C "$local_repo" branch --set-upstream-to=origin/main main >/dev/null
  create_fake_chezmoi
  : > "$notification_log"
  export FAKE_CHEZMOI_SOURCE_PATH="$local_repo"
  export FAKE_NOTIFICATION_LOG="$notification_log"
  unset FAKE_OSASCRIPT_FAIL
}

function arrange_repository_without_upstream() {
  arrange_test_paths
  git init -q "$local_repo"
  git -C "$local_repo" config user.name "Chezmoi Test"
  git -C "$local_repo" config user.email "chezmoi-test@example.invalid"
  print -r -- 'initial' > "$local_repo/dotfile"
  git -C "$local_repo" add dotfile
  git -C "$local_repo" commit -q -m 'initial'
  create_fake_chezmoi
  : > "$notification_log"
  export FAKE_CHEZMOI_SOURCE_PATH="$local_repo"
  export FAKE_NOTIFICATION_LOG="$notification_log"
  unset FAKE_OSASCRIPT_FAIL
}

function advance_remote() {
  print -r -- "advance $fixture_number $(git -C "$writer_repo" rev-list --count HEAD)" >> "$writer_repo/dotfile"
  git -C "$writer_repo" add dotfile
  git -C "$writer_repo" commit -q -m 'advance remote'
  git -C "$writer_repo" push -q origin main
}

function arrange_lock_started_at() {
  local started_at=$1

  mkdir -p "$cache_dir/run.lock"
  print -r -- 99999 > "$cache_dir/run.lock/pid"
  print -r -- "$started_at" > "$cache_dir/run.lock/started_at"
}

function arrange_lock_without_started_at() {
  mkdir -p "$cache_dir/run.lock"
  print -r -- 99999 > "$cache_dir/run.lock/pid"
}

function arrange_unreadable_lock_started_at() {
  arrange_lock_started_at "$1"
  chmod 000 "$cache_dir/run.lock/started_at"
}

function arrange_signal_chezmoi() {
  local signal=$1

  print -r -- '#!/usr/bin/env zsh' > "$fake_chezmoi"
  print -r -- 'print -r -- "$FAKE_CHEZMOI_SOURCE_PATH"' >> "$fake_chezmoi"
  print -r -- "kill -$signal \"\$PPID\"" >> "$fake_chezmoi"
  chmod +x "$fake_chezmoi"
}

function arrange_blocking_chezmoi() {
  mkdir -p "$cache_dir"
  print -r -- '#!/usr/bin/env zsh' > "$fake_chezmoi"
  print -r -- 'print -r -- "$FAKE_CHEZMOI_SOURCE_PATH"' >> "$fake_chezmoi"
  print -r -- ': > "$FAKE_CHEZMOI_READY"' >> "$fake_chezmoi"
  print -r -- 'while [[ ! -e "$FAKE_CHEZMOI_CONTINUE" ]]; do sleep 0.01; done' >> "$fake_chezmoi"
  chmod +x "$fake_chezmoi"
}

function wait_for_file() {
  local file=$1
  local attempt

  for attempt in {1..500}; do
    [[ -e "$file" ]] && return 0
    sleep 0.01
  done

  print -u2 -- "待機対象のファイルが作成されませんでした: $file"
  return 1
}

function start_blocking_notifier() {
  local now_epoch=$1
  local ready_file=$2
  local continue_file=$3
  local stdout_file=$4
  local stderr_file=$5

  CHEZMOI_FETCH_NOTIFY_CHEZMOI_BIN="$fake_chezmoi" \
    CHEZMOI_FETCH_NOTIFY_OSASCRIPT_BIN="$fake_osascript" \
    CHEZMOI_FETCH_NOTIFY_CACHE_DIR="$cache_dir" \
    CHEZMOI_FETCH_NOTIFY_NOW_EPOCH="$now_epoch" \
    FAKE_CHEZMOI_READY="$ready_file" \
    FAKE_CHEZMOI_CONTINUE="$continue_file" \
    "$notifier_script" > "$stdout_file" 2> "$stderr_file" &
  blocking_notifier_pid=$!
}

function assert_file_line_count() {
  local file=$1
  local expected=$2

  [[ $(wc -l < "$file") -eq $expected ]]
}

function assert_state_matches_upstream() {
  local state_commit
  local upstream_commit

  read -r state_commit < "$cache_dir/last-notified-commit"
  upstream_commit=$(git -C "$local_repo" rev-parse origin/main)
  [[ $state_commit == "$upstream_commit" ]]
}

function assert_command_fails() {
  if "$@" > "$test_tmp/command.stdout" 2> "$test_tmp/command.stderr"; then
    print -u2 -- "失敗するべきコマンドが成功しました: $*"
    return 1
  fi
}

function assert_command_error_is() {
  local expected=$1
  local actual

  actual=$(< "$test_tmp/command.stderr")
  [[ $actual == "$expected" ]]
}

function assert_command_exits_with() {
  local expected=$1
  shift
  local actual

  if "$@" > "$test_tmp/command.stdout" 2> "$test_tmp/command.stderr"; then
    actual=0
  else
    actual=$?
  fi

  [[ $actual -eq $expected ]]
}

function assert_file_is() {
  local file=$1
  local expected=$2
  local actual

  actual=$(< "$file")
  [[ $actual == "$expected" ]]
}

function assert_value_is() {
  local actual=$1
  local expected=$2
  local description=$3

  if [[ $actual != "$expected" ]]; then
    print -u2 -- "$description: expected=$expected actual=$actual"
    return 1
  fi
}

function run_notifier() {
  CHEZMOI_FETCH_NOTIFY_CHEZMOI_BIN="$fake_chezmoi" \
    CHEZMOI_FETCH_NOTIFY_OSASCRIPT_BIN="$fake_osascript" \
    CHEZMOI_FETCH_NOTIFY_CACHE_DIR="$cache_dir" \
    CHEZMOI_FETCH_NOTIFY_NOW_EPOCH="$fake_now" \
    "$notifier_script"
}

function test_リモートが先行していなければ通知しない() {
  arrange_synced_repository

  run_notifier

  [[ ! -s "$notification_log" ]]
}

function test_リモートが先行していれば一度通知する() {
  arrange_synced_repository
  advance_remote

  run_notifier

  assert_file_line_count "$notification_log" 1
  assert_state_matches_upstream
}

function test_同じupstreamコミットでは再通知しない() {
  arrange_synced_repository
  advance_remote

  run_notifier
  run_notifier

  assert_file_line_count "$notification_log" 1
}

function test_upstreamが進めば再通知する() {
  arrange_synced_repository
  advance_remote

  run_notifier
  advance_remote
  run_notifier

  assert_file_line_count "$notification_log" 2
  assert_state_matches_upstream
}

function test_fetch失敗時は通知しない() {
  arrange_synced_repository
  git -C "$local_repo" remote set-url origin "$test_tmp/missing.git"

  assert_command_fails run_notifier

  assert_command_error_is "chezmoi-fetch-notify: Git fetchに失敗しました"
  [[ ! -s "$notification_log" ]]
  [[ ! -e "$cache_dir/last-notified-commit" ]]
}

function test_upstream未設定では通知しない() {
  arrange_repository_without_upstream

  assert_command_fails run_notifier

  [[ ! -s "$notification_log" ]]
}

function test_実行中ロックがあればスキップする() {
  arrange_synced_repository
  advance_remote
  arrange_lock_started_at "$fake_now"

  run_notifier

  [[ ! -s "$notification_log" ]]
}

function test_3600秒経過ロックはスキップする() {
  arrange_synced_repository
  advance_remote
  arrange_lock_started_at "$((fake_now - 3600))"

  run_notifier

  [[ ! -s "$notification_log" ]]
  [[ -d "$cache_dir/run.lock" ]]
}

function test_started_at不在ロックはスキップする() {
  arrange_synced_repository
  advance_remote
  arrange_lock_without_started_at

  run_notifier

  [[ ! -s "$notification_log" ]]
  [[ -d "$cache_dir/run.lock" ]]
}

function test_started_atが読取不能のロックはスキップする() {
  arrange_synced_repository
  advance_remote
  arrange_unreadable_lock_started_at "$((fake_now - 3601))"

  run_notifier

  [[ ! -s "$notification_log" ]]
  [[ -d "$cache_dir/run.lock" ]]
}

function test_started_atが非数値のロックはスキップする() {
  arrange_synced_repository
  advance_remote
  arrange_lock_started_at "not-an-epoch"

  run_notifier

  [[ ! -s "$notification_log" ]]
  [[ -d "$cache_dir/run.lock" ]]
}

function test_started_atが未来のロックはスキップする() {
  arrange_synced_repository
  advance_remote
  arrange_lock_started_at "$((fake_now + 1))"

  run_notifier

  [[ ! -s "$notification_log" ]]
  [[ -d "$cache_dir/run.lock" ]]
}

function test_started_atが過大桁数のロックはスキップする() {
  arrange_synced_repository
  advance_remote
  arrange_lock_started_at "999999999999999999999999999999999999999999"

  run_notifier

  [[ ! -s "$notification_log" ]]
  [[ -d "$cache_dir/run.lock" ]]
}

function test_期限切れロックを回収する() {
  arrange_synced_repository
  advance_remote
  arrange_lock_started_at "$((fake_now - 3601))"

  run_notifier

  assert_file_line_count "$notification_log" 1
  [[ ! -d "$cache_dir/run.lock" ]]
}

function test_旧所有者の終了は置換後のロックを削除しない() {
  arrange_synced_repository
  arrange_blocking_chezmoi
  local old_ready="$cache_dir/old.ready"
  local old_continue="$cache_dir/old.continue"
  local new_ready="$cache_dir/new.ready"
  local new_continue="$cache_dir/new.continue"
  local old_pid
  local new_pid
  local actual_owner

  start_blocking_notifier "$((fake_now - 3601))" \
    "$old_ready" "$old_continue" "$cache_dir/old.stdout" "$cache_dir/old.stderr"
  old_pid=$blocking_notifier_pid
  wait_for_file "$old_ready"
  start_blocking_notifier "$fake_now" \
    "$new_ready" "$new_continue" "$cache_dir/new.stdout" "$cache_dir/new.stderr"
  new_pid=$blocking_notifier_pid
  wait_for_file "$new_ready"
  : > "$old_continue"
  wait "$old_pid"
  actual_owner=$(cat "$cache_dir/run.lock/pid" 2>/dev/null || print -r -- "missing")
  : > "$new_continue"
  wait "$new_pid"

  assert_value_is "$actual_owner" "$new_pid" "置換後のロック所有PID"
}

function test_通知失敗時は状態を更新しない() {
  arrange_synced_repository
  advance_remote
  mkdir -p "$cache_dir"
  print -r -- "previous-notified-commit" > "$cache_dir/last-notified-commit"
  export FAKE_OSASCRIPT_FAIL=1

  assert_command_fails run_notifier

  assert_file_is "$cache_dir/last-notified-commit" "previous-notified-commit"
}

function test_通知に正しい引数を渡す() {
  arrange_synced_repository
  advance_remote

  run_notifier

  assert_file_is "$notification_log" "- local 1"
}

function test_TERM受信時は後続処理を実行しない() {
  arrange_synced_repository
  advance_remote
  arrange_signal_chezmoi TERM

  assert_command_exits_with 143 run_notifier

  [[ ! -s "$notification_log" ]]
  [[ ! -e "$cache_dir/last-notified-commit" ]]
  [[ ! -d "$cache_dir/run.lock" ]]
}

function test_HUP受信時は後続処理を実行しない() {
  arrange_synced_repository
  advance_remote
  arrange_signal_chezmoi HUP

  assert_command_exits_with 129 run_notifier

  [[ ! -s "$notification_log" ]]
  [[ ! -e "$cache_dir/last-notified-commit" ]]
  [[ ! -d "$cache_dir/run.lock" ]]
}

function test_INT受信時は後続処理を実行しない() {
  arrange_synced_repository
  advance_remote
  arrange_signal_chezmoi INT

  assert_command_exits_with 130 run_notifier

  [[ ! -s "$notification_log" ]]
  [[ ! -e "$cache_dir/last-notified-commit" ]]
  [[ ! -d "$cache_dir/run.lock" ]]
}

test_リモートが先行していなければ通知しない
test_リモートが先行していれば一度通知する
test_同じupstreamコミットでは再通知しない
test_upstreamが進めば再通知する
test_fetch失敗時は通知しない
test_upstream未設定では通知しない
test_実行中ロックがあればスキップする
test_3600秒経過ロックはスキップする
test_started_at不在ロックはスキップする
test_started_atが読取不能のロックはスキップする
test_started_atが非数値のロックはスキップする
test_started_atが未来のロックはスキップする
test_started_atが過大桁数のロックはスキップする
test_期限切れロックを回収する
test_旧所有者の終了は置換後のロックを削除しない
test_通知失敗時は状態を更新しない
test_通知に正しい引数を渡す
test_TERM受信時は後続処理を実行しない
test_HUP受信時は後続処理を実行しない
test_INT受信時は後続処理を実行しない

print -- "chezmoi-fetch-notify tests: PASS"
