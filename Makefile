TESTS := $(shell find tests -type f -name "test_*.lua")

APPNAME = Quadtastic
APPIDENTIFIER = com.25a0.quadtastic
APPVERSION = $(shell git describe --tags)
APPCOPYRIGHT = 2017 Moritz Neikes
macos-love-distname = love-0.10.2-macosx-x64
windows-love-distname = love-0.10.2-win32

.PHONY: clean test check tests/* run all app_resources run_debug update_license release* distfiles publish screenshots/example.gif check_license

all: run_debug

run: app_resources
	${DEBUG} love ${APPNAME}

run_debug: DEBUG=DEBUG=true
run_debug: run

app_resources: ${APPNAME}/res/style.png
app_resources: ${APPNAME}/res/icon-32x32.png
app_resources: ${APPNAME}/res/turboworkflow-deactivated.png
app_resources: ${APPNAME}/res/turboworkflow-activated.png
app_resources: check_license
	# Store version info in ${APPNAME}/res
	echo v${APPVERSION} > ${APPNAME}/res/version.txt

check: ${APPNAME}/*.lua
	@which luacheck 1>/dev/null || (echo \
		"Luacheck (https://github.com/mpeterv/luacheck/) is required to run the static analysis checks" \
		&& false )
	luacheck -q ${APPNAME}/*.lua

test: check ${TESTS}

distfiles: test
distfiles: dist/releases/${APPVERSION}/macos/${APPNAME}.app
distfiles: dist/releases/${APPVERSION}/windows/${APPNAME}.zip
distfiles: dist/releases/${APPVERSION}/crossplatform/${APPNAME}.zip
distfiles: dist/releases/${APPVERSION}/love/${APPNAME}.love
distfiles: dist/releases/${APPVERSION}/libquadtastic/libquadtastic.lua

dist/releases/${APPVERSION}/macos/${APPNAME}.app: dist/macos/${APPNAME}.app
	mkdir -p dist/releases/${APPVERSION}/macos
	cp -r dist/macos/${APPNAME}.app dist/releases/${APPVERSION}/macos/

dist/releases/${APPVERSION}/windows/${APPNAME}.zip: dist/windows/${APPNAME}.zip
	mkdir -p dist/releases/${APPVERSION}/windows
	cp dist/windows/${APPNAME}.zip dist/releases/${APPVERSION}/windows/

dist/releases/${APPVERSION}/crossplatform/${APPNAME}.zip: dist/${APPNAME}.love
	mkdir -p dist/releases/${APPVERSION}/crossplatform
	cp dist/${APPNAME}.love dist/releases/${APPVERSION}/crossplatform/
	cp -r dist/shared dist/releases/${APPVERSION}/crossplatform/

	cd dist/releases/${APPVERSION}/crossplatform;\
	zip ${APPNAME}.zip -Z store -m -r .

dist/releases/${APPVERSION}/love/${APPNAME}.love: dist/${APPNAME}.love
	mkdir -p dist/releases/${APPVERSION}/love
	cp dist/${APPNAME}.love dist/releases/${APPVERSION}/love/

dist/releases/${APPVERSION}/libquadtastic/libquadtastic.lua: Quadtastic/libquadtastic.lua
	mkdir -p dist/releases/${APPVERSION}/libquadtastic
	cp Quadtastic/libquadtastic.lua dist/releases/${APPVERSION}/libquadtastic/

dist/${APPNAME}.love: ${APPNAME}/*.lua app_resources
	cd ${APPNAME}; zip ../dist/${APPNAME}.love -Z store -FS -r . -x .\*
	cp -R shared dist/

dist/macos/${APPNAME}.app: dist/res/love.app dist/${APPNAME}.love dist/res/icon.icns
	mkdir -p dist/macos
	mkdir -p dist/macos/${APPNAME}.app
	rsync -qa dist/res/love.app/ dist/macos/${APPNAME}.app/
	cp dist/${APPNAME}.love dist/macos/${APPNAME}.app/Contents/Resources/
	cp -R dist/shared dist/macos/${APPNAME}.app/Contents/Resources/
	cp dist/res/icon.icns dist/macos/${APPNAME}.app/Contents/Resources/

	cp res/plist.patch dist/macos/
	sed -i -e 's/__APPIDENTIFIER/${APPIDENTIFIER}/g' dist/macos/plist.patch
	sed -i -e 's/__APPNAME/${APPNAME}/g' dist/macos/plist.patch
	sed -i -e 's/__APPVERSION/${APPVERSION}/g' dist/macos/plist.patch
	sed -i -e 's/__APPCOPYRIGHT/${APPCOPYRIGHT}/g' dist/macos/plist.patch
	patch dist/macos/${APPNAME}.app/Contents/Info.plist dist/macos/plist.patch
	rm dist/macos/plist.patch*

dist/windows/${APPNAME}.zip: dist/res/${windows-love-distname}.zip dist/${APPNAME}.love
	mkdir -p dist/windows/${APPNAME}
	rsync -qa dist/res/${windows-love-distname}/ dist/windows/${APPNAME}/
	cat dist/${APPNAME}.love >> dist/windows/${APPNAME}/love.exe
	mv dist/windows/${APPNAME}/love.exe dist/windows/${APPNAME}/${APPNAME}.exe
	cp -r dist/shared dist/windows/${APPNAME}/
	cd dist/windows/${APPNAME}; zip ../${APPNAME}.zip -Z store -FS -r . -x .\*

dist/res/${windows-love-distname}.zip:
	mkdir -p dist/res
	cd dist/res; \
	wget -N https://bitbucket.org/rude/love/downloads/${windows-love-distname}.zip; \
	unzip ${windows-love-distname}.zip

dist/res/love.app:
	mkdir -p dist/res
	cd dist/res; \
	wget -N https://bitbucket.org/rude/love/downloads/${macos-love-distname}.zip; \
	unzip ${macos-love-distname}.zip

dist/res/%.icns: res/%.ase
	mkdir -p dist/res
	cp res/$*.ase dist/res/
	# Create iconset folder with icon at various sizes
	./scale_icon.sh dist/res/$*.ase
	# Run iconutil to create icns file
	iconutil -c icns dist/res/$*.iconset

aseprite=/Applications/Aseprite.app/Contents/MacOS/aseprite
screenshots/turboworkflow.gif: res/turboworkflow-activated.ase Makefile
	${aseprite} -b res/turboworkflow-activated.ase --scale 1 --save-as screenshots/turboworkflow.gif

${APPNAME}/res/turboworkflow-activated.png: res/turboworkflow-activated.ase
	${aseprite} -b res/turboworkflow-activated.ase --sheet ${APPNAME}/res/turboworkflow-activated.png

${APPNAME}/res/%.png: res/%.ase
	${aseprite} -b res/$*.ase --save-as ${APPNAME}/res/$*.png

${APPNAME}/res/icon-32x32.png: res/icon.ase
	${aseprite} -b res/icon.ase --scale 2 --save-as ${APPNAME}/res/icon-32x32.png

%.png: %.ase
	${aseprite} -b $*.ase --save-as $*.png

screenshots/example.gif:
	ffmpeg -i screenshots/example.mov -r 10 -vcodec png screenshots/out-static-%04d.png 
	time convert -verbose +dither -layers Optimize -resize 106x120\> screenshots/out-static*.png  GIF:- > screenshots/example.gif
	rm screenshots/out-static-*

tests/test_*.lua:
	lua $@

clean:
	rm -rf dist/

firstyear=2017
thisyear=$(shell date "+%Y")
update_license:
	cp res/raw_mit_license.txt LICENSE.txt
	test ${firstyear} = ${thisyear} && \
	sed -i '' -e 's/\[years\]/${thisyear}/' LICENSE.txt || \
	sed -i '' -e 's/\[years\]/${firstyear}-${thisyear}/' LICENSE.txt
	head -1 LICENSE.txt > Quadtastic/res/copyright.txt
	test ${firstyear} = ${thisyear} && \
	sed -i '' -e 's/Copyright (c) .* Moritz Neikes/Copyright (c) ${thisyear} Moritz Neikes/' \
	    Quadtastic/libquadtastic.lua || \
	sed -i '' -e 's/Copyright (c) .* Moritz Neikes/Copyright (c) ${firsyear}-${thisyear} Moritz Neikes/' \
	    Quadtastic/libquadtastic.lua

check_license:
	@(test ${firstyear} = ${thisyear} && \
	grep -q "Copyright (c) ${thisyear} Moritz" LICENSE.txt || \
	grep -q "Copyright (c) ${firstyear}-${thisyear} Moritz" LICENSE.txt) || \
	(echo "LICENSE.txt is not up to date" && false)

	@(test ${firstyear} = ${thisyear} && \
	grep -q "Copyright (c) ${thisyear} Moritz" Quadtastic/libquadtastic.lua || \
	grep -q "Copyright (c) ${firstyear}-${thisyear} Moritz" Quadtastic/libquadtastic.lua) || \
	(echo "License in Quadtastic/libquadtastic.lua is not up to date" && false)

# Build as $ make release-0.2.0
release-%: test check_license
	@# Only proceed if that version doesn't already exist
	@test ! -f .git/refs/tags/$* || \
	(echo "Version $* is already released"; exit 1)

	@printf "\e[1mReleasing $*\e[0m\n"
	@printf "Press CTRL-C at any time to cancel the release\n"

	@# Prepare tag message
	@mkdir -p .tmp
	@echo 'Release $*\n' > .tmp/tagmessage

	@printf "\e[1m1. Write release message\e[0m\n"
	@printf "\
	# Write a message for release $*\n\
	# Lines starting with # will be ignored\n\n\
	" >> .tmp/tagmessage
	@echo "Changelog:" >> .tmp/tagmessage

	@################################################################
	@# If you're on linux, you will almost certainly need to change #
	@# `sed -E` to `sed -r`. Sorry for that                         #
	@################################################################
	@cat changelog.md | sed -E '/^### Unreleased/,/^### Release/!d' \
					  | sed -E '/^###/d' >> .tmp/tagmessage

	@# Open the tag message in the editor before creating the tag.
	@# If you're using sublime text as your editor, make sure to pass the -w
	@# flag so that sublime text doesn't return until you close the edited
	@# tag message.
	@${EDITOR} .tmp/tagmessage
	@cp .tmp/tagmessage .tmp/releasemessage

	@# Now we use the composed tag message to update the changelog, so that
	@# changelog and release notes are uniform.
	@sed -i '' "/#.*/ d" .tmp/releasemessage
	@sed -i '' "/Changelog:/ d" .tmp/releasemessage

	@# Can't use multi-line sed commands in Make, so this is stored separately
	@./changelog.sh $*

	@#Now combine all of this to update the changelog
	@sed -E '1,/### Unreleased/ !d' < changelog.md > .tmp/planned
	@sed -E '/### Release/,$$ !d' < changelog.md > .tmp/older
	@cat -s .tmp/planned .tmp/releasemessage .tmp/older > .tmp/changelog

	@printf "\e[1m2. Review new changelog\e[0m\n"
	@${EDITOR} .tmp/changelog
	@printf "\e[1m3. Commit changes to changelog\e[0m\n"
	@cp .tmp/changelog changelog.md
	git add -p changelog.md

	git commit -m "Update changelog.md"

	@# Signing tag
	@printf "\e[1m4. Tag release\e[0m\n"
	@git tag -s $* -F .tmp/tagmessage

	@rm -rf .tmp
	@printf "\e[1mAll done.\e[0m You can now run 'make publish' to publish version $*\n"

publish: distfiles
	# Check that the version to be released is tagged.
	@if [[ ! ${APPVERSION} =~ ^[0-9]+.[0-9]+.[0-9]+$$ ]] ; then\
	  echo "Error: Cannot publish an untagged commit."; false;\
	fi
	# Uses itch.io's butler to push dist files to the Quadtastic page on itch.io
	butler push dist/releases/${APPVERSION}/windows/${APPNAME}.zip \
	       25a0/quadtastic:windows       --userversion ${APPVERSION}
	butler push dist/releases/${APPVERSION}/macos \
	       25a0/quadtastic:osx           --userversion ${APPVERSION}
	butler push dist/releases/${APPVERSION}/love \
	       25a0/quadtastic:love          --userversion ${APPVERSION}
	butler push dist/releases/${APPVERSION}/libquadtastic \
	       25a0/quadtastic:libquadtastic --userversion ${APPVERSION}

