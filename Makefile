.PHONY: all help brew tools fonts dotfiles clean mac_setup

# デフォルトターゲット
all: brew tools mac_setup dotfiles fonts

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all       - Install everything including system defaults"
	@echo "  brew      - Install Homebrew"
	@echo "  tools     - Install CLI tools/Apps via Brewfile"
	@echo "  mac_setup - Configure macOS system defaults (Key repeat, Dock, etc.)"
	@echo "  dotfiles  - Apply dotfiles via chezmoi"
	@echo "  fonts     - Install Nerd Fonts"

# macOS System Defaults
mac_setup:
	@echo "Configuring macOS system defaults..."
	defaults write NSGlobalDomain KeyRepeat -int 2
	defaults write NSGlobalDomain InitialKeyRepeat -int 15
	defaults write com.apple.dock autohide -bool true
	defaults write com.apple.finder CreateDesktop -bool false
	defaults write com.apple.screencapture disable-shadow -bool true
	defaults write NSGlobalDomain AppleShowAllExtensions -bool true
	defaults write com.apple.CrashReporter DialogType -string "none"
	@echo "System settings applied. Some changes may require a logout/restart."

# Homebrewのインストール
brew:
	@if [ -z "$$(command -v brew)" ]; then \
		echo "Installing Homebrew..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		eval "$$(/opt/homebrew/bin/brew shellenv)"; \
	else \
		echo "Homebrew is already installed."; \
	fi

# Brewfileに基づくツールのインストール
tools: brew
	brew bundle --file=./Brewfile

# フォントのインストール
fonts: tools
	brew install --cask font-jetbrains-mono-nerd-font

# chezmoiによる設定の適用
dotfiles: tools
	@if [ ! -d "$$HOME/.local/share/chezmoi" ]; then \
		echo "Initializing chezmoi..."; \
		chezmoi init; \
	fi
	@echo "Applying dotfiles..."
	chezmoi apply -v