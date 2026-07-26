# Chezmoi更新確認と通知 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chezmoi正本のリモート更新をログイン直後と1時間ごとにfetchし、未通知のupstreamコミットがある場合だけMacへ通知する。

**Architecture:** 更新確認を単独のzshスクリプトへ閉じ込め、LaunchAgentはスケジュールとログ出力だけを担当する。テストはローカルbare Gitリポジトリを本物のremoteとして使い、macOS通知だけをFakeへ差し替える。Chezmoiの `run_onchange_after_` スクリプトがplist変更時だけLaunchAgentを再登録する。

**Tech Stack:** Chezmoi 2.70.1、zsh、Git、macOS launchd、AppleScript、plutil

## Global Constraints

- Macへのログイン直後と1時間ごとに確認する。
- 同じupstreamコミットIDについては一度だけ通知する。
- `git pull`、`chezmoi apply`、`git commit`、`git push` を自動実行しない。
- エラー時はログへ記録し、デスクトップ通知しない。
- リモートURL、認証情報、Git差分をログへ出さない。
- 実行が重なった場合は後続処理を成功終了でスキップする。
- 1時間より古いロックだけを期限切れとして回収する。
- 既存の未追跡Nvimファイルを変更、ステージ、コミットしない。
- コミットメッセージは `<type>: <日本語の要約>` とし、pushしない。

---

## File Structure

- Create: `dot_local/bin/executable_chezmoi-fetch-notify`
  - 正本の検出、fetch、比較、通知、状態更新、排他制御を行う。
- Create: `dot_config/chezmoi/tests/chezmoi-fetch-notify_test.zsh`
  - ローカルGit remoteを使って更新検出を検証する。
- Create: `dot_config/chezmoi/tests/fakes/executable_osascript`
  - 通知内容を状態ファイルへ蓄積し、通知失敗も再現する。
- Create: `Library/LaunchAgents/com.kamo.chezmoi-fetch-notify.plist.tmpl`
  - ログイン直後と3600秒ごとの実行を定義する。
- Create: `run_onchange_after_configure-chezmoi-fetch-notify.sh.tmpl`
  - plist変更時にLaunchAgentを再登録する。

---

### Task 1: 更新検出スクリプトをテスト駆動で実装する

**Files:**

- Create: `dot_local/bin/executable_chezmoi-fetch-notify`
- Create: `dot_config/chezmoi/tests/chezmoi-fetch-notify_test.zsh`
- Create: `dot_config/chezmoi/tests/fakes/executable_osascript`

**Interfaces:**

- Produces: `chezmoi-fetch-notify -> exit status`
- Consumes: `chezmoi source-path`, local Git upstream, `osascript`
- Test injection:
  - `CHEZMOI_FETCH_NOTIFY_CHEZMOI_BIN`
  - `CHEZMOI_FETCH_NOTIFY_OSASCRIPT_BIN`
  - `CHEZMOI_FETCH_NOTIFY_CACHE_DIR`
  - `CHEZMOI_FETCH_NOTIFY_NOW_EPOCH`

- [ ] **Step 1: 通知Fakeを作る**

`dot_config/chezmoi/tests/fakes/executable_osascript` を次の内容で作る。

```zsh
#!/usr/bin/env zsh

set -u

if [[ ${FAKE_OSASCRIPT_FAIL:-0} == 1 ]]; then
  print -u2 -- "Fake通知エラー"
  exit 1
fi

if [[ -z ${FAKE_NOTIFICATION_LOG:-} ]]; then
  print -u2 -- "FAKE_NOTIFICATION_LOGが未設定です"
  exit 2
fi

cat >/dev/null
print -r -- "${(j: :)@}" >> "$FAKE_NOTIFICATION_LOG"
```

- [ ] **Step 2: 最初の失敗テストを書く**

テストはArrange、Act、Assertを空行で分ける。
最初のテストは、remoteが先行していない状態で通知ログが空のままになることを保証する。

```zsh
function test_リモートが先行していなければ通知しない() {
  arrange_synced_repository

  run_notifier

  [[ ! -s "$notification_log" ]]
}
```

テスト共通準備は次を行う。

```text
一時ディレクトリをmktemp -dで作る
bare remoteをgit init --bareで作る
writer cloneとlocal cloneを作る
writerで初期commitしmainへpushする
localでmainをcheckoutしorigin/mainをupstreamにする
Fake chezmoiはlocal cloneのパスだけを返す
Fake osascriptは通知引数をnotification_logへ保存する
```

- [ ] **Step 3: テストを実行してスクリプト不在で失敗することを確認する**

Run:

