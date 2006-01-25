/*
*+
*  Name:
*     smf_correct_extinction

*  Purpose:
*     Low-level EXTINCTION correction function

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Subroutine

*  Invocation:
*     smf_correct_extinction( smfData *data, double tau, int *status) {

*  Arguments:
*     data = smfData* (Given)
*        smfData struct
*     tau = float (Given)
*        Optical depth from the command line
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This is the main routine implementing the EXTINCTION task.


*  Authors:
*     Andy Gibb (UBC)
*     Tim Jenness (TIMJ)
*     {enter_new_authors_here}

*  History:
*     2005-09-27 (AGG):
*        Initial test version
*     2005-11-14 (AGG):
*        Update API to accept a smfData struct
*     2005-12-20 (AGG):
*        Store the current coordinate system on entry and reset on return.
*     2005-12-21 (AGG):
*        Use the curslice as a frame offset into the timeseries data
*     2005-12-22 (AGG):
*        Deprecate use of curslice, make use of virtual flag instead
*     2006-01-11 (AGG):
*        API updated: tau no longer needed as it is retrieved from the
*        header. For now, image data uses the MEANWVM keyword from the
*        FITS header
*     2006-01-12 (AGG):
*        API update again: tau will be needed in the case the user
*        supplies it at the command line
*     2006-01-24 (AGG):
*        Floats to doubles
*     2006-01-25 (AGG):
*        Code factorization to simplify logic. Also corrects variance
*        if present.
*     2006-01-25 (TIMJ):
*        1-at-a-time astTran2 is not fast. Rewrite to do the astTran2
*        a frame at a time.
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2005-2006 Particle Physics and Astronomy Research
*     Council. University of British Columbia. All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
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

/* Standard includes */
#include <stdio.h>

/* Starlink includes */
#include "sae_par.h"
#include "ast.h"
#include "mers.h"
#include "msg_par.h"
#include "prm_par.h"

/* SMURF includes */
#include "smf.h"
#include "smurf_par.h"
#include "smurf_typ.h"

/* Fortran prototypes */
#include "f77.h"
F77_DOUBLE_FUNCTION(sla_airmas)( double * );

/* Simple default string for errRep */
#define FUNC_NAME "smf_correct_extinction"

void smf_correct_extinction(smfData *data, const char *method, double tau, int *status) {

  /* Local variables */
  smfHead *hdr;            /* Pointer to full header struct */
  dim_t i;                 /* Loop counter */
  dim_t j;                 /* Loop counter */
  const char *origsystem;  /* Character string to store the coordinate
			      system on entry */
  AstFrameSet *wcs;        /* Pointer to AST WCS frameset */
  double airmass;          /* Airmass */
  double *indata;          /* Pointer to data array */
  double *vardata;          /* Pointer to variance array */
  dim_t index;             /* index into vectorized data array */
  dim_t k;                 /* Loop counter */
  double *xin;              /* X coordinates of input mapping */
  double *xout;             /* X coordinates of output */
  double *yin;              /* Y coordinates of input */
  double *yout;             /* Y coordinates of output */
  double zd;               /* Zenith distance */
  size_t * indices;

  size_t nframes = 0;        /* Number of frames */
  size_t npts;
  double extcorr;
  size_t base;
  int z;

  /* Check status */
  if (*status != SAI__OK) return;

  /* Do we have 2-D image data? */
  if (data->ndims == 2) {

    nframes = 1;

  } else if (data->ndims == 3 ) {

    nframes = (data->dims)[2];

  } else {
    /* Abort with an error if the number of dimensions is not 2 or 3 */
    if ( *status == SAI__OK) {
      *status = SAI__ERROR;
      msgSeti("ND", data->ndims);
      errRep(FUNC_NAME,
	     "Number of dimensions of input file is ^ND; should be either 2 or 3",
	     status);
    }
  }

  /* Should check data type for double */
  smf_dtype_check_fatal( data, NULL, SMF__DOUBLE, status);
  if ( *status != SAI__OK) return;

  /* Assign pointer to input data array */
  /* of course, check status on return... */
  indata = (data->pntr)[0]; 
  vardata = (data->pntr)[1];
  npts = (data->dims)[0] * (data->dims)[1];

  /* It is more efficient to call astTran2 with all the points
     rather than one point at a time */
  xin = malloc( npts * sizeof(double) );
  yin = malloc( npts * sizeof(double) );
  xout = malloc( npts * sizeof(double) );
  yout = malloc( npts * sizeof(double) );
  indices = malloc( npts * sizeof(size_t) );

  /* Assume malloc worked for now */
  /* Prefill with coordintes */
  z = 0;
  for (j = 0; j < (data->dims)[1]; j++) {
    base = j *(data->dims)[0];
    for (i = 0; i < (data->dims)[0]; i++) {
      xin[z] = (double)i + 1.0;
      yin[z] = (double)j + 1.0;
      indices[z] = base + i; /* index into data array */
      z++;
    }
  }

  /* Loop over number of time slices/frames */
  for ( k=0; k<nframes; k++) {
    /* Call tslice_ast to update the header for the particular
       timeslice */
    smf_tslice_ast( data, k, status );
    /*    smf_tslice( data, &tdata, j, status );*/
    /* Retrieve header info */
    hdr = data->hdr;
    wcs = hdr->wcs;
    /* Check current frame and store it */
    origsystem = astGetC( wcs, "SYSTEM");
    /* Select the AZEL system */
    if (wcs != NULL) 
      astSetC( wcs, "SYSTEM", "AZEL" );
    if (!astOK) {
      if (*status == SAI__OK) {
	*status = SAI__ERROR;
	errRep( FUNC_NAME, "Error from AST", status);
      }
    }

    /* Transfrom from pixels to AZEL */
    astTran2(wcs, npts, xin, yin, 1, xout, yout );

    /* Loop over data in time slice. Start counting at 1 since this is
       the GRID coordinate frame */
    base = npts * k; /* Offset into 3d data array */
    for (i=0; i < npts; i++ ) {
      index = indices[i] + base;
      if (indata[index] != VAL__BADD) {
	zd = M_PI_2 - yout[indices[i]];
	airmass = F77_CALL(sla_airmas)( &zd );
	/*    printf( "Zenith distance: %f, Airmass: %f El: %f\n",zd, airmass);*/
	/*    printf("Index: %" DIM_T_FMT "  Data: %f  Correction: %f\n",
	  index, indata[index], (exp(airmass*(double)tau)));*/
	extcorr = exp(airmass*tau);
	indata[index] *= extcorr;
	if (vardata != NULL && vardata[index] != VAL__BADD) {
	  vardata[index] *= extcorr*extcorr;
	}
      }
    }

    /* Restore coordinate frame to original */
    if ( *status == SAI__OK) {
      astSetC( wcs, "SYSTEM", origsystem );
      /* Check AST status */
      if (!astOK) {
	if (*status == SAI__OK) {
	  *status = SAI__ERROR;
	  errRep( FUNC_NAME, "Error from AST", status);
	}
      }
    }

  }

  free(xin);
  free(yin);
  free(xout);
  free(yout);
  free(indices);

}
