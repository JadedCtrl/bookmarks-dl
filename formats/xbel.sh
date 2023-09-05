#!/bin/sh
#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# Name: bookmarks-dl: xbel
# Desc: Output format for bookmarks-dl, formatting bookmarks in XBEL format.
# Auth: Jaidyn Ann <jadedctrl@posteo.at>
# Date: 2023-09-04
# Reqs: lynx, jq
# Lisc: GPLv3
#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

format_bookmarks() {
	local json_bookmarks_file="$(mktemp)"
	cat \
		> "$json_bookmarks_file"

	echo '<?xml version="1.0" encoding="UTF-8"?>'
	echo '<xbel version="1.0">'

	items_count="$(jq -r '. | length' < "$json_bookmarks_file")"
	item_index="0"
	while test "$item_index" -lt "$items_count"; do
		format_bookmark "$json_bookmarks_file" "$item_index"
		item_index="$(echo "$item_index + 1" | bc)"
	done

	echo "</xbel>"
	rm "$json_bookmarks_file"
}


format_bookmark() {
	local json_file="$1"
	local json_index="$2"

	title="$(jq -r ".[$json_index].title" < "$json_file")" # | html_text_deescape | html_escape)"
	desc="$(jq -r ".[$json_index].desc" < "$json_file")" # | html_text_deescape | html_escape)"
	added="$(jq -r ".[$json_index].added" < "$json_file")"
	href="$(jq -r ".[$json_index].href" < "$json_file")"
	if test -z "$title" -a -n "$desc"; then
		title="$(echo "$desc" | head --bytes=40)"
	fi

	cat <<MDR
  <bookmark href="$href" $(if valid_value "$added"; then echo "added=\"$added\""; fi)>
    $(if valid_value "$title"; then echo "<title>$title</title>"; fi)
    $(if valid_value "$desc"; then echo "<desc>$desc</desc>"; fi)
  </bookmark>
MDR
}


valid_value() {
	local value="$1"
	test -n "$value" -a ! "$value" = "null"
}
