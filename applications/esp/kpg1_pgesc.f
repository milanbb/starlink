      SUBROUTINE KPG1_PGESC( TEXT, STATUS )
*+
*  Name:
*     KPG1_PGESC

*  Purpose:
*     Remove PGPLOT escape sequences from a text string.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL  KPG1_PGESC( TEXT, STATUS )

*  Description:
*     This routine removes PGPLOT escape sequences form a text string.
*     Any "\" characters in the string are removed, together with the
*     character following each "\".

*  Arguments:
*     TEXT = CHARACTER * ( * ) (Given and Returned)
*        The text string.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David S. Berry (STARLINK)
*     PWD: Peter W. Draper (STARLINK)
*     {enter_new_authors_here}

*  History:
*     29-SEP-1998 (DSB):
*        Original version.
*     15-APR-2005 (PWD):
*        Parameterise the PGPLOT escape character for better portability.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Local Constants:
      CHARACTER ESC*1            ! The PGPLOT escape character
*  Some compilers need '\\' to get '\', which isn't a problem as Fortran
*  will truncate the string '\\' to '\' on the occasions when that isn't
*  needed.
      PARAMETER( ESC = '\\' )

*  Arguments Given and Returned:
      CHARACTER TEXT*(*)

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      INTEGER CHR_LEN            ! Used length of a string

*  Local Variables:
      CHARACTER C*1              ! Current character
      INTEGER IR                 ! Index of next character to be read
      INTEGER IW                 ! Index of next character to be written
      INTEGER TLEN               ! Significant length of supplied string

*.

*  Check the inherited status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise the index of the next character to be read.
      IR = 1

*  Initialise the index of the next character to be written.
      IW = 1

*  Save the used length of the supplied string.
      TLEN = CHR_LEN( TEXT )

*  Loop round until all potentially significant characters have been read.
      DO WHILE( IR .LE. TLEN )

*  Save the current character.
         C = TEXT( IR : IR )

*  If it is not an escape character, store the read character in the
*  returned string, and increment the index of the next character to be
*  written.
         IF( C .NE. ESC ) THEN
            TEXT( IW : IW ) = C
            IW = IW + 1
*  If it is an escape character, do not store it in the string, but
*  increment the index of the next character to be read in order to skip the
*  character following the esscape character.
         ELSE
            IR = IR + 1
         END IF

*  Move on to read the next character.
         IR = IR + 1

      END DO

*  Fill the remainder of the string with spaces.
      TEXT( IW : ) = ' '

      END
