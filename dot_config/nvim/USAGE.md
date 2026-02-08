# NeoVim プラグイン使い方ガイド

> この設定の Leader キーは **Space** です。以下 `<leader>` は全てスペースキーを指します。

## キーマップ早見表

| キー | モード | 動作 |
|------|--------|------|
| `<leader>e` | Normal | ファイルエクスプローラの開閉 |
| `<leader>ff` | Normal | ファイル名で検索 |
| `<leader>fg` | Normal | ファイル内容をグレップ検索 |
| `<leader>fb` | Normal | 開いているバッファ一覧 |
| `<leader>cf` | Normal | 現在のバッファをフォーマット |
| `<leader>xx` | Normal | 診断パネル (Trouble) の開閉 |
| `<leader>gg` | Normal | gitui を起動 |
| `[d` / `]d` | Normal | 前 / 次の診断 (エラー・警告) へジャンプ |
| `[c` / `]c` | Normal | 前 / 次の Git 変更箇所 (hunk) へジャンプ |
| `Ctrl-h/j/k/l` | Normal | ウィンドウ間移動 (左/下/上/右) |
| `jk` | Insert | Insert モードから抜ける (`Esc` 代替) |
| `Esc` | Normal | 検索ハイライトをクリア |
| `gcc` | Normal | 現在行のコメントトグル (NeoVim 0.11 組み込み) |
| `gc` | Visual | 選択範囲のコメントトグル (NeoVim 0.11 組み込み) |

---

## シナリオ 1: プロジェクトを開いてファイルを探す

**状況:** ターミナルでプロジェクトディレクトリに移動し、`nvim` で起動した。目的のファイルを見つけたい。

### ファイルツリーから探す

```
<leader>e          ← 左側にファイルツリーが開く
j / k              ← ツリー内を上下に移動
Enter              ← ファイルを開く / ディレクトリを展開
<leader>e          ← もう一度押すとツリーを閉じる
```

Neo-tree は現在編集中のファイルを自動的にハイライトする (`follow_current_file` 有効)。
dotfiles や .gitignore 対象ファイルも表示される設定になっている。

### ファイル名であいまい検索する (Telescope)

```
<leader>ff         ← ファイル名検索ウィンドウが開く
(ファイル名を入力)  ← リアルタイムで絞り込み
Enter              ← 選択したファイルを開く
Esc                ← キャンセル
```

### ファイル内容をグレップ検索する

```
<leader>fg         ← プロジェクト全体の grep 検索
(検索文字列を入力)  ← マッチする行がリアルタイムに表示される
Enter              ← 該当行にジャンプ
```

### 開いているバッファを切り替える

```
<leader>fb         ← バッファ一覧を表示
(名前で絞り込み)    ← Enter で切り替え
```

画面上部の bufferline タブバーでも開いているバッファを確認できる。

---

## シナリオ 2: TypeScript のコードを書く

**状況:** `.ts` ファイルを開いてコードを書く。補完・定義ジャンプ・フォーマットを使いたい。

### コード補完 (blink.cmp)

Insert モードで文字を入力すると自動的に補完候補が表示される。

```
(文字を入力)       ← 補完メニューが自動で表示される
Ctrl-n / Ctrl-p   ← 候補を上下に選択
Enter              ← 候補を確定
Ctrl-e             ← 補完メニューを閉じる
```

補完ソースの優先順位: **LSP > パス > スニペット > バッファ内の単語**

### スニペット展開

friendly-snippets により VSCode 互換のスニペットが使える。

```
(Insert モードで)
func               ← 補完候補に "function" スニペットが表示される
Enter              ← スニペットを展開
Tab                ← 次のプレースホルダーへ移動
Shift-Tab          ← 前のプレースホルダーに戻る
```

TypeScript でよく使うスニペット例: `imp` (import), `exp` (export), `af` (arrow function), `cl` (console.log)

### LSP 機能 (定義ジャンプ・ホバー・リネーム)

```
gd                 ← 定義へジャンプ
gr                 ← 参照一覧を表示
K                  ← ホバー情報 (型情報・ドキュメント) を表示
<leader>rn         ← シンボルのリネーム (LSP 標準キーマップの場合)
```

LSP サーバの起動状況は画面右下に fidget が小さく進捗表示する。

### フォーマット

```
<leader>cf         ← prettier でフォーマット実行
```

TypeScript / JavaScript / JSON / CSS / HTML / Markdown は全て prettier が使われる。

### リント

nvim-lint がファイルを開いたとき・保存時・Insert モードから抜けたときに自動で eslint を実行する。
エラーがあれば行の左端 (sign column) にマークが表示される。

---

## シナリオ 3: Python のコードを書く

**状況:** `.py` ファイルを開いて Python コードを書く。

### 補完・定義ジャンプ

TypeScript と同じ操作。LSP は pyright が担当する。

### フォーマット

```
<leader>cf         ← ruff format でフォーマット実行
```

### リント

nvim-lint が自動で ruff を実行する。
設定不要で型エラー・スタイル違反が sign column に表示される。

---

## シナリオ 4: エラーを調査・修正する

**状況:** コードにエラーがある。全体の診断情報を確認して一つずつ修正したい。

### 診断パネルを開く (Trouble)

```
<leader>xx         ← 画面下部に全ファイルの診断一覧が開く
j / k              ← 一覧内を上下に移動
Enter              ← 該当箇所にジャンプ
<leader>xx         ← もう一度押すと閉じる
```

### エラー箇所を順にジャンプする

```
]d                 ← 次の診断 (エラー / 警告) にジャンプ
[d                 ← 前の診断にジャンプ
```

Trouble を開かずにコード内で素早く移動できる。

---

## シナリオ 5: Git の変更を確認してコミットする

**状況:** コードを変更した。差分を確認してコミットしたい。

### 変更箇所を確認する (gitsigns)

sign column (行番号の左) に Git の差分が色付きで表示される。

- 緑のバー: 追加行
- 青のバー: 変更行
- 赤の三角: 削除行

```
]c                 ← 次の変更箇所 (hunk) にジャンプ
[c                 ← 前の変更箇所にジャンプ
```

### gitui でステージ・コミットする

```
<leader>gg         ← フローティングウィンドウで gitui が起動
```

gitui の操作:
```
Tab                ← パネル切り替え (変更一覧 / ステージ / ログなど)
Enter              ← ファイルをステージ / アンステージ
c                  ← コミットメッセージ入力画面へ
Enter              ← コミット確定
q                  ← gitui を閉じて NeoVim に戻る
```

---

## シナリオ 6: コードを編集する (括弧・囲み文字)

**状況:** 括弧や引用符を効率的に操作したい。

### 自動括弧閉じ (nvim-autopairs)

Insert モードで `(` を入力すると自動的に `)` が挿入される。
対応: `()`, `[]`, `{}`, `""`, `''`, `` `` ``

### 囲み文字の操作 (nvim-surround)

```
ys{motion}{char}   ← テキストオブジェクトを指定文字で囲む
ds{char}           ← 囲み文字を削除
cs{old}{new}       ← 囲み文字を変更
```

具体例:

```
ysiw"              ← カーソル位置の単語を "" で囲む:  hello → "hello"
ysiw)              ← カーソル位置の単語を () で囲む:  hello → (hello)
ds"                ← "" を削除:                      "hello" → hello
cs"'               ← "" を '' に変更:                "hello" → 'hello'
cs"<div>           ← "" を HTML タグに変更:           "hello" → <div>hello</div>
```

Visual モードで範囲選択してから `S{char}` でも囲める:

```
(Visual 選択後)
S"                 ← 選択範囲を "" で囲む
S)                 ← 選択範囲を () で囲む
```

---

## シナリオ 7: キーバインドを忘れた

**状況:** キーバインドが思い出せない。

### which-key でヒントを見る

```
<leader>           ← Space を押して少し待つと、続くキーの一覧が表示される
```

例えば `<leader>` を押すと:

```
e → Toggle Explorer
f → +find (ff, fg, fb ...)
c → +code (cf ...)
g → +git (gg ...)
x → +diagnostics (xx ...)
```

のようにグループ化されたキーバインド一覧が表示される。
目的のキーを押せばそのまま実行される。

---

## シナリオ 8: 複数ファイルを並べて作業する

**状況:** 2 つのファイルを左右に並べて見比べたい。

### ウィンドウ分割

```
:vs {file}         ← 左右分割で別ファイルを開く
:sp {file}         ← 上下分割で別ファイルを開く
```

### ウィンドウ間の移動

```
Ctrl-h             ← 左のウィンドウへ
Ctrl-l             ← 右のウィンドウへ
Ctrl-j             ← 下のウィンドウへ
Ctrl-k             ← 上のウィンドウへ
```

Neo-tree を開いている場合も同じキーで Neo-tree とエディタ間を行き来できる。

### bufferline でバッファを切り替える

画面上部のタブバーに開いているファイルが表示される。
`:bnext` / `:bprev` でバッファを順に切り替えられる。

---

## 設定ファイルの構成

```
~/.config/nvim/
├── init.lua                    ← エントリポイント (lazy.nvim ブートストラップ)
├── lua/
│   ├── config/
│   │   ├── options.lua         ← エディタの基本設定
│   │   └── keymaps.lua         ← キーマップ定義
│   └── plugins/
│       ├── colorscheme.lua     ← catppuccin テーマ
│       ├── telescope.lua       ← ファジーファインダー
│       ├── treesitter.lua      ← シンタックスハイライト
│       ├── lsp.lua             ← LSP + Mason
│       ├── completion.lua      ← blink.cmp 補完エンジン
│       ├── explorer.lua        ← Neo-tree ファイルエクスプローラ
│       ├── git.lua             ← gitsigns + gitui
│       ├── ui.lua              ← lualine + bufferline + devicons + indent guide
│       ├── editor.lua          ← autopairs + surround + which-key
│       ├── format-lint.lua     ← conform (formatter) + nvim-lint (linter)
│       └── lsp-ui.lua          ← fidget (LSP進捗) + trouble (診断一覧)
└── lazy-lock.json              ← プラグインバージョンロックファイル
```

プラグインを追加・変更するときは `lua/plugins/` 配下の対応ファイルを編集する。
編集後 `chezmoi add ~/.config/nvim` で dotfiles リポジトリに反映される。
