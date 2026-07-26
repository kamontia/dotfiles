# Herdr設定とhdevのChezmoi管理設計

## 背景

Herdrは複数のGitリポジトリとエージェント作業を、Space、Tab、Paneの階層で管理する。
現在の運用では、SpaceをGitリポジトリ、Tabをエージェント作業、PaneをAgent、Hunk、Shellの役割に対応させている。

HerdrのPrefixは既定の `Ctrl+B` のままであり、設定ファイルはChezmoi管理外である。
tmuxのPrefixはライブ設定とChezmoi正本の両方で `Ctrl+A` になっている。
Herdr内でtmuxを起動する可能性があるため、両者のPrefixは分ける。

`hdev` はライブの `.zshrc` にだけ存在する。
ライブの `.zshrc` にはChezmoi正本にないローカル設定と秘匿情報が含まれるため、ファイル全体を正本へコピーする方法は採用しない。

## 目的

この変更は次の状態を作る。

- HerdrのPrefixを `Ctrl+Q` にする。
- tmuxのPrefixは `Ctrl+A` のまま維持する。
- Herdr設定、`hdev`、`hdev`のテストをChezmoiで管理する。
- HomebrewのHerdrとHunkを `Brewfile` で管理する。
- `hdev claude` と `hdev codex` の利用方法を維持する。
- ライブの `.zshrc` にある未整理の差分や秘匿情報をChezmoi正本へ取り込まない。

## 対象外

次の変更は行わない。

- tmuxのPrefix変更
- Herdrのネスト起動許可
- `.zshrc` 全体のChezmoi正本への同期
- `hdev` が作成するSpace、Tab、Pane構成の仕様変更
- 選択した番号ショートカット以外のHerdrキーバインド変更
- tmuxの追加キーバインド変更

## 設定構成

### Herdr

Chezmoi正本へ `dot_config/herdr/config.toml` を追加する。
現在のライブ設定を維持し、選択した操作、表示、通知、復元、更新、IME設定を明示する。

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

HerdrのPrefix操作は `Ctrl+Q` に続けてアクションキーを押す。
既定のdetachは `prefix+q` なので、操作は `Ctrl+Q`、`Q` の順になる。
`experimental.allow_nested` は有効化しない。

番号ショートカットは次の対応にする。

- `Ctrl+Q`、`1..9`：Tabを切り替える。
- `Ctrl+Q`、`Shift+1..9`：Spaceを切り替える。
- `Ctrl+Q`、`Alt+1..9`：Agentへフォーカスする。

新しいTabは名前入力を挟まず作成する。
新しいPaneとTabは、現在のPaneまたはSpaceのディレクトリを引き継ぐ。
`default_shell` は環境の `$SHELL` を使い、`shell_mode = "auto"` によってmacOSではログインシェルとして起動する。

サイドバーは展開状態で開始し、AgentをSpace単位で並べる。
単一TabでもTabバーを表示し、Paneの境界線、余白、Agent名を表示する。

Agentの完了または入力待ちは、外側のターミナルを通じてデスクトップ通知する。
通知音は有効にする。

Herdrサーバー再起動後は、公式Integrationがセッション参照を取得できたAgentを復元する。
更新チャンネルは安定版とし、Herdr本体とAgent検出定義の更新を確認する。
リモート接続では、利用者のSSH設定を優先しながらHerdrにkeepalive設定を補完させる。

Prefixモード中はmacOSの入力ソースを一時的にASCIIへ切り替える。
Claude CodeとCodexでは、IME候補ウィンドウの位置を合わせるため、フォーカス中のPaneのカーソルを外側のターミナルへ表示する。

### tmux

`dot_tmux.conf` は変更しない。
tmuxのPrefixは `Ctrl+A` を維持する。
Herdr内でtmuxを起動した場合も、Herdrは `Ctrl+Q`、tmuxは `Ctrl+A` で直接操作できる。

### hdev

`hdev` を `.zshrc` 内の関数から独立したコマンドへ移す。
実装は `~/.config/zsh/functions/hdev.zsh` に置き、`~/.local/bin/hdev` は実装を読み込んで呼び出すだけの入口にする。

