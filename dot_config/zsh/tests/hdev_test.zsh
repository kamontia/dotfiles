#!/usr/bin/env zsh

set -eu

test_tmp=$(mktemp -d -t hdev-test.XXXXXX)
trap 'command rm -r -- "$test_tmp"' EXIT

fake_log="$test_tmp/herdr.log"
fake_server_state="$test_tmp/herdr-server-running"
repo_dir="$test_tmp/sample-project"
mkdir -p "$repo_dir"
git -C "$repo_dir" init -q
repo_dir=$(cd "$repo_dir" && pwd -P)

function herdr() {
  local action="${(j: :)@}"
  [[ -n "$action" ]] || action="<attach>"
  print -r -- "$action" >> "$fake_log"

  case "${(j: :)@}" in
    "status server")
      if [[ ${FAKE_SERVER_STOPPED:-0} == 1 && ! -e "$fake_server_state" ]]; then
        print -- "status: not running"
        return 0
      fi
      print -- "status: running"
      return 0
      ;;
    "server")
      : > "$fake_server_state"
      return 0
      ;;
    "workspace list")
      if [[ ${FAKE_EXISTING_WORKSPACE:-0} == 1 ]]; then
        print -r -- '{"result":{"workspaces":[{"workspace_id":"w1"}]}}'
      else
        print -r -- '{"result":{"workspaces":[]}}'
      fi
      ;;
    "pane list --workspace w1")
      if [[ ${FAKE_CURRENT_TAB:-0} == 1 ]]; then
        print -r -- "{\"result\":{\"panes\":[{\"pane_id\":\"w1:p9\",\"tab_id\":\"w1:t9\",\"cwd\":\"$repo_dir\"}]}}"
      elif [[ ${FAKE_CURRENT_TAB_CROWDED:-0} == 1 ]]; then
        print -r -- "{\"result\":{\"panes\":[{\"pane_id\":\"w1:p9\",\"tab_id\":\"w1:t9\",\"cwd\":\"$repo_dir\"},{\"pane_id\":\"w1:p10\",\"tab_id\":\"w1:t9\",\"cwd\":\"$repo_dir\"}]}}"
      else
        print -r -- "{\"result\":{\"panes\":[{\"pane_id\":\"w1:p1\",\"tab_id\":\"w1:t1\",\"cwd\":\"$repo_dir\"}]}}"
      fi
      ;;
    workspace\ create*)
      print -r -- '{"result":{"workspace":{"workspace_id":"w1"},"root_pane":{"pane_id":"w1:p1"}}}'
      ;;
    tab\ create*)
      print -r -- '{"result":{"tab":{"tab_id":"w1:t2"},"root_pane":{"pane_id":"w1:p10"}}}'
      ;;
    "pane split w1:p1 --direction down --ratio 0.7")
      print -r -- '{"result":{"pane":{"pane_id":"w1:p2"}}}'
      ;;
    "pane split w1:p1 --direction right --ratio 0.5")
      print -r -- '{"result":{"pane":{"pane_id":"w1:p3"}}}'
      ;;
    "pane split w1:p10 --direction down --ratio 0.7")
      print -r -- '{"result":{"pane":{"pane_id":"w1:p11"}}}'
      ;;
    "pane split w1:p10 --direction right --ratio 0.5")
      print -r -- '{"result":{"pane":{"pane_id":"w1:p12"}}}'
      ;;
    "pane split w1:p9 --direction down --ratio 0.7")
      print -r -- '{"result":{"pane":{"pane_id":"w1:p10"}}}'
      ;;
    "pane split w1:p9 --direction right --ratio 0.5")
      print -r -- '{"result":{"pane":{"pane_id":"w1:p11"}}}'
      ;;
    "")
      if [[ ${HERDR_ENV:-0} == 1 ]]; then
        print -u2 -- "error: nested herdr is disabled by default."
        return 1
      fi
      return 0
      ;;
    *)
      print -r -- '{"result":{}}'
      ;;
  esac
}

function reset_fake() {
  : > "$fake_log"
  command rm -f -- "$fake_server_state"
  unset FAKE_EXISTING_WORKSPACE
  unset FAKE_SERVER_STOPPED
  unset FAKE_CURRENT_TAB
  unset FAKE_CURRENT_TAB_CROWDED
  unset HERDR_ENV
  unset HERDR_WORKSPACE_ID
  unset HERDR_TAB_ID
  unset HERDR_PANE_ID
}

function assert_log_contains() {
  local expected=$1

  if ! grep -Fqx -- "$expected" "$fake_log"; then
    print -u2 -- "期待したHerdr操作がありません: $expected"
    print -u2 -- "--- 実際の操作 ---"
    print -u2 -r -- "$(cat "$fake_log")"
    return 1
  fi
}

function test_codexを指定すると3ペインを作ってCodexを起動する() {
  reset_fake
  cd "$repo_dir"

  hdev codex

  assert_log_contains "pane split w1:p1 --direction down --ratio 0.7"
  assert_log_contains "pane split w1:p1 --direction right --ratio 0.5"
  assert_log_contains "pane run w1:p3 hunk diff --watch"
  assert_log_contains "pane run w1:p1 codex"
}

function test_claudeを指定するとClaudeCodeを起動する() {
  reset_fake
  cd "$repo_dir"

  hdev claude

  assert_log_contains "pane run w1:p1 claude"
}

function test_既存workspaceがあれば新しいタブに3ペインを作る() {
  reset_fake
  export FAKE_EXISTING_WORKSPACE=1
  cd "$repo_dir"

  hdev codex

  assert_log_contains "tab create --workspace w1 --cwd $repo_dir --label codex --focus"
  assert_log_contains "pane split w1:p10 --direction down --ratio 0.7"
  assert_log_contains "pane split w1:p10 --direction right --ratio 0.5"
  assert_log_contains "pane run w1:p12 hunk diff --watch"
  assert_log_contains "pane run w1:p10 codex"
}

function test_未対応の引数を拒否する() {
  reset_fake
  cd "$repo_dir"

  if hdev claudex 2>/dev/null; then
    print -u2 -- "未対応の引数を受理しています"
    return 1
  fi

  if [[ -s "$fake_log" ]]; then
    print -u2 -- "引数エラーでもHerdrを操作しています"
    return 1
  fi
}

function test_Herdr停止中ならサーバーを起動する() {
  reset_fake
  export FAKE_SERVER_STOPPED=1
  cd "$repo_dir"

  hdev codex

  assert_log_contains "server"
}

function test_Herdr内ではクライアントを再起動しない() {
  reset_fake
  export FAKE_CURRENT_TAB=1
  export HERDR_ENV=1
  export HERDR_WORKSPACE_ID=w1
  export HERDR_TAB_ID=w1:t9
  export HERDR_PANE_ID=w1:p9
  cd "$repo_dir"

  hdev claude

  assert_log_contains "pane split w1:p9 --direction down --ratio 0.7"
  assert_log_contains "pane split w1:p9 --direction right --ratio 0.5"
  assert_log_contains "pane run w1:p11 hunk diff --watch"
  assert_log_contains "pane run w1:p9 claude"
  if grep -Fqx -- "<attach>" "$fake_log"; then
    print -u2 -- "Herdr内でクライアントを再起動しています"
    return 1
  fi
}

function test_Herdr内の構成済みタブにはペインを追加しない() {
  reset_fake
  export FAKE_CURRENT_TAB_CROWDED=1
  export HERDR_ENV=1
  export HERDR_WORKSPACE_ID=w1
  export HERDR_TAB_ID=w1:t9
  export HERDR_PANE_ID=w1:p9
  cd "$repo_dir"

  if hdev codex 2>/dev/null; then
    print -u2 -- "構成済みタブを受理しています"
    return 1
  fi

  if grep -Fq -- "pane split" "$fake_log"; then
    print -u2 -- "構成済みタブにペインを追加しています"
    return 1
  fi
}

set +e +u
implementation_path=${HDEV_IMPLEMENTATION_PATH:-"$HOME/.config/zsh/functions/hdev.zsh"}
source "$implementation_path"
set -e -u

test_codexを指定すると3ペインを作ってCodexを起動する
test_claudeを指定するとClaudeCodeを起動する
test_既存workspaceがあれば新しいタブに3ペインを作る
test_未対応の引数を拒否する
test_Herdr停止中ならサーバーを起動する
test_Herdr内ではクライアントを再起動しない
test_Herdr内の構成済みタブにはペインを追加しない

print -- "hdev tests: PASS"
