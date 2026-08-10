#!/bin/sh

set -eu

PI_SHA=${PI_SHA:?PI_SHA is required}
PI_REPO=${PI_REPO:-https://github.com/earendil-works/pi.git}
PI_CONFIG=${PI_CONFIG:?PI_CONFIG is required}
PI_AGENT=${PI_AGENT:-"$HOME/.pi/agent"}
PI_SRC=${PI_SRC:-"$HOME/.pi/src/pi"}
PI_UPSTREAM="$PI_SRC/packages/coding-agent/examples/extensions"

UPSTREAM_FILES="git-checkpoint.ts permission-gate.ts protected-paths.ts status-line.ts todo.ts"
UPSTREAM_DIRS="plan-mode subagent"
CUSTOM_EXTENSIONS="vim-editor.ts"

fail() {
	printf 'FAIL: %s\n' "$*" >&2
	exit 1
}

link_managed() {
	source_path=$1
	destination=$2

	if [ -L "$destination" ]; then
		current=$(readlink "$destination")
		[ "$current" = "$source_path" ] || fail "$destination points to unexpected target $current."
	elif [ -e "$destination" ]; then
		fail "$destination already exists and was left unchanged."
	else
		ln -s "$source_path" "$destination"
		printf 'linked %s\n' "$destination"
	fi
}

check_managed_link() {
	source_path=$1
	destination=$2

	[ -L "$destination" ] || fail "expected $destination to be a symlink."
	[ "$(readlink "$destination")" = "$source_path" ] || fail "expected $destination -> $source_path."
	[ -e "$destination" ] || fail "$destination is dangling."
}

unlink_managed() {
	source_path=$1
	destination=$2

	if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source_path" ]; then
		rm "$destination"
		printf 'unlinked %s\n' "$destination"
	fi
}

check_config() {
	[ -f "$PI_CONFIG/settings.json" ] || fail "settings.json is missing."
	[ -f "$PI_CONFIG/keybindings.json" ] || fail "keybindings.json is missing."
	[ -d "$PI_CONFIG/themes" ] || fail "themes are missing."
	[ -f "$PI_CONFIG/extensions/vim-editor.ts" ] || fail "vim-editor.ts is missing."

	for name in $UPSTREAM_FILES $UPSTREAM_DIRS; do
		[ ! -e "$PI_CONFIG/extensions/$name" ] || fail "upstream extension $name is vendored in configs/pi."
	done

	links=$(find "$PI_CONFIG" -type l -print)
	[ -z "$links" ] || fail "tracked pi configuration contains symlinks:\n$links"

	if grep -R -n -E '(/Users/|/home/|~/src/)' "$PI_CONFIG" --include='*.json' 2>/dev/null; then
		fail "machine-specific paths found in configs/pi."
	fi

	for path in auth.json trust.json sessions npm git models-store.json mcp-cache.json; do
		[ ! -e "$PI_CONFIG/$path" ] || fail "runtime state found at configs/pi/$path."
	done

	if grep -R -n -E '(sk-[A-Za-z0-9_-]{16,}|Bearer[[:space:]]+[A-Za-z0-9._-]{16,}|"(apiKey|api_key|accessToken|refreshToken)"[[:space:]]*:)' "$PI_CONFIG" 2>/dev/null; then
		fail "possible credential material found in configs/pi."
	fi

	printf 'configs/pi is portable and contains only custom configuration.\n'
}

install_source() {
	mkdir -p "$(dirname "$PI_SRC")" "$PI_AGENT"

	if [ ! -d "$PI_SRC/.git" ]; then
		[ ! -e "$PI_SRC" ] || fail "$PI_SRC exists but is not a git checkout."
		git clone --filter=blob:none --sparse "$PI_REPO" "$PI_SRC"
	fi

	[ "$(git -C "$PI_SRC" remote get-url origin)" = "$PI_REPO" ] || fail "$PI_SRC has an unexpected origin."
	git -C "$PI_SRC" sparse-checkout set packages/coding-agent/examples/extensions
	git -C "$PI_SRC" fetch --quiet origin
	git -C "$PI_SRC" cat-file -e "$PI_SHA^{commit}" 2>/dev/null || fail "revision $PI_SHA was not found in $PI_REPO."
	git -C "$PI_SRC" checkout --quiet --detach --force "$PI_SHA"
}

remove_legacy_links() {
	for name in AGENTS.md prompts; do
		destination="$PI_AGENT/$name"
		legacy_source="$PI_CONFIG/$name"
		if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$legacy_source" ] && [ ! -e "$legacy_source" ]; then
			rm "$destination"
			printf 'removed legacy dangling link %s\n' "$destination"
		fi
	done
}

prepare_extensions_directory() {
	if [ -L "$PI_AGENT/extensions" ]; then
		current=$(readlink "$PI_AGENT/extensions")
		if [ "$current" = "$PI_CONFIG/extensions" ]; then
			rm "$PI_AGENT/extensions"
		else
			fail "$PI_AGENT/extensions points to unexpected target $current."
		fi
	elif [ -e "$PI_AGENT/extensions" ] && [ ! -d "$PI_AGENT/extensions" ]; then
		fail "$PI_AGENT/extensions exists but is not a directory."
	fi

	mkdir -p "$PI_AGENT/extensions"
}

install_links() {
	link_managed "$PI_CONFIG/settings.json" "$PI_AGENT/settings.json"
	link_managed "$PI_CONFIG/keybindings.json" "$PI_AGENT/keybindings.json"
	link_managed "$PI_CONFIG/themes" "$PI_AGENT/themes"

	for name in $UPSTREAM_FILES $UPSTREAM_DIRS; do
		link_managed "$PI_UPSTREAM/$name" "$PI_AGENT/extensions/$name"
	done

	for name in $CUSTOM_EXTENSIONS; do
		link_managed "$PI_CONFIG/extensions/$name" "$PI_AGENT/extensions/$name"
	done
}

verify_install() {
	[ -d "$PI_SRC/.git" ] || fail "pi source checkout is missing."
	[ "$(git -C "$PI_SRC" rev-parse HEAD)" = "$PI_SHA" ] || fail "pi source checkout is at the wrong revision."

	check_managed_link "$PI_CONFIG/settings.json" "$PI_AGENT/settings.json"
	check_managed_link "$PI_CONFIG/keybindings.json" "$PI_AGENT/keybindings.json"
	check_managed_link "$PI_CONFIG/themes" "$PI_AGENT/themes"

	for name in $UPSTREAM_FILES $UPSTREAM_DIRS; do
		check_managed_link "$PI_UPSTREAM/$name" "$PI_AGENT/extensions/$name"
	done

	for name in $CUSTOM_EXTENSIONS; do
		check_managed_link "$PI_CONFIG/extensions/$name" "$PI_AGENT/extensions/$name"
	done

	printf 'Pi checkout and configuration links verified.\n'
}

remove_links() {
	unlink_managed "$PI_CONFIG/settings.json" "$PI_AGENT/settings.json"
	unlink_managed "$PI_CONFIG/keybindings.json" "$PI_AGENT/keybindings.json"
	unlink_managed "$PI_CONFIG/themes" "$PI_AGENT/themes"

	for name in $UPSTREAM_FILES $UPSTREAM_DIRS; do
		unlink_managed "$PI_UPSTREAM/$name" "$PI_AGENT/extensions/$name"
	done

	for name in $CUSTOM_EXTENSIONS; do
		unlink_managed "$PI_CONFIG/extensions/$name" "$PI_AGENT/extensions/$name"
	done

	printf 'Managed links removed; machine-local runtime state was left unchanged.\n'
}

case ${1:-} in
check)
	check_config
	;;
install)
	check_config
	install_source
	remove_legacy_links
	prepare_extensions_directory
	install_links
	verify_install
	;;
verify)
	verify_install
	;;
unlink)
	remove_links
	;;
*)
	fail "usage: $0 {check|install|verify|unlink}"
	;;
esac
