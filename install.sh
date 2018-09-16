#!/bin/bash


for file in .??*
do
  [[ "$file" == ".git" ]] && continue
  [[ "$file" == ".DS_Store" ]] && continue

  echo "ln -s $(realpath ${file}) ${HOME}/${file}"
  ln -s $(realpath ${file} ${HOME}/${file})
done