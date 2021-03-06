	SUBROUTINE FITSWGET2( LOCCELL, UT, STATUS)

	IMPLICIT NONE

	INCLUDE 'SAE_PAR'

	INTEGER NDIMS, DIMS( 2), STATUS

	REAL UT( 4)

	CHARACTER*15 LOCTEMP
	CHARACTER*( *) LOCCELL

*      test status on entry
	IF( STATUS .NE. SAI__OK) THEN
	  RETURN
	END IF

*      get the primitive parameters defining an observation
	NDIMS = 1
	DIMS( 1) = 4
	DIMS( 2) = 0
	CALL DAT_FIND( LOCCELL, 'UT_TIME', LOCTEMP, STATUS)
	CALL DAT_GETR( LOCTEMP, NDIMS, DIMS, UT, STATUS)
	CALL DAT_ANNUL( LOCTEMP, STATUS)
	STATUS = SAI__OK

	END
