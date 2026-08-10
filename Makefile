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
install: bash brew git vim pi

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


# >>> pi coding agent — managed by pi-sync.sh, edits will be overwritten
PI_SHA := ac4ac9eaf69f2b01ca3af984a5c48f3b99b84278
PI_EXAMPLES := git-checkpoint todo permission-gate protected-paths notify \
               status-line confirm-destructive dirty-repo-guard
PI_CONFIG := $(DOTFILES)/configs/pi
PI_AGENT  := $(HOME)/.pi/agent

.PHONY: pi # Install the pi coding agent and link its configuration
pi: pi_check
	npm install -g --ignore-scripts @earendil-works/pi-coding-agent || make msg
	mkdir -p $(PI_AGENT)
	ln -s $(PI_CONFIG)/settings.json $(PI_AGENT)/settings.json || make msg
	ln -s $(PI_CONFIG)/keybindings.json $(PI_AGENT)/keybindings.json || make msg
	ln -s $(PI_CONFIG)/AGENTS.md $(PI_AGENT)/AGENTS.md || make msg
	ln -s $(PI_CONFIG)/themes $(PI_AGENT)/themes || make msg
	ln -s $(PI_CONFIG)/extensions $(PI_AGENT)/extensions || make msg
	ln -s $(PI_CONFIG)/prompts $(PI_AGENT)/prompts || make msg
	@echo
	@echo "Linked what was missing. Existing files were left alone."
	@echo "Verify with: pi config"

.PHONY: pi_check # Verify configs/pi is self-contained and portable
pi_check:
	@test -d "$(PI_CONFIG)/extensions" || { \
	  echo "FAIL: $(PI_CONFIG)/extensions missing. Run pi-sync.sh (or make pi_vendor)."; exit 1; }
	@n=`find "$(PI_CONFIG)/extensions" -maxdepth 1 -name '*.ts' | wc -l | tr -d ' '`; \
	 d=`find "$(PI_CONFIG)/extensions" -maxdepth 2 -name 'index.ts' | wc -l | tr -d ' '`; \
	 t=`expr $$n + $$d`; echo "loadable extensions committed: $$t"; \
	 if [ "$$t" -eq 0 ]; then \
	   echo "FAIL: no extensions in the repo. pi would load nothing."; exit 1; fi
	@l=`find "$(PI_CONFIG)" -type l | wc -l | tr -d ' '`; \
	 if [ "$$l" -ne 0 ]; then \
	   echo "FAIL: $$l symlink(s) inside configs/pi — these break on a new machine:"; \
	   find "$(PI_CONFIG)" -type l; exit 1; fi
	@if grep -rq -E '(/Users/|/home/|~/src/)' "$(PI_CONFIG)" --include='*.json' 2>/dev/null; then \
	   echo "FAIL: machine-specific paths in configs/pi:"; \
	   grep -rn -E '(/Users/|/home/|~/src/)' "$(PI_CONFIG)" --include='*.json'; exit 1; fi
	@echo "configs/pi is self-contained."

.PHONY: pi_vendor # Re-vendor pi's upstream example extensions at PI_SHA
pi_vendor:
	rm -rf /tmp/pi-vendor
	git clone --filter=blob:none --sparse https://github.com/earendil-works/pi.git /tmp/pi-vendor
	cd /tmp/pi-vendor && git sparse-checkout set packages/coding-agent/examples/extensions && git checkout $(PI_SHA)
	mkdir -p $(PI_CONFIG)/extensions
	for f in $(PI_EXAMPLES); do \
	  cp /tmp/pi-vendor/packages/coding-agent/examples/extensions/$$f.ts $(PI_CONFIG)/extensions/; done
	rm -rf $(PI_CONFIG)/extensions/subagent
	cp -R /tmp/pi-vendor/packages/coding-agent/examples/extensions/subagent $(PI_CONFIG)/extensions/
	rm -rf /tmp/pi-vendor
	@echo "Vendored at $(PI_SHA)."

.PHONY: pi_unlink # Remove pi symlinks, leaving real files, sessions and auth intact
pi_unlink:
	for f in settings.json keybindings.json AGENTS.md themes extensions prompts; do \
	  if [ -L "$(PI_AGENT)/$$f" ]; then rm -f "$(PI_AGENT)/$$f"; echo "unlinked $$f"; fi; done
	@echo "Only symlinks were removed. Real files, auth.json and sessions/ untouched."
# <<< pi coding agent