Chezmoi正本では次のパスを使う。

```text
dot_config/zsh/functions/hdev.zsh
dot_local/bin/executable_hdev
```

この構成なら、ライブとChezmoi正本で差分の大きい `.zshrc` を変更せずに `hdev` を配布できる。
`~/.local/bin` は既にPATHへ追加されているため、利用者のコマンドは変わらない。

```bash
hdev claude
hdev codex
```

実装ファイルは `hdev` 関数を定義する。
実行入口は実装ファイルを読み込み、受け取った引数を関数へ渡し、同じ終了コードを返す。

現在のライブ `.zshrc` にある `hdev` 関数は削除する。
この削除はChezmoi正本をライブへ全面適用せず、該当ブロックだけを対象にする。
既に起動しているzshには古い関数定義が残るため、新しいシェルを開くか `unfunction hdev` を実行して独立コマンドへ切り替える。

### テスト

テストは `~/.config/zsh/tests/hdev_test.zsh` に配置する。
Chezmoi正本では `dot_config/zsh/tests/hdev_test.zsh` とする。

テストは `.zshrc` 全体を読み込まず、`hdev` の実装ファイルだけを読み込む。
これにより、zinit、補完、対話シェル用フック、ローカルの環境変数からテストを分離する。

テストは次の振る舞いを保証する。

- `codex` を指定するとAgent、Hunk、Shellの3ペインを作る。
- `claude` を指定するとClaude Codeを起動する。
- 既存Spaceがある場合は新規Tabに3ペインを作る。
- 未対応の引数を拒否する。
- Herdr停止中ならサーバーを起動する。
- Herdr内ではクライアントをネスト起動しない。
- 構成済みTabにはペインを追加しない。

## Homebrew管理

Chezmoi正本の `Brewfile` に次を追加する。

```ruby
brew "herdr"
brew "hunk"
```

既にインストール済みの環境では、`brew bundle` は同じFormulaを重複インストールしない。
新しい環境では、Brewfileから必要な実行ファイルを導入できる。

## 適用手順

変更はChezmoi正本を先に更新する。
その後、対象ファイルだけを確認してライブ環境へ適用する。

```bash
chezmoi diff
chezmoi apply ~/.config/herdr/config.toml
chezmoi apply ~/.config/zsh/functions/hdev.zsh
chezmoi apply ~/.config/zsh/tests/hdev_test.zsh
chezmoi apply ~/.local/bin/hdev
```

ライブ `.zshrc` の `hdev` 関数だけを削除し、他の差分には触れない。
Herdrが起動中なら `herdr server reload-config` でPrefix設定を再読込する。
再読込が未対応または失敗した場合は、既存Paneを停止せず、次回のHerdr起動から新設定を使う。

## 検証

実装後は次の順序で確認する。

1. `zsh -n` で実装、入口、テストの構文を確認する。
2. `hdev`の全テストを実行する。
3. `chezmoi diff` で対象外のファイルが変わっていないことを確認する。
4. `chezmoi apply --dry-run` 相当の確認後、対象パスだけを適用する。
5. `herdr --version` と `hunk --version` を確認する。
6. Herdr設定を再読込し、`Ctrl+Q` でPrefixモードへ入れることを確認する。
7. tmuxのPrefixが `Ctrl+A` のままであることを確認する。
8. Tab、Space、Agentの番号ショートカットを確認する。
9. デスクトップ通知と通知音を確認する。
10. Claude CodeとCodexでIME候補ウィンドウの位置を確認する。
11. 隔離したHerdrセッションで、1 Space内の複数Tabがそれぞれ3ペインになることを確認する。

## 失敗時の扱い

Herdr設定が読み込めない場合は、ライブ設定を変更前の内容へ戻して再読込する。
`hdev`の独立コマンドが動かない場合は、Chezmoi管理した実装と入口を修正し、ライブ `.zshrc` へ関数を戻さない。
Brewfileの追加はインストール済みFormulaを削除しないため、ロールバック時も既存バイナリは保持する。
