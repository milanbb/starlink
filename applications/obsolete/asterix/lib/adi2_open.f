      SUBROUTINE ADI2_OPEN( FID, MID, ID, STATUS )
*+
*  Name:
*     ADI2_OPEN

*  Purpose:
*     Attempt to open an FITS file. If the file is opened ok then the
*     FileHandle object pointed to by ID is updated.

*  Language:
*     Fortran

*  Invocation:
*     CALL ADI2_OPEN( FID, MID, ID, STATUS )

*  Description:
*     Attempts to open the named file object as an FITS file. If successful
*     the routine stores the logical unit and HDU number on the property
*     list of the ID object.

*  Arguments:
*     FID = INTEGER (Given)
*        Name of the object on which FITS access to be attempted
*     MID = CHAR (Given)
*        File access mode
*     ID = INTEGER (Given)
*        ADI identifier of FileHandle object
*     STATUS = INTEGER (Given and returned)
*        The global status.

*  Examples:
*     {routine_example_text}
*        {routine_example_description}

*  Notes:
*     {routine_notes}...

*  Prior Requirements:
*     {routine_prior_requirements}...

*  Side Effects:
*     {routine_side_effects}...

*  Algorithm:
*     {algorithm_description}...

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
*     DJA: David J. Allan (JET-X, University of Birmingham)
*     RB: Richard Beard (ROSAT, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     15 Jul 1994 (DJA):
*        Original version.
*     24 Feb 1997 (RB):
*        Add MODE and REP values.
*     4 Mar 1887 (RB):
*        Use IMODE in FTOPEN (not MODE!).
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'ADI_ERR'

*  Arguments Given:
      INTEGER			FID, MID, ID

*  Status:
      INTEGER 			STATUS             	! Global status

*  External refernced
      INTEGER			CHR_LEN
        EXTERNAL		  CHR_LEN

*  Local Variables:
      CHARACTER*132		ERRTEXT			! FITS error text
      CHARACTER*80		FPATH			! Sub-file stuff
      CHARACTER*200		FSPEC			! File name
      CHARACTER*6		MODE			! Access mode

      INTEGER			BSIZE			! FITS block size
      INTEGER			FSTAT			! FITS inherited status
      INTEGER			FPLEN			! Length of FPATH
      INTEGER			HDU			! HDU number
      INTEGER			HDUTYP			! HDU type
      INTEGER			IMODE			! FITSIO mode
      INTEGER			LFILEC			! Last char in filename
      INTEGER			LUN			! Logical unit number
      INTEGER			REPID			! File representaion ID
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Extract name and access mode
      CALL ADI_GET0C( FID, FSPEC, STATUS )
      CALL ADI_GET0C( MID, MODE, STATUS )

*  Parse the file name
      CALL ADI2_PARSE( FSPEC, LFILEC, HDU, FPATH, FPLEN, STATUS )

*  Get a logical unit from the system
      CALL FIO_GUNIT( LUN, STATUS )

*  Allocated ok?
      IF ( STATUS .EQ. SAI__OK ) THEN

*    Parse access mode
        IF ( (MODE(1:1) .EQ. 'R') .OR. (MODE(1:1) .EQ. 'r') ) THEN
          IMODE = 0
        ELSE IF ( (MODE(1:1) .EQ. 'U') .OR. (MODE(1:1) .EQ. 'u') ) THEN
          IMODE = 1
        END IF

*    Try to open file
        FSTAT = 0
        CALL FTOPEN( LUN, FSPEC(:LFILEC), IMODE, BSIZE, FSTAT )

*    Opened ok?
        IF ( FSTAT .EQ. 0 ) THEN

*      Create the new object
          CALL ADI_NEW0( 'FITSfile', ID, STATUS )

*      Write HDU number
          CALL ADI_CPUT0I( ID, 'UserHDU', HDU, STATUS )

*      Write path info if supplied
          IF ( FPLEN .GT. 0 ) THEN
            CALL ADI_CPUT0C( ID, 'Fpath', FPATH(:FPLEN), STATUS )
          END IF

*      Put in the correct access mode (is any of this necessary?)
          CALL CHR_UCASE( MODE )
          CALL ADI_CPUT0C( ID, 'MODE', MODE(:CHR_LEN(MODE)), STATUS )
          CALL ADI_LOCREP( 'FITS', REPID, STATUS )
          CALL ADI_CPUT0I( ID, 'REP', REPID, STATUS )

*      Initialise HDU cursor
          CALL ADI_CPUT0I( ID, '.CurHdu', -1, STATUS )

*      Write extra info into the file handle object
          CALL ADI_CPUT0I( ID, 'Lun', LUN, STATUS )
          CALL ADI_CPUT0I( ID, 'BlockSize', BSIZE, STATUS )

*      Skip to HDU if specified
          IF ( HDU .GT. 0 ) THEN
            CALL ADI2_MVAHDU( ID, LUN, HDU, HDUTYP, STATUS )
          END IF

*    Failed to open
        ELSE
          CALL FIO_PUNIT( LUN, STATUS )

          STATUS = ADI__RETRY
          CALL FTGERR( FSTAT, ERRTEXT )
          CALL MSG_SETC( 'REASON', ERRTEXT )
          CALL ERR_REP( ' ', '^REASON', STATUS )

*    End opened ok test
        END IF

*  End acquired logical unit test
      END IF

      END
