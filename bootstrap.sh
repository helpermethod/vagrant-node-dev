#!/usr/bin/env bash

readonly nvm_version=v0.20.0

main() {
	local release=stable
	local harmony=false
	local vim=false

	for arg; do
		case $arg in
			--unstable)
				release=unstable
				;;
			--harmony)
				harmony=true
				;;
			--vim)
				vim=true
				;;
			--all)
				release=unstable
				harmony=true
				vim=true
			-*)
				printf "%s: invalid option -- '%s'\n" 'bootstrap.sh' "${arg*-}"
				;;	
			*)
				break
		esac
	done

	sudo apt-get update
	sudo apt-get install -y git

	__setup_node "$release" "$harmony"
	[[ $vim == true ]] && __setup_vim || true
}

__setup_node() {
	local release=$1
	local harmony=$2

	curl --silent https://raw.githubusercontent.com/creationix/nvm/"$nvm_version"/install.sh | sh
	. ~/.nvm/nvm.sh

	# runs node with all harmony flags enabled by default
	[[ $harmony == true ]] && printf "alias node='node --harmony'\n" >> ~/.bashrc

	nvm install "$release"

	# enables tab completion for nvm
	printf '[[ -r "$NVM_DIR"/bash_completion ]] && . "$NVM_DIR"/bash_completion\n' >> ~/.bashrc

	__setup_global_node
	nvm use system

	# enables tab completion for npm
	printf '. <(npm completion)\n' >> ~/.bashrc
}

__setup_global_node() {
	local node_path=$(which node)
	node_path=${node_path%/bin/node}
	chmod -R 755 "$node_path"/bin/* 
	sudo cp -r "$node_path"/{bin,lib,share} /usr/local
}

__setup_vim() {
	git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
	cp /vagrant/.vimrc ~
	vim +PluginInstall +qall

	sudo npm install -g jshint
	__setup_you_complete_me
	(cd ~/.vim/bundle/tern_for_vim && npm install)
}

__setup_you_complete_me() {
	sudo apt-get install -y build-essential cmake python-dev
	# prevents running out of memory when compiling YouCompleteMe
	__create_swap
	(cd ~/.vim/bundle/YouCompleteMe && ./install.sh)
	__delete_swap
}

__create_swap() {
	sudo fallocate -l 1G /swap
	sudo mkswap /swap
	sudo swapon /swap
}

__delete_swap() {
	sudo swapoff -a
	sudo rm -f /swap
}

main "$@"
