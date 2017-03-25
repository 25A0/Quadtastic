TESTS := $(shell find tests -type f -name "test_*.lua")

APPNAME = Quadtastic
APPIDENTIFIER = com.25a0.quadtastic
APPVERSION = $(shell git tag -l | head -1)-$(shell git log -1 --pretty=format:%h )
APPCOPYRIGHT = 2017 Moritz Neikes
macos-love-distname = love-0.10.2-macosx-x64

.PHONY: clean test check tests/* run all app_resources run_debug

all: test

run: app_resources
	${DEBUG} love ${APPNAME}

run_debug: DEBUG=DEBUG=true
run_debug: run

app_resources: ${APPNAME}/res/style.png ${APPNAME}/res/icon-32x32.png
	# Store version info in ${APPNAME}/res
	echo v${APPVERSION} > ${APPNAME}/res/version.txt

check: ${APPNAME}/*.lua
	@which luacheck 1>/dev/null || (echo \
		"Luacheck (https://github.com/mpeterv/luacheck/) is required to run the static analysis checks" \
		&& false )
	luacheck -q ${APPNAME}/*.lua

test: check ${TESTS}

dist/${APPNAME}.love: ${APPNAME}/* app_resources
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
${APPNAME}/res/%.png: res/%.ase
	${aseprite} -b res/$*.ase --save-as ${APPNAME}/res/$*.png

${APPNAME}/res/icon-32x32.png: res/icon.ase
	${aseprite} -b res/icon.ase --scale 2 --save-as ${APPNAME}/res/icon-32x32.png

tests/test_*.lua:
	lua $@

clean:
	rm -rf dist
