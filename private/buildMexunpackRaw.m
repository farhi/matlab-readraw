if ispc
    % a compiled library can be downloaded from https://www.libraw.org/download
    % libraw.dll needs also to be copied in this directory - is there a
    % better way?
    libpath='D:\LibRaw-0.19.2\';
    mex(['-L' libpath 'lib'], '-llibraw',...
        ['-I' libpath], '-DWIN32', '-outdir','.', 'unpackRaw.cpp')
else
    % on ubuntu, needs the package libraw-dev (which depends on libraw15
    %  and liblcms2-dev)
    mex -lraw -outdir . -ULINUX unpackRaw.cpp
end

