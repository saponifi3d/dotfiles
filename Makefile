# Help command to see all available things.
help:
	@echo "Available commands:"
	@echo
	@cat $(MAKEFILE_LIST) | grep '^\.PHONY' | sed -e 's/\.PHONY\:/  /' | column -t -c 100 -s '#' | sed -e 's/#//'
	@echo

# Internal message to show
msg:
	echo "Already installed."

.PHONY: install # Symlinks all the configuration files
install: bash brew git vim

## DISABLED COMMANDS
# code_complete ctags

.PHONY: screen_saver # Installs the Aerial screen saver from brew
screen_saver:
	brew install --cask aerial

.PHONY: bash # Add a "source .bash_profile" to the top level bash_profile
bash:
	echo "source $(DOTFILES)/configs/bash/.bash_profile" >> ~/.bash_profile

.PHONY: ctags # Add and configure ctags
ctags:
	brew install --HEAD universal-ctags/universal-ctags/universal-ctags
	ln -s $(DOTFILES)/configs/ctags/.ctags ~/.ctags || make msg
	git clone https://github.com/ludovicchabant/vim-gutentags.git ~/.vim/bundle/vim-gutentags || make msg

.PHONY: code_complete # Add configurations to use the `code` command with tab completion
code_complete:
	brew install bash-completion || brew upgrade bash-completion
	npm link "$(DOTFILES)/configs/bash/code-tabtab"
	echo "source ~/.bashrc" >> ~/.bash_profile

.PHONY: git # Add git configurations to the top level
git:
	brew install git || brew upgrade git
	ln -s $(DOTFILES)/configs/git/.gitconfig ~/.gitconfig || make msg
	ln -s $(DOTFILES)/configs/git/.gitexcludes ~/.gitexlcudes || make msg
	curl -o ~/.git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh

.PHONY: brew # Install any additional brew packages regularly used
brew:
	brew install wget || brew upgrade wget
	brew install tree || brew upgrade tree
	brew install ag || brew upgrade ag
	brew install fzf || brew upgrade fzf
	brew install git-machete || brew upgrade git-machete

.PHONY: vim # Add vimrc file to the top level and install all vim plugins
vim:
	# Link vim config
	ln -s $(DOTFILES)/configs/vim/.vimrc ~/.vimrc || make msg

	# Install vim plugins
	curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim || make msg