```bash
source_dir=$(chezmoi source-path)
CHEZMOI_FETCH_NOTIFY_SCRIPT="$source_dir/dot_local/bin/executable_chezmoi-fetch-notify" \
  zsh "$source_dir/dot_config/chezmoi/tests/chezmoi-fetch-notify_test.zsh"
```

Expected: FAIL because `executable_chezmoi-fetch-notify` does not exist.

- [ ] **Step 4: 更新検出スクリプトの基礎を実装する**

`dot_local/bin/executable_chezmoi-fetch-notify` は次の構造にする。

```zsh
#!/usr/bin/env zsh

set -u

chezmoi_bin=${CHEZMOI_FETCH_NOTIFY_CHEZMOI_BIN:-chezmoi}
osascript_bin=${CHEZMOI_FETCH_NOTIFY_OSASCRIPT_BIN:-osascript}
cache_dir=${CHEZMOI_FETCH_NOTIFY_CACHE_DIR:-"$HOME/Library/Caches/chezmoi-fetch-notify"}
now_epoch=${CHEZMOI_FETCH_NOTIFY_NOW_EPOCH:-$(date +%s)}
lock_dir="$cache_dir/run.lock"
state_file="$cache_dir/last-notified-commit"

function log_error() {
  print -u2 -- "chezmoi-fetch-notify: $1"
}

function release_lock() {
  command rm -f -- "$lock_dir/pid" "$lock_dir/started_at"
  command rmdir -- "$lock_dir" 2>/dev/null || true
}

function try_acquire_lock() {
  command mkdir -p -- "$cache_dir" || return 1
  if command mkdir -- "$lock_dir" 2>/dev/null; then
    print -r -- $$ > "$lock_dir/pid"
    print -r -- "$now_epoch" > "$lock_dir/started_at"
    return 0
  fi

  local started_at=0
  if [[ -r "$lock_dir/started_at" ]]; then
    read -r started_at < "$lock_dir/started_at"
  fi

  if [[ $started_at != <-> || $((now_epoch - started_at)) -lt 3600 ]]; then
    return 2
  fi

  command rm -f -- "$lock_dir/pid" "$lock_dir/started_at"
  command rmdir -- "$lock_dir" 2>/dev/null || return 2
  command mkdir -- "$lock_dir" || return 2
  print -r -- $$ > "$lock_dir/pid"
  print -r -- "$now_epoch" > "$lock_dir/started_at"
}
```

メイン処理は次の契約を守る。

```zsh
try_acquire_lock
lock_status=$?
[[ $lock_status == 2 ]] && exit 0
[[ $lock_status == 0 ]] || {
  log_error "排他ロックを取得できません"
  exit 1
}
trap release_lock EXIT HUP INT TERM

source_dir=$("$chezmoi_bin" source-path 2>/dev/null) || {
  log_error "Chezmoi正本を取得できません"
  exit 1
}

upstream=$(git -C "$source_dir" rev-parse \
  --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null) || {
  log_error "upstreamが設定されていません"
  exit 1
}

git -C "$source_dir" fetch --quiet || {
  log_error "Git fetchに失敗しました"
  exit 1
}

behind_count=$(git -C "$source_dir" rev-list \
  --count 'HEAD..@{upstream}' 2>/dev/null) || {
  log_error "upstreamとの差分を比較できません"
  exit 1
}

[[ $behind_count == 0 ]] && exit 0

upstream_commit=$(git -C "$source_dir" rev-parse '@{upstream}' 2>/dev/null) || {
  log_error "upstreamのコミットIDを取得できません"
  exit 1
}

last_notified=""
[[ -r "$state_file" ]] && read -r last_notified < "$state_file"
[[ $last_notified == "$upstream_commit" ]] && exit 0

repo_name=${source_dir:t}
"$osascript_bin" - "$repo_name" "$behind_count" <<'APPLESCRIPT' || {
on run argv
  set repoName to item 1 of argv
  set behindCount to item 2 of argv
  display notification (behindCount & "件の未取得コミットがあります") with title ("Chezmoi: " & repoName)
end run
APPLESCRIPT
  log_error "デスクトップ通知に失敗しました"
  exit 1
}

state_tmp="$state_file.$$"
print -r -- "$upstream_commit" > "$state_tmp" || exit 1
command mv -f -- "$state_tmp" "$state_file" || exit 1
```

- [ ] **Step 5: 最初のテストを通す**

Run:

```bash
source_dir=$(chezmoi source-path)
CHEZMOI_FETCH_NOTIFY_SCRIPT="$source_dir/dot_local/bin/executable_chezmoi-fetch-notify" \
  zsh "$source_dir/dot_config/chezmoi/tests/chezmoi-fetch-notify_test.zsh"
```

