DDNet data directory as SVG collection
======================================

DDNet data SVG repository is a collection of SVGs, that can replace and/or extend
the official data directory of [ddnet](https://github.com/ddnet/ddnet/tree/master/data) with user specified resolution generated
textures, meant for higher resolution support.

Contributing
------------

When adding or changing a SVG file, make sure the file path fits the original PNG file path
in the data directory.
The SVG should contain a width and height(in inkscape the page width/height) in pixels matching the current size of the original PNG.
This is required to properly scale up the generated images.
Also the SVG should not contain the export path(e.g. in inkscape the export path for exporting PNGs).

