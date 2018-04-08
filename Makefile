# Internal message to show
msg:
	echo "Already installed."

.PHONY: install # Symlinks all the configuration files
install: bash brew git vim code_complete ctags

.PHONY: bash # Add a "source .bash_profile" to the top level bash_profile
bash:
	echo "source $(DOTFILES)/configs/bash/.bash_profile" >> ~/.bash_profile

ctags:
	brew install --HEAD universal-ctags/universal-ctags/universal-ctags
	ln -s $(DOTFILES)/configs/ctags/.ctags ~/.ctags || make msg

generate_ctags:
	echo "TODO, run `ctags -a -R .`"

code_complete:
	brew install bash-completion || brew upgrade bash-completion
	npm link "$(DOTFILES)/configs/bash/code-tabtab"
	echo "source ~/.bashrc" >> ~/.bash_profile

.PHONY: git # Add git configurations to the top level
git:
	brew install git || brew upgrade git
	ln -s $(DOTFILES)/configs/git/.gitconfig ~/.gitconfig || make msg
	ln -s $(DOTFILES)/configs/git/.gitexcludes ~/.gitexlcudes || make msg

.PHONY: brew # Install any additional brew packages
brew:
	brew install wget || brew upgrade wget
	brew install tree || brew upgrade tree
	brew install ag || brew upgrade ag

.PHONY: vim # Add vimrc file to the top level
vim:
	# Link vim config
	ln -s $(DOTFILES)/configs/vim/.vimrc ~/.vimrc || make msg

	# Create vim directories
	mkdir -p ~/.vim ~/.vim/autoload ~/.vim/bundle

	# Install vim plugins
	curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim || make msg
	git clone https://github.com/wincent/command-t.git ~/.vim/bundle/command-t || make msg
	git clone https://github.com/w0rp/ale.git ~/.vim/bundle/ale || make msg
	git clone https://github.com/rking/ag.vim ~/.vim/bundle/ag || make msg
	git clone https://github.com/scrooloose/nerdtree.git ~/.vim/bundle/nerdtree || make msg
	git clone https://github.com/vim-airline/vim-airline ~/.vim/bundle/vim-airline || make msg
	git clone https://github.com/tpope/vim-fugitive.git ~/.vim/bundle/vim-fugitive || make msg
	git clone https://github.com/mxw/vim-jsx.git ~/.vim/bundle/vim-jsx || make msg
	git clone https://github.com/leafgarland/typescript-vim.git ~/.vim/bundle/typescript-vim || make msg
