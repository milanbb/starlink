      SUBROUTINE IRQ_CLOSE( STATUS )
*+
*  Name:
*     IRQ_CLOSE

*  Purpose:
*     Close down the IRQ identifier system.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRQ_CLOSE( STATUS )

*  Description:
*     This routine must be called once all use of compiled quality
*     expression identifiers (as generated by IRQ_COMP) has been
*     completed.  All internal resources used by any such identifiers
*     currently in use are released. Note, this routine does not
*     release the locators created by IRQ_NEW or IRQ_FIND. IRQ_RLSE
*     must be called to release these locators.
*
*     This routine attempts to execute even if STATUS is bad on entry,
*     although no further error report will be made if it subsequently
*     fails under these circumstances.

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 1991 Science & Engineering Research Council.
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
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     16-JUL-1991 (DSB):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT__ constants
      INCLUDE 'IRQ_PAR'          ! IRQ constants.
      INCLUDE 'IRQ_ERR'          ! IRQ error values.

*  Global Variables:
      INCLUDE 'IRQ_COM'          ! IRQ common blocks.
*        QCM_LOC = CHARACTER (Read and Write)
*           An HDS locator to the array of QEXP structures.
*        QCM_STATE = CHARACTER (Read and Write)
*           If QCM_STATE = IRQ__GOING then IRQ has been initialised.
*        QCM_VALID( IRQ__MAXQ ) = LOGICAL (Read)
*           True if the corresponding IRQ identifier is valid (i.e. in
*           use).


*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER I                  ! Loop count.
      INTEGER IDQ                ! IRQ identifier.
      INTEGER TSTAT              ! Saved input STATUS value.
*.

*  If IRQ has not been initialised, return immediately.
      IF( QCM_STATE .NE. IRQ__GOING ) RETURN

*  Save the STATUS value and mark the error stack.
      TSTAT = STATUS
      CALL ERR_MARK

*  Annul each IRQ identifier currently in use. Note, IRQ1_IANNU
*  overwrite the supplied IRQ identifier with the value IRQ__NOID.
      STATUS = SAI__OK

      DO I = 1, IRQ__MAXQ
         IDQ = I
         IF( QCM_VALID( IDQ ) ) CALL IRQ1_IANNU( IDQ, STATUS )
      END DO

*  Delete the array of QEXP structures.
      CALL IRQ1_ANTMP( QCM_LOC, STATUS )

*  Indicate that IRQ is no longer ready for use.
      QCM_STATE = ' '

*  Annul any error if STATUS was previously bad, otherwise let the new
*  error report stand. Release the error stack.
      IF ( STATUS .NE. SAI__OK ) THEN
         IF ( TSTAT .NE. SAI__OK ) THEN
            CALL ERR_ANNUL( STATUS )
            STATUS = TSTAT
         ELSE
            CALL ERR_REP( 'IRQ_CLOSE_ERR1',
     :                 'IRQ_CLOSE: Error closing down the IRQ package',
     :                  STATUS )
         END IF
      ELSE
         STATUS = TSTAT
      END IF
      CALL ERR_RLSE

      END