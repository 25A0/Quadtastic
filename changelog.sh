#!/bin/sh
datestring=`date "+%Y-%m-%d"`
sed -i '' "/^Release $1/ {
i\\
\\
There are currently no unreleased changes\\
\\

c\\
### Release $1, ${datestring}
a\\
\\
[Download](https://github.com/25A0/Quadtastic/releases/tag/$1)
}" .tmp/releasemessage
