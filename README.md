unix-utilities
==============

Various small Unix utilities for ~/bin

All of them have been written by me, except ~/bin/rename by Larry Wall
which I'm bundling with the rest for convenience since a lot of Unix boxes don't have it.

These are all meant to work on OSX. Most but not all will work on other Unix
distributions. If you have patches to make them work elsewhere, send them
via pull request or another convenient method.

Individual utilities
====================

annotate_sgf
------------

It uses Gnu Go debug mode to annotate your go game in SGF.
It will find a lot of tactical mistakes for most games by kyu players.

Usage:

    annotate_sgf <game.sgf>

Output saved to annotated-<game.sgf> in the same directory as <game.sgf>.

See: http://t-a-w.blogspot.com/2009/08/get-better-at-go-with-gnugo.html

colcut
------

Cuts long lines to specific number of characters for easy previewing.

    colcut 80 < file.xml

convert_to_png
--------------

Converts various image formats to PNG.
Mostly useful for mass conversion, for example when you have a directory
with 100 svg files dir/file-001.svg to dir/file-100.svg:

    convert_to_png dir/*.svg

will convert them all.

countdown
---------

Counts down time, then optionally runs a command.

    countdown 60
    countdown 60 open rickroll.mp3

dedup_files
-----------

Deletes duplicate files in huge directories by hash, with some optimization
to avoid unnecessary hashing.

Usage:

    dedup_files <dir1> <dir2><...

For example:

    dedup_files my_little_pony_wallpapers/

which will work pretty well even if you have 100GB of My Little Pony wallpapers.


diffschemas
-----------

Gives diff of mysql schemas.

Do dump mysql schema use:

    mysqldump -uuser -ppassword -h hostname --where 0=1 database >schema.sql

Then run:

    diffschemas schema_1.sql schema_2.sql

which will strip garbage like autoincrement counters and give you clean diff.

e
---

This utility has extremely short name since it's meant to be used as your primary
way to call text editor.

If you give it a path containing /, or file with such name exists in current directory,
it will call your editor on that file.

Otherwise - it will search your `$PATH` for this file, and execute your editor on it,
avoiding opening binaries, and other false positives.

This is extremely helpful if you have a ton of scripts you edit a lot.

These two commands achieve similar effect:

    mate `which foo`

    e foo

except `e` is shorter, doesn't force you to think about paths,
will expand all symlinks in name (avoiding issues like accidentally editing the
same file under different name in two editor window), and won't accidentally open binaries.

Editor it will use is `$E_EDITOR`, then `$EDITOR`, then TextMate if neither variable is specified.
`$E_EDITOR` variable is provided in case you want to set up them as:


    export E_EDITOR=mate
    export EDITOR="mate -w"

since git and other such tools require waiting flag.

flickr_find
-----------

Find Creative Commons licenced photos on flickr.

Usage example:

    flickr_find cute kittens

flickr_get
----------

Download best quality version of a photo from flickr and annotate it with proper file name.

Usage example:

    flickr_get http://www.flickr.com/photos/pagedooley/386303100/

which will be saved as `~/Downloads/naughty_cat_by_kevin_dooley_from_flickr_cc-by.jpg`

fix_permissions
---------------

Removes executable flag from files which shouldn't have it.
Useful for archives that went through a Windows system, zip archive,
or other system not aware of Unix executable flag.

It doesn't turn +x flag, only removes it if a file neither starts with #!,
nor is an executable according to `file` utility.

Usage:

    fix_permissions ~/Downloads

If no parameters are passed, it fixes permissions in current directory.


git_hash
--------

Hash contents of current git repository. It is useful when multiple branches
can have same contents.

Usage example:

    git_hash ~/repository
    git_hash # will hash current directory


gzip_stream
-----------

Pipe through it to gzip log without having infinitely long buffers.

Usage example:

    my_server | gzip_stream > log.gz

If you use regular gzip the last few hundred lines will be in memory indefinitely,
so you won't be able to see what's going on in `log.gz` without killing the server,
even if it happened yesterday. `gzip_stream` flushes every 5s (easily configurable),
sacrificing tiny amount of compression quality for huge amount of convenience.

See: http://t-a-w.blogspot.com/2010/07/synchronized-compressed-logging-unix.html

lastfm_status
-------------

Find what your friends have been listening to recently.

Usage example:

    lastfm_status some_user

It requires `magic-xml` gem.

namenorm
--------

Safely normalizes file names replacing upper case characters and spaces with
lower case characters and underlines.

Usage:

    namenorm ~/Downloads/*


openmany
--------

Runs `open` command on multiple files, either as command line arguments,
or one-per-line in STDIN.

Usage:

    openmany <urls.txt
    openmany *.pdf

It uses OSX `open` command. For Linux edit to use whatever was Linux equivalent.
(I keep forgetting since `alias open=...` is always in my `.bashrc`)

osx_suspend
-----------

Quickly lock out your OSX session.


osx_screensaver
---------------

Turn on OSX screensaver (will lock out your OSX session depending on your settings)

pomodoro
--------

Count downs 25 minutes (or however many you specify as command line argument),
printing countdown on command line, and when it's over turning volume to maximum
and playing selected sound.

Usage:

    pomodoro   # 25 minutes
    pomodoro 5 # 5 minutes

See: https://en.wikipedia.org/wiki/Pomodoro_Technique

Setting volume and playing sound assume OSX commands, but I'm sure you'll be able
to figure out Linux equivalents.

pub
---

Fixes directory tree by making it publicly readable and editable by you.

Very useful when fixing permissions on files you just unpacked from an archive,
since many archive formats store stupid permissions (like read only on directories) inside,
which is a bad idea for everything except backups.

Usage:

    pub file.txt
    pub directory/


process_gplus_takeout
---------------------

Converts a directory of Google+ posts taken from Google takeout to a single HTML file,
sorted by publication date, keeping only original posts and attachments (links, images etc.),
without comments and other stuff.

Usage:

    process_gplus_takeout Stream/ output.html

progress
--------

Displays progress for piped file.

Usage examples:

       cat /dev/urandom | progress | gzip  >/dev/null
       progress -l <file.txt | upload

By default it's in bytes mode. Use -l to specify line mode.

If progress is piped a file and it's in byte mode, it checks its size
and uses that to display relative progress (like `18628608/104857600 [17%]`).

You can also specify what counts as 100% explicitly:

     progesss 123456
     progress 128m
     progress -l 42042

It will happily go over 100% on display.

rand_passwd
-----------

Generate random password consisting of 12 random lowercase letters,
that is 56 bits of entropy.

Including upper case letters, numbers, and symbols wouldn't provide
any meaningful extra security, but it would be much more pain to type it.

Use this together with password manager in your browser for all low-security
websites - in case your browser forgets the password you can reset it with
your email on pretty much all such sites anyway.

Usage:

    rand_passwd


randswap
--------

Randomly swaps lines of STDIN.

Usage:

    randswap <urls.txt | head -n 10 >sample.txt

rbexe
-----

Creates executable script path with proper `#!` line and permissions.

Defaults to Ruby executable but supports a few other `#!`s.

Usage:

    rbexe file.rb
    rbexe --9 file.rb
    rbexe --pl file.pl

If file exists, it will only change its permissions without overwriting it,
so it's safe to use.

rename
------

Larry Wall's rename script, included in Debian-derived distribution, but not on any other Unix
I know of - which is literally criminal, since it's one of core Unix utilities.

If your distribution doesn't have it (or worse - has some total crap as `rename` script),
do yourself a service and install something more sensible, and in the meantime copy this
file to your `~/bin`.

rot13
-----

ROT13 a file.

Usage (either form works):

    rot13 <file.txt
    rot13 file.txt
    cat file.txt | rot13 | rot13 > double_the_security.txt


since_soup
----------

Link to soup posts starting from the post before one specified.

Usage:

    since_soup http://taw.soup.io/post/307955954/Image

sortby
------

Sort input through arbitrary Ruby expression. A lot more flexible than Unix `sort` utility.

Usage:

    sortby '$_.length' <file.txt

speedup_mp3
-----------

Convert MP3 podcasts/audiobooks to faster playback (or slower if you wish).
Useful if your device (like default music playing apps on most phones) doesn't support playback speed change.

Requires sox.

Usage:

    Usage: #{$0} [-factor] file_in.mp3 file_out.mp3
           #{$0} [-factor] file1.mp3 file2.mp3 dir
           #{$0} [-factor] dir_in dir_out

Default factor is 1.4 (40% faster) if not specified.

split_dir
---------

Splits directories with excessively many files into multiple directories with about
equal number of about-200 files.

Usage example:

    split_dir my_little_pony_wallpapers/

Mostly useful for directories containing images.

strip_9gag
----------

Removes extremely annoying 9gag watermark they put on files they didn't make.

Usage:

    strip_9gag file.jpg
    strip_9gag http://some.site.example/file.jpg


tac
---

Reverses order of lines of whatever is on STDIN, prints to STDOUT.

Usage example:

    tac <pokemon_by_newest.txt >pokemon_by_oldest.txt

terminal_title
--------------

Changes title of current terminal window. Extremely useful if you have too many terminal titles.

Usage example:

    terminal_title 'Production server (do not accidentally killall -9)'; ssh production.server.example

unall
-----

Universal unarchiver. Possibly the most useful nontrivial utility in this repository (not counting Larry Wall's `rename`).

Command like interface to various archives formats is a total failure compared with convenience of desktop programs.

They have huge number of incompatible interfaces, which one can get used to, but there's a much more severe failures - sometimes an archive contains files without a single directory to contain them all.
This problem is solved by most good desktop unarchivers, but in command line world any such archive will ruin your day.

`unall` fixes all these problems - it checks what's inside the archive, if it's broken archive with multiple files not in same directory it will creature directory for it, if directory already exists it will rename it to something else etc.

If it was successful, it will then delete archive after unpacking (with `trash` command which puts it into OSX Trash, feel free to change it to whatever your system uses).

Usage:

    unall *.zip *.rar *.7z *.tar.bz2 *.tar.gz

`unall` assumes you have `7za`, `unrar`, and sane version of `tar` installed.

webman
------

Open man pages in web browser.

It is meant to be used with:

    alias man=webman

in your `bashrc`.

Usage:

    webman perl
    webman -T perl # to use terminal instead

If it can't find a man page, it googles for it.

xmlview
-------

Reindents XML and cuts it to 150 column limit for easy viewig.

Usage example:

    xmlview huge_machine_generated_xml_file.xml


xnorm
-----

A version of `namenorm` script which also removes random garbage from file names like ".x264".
Useful mostly for TV episodes.

Usage:

    xnorm ~/Downloads/*

It's included more as an example than as actually useful utilities since garbage they include
in file names changes constantly.

xpstree
-------

A much superior replacement for `pstree`.

Shows directory tree of processes with a lot of garbage cleaned up (like kernel processes removed, scripts displayed by their script name not their interpreter name etc.).

Regexps used to cleanup the tree might require some customization for your situation.

Usage examples:

    xpstree
    xpstree -u          # By current user
    xpstree -p          # Show pids
    xpstree -s          # Highlight current process's tree
    xpstree -h java     # Highlight anything with /java/ in process path
    xpstree -s Terminal # Ignore /Terminal/
    xpstree -x Terminal # Ignore /Terminal/ and all its children
    xpstree -f Terminal # Show only /Terminal/ and all its children
    xpstree -h Terminal # Highlight /Terminal/

Lower case options -sxfh are exact match (sane insensitive).

Upper case options -SXFH are regexp match.

xrmdir
------

Works like `rmdir` for OSX. Since OSX creates garbage files like `.DS_Store` in every single
directory you ever open with Finder (or just because it can), many empty directories
are technically non-empty.

`xrmdir` deletes this worthless file, then calls `rmdir` on it.

Usage:

    xrmdir ~/101/reasons/why/osx/sucks/*