Expected: first test PASS.

- [ ] **Step 6: 残りの振る舞いテストを1件ずつ追加する**

各テストを次の形で追加する。

```zsh
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
```

テスト内にループや条件分岐を書かず、1テスト1関心事にする。
`assert_command_fails` の分岐はテストユーティリティ側へ置く。
Gitのremote、fetch、upstream比較には本物のローカルGitリポジトリを使う。

- [ ] **Step 7: 全テストと構文を確認する**

Run:

```bash
source_dir=$(chezmoi source-path)
zsh -n "$source_dir/dot_local/bin/executable_chezmoi-fetch-notify"
zsh -n "$source_dir/dot_config/chezmoi/tests/chezmoi-fetch-notify_test.zsh"
zsh -n "$source_dir/dot_config/chezmoi/tests/fakes/executable_osascript"
CHEZMOI_FETCH_NOTIFY_SCRIPT="$source_dir/dot_local/bin/executable_chezmoi-fetch-notify" \
  zsh "$source_dir/dot_config/chezmoi/tests/chezmoi-fetch-notify_test.zsh"
```

Expected: 9 tests PASS with no unexpected stderr.

- [ ] **Step 8: 更新検出スクリプトとテストだけをコミットする**

```bash
git add \
  dot_local/bin/executable_chezmoi-fetch-notify \
  dot_config/chezmoi/tests/chezmoi-fetch-notify_test.zsh \
  dot_config/chezmoi/tests/fakes/executable_osascript
git diff --cached --check
git commit -m "feat: Chezmoiのリモート更新通知を追加"
```

---

### Task 2: LaunchAgentをChezmoi管理へ追加する

**Files:**

- Create: `Library/LaunchAgents/com.kamo.chezmoi-fetch-notify.plist.tmpl`
- Create: `run_onchange_after_configure-chezmoi-fetch-notify.sh.tmpl`

**Interfaces:**

- Produces: launchd label `com.kamo.chezmoi-fetch-notify`
- Consumes: `~/.local/bin/chezmoi-fetch-notify`

- [ ] **Step 1: LaunchAgentテンプレートを作る**

`Library/LaunchAgents/com.kamo.chezmoi-fetch-notify.plist.tmpl` を次の内容で作る。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.kamo.chezmoi-fetch-notify</string>
  <key>ProgramArguments</key>
  <array>
    <string>{{ .chezmoi.homeDir }}/.local/bin/chezmoi-fetch-notify</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>StartInterval</key>
  <integer>3600</integer>
  <key>ProcessType</key>
  <string>Background</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>HOME</key>
    <string>{{ .chezmoi.homeDir }}</string>
    <key>PATH</key>
    <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
  </dict>
  <key>StandardOutPath</key>
  <string>{{ .chezmoi.homeDir }}/Library/Logs/chezmoi-fetch-notify.log</string>
  <key>StandardErrorPath</key>
  <string>{{ .chezmoi.homeDir }}/Library/Logs/chezmoi-fetch-notify-error.log</string>
</dict>
</plist>
```

- [ ] **Step 2: plistをレンダリングして構文を検証する**

Run:

```bash
chezmoi cat ~/Library/LaunchAgents/com.kamo.chezmoi-fetch-notify.plist \
  | plutil -lint -
```

Expected:

```text
stdin: OK
```

- [ ] **Step 3: plist変更時の再登録スクリプトを作る**

`run_onchange_after_configure-chezmoi-fetch-notify.sh.tmpl` を次の内容で作る。

```sh
#!/bin/sh

# plist-hash: {{ include "Library/LaunchAgents/com.kamo.chezmoi-fetch-notify.plist.tmpl" | sha256sum }}

set -eu

label="com.kamo.chezmoi-fetch-notify"
domain="gui/$(id -u)"
plist="$HOME/Library/LaunchAgents/$label.plist"

launchctl bootout "$domain/$label" 2>/dev/null || true
launchctl bootstrap "$domain" "$plist"
launchctl enable "$domain/$label"
```

- [ ] **Step 4: 再登録スクリプトをレンダリングして構文を検証する**

Run:

```bash
source_dir=$(chezmoi source-path)
chezmoi cat --source-path \
  run_onchange_after_configure-chezmoi-fetch-notify.sh.tmpl \
  | sh -n
```

Expected: exit 0.

- [ ] **Step 5: LaunchAgent関連ファイルだけをコミットする**

```bash
git add \
  Library/LaunchAgents/com.kamo.chezmoi-fetch-notify.plist.tmpl \
  run_onchange_after_configure-chezmoi-fetch-notify.sh.tmpl
