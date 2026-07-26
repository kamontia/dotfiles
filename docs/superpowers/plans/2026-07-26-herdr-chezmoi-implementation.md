# Herdr設定とhdevのChezmoi管理 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Herdrの選択済み設定、`hdev`、テスト、Homebrew依存をChezmoi正本で再現できる状態にする。

**Architecture:** `hdev`のロジックをzsh関数ファイルへ分離し、`~/.local/bin/hdev`を薄い実行入口にする。Herdr設定とテストをXDG配下へ配置し、Chezmoiでは各ライブパスに対応する正本名で管理する。ライブの `.zshrc` は全面同期せず、既存の `hdev` 関数ブロックだけを除去する。

**Tech Stack:** Chezmoi 2.70.1、zsh、Herdr 0.7.5、Hunk 0.17.6、Homebrew Bundle、jq

## Global Constraints

- HerdrのPrefixは `Ctrl+Q` とする。
- tmuxのPrefixは `Ctrl+A` のまま変更しない。
- Herdrのネスト起動は許可しない。
- `hdev`のCLIは `hdev claude` と `hdev codex` を維持する。
- SpaceはGitリポジトリ、Tabはエージェント作業、各TabはAgent、Hunk、Shellの3ペインとする。
- ライブの `.zshrc` 全体をChezmoi正本へコピーしない。
- 秘匿情報をChezmoi正本、テスト出力、コミットへ含めない。
- 既存の未追跡Nvimファイルを変更、ステージ、コミットしない。
- コミットメッセージは `<type>: <日本語の要約>` とし、pushしない。

---

## File Structure

- Create: `dot_config/zsh/functions/hdev.zsh`
  - `hdev <claude|codex>` のロジックだけを定義する。
- Create: `dot_local/bin/executable_hdev`
  - 管理済み関数ファイルを読み込み、引数と終了コードを透過する。
- Create: `dot_config/zsh/tests/hdev_test.zsh`
  - HerdrのFakeを使い、`hdev`の7つの振る舞いを検証する。
- Create: `dot_config/herdr/config.toml`
  - 選択済みのHerdr設定を保持する。
- Modify: `Brewfile`
  - `herdr` と `hunk` のFormulaを宣言する。
- Modify live only: `~/.zshrc`
  - 未管理の `hdev` 関数ブロックだけを削除する。
- Remove live only after migration: `~/.config/zsh/hdev_test.zsh`
  - Chezmoi適用後は同じパスへ管理済みテストが配置されるため、別途削除しない。

---

### Task 1: hdevを独立したChezmoi管理コマンドへ移す

**Files:**

- Create: `dot_config/zsh/functions/hdev.zsh`
- Create: `dot_local/bin/executable_hdev`
- Create: `dot_config/zsh/tests/hdev_test.zsh`
- Reference only: `~/.zshrc`
- Reference only: `~/.config/zsh/hdev_test.zsh`

**Interfaces:**

- Produces: `hdev <claude|codex> -> exit status`
- Produces: sourceable zsh function `hdev()`
- Consumes: `herdr`, `hunk`, `jq`, `git`, `claude` または `codex`

- [ ] **Step 1: Chezmoi側へテストを作り、関数ファイルを直接読むようにする**

現在の `~/.config/zsh/hdev_test.zsh` を正本側の `dot_config/zsh/tests/hdev_test.zsh` へ移す。
テスト末尾の `.zshrc` 読込を次に置き換える。

```zsh
implementation_path=${HDEV_IMPLEMENTATION_PATH:-"$HOME/.config/zsh/functions/hdev.zsh"}
source "$implementation_path"
```

テスト名と期待値は次の7件を維持する。

```text
codexを指定すると3ペインを作ってCodexを起動する
claudeを指定するとClaudeCodeを起動する
既存workspaceがあれば新しいタブに3ペインを作る
未対応の引数を拒否する
Herdr停止中ならサーバーを起動する
Herdr内ではクライアントを再起動しない
Herdr内の構成済みタブにはペインを追加しない
```

- [ ] **Step 2: テストを実行し、関数ファイル不在で失敗することを確認する**

Run:

```bash
source_dir=$(chezmoi source-path)
HDEV_IMPLEMENTATION_PATH="$source_dir/dot_config/zsh/functions/hdev.zsh" \
  zsh "$source_dir/dot_config/zsh/tests/hdev_test.zsh"
```

Expected: FAIL with `no such file or directory: .../dot_config/zsh/functions/hdev.zsh`

- [ ] **Step 3: hdev関数を正本側へ移す**

ライブ `.zshrc` の `hdev()` 本体を `dot_config/zsh/functions/hdev.zsh` へ移す。
関数ファイルはシェル初期化、環境変数設定、関数実行を行わず、次の形で関数定義だけを持つ。

