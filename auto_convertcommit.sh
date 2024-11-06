#!/bin/bash

# Split words on newline
IFS=$'\n'

# Ensure in directory where this script is
obsidian_dir="$(dirname $(realpath "$0"))"
cd "$obsidian_dir"

# Set commit message with date and time
commit_message="autoCommit $(date +'%Y%m%d.%H%M%S')"

# Create a unique temporary directory
tempdir=$(mktemp -d /tmp/obsidian_XXXXXX)

# Check if there is an existing worktree indicating the script exited prematurely
wstatus=$(git worktree list | awk '{print $1}' | tail -n 1)

if [[ "$wstatus" != "$obsidian_dir" ]]; then
  git worktree remove --force "$wstatus"
else
  # Check if files have changed or a push is pending; if not, do nothing
  gstatus=$(git status --porcelain)
  pstatus="$(($(git rev-list --count gitlab/master..master) +\
            + $(git rev-list --count gitlab/mdlinks..mdlinks)))"

  if [[ -z "$gstatus" ]] && [[ "$pstatus" -eq 0 ]]; then
    exit 0
  fi

  # Copy new files from the mdlinks branch
  for file in $(git diff --name-only --no-renames --diff-filter=A master mdlinks); do
    git checkout mdlinks -- "$file"
  done

  git add .
  # Commit changes from the master wikilinked branch
  git commit -m "$commit_message"

  # Integrate any updates from the master branch
  git pull gitlab master --rebase
  git push gitlab master
fi

# Create a temporary copy of mdlinks to convert updated files' wikilinks to markdown
git worktree add "$tempdir" mdlinks
cd "$tempdir" || exit

# Integrate updates from the markdown-linked branch
git pull gitlab mdlinks --rebase

# Clean up files that were deleted (including renamed) on master
for file in $(git diff --name-only --no-renames --diff-filter=D master~1 master); do
  rm -f "$file"
  git add "$file"
done

# Copy new files from the master branch
for file in $(git diff --name-only --no-renames --diff-filter=A mdlinks master); do
  # do not copy these files
  if [[ "$file" != "auto_convertcommit.*" ]] && [[ "$file" != "convert_to_gitlab.py" ]]; then
    git checkout master -- "$file"
  fi
done

# Convert links of updated markdown files in tempdir
for file in $(git diff --name-only master~1 master); do
  python3 "$obsidian_dir/convert_to_gitlab.py" "$file"
  git add "$file"
done

# Convert links in files linking to renamed or new files
for file in $(git diff --name-only --diff-filter=AR master~1 master); do
  for link in $(git grep -El "\[\[${file%%.*}((\||#).*)?\]\]" master); do
    python3 "$obsidian_dir/convert_to_gitlab.py" "$link"
    git add "$link"
  done
done

# Commit changes and push converted files to mdlinks branch
git commit -m "$commit_message"
git push gitlab mdlinks

# Remove temporary worktree
cd "$obsidian_dir" || exit
git worktree remove "$tempdir"
