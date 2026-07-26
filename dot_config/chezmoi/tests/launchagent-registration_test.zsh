#!/usr/bin/env zsh

set -eu

test_tmp=$(mktemp -d -t launchagent-registration-test.XXXXXX)
trap 'command rm -r -- "$test_tmp"' EXIT

source_dir=${CHEZMOI_FETCH_NOTIFY_SOURCE_DIR:-"${0:A:h:h:h:h}"}
template="$source_dir/run_onchange_after_configure-chezmoi-fetch-notify.sh.tmpl"
fake_launchctl="$source_dir/dot_config/chezmoi/tests/fakes/executable_launchctl"
chezmoi_bin=${commands[chezmoi]:?chezmoiが見つかりません}
fixture_number=0
fixture_dir=""
fake_home=""
state_dir=""
log_file=""
rendered_script=""
domain="gui/$(id -u)"
label="com.kamo.chezmoi-fetch-notify"

function assert_value_is() {
  local actual=$1
  local expected=$2
  local description=$3

  if [[ $actual != "$expected" ]]; then
    print -u2 -- "$description"
    print -u2 -- "expected:\n$expected"
    print -u2 -- "actual:\n$actual"
    return 1
  fi
}

function arrange_launchctl_state() {
  local initial_state=$1
  fixture_number=$((fixture_number + 1))
  fixture_dir="$test_tmp/fixture-$fixture_number"
  fake_home="$fixture_dir/home"
  state_dir="$fixture_dir/state"
  log_file="$fixture_dir/launchctl.log"
  rendered_script="$fixture_dir/configure.sh"
  local fake_bin="$fixture_dir/bin"
  local plist="$fake_home/Library/LaunchAgents/$label.plist"
  mkdir -p "$fake_bin" "$state_dir" "${plist:h}"
  ln -s "$fake_launchctl" "$fake_bin/launchctl"
  : > "$log_file"
  : > "$plist"

  case "$initial_state" in
    enabled)
      : > "$state_dir/enabled"
      : > "$state_dir/registered"
      ;;
    disabled)
      : > "$state_dir/disabled"
      : > "$state_dir/registered"
      ;;
    unregistered)
      ;;
    *)
      print -u2 -- "未対応の初期状態です: $initial_state"
      return 1
      ;;
  esac

  "$chezmoi_bin" --source "$source_dir" execute-template \
    < "$template" > "$rendered_script"
  chmod +x "$rendered_script"
  export HOME="$fake_home"
  export PATH="$fake_bin:/usr/bin:/bin"
  export FAKE_LAUNCHCTL_STATE_DIR="$state_dir"
  export FAKE_LAUNCHCTL_LOG="$log_file"
}

function assert_agent_is_registered_in_order() {
  local expected
  local actual

  expected=$(
    print -r -- "bootout $domain/$label"
    print -r -- "enable $domain/$label"
    print -r -- "bootstrap $domain $fake_home/Library/LaunchAgents/$label.plist"
  )
  actual=$(< "$log_file")

  [[ -e "$state_dir/registered" ]]
  [[ -e "$state_dir/enabled" ]]
  [[ ! -e "$state_dir/disabled" ]]
  assert_value_is "$actual" "$expected" "LaunchAgent操作順が一致しません"
}

function test_有効かつ登録済みなら再登録する() {
  arrange_launchctl_state enabled

  "$rendered_script"

  assert_agent_is_registered_in_order
}

function test_無効かつ登録済みでも有効化して再登録する() {
  arrange_launchctl_state disabled

  "$rendered_script"

  assert_agent_is_registered_in_order
}

function test_未登録でも有効化して登録する() {
  arrange_launchctl_state unregistered

  "$rendered_script"

  assert_agent_is_registered_in_order
}

test_有効かつ登録済みなら再登録する
test_無効かつ登録済みでも有効化して再登録する
test_未登録でも有効化して登録する

print -- "launchagent registration tests: PASS"
