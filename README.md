# Redmine Issue Summary Filter Plugin

このプラグインは、Redmineのチケットサマリーページにフィルター機能を追加します。

## 機能

- チケットサマリーページでのフィルタリング
- 複数選択可能なフィルター
- フィルター設定の保存・読み込み
- レスポンシブデザイン

## インストール

1. プラグインを `plugins/redmine_issue_summary_filter` ディレクトリに配置
2. マイグレーションを実行してデータベーステーブルを作成
   ```bash
   bundle exec rake redmine:plugins:migrate NAME=redmine_issue_summary_filter RAILS_ENV=production
   ```
3. Redmineサーバーを再起動

> **注意**: プラグインは自動的に有効化されます。管理画面での有効化は不要です。

## アンインストール

### アンインストール手順

1. Redmineサーバーを停止
2. プラグインディレクトリを削除
   ```bash
   rm -rf plugins/redmine_issue_summary_filter
   ```
3. データベースからテーブルを削除
   
   **マイグレーションを使用する場合:**
   ```bash
   bundle exec rake redmine:plugins:migrate NAME=redmine_issue_summary_filter VERSION=0
   ```
   
   **またはSQLで直接削除する場合:**
   ```sql
   DROP TABLE IF EXISTS redmine_issue_summary_filter_settings;
   ```
4. Redmineサーバーを再起動

## 開発環境での使用方法

このリポジトリには開発環境用のWindowsバッチファイルが含まれています：

### バッチファイル一覧

| ファイル名 | 機能 | 説明 |
|-----------|------|------|
| **redmine_manager.bat** | メインメニュー | 統合管理スクリプト（起動・停止・再起動・ステータス確認を選択可能） |
| **start_redmine.bat** | サーバー起動 | Rubyプロセスを停止→待機→プラグインをコピー→マイグレーション実行→サーバー起動 |
| **stop_redmine.bat** | サーバー停止 | Rubyプロセスを停止 |

### 実行手順

1. **メニュー方式**（推奨）:
   ```bash
   redmine_manager.bat
   ```
   メニューから必要な操作を選択

2. **直接実行**:
   ```bash
   start_redmine.bat # サーバーを起動（または再起動）
   stop_redmine.bat # サーバーを停止
   ```

### 注意事項

- すべてのバッチファイルは `src` フォルダーを `../redmine/plugins/redmine_issue_summary_filter` にコピーします
- マイグレーションは自動的に実行されます
- サーバーは http://localhost:3000 で起動します
- デフォルトログイン: `admin` / `admin123`

## 使用方法

1. プロジェクトのレポートページにアクセス
2. フィルターパネルで条件を選択
3. 「フィルター適用」ボタンをクリック
4. 必要に応じて設定を保存・読み込み

## 設定

管理画面のプラグイン設定で以下を設定できます：

- フィルターの有効/無効
- フィルターパネルの表示/非表示
- デフォルトフィルターフィールド

## ライセンス

MIT License