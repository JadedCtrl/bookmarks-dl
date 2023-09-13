#!/bin/sh
#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# Name: bookmarks-dl
# Desc: A script used to download remote bookmarks into the XBEL format.
# Auth: Jaidyn Ann <jadedctrl@posteo.at>
# Date: 2023-09-02
# Reqs: lynx, jq, gsed
# Lisc: GPLv3
#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

SOURCE_DIRS="./sources/ $HOME/.local/libexec/bookmarks-dl/sources/ /usr/local/libexec/bookmarks-dl/sources/ /usr/libexec/bookmarks-dl/sources/"


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
	local script_name="$1"
	all_sources \
		| grep "/$script_name.sh" \
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


# The function called to parse arguments of a source and begin downloading
# bookmarks-dl.sh
# This should be overloaded by a “source” script.
source_start() {
	exit 4
}


# ————————————————————————————————————————
# MISC. UTILS
# ————————————————————————————————————————
# Trims preceding and trailing spaces of a string.
# Be warned: Uses extended regexps, a GNUism!
trim_spaces() {
	sed -E 's%^[[:space:]]+%%g' \
		| sed -E 's%[[:space:]]+$%%g'
}


# Given some HTML, return it’s plain-text and deescaped form.
html_text_deescape() {
	lynx -stdin -dump -nolist --assume_charset=utf8 --display_charset=utf8 \
		| trim_spaces
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


# In case we want to look (mostly) like a normal web-browser.
curl_browseresque() {
	curl $@ \
		--compressed \
		-H 'sec-ch-ua: "Not:A-Brand";v="99", "Chromium";v="112"' \
		-H 'sec-ch-ua-mobile: ?0' \
		-H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36' \
		-H 'sec-ch-ua-platform: "Linux"' \
		-H 'Accept: applincation/json' \
		-H 'Accept-Language: en-US,en;q=0.5' \
		-H 'Accept-Encoding: gzip, deflate, br' \
		-H 'DNT: 1' \
		-H 'Connection: keep-alive' \
		-H 'Sec-Fetch-Dest: empty' \
		-H 'Sec-Fetch-Mode: cors' \
		-H 'Sec-Fetch-Site: same-origin' \
		-H 'TE: trailers'
}


# ————————————————————————————————————————
# INVOCATION
# ————————————————————————————————————————
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
		SOURCE="$(get_source "$SOURCE_NAME")"
		if test -f "$SOURCE"; then
			source "$SOURCE"
		fi
		if test "$?" -ne 0 -o ! -f "$SOURCE"; then
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


# This should be overloaded.
source_start $@
