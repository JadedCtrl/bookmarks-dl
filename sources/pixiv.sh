#!/bin/sh
#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# Name: bookmarks-dl: Pixiv
# Desc: A source for bookmarks-dl that fetches bookmarks from Pixiv.
# Auth: Jaidyn Ann <jadedctrl@posteo.at>
# Date: 2023-09-04
# Reqs: curl, jq
# Lisc: GPLv3
#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

usage() {
	1>&2 echo "usage: bookmarks-dl pixiv [-h] -a PHPSESSID -u USER_ID"
	1>&2 echo
	1>&2 echo "  -h             print this message and exit"
	1>&2 echo "  -u             account user-id"
	1>&2 echo "  -a             the authorization cookie PHPSESSID for your account"
	1>&2 echo
	1>&2 echo "bookmarks-dl pixiv can be used to fetch all of a user’s pixiv"
	1>&2 echo "bookmarks from their account into an easily-parseable JSON format."
	1>&2 echo
	1>&2 echo "Use is simple, you only need your user-ID and your PHPSESSID cookie."

	1>&2 echo "To find your user-id, go to you pixiv profile and look at the URL:"
	1>&2 echo '  https://www.pixiv.net/en/users/$USER_ID'
	1>&2 echo
	1>&2 echo "To find your PHPSESSID cookie, look at your web-browser’s storage for"
	1>&2 echo "pixiv.net. This varies from browser to browser, but you can do so in"
	1>&2 echo "Firefox by navigating to F12 → Storage → Cookies → pixiv.net → PHPSESSID."
}


# Fetch all of a user’s Pixiv bookmarks.
fetch_bookmarks() {
	local user_id="$1"
	local auth="$2"
	local offset="$3"
	local rest="$4"
	if test -z "$offset"; then
		offset=0
	fi
	# We want to download private *and* public bookmarks; start with private.
	if test -z "$rest"; then
		rest="hide"
	fi

	local limit="48"
	local temp_json="$(mktemp)"
	curl_browseresque \
		"https://www.pixiv.net/ajax/user/57397070/illusts/bookmarks?tag=&offset=${offset}&limit=${limit}&rest=${rest}&lang=en" \
		-H "Cookie:PHPSESSID=${auth}" \
		-H "x-user-id:${user-id}" \
		-H 'Accept:application/json' \
		> "$temp_json"
	cat "$temp_json" \
		| bookmarks_parse

	local total_bookmarks="$(jq -r '.body.total' < "$temp_json")"
	local next_offset="$(echo "$offset + $limit" | bc)"

	if test "$next_offset" -le "$total_bookmarks"; then
		fetch_bookmarks "$user_id" "$auth" "$next_offset" "$rest"
	# When finished downloading private bookmarks, start downloading public ones.
	elif test "$rest" = "hide"; then
		fetch_bookmarks "$user_id" "$auth" "0" "show"
	fi
}


source_start() {
	local auth=""
	local user_id=""
	while getopts 'hf:a:u:' arg; do
		case $arg in
			h)
				usage
				exit 1
				;;
			a)
				auth="$OPTARG"
				;;
			u)
				user_id="$OPTARG"
				;;
		esac
	done

	if test -z "$auth" -o -z "$user_id"; then
		usage
		exit 5
	else
		fetch_bookmarks "$user_id" "$auth"
	fi
}


bookmarks_parse() {
	jq -r '.body.works[] | "https://www.pixiv.net/en/artworks/\(.id)\t\(.title)\t\(.alt)\t"'
}
