/*
*+
*  Name:
*     smf_correct_extinction

*  Purpose:
*     Low-level EXTINCTION correction function

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     smf_correct_extinction( AstFrameSet *wcs, const dim_t dims[2], 
*                             float tau, float *data, int *status );

*  Arguments:
*     wcs = AstFrameSet* (Given)
*        AST Frame Set
*     dims[2] = const dim_t (Given)
*        Dimensions of the data array, must be 2 dimensional
*     tau = float (Given)
*        Optical depth at this wavelength
*     data = float* (Given and Returned)
*        2-D data array 
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This is the main routine implementing the EXTINCTION task.


*  Authors:
*     Andy Gibb (UBC)
*     {enter_new_authors_here}

*  History:
*     2005-09-27 (AGG):
*        Initial test version
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2005 Particle Physics and Astronomy Research Council.
*     University of British Columbia.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public
*     License along with this program; if not, write to the Free
*     Software Foundation, Inc., 59 Temple Place,Suite 330, Boston,
*     MA 02111-1307, USA

*  Bugs:
*     {note_any_bugs_here}
*-
*/

#include <stdio.h>

#include "smf.h"
#include "sae_par.h"
#include "ast.h"
#include "prm_par.h"
#include "smurf_par.h"
#include "smurf_typ.h"

/* Fortran prototypes */
#include "f77.h"
F77_DOUBLE_FUNCTION(sla_airmas)( double * );

void smf_correct_extinction(AstFrameSet *wcs, const dim_t dims[], 
			    float tau, float *data, int *status) {


  /* Local variables */
  double airmass;     /* Airmass */
  dim_t i;            /* Loop counter */
  dim_t index;        /* index into vectorized data array */
  dim_t j;            /* Loop counter */
  double xin;         /* X coordinate of input mapping */
  double xout;        /* X coordinate of output */
  double yin;         /* Y coordinate of input */
  double yout;        /* Y coordinate of output */
  double zd;          /* Zenith distance */

  if (*status != SAI__OK) return;

  /* Assume 2 dimensions. Start counting at 1 since this is the GRID
     coordinate frame */
  for (j = 1; j <= dims[1]; j++) {
    for (i = 1; i <= dims[0]; i++) {
      
      index = (j-1)*dims[0] + (i-1);
      if (data[index] != VAL__BADR) {

	xin = (double)i;
	yin = (double)j;
	astTran2( wcs, 1, &xin, &yin, 1, &xout, &yout );

	zd = M_PI_2 - yout;
	airmass = F77_CALL(sla_airmas)( &zd );
	printf( "Airmass: %f\n",airmass);

	printf("Index: %" DIM_T_FMT "  Data: %f  Correction: %f\n",
	       index, data[index], (expf((float)airmass*tau)));
	data[index] *= expf((float)airmass*tau);
      }
    }
  }

}
