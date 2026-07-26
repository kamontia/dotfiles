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
fake_osascript="${0:A:h}/fakes/executable_osascript"
notifier_script=${CHEZMOI_FETCH_NOTIFY_SCRIPT:?CHEZMOI_FETCH_NOTIFY_SCRIPTが未設定です}

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

function test_期限切れロックを回収する() {
  arrange_synced_repository
  advance_remote
  arrange_lock_started_at "$((fake_now - 3601))"

  run_notifier

  assert_file_line_count "$notification_log" 1
  [[ ! -d "$cache_dir/run.lock" ]]
}

function test_通知失敗時は状態を更新しない() {
  arrange_synced_repository
  advance_remote
  export FAKE_OSASCRIPT_FAIL=1

  assert_command_fails run_notifier

  [[ ! -e "$cache_dir/last-notified-commit" ]]
}

test_リモートが先行していなければ通知しない
test_リモートが先行していれば一度通知する
test_同じupstreamコミットでは再通知しない
test_upstreamが進めば再通知する
test_fetch失敗時は通知しない
test_upstream未設定では通知しない
test_実行中ロックがあればスキップする
test_期限切れロックを回収する
test_通知失敗時は状態を更新しない

print -- "chezmoi-fetch-notify tests: PASS"
