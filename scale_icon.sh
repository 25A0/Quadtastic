#!/bin/sh
# Automatically create png versions of an icon at different scales

aseprite="/Users/moritz/Library/Application Support/itch/apps/Aseprite/Aseprite.app/Contents/MacOS/aseprite"

icon=$1
iconname=`echo ${icon} | sed -e 's/.ase//'`
iconset_dir=${iconname}.iconset
mkdir -p ${iconset_dir}

scales=([1]=1 2 8 16 32)
sizes=([1]=16 32 128 256 512)

for (( i = 1; i <= ${#scales[*]}; i++ )); do
	scale=${scales[$i]}
	size=${sizes[$i]}
	"${aseprite}" -b ${icon} --scale ${scale} --save-as ${iconset_dir}/icon_${size}x${size}.png
done
