/*
*+
*  Name:
*     CALCDARK

*  Purpose:
*     Calculate the 2d dark frame from dark observation.

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     smurf_calcdark( int *status );

*  Arguments:
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     Given a set of dark observations, calculate the dark frame from each.
*     Does not flatfield.

*  Notes:

*  ADAM Parameters:
*     IN = NDF (Read)
*          Input files to be processed. Non-darks will be filtered out.
*     OUT = NDF (Write)
*          Output dark files.

*  Authors:
*     Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     2008-08-22 (TIMJ):
*        Initial version.
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2008 Science and Technology Facilities Council.
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

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <string.h>
#include <stdio.h>

#include "star/kaplibs.h"
#include "star/grp.h"
#include "star/ndg.h"
#include "ndf.h"
#include "mers.h"
#include "prm_par.h"
#include "sae_par.h"
#include "msg_par.h"

#include "smurf_par.h"
#include "libsmf/smf.h"
#include "smurflib.h"
#include "libsmf/smf_err.h"
#include "sc2da/sc2store.h"

#define FUNC_NAME "smurf_calcdark"

void smurf_calcdark( int *status ) {

  smfArray *darks = NULL;   /* set of processed darks */
  Grp *dgrp = NULL;         /* Group of darks */
  size_t i;                 /* Loop index */
  int indf;                 /* NDF identifier for input file */
  Grp *igrp = NULL;         /* Input group of files */
  Grp *ogrp = NULL;         /* Output group of files */
  size_t outsize;           /* Total number of NDF names in the output group */
  size_t size;              /* Number of files in input group */

  /* Main routine */
  ndfBegin();

  /* Get input file(s) */
  kpg1Rgndf( "IN", 0, 1, "", &igrp, &size, status );

  /* Filter out non-darks and reduce the darks themselves */
  smf_find_darks( igrp, NULL, &dgrp, 1, &darks, status );

  /* no longer need the input group */
  grpDelet( &igrp, status );

  /* Get output file(s) */
  size = grpGrpsz( dgrp, status );
  kpg1Wgndf( "OUT", dgrp, size, size, "More output files required...",
             &ogrp, &outsize, status );

  for (i=1; i<=size; i++ ) {
    smfData * outdata = NULL; /* output data file smfData */
    smfFile * outfile = NULL; /* output file information */
    smfData * dark = (darks->sdata)[i-1]; /* This dark */
    int lbnd[2] = { 1, 1 };
    int ubnd[2];

    if (*status != SAI__OK) break;

    /* Open input file and create output file. Do not propagate
       since we do not want to get a large file the wrong size */
    ndgNdfas( dgrp, i, "READ", &indf, status );

    ubnd[0] = lbnd[0] + (dark->dims)[0] - 1;
    ubnd[1] = lbnd[1] + (dark->dims)[1] - 1;
    smf_open_newfile( ogrp, i, dark->dtype, dark->ndims, lbnd, ubnd,
                      SMF__MAP_VAR, &outdata, status );
    outfile = outdata->file;

    /* Update provenance in the output before we close the input
       because sc2store will not give us access to an NDF identifier
       from the raw time series */
    if (outfile) {
      smf_updateprov( outfile->ndfid, NULL, indf,
                      "SMURF:CALCDARK", status );
    }
    ndfAnnul( &indf, status);

    if (*status == SAI__OK) {
      size_t nbperel = smf_dtype_size( dark, status );
      size_t nelem = (dark->dims)[0] * (dark->dims)[1];

      /* Copy the dark data into the output file */
      memcpy( (outdata->pntr)[0], (dark->pntr)[0], nelem * nbperel );
      memcpy( (outdata->pntr)[1], (dark->pntr)[1], nelem * nbperel );

      /* Set labels */
      ndfCput( "Dark", outfile->ndfid, "TITLE", status);

      /* Fits header */
      kpgPtfts(outfile->ndfid, dark->hdr->fitshdr, status );

    }

    /* Free resources for files */
    smf_close_file( &outdata, status );
  }

  /* Tidy up after ourselves: release the resources used by the grp routines  */
  grpDelet( &dgrp, status);
  grpDelet( &ogrp, status);
  smf_close_related( &darks, status );

  ndfEnd( status );
}

