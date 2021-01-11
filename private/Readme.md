# unpackRaw - read raw camera image files into Matlab

This small mex was created with a simple purpose in mind - import images
written in raw camera files into matlab, without an additional preliminary
conversion to a common image file like jpeg or tiff.

In order to do it, I rely on the external library [LibRaw](https://www.libraw.org/),
which is well maintained and supports dozens of modern and old raw file formats.

The need arose because [other MATLAB cental contributions](https://www.mathworks.com/matlabcentral/fileexchange?q=raw+camera) don't do that -
either they use `dcraw` which implies writing an additional image file,
or use very old importing code which supports few raw file formats.

Since my needs were basic, I decidedly implemented only importing
either b/w 16bit images, or 8bit color images casted to Matlab
three channels, 0-1 range, with no particular rendering, gamma,
interpolation, white balance, whatever. In principle all those
could be easily added in the `.cpp` code, leveraging on `LibRaw`'s
extensive capabilities. Adding more flexibility would have meant
handling and parsing options at the level of the function call,
and I am not interested in it now. Other contributions do that.

## Installing LibRaw

### on Ubuntu 16

The package to be installed is `libraw-dev` (which depends on `libraw15`
and `liblcms2-dev`)

### on windows

The library package
(sources+compiled) has to be [downloaded from the `LibRaw` site](https://www.libraw.org/download)
and uncompressed in some directory. Edit `buildMexunpackRaw.m` to match.

The file `libraw.dll` from `\bin\`, inside the library directory, needs also to be copied in the same directory of
`unpackRaw.m` - (unless someone suggests a smarter way of building the `mex`, if there
   is such a thing)

## Use

First, build the `mex`, running once `buildMexunpackRaw.m` for good. Then:

+ `img=unpackRaw(raw_image_file)` % retrieves an uint16 grayscale

+ `img=unpackRaw(raw_image_file,'color')` % retrieves a single three-channel image

There is actually a lot of metadata stored together with the raw
image, which could be retrieved and passed to Matlab from the structures of
`LibRaw`. Camera information, color map, etc. etc. I wanted to keep
things as simple as possible to start with.
