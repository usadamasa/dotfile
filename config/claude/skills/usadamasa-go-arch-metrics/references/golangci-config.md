# .golangci.yml テンプレート (アーキテクチャメトリクス向け)

プロジェクトルートに `.golangci.yml` として配置する。

```yaml
# .golangci.yml
# アーキテクチャメトリクス向け golangci-lint 設定
# 参考: ソフトウェアアーキテクチャメトリクス (ISBN: 9784814400607)
version: "2"

linters:
  # デフォルト有効 linter を維持しつつ、メトリクス系を追加
  default: standard
  enable:
    # --- テスト可能性メトリクス ---
    # 認知的複雑度: コードの理解しやすさを数値化
    - gocognit
    # 循環複雑度: 分岐の多さを数値化 (McCabe)
    - gocyclo
    # 関数の長さ: 行数と文数の上限
    - funlen
    # ネストの深さ: if/for の入れ子レベル
    - nestif
    # --- 保守性メトリクス ---
    # 保守性指数: 複雑度・行数・Halstead の複合指標
    - maintidx
    # 到達不能コード: 実行されないコードの検出
    - deadcode
    # --- 高度な静的解析 ---
    # staticcheck は standard に含まれるが明示的に指定
    - staticcheck
    # --- 依存管理 ---
    # 禁止パッケージの import を防ぐ
    - depguard

linters-settings:
  # 認知的複雑度: 20 超えは要リファクタリング
  gocognit:
    min-complexity: 20

  # 循環複雑度: 20 超えは要リファクタリング
  gocyclo:
    min-complexity: 20

  # 関数の長さ
  funlen:
    lines: 100      # 行数上限
    statements: 60  # 文数上限 (コメント・空行除く)

  # ネストの深さ
  nestif:
    min-complexity: 5

  # 保守性指数: 20 未満は保守困難
  maintidx:
    under: 20

  # 禁止パッケージ設定 (プロジェクトに合わせてカスタマイズ)
  depguard:
    rules:
      # 例: sync/atomic より atomic パッケージを使う場合
      # no-sync-atomic:
      #   deny:
      #     - pkg: "sync/atomic"
      #       desc: "Use go.uber.org/atomic instead"

issues:
  # テストファイルは関数長・複雑度の制限を緩める
  exclude-rules:
    - path: "_test\\.go"
      linters:
        - funlen
        - gocognit
        - gocyclo
    # 生成コードは除外
    - path: ".*\\.pb\\.go"
      linters:
        - all
    - path: ".*_gen\\.go"
      linters:
        - all

  # 初期導入時: 既存違反を許容しつつ新規追加分のみチェック
  # new: true
  # new-from-rev: HEAD~1

  # 同一関数での複数 linter 報告をまとめる
  max-same-issues: 5
```

## カスタマイズガイド

### しきい値の調整

初期導入時は既存コードの最大値より少し上にしきい値を設定し、段階的に絞る:

```yaml
# 例: 既存コードの最大認知的複雑度が 45 の場合、まず 50 から始める
gocognit:
  min-complexity: 50
```

### 段階的な導入 (new-from-rev オプション)

既存違反を一度に修正するのが難しい場合は、新規コミット分のみチェックする:

```yaml
issues:
  new: true
  new-from-rev: main  # main ブランチとの差分のみ
```

### depguard でレイヤー間の直接依存を禁止する例

```yaml
depguard:
  rules:
    no-infra-in-domain:
      files:
        - "**/domain/**"
      deny:
        - pkg: "database/sql"
          desc: "Domain layer must not depend on infrastructure directly"
        - pkg: "github.com/your-org/app/infrastructure"
          desc: "Domain must not import infrastructure packages"
```
