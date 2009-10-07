/*
 *+
 *  Name:
 *     smf_concat_smfGroup

 *  Purpose:
 *     Concatenate many small chunks of data into single large chunks.

 *  Language:
 *     Starlink ANSI C

 *  Type of Module:
 *     C function

 *  Invocation:
 *     smf_concat_smfGroup( smfWorkForce *wf, const smfGroup *igrp,
 *                          const smfArray *darks, const smfArray *bpms,
 *                          size_t whichchunk, int ensureflat, int isTordered,
 *                          AstFrameSet *outfset, int moving,
 *                          int *lbnd_out, int *ubnd_out, dim_t padStart,
 *                          dim_t padEnd, int flags, smfArray **concat,
 *                          int *status )

 *  Arguments:
 *     wf = smfWorkForce * (Given)
 *        Pointer to a pool of worker threads (can be NULL)
 *     igrp = const smfGroup* (Given)
 *        Group of input data files
 *     darks = const smfArray * (Given)
 *        Collection of darks that can be applied to non-flatfielded data.
 *        Can be NULL.
 *     bpms = smfArray * (Given)
 *        Masks for each subarray (e.g. returned by smf_reqest_mask call)
 *     whichchunk = size_t (Given)
 *        Which continuous subset of igrp will get concatenated?
 *     ensureflat = int (Given)
 *        If true, ensure that the flatfield is applied when opening the data
 *        files, else read them as raw files converted to double.
 *     isTordered = int (Given)
 *        If 0, ensure concatenated data is ordered by bolometer. If 1 ensure
 *        concatenated data is ordered by time slice (default ICD ordering)
 *     outfset = AstFrameSet* (Given)
 *        Frameset containing the sky->output map mapping if calculating
 *        pointing LUT on-the-fly
 *     moving = int (Given)
 *        Is coordinate system tracking moving object? (if outfset specified)
 *     lbnd_out = double* (Given)
 *        2-element array pixel coord. for the lower bounds of the output map
 *        (if outfset specified)
 *     ubnd_out = double* (Given)
 *        2-element array pixel coord. for the upper bounds of the output map
 *        (if outfset specified)
 *     padStart = dim_t (Given)
 *        Pad start of concatenated array with this many samples.
 *     padEnd = dim_t (Given)
 *        Pad end of concatenated array with this many samples.
 *     flags = int (Given)
 *        Additional flags to control processing of individual data files
 *        as they are being concatenated.
 *     concat = smfArray ** (Returned)
 *        smfArray containing concatenated data for each subarray
 *     status = int* (Given and Returned)
 *        Pointer to global status.

 *  Description:
 *     This function takes an input group containing data taken continuously,
 *     but chopped up into smaller files (possibly from multiple subarrays).
 *     This routine attempts to load all of the data into memory at once,
 *     concatenates it into a single contiguous piece of memory for each
 *     subarray, and optionally re-orders the data to bolo-ordered rather
 *     than time-ordered if desired. If a pointing LUT is to be calculated
 *     as data is being loaded, specify outfset, moving, lbnd_out and
 *     ubnd_out. Otherwise set outfset to NULL.
 *
 *  Authors:
 *     EC: Edward Chapin (UBC)
 *     TIMJ: Tim Jenness (JAC, Hawaii)
 *     {enter_new_authors_here}

 *  History:
 *     2007-10-19 (EC):
 *        Initial version.
 *     2007-10-29 (EC):
 *        -Fixed loop bounds for addressing DATA/VARIANCE/QUALITY memory
 *        -Inserted Ast status check after copying FITS headers
 *        -Fixed bug in reference file dimensions
 *        -Modified interface to smf_open_file.
 *     2007-11-15 (EC):
 *        -Added projection information, flags and isTordered to interface.
 *        -With projection info pointing LUT can now be calculated on-the-fly
 *     2007-11-28 (EC):
 *        -Use smf_open_file with SMF__NOCREATE_DATA for first pass
 *        -Set bad status if input is not ICD-compliant time-ordered data
 *        -Fixed bug in time-axis length which depends on output data order
 *     2007-12-14 (EC):
 *        -close reference data
 *        -modified smf_calc_mapcoord interface
 *        -properly set isTordered flag
 *     2008-01-25 (EC):
 *        -use smf_open_and_flatfield in case input data is raw
 *        -store name of first file of subarray with "_con" suffix
 *     2008-02-08 (EC):
 *        -Fixed data type for QUALITY
 *        -generate QUALITY array if not present
 *        -Use SMF__NOCREATE* flags
 *     2008-04-16 (EC):
 *        -added chunking based on time stamps
 *     2008-04-17 (EC):
 *        -fixed calculation of number of subarrays
 *     2008-04-23 (EC):
 *        -propagate time series WCS
 *     2008-06-24 (EC):
 *        Added ability to pad start and end of the data (padStart/padEnd)
 *     2008-07-03 (EC):
 *        Correct time origin in tswcs if padStart set.
 *     2008-07-11 (TIMJ):
 *        Use strlcat/strlcpy
 *     2008-07-22 (TIMJ):
 *        Apply darks.
 *     2008-07-29 (TIMJ):
 *        Steptime is now in smfHead.
 *     2008-09-09 (EC):
 *        Concat dark squid signals.
 *     2008-12-04 (EC):
 *        Padded JCMTState filled with first/last real values.
 *     2009-01-07 (EC):
 *        Stride-ify
 *     2009-01-12 (EC):
 *        Add bad pixel masks (bpms) to interface
 *     2009-09-29 (TIMJ):
 *        Handle pixel origin in concatenated smfData
 *     2009-10-02 (TIMJ):
 *        Copy more information from reference smfData
 *        Allow flatfielding to be disabled.

 *  Notes:
 *     If projection information supplied, pointing LUT will not be
 *     concatenated if SMF__NOCREATE_LUT is specified. By default, a
 *     QUALITY array is created even if one is not present in the
 *     template file. This behaviour can be avoided by setting flag bit
 *     SMF__NOCREATE_QUALITY. Additionally, if VARIANCE and/or QUALITY
 *     is present in the template, prevent propagation to the
 *     concatenated file by setting SMF__NOCREATE_VARIANCE /
 *     SMF__NOCREATE_QUALITY. Specifying padStart and/or padEnd will
 *     pad the data with the specified number of samples. DATA and VARIANCE
 *     are set to 0 in this region. QUALITY to SMF__Q_PAD | SMF__Q_BADB (if
 *     the BADB flag was set at the start of the real data). LUT is set to
 *     VAL__BADI, and the JCMTState values are all set to 0.

 *  Copyright:
 *     Copyright (C) 2007-2009 University of British Columbia.
 *     Copyright (C) 2008 Science and Technology Facilities Council.
 *
 *     All Rights Reserved.

 *  Licence:
 *     This program is free software; you can redistribute it and/or
 *     modify it under the terms of the GNU General Public License as
 *     published by the Free Software Foundation; either version 3 of
 *     the License, or (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be
 *     useful, but WITHOUT ANY WARRANTY; without even the implied
 *     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 *     PURPOSE. See the GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public
 *     License along with this program; if not, write to the Free
 *     Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 *     MA 02111-1307, USA

 *  Bugs:
 *     {note_any_bugs_here}
 *-
 */

#include <stdio.h>

/* Starlink includes */
#include "ast.h"
#include "mers.h"
#include "ndf.h"
#include "sae_par.h"
#include "star/ndg.h"
#include "prm_par.h"
#include "par_par.h"
#include "kpg_err.h"
#include "star/one.h"

/* SMURF includes */
#include "libsmf/smf.h"
#include "libaztec/aztec.h"

#define FUNC_NAME "smf_concat_smfGroup"

void smf_concat_smfGroup( smfWorkForce *wf, const smfGroup *igrp,
                          const smfArray *darks, const smfArray *bpms,
                          size_t whichchunk, int ensureflat, int isTordered,
                          AstFrameSet *outfset, int moving,
                          int *lbnd_out, int *ubnd_out, dim_t padStart,
                          dim_t padEnd, int flags, smfArray **concat,
                          int *status ) {

  /* Local Variables */
  size_t bstr;                  /* Concatenated bolo stride */
  int creflag;                  /* flags for smfData creation */
  smfDA *da=NULL;               /* Pointer to smfDA struct */
  smfData *data=NULL;           /* Concatenated smfData */
  int flag;                     /* Flag */
  char filename[GRP__SZNAM+1];  /* Input filename, derived from GRP */
  dim_t firstpiece = 0;         /* index to start of whichchunk */
  int foundfirst=0;             /* Flag indicates if first index found */
  int foundlast=0;              /* Flag indicates if last index found */
  int havearray[3];             /* flags for DATA/QUALITY/VARIANCE present */
  int havelut;                  /* flag for pointing LUT present */
  smfHead *hdr;                 /* pointer to smfHead in concat data */
  dim_t i;                      /* Loop counter */
  Grp *ingrp=NULL;              /* Pointer to 1-element input group */
  dim_t j;                      /* Loop counter */
  dim_t k;                      /* Loop counter */
  dim_t l;                      /* Loop counter */
  dim_t m;                      /* Loop counter */
  dim_t lastpiece = 0;          /* index to end of whichchunk */
  dim_t nbolo=0;                /* Number of detectors */
  dim_t ncol=0;                 /* Number of columns */
  dim_t ndata;                  /* Total data points: nbolo*tlen */
  dim_t nrelated;               /* Number of subarrays */
  dim_t nrow;                   /* Number of rows */
  Grp *outgrp=NULL;             /* Pointer to 1-element output group */
  size_t outgrpsize;            /* Size of outgrp */
  int pass;                     /* Two passes over list of input files */
  char *pname;                  /* Pointer to input filename */
  unsigned char qual;           /* Set quality */
  smfData *refdata=NULL;        /* Reference smfData */
  smf_dtype refdtype;           /* reference DATA/VARIANCE type */
  const char *refdtypestr;      /* const string for reference data type */
  smfHead *refhdr=NULL;         /* pointer to smfHead in ref data */
  dim_t refncol=0;              /* reference number of rows */
  dim_t refndata;               /* Number data points in reference file */
  dim_t refnrow=0;              /* reference number of rows */
  dim_t reftlen;                /* Number of time slices in reference file */
  size_t rbstr;                 /* Reference bolo stride */
  size_t rtstr;                 /* Reference time slice stride */
  JCMTState *sourceState=NULL;  /* temporary JCMTState pointer */
  double steptime;              /* Length of a sample in seconds */
  dim_t tchunk = 0;             /* Time offset in concat. array this chunk */
  dim_t tend;                   /* Time at start of padded region */
  AstFrame *tframe=NULL;        /* Pointer to TimeFrame */
  dim_t tlen;                   /* Time length entire concatenated array */
  double torigin;               /* Origin of TimeFrame */
  dim_t tstart;                 /* Time at end of padded region */
  smf_dtype type;               /* type of array */
  size_t tstr;                  /* Concatenated time slice stride */
  dim_t sz;                     /* Data type size */

  /* Main routine */
  if (*status != SAI__OK) return;

  /* Verify that we have a valid whichchunk, and determine the range of
     indices into igrp->chunk */
  if( whichchunk > igrp->chunk[igrp->ngroups-1] ) {
    msgSeti( "WHICHCHUNK", whichchunk );
    msgSeti( "MAXCHUNK", igrp->chunk[igrp->ngroups-1] );
    *status = SAI__ERROR;
    errRep( "", FUNC_NAME
            ": Invalid whichchunk: ^WHICHCHUNK. Must be 0 - ^MAXCHUNK",
            status );
  } else {
    /* Find the range of indices */
    foundfirst = 0;
    foundlast = 0;

    for( i=0; i<igrp->ngroups; i++ ) {
      if( (igrp->chunk[i] == whichchunk) && (!foundfirst) ) {
        firstpiece = i;
        foundfirst = 1;
      }

      if( igrp->chunk[i] == whichchunk ) {
        lastpiece = i;
        foundlast = 1;
      }
    }
  }

  /* Check that a valid range was actually found */
  if( (!foundfirst) || (!foundlast) ) {
    *status = SAI__ERROR;
    errRep( "", FUNC_NAME
            ": Possible programming error, couldn't find valid chunk range",
            status );
    return;
  }

  /* Allocate space for the smfArray */
  *concat = smf_create_smfArray( status );

  /* Determine how many subarrays there actually are in this chunk*/
  nrelated = 0;
  for( i=0; (*status == SAI__OK) && i<igrp->nrelated; i++ ) {
    for( j=firstpiece; j<=lastpiece; j++ ) {
      if( (igrp->subgroups[j][i] > 0) && ((i+1) > nrelated) ) {
        nrelated = i+1;
      }
    }
  }

  /* Loop over related elements (number of subarrays) */
  for( i=0; (*status == SAI__OK) && i<nrelated; i++ ) {

    /* Initialize time length of concatenated array to amount of padding */
    tlen = padStart + padEnd;

    /* Two passes over data for the subarray: first time to identify
       dimensions of each file, second time to actually open each file
       and copy into single array. */
    for( pass=0; pass<2; pass++ ) {
      /* Loop over subgroups (number of time chunks), continuing only
         if the chunk is equal to whichchunk */
      for( j=firstpiece; j<=lastpiece; j++ ) {
        /* First pass - get dimensions */
        if( pass == 0 ) {

          smf_open_file( igrp->grp, igrp->subgroups[j][i], "READ",
                         flags, &refdata, status );

          /* Verify that the array is 3-dimensional and compatible with the
             reference array dimensions. */
          if( *status == SAI__OK ) {
            msgSetc( "FILE", refdata->file->name );

            if( refdata->ndims != 3 ) {
              *status = SAI__ERROR;
              errRep( "", FUNC_NAME
                      ": ^FILE does not contain 3-dimensional data!",
                      status );
            }
          }

          /* If data order is 0 (bolo-ordered) then fail since that case
             is not currently handled. */
          if( (*status == SAI__OK) && (refdata->isTordered == 0) ) {
            *status = SAI__ERROR;
            errRep( "", FUNC_NAME
                    ": ^FILE contains bolo-ordered data (unsupported)",
                    status);
          }

          /* Get data dimensions */
          smf_get_dims( refdata, &nrow, &ncol,
                        NULL, &reftlen, NULL, NULL, NULL, status );

          if( *status == SAI__OK ) {
            if( j == firstpiece ) {
              /* If this is the first chunk we will use it for refdims
                 - check the number of bolometers! */
              refnrow = nrow;
              refncol = ncol;

              /* Check for DATA/VARIANCE/QUALITY and data type */
              for( k=0; k<3; k++ ) {
                havearray[k] = (refdata->pntr[k] != NULL);
              }

              /* Concatenated data is always double precision */
              refdtype = SMF__DOUBLE;
              refdtypestr = smf_dtype_string(refdata, status);

            } else {
              /* Check these dims against refdims */
              if( (nrow != refnrow) || (ncol != refncol) ) {
                *status = SAI__ERROR;
                msgSeti( "XREF", refnrow );
                msgSeti( "YREF", refncol );
                msgSeti( "X", nrow );
                msgSeti( "Y", ncol );
                errRep( "", FUNC_NAME ": Detector dimensions (^X,^Y) in "
                        "^FILE do not match reference (^XREF,^YREF)", status );
              }

              /* Check existence of DATA/QUALITY/VARIANCE */
              if( (refdata->pntr[0] != NULL) != havearray[0] ) {
                *status = SAI__ERROR;
                if( havearray[0] ) msgSetc( "FLAG", "is missing" );
                else msgSetc( "FLAG", "has extra" );
                errRep( "", FUNC_NAME ": ^FILE ^FLAG component DATA", status );
              }

              if( (refdata->pntr[1] != NULL) != havearray[1] ) {
                *status = SAI__ERROR;
                if( havearray[1] ) msgSetc( "FLAG", "is missing" );
                else msgSetc( "FLAG", "has extra" );
                errRep( "", FUNC_NAME
                        ": ^FILE ^FLAG component VARIANCE", status );
              }

              if( (refdata->pntr[2] != NULL) != havearray[2] ) {
                *status = SAI__ERROR;
                if( havearray[2] ) msgSetc( "FLAG", "is missing" );
                else msgSetc( "FLAG", "has extra" );
                errRep( "", FUNC_NAME
                        ": ^FILE ^FLAG component QUALITY", status );
              }
            }
          }

          if( *status == SAI__OK ) {
            /* At this stage increment tlen for this chunk */
            tlen += reftlen;
          }

          /* Close the reference file */
          smf_close_file( &refdata, status );
        }

        /* Second pass copy data over to new array */
        if( (pass == 1) && (*status == SAI__OK) ) {
          /* Open the file corresponding to this chunk. Data may
             require flat-fielding. */
          if (ensureflat) {
            smf_open_and_flatfield( igrp->grp, NULL, igrp->subgroups[j][i],
                                    darks, &refdata, status );
          } else {
            smf_open_raw_asdouble( igrp->grp, igrp->subgroups[j][i],
                                   darks, &refdata, status );
          }

          /* Apply bad pixel mask */
          smf_apply_mask( refdata, NULL, bpms, SMF__BPM_DATA, status );

          /* Calculate the pointing LUT if requested */
          if( !(flags & SMF__NOCREATE_LUT) && outfset ) {

            /* Set havelut flag */
            havelut = 1;

            /* Calculate the LUT for this chunk */
            smf_calc_mapcoord( wf, refdata, outfset, moving, lbnd_out, ubnd_out,
                               SMF__NOCREATE_FILE, status );
          } else {
            havelut = 0;
          }

          /* Get reference dimensions/strides */
          smf_get_dims( refdata, NULL, NULL, &nbolo, &reftlen, &refndata,
                        &rbstr, &rtstr, status );

          if( *status == SAI__OK ) {
            /* If first chunk initialize the concatenated array */
            if( j == firstpiece ) {
              /* Copy first data right after the initial padding */
              tchunk = padStart;

              /* Allocate memory for empty smfData with a smfHead. Create
                 a DA struct only if the input file has one. Create it as
                 a clone rather than creating an empty smfDa. */
              data = smf_create_smfData( SMF__NOCREATE_DA, status );
              if (refdata->da) {
                da = smf_deepcopy_smfDA( refdata, status );
                data->da = da;
              }
              if (refdata->history) data->history = astCopy( refdata->history );

              if( *status == SAI__OK ) {
                /* Copy over basic header information from the reference */
                hdr = data->hdr;
                refhdr = refdata->hdr;
                hdr->instrument = refhdr->instrument;
                hdr->steptime = refhdr->steptime;
                hdr->obsmode = refhdr->obsmode;
                hdr->obstype = refhdr->obstype;
                hdr->swmode = refhdr->swmode;

                switch ( hdr->instrument ) {
                case INST__AZTEC:
                  aztec_fill_smfHead( hdr, NDF__NOID, status );
                  break;
                default:
                  break;
                  /* SCUBA-2 has nothing special here because the focal plane
                     coordinates are derived using an AST polyMap */
                }

                /* Copy over the name of the first file in
                   subarray. Use a grpex to strip off the path, and
                   then add the suffix "_con.dimm" to denote concatenated
                   iterative map-maker data */

                ingrp = grpNew( "GRP", status );
                outgrp = grpNew( "GRP", status );

                ndgCpsup( igrp->grp, igrp->subgroups[j][i], ingrp, status );
                ndgCrexp( "./*_con" SMF__DIMM_SUFFIX "|.sdf||", ingrp, &outgrp,
                          &outgrpsize, &flag, status );

                pname = filename;
                grpGet( outgrp, 1, 1, &pname, SMF_PATH_MAX, status);

                grpDelet( &ingrp, status );
                grpDelet( &outgrp, status );

                one_strlcpy( data->file->name, filename,
                             sizeof(data->file->name), status );

                /* Allocate space for the concatenated allState */
                hdr->nframes = tlen;
                hdr->allState = smf_malloc( tlen, sizeof(*(hdr->allState)),
                                            1, status );

                /* Allocate space in the smfData for DATA/VARAIANCE/QUALITY */
                if( isTordered ) {
                  data->dims[SC2STORE__COL_INDEX] = refncol;
                  data->dims[SC2STORE__ROW_INDEX] = refnrow;
                  data->dims[2] = tlen;
                  ncol = data->dims[SC2STORE__COL_INDEX];
                } else {
                  data->dims[0] = tlen;
                  data->dims[SC2STORE__ROW_INDEX+1] = refnrow;
                  data->dims[SC2STORE__COL_INDEX+1] = refncol;
                  ncol = data->dims[1+SC2STORE__COL_INDEX];
                }
                data->ndims = 3;

                /* time ordering should adjust pixel lower bounds automatically */
                for (k = 0; k < 3; k++) {
                  (data->lbnd)[k] = (refdata->lbnd)[k];
                }

                /* Set the data type and order */
                data->dtype = refdtype;
                data->isTordered = isTordered;
                ndata = nbolo*tlen;

                /* get the strides */
                smf_get_dims( data, NULL, NULL, NULL, NULL, NULL,
                              &bstr, &tstr, status );

                /* Allocate space for enlarged dksquid array. */
                if( da ) {
                  da->dksquid = smf_realloc( da->dksquid, ncol*tlen,
                                              sizeof(*(da->dksquid)), status );
                }

                /* Un-set havearray values corresponding to flags */
                havearray[0] = havearray[0] && !(flags&SMF__NOCREATE_DATA);
                havearray[1] = havearray[1] && !(flags&SMF__NOCREATE_VARIANCE);
                havearray[2] = havearray[2] && !(flags&SMF__NOCREATE_QUALITY);

                /* Allocate space for arrays being propagated from template */
                for( k=0; k<3; k++ ) if( havearray[k] ) {
                    if( k == 2 ) sz = smf_dtype_sz( SMF__UBYTE, status );
                    else sz = smf_dtype_sz(data->dtype, status );
                    data->pntr[k] = smf_malloc(ndata, sz, 1, status);
                  }

                /* Check to see if havearray for QUALITY is not set,
                   but SMF__NOCREATE_QUALITY is also not set. In this
                   case, allocate a fresh QUALITY component that will
                   not require propagation from the template */
                if( !havearray[2] && !(flags & SMF__NOCREATE_QUALITY) ) {
                  data->pntr[2] = smf_malloc(ndata,
                                             smf_dtype_sz(SMF__UBYTE,status),
                                             1, status);
                }

                /* Allocate space for the pointing LUT if needed */
                if( havelut ) {
                  data->lut = smf_malloc(ndata, sizeof(*(data->lut)), 1,
                                         status);
                }

                /* Copy over the FITS header */
                if( (*status == SAI__OK) && (refhdr->fitshdr) ) {
                  hdr->fitshdr = astCopy( refhdr->fitshdr );
                  if (!astOK) {
                    if (*status == SAI__OK) {
                      *status = SAI__ERROR;
                      errRep( "", FUNC_NAME ": AST error copying FITS header",
                              status);
                    }
                  }
                }

                /* Copy over the TSWCS */
                if( (*status == SAI__OK) && (refhdr->tswcs) ) {
                  hdr->tswcs = astCopy( refhdr->tswcs );
                  if (!astOK) {
                    if (*status == SAI__OK) {
                      *status = SAI__ERROR;
                      errRep( "", FUNC_NAME
                              ": AST error copying time series WCS",
                              status);
                    }
                  }
                }
              }
            }

            /* Copy DATA/QUALITY/VARIANCE and JCMTstate information into
               concatenated smfData */
            if( *status == SAI__OK ) {
              /* Copy over JCMTstate */
              hdr = data->hdr;
              refhdr = refdata->hdr;

              memcpy( (void *) &(hdr->allState[tchunk]), refhdr->allState,
                      reftlen*sizeof(*hdr->allState) );

              /* Copy LUT */
              if( havelut ) {
                for( l=0; l<nbolo; l++ ) {
                  for( m=0; m<reftlen; m++ ) {
                    data->lut[(tchunk+m)*tstr + l*bstr] =
                      refdata->lut[m*rtstr + l*rbstr];
                  }
                }
              }

              /* dark squids */
              if( da ) {
                memcpy( &(da->dksquid[tchunk*ncol]), refdata->da->dksquid,
                        reftlen*ncol*sizeof(*(da->dksquid)) );
              }

              /* Now do DATA/QUALITY/VARIANCE */
              for( k=0; k<3; k++ ) if( havearray[k] ) {
                  if( k == 2 ) type = SMF__UBYTE;
                  else type = data->dtype;

                  switch( type ) {
                  case SMF__DOUBLE:
                    for( l=0; l<nbolo; l++ ) {
                      for( m=0; m<reftlen; m++ ) {
                        ((double *)data->pntr[k])[(tchunk+m)*tstr + l*bstr] =
                          ((double *)refdata->pntr[k])[m*rtstr + l*rbstr];
                      }
                    }
                    break;
                  case SMF__UBYTE:
                    for( l=0; l<nbolo; l++ ) {
                      for( m=0; m<reftlen; m++ ) {
                        ((unsigned char *)data->pntr[k])[(tchunk+m)*tstr +
                                                         l*bstr] =
                          ((unsigned char *)refdata->pntr[k])[m*rtstr +
                                                              l*rbstr];
                      }
                    }
                    break;
                  default:
                    msgSetc("DTYPE",smf_dtype_str(type, status));
                    *status = SAI__ERROR;
                    errRep( "", FUNC_NAME
                            ": Don't know how to handle ^DTYPE type.", status);
                  }
                }

              /* increment tchunk */
              tchunk += reftlen;
            }
          }
          /* Close the file we had open */
          smf_close_file( &refdata, status );
        }

      }
    }

    /* Full subarray is now concatenated. Finish up by filling the padded
       regions of the data with something intelligent.  */

    for( j=0; (*status==SAI__OK)&&(j<2); j++ ) { /* Loop padded region */
      tstart = 0;
      tend = 0;

      if( (j==0) && padStart ) {
        tstart = 0;
        tend = padStart-1;
      }

      if( (j==1) && padEnd ) {
        tstart = tlen-padEnd;
        tend = tlen-1;
      }

      /* Clean up padded region if nonzero length */
      if( tend != tstart ) {

        /* If QUALITY present, set SMF__Q_BADB as needed and SMF__Q_PAD */
        if( data->pntr[2] ) {
          /* Loop over bolometer */
          for( k=0; k<nbolo; k++ ) {
            /* SMF__Q_PAD always set */
            qual = SMF__Q_PAD;

            /* Check for SMF__Q_BADB in first sample of this bolo */
            qual |= ((char *)data->pntr[2])[padStart*tstr+k*bstr]&SMF__Q_BADB;

            /* Loop over relevant time slices at set quality */
            for( l=tstart; l<=tend; l++ ) {
              ((char *)data->pntr[2])[l*tstr+k*bstr] |=  qual;
            }
          }
        }

        /* If LUT present, set data to VAL__BADI */
        if( data->lut ) {
          for( l=tstart; l<=tend; l++ ) {
            for( k=0; k<nbolo; k++ ) {
              data->lut[l*tstr + k*bstr] = VAL__BADI;
            }
          }
        }

        /* If smfHead->allState present, pad with start/finish values */
        if( (data->hdr) && (data->hdr->allState) ) {
          /* Pointer to first/last real JCMTState */
          if( j==0 ) sourceState = data->hdr->allState + padStart;
          else sourceState = data->hdr->allState + tlen - padEnd - 1;

          /* Loop Over Time slice */
          for( l=tstart; l<=tend; l++ ) {
            memcpy( &(data->hdr->allState[l]),
                    sourceState, sizeof(*sourceState) );
          }
        }
      }
    }

    /* Shift the origin of the time axis in the WCS if padStart != 0 */
    if( padStart && data->hdr && data->hdr->tswcs ) {
      /* Figure out the length of a sample in seconds */
      steptime = data->hdr->steptime;

      if( *status == SAI__OK ) {
        /* Obtain pointer to TimeFrame */
        tframe = astGetFrame( data->hdr->tswcs, AST__CURRENT );

        /* Subtract off padStart*steptime seconds from current TimeOrigin */
        torigin = astGetD( tframe, "TimeOrigin" );
        torigin -= padStart*steptime / (3600.*24.); /* Measured in days */
        astSetD( tframe, "TimeOrigin", torigin );
        tframe = astAnnul( tframe );

        /* Trap AST errors */
        if( !astOK ) {
          *status = SAI__ERROR;
          errRep( "", FUNC_NAME
                  ": AST error correcting TimeOrigin in concatenated data.",
                  status );
        }
      }
    }

    /* Put this concatenated subarray into the smfArray */
    smf_addto_smfArray( *concat, data, status );
  }
}

