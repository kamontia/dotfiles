#!/usr/bin/env bash
set -eu

if [ "$#" -ne 1 ]; then
  echo "usage: open-diffview.sh <relative-path>" >&2
  exit 1
fi

relative_path="$1"

if ! command -v nvim >/dev/null 2>&1; then
  echo "nvim is not installed or not in PATH" >&2
  exit 1
fi

if ! repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  echo "current directory is not inside a git repository" >&2
  exit 1
fi

cd "$repo_root"
LAZYGIT_DIFFVIEW_PATH="$relative_path" \
  exec nvim -c 'lua vim.cmd("DiffviewOpen -- " .. vim.fn.fnameescape(vim.env.LAZYGIT_DIFFVIEW_PATH))'
