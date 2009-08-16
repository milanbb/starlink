      SUBROUTINE NDF1_FR2PX( NAX, NDIM, NLBND, NUBND, ISBND, VALUE1, 
     :                       VALUE2, FRAME1, FRAME2, STATUS )
*+
*  Name:
*     NDF1_FR2PX

*  Purpose:
*     Convert FRACTION axis values to pixel indices.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL NDF1_FR2PX( NAX, NDIM, NLBND, NUBND, ISBND, VALUE1, VALUE2, 
*                      FRAME1, FRAME2, STATUS )

*  Description:
*     This routine converts any supplied FRACTION values to corresponding
*     pixel indices.

*  Arguments:
*     NAX = INTEGER (Given)
*        The number of WCS axis bound supplied.
*     NDIM = INTEGER (Given)
*        The number of pixel axes in the NDF.
*     NLBND( NDIM ) = INTEGER (Given)
*        The NDF lower pixel bounds.
*     NUBND( NDIM ) = INTEGER (Given)
*        The NDF upper pixel bounds.
*     ISBND( NDIM ) = LOGICAL (Given)
*        Whether VALUE1 and VALUE2 specify the lower and upper bounds
*        directly (i.e. .TRUE. ==> a ':' separator was given or
*        implied, whereas .FALSE. ==> a '~' separator was given).
*     VALUE1( NAX ) = DOUBLE PRECISION (Given and returned)
*        First value specifying the bound on each axis. 
*     VALUE2( NAX ) = DOUBLE PRECISION (Given and returned)
*        Second value specifying the bound on each axis. 
*     FRAME1( NAX ) = LOGICAL (Given and returned)
*        0 ==> VALUE1 is to be interpreted as a WCS or axis coordinate 
*        value, 1 ==> it is a pixel index, 2 ==> it is a FRACTION value.
*     FRAME2( NAX ) = LOGICAL (Given and returned)
*        0 ==> VALUE2 is to be interpreted as a WCS or axis coordinate 
*        value, 1 ==> it is a pixel index, 2 ==> it is a FRACTION value.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 2009 Science & Technology Facilities Council.
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
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     DSB: David S Berry (JACH, UCLan)
*     {enter_new_authors_here}

*  History:
*     4-AUG-2009 (DSB):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'NDF_PAR'          ! NDF_ public constants      
      INCLUDE 'AST_PAR'          ! AST_ constants and functions
      INCLUDE 'NDF_ERR'          ! NDF_ error codes

*  Arguments Given:
      INTEGER NAX
      INTEGER NDIM
      INTEGER NLBND( NDIM )
      INTEGER NUBND( NDIM )
      LOGICAL ISBND( NDIM )

*  Arguments Given and Returned:
      DOUBLE PRECISION VALUE1( NAX )
      DOUBLE PRECISION VALUE2( NAX )
      INTEGER FRAME1( NAX )
      INTEGER FRAME2( NAX )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      DOUBLE PRECISION A
      DOUBLE PRECISION B
      INTEGER I
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Check each supplied axis bound
      DO I = 1, NAX

*  Get the constants relating FRACTION value to pixel coord for the
*  current pixel axis.
         IF( I .LE. NDIM ) THEN
            B = DBLE( NLBND( I ) - 1 )
            A = DBLE( NUBND( I ) ) - B
         ELSE
            B = 0.0D0
            A = 1.0D0
         END IF

*  Check the first bound. Skip if it is not a FRACTION value. Otherwise,
*  convert the fraction bound into a pixel index.
         IF( FRAME1( I ) .EQ. 2 ) THEN
            VALUE1( I ) = NINT( 0.5D0 + VALUE1( I )*A + B )
            FRAME1( I ) = 1
         END IF

*  Check the second bound in the same way if it is a bound. If it is a
*  range, convert using an appropriate scaling.
         IF( FRAME2( I ) .EQ. 2 ) THEN
            IF( ISBND( I ) ) THEN
               VALUE2( I ) = NINT( 0.5D0 + VALUE2( I )*A + B )
            ELSE
               VALUE2( I ) = NINT( VALUE2( I )*
     :                             DBLE( NUBND( I ) - NLBND( I ) + 1 ) )
               IF( VALUE2( I ) .LT. 1 ) VALUE2( I ) = 1
            END IF
            FRAME2( I ) = 1
         END IF

      END DO

*  Call error tracing routine and exit.
      IF ( STATUS .NE. SAI__OK ) CALL NDF1_TRACE( 'NDF1_FR2PX', STATUS )

      END