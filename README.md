# matlab-readraw
Read RAW camera images from within Matlab, using DCRAW

The use of this class boils down to simply creating the object. Then, you
may simply use the **imread** and **imfinfo** call as usual, and RAW files
will magically be handled.

Example:
--------

In the following example, we just call **readraw** once, and then all is done 
with **imread** and **imfinfo** as you would do with other image formats.

  ```matlab
  dc   = readraw;
  im   = imread('file.RAW');
  info = imfinfo('file.RAW'); % this creates a file.tiff
  delete('file.tiff');  % to save disk space
  ...
  delete(dc); clear dc
  ```
  
NOTES:
------

NOTE: Each RAW file will be converted to a 16-bits TIFF one at the same
location as the initial RAW file. This file is then read again by imread
to actually get the image RGB channels. If you have created these files
(which are each 146 Mb), you may either remove them, or further access
them without requiring conversion.

Supported RAW camera image formats include:

- RAW CRW CR2 KDC DCR MRW ARW NEF NRW DNG ORF PTX PEF RW2 SRW RAF KDC

If you which to import the RAW files with specific DCRAW options, use the
readraw class method 'imread' with options as 3rd argument e.g:

  ```matlab
  dc = readraw;
  im = imread(dc, 'file.RAW', '-a -T -6 -n 100');
  ```
  
and if you wish to get also the output file name and some more information:

  ```matlab
  [im, info, output] = imread(dc, 'file.RAW', '-T');
  ```
  
Some useful DCRAW options are:

- -T              write a TIFF file, and copy metadata in
- -w -T -6 -q 3   use camera white balance, and best interpolation AHD
- -a -T -6        use auto white balance
- -i -v           print metadata
- -z              set the generated image date to that of the camera
- -n 100          remove noise using wavelets
- -w              use white balance from camera or auto

Methods:
--------

- **readraw**     class instantiation. No argument.
- **compile**     check for DCRAW availability or compile it
- **delete**      remove readraw references in imformats
- **imread**      read a RAW image using DCRAW. Allow more options
- **imfinfo**     read a RAW image metadata using DCRAW

Credits: 
--------

- DCRAW is a great tool <https://www.cybercom.net/~dcoffin/dcraw/>
- Reading RAW files into MATLAB and Displaying Them <http://www.rcsumner.net/raw_guide/>
- RAW Camera File Reader by Bryan White 2016 <https://fr.mathworks.com/matlabcentral/fileexchange/7412-raw-camera-file-reader?focused=6779250&tab=function>

License: (c) E. Farhi, GPL2 (2018)
