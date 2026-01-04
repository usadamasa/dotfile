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

  # Create temporary file for local branches
  local tmp_file=$(mktemp)

  # Set up trap to ensure cleanup on function exit
  trap "rm -f '$tmp_file'" EXIT

  git branch --format="%(refname:short)" > "$tmp_file"

  # List and format branches
  local selected_branch=$(
    git branch -a --sort=refname |
      grep -v -e '->' |
      perl -pe 's/^\h+//g' |
      perl -pe 's/^\* (.*)$/\1 (current)/' |
      perl -pe 's#^remotes/origin/##' |
      perl -nle 'print if !$c{$_}++' |
      perl -e '
        open(my $fh, "<", "'"$tmp_file"'") or die;
        my %locals = map { chomp; $_ => 1 } <$fh>;
        close($fh);
        while (<>) {
          chomp;
          if (/\(current\)$/) {
            print "$_\n";
          } else {
            my $branch_name = $_;
            if ($locals{$branch_name}) {
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
    # Remove status suffixes if present
    selected_branch=$(echo "$selected_branch" | perl -pe 's/ \((current|local)\)$//')

    # Set the command to the buffer and execute it
    BUFFER="git checkout ${selected_branch}"
    zle accept-line
  else
    zle clear-screen
  fi

  # Trap will handle cleanup automatically
}
zle -N peco-gcop
bindkey '^[' peco-gcop
