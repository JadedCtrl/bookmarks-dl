# bookmarks-dl

Set of scripts for downloading “bookmarks” from online sources (Mastodon, Pixiv) into an easily-parseable line-based format. Currently, it supports Mastodon and Pixiv.

The format is TSV, with columns like so:
`URL	Title	Description	Date`


## Installation
Copy `bookmarks-dl.sh` to a directory in your `$PATH`, and copy `sources/` to a directory like `/usr/libexec/bookmarks-dl/sources/`.

```
$ chmod +x bookmarks-dl.sh
$ cp bookmarks-dl.sh ~/.local/bin/bookmarks-dl
$ mkdir -p ~/.local/libexec/bookmarks-dl/
$ cp -r sources/ ~/.local/libexec/bookmarks-dl/
```


## Usage
`bookmarks-dl` uses different “source” scripts in `$PREFIX/libexec/bookmarks-dl/sources/`, like `~/.local/libexec/bookmarks-dl/sources/`.

You can see a list of sources with `bookmarks-dl --list`, and invoke a specific source with `bookmarks-dl $SOURCE --help`, like `$ bookmarks-dl mastodon --help`.


### Mastodon
The Mastodon source works with any fedi server that implements the Mastodon client API — this includes servers like Pleroma, Akkoma, etc.

To use it, you need two bits of information: Your server, and your Authentication token.
To find your Authorization token, you can snoop through request headers in Firefox or Chromium by navigating to `Developer Tools (F12) → Network → Headers`. Refresh your Mastodon page, and examine a request, looking for a header like so:

`Authorization: Bearer $TOKEN`

… where $TOKEN is your token. Copy it!
Then, all you have to do is download bookmarks:

`$ bookmarks-dl mastodon -d $SERVER -a $TOKEN > fedi-bookmarks.tsv`

Note that, since these posts don’t have “descriptions” in the strict sense, the “description” column contains the post’s text-content itself. And since posts don’t have “titles” either, the “title” column contains a truncated version of the “description.”


### Pixiv
For the Pixiv source, you need your user-ID and your PHPSESSID cookie.

To find your user-id, go to you pixiv profile and look at the URL:

`https://www.pixiv.net/en/users/$USER_ID`

To find your PHPSESSID cookie, look at your web-browser’s storage for pixiv.net. This varies from browser to browser, but you can do so in Firefox by navigating to `Developer Tools (F12) → Storage → Cookies → pixiv.net → PHPSESSID`.

Now, to fetch your bookmarks:

`$ bookmarks-dl pixiv -u $USER_ID -a $PHPSESSID > pixiv-bookmarks.tsv


## Example
```
$ bookmarks-dl mastodon -d jam.xwx.moe -a $auth_token > bookmarks.tsv
$ head -2 bookmarks.tsv
https://mastodon.social/@kroyxt/110861657854740188	Mia uzo de #linukso estas tre minimalism	Mia uzo de #linukso estas tre minimalisma komparante min kun aliaj uzantoj:  - Mia fenestra administrilo estas "i3wm". - Mi skribas kodon per "Vim". - Mi legas je RSS per "Newsboat". - Mi aŭdas podkaston per "Newsboat+Podboat+MPV". - Mi aŭdas radion per "PyRadio". - Mi administras miajn dosierojn per "Ranger"(Antaŭe per Vifm). - Mi aŭdas muzikon per "Cmus". - Mi legas e-librojn per "Zathura". - Mi skribas notojn per "jrnl". - Por krei aŭtomatigon mi uzas je bash + rofi + fulmklavo.  #esperanto 	2023-08-09T20:57:32.000Z
https://esperanto.masto.host/@abouadil/111084745919750147	Svahila proverbo (151)  Penye uchafu hap	Svahila proverbo (151)  Penye uchafu hapakosi nzi.  Tie kie estas malpuraĵoj, tie ne mankas muŝojn.  #Swahili #Kiswahili #MethaliZaKiswahili #Esperanto #Kiesperanto #SvahilaProverbaro #lang_eo 	2023-09-18T06:31:46.000Z
```


## Sources
Sources are ultimately just shell scripts that have functions to override those of bookmarks-dl. At the moment, the function `source_start` should be implemented.

`source-start`: Takes source-specific arguments (that is, all arguments after `$SOURCE` in `bookmarks-dl source arg1 arg2 arg3`. Should print a help message if -h/--help are parameters, or if no parameters are given. Should print bookmarks in the above-described tab-separated format.

I might change it up, as necessary. I just want the interface to be semi-consistent between these scripts; that’s why this is all under `bookmarks-dl`, rather than under separate scripts/repos.

I hope to make sources for at least one other website — DeviantArt. Suggestions or contributions for other sites would be greatly appreciated!


## Misc.
License: GNU GPLv3  
Author: Jaidyn Ann <jadedctrl@posteo.at>  
Weather: Temperate
