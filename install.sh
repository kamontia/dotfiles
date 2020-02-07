#!/bin/zsh

function isCmdOK(){
  type "$1" >/dev/null 2>&1;
}

function die(){
  echo $@ >&2
  exit 1
}


#######################
# USER CONFIGURATION
#######################
DOTPATH=~/.dotfiles
GITHUB_URL="git@github.com:kamontia/dotfiles.git"


# ---------------------

if $(isCmdOK git); then

  git clone --recursive "$GITHUB_URL" "$DOTPATH"

elif $(isCmdOK curl) || $(isCmdOK wget);then
  mkdir -p "$DOTPATH"
  tarball="https://github.com/kamontia/dotfiles/archive/master.tar.gz"

  if $(isCmdOK curl); then
     curl -L "$tarball"
  else
     wget -O - "$tarball"
  fi | tar zxv

  mv -f dotfiles-master "$DOTPATH"
else
  die "curl or wget required"
fi

#cd $DOTPATH

#if [ $? -ne 0 ]; then
#  die "Not found: $DOTPATH"
#fi



function deploy() {
   for file in .??*
   do
     [[ "$file" == ".git" ]] && continue
     [[ "$file" == ".DS_Store" ]] && continue

     echo "ln -sfvn ${file} ${HOME}/${file}"
     ln -sfvn $(realpath ${file}) ${HOME}/${file}
   done
}

function install() {
   echo "INITIALIZATION START ..."

   echo "Zplugin ..."
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"

   echo "anyenv ..."
   git clone https://github.com/anyenv/anyenv ~/.anyenv
   echo 'export PATH="$HOME/.anyenv/bin:$PATH"' >> ~/.zshrc
   ~/.anyenv/bin/anyenv init
   anyenv install --init
   echo 'eval "$(anyenv init -)"' >> ~/.zshrc

   echo "zprezto ..."
   git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"

   setopt EXTENDED_GLOB
   for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
     ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
   done

   git clone https://github.com/powerline/fonts.git --depth=1
   pushd fonts
   ./install.sh
   popd

   #echo "Icons ..."
   #git clone https://github.com/ryanoasis/nerd-fonts.git ~/.nerd-fonts
   #pushd ~/.nerd-fonts
   #./install.sh

   echo "Vim Plugins ..."
   git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
   sh ~/.vim_runtime/install_awesome_vimrc.sh

   curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

   echo "Tmux plugin manager ..."
   git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
   echo "Press 'Prefix + I' in tmux"

   echo "the fuck ..."
   pip install thefuck
   eval $(thefuck --alias) >> ~.zshrc

   #echo "Installing Ansible"
   #pip install --user git+https://github.com/ansible/ansible.git

   echo "Installing Packages via Ansible"


   echo "END"
}


if [ "$1" = "deploy" -o "$1" = "-d" ]; then
    deploy
elif [ "$1" = "init" -o "$1" = "-i" ]; then
    install
fi
