#include <stdio.h>
#include <string.h>
#include <math.h>
#include <time.h>

#include <libraw/libraw.h>
#include "mex.h"

#ifdef WIN32
  #include <windows.h>
  #include <sys/utime.h>
  #include <winsock2.h>
#else
  #include <unistd.h>
  #include <netinet/in.h>
#endif

void
mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
    unsigned char *ImgData;
    LibRaw RawProcessor;
    char *filename, errmsg[160];
    char const *options;
    int i,j,ret;
    
    # define verbose false

    /* check proper input and output */
    if(nrhs<1)
        mexErrMsgIdAndTxt( "MATLAB:librawmex:invalidInput",
                            "Filename input required.");
    else if(!mxIsChar(prhs[0]))
        mexErrMsgIdAndTxt( "MATLAB:librawmex:inputNotChar",
                            "Input must be a string.");
    
    if(nrhs>1)
    {
        if(!mxIsChar(prhs[1]))
            mexErrMsgIdAndTxt( "MATLAB:librawmex:inputNotChar",
                               "Input must be a string.");
        options = mxArrayToString(prhs[1]);
    }
    else options="bw";
    
    filename = mxArrayToString(prhs[0]);
    
    #define S RawProcessor.imgdata.sizes
    #define OUT RawProcessor.imgdata.params

    if (verbose)
      mexPrintf("Processing file %s\n", filename);
    if ((ret = RawProcessor.open_file(filename)) != LIBRAW_SUCCESS)
    {
      sprintf(errmsg,"Cannot open %s: %s\n", filename, libraw_strerror(ret));
      mexErrMsgIdAndTxt( "MATLAB:librawmex:cantOpenFile",errmsg);
    }
    
    if (verbose)
    {
      mexPrintf("Image size: %dx%d\nRaw size: %dx%d\n",
              S.width, S.height, S.raw_width, S.raw_height);
      mexPrintf("Margins: top=%d, left=%d\n", S.top_margin, S.left_margin);
    }

    if ((ret = RawProcessor.unpack()) != LIBRAW_SUCCESS)
    {
      sprintf(errmsg,"Cannot unpack %s: %s\n", filename, libraw_strerror(ret));
      mexErrMsgIdAndTxt( "MATLAB:librawmex:cantUnpack",errmsg);
    }

    if (verbose)
      mexPrintf("Unpacked....\n");

    if (!(RawProcessor.imgdata.idata.filters || RawProcessor.imgdata.idata.colors == 1))
    {
      mexPrintf("Only Bayer-pattern RAW files supported, sorry....\n");
    }

    if (strcmp(options,"color")==0)
    {
    // dcraw conversion, with no options = 8 bit per channel
        OUT.output_bps = 8;
        OUT.gamm[0] = OUT.gamm[1] = OUT.no_auto_bright = 1;
        ret = RawProcessor.dcraw_process();
        if (LIBRAW_SUCCESS != ret)
        {
            sprintf(errmsg,"Cannot postprocess %s: %s\n", filename, libraw_strerror(ret));
            mexErrMsgIdAndTxt( "MATLAB:librawmex:cantUnpack",errmsg);
        }
        else
        {
            libraw_processed_image_t *image = RawProcessor.dcraw_make_mem_image(&ret);
            if (verbose)
                mexPrintf("allocated....\n");
            
            mwSize dims[3];
            dims[0]=image->height;
            dims[1]=image->width;
            dims[2]=3;
            plhs[0] = mxCreateNumericArray(3,dims,mxSINGLE_CLASS,mxREAL);
            float * pImage = (float*)mxGetData(plhs[0]);
            // arrange as matlab expects three channels images
            for (i = 0; i < image->height; i++)
                for (j = 0; j < image->width; j++)
                    for (int k=0; k<3; k++)
                    {
                        pImage[j*image->height
                                +(image->height-i-1)
                                +image->width*image->height*k]
                               =  float(image->data[(i*image->width+j)*3+k])/255;
                    }
            libraw_dcraw_clear_mem(image);
        }
    }
    else
    //raw output
    {
        plhs[0] = mxCreateNumericMatrix(S.raw_height,S.raw_width,mxUINT16_CLASS,mxREAL);
        uint16_t * pImage = (uint16_t*)mxGetData(plhs[0]);
        //rotate 90
        for (i = 0; i < S.raw_height; i++)
            for (j = 0; j < S.raw_width; j++)
            {
               pImage[j*S.raw_height+(S.raw_height-i-1)]=
                       RawProcessor.imgdata.rawdata.raw_image[i*S.raw_width+j];
            }
    }
}
