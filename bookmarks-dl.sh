#!/bin/sh
#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# Name: bookmarks-dl
# Desc: A script used to download remote bookmarks into the XBEL format.
# Auth: Jaidyn Ann <jadedctrl@posteo.at>
# Date: 2023-09-02
# Reqs: lynx, jq
# Lisc: GPLv3
#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

SOURCE_DIRS="./sources/ $HOME/.local/libexec/bookmarks-dl/sources/ /usr/local/libexec/bookmarks-dl/sources/ /usr/libexec/bookmarks-dl/sources/"
FORMAT_DIRS="./formats/ $HOME/.local/libexec/bookmarks-dl/formats/ /usr/local/libexec/bookmarks-dl/formats/ /usr/libexec/bookmarks-dl/formats/"

usage() {
	1>&2 echo "usage: $(basename "$0") SOURCE ..."
	1>&2 echo "       $(basename "$0") --sources"
	1>&2 echo "       $(basename "$0") --formats"
	1>&2 echo "       $(basename "$0") --help"
	1>&2 echo ""
	1>&2 echo "  SOURCE is a source of bookmarks."
	1>&2 echo "  You can see a list of sources with '--list'."
	1>&2 echo "  You can see a list of output formats with '--formats'."
}


# Return the paths to all available bookmarks-dl “source” scripts.
all_scripts() {
	local target_dirs="$1"
	find $target_dirs -type f -name '*.sh' \
		 2> /dev/null
}


# Return the path to a specific bookmarks-dl source.
get_script() {
	local script_dirs="$1"
	local script_name="$2"
	all_scripts \
		| grep "/$script_name.sh" \
		| head -1
}


# List all available bookmarks-dl sources user-friendly-like.
list_scripts() {
	local script_dirs="$1"
	for script in $(all_scripts "$script_dirs"); do
		printf '%s\t%s\n' \
			   "$(basename "$script" | sed 's/\.sh//')" \
			   "$script"
	done
}


# Given the arguments to this program, find that matching `-f`, the paramter
# for selecting a specific format.
get_format() {
	while test -n "$1" -a ! "$1" = "-f"; do
		shift
	done
	if test "$1" = "-f"; then
		echo "$2"
	fi
}


# The function called to format the internal JSON-format bookmarks into a
# more usable format. This should be overridden by a “format” script; see
# last couple of lines of this script.
# It receives the bookmarks over stdin, and returns them over stdout.
format_bookmarks() {
	cat
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
	--sources|sources)
		list_scripts "$SOURCE_DIRS"
		exit 0
		;;
	--formats|formats)
		list_scripts "$FORMAT_DIRS"
		exit 0
		;;

	--help|-h|help|'')
		usage
		exit 1
		;;
	*)
		SOURCE="$(get_script "$SOURCE_DIRS" "$SOURCE_NAME")"
		if test -f "$SOURCE"; then
			source "$SOURCE"
		fi
		if test "$?" -ne 0 -o ! -f "$SOURCE"; then
			1>&2 echo "The source '$SOURCE_NAME' couldn’t be found."
			1>&2 echo "Try '$(basename "$0") --sources' to see a list of possible sources."
		fi
		;;
esac


if test -z "$1"; then
	usage
	exit 1
else
	shift
fi


FORMAT="$(get_script "$FORMAT_DIRS" "$(get_format $@)")"
if test -f "$FORMAT"; then
	source "$FORMAT" \
		   2> /dev/null > /dev/null
fi


# These both should be overloaded.
source_start $@ \
	| format_bookmarks