```zsh
function hdev() {
  local agent_command
  case ${1:-} in
    claude)
      agent_command=claude
      ;;
    codex)
      agent_command=codex
      ;;
    *)
      print -u2 -- "使い方: hdev <claude|codex>"
      return 2
      ;;
  esac

  local required_command
  for required_command in herdr hunk jq "$agent_command"; do
    if (( ! $+commands[$required_command] )) && (( ! $+functions[$required_command] )); then
      print -u2 -- "必要なコマンドが見つかりません: $required_command"
      return 1
    fi
  done

  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
    print -u2 -- "Gitリポジトリ内で実行してください"
    return 1
  }

  local server_status
  server_status=$(herdr status server 2>/dev/null)
  if [[ $server_status != *"status: running"* ]]; then
    herdr server >/dev/null 2>&1 &!

    local attempt
    for attempt in {1..50}; do
      server_status=$(herdr status server 2>/dev/null)
      [[ $server_status == *"status: running"* ]] && break
      sleep 0.1
    done

    if [[ $server_status != *"status: running"* ]]; then
      print -u2 -- "Herdrサーバーを起動できませんでした"
      return 1
    fi
  fi

  local workspace_id="" root_pane_id pane_list
  local workspace_list workspace_json tab_json workspace_label

  if [[ ${HERDR_ENV:-0} == 1 ]]; then
    if [[ -z ${HERDR_WORKSPACE_ID:-} || -z ${HERDR_TAB_ID:-} || -z ${HERDR_PANE_ID:-} ]]; then
      print -u2 -- "現在のHerdrペインを特定できません"
      return 1
    fi

    workspace_id=$HERDR_WORKSPACE_ID
    root_pane_id=$HERDR_PANE_ID
    pane_list=$(herdr pane list --workspace "$workspace_id") || return 1

    if ! jq -e \
      --arg tab "$HERDR_TAB_ID" \
      --arg pane "$root_pane_id" \
      '[.result.panes[]? | select(.tab_id == $tab)] as $panes
       | ($panes | length) == 1 and $panes[0].pane_id == $pane' \
      >/dev/null <<< "$pane_list"; then
      print -u2 -- "新規の空Tabで実行してください"
      return 1
    fi
  else
    workspace_list=$(herdr workspace list) || return 1

    local candidate_workspace_id
    for candidate_workspace_id in ${(f)"$(jq -r '.result.workspaces[]?.workspace_id' <<< "$workspace_list")"}; do
      pane_list=$(herdr pane list --workspace "$candidate_workspace_id") || continue
      if jq -e --arg cwd "$repo_root" \
        '.result.panes[]? | select(.cwd == $cwd)' \
        >/dev/null <<< "$pane_list"; then
        workspace_id=$candidate_workspace_id
        break
      fi
    done

    if [[ -n $workspace_id ]]; then
      tab_json=$(herdr tab create \
        --workspace "$workspace_id" \
        --cwd "$repo_root" \
        --label "$agent_command" \
        --focus) || return 1
      root_pane_id=$(jq -er '.result.root_pane.pane_id' <<< "$tab_json") || return 1
    else
      workspace_label=${repo_root:t}
      workspace_json=$(herdr workspace create \
        --cwd "$repo_root" \
        --label "$workspace_label" \
        --focus) || return 1
      workspace_id=$(jq -er '.result.workspace.workspace_id' <<< "$workspace_json") || return 1
      root_pane_id=$(jq -er '.result.root_pane.pane_id' <<< "$workspace_json") || return 1
    fi
  fi

  local bottom_pane_json hunk_pane_json bottom_pane_id hunk_pane_id

  bottom_pane_json=$(herdr pane split "$root_pane_id" \
    --direction down \
    --ratio 0.7) || return 1
  bottom_pane_id=$(jq -er '.result.pane.pane_id' <<< "$bottom_pane_json") || return 1

  hunk_pane_json=$(herdr pane split "$root_pane_id" \
    --direction right \
    --ratio 0.5) || return 1
  hunk_pane_id=$(jq -er '.result.pane.pane_id' <<< "$hunk_pane_json") || return 1

  herdr pane rename "$root_pane_id" "$agent_command" >/dev/null || return 1
  herdr pane rename "$hunk_pane_id" review >/dev/null || return 1
  herdr pane rename "$bottom_pane_id" shell >/dev/null || return 1

  herdr pane run "$hunk_pane_id" "hunk diff --watch" >/dev/null || return 1
  herdr pane run "$root_pane_id" "$agent_command" >/dev/null || return 1

  [[ ${HERDR_ENV:-0} == 1 ]] && return 0
  herdr
}
```

移動時はライブ実装と関数本体を比較し、次のHerdr操作が残っていることを確認する。

