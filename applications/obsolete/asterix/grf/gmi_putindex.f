      SUBROUTINE GMI_PUTINDEX( ID, NUM, ENTRY, STATUS )
*+
*  Name:
*     GMI_PUTINDEX

*  Purpose:
*     Adds specified entry to multiple dataset index

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL GMI_PUTINDEX( ID, NUM, ENTRY, STATUS )

*  Description:
*     {routine_description}

*  Arguments:
*     ID = INTEGER (given)
*        ADI identifier of MultiGraph object
*     NUM = INTEGER (given)
*        Number of entry required
*     ENTRY = CHARACTER*(*) (given)
*        The index entry
*     STATUS = INTEGER (given and returned)
*        The global status.

*  Examples:
*     {routine_example_text}
*        {routine_example_description}

*  Pitfalls:
*     {pitfall_description}...

*  Notes:
*     {routine_notes}...

*  Prior Requirements:
*     {routine_prior_requirements}...

*  Side Effects:
*     {routine_side_effects}...

*  Algorithm:
*     {algorithm_description}...

*  Accuracy:
*     {routine_accuracy}

*  Timing:
*     {routine_timing}

*  External Routines Used:
*     {name_of_facility_or_package}:
*        {routine_used}...

*  Implementation Deficiencies:
*     {routine_deficiencies}...

*  References:
*     GMI Subroutine Guide : http://www.sr.bham.ac.uk/asterix-docs/Programmer/Guides/gmi.html

*  Keywords:
*     package:gmi, usage:public

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     5 Oct 1995 (DJA):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'

*  Arguments Given:
      INTEGER			ID, NUM
      CHARACTER*(*)		ENTRY

*  Status:
      INTEGER 			STATUS             	! Global status

*  Local Variables:
      CHARACTER*(DAT__SZLOC)	LOC			! Dataset locator
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Get locator and invoke HDS version
      CALL ADI1_GETLOC( ID, LOC, STATUS )
      CALL GMD_PUTINDEX( LOC, NUM, ENTRY, STATUS )

*  Report any errors
      IF ( STATUS .NE. SAI__OK ) CALL AST_REXIT( 'GMI_PUTINDEX', STATUS )

      END
