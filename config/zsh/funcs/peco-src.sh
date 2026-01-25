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

# checkout git branch with peco
function peco-gcop() {
  # Check if inside a git repository
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo -n "peco-gcop: Error: Not in a git repository" >&2
    zle accept-line
    return 1
  fi

  # Enable pipefail to catch errors in pipeline
  setopt local_options pipefail

  # Get current branch for highlighting
  local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)

  # Create temporary files for branch categorization
  local tmp_file=$(mktemp)
  local wt_file=$(mktemp)
  local base_file=$(mktemp)

  # Set up trap to ensure cleanup on function exit
  trap "rm -f '$tmp_file' '$wt_file' '$base_file'" EXIT

  git branch --format="%(refname:short)" > "$tmp_file"

  # Determine the main worktree path
  local git_common_dir=$(git rev-parse --git-common-dir)
  local main_wt_path
  if [[ "$git_common_dir" == ".git" ]]; then
    # Currently in the main worktree
    main_wt_path=$(git rev-parse --show-toplevel)
  else
    # Currently in an added worktree
    main_wt_path=$(dirname "$git_common_dir")
  fi
  local current_wt_path=$(git rev-parse --show-toplevel)

  # Build worktree map: branch -> path
  typeset -A worktree_map
  local current_path=""
  while IFS= read -r line; do
    if [[ $line =~ ^worktree\ (.+)$ ]]; then
      current_path="${match[1]}"
    elif [[ $line =~ ^branch\ refs/heads/(.+)$ ]]; then
      worktree_map[${match[1]}]="$current_path"
    fi
  done < <(git worktree list --porcelain)

  # Write worktree branches to files for Perl script, categorizing as BASE or worktree
  for branch in ${(k)worktree_map}; do
    local wt_path="${worktree_map[$branch]}"
    if [[ "$wt_path" == "$current_wt_path" ]]; then
      # Current worktree's branch - skip (will be marked as current)
      continue
    elif [[ "$wt_path" == "$main_wt_path" ]]; then
      # Main worktree's branch
      echo "$branch" >> "$base_file"
    else
      # Added worktree's branch
      echo "$branch" >> "$wt_file"
    fi
  done

  # List and format branches
  local selected_branch=$(
    git branch -a --sort=refname |
      grep -v -e '->' |
      perl -pe 's/^\h+//g' |
      perl -pe 's/^\* (.*)$/\1 (current)/' |
      perl -pe 's/^\+ //' |
      perl -pe 's#^remotes/origin/##' |
      perl -nle 'print if !$c{$_}++' |
      perl -e '
        open(my $fh, "<", "'"$tmp_file"'") or die;
        my %locals = map { chomp; $_ => 1 } <$fh>;
        close($fh);
        open(my $wt, "<", "'"$wt_file"'") or die;
        my %worktrees = map { chomp; $_ => 1 } <$wt>;
        close($wt);
        open(my $base, "<", "'"$base_file"'") or die;
        my %bases = map { chomp; $_ => 1 } <$base>;
        close($base);
        my %seen;
        my @lines = <>;
        # First pass: collect current branch names
        for (@lines) {
          chomp;
          if (/^(.+) \(current\)$/) {
            $seen{$1} = 1;
          }
        }
        # Second pass: output with tags
        for (@lines) {
          chomp;
          if (/\(current\)$/) {
            print "$_\n";
          } else {
            my $branch_name = $_;
            next if $seen{$branch_name};  # Skip if already shown as current
            $seen{$branch_name} = 1;      # Mark as seen
            if ($bases{$branch_name}) {
              print "$branch_name (BASE)\n";
            } elsif ($worktrees{$branch_name}) {
              print "$branch_name (worktree)\n";
            } elsif ($locals{$branch_name}) {
              print "$branch_name (local)\n";
            } else {
              print "$branch_name\n";
            }
          }
        }
      ' |
      peco --query "$LBUFFER" --prompt="BRANCH>"
  )

  # Check if a branch was selected
  if [ -n "$selected_branch" ]; then
    if [[ $selected_branch == *"(BASE)"* || $selected_branch == *"(worktree)"* ]]; then
      # Extract branch name and navigate to worktree directory
      local branch_name=$(echo "$selected_branch" | perl -pe 's/ \((BASE|worktree)\)$//')
      local wt_path="${worktree_map[$branch_name]}"
      BUFFER="cd '${wt_path}'"
      zle accept-line
    else
      # Remove status suffixes if present
      selected_branch=$(echo "$selected_branch" | perl -pe 's/ \((current|local)\)$//')

      # Set the command to the buffer and execute it
      BUFFER="git checkout ${selected_branch}"
      zle accept-line
    fi
  else
    zle clear-screen
  fi

  # Trap will handle cleanup automatically
}
zle -N peco-gcop
bindkey '^[' peco-gcop