```text
herdr status server
herdr workspace list/create
herdr tab create
herdr pane list/split/rename/run
```

- [ ] **Step 4: 薄い実行入口を作る**

`dot_local/bin/executable_hdev` を次の内容で作る。

```zsh
#!/usr/bin/env zsh

implementation_path="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/functions/hdev.zsh"

if [[ ! -r "$implementation_path" ]]; then
  print -u2 -- "hdevの実装が見つかりません: $implementation_path"
  exit 1
fi

source "$implementation_path"
hdev "$@"
```

- [ ] **Step 5: 構文とテストを確認する**

Run:

```bash
source_dir=$(chezmoi source-path)
zsh -n "$source_dir/dot_config/zsh/functions/hdev.zsh"
zsh -n "$source_dir/dot_local/bin/executable_hdev"
zsh -n "$source_dir/dot_config/zsh/tests/hdev_test.zsh"
HDEV_IMPLEMENTATION_PATH="$source_dir/dot_config/zsh/functions/hdev.zsh" \
  zsh "$source_dir/dot_config/zsh/tests/hdev_test.zsh"
```

Expected:

```text
hdev tests: PASS
```

- [ ] **Step 6: hdevの正本だけをコミットする**

```bash
git add \
  dot_config/zsh/functions/hdev.zsh \
  dot_local/bin/executable_hdev \
  dot_config/zsh/tests/hdev_test.zsh
git diff --cached --check
git commit -m "feat: hdevをChezmoi管理の独立コマンドへ移行"
```

---

### Task 2: 選択済みのHerdr設定をChezmoi管理へ追加する

**Files:**

- Create: `dot_config/herdr/config.toml`

**Interfaces:**

- Produces: `~/.config/herdr/config.toml`
- Consumes: Herdr 0.7.5 configuration schema

- [ ] **Step 1: 設定ファイル不在の失敗を確認する**

Run:

```bash
source_dir=$(chezmoi source-path)
HERDR_CONFIG_PATH="$source_dir/dot_config/herdr/config.toml" herdr config check
```

Expected: non-zero exit because the target config does not exist.

- [ ] **Step 2: 選択済み設定を作る**

`dot_config/herdr/config.toml` を次の内容で作る。

```toml
onboarding = false

[theme]
name = "catppuccin"
auto_switch = false

[terminal]
default_shell = ""
shell_mode = "auto"
new_cwd = "follow"

[update]
channel = "stable"
version_check = true
manifest_check = true

[keys]
prefix = "ctrl+q"
switch_tab = "prefix+1..9"
switch_workspace = "prefix+shift+1..9"
focus_agent = "prefix+alt+1..9"

[ui]
agent_panel_sort = "spaces"
sidebar_start_collapsed = false
prompt_new_tab_name = false
pane_borders = true
pane_gaps = true
show_agent_labels_on_pane_borders = true
hide_tab_bar_when_single_tab = false

[ui.toast]
delivery = "terminal"
delay_seconds = 1

[ui.sound]
enabled = true

[session]
resume_agents_on_restore = true

[remote]
manage_ssh_config = true

[experimental]
allow_nested = false
switch_ascii_input_source_in_prefix = true
reveal_hidden_cursor_for_cjk_ime = true
cjk_ime_agents = ["claude", "codex"]
```

- [ ] **Step 3: Herdr自身の設定検証を実行する**

Run:

```bash
source_dir=$(chezmoi source-path)
HERDR_CONFIG_PATH="$source_dir/dot_config/herdr/config.toml" herdr config check
```

Expected: exit 0 with no errors or conflicting key diagnostics.

- [ ] **Step 4: Herdr設定だけをコミットする**

```bash
git add dot_config/herdr/config.toml
git diff --cached --check
git commit -m "feat: Herdr設定をChezmoi管理へ追加"
```

---

### Task 3: Homebrew依存をBrewfileへ追加する

**Files:**

- Modify: `Brewfile`

**Interfaces:**

- Produces: Homebrew Formula declarations for `herdr` and `hunk`
- Consumes: existing `make tools` and `brew bundle --file=./Brewfile`

- [ ] **Step 1: FormulaをCLI Tools節へ追加する**

`brew "chezmoi"` の後へ次を追加する。

```ruby
brew "herdr"
brew "hunk"
```

- [ ] **Step 2: Brewfileの宣言とインストール済みFormulaを検証する**

Run:

```bash
source_dir=$(chezmoi source-path)
brew bundle list --file="$source_dir/Brewfile" --formula \
  | rg '^(herdr|hunk)$'
brew list --versions herdr hunk
```

Expected:

```text
herdr
hunk
herdr 0.7.5
hunk 0.17.6
```

