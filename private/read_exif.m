function [info] = read_exif(exe, files, options)

  % useful DCRAW options
  % -i -v           print metadata
  
  if ismac,      precmd = 'DYLD_LIBRARY_PATH= ; ';
  elseif isunix, precmd = 'LD_LIBRARY_PATH= ; '; 
  else           precmd=''; end
  
  if nargin < 3, options=''; end
  
  if iscell(exe) && numel(exe)==2
    options = exe{2};
    exe     = exe{1};
  end
  
  if ischar(options), options= cellstr(options); end
  
  if ischar(files), files=cellstr(files); end
  info = {};
  
  for index=1:numel(files)
    file = files{index};
    [p,f]= fileparts(file);
    
    % we first check if the output file already exists. If so we just read it.
    flag_output = '';
    for ext=[ ...
      strcat(fullfile(p, f),  {'.tiff', '.pnm','.ppm','.pgm'}) ...
      strcat(file,            {'.tiff', '.pnm','.ppm','.pgm'}) ]

      if exist(ext{1}, 'file')
        flag_output = ext{1};
        break
      end
    end
    if ~isempty(flag_output) && isempty(strfind(char(options), '-i'))
      info{end+1} = imfinfo(flag_output);
      break
    end
    
    if isstruct(exe) && isfield(exe, 'info') % from imformats
      info{end+1} = feval(exe.info, file);
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
    
  end
  
  % single output ?
  if numel(info) == 1
    info   = info{1};
  end
  

end % read_exif
