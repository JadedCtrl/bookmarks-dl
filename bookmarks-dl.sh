#!/bin/sh
#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# Name: bookmarks-dl
# Desc: A script used to download remote bookmarks into the XBEL format.
# Auth: Jaidyn Ann <jadedctrl@posteo.at>
# Date: 2023-09-02
# Reqs: lynx, jq
# Lisc: GPLv3
#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

SOURCE_DIRS="./sources/ $HOME/.local/libexec/bookmarks-dl/ /usr/local/libexec/bookmarks-dl/ /usr/libexec/bookmarks-dl/"

usage() {
	1>&2 echo "usage: $(basename "$0") SOURCE ..."
	1>&2 echo "       $(basename "$0") --list"
	1>&2 echo "       $(basename "$0") --help"
	1>&2 echo ""
	1>&2 echo "  SOURCE is a source of bookmarks."
	1>&2 echo "  You can see a list of sources with '--list'."
}


# Return the paths to all available bookmarks-dl “source” scripts.
all_sources() {
	find $SOURCE_DIRS -type f -name '*.sh' \
		 2> /dev/null
}


# Return the path to a specific bookmarks-dl source.
get_source() {
	local source_name="$1"
	all_sources \
		| grep "/$source_name.sh" \
		| head -1
}


# List all available bookmarks-dl sources user-friendly-like.
list_sources() {
	for source in $(all_sources); do
		printf '%s\t%s\n' \
			   "$(basename "$source" | sed 's/\.sh//')" \
			   "$source"
	done
}


# Given some HTML, return it’s plain-text and deescaped form.
html_text_deescape() {
	lynx -dump -stdin
}


# Print a piped string in HTML-escaped form.
html_escape() {
	json_escape \
		| jq -r '. | @html'
}


# Print a piped string in JSON-escaped format.
json_escape() {
	sed 's!"!\\"!g' \
		| perl -pe 's!\n!\\n!' \
		| sed 's/^/"/' \
		| sed 's/$/"/'
}


SOURCE_NAME="$1"
case "$SOURCE_NAME" in
	--list|list)
		list_sources
		exit 0
		;;
	--help|-h|help|'')
		usage
		exit 1
		;;
	*)
		source "$(get_source "$SOURCE_NAME")" \
			   2> /dev/null > /dev/null
		if test "$?" -ne 0; then
			1>&2 echo "The source '$SOURCE_NAME' couldn’t be found."
			1>&2 echo "Try '$(basename "$0") --list' to see a list of possible sources."
		fi
		;;
esac


if test -z "$1"; then
	usage
	exit 1
else
	shift
fi


# Overloaded by the `source`-d bookmarks-dl “source.”
source_start $@