Formulaの将来更新でバージョンは上がり得るため、実装時は両方の名前と非空のバージョンが出ることを必須とする。
既存Brewfile全体には未更新Formulaと未導入tapがあるため、`brew bundle check` 全体の成功は今回の完了条件にしない。

- [ ] **Step 3: Brewfileだけをコミットする**

```bash
git add Brewfile
git diff --cached --check
git commit -m "chore: HerdrとHunkをBrewfileへ追加"
```

---

### Task 4: 対象パスだけをライブ環境へ適用して検証する

**Files:**

- Create live: `~/.config/herdr/config.toml`
- Create live: `~/.config/zsh/functions/hdev.zsh`
- Replace live with managed version: `~/.config/zsh/tests/hdev_test.zsh`
- Create live: `~/.local/bin/hdev`
- Modify live only: `~/.zshrc`

**Interfaces:**

- Consumes: Tasks 1から3のChezmoi正本
- Produces: live commands `hdev claude` and `hdev codex`

- [ ] **Step 1: リポジトリ状態と対象差分を確認する**

Run:

```bash
source_dir=$(chezmoi source-path)
git -C "$source_dir" status --short
chezmoi diff -- \
  ~/.config/herdr/config.toml \
  ~/.config/zsh/functions/hdev.zsh \
  ~/.config/zsh/tests/hdev_test.zsh \
  ~/.local/bin/hdev
```

Expected: 対象4パスだけに追加または更新差分がある。未追跡のNvimファイルは残る。

- [ ] **Step 2: Chezmoi適用をdry-runする**

Run:

```bash
chezmoi apply --dry-run --verbose -- \
  ~/.config/herdr/config.toml \
  ~/.config/zsh/functions/hdev.zsh \
  ~/.config/zsh/tests/hdev_test.zsh \
  ~/.local/bin/hdev
```

Expected: 対象4パス以外を変更しない。

- [ ] **Step 3: 対象4パスだけを適用する**

Run:

```bash
chezmoi apply --verbose -- \
  ~/.config/herdr/config.toml \
  ~/.config/zsh/functions/hdev.zsh \
  ~/.config/zsh/tests/hdev_test.zsh \
  ~/.local/bin/hdev
```

Expected: exit 0.

- [ ] **Step 4: ライブ.zshrcから旧hdev関数だけを削除する**

`# Herdr上にエージェント、Hunk、作業用シェルの3ペインを用意する` から `hdev()` の閉じ括弧までを削除する。
削除前後で次を確認し、他のライブ差分を保持する。

```bash
rg -n '^function hdev|Herdr上に' ~/.zshrc
chezmoi status ~/.zshrc
zsh -n ~/.zshrc
```

Expected:

- `rg` は該当なし。
- `.zshrc` は既存のChezmoi差分を保持する。
- `zsh -n` はexit 0。

- [ ] **Step 5: 管理済みhdevを検証する**

Run:

```bash
zsh ~/.config/zsh/tests/hdev_test.zsh
~/.local/bin/hdev unsupported
```

Expected:

- テストは `hdev tests: PASS`。
- 未対応引数は使い方を表示してexit 2。

- [ ] **Step 6: Herdr設定を検証して再読込する**

Run:

```bash
herdr config check
herdr server reload-config
```

Expected: 両方ともexit 0。
再読込が非対応の設定を報告した場合はHerdrを停止せず、次回起動で反映する。

- [ ] **Step 7: tmux設定が変わっていないことを確認する**

Run:

```bash
rg -n 'set -g prefix C-a' ~/.tmux.conf
tmux show-options -gv prefix
```

Expected:

```text
C-a
```

tmuxサーバーが未起動なら、ファイル検証だけを必須とする。

- [ ] **Step 8: 実Herdrの隔離セッションでhdevを確認する**

一時Gitリポジトリと `HERDR_SESSION=hdev-final-integration` を使う。
AgentとHunkは一時PATH上で `/usr/bin/true` へ差し替え、課金や対話セッションを発生させない。

次を検証する。

```text
Space数: 1
Tab数: 2
総Pane数: 6
Tab 1: codex / review / shell
Tab 2: claude / review / shell
```

検証後は `hdev-final-integration` セッションだけを停止、削除する。
既存のdefaultセッションは停止しない。

- [ ] **Step 9: ChezmoiとGitの最終状態を確認する**

Run:

```bash
chezmoi verify \
  ~/.config/herdr/config.toml \
  ~/.config/zsh/functions/hdev.zsh \
  ~/.config/zsh/tests/hdev_test.zsh \
  ~/.local/bin/hdev
git -C "$(chezmoi source-path)" status --short
git -C "$(chezmoi source-path)" log -5 --oneline
```

Expected:

- 管理対象ファイルは一致する。
- 未追跡のNvimファイルだけが残る。
- 実装コミット3件と設計コミット2件が確認できる。
- pushは実行されていない。
