      SUBROUTINE ADI2_GETHDI( ID, IHDU, HNAME, STATUS )
*+
*  Name:
*     ADI2_GETHDI

*  Purpose:
*     Read HDU index entry

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL ADI2_GETHDI( ID, IHDU, HNAME, STATUS )

*  Description:
*     Reads an HDU index entry.

*  Arguments:
*     ID = INTEGER (given)
*        ADI identifier of FITSfile object
*     IHDU = INTEGER (given)
*        The consecutive HDU number
*     HNAME = CHARACTER*(*) (given)
*        Name of the HDU we're indexing
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
*     ADI Subroutine Guide : http://www.sr.bham.ac.uk/asterix-docs/Programmer/Guides/adi.html

*  Keywords:
*     package:adi, usage:private

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     11 Sep 1995 (DJA):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      INTEGER			ID, IHDU

*  Arguments Returned:
      CHARACTER*(*)		HNAME

*  Status:
      INTEGER 			STATUS             	! Global status

*  Local Variables:
      CHARACTER*4		HINAM			! Index name

      INTEGER			HIID			! HDU index
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Locate the HDU index in the file
      CALL ADI_FIND( ID, 'HduIndex', HIID, STATUS )

*  Write index component name
      WRITE( HINAM, '(A1,I3.3)' ) 'H', IHDU
      CALL ADI_CGET0C( HIID, HINAM, HNAME, STATUS )

*  Release the HDU index
      CALL ADI_ERASE( HIID, STATUS )

*  Report any errors
      IF ( STATUS .NE. SAI__OK ) CALL AST_REXIT( 'ADI2_GETHDI', STATUS )

      END
