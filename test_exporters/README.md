## Test exporters

You can use the tool in this directory to test whether your exporter can handle
various projects correctly.

 - Clone or download this repository `git clone git@github.com:25a0/Quadtastic.git`
 - `cd Quadtastic`
 - Install [Love2d](https://love2d.org) and make `love` available on your `PATH`
 - Run `love test_exporters <path-to-your-exporter.lua>`

This will test your exporter with various projects to check if it crashes. Since
each export format is different, this tool cannot do any more sophisticated
tests. However, should you want to see the output of your exporter, you can
pass `-v` as an option to turn on verbose output. You will then see what project
was passed to your exporter, and what your exporter produced.

The file [`export_test_cases.lua`](https://github.com/25A0/Quadtastic/blob/master/test_exporters/export_test_cases.lua)
contains the projects with which your exporter will be tested.