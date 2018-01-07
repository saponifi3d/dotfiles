.PHONY: install # Symlinks all the configuration files
install: bash git vim

.PHONY: bash # Add a "source .bash_profile" to the top level bash_profile
bash:
	echo "source $(DOTFILES)/configs/bash/.bash_profile" >> ~/.bash_profile

.PHONY: git # Add git configurations to the top level
git:
	ln -s $(DOTFILES)/configs/git/.gitconfig ~/.gitconfig
	ln -s $(DOTFILES)/configs/git/.gitexcludes ~/.gitexlcudes

.PHONY: vim # Add vimrc file to the top level
vim:
	ln -s $(DOTFILES)/configs/vim/.vimrc ~/.vimrc
