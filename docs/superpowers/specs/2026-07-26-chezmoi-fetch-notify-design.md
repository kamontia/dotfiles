# Chezmoi更新確認と通知の設計

## 背景

Chezmoiは `chezmoi update` によって、正本リポジトリのpullとライブ環境へのapplyを連続して実行する。
現在のライブ `.zshrc` にはChezmoi正本との差分があり、無条件の自動applyはその差分を上書きする可能性がある。

Chezmoiの `git.autoCommit` と `git.autoPush` は、Chezmoi操作による正本変更を自動的にcommit、pushする。
この動作は、日本語コミットとpush前確認の運用規約に合わない。
平文の秘匿情報を誤追加した場合に自動pushする危険もある。

したがって、自動化の範囲をリモート更新の検出と通知に限定する。

## 目的

この変更は次の状態を作る。

- Macへのログイン直後にChezmoi正本のリモート更新を確認する。
- 1時間ごとにリモート更新を確認する。
- upstreamがローカルHEADより先行している場合にデスクトップ通知する。
- 同じリモートコミットについては一度だけ通知する。
- ネットワーク障害とGitエラーをログへ記録する。
- スクリプト、テスト、LaunchAgent、LaunchAgent再登録処理をChezmoiで管理する。

## 対象外

次の操作は自動化しない。

- `git pull`
- `chezmoi apply`
- `git commit`
- `git push`
- Git競合の解消
- upstreamが設定されていないブランチへの自動設定

## 構成

### 更新確認スクリプト

更新確認は `~/.local/bin/chezmoi-fetch-notify` が担当する。
Chezmoi正本では `dot_local/bin/executable_chezmoi-fetch-notify` として管理する。

スクリプトは次の順序で処理する。

1. `chezmoi source-path` で正本リポジトリを特定する。
2. キャッシュディレクトリ内に排他用ディレクトリを作る。
3. 排他用ディレクトリが既に存在する場合は、別プロセスが実行中と判断して終了する。
4. 正本リポジトリでupstreamの有無を確認する。
5. `git fetch --quiet` を実行する。
6. `git rev-list --count HEAD..@{upstream}` でリモート先行数を確認する。
7. 先行数が0なら通知せず終了する。
8. upstreamのコミットIDを通知済み状態と比較する。
9. 未通知のコミットなら `osascript` でデスクトップ通知する。
10. 通知成功後にコミットIDを状態ファイルへ保存する。
11. 終了時に排他用ディレクトリを削除する。

通知本文には先行コミット数とリポジトリ名を含める。
コミットメッセージ、ファイル名、差分内容は通知へ含めない。

### 排他制御

排他制御にはキャッシュディレクトリ内のディレクトリ作成を使う。
`mkdir` の成功をロック取得、失敗を実行中として扱う。

ロックの場所は次とする。

```text
~/Library/Caches/chezmoi-fetch-notify/run.lock
```

スクリプトは `trap` でロックを解除する。
ロックディレクトリの再帰削除は行わない。

異常終了でロックが残った場合に備え、ロック内へ開始時刻とPIDを記録する。
1時間より古いロックは期限切れと判断し、通常のディレクトリ削除で除去してから一度だけロック取得を再試行する。

### 通知済み状態

最後に通知したupstreamコミットIDを次へ保存する。

```text
~/Library/Caches/chezmoi-fetch-notify/last-notified-commit
```

状態ファイルは一時ファイルへ書いてから同一ディレクトリ内でrenameする。
通知が失敗した場合は状態を更新しない。
そのため、次回実行時に通知を再試行できる。

### ログ

LaunchAgentの標準出力と標準エラーは次へ分ける。

```text
~/Library/Logs/chezmoi-fetch-notify.log
~/Library/Logs/chezmoi-fetch-notify-error.log
```

スクリプトは次の事象を標準エラーへ記録する。

- `chezmoi` または `git` が見つからない。
- 正本リポジトリを取得できない。
- upstreamが設定されていない。
- `git fetch` が失敗する。
- Gitの比較処理が失敗する。
- `osascript` による通知が失敗する。

ログには認証情報、リモートURL、Git差分を出力しない。

### LaunchAgent

LaunchAgentは次のパスへ配置する。

```text
~/Library/LaunchAgents/com.kamo.chezmoi-fetch-notify.plist
```

Chezmoi正本では、ホームディレクトリを埋め込むテンプレートとして管理する。

```text
Library/LaunchAgents/com.kamo.chezmoi-fetch-notify.plist.tmpl
```

LaunchAgentは次を設定する。

- `RunAtLoad = true`
- `StartInterval = 3600`
- `ProgramArguments` は管理済み更新確認スクリプトを指す。
- `PATH` はHomebrewとmacOS標準コマンドを解決できる値に固定する。
- 標準出力と標準エラーを指定のログへ出す。

LaunchAgent自身はpull、apply、commit、pushを実行しない。

### LaunchAgent再登録

plistの追加または変更後は、Chezmoiの `run_onchange_after_` スクリプトでLaunchAgentを再登録する。
再登録スクリプトはplist内容のハッシュをテンプレートコメントへ含め、plistが変わった場合だけ実行されるようにする。

再登録は現在のGUIセッションを対象にする。
同じlabelが登録済みなら `launchctl bootout` し、その後 `launchctl bootstrap` する。
未登録時の `bootout` 失敗は無視するが、`bootstrap` 失敗は終了コードで通知する。

### テスト

テストは次へ配置する。

```text
~/.config/chezmoi/tests/chezmoi-fetch-notify_test.zsh
```

Chezmoi正本では次のパスで管理する。

```text
dot_config/chezmoi/tests/chezmoi-fetch-notify_test.zsh
```

テストは一時GitリポジトリとFakeコマンドを使う。
本物のリモートリポジトリ、通知センター、ライブのChezmoi正本にはアクセスしない。

テストは次の振る舞いを保証する。

- リモートが先行していなければ通知しない。
- リモートが先行していれば一度通知する。
- 同じupstreamコミットIDでは再通知しない。
- upstreamが新しいコミットへ進めば再通知する。
- `git fetch` が失敗した場合は通知せず非0で終了する。
- upstream未設定では通知せず非0で終了する。
- 実行中ロックがあれば処理を重ねず0で終了する。
- 期限切れロックなら回収して更新確認を行う。
- 通知失敗時は通知済み状態を更新しない。

## Chezmoi管理パス

Chezmoi正本へ次を追加する。

```text
dot_local/bin/executable_chezmoi-fetch-notify
dot_config/chezmoi/tests/chezmoi-fetch-notify_test.zsh
Library/LaunchAgents/com.kamo.chezmoi-fetch-notify.plist.tmpl
run_onchange_after_configure-chezmoi-fetch-notify.sh.tmpl
```

## 適用

実装後は対象パスだけをdry-runし、その後に適用する。
既存の管理対象全体へ `chezmoi apply` は実行しない。

LaunchAgent適用後は `launchctl print` で登録状態を確認する。
更新確認スクリプトを手動実行し、リモート更新がない場合に通知せず終了することを確認する。

## 失敗時の扱い

LaunchAgent登録に失敗した場合でも、更新確認スクリプトとChezmoi正本は保持する。
再登録スクリプトを修正し、plistを直接編集しない。

通知が不要になった場合は、LaunchAgentを `bootout` してからChezmoi正本のplistと再登録スクリプトを削除する。
キャッシュとログは自動削除しない。
