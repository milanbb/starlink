#include "f77.h"
#include "sae_par.h"
#include "mers.h"
#include "tcl.h"
#include <stdio.h>
#include <stdlib.h>
#include "ccdtcl.h"



#define BUFLENG 200


   F77_SUBROUTINE(ccd1_tcurs)( CHARACTER(ndfnam), INTEGER(maxpos), 
                               DOUBLE_ARRAY(percnt), DOUBLE(zoom), 
                               INTEGER(maxcanv), INTEGER(windim),
                               CHARACTER(mstyle),
                               INTEGER_ARRAY(id), DOUBLE_ARRAY(xpos), 
                               DOUBLE_ARRAY(ypos), INTEGER(npos), 
                               INTEGER(status)
                               TRAIL(ndfnam) TRAIL(mstyle) ) {
/*
*+
*  Name:
*     CCD1_TCURS

*  Purpose:
*     Harness Tcl code to get points interactively from a displayed NDF.

*  Language:
*     ANSI C.

*  Invocation:
*     CALL CCD1_TCURS( NDFNAM, MAXPOS, PERCNT, ZOOM, MAXCANV,
*                      WINDIM, MSTYLE, YPOS, NPOS, STATUS )

*  Description:
*     This routine calls a Tcl script which displays an NDF in a window
*     and allows the user to select points on it using an intuitive
*     graphical interface.  It returns a list of the selected points
*     to the calling routine.  If the list of selected points is not
*     empty on entry (if NPOS is not zero) then the list passed in to
*     the routine will be used as a starting point.
*
*     If the user attempts to select more positions than MAXPOS, the
*     GUI part of the application will not allow it, and will force an
*     early exit.

*  Arguments:
*     NDFNAM = CHARACTER * ( * ) (Given)
*        Name of an NDF to use.
*     MAXPOS = INTEGER (Given)
*        The size of the XPOS and YPOS arrays.
*     PERCNT( 2 ) = DOUBLE PRECISION (Given and Returned)
*        Lower and higher percentiles to use in displaying the images.
*        They should satisfy 0 <= PERCNT( 0 ) <= PERCNT( 1 ) <= 100.
*     ZOOM = DOUBLE PRECISION (Given and Returned)
*        The zoom factor for the initial display (may be limited by 
*        MAXCANV).
*     MAXCANV = INTEGER (Given and Returned)
*        The maximum X or Y dimension of canvas on which an initial NDF 
*        is to be displayed (if zero there is no limit).
*     WINDIM( 2 ) = INTEGER (Given and Returned)
*        Dimensions of the window used for display.
*     MSTYLE = CHARACTER * ( * ) (Given and Returned)
*        A string indicating how markers are to be plotted on the image.
*     ID( MAXPOS ) = INTEGER (Given and Returned)
*        The index idenfiers for the positions selected.
*     XPOS( MAXPOS ) = DOUBLE PRECISION (Given and Returned)
*        X coordinates of the positions selected.
*     YPOS( MAXPOS ) = DOUBLE PRECISION (Given and Returned)
*        Y coordinates of the positions selected.
*     NPOS = INTEGER (Given and Returned)
*        The number of X,Y positions selected.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils

*  Authors:
*     MBT: Mark Taylor (STARLINK)
*     {enter_new_authors_here}

*  History:
*     17-APR-2000 (MBT):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
*/

/* Arguments. */
      GENPTR_CHARACTER(ndfnam)
      GENPTR_INTEGER(maxpos)
      GENPTR_DOUBLE(zoom)
      GENPTR_DOUBLE_ARRAY(percnt)
      GENPTR_INTEGER(maxcanv)
      GENPTR_INTEGER_ARRAY(windim)
      GENPTR_CHARACTER(mstyle)
      GENPTR_INTEGER_ARRAY(id)
      GENPTR_DOUBLE_ARRAY(xpos)
      GENPTR_DOUBLE_ARRAY(ypos)
      GENPTR_INTEGER(npos)
      GENPTR_INTEGER(status)

/* Local variables. */
      ccdTcl_Interp *cinterp;
      char buffer[ BUFLENG ];
      char *cmstyle;
      int i;

/* Test the global status. */
      if ( *status != SAI__OK ) return;

/* Initialise the Tcl interpreter. */
      cinterp = ccdTclStart( status );
      if ( *status != SAI__OK ) return;

/* Set the value of Tcl variables to be passed into the script. */
      if ( ( cmstyle = malloc( mstyle_length + 1 ) ) == NULL ) {
         *status = SAI__ERROR;
         errRep( " ", "Memory allocation failed", status );
         return;
      }
      cnfImprt( ndfnam, ndfnam_length, ndfnam );
      cnfImprt( mstyle, mstyle_length, cmstyle );
      ccdTclSetC( cinterp, "NDFNAME", ndfnam, status );
      ccdTclSetI( cinterp, "MAXPOS", *maxpos, status );
      ccdTclSetD( cinterp, "ZOOM", *zoom, status );
      ccdTclSetD( cinterp, "PERCLO", percnt[ 0 ], status );
      ccdTclSetD( cinterp, "PERCHI", percnt[ 1 ], status );
      ccdTclSetI( cinterp, "MAXCANV", *maxcanv, status );
      ccdTclSetI( cinterp, "WINX", windim[ 0 ], status );
      ccdTclSetI( cinterp, "WINY", windim[ 1 ], status );
      ccdTclSetC( cinterp, "MARKSTYLE", cmstyle, status );
      for ( i = 0; i < *npos; i++ ) {
         sprintf( buffer, "lappend POINTS [ list %d %lf %lf ]", 
                          id[ i ], xpos[ i ], ypos[ i ] );
         ccdTclEval( cinterp, buffer, status );
      }

/* Execute the Tcl script. */
      ccdTclRun( cinterp, "idicurs.tcl", status );

/* Retrieve the values generated by the script. */
      ccdTclGetI( cinterp, "llength $POINTS", npos, status );
      if ( *status == SAI__OK ) {
         char *fmt = "lindex [ lindex $POINTS %d ] %d";
         for ( i = 0; i < *npos && i < *maxpos; i++ ) {
            sprintf( buffer, fmt, i, 0 );
            ccdTclGetI( cinterp, buffer, id + i, status );
            sprintf( buffer, fmt, i, 1 );
            ccdTclGetD( cinterp, buffer, xpos + i, status );
            sprintf( buffer, fmt, i, 2 );
            ccdTclGetD( cinterp, buffer, ypos + i, status );
         }
         ccdTclGetD( cinterp, "set ZOOM", zoom, status );
         ccdTclGetD( cinterp, "set PERCLO", percnt, status );
         ccdTclGetD( cinterp, "set PERCHI", percnt + 1, status );
         ccdTclGetI( cinterp, "set MAXCANV", maxcanv, status );
         ccdTclGetI( cinterp, "set WINX", windim, status );
         ccdTclGetI( cinterp, "set WINY", windim + 1, status );
         cnfExprt( ccdTclGetC( cinterp, "set MARKSTYLE", status ), 
                   mstyle, mstyle_length );
         free( cmstyle );
      }

/* Delete the Tcl interpreter. */
      ccdTclStop( cinterp, status );
   }

/* $Id$ */
