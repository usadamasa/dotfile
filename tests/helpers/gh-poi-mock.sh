#!/usr/bin/env bash
# gh poi のモック

# マーカーファイルを使用してgh poiの呼び出しを追跡
# (runコマンドがサブシェルで実行されるため、環境変数では追跡できない)

setup_gh_poi_mock() {
  GH_POI_MARKER_FILE=$(mktemp)
  export GH_POI_MARKER_FILE
}

cleanup_gh_poi_mock() {
  [ -n "$GH_POI_MARKER_FILE" ] && rm -f "$GH_POI_MARKER_FILE"
  unset GH_POI_MARKER_FILE
}

gh_poi_was_called() {
  [ -f "$GH_POI_MARKER_FILE" ] && grep -q "called" "$GH_POI_MARKER_FILE"
}

gh() {
  if [ "$1" = "poi" ]; then
    echo "called" > "$GH_POI_MARKER_FILE"
    return 0
  fi
  command gh "$@"
}
export -f gh
