setopt hist_ignore_all_dups     # ヒストリに追加されるコマンド行が古いものと同じなら古いものを削除
setopt hist_ignore_dups         # 直前と同じコマンドの場合は履歴に追加しない
setopt hist_ignore_space        # スペースから始まるコマンド行はヒストリに残さない
setopt hist_no_store            # historyコマンドは履歴に登録しない
setopt hist_reduce_blanks       # ヒストリに保存するときに余分なスペースを削除する
setopt hist_save_no_dups        # 古いコマンドと同じものは無視
setopt inc_append_history       # 履歴をインクリメンタルに追加
setopt share_history            # 同時に起動したzshの間でヒストリを共有する
