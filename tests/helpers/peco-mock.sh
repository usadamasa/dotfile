#!/usr/bin/env bash
# peco のモック

# モックで返すブランチ名を設定
# $1: 選択されるブランチ名
PECO_MOCK_SELECTION=""

# peco のモック実装
# 入力をそのまま通過させるか、PECO_MOCK_SELECTION が設定されていればそれを返す
peco() {
  if [ -n "$PECO_MOCK_SELECTION" ]; then
    echo "$PECO_MOCK_SELECTION"
  else
    # 何も選択されなかった場合(キャンセル)
    return 0
  fi
}

export -f peco
