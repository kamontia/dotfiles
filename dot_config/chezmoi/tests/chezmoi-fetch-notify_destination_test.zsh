#!/usr/bin/env zsh

set -eu

test_tmp=$(mktemp -d -t chezmoi-fetch-notify-destination-test.XXXXXX)
trap 'command rm -r -- "$test_tmp"' EXIT

source_dir=${CHEZMOI_FETCH_NOTIFY_SOURCE_DIR:-"${0:A:h:h:h:h}"}
destination_dir="$test_tmp/destination"
state_file="$test_tmp/chezmoi-state.boltdb"

function test_Chezmoi配布後のFakeで更新通知テストが成功する() {
  mkdir -p "$destination_dir"

  chezmoi \
    --source "$source_dir" \
    --destination "$destination_dir" \
    --persistent-state "$state_file" \
    apply --parent-dirs --source-path \
    dot_config/chezmoi/tests/chezmoi-fetch-notify_test.zsh \
    dot_config/chezmoi/tests/fakes/executable_osascript \
    dot_local/bin/executable_chezmoi-fetch-notify

  CHEZMOI_FETCH_NOTIFY_SCRIPT="$destination_dir/.local/bin/chezmoi-fetch-notify" \
    zsh "$destination_dir/.config/chezmoi/tests/chezmoi-fetch-notify_test.zsh"
}

test_Chezmoi配布後のFakeで更新通知テストが成功する

print -- "chezmoi-fetch-notify destination test: PASS"
