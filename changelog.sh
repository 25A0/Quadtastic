#!/bin/sh
#
# Prints all ticked items from the README's roadmap
# that have been checked since the last release

################################################################
# If you're on linux, you will almost certainly need to change #
# `sed -E` to `sed -r`. Sorry for that                         #
################################################################

current_version=`git describe --abbrev=0 --tags`
last_tagged_commit=`git tag -v ${current_version} 2>/dev/null |\
	head -1 | sed -e 's/object //'`

echo 'Changelog:\n'

# Diff since last tag
git diff ${last_tagged_commit} -U20 -- README.md \
| sed -E '/^\+ +- \[x\]/,/^. +- \[/!d' \
| sed -E '/^. +- \[ \]/ d' \
| sed -E '/^[^+] +- \[x\]/ d' \
| sed -E 's/^\+ +- \[x\]/ -/' \
| sed -E 's/^[+ ] {3,}/   /' \
