# Redmine Issue Summary Filter Plugin

このプラグインは、Redmineのチケットサマリーページにフィルター機能を追加します。

## 機能

- チケットサマリーページでのフィルタリング
- 複数選択可能なフィルター
- フィルター設定の保存・読み込み
- レスポンシブデザイン

## インストール

1. プラグインを `plugins/redmine_issue_summary_filter` ディレクトリに配置
2. Redmineサーバーを再起動
3. 管理画面でプラグインを有効化

## アンインストール

### 自動アンインストール
```bash
ruby plugins/redmine_issue_summary_filter/uninstall.rb
```

### 手動アンインストール
1. `app/controllers/reports_controller.rb` を元に戻す
2. `app/views/reports/issue_report.html.erb` からフックを削除
3. プラグインディレクトリを削除
4. Redmineサーバーを再起動

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