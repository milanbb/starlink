      SUBROUTINE IRQ1_GET( LOCS, SLOT, QNAME, FIXED, VALUE, BIT, COMMNT,
     :                     STATUS )
*+
*  Name:
*     IRQ1_GET

*  Purpose:
*     Get a quality name from a given slot.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRQ1_GET( LOCS, SLOT, QNAME, FIXED, VALUE, BIT, COMMNT,
*                    STATUS )

*  Description:
*     The quality information is retrieved from the given slot. If the
*     slot is not currently in use, and error is reported.

*  Arguments:
*     LOCS( 5 ) = CHARACTER * ( * ) (Given)
*        A set of 5 HDS locators. LOCS( 1 ) locates a temporary
*        structure holding a cloned NDF identifier. LOCS(2) locates the
*        QUAL array. LOCS(3) locates the LAST_USED value, holding the
*        index of the last used slot in the QUAL array. LOCS(4) locates
*        the NFREE value, holding the number of free slots in the QUAL
*        array. LOCS(5) locates the FREE array, which contains a stack
*        of the NFREE slot indices corresponding to free slots. This
*        stack is accessed in a "First-In-Last-Out" method.
*     SLOT = INTEGER (Given)
*        The index at which the required information is stored in the
*        QUAL array.
*     QNAME = CHARACTER * ( * ) (Returned)
*        The quality name.
*     FIXED = LOGICAL (Returned)
*        True if all or none of the pixels hold the quality. False is
*        some do and some don't.
*     VALUE = LOGICAL (Returned)
*        If FIXED is true and VALUE is true, then the quality is held
*        by all pixels by default.  If FIXED is true and VALUE is
*        false, then the quality is held by no pixels. If FIXED is
*        false, then VALUE is indeterminate.
*     BIT = INTEGER (Returned)
*        If FIXED is false, then this gives the bit number within the
*        QUALITY component which corresponds with the quality name. If
*        FIXED is true, then BIT is indeterminate. The least significant
*        bit is called bit 1 (not bit 0).
*     COMMNT = CHARACTER * ( * ) (Returned)
*        A descriptive comment stored with the name.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     26-JUL-1991 (DSB):
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

*  Arguments Given:
      CHARACTER LOCS(5)*(*)
      INTEGER SLOT

*  Arguments Returned:
      CHARACTER QNAME*(*)
      LOGICAL FIXED
      LOGICAL VALUE
      INTEGER BIT
      CHARACTER COMMNT*(*)

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER LUSED              ! Index of last used slot in QUAL array.
      CHARACTER QULOC*(DAT__SZLOC)! Locator to a single cell of the QUAL
                                 ! array.

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Get the index of the last used slot.
      CALL DAT_GET0I( LOCS(3), LUSED, STATUS )

*  If the index of the required slot is greater than that of the last
*  used slot, report an error.
      IF( SLOT .GT. LUSED .AND. STATUS .EQ. SAI__OK ) THEN
         STATUS = IRQ__BADSL
         CALL MSG_SETI( 'SL', SLOT )
         CALL ERR_REP( 'IRQ1_GET_ERR1',
     :       'IRQ1_GET: Quality name no. ^SL is not currently defined.',
     :                 STATUS )
      END IF

*  Get a locator to the requested slot of the QUAL array.
      CALL DAT_CELL( LOCS(2), 1, SLOT, QULOC, STATUS )
      IF ( STATUS .NE. SAI__OK ) GO TO 999

*  Get the quality name.
      CALL CMP_GET0C( QULOC, IRQ__NMNAM, QNAME, STATUS )

*  If the name is not defined, signal a bad slot structure.
      IF( STATUS .NE. SAI__OK ) THEN
         CALL ERR_ANNUL( STATUS )
         QNAME = IRQ__SBAD
      END IF

*  If a bad slot structure is found, report an error.
      IF( QNAME .EQ. IRQ__SBAD ) THEN
         STATUS = IRQ__BADST
         CALL ERR_REP( 'IRQ1_GET_ERR',
     :                 'IRQ1_GET: Incomplete slot structure found',
     :                 STATUS )

*  If the name is not currently in use, report an error.
      ELSE IF( QNAME .EQ. IRQ__SFREE ) THEN
         STATUS = IRQ__BADSL
         CALL MSG_SETI( 'SL', SLOT )
         CALL ERR_REP( 'IRQ1_GET_ERR2',
     :       'IRQ1_GET: Quality name no. ^SL is not currently defined.',
     :                 STATUS )
      END IF

*  Get the other items of information.
      CALL CMP_GET0L( QULOC, IRQ__FXNAM, FIXED, STATUS )
      CALL CMP_GET0L( QULOC, IRQ__VLNAM, VALUE, STATUS )
      CALL CMP_GET0I( QULOC, IRQ__BTNAM, BIT, STATUS )
      CALL CMP_GET0C( QULOC, IRQ__CMNAM, COMMNT, STATUS )

*  Annul the locator to the cell of QUAL.
 999  CONTINUE

      CALL DAT_ANNUL( QULOC, STATUS )

      END
