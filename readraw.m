classdef readraw
%  Read RAW camera images from within Matlab
%
%  The use of this class boils down to simply creating the object. Then, you
%  may simply use the imread and imfinfo call as usual, and RAW files
%  will magically be handled.
%
%  Example:
%  --------
%
%  In the following example, we just call readraw once, and then all is done 
%  with imread and imfinfo as you would do with other image formats.
%
%    readraw;
%    im   = imread('file.RAW');   % this creates a file.tiff
%    info = imfinfo('file.RAW');  
%    delete('file.tiff');         % to save disk space, if ever required
%    ...
%    delete(readraw);
%
%  The image is imported without applying any color/white balance adjustment,
%  which corresponds with DCRAW options '-T -4 -t 0 -v'.
%    
%  NOTES:
%  ------
%
%  NOTE: Each RAW file will be converted to a 16-bits TIFF one at the same
%  location as the initial RAW file. This file is then read again by imread
%  to actually get the image RGB channels. If you have created these files
%  (which are each 146 Mb for 4k images), you may either remove them, or 
%  further access them without requiring conversion (which is then much faster).
%
%  If your disk storage is limited, use (this is anyway the default):
%    readraw clean;
%    im = imread(raw_file);
%  will remove the TIFF files after being read.
%
%  You may as well use 'tiff' to explicitly keep the TIFF files.
%    readraw tiff
%
%  Supported RAW camera image formats include:
%
%  - RAW CRW CR2 KDC DCR MRW ARW NEF NRW DNG ORF PTX PEF RW2 SRW RAF KDC
%
%  If you wish to import the RAW files with specific DCRAW options, use the
%  readraw class method 'imread' with options as 3rd argument e.g:
%
%    dc = readraw;
%    im = imread(dc, 'file.RAW', '-a -T -6 -n 100');
%    
%  and if you wish to get also the output file name and some EXIF information:
%
%    [im, info, output] = imread(dc, 'file.RAW', '-T');
%    
%  Some useful DCRAW options are:
%
%  -T              write a TIFF file, and copy metadata in
%  -w -T -6 -q 3   use camera white balance, and best interpolation AHD
%  -a -T -6        use auto white balance
%  -i -v           print metadata
%  -z              set the generated image date to that of the camera
%  -n 100          remove noise using wavelets
%  -w              use white balance from camera or auto
%  -t 0            do not flip the image
%
%  Methods:
%  --------
%
%  - readraw     class instantiation. No argument.
%  - compile     check for RAW reader availability or compile it.
%  - delete      remove readraw references in imformats. Then use clear.
%  - imread      read a RAW image. Allow more options.
%  - imfinfo     read a RAW image metadata (EXIF).
%
%  Credits: 
%  --------
%
%  - DCRAW is a great tool <https://www.cybercom.net/~dcoffin/dcraw/>
%  - Reading RAW files into MATLAB and Displaying Them <http://www.rcsumner.net/raw_guide/>
%  - RAW Camera File Reader by Bryan White 2016 <https://fr.mathworks.com/matlabcentral/fileexchange/7412-raw-camera-file-reader?focused=6779250&tab=function>
%
%  License: (c) E. Farhi, GPL2 (2018)

  properties
  
    reader_raw =[]; % executable to read RAW
    reader_exif=[]; % executable to extract EXIF data
    UserData   =[]; % user area
    clean      =1;  % when true, clear temporary file
    
  end
  
  methods
  
    function self=readraw(varargin)
      % READRAW read RAW camera files and return their information and image
      %
      %   readraw(): create the RAW file reader
      %     the RAW images can then be read using the usual imread and imfinfo
      %   readraw tiff      same as above, and keeps   temporary files
      %   readraw clean     same as above, and removes temporary files (default)

      [self.reader_raw, self.reader_exif] = compile(self); % find DCRAW/libRAW executable
      
      % check 'clean' 'tiff' options
      for index=1:nargin
        if ischar(varargin{index})
          switch varargin{index}
          case {'clean','purge'}
            self.clean = 1;
          case {'tiff','keep'}
            self.clean = 0;
          end
        end
      end
      
      % we add entries to the imformats registry
      formats = imformats;
      
      rawFormat.ext = {'raw', 'crw', 'cr2', 'kdc', ...
         'dcr', 'mrw', 'arw', 'nef', 'nrw', 'dng', 'orf', 'ptx', 'pef', ...
         'rw2', 'srw', 'raf', 'kdc' };
      rawFormat.isa = @(f)not(isempty(imfinfo(self, f)));
      rawFormat.info = @(f)imfinfo(self, f);
      rawFormat.read = @(f)imread(self, f);
      rawFormat.write = '';
      rawFormat.alpha = 0;
      rawFormat.description = 'RAW Camera Format (RAW)';
      
      index   = find(strncmp({ formats.description },'RAW',3), 1);
      if isempty(index) % not registered yet
        imformats('add', rawFormat);
      else % replace existing entry
        formats(index) = rawFormat;
        imformats(formats);
      end
      disp([ mfilename ': installed ReadRaw as loader for RAW camera images.' ]);
      
    end
    
    function delete(self)
      % DELETE clear the image format registry for RAW images
      %
      %   use delete(self) and then clear(self)
      formats = imformats;
      index   = find(strncmp({ formats.description },'RAW',3), 1);
      formats(index) = [];
      imformats(formats);
    end % delete
    
    function [reader_raw, reader_exif] = compile(self, force)
      % COMPILE test if DCRAW/libRAW binary is requested and exists.
      %   return the location of the RAW reader executable
      %
      %   COMPILE(READRAW,'force') force compiles unpackRaw and/or DCRAW
      %
      %   COMPILE(READRAW,'reader') selects the given reader, amongst
      %   dcraw_emu, dcraw, simple_dcraw, unpackRaw, libraw
      
      % test if bin is requested and exists, else compiles
      if nargin > 1
           [self.reader_raw, self.reader_exif] = compile_binary(force); % force
      else [self.reader_raw, self.reader_exif] = compile_binary; end

      if isempty(self.reader_raw)
        error('%s: ERROR: Can''t compile RAW reader executable (Binary).', ...
              mfilename);
      end
      
      reader_raw  = self.reader_raw;
      reader_exif = self.reader_exif;
        
    end % compile
    
    function [im, info, output]=imread(self, file, options)
      % IMREAD read a RAW file
      %
      %   imread(self, file)
      %     read RAW file
      %   imread(self, { file1, file2, ...})
      %     read RAW iteratively files
      %   imread(self, file, options)
      %     same as above, and send specific DCRAW options, e.g. '-v -T'
      %     See <https://www.cybercom.net/~dcoffin/dcraw/>
      
      if nargin < 3, options='-T -4 -t 0 -v'; end

      [im, info, output] = read_raw(self.reader_raw, file, options); % private
      info.software = self.reader_raw;
      if self.clean && exist(output, 'file'), delete(output); end
    
    end % imread
    
    function info=imfinfo(self, file)
      % IMFINFO read a RAW file metainfo (EXIF)
      %
      %   imfinfo(self, file)
      %     read RAW file metainfo
      %   imfinfo(self, { file1, file2, ...})
      %     read iteratively RAW files metainfo
    
      [info] = read_exif(self.reader_exif, file);
      info.software = self.reader_raw;
      
    end % imfinfo
    
  end
  
end % readraw
