function [im, info, output] = read_raw(exe, files, options)
  % READ_RAW Read the image data
  %   READ_RAW(exe, file) reads 'file' with method 'exe'.
  %
  %   READ_RAW(exe, file, options) reads 'file' with method 'exe' passing 
  %   additional 'options' as a string.
  %
  %  [IM, INFO, OUPUT] =READ_RAW(...) retuens the image data as IM, the EXIF 
  %  data as INFO, and any temporary generated file as OUTPUT.

  % useful DCRAW options
  % -T              write a TIFF file, and copy metadata in
  % -H 2
  % -w -T -6 -q 3   use camera white balance, and best interpolation
  % -a -T -6        use auto white balance
  % -i -v           print metadata
  % -z              set the generated image date to that of the camera
  % -n 100          remove noise using wavelets
  % -w              use white balance from camera or auto
  
  if ismac,      precmd = 'DYLD_LIBRARY_PATH= ; ';
  elseif isunix, precmd = 'LD_LIBRARY_PATH= ; '; 
  else           precmd=''; end
  
  if nargin < 3, options='-T -w -6 -v'; end
  
  if ischar(options), options= cellstr(options); end
  
  if ischar(files), files=cellstr(files); end
  im = {}; info = {}; output = {};
  
  for index=1:numel(files)
    file = files{index};
    [p,f]= fileparts(file);
    
    % we first check if the output file already exists. If so we just read it.
    flag_output = '';
    for ext={'.tiff', '.pnm','.ppm','.pgm'}
      out = fullfile(p, [f ext{1} ]);
      if exist(out, 'file')
        flag_output = out;
        break
      end
    end
    if ~isempty(flag_output) && isempty(strfind(char(options), '-i'))
      im{end+1}   = imread(flag_output);
      info{end+1} = imfinfo(flag_output);
      output{end+1} = flag_output;
      break
    end
    
    if isstruct(exe) && isfield(exe, 'read') % from imformats
      if iscell(exe.read)
        im{end+1}   = feval(exe.read{1}, file, exe.read{2:end});
      else
        im{end+1}   = feval(exe.read, file);
      end
      if isfield(exe, 'info')
        info{end+1} = feval(exe.info, file);
      else
        info{end+1} = [];
      end
      output{end+1} = '';
      continue
    end
  
    cmd       = [ precmd exe ' ' sprintf('%s ', options{:}) file ];

    % launch the command
    [status, result] = system([ cmd ]);
    if status, continue; end
    
    % interpret the result: image or information
    tokens = { 'Scaling with darkness', 'Scaling_Darkness:';
               ', saturation',          '; Scaling_Saturation:';
               'multipliers',           'Multipliers:';
               'Writing data to',       'Filename:';
               ', and',                 '';
               'Processing file',       'Source:';
               'Writing file',          'Filename:'};
    for tokid = 1:size(tokens,1)
      result = strrep(result, tokens{tokid,1}, tokens{tokid,2});
    end
    info{end+1} = str2struct(result);
    
    % must wait for result. dcraw_emu writes files asynchronously
    search_output = {};
    if isfield(info{end},'Filename') && exist(info{end}.Filename, 'file')
      search_output{end+1} = info{end}.Filename;
    end
    
    flag_output = '';
    
    for ext=[ search_output ...
      strcat(fullfile(p, f),  {'.tiff', '.pnm','.ppm','.pgm'}) ...
      strcat(file,            {'.tiff', '.pnm','.ppm','.pgm'}) ]
      
      if exist(ext{1}, 'file')
        if  isempty(strfind(char(options), '-i'))
          im{end+1}   = imread(ext{1});
        else
          im{end+1} = [];
        end
        flag_output   = ext{1};
        output{end+1} = ext{1};
        break
      end
    end
    if isempty(flag_output), im{end+1} = []; output{end+1} = ''; end
  end
  
  % single output ?
  if iscell(im) && numel(im) == 1
    im     = im{1};
    info   = info{1};
    output = output{1};
  end
  

end % read_raw