git diff --cached --check
git commit -m "feat: Chezmoi更新確認をLaunchAgentへ登録"
```

---

### Task 3: 対象パスだけをライブ環境へ適用して検証する

**Files:**

- Create live: `~/.local/bin/chezmoi-fetch-notify`
- Create live: `~/.config/chezmoi/tests/chezmoi-fetch-notify_test.zsh`
- Create live: `~/.config/chezmoi/tests/fakes/osascript`
- Create live: `~/Library/LaunchAgents/com.kamo.chezmoi-fetch-notify.plist`
- Execute on change: LaunchAgent再登録スクリプト

**Interfaces:**

- Consumes: Tasks 1と2のChezmoi正本
- Produces: launchd job `gui/$UID/com.kamo.chezmoi-fetch-notify`

- [ ] **Step 1: 対象差分を確認する**

Run:

```bash
chezmoi diff -- \
  ~/.local/bin/chezmoi-fetch-notify \
  ~/.config/chezmoi/tests/chezmoi-fetch-notify_test.zsh \
  ~/.config/chezmoi/tests/fakes/osascript \
  ~/Library/LaunchAgents/com.kamo.chezmoi-fetch-notify.plist
```

Expected: 対象4パスだけに追加差分がある。

- [ ] **Step 2: 対象パスをdry-runする**

Run:

```bash
chezmoi apply --dry-run --verbose -- \
  ~/.local/bin/chezmoi-fetch-notify \
  ~/.config/chezmoi/tests/chezmoi-fetch-notify_test.zsh \
  ~/.config/chezmoi/tests/fakes/osascript \
  ~/Library/LaunchAgents/com.kamo.chezmoi-fetch-notify.plist
```

Expected: 対象4パス以外を変更しない。

- [ ] **Step 3: 対象パスとrun_onchangeスクリプトだけを適用する**

Run:

```bash
chezmoi apply --verbose -- \
  ~/.local/bin/chezmoi-fetch-notify \
  ~/.config/chezmoi/tests/chezmoi-fetch-notify_test.zsh \
  ~/.config/chezmoi/tests/fakes/osascript \
  ~/Library/LaunchAgents/com.kamo.chezmoi-fetch-notify.plist
chezmoi apply --source-path \
  run_onchange_after_configure-chezmoi-fetch-notify.sh.tmpl
```

Expected: exit 0 and LaunchAgent registration.

- [ ] **Step 4: 管理対象とLaunchAgentを検証する**

Run:

```bash
chezmoi verify \
  ~/.local/bin/chezmoi-fetch-notify \
  ~/.config/chezmoi/tests/chezmoi-fetch-notify_test.zsh \
  ~/.config/chezmoi/tests/fakes/osascript \
  ~/Library/LaunchAgents/com.kamo.chezmoi-fetch-notify.plist
launchctl print "gui/$(id -u)/com.kamo.chezmoi-fetch-notify"
```

Expected:

- Chezmoi対象4パスが一致する。
- LaunchAgentの `state`、`runs`、`last exit code` が表示される。
- `StartInterval` は3600秒。

- [ ] **Step 5: ライブテストを実行する**

Run:

```bash
CHEZMOI_FETCH_NOTIFY_SCRIPT="$HOME/.local/bin/chezmoi-fetch-notify" \
  zsh "$HOME/.config/chezmoi/tests/chezmoi-fetch-notify_test.zsh"
```

Expected: 9 tests PASS.

- [ ] **Step 6: 実正本に対して手動確認を1回実行する**

Run:

```bash
"$HOME/.local/bin/chezmoi-fetch-notify"
```

Expected:

- リモート更新がなければ通知なしでexit 0。
- リモート更新があれば一度だけ通知してexit 0。
- pull、apply、commit、pushは発生しない。

- [ ] **Step 7: ログとキャッシュに秘匿情報がないことを確認する**

Run:

```bash
sed -n '1,120p' ~/Library/Logs/chezmoi-fetch-notify.log
sed -n '1,120p' ~/Library/Logs/chezmoi-fetch-notify-error.log
find ~/Library/Caches/chezmoi-fetch-notify -maxdepth 2 -type f -print
```

Expected:

- ログにリモートURL、認証情報、Git差分がない。
- キャッシュには `last-notified-commit` または実行中ロックの既知ファイルだけがある。

- [ ] **Step 8: Gitの最終状態を確認する**

Run:

```bash
source_dir=$(chezmoi source-path)
git -C "$source_dir" status --short
git -C "$source_dir" log -5 --oneline
```

Expected:

- 未追跡のNvimファイルだけが残る。
- 自動更新確認の実装コミット2件と設計、計画コミットが確認できる。
- pushは実行されていない。
