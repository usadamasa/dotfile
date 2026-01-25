# find repo with ghq
function peco-src () {
  # Check if ghq command exists
  if ! command -v ghq >/dev/null 2>&1; then
    echo "peco-src: Error: ghq is not installed" >&2
    zle reset-prompt
    return 1
  fi

  # Enable pipefail to catch errors in pipeline
  setopt local_options pipefail

  local selected_dir=$(ghq list -p | peco --query "$LBUFFER")
  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
}
zle -N peco-src
bindkey '^]' peco-src

# =============================================================================
# peco-gcop: checkout git branch with peco
# =============================================================================

# Core function: List branches with prefix symbols
# Outputs branch list to stdout with prefix symbols: @ * + # ~
_peco_gcop_list_branches() {
  # Check if inside a git repository
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "peco-gcop: Error: Not in a git repository" >&2
    return 1
  fi

  # Get current branch
  local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)

  # Create temporary files for branch categorization
  local tmp_file=$(mktemp)
  local wt_file=$(mktemp)
  local base_file=$(mktemp)

  # Set up trap to ensure cleanup (use EXIT for bash compatibility)
  trap "rm -f '$tmp_file' '$wt_file' '$base_file'" EXIT

  git branch --format="%(refname:short)" > "$tmp_file"

  # Determine the main worktree path
  local git_common_dir=$(git rev-parse --git-common-dir)
  local main_wt_path
  if [[ "$git_common_dir" == ".git" ]]; then
    main_wt_path=$(git rev-parse --show-toplevel)
  else
    main_wt_path=$(dirname "$git_common_dir")
  fi
  local current_wt_path=$(git rev-parse --show-toplevel)

  # Check if we are in a subworktree
  local is_subworktree="false"
  if [[ "$main_wt_path" != "$current_wt_path" ]]; then
    is_subworktree="true"
  fi

  # Get worktree branches using awk (bash compatible)
  git worktree list --porcelain 2>/dev/null | \
    awk -v main_wt="$main_wt_path" -v current_wt="$current_wt_path" '
      /^worktree / { wt = substr($0, 10) }
      /^branch / {
        branch = substr($0, 19)
        if (wt == current_wt) {
          # Current worktree - skip
        } else if (wt == main_wt) {
          print branch > "'"$base_file"'"
        } else {
          print branch > "'"$wt_file"'"
        }
      }
    '

  # List and format branches
  git branch -a --sort=refname | \
    grep -v -e '->' | \
    perl -pe 's/^[\h\*\+]+//g' | \
    perl -pe 's#^remotes/origin/##' | \
    perl -nle 'print if !$c{$_}++' | \
    perl -e '
      my $current = "'"$current_branch"'";
      my $is_subworktree = "'"$is_subworktree"'";
      open(my $fh, "<", "'"$tmp_file"'") or die;
      my %locals = map { chomp; $_ => 1 } <$fh>;
      close($fh);
      my %worktrees;
      if (open(my $wt, "<", "'"$wt_file"'")) {
        %worktrees = map { chomp; $_ => 1 } <$wt>;
        close($wt);
      }
      my %bases;
      if (open(my $base, "<", "'"$base_file"'")) {
        %bases = map { chomp; $_ => 1 } <$base>;
        close($base);
      }
      while (<>) {
        chomp;
        my $branch = $_;
        if ($branch eq $current && $is_subworktree eq "true") {
          print "@ $branch\n";
        } elsif ($branch eq $current) {
          print "* $branch\n";
        } elsif ($bases{$branch}) {
          print "# $branch\n";
        } elsif ($worktrees{$branch}) {
          print "+ $branch\n";
        } elsif ($locals{$branch}) {
          print "~ $branch\n";
        } else {
          print "  $branch\n";
        }
      }
    '
}

# Core function: Checkout branch or navigate to worktree
# $1: branch name (may include prefix symbol)
_peco_gcop_checkout() {
  local selected_branch="$1"

  # Remove prefix symbol to get branch name
  local branch_name=$(echo "$selected_branch" | perl -pe 's/^[*#+~@ ] //')

  # Check if this is a worktree branch
  local worktree_path=$(git worktree list --porcelain 2>/dev/null | \
    awk -v branch="$branch_name" '
      /^worktree / { wt = substr($0, 10) }
      /^branch / && substr($0, 19) == branch { print wt; exit }
    ')

  if [ -n "$worktree_path" ]; then
    # Worktree branch - set cd command to BUFFER
    BUFFER="cd '${worktree_path}'"
    return 0
  else
    # Normal checkout
    git checkout "$branch_name"
    return $?
  fi
}

# zle widget (UI layer)
function peco-gcop() {
  # Check if inside a git repository
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo -n "peco-gcop: Error: Not in a git repository" >&2
    zle accept-line
    return 1
  fi

  # Get branch list and select with peco
  local selected_branch=$(_peco_gcop_list_branches | peco --query "$LBUFFER" --prompt="BRANCH>")

  # Check if a branch was selected
  if [ -n "$selected_branch" ]; then
    if [[ $selected_branch == "#"* || $selected_branch == "+"* || $selected_branch == "@"* ]]; then
      # Worktree branch - use _peco_gcop_checkout to set BUFFER
      _peco_gcop_checkout "$selected_branch"
      zle accept-line
    else
      # Remove prefix symbol if present
      local branch_name=$(echo "$selected_branch" | perl -pe 's/^[*#+~@ ] //')

      # Set the command to the buffer and execute it
      BUFFER="git checkout ${branch_name}"
      zle accept-line
    fi
  else
    zle clear-screen
  fi
}
zle -N peco-gcop
bindkey '^[' peco-gcop
