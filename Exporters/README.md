# Exporters

The following exporters are available in Quadtastic by default:

 - [JSON](#json)
 - [XML](#xml)

## How to install custom exporters

 - Download the exporter that you want to install using the links in the table
   above
 - Open Quadtastic
 - Click 'File' -> 'Export as...' -> 'Manage exporters'. A file browser will
   open the directory in which custom exporters need to be stored.
 - Move the downloaded file to that directory
 - In Quadtastic, click 'File' -> 'Export as...' -> 'Reload exporters'
 - The new exporter should now be available in the 'File' -> 'Export as...' menu

## How to contribute custom exporters

With some knowledge about Lua, you can easily [write your own
exporter](https://github.com/25A0/Quadtastic/wiki/Exporters). If you wrote a
custom exporter that you would like to share with others, feel free to send a
pull request to this repo. Your custom exporter should be a single lua file in `Exporters/source/`.

Please also add a new entry about your exporter to the section below with the
following details:

 - A short description (e.g. is your exporter meant to be used for a specific game engine / programming language etc.)
 - Limitations, in case that your exporter cannot handle arbitrary lua tables
 - A direct download link to your exporter, for convenience, of the form

   ` - **Download** [your-exporter.lua](https://raw.githubusercontent.com/25A0/Quadtastic/master/Exporters/source/your-exporter.lua)`

 - An example that shows what your exporter produces when you export the quads
   of the example project. If that's not possible, feel free to choose your own
   illustrative example. Note that the metatable may contain your username, or
   details about your operating system and file system. You might want to censor
   that for privacy reasons.

## Exporter details

### JSON

 - **Description** Generic JSON exporter
 - **Limitations** Cannot handle tables that have both, string and numeric keys, or tables that have discontinuous numeric keys.
 - **Download** [json.lua](https://raw.githubusercontent.com/25A0/Quadtastic/custom-exporter/Quadtastic/exporters/json.lua)
   (but there's no need to download this one; it's already included in Quadtastic)
 - **Example**
	```json
	{
	  "_META": {
	    "image_path": ".\/sheet.png",
	    "version": "v0.5.3-60-g70c7852"
	  },
	  "base": {"x":16, "y": 27, "w": 16, "h": 8},
	  "bubbles": [
	    {"x":2, "y": 18, "w": 5, "h": 5},
	    {"x":1, "y": 25, "w": 3, "h": 4},
	    {"x":10, "y": 18, "w": 5, "h": 3},
	    {"x":7, "y": 24, "w": 7, "h": 6},
	    {"x":3, "y": 8, "w": 5, "h": 4},
	    {"x":10, "y": 11, "w": 4, "h": 3},
	    {"x":7, "y": 3, "w": 6, "h": 4}
	  ],
	  "lid": {"x":16, "y": 7, "w": 16, "h": 15},
	  "liquid": {"x":0, "y": 32, "w": 3, "h": 3},
	  "stand": {"x":32, "y": 32, "w": 16, "h": 16}
	}
	```

### XML

 - **Description** Generic XML exporter
 - **Limitations** None
 - **Download** [xml.lua](https://raw.githubusercontent.com/25A0/Quadtastic/custom-exporter/Quadtastic/exporters/xml.lua)
   (but there's no need to download this one; it's already included in Quadtastic)
 - **Example**
 	```xml
 	<?xml encoding='UTF-8'?>
	<quad_definitions>
	  <group key="_META">
	    <string key="image_path">./sheet.png</string>
	    <string key="version">v0.5.3-60-g70c7852</string>
	  </group>
	  <quad key="base", x="16", y="27", w="16", h="8" />
	  <group key="bubbles">
	    <quad key="1", x="2", y="18", w="5", h="5" />
	    <quad key="2", x="1", y="25", w="3", h="4" />
	    <quad key="3", x="10", y="18", w="5", h="3" />
	    <quad key="4", x="7", y="24", w="7", h="6" />
	    <quad key="5", x="3", y="8", w="5", h="4" />
	    <quad key="6", x="10", y="11", w="4", h="3" />
	    <quad key="7", x="7", y="3", w="6", h="4" />
	  </group>
	  <quad key="lid", x="16", y="7", w="16", h="15" />
	  <quad key="liquid", x="0", y="32", w="3", h="3" />
	  <quad key="stand", x="32", y="32", w="16", h="16" />
	</quad_definitions>
	```
