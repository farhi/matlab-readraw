function [reader_raw,reader_exif] = compile_binary(compile)
  % search for DCRAW-like and EXIF reader
  % Compile dcraw as binary when does not exist yet.
  %
  % additional argument can be 'compile' or 'force'
  % or a pattern to match executable, e.g. 
  %   dcraw_emu, dcraw, simple_dcraw, unpackRaw, libraw
  
  reader_raw  = ''; 
  reader_exif = '';
  if nargin == 0, compile = ''; end
  if ismac,      precmd = 'DYLD_LIBRARY_PATH= ;';
  elseif isunix, precmd = 'LD_LIBRARY_PATH= ; '; 
  else           precmd = ''; end
  
  if ispc, ext='.exe'; else ext=''; end
  this_path = fullfile(fileparts(which(mfilename)));
  
  % try with the libRAW mex from E. Segre. It must have been compiled previously.
  % https://fr.mathworks.com/matlabcentral/fileexchange/70985-matlab-unpackraw
  if any(strcmp(compile, {'force','compile'}))
    p = pwd;
    try
      pdc = fullfile(fileparts(which('readraw')),'private');
      cd (pdc);
      buildMexunpackRaw;
    catch ME
      disp(getReport(ME));
    end
    cd(p)
  end
  if exist('unpackRaw') == 3 && (nargin ==0 || strcmpi(compile,'unpackRaw'))
    reader_raw.read = { @unpackRaw, 'color' };
  end
  
  % try in order: global(system), local, local_arch
  if isempty(reader_raw)
    for try_target={ ...
            [ 'dcraw_emu' ext ], ...
            fullfile('/usr/lib/libraw', [ 'dcraw_emu' ext ]), ...
            [ 'dcraw' ext ], 'dcraw', ...
            fullfile(this_path, [ 'dcraw_' computer('arch') ext ]), ...
            fullfile(this_path, [ 'dcraw' ext ]), ...
            [ 'simple_dcraw' ext ], ...
            fullfile('/usr/lib/libraw', [ 'simple_dcraw' ext ] ) }
        
      [status, result] = system([ precmd try_target{1} ]); % run from Matlab
      if status == 1 && (~isempty(strfind(result, 'Coffin')) || ~isempty(strfind(result, 'emulator')))
          if nargin == 0 || any(strcmp(compile, {'force','compile'}))
            % the executable is already there. No need to make it.
		        reader_raw = try_target{1};
		        break
          elseif ~isempty(strfind(try_target{1}, compile))
            % match executable name.
		        reader_raw = try_target{1};
		        break
          end
      end
    end
  end
  
  if isempty(reader_raw)
    % when we get there, compile dcraw_arch, not existing yet
    target = fullfile(this_path, [ 'dcraw_' computer('arch') ext ]);

    % search for a C compiler
    cc = '';
    for try_cc={getenv('CC'),'cc','gcc','ifc','pgcc','clang','tcc'}
      if ~isempty(try_cc{1})
        [status, result] = system([ precmd try_cc{1} ]);
        if status == 4 || ~isempty(strfind(result,'no input file'))
          cc = try_cc{1};
          break;
        end
      end
    end
    if isempty(cc)
      if ~ispc
        disp([ mfilename ': ERROR: C compiler is not available from PATH:' ])
        disp(getenv('PATH'))
        disp([ mfilename ': You may have to extend the PATH with e.g.' ])
        disp('setenv(''PATH'', [getenv(''PATH'') '':/usr/local/bin'' '':/usr/bin'' '':/usr/share/bin'' ]);');
      end
      error('%s: Can''t find a valid C compiler. Install any of: gcc, ifc, pgcc, clang, tcc\n', ...
      mfilename);
    else
      try
        fprintf(1, '%s: compiling dcraw binary (using %s)...\n', mfilename, cc);
        cmd={cc, '-O2','-o',target, ...
          fullfile(this_path,'dcraw.c'),'-lm','-DNODEPS'};
        cmd = sprintf('%s ',cmd{:});
        disp(cmd)
        [status, result] = system([ precmd cmd ]);
        if status == 0
          reader_raw = target;
        end
      end
    end

    if isempty(reader_raw) && ~isempty(compile)
      error('%s: Can''t compile dcraw.c binary\n       in %s\n', ...
          mfilename, fullfile(this_path));
    end
  end
  
  % we search for an EXIF tag reader.
  if ~isempty(reader_raw)
    % try in order: global(system), local, local_arch
    for try_target={ ...
            [ 'metacam' ext ], ...
            [ 'exiv2' ext ], ...
            {[ 'raw-identify' ext ],'-v'}, ...
            { fullfile('/usr/lib/libraw', [ 'raw-identify' ext ]) '-v' }, ...
            { 'dcraw' '-v -i' }, ...
            { [ 'dcraw' ext ] '-v -i' }, ...
            { fullfile(this_path, [ 'dcraw_' computer('arch') ext ]) '-v -i' }, ...
            { fullfile(this_path, [ 'dcraw' ext ]) '-v -i' }, ...
            'exifprobe' }
      exe=try_target{1};
      if iscell(exe) && numel(exe)==2
        exe=exe{1};
      end
      [status, result] = system([ precmd exe ]); % run from Matlab

      if any(status == [0 1 2 255]) && nargin == 0
        reader_exif = try_target{1};
        break
      end
    end
  end
  
  if isempty(reader_exif) % EXIF not found ? Will try with the default TIFF reader.
    reader_exif = imformats('tiff');
  end
  
end % compile_binary
