#!/bin/sh
#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# Name: bookmarks-dl: Mastodon
# Desc: A source for bookmarks-dl that fetches bookmarks from Mastodon/Pleroma.
# Auth: Jaidyn Ann <jadedctrl@posteo.at>
# Date: 2023-09-02
# Reqs: curl, jq
# Lisc: GPLv3
#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

usage() {
	1>&2 echo "usage: bookmarks-dl mastodon [-h] [-a USER_TOKEN] -u USERNAME -d DOMAIN"
	1>&2 echo ""
	1>&2 echo "  -h             print this message and exit"
	1>&2 echo "  -a             the authorization token for your account; see below"
	1>&2 echo "  -u             account username"
	1>&2 echo "  -d             the server’s domain name"
}


# Fetch all of a user’s Mastodon/Pleroma bookmarks.
fetch_bookmarks() {
	local auth="$1"
	local domain="$2"
	local url="$3"
	if test -z "$url"; then
		url="https://$domain/api/v1/bookmarks?limit=40"
		printf "[" # Start the JSON array
	fi

	local header_file="$(mktemp)"
	curl -H "Authorization: Bearer $auth" \
		 -D "$header_file" \
		 "$url" \
		 | bookmarks_parse

	local next_url="$(header_next_link "$header_file")"
	rm "$header_file"
	if test -n "$next_url"; then
		fetch_bookmarks "$auth" "$domain" "$next_url" \
			| sed 's/^},},/}]/' # Two },}, means end of JSON array
	fi
}


source_start() {
	local auth=""
	local domain=""
	while getopts 'ha:u:d:' arg; do
		case $arg in
			h)
				usage
				exit 1
				;;
			a)
				auth="$OPTARG"
				;;
			d)
				domain="$OPTARG"
				;;
		esac
	done

	if test -z "$auth" -o -z "$domain"; then
		usage
		exit 5
	else
		fetch_bookmarks "$auth" "$domain"
	fi
}


# Given a page of /api/v1/bookmarks, parse into the simple bookmarks-dl format
bookmarks_parse() {
	jq -r '.[] | { "desc": .content, "href": .url, "added": .created_at }' \
		| sed 's/^}/},/' \
		| head -n-1
	printf '},'
}


# If curl’s HTTP response contains a “link” header for pagination, return the
# “next” page’s URL.
header_next_link() {
	local header_file="$1"
	grep '^link:' "$header_file" \
		| tr -d ' ' \
		| tr '[A-Z]' '[a-z]' \
		| sed 's/>;rel="next",.*//' \
		| sed 's/link:<//'
}
