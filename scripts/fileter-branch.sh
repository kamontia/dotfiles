#!/usr/bin/env bash

FIX_NAME="Tatsuya Kamohara"
FIX_EMAIL="kamontia@gmail.com"
CORRECT_NAME="Tatsuya Kamohara"
CORRECT_EMAIL="17017563+kamontia@users.noreply.github.com"

if ! git log --pretty=format:"%an %ae %cn %cn"|grep -q -e "$FIX_NAME" -e "$FIX_EMAIL";then
  exit
fi

git filter-branch -f --env-filter "
if [ \"\$GIT_AUTHOR_NAME\" = \"$FIX_NAME\" ] || [ \"\$GIT_AUTHOR_EMAIL\" = \"$FIX_EMAIL\" ];then
    export GIT_AUTHOR_NAME=\"$CORRECT_NAME\"
    export GIT_AUTHOR_EMAIL=\"$CORRECT_EMAIL\"
fi
if [ \"\$GIT_COMMITTER_NAME\" = \"$FIX_NAME\" ] || [ \"\$GIT_COMMITTER_EMAIL\" = \"$FIX_EMAIL\" ];then
    export GIT_COMMITTER_NAME=\"$CORRECT_NAME\"
    export GIT_COMMITTER_EMAIL=\"$CORRECT_EMAIL\"
fi
" --tag-name-filter cat -- --branches --tags
