TESTS := $(shell find tests -type f -name "test_*.lua")

APPNAME = Quadtastic
APPIDENTIFIER = com.25a0.quadtastic
APPVERSION = $(shell git describe --tags)
APPCOPYRIGHT = 2017 Moritz Neikes
macos-love-distname = love-0.10.2-macosx-x64
windows-love-distname = love-0.10.2-win32

.PHONY: clean test check tests/* run all app_resources run_debug update_license release* distfiles

all: run_debug

run: app_resources
	${DEBUG} love ${APPNAME}

run_debug: DEBUG=DEBUG=true
run_debug: run

app_resources: ${APPNAME}/res/style.png ${APPNAME}/res/icon-32x32.png ${APPNAME}/res/turboworkflow-deactivated.png ${APPNAME}/res/turboworkflow-activated.png update_license
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
	${aseprite} -b res/turboworkflow-activated.ase --scale 2 --save-as screenshots/turboworkflow.gif

${APPNAME}/res/turboworkflow-activated.png: res/turboworkflow-activated.ase
	${aseprite} -b res/turboworkflow-activated.ase --sheet ${APPNAME}/res/turboworkflow-activated.png

${APPNAME}/res/%.png: res/%.ase
	${aseprite} -b res/$*.ase --save-as ${APPNAME}/res/$*.png

${APPNAME}/res/icon-32x32.png: res/icon.ase
	${aseprite} -b res/icon.ase --scale 2 --save-as ${APPNAME}/res/icon-32x32.png

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

# Build as $ make release-0.2.0
release-%: test update_license
	# Releasing $*
	@# Only proceed if that version doesn't already exist
	@test ! -f .git/refs/tags/$* || \
	(echo "Version $* is already released"; exit 1)

	@# Prepare tag message
	@echo 'Release $*\n' > .tagmessage
	@printf "\
	# Write a message for release $*\n\
	# Lines starting with # will be ignored\n\n\
	" >> .tagmessage
	@echo "Changelog:" >> .tagmessage

	@################################################################
	@# If you're on linux, you will almost certainly need to change #
	@# `sed -E` to `sed -r`. Sorry for that                         #
	@################################################################
	@cat changelog.md | sed -E '/^### Unreleased/,/^### Release/!d' \
					  | sed -E '/^###/d' >> .tagmessage

	@# Open the tag message in the editor before creating the tag.
	# If you're using sublime text as your editor, make sure to pass the -w
	# flag so that sublime text doesn't return until you close the edited
	# tag message.
	@${EDITOR} .tagmessage
	@cp .tagmessage .releasemessage

	@# Now we use the composed tag message to update the changelog, so that
	@# changelog and release notes are uniform.
	@sed -i '' "/#.*/ d" .releasemessage
	@sed -i '' "/Changelog:/ d" .releasemessage

	@# Can't use multi-line sed commands in Make, so this is stored separately
	@./changelog.sh $*

	@#Now combine all of this to update the changelog
	@sed -e '/### Release/,$$ !d' < changelog.md >> .releasemessage
	@cp .releasemessage changelog.md

	@echo Review and commit changes made to changelog.md
	@${EDITOR} changelog.md
	git add -p changelog.md

	git commit -m "Update chagnelog.md"

	@# Signing tag
	@git tag -s $* -F .tagmessage

	@rm .tagmessage
	@rm .releasemessage