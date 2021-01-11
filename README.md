# matlab-readraw
Read RAW camera images from within Matlab, using DCRAW

![Image of READRAW](https://github.com/farhi/matlab-readraw/blob/master/readraw.jpg)

The use of this class boils down to simply creating the object. Then, you
may simply use the **imread** and **imfinfo** call as usual, and RAW files
will magically be handled.

Example:
--------

In the following example, we just call **readraw** once, and then all is done 
with **imread** and **imfinfo** as you would do with other image formats.

  ```matlab
  readraw;
  im   = imread('file.RAW');  % this creates a file.tiff
  info = imfinfo('file.RAW'); 
  delete('file.tiff');  % to save disk space, if ever needed
  ...
  delete(readraw);
  ```
  
The default DCRAW setting for the importation is '-T -4 -t 0 -v' to get the raw data.

NOTES:
------

NOTE: Each RAW file will be converted to a 16-bits TIFF one at the same
location as the initial RAW file. This file is then read again by imread
to actually get the image RGB channels. If you have created these files
(which are each 146 Mb for 6x4k images), you may either remove them, or further access
them without requiring conversion.

Supported RAW camera image formats include:

RAW File Format | Description
-- | --
CRW, CR2 | Canon digital camera RAW file formats
NEF | Nikon digital camera RAW file format
ORF | Olympus digital camera RAW file format
RAF | Fuji digital camera RAW file format
RWL | Leica camera RAW file format
PEF, PTX | Pentax digital camera RAW file format
X3F | Sigma digital camera RAW file format
DCR, KDC, DC2, K25 | Kodak digital camera RAW file format
SRF, ARW, MRW, MDC | Sony/Minolta digital camera RAW file format
RAW | Panasonic, Casio, Leica digital camera RAW file format
DNG (CS1, HDR) | Adobe RAW file format (Digital Negative)
BAY | Casio RAW (Bayer)
ERF | Epson digital camera RAW file format
FFF | Imacon/Hasselblad RAW format
MOS | CREO Photo RAW
PXN | Fotoman RAW
RDC | Ricoh RAW format

If you wish to import the RAW files with specific DCRAW options, use the
readraw class method 'imread' with options as 3rd argument e.g:

  ```matlab
  dc = readraw;
  im = imread(dc, 'file.RAW', '-a -T -6 -n 100');
  ```
  
and if you wish to get also the output file name and some more information:

  ```matlab
  [im, info, output] = imread(dc, 'file.RAW', '-T -4 -t 0 -v');
  ```
  
Some useful DCRAW options are:

- -T              write a TIFF file, and copy metadata in
- -w -T -6 -q 3   use camera white balance, and best interpolation AHD
- -a -T -6        use auto white balance
- -T -4           use raw data, without color scaling, nor white balance
- -i -v           print metadata
- -z              set the generated image date to that of the camera
- -n 100          remove noise using wavelets
- -w              use white balance from camera or auto
- -t 0            do not flip the image

Methods:
--------

- **readraw**     class instantiation. No argument.
- **compile**     check for DCRAW availability or compile it
- **delete**      remove readraw references in imformats
- **imread**      read a RAW image using DCRAW. Allow more options
- **imfinfo**     read a RAW image metadata using DCRAW

Installation:
-------------

Copy the directory and navigate to it. Then type from the Matlab prompt:

  ```matlab
  addpath('path-to-readraw')
  readraw;
  ```

READRAW can use any of the following installed tools:

- libraw (with header/include files)
- dcraw
- libraw binary tools (dcraw_emu, raw-identify, simple_dcraw)
- exiv2
- metacam
- exifprobe

which should be in the executable search path. These can be installed for Debian-like systems with:
```
sudo apt install dcraw libraw-bin exiv2 metacam exifprobe libraw-dev
sudo ln -s /usr/lib/libraw/dcraw_emu /usr/local/bin
sudo ln -s /usr/lib/libraw/raw-identify /usr/local/bin
```

To make use of the libraw direct reader (which is much faster than the others), you may have to compile the MeX file for your system by running:
```
cd path-to-readraw/private
buildMexunpackRaw
```
which makes use of the excellent contribution from E. Segre.

If no RAW reader is found, and DCRAW is not yet installed on the computer, you will need a C compiler.
The DCRAW C source file (provided with READRAW, `private` directory) will be built and used.

Credits: 
--------

- **DCRAW** is a great tool <https://www.cybercom.net/~dcoffin/dcraw/>
- Reading RAW files into MATLAB and Displaying Them <http://www.rcsumner.net/raw_guide/>
- RAW Camera File Reader by Bryan White 2016 <https://fr.mathworks.com/matlabcentral/fileexchange/7412-raw-camera-file-reader?focused=6779250&tab=function>
- LibRaw MeX https://fr.mathworks.com/matlabcentral/fileexchange/70985-matlab-unpackraw and https://github.com/EastEriq/matlab-unpackRaw

License: (c) E. Farhi, GPL2 (2018)
