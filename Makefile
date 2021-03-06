TESTS := $(shell find tests -type f -name "test_*.lua")

APPNAME = Quadtastic
APPIDENTIFIER = com.25a0.quadtastic
APPVERSION = $(shell git describe --tags)
APPCOPYRIGHT = 2017-2018 Moritz Neikes
macos-love-distname = love-0.10.2-macosx-x64
windows-love-distname = love-0.10.2-win32

# When changing these edition identifiers, remember to change them in strings.lua
EDITION_WINDOWS = windows
EDITION_MACOS = osx
EDITION_CROSSPLATFORM = love
EDITION_LIBQUADTASTIC = libquadtastic

.PHONY: clean test check tests/* run all distfiles app_resources run_debug release* publish

all: run_debug

run: app_resources
	${DEBUG} love ${APPNAME}

run_debug: DEBUG=DEBUG=true
run_debug: run

LICENSES = LICENSE.txt ${APPNAME}/res/copyright.txt ${APPNAME}/libquadtastic.lua

APP_RESOURCES = ${LICENSES} \
                ${APPNAME}/res/style.png \
                ${APPNAME}/res/icon-32x32.png \
                ${APPNAME}/res/turboworkflow-deactivated.png \
                ${APPNAME}/res/turboworkflow-activated.png \
                ${APPNAME}/res/version.txt

app_resources: ${APP_RESOURCES}

check: ${APPNAME}/*.lua
	@which luacheck 1>/dev/null || (echo \
		"Luacheck (https://github.com/mpeterv/luacheck/) is required to run the static analysis checks" \
		&& false )
	luacheck -q ${APPNAME}/*.lua

test: check ${TESTS}

DISTFILES = dist/releases/${APPVERSION}/macos/${APPNAME}.app \
            dist/releases/${APPVERSION}/windows/${APPNAME}.zip \
            dist/releases/${APPVERSION}/crossplatform/${APPNAME}.zip \
            dist/releases/${APPVERSION}/love/${APPNAME}.love \
            dist/releases/${APPVERSION}/libquadtastic/libquadtastic.lua

distfiles: ${DISTFILES}

dist/releases/${APPVERSION}/macos/${APPNAME}.app: dist/macos/${APPNAME}.app
	mkdir -p dist/releases/${APPVERSION}/macos
	cp -r dist/macos/${APPNAME}.app dist/releases/${APPVERSION}/macos/
	# Update directory timestamp explicitly
	touch $@

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

dist/${APPNAME}.love: ${APPNAME}/**/*.lua ${APPNAME}/*.lua ${APP_RESOURCES}
	echo ${EDITION_CROSSPLATFORM} > ${APPNAME}/res/edition.txt
	cd ${APPNAME}; zip ../dist/${APPNAME}.love -Z store -FS -r . -x .\*
	cp -R shared dist/

dist/macos/${APPNAME}.app: dist/res/love.app dist/${APPNAME}.love dist/res/icon.icns
	mkdir -p dist/macos
	mkdir -p dist/macos/${APPNAME}.app
	rsync -qat dist/res/love.app/ dist/macos/${APPNAME}.app/
	cp dist/${APPNAME}.love dist/macos/

	# Update edition in this version of the .love archive
	mkdir -p dist/macos/res
	echo ${EDITION_MACOS} > dist/macos/res/edition.txt
	cd dist/macos; zip ${APPNAME}.love -Z store res/edition.txt
	rm dist/macos/res/edition.txt
	rm -d dist/macos/res

	mv dist/macos/${APPNAME}.love dist/macos/${APPNAME}.app/Contents/Resources/
	cp -R dist/shared dist/macos/${APPNAME}.app/Contents/Resources/
	cp dist/res/icon.icns dist/macos/${APPNAME}.app/Contents/Resources/

	cp res/plist.patch dist/macos/
	sed -i -e 's/__APPIDENTIFIER/${APPIDENTIFIER}/g' dist/macos/plist.patch
	sed -i -e 's/__APPNAME/${APPNAME}/g' dist/macos/plist.patch
	sed -i -e 's/__APPVERSION/${APPVERSION}/g' dist/macos/plist.patch
	sed -i -e 's/__APPCOPYRIGHT/${APPCOPYRIGHT}/g' dist/macos/plist.patch
	patch dist/macos/${APPNAME}.app/Contents/Info.plist dist/macos/plist.patch
	rm dist/macos/plist.patch*

	# Update directory timestamp explicitly
	touch $@

dist/windows/${APPNAME}.zip: dist/res/${windows-love-distname}.zip dist/${APPNAME}.love
	mkdir -p dist/windows/${APPNAME}
	rsync -qat dist/res/${windows-love-distname}/ dist/windows/${APPNAME}/
	cp dist/${APPNAME}.love dist/windows/

	# Update edition in this version of the .love archive
	mkdir -p dist/windows/res
	echo ${EDITION_WINDOWS} > dist/windows/res/edition.txt
	cd dist/windows; zip ${APPNAME}.love -Z store res/edition.txt
	rm dist/windows/res/edition.txt
	rm -d dist/windows/res

	cat dist/windows/${APPNAME}.love >> dist/windows/${APPNAME}/love.exe
	rm dist/windows/${APPNAME}.love
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

aseprite=/Users/moritz/Library/Application\ Support/itch/apps/Aseprite/Aseprite.app/Contents/MacOS/aseprite
screenshots/turboworkflow.gif: res/turboworkflow-activated.ase Makefile
	${aseprite} -b res/turboworkflow-activated.ase --scale 1 --save-as screenshots/turboworkflow.gif

${APPNAME}/res/turboworkflow-activated.png: res/turboworkflow-activated.ase
	${aseprite} -b res/turboworkflow-activated.ase --sheet ${APPNAME}/res/turboworkflow-activated.png

${APPNAME}/res/loading.png: res/loading.ase
	${aseprite} -b res/loading.ase --sheet ${APPNAME}/res/loading.png

${APPNAME}/res/%.png: res/%.ase
	${aseprite} -b res/$*.ase --save-as ${APPNAME}/res/$*.png

${APPNAME}/res/icon-32x32.png: res/icon.ase
	${aseprite} -b res/icon.ase --scale 2 --save-as ${APPNAME}/res/icon-32x32.png

# hacky way to determine whether we need to remake the version file
_stored_version = $(shell test -f ${APPNAME}/res/version.txt && cat ${APPNAME}/res/version.txt)
ifneq "v$(APPVERSION)" "$(_stored_version)"
.PHONY: ${APPNAME}/res/version.txt
endif

${APPNAME}/res/version.txt:
	echo v${APPVERSION} > ${APPNAME}/res/version.txt

%.png: %.ase
	${aseprite} -b $*.ase --save-as $*.png

%.gif: %.mov
	mkdir -p .tmp
	ffmpeg -i $*.mov -r 10 -vcodec png .tmp/out-static-%04d.png 
	time convert -verbose +dither -alpha set -layers Optimize .tmp/out-static*.png  GIF:- > $*.gif
	rm .tmp/out-static-*

tests/test_*.lua:
	lua $@

clean:
	rm -rf dist/

firstyear=2017
thisyear=$(shell date "+%Y")
years=$(shell test ${firstyear} = ${thisyear} && echo ${firstyear} || echo ${firstyear}-${thisyear})

# hacky way to determine whether we need to remake the license file
_remake_license = $(shell test -f LICENSE.txt && grep -q " ${years} " LICENSE.txt || echo 1)
ifeq "${_remake_license}" "1"
.PHONY: LICENSE.txt
endif

LICENSE.txt: res/raw_mit_license.txt
	cp res/raw_mit_license.txt LICENSE.txt
	sed -i '' -e 's/\[years\]/${years}/' LICENSE.txt

${APPNAME}/res/copyright.txt: LICENSE.txt
	head -1 LICENSE.txt > ${APPNAME}/res/copyright.txt

# hacky way to determine whether we need to remake the license file
_remake_libquadtastic = $(shell grep -q " ${years} " Quadtastic/libquadtastic.lua || echo 1)
ifeq "1" "${_remake_libquadtastic}"
.PHONY: ${APPNAME}/libquadtastic.lua
endif

${APPNAME}/libquadtastic.lua:
	sed -i '' -e 's/Copyright (c) .* Moritz Neikes/Copyright (c) ${years} Moritz Neikes/' \
	    Quadtastic/libquadtastic.lua

# Build as $ make release-0.2.0
# Tag names MUST follow the major.minor.patch pattern.
release-%: test ${LICENSES} ${DISTFILES}
	@# Only allow releases from the master branch.
	@git status -b --porcelain | head -n 1 | grep --silent "## master" || \
	(echo "Error: Can only release from master"; exit 1)

	@# Only allow releasing a clean working directory
	@test -z "`git status --porcelain --untracked-files=no`" || \
	(echo "Error: Working directory is not clean"; exit 1)

	@# Check whether there are any files in the archive that are not in the
	@# index
	@mkdir -p .tmp
	@# This writes all files in the index to indexed_files.txt that are in
	@# Quadtastic, or in any subdirectory
	@cd Quadtastic; git ls-files . | sort > ../.tmp/indexed_files.txt
	@# This writes all files in the zipfile to staged_files.txt.
	@# We explicitly remove res/version.txt since we need that file to be in
	@# the archive, but not in the index
	@# We also remove any directories listed in the zip, since they will not
	@# show up in the index.
	@unzip -Z -1 dist/${APPNAME}.love | \
	grep -v "res/version.txt" - | \
	grep -v "/$$" - | \
	sort > .tmp/staged_files.txt
	@-diff .tmp/staged_files.txt .tmp/indexed_files.txt > .tmp/filelists.diff
	@test -s .tmp/filelists.diff && \
	echo "Error: ${APPNAME}.love includes files that are not in the index:" && \
	cat .tmp/filelists.diff && \
	echo "Remove these files or add them to the index; then re-make all distfiles" && \
	false || true

	@# Only proceed if that version doesn't already exist
	@test ! -f .git/refs/tags/$* || \
	(echo "Error: Version $* is already released"; exit 1)

	# Check that the version to be released is tagged.
	@if [[ ! $* =~ ^[0-9]+.[0-9]+.[0-9]+$$ ]] ; then\
	  echo "Error: Version does not have major.minor.patch format."; false;\
	fi

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
	@sed -i '' "/^#.*/ d" .tmp/releasemessage
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

	@# Merge master into stable
	@printf "\e[1m4. Merge master branch into stable branch\e[0m\n"
	git checkout stable
	git merge --ff-only master
	git checkout master

	@rm -rf .tmp
	@printf "\e[1mAll done.\e[0m You can now run 'make publish' to publish version $*\n"
	@printf "Remember to push the new tag, as well as the master and stable branch.\n"

publish: ${DISTFILES}
	# Check that the version to be released is tagged.
	@if [[ ! ${APPVERSION} =~ ^[0-9]+.[0-9]+.[0-9]+$$ ]] ; then\
	  echo "Error: Cannot publish an untagged commit."; false;\
	fi
	# Uses itch.io's butler to push dist files to the Quadtastic page on itch.io
	butler push dist/releases/${APPVERSION}/windows/${APPNAME}.zip \
	       25a0/quadtastic:${EDITION_WINDOWS}       --userversion ${APPVERSION}
	butler push dist/releases/${APPVERSION}/macos \
	       25a0/quadtastic:${EDITION_MACOS}         --userversion ${APPVERSION}
	butler push dist/releases/${APPVERSION}/love \
	       25a0/quadtastic:${EDITION_CROSSPLATFORM} --userversion ${APPVERSION}
	butler push dist/releases/${APPVERSION}/libquadtastic \
	       25a0/quadtastic:${EDITION_LIBQUADTASTIC} --userversion ${APPVERSION}

