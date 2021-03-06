      SUBROUTINE ADI2_EXIREN( FNAME, STATUS )
*+
*  Name:
*     ADI2_EXIREN

*  Purpose:
*     Rename a file to its backup version, if it exists

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL ADI2_EXIREN( FNAME, STATUS )

*  Description:
*     Rename a file to its backup version, if it already exists.

*  Arguments:
*     FNAME = CHARACTER*(*) (given)
*        Name of the file to rename
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

*  {machine}-specific features used:
*     {routine_machine_specifics}...

*  {DIY_prologue_heading}:
*     {DIY_prologue_text}

*  References:
*     ADI Subroutine Guide : http://www.sr.bham.ac.uk/asterix-docs/Programmer/Guides/adi.html

*  Keywords:
*     package:adi, usage:private, FITS

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     6 Feb 1995 (DJA):
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
      CHARACTER*(*)		FNAME

*  Status:
      INTEGER 			STATUS             	! Global status

*  External References:
      EXTERNAL			CHR_LEN
        INTEGER			CHR_LEN

*  Local Variables:
      CHARACTER*20              SYSNAME, NODENAME,	! Operating system
     :                          RELEASE, VERSION, 	! description
     :                          MACHINE
      CHARACTER*200		LFILE			! Local file name
      INTEGER			FLEN			! File name length

      LOGICAL			THERE			! File exists?
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Don't bother with this on VMS
      CALL PSX_UNAME( SYSNAME, NODENAME, RELEASE, VERSION, MACHINE,
     :                STATUS )
      IF ( (INDEX(SYSNAME,'VMS').EQ.0) .AND.
     :     (INDEX(SYSNAME,'vms').EQ.0) ) THEN

*    Make local copy of file
        LFILE = FNAME
        FLEN = CHR_LEN(FNAME)
        LFILE(FLEN+1:FLEN+1) = '~'

*    Does file exist?
        INQUIRE( FILE=FNAME(:FLEN), EXIST=THERE )
        IF ( THERE ) THEN

*      Does a backup file already exist?
          INQUIRE( FILE=LFILE(:FLEN+1), EXIST=THERE )

*      If so, delete it
          IF ( THERE ) THEN
            CALL UTIL_DELETE( LFILE(:FLEN+1), STATUS )
          END IF

*      Rename old file
          CALL UTIL_RENAME( LFILE(:FLEN), LFILE(:FLEN+1), STATUS )

        END IF

*  End of VMS test
      END IF

*  Report any errors
      IF ( STATUS .NE. SAI__OK ) CALL AST_REXIT( 'ADI2_EXIREN', STATUS )

      END
