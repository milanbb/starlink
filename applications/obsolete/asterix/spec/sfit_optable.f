*+  SFIT_OPTABLE - Write a table with parameters & approx errors
      SUBROUTINE SFIT_OPTABLE( NPAR, PARAM, FROZEN, PEGGED, PARSIG,
     :                                         IMOD, OCI, STATUS )
*
*    Description :
*
*     Writes a table containing the model parameter names, values and
*     approximate errors.
*
*    Method :
*
*    Deficiencies :
*    Bugs :
*    Authors :
*
*     David J. Allan (BHVAD::DJA)
*
*    History :
*
*      8 Dec 92 : Original (DJA)
*     25 Jul 94 : Converted to use AIO system (DJA)
*
*    Type definitions :
*
      IMPLICIT NONE
*
*    Global constants :
*
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'FIT_PAR'
*
*    Structure definitions :
*
      INCLUDE 'FIT_STRUC'
*
*    Status :
*
      INTEGER STATUS
*
*    Import :
*
      INTEGER               NPAR          ! Number of parameters
      REAL                  PARAM(NPAR)   ! Parameter values
      LOGICAL               FROZEN(NPAR)  ! Parameter frozen?
      LOGICAL               PEGGED(NPAR)  ! Parameter pegged?
      REAL                  PARSIG(NPAR)  ! Parameter values
c     RECORD /MODEL_SPEC/   MODEL	  ! Model specification
      INTEGER		    IMOD
      INTEGER		    OCI		  ! AIO stream id
*
*    Local variables :
*
      CHARACTER*27          OPSTRING      ! Parameter state
      CHARACTER*79          OTXT          ! Output text buffer
      CHARACTER*12          PFMT	  ! Format to use for printing

      INTEGER               J		  ! Parameter index
      INTEGER               NC		  ! Model component number
*-

*    Check status
      IF ( STATUS .NE. SAI__OK ) RETURN

*    A couple of blank lines
      CALL AIO_BLNK( OCI, STATUS )
      CALL AIO_BLNK( OCI, STATUS )

*    Heading underlined
      WRITE( OTXT, 100 )
 100  FORMAT( 7X,'Parameter',18X,'Value',6X,'Approx error (1 sigma)' )
      CALL AIO_WRITE( OCI, OTXT(:71), STATUS )
      CALL CHR_FILL( '-', OTXT )
      CALL AIO_WRITE( OCI, OTXT(:71), STATUS )

*    Loop over parameters
      NC=1
      DO J = 1, NPAR

*      Format to use for value printing
        IF ( MODEL_SPEC_FORMAT(IMOD,J) .GT. ' ' ) THEN
          PFMT = MODEL_SPEC_FORMAT(IMOD,J)
        ELSE
          PFMT = '1PG12.5'
        END IF

*      String to describe parameter state, or error if free
	IF ( FROZEN(J) ) THEN
	  WRITE ( OPSTRING, '(''   Frozen'')' )
	ELSE IF ( PEGGED(J) ) THEN
	  WRITE ( OPSTRING,'(''   pegged'')' )
	ELSE
          IF ( (MODEL_SPEC_NTIE(IMOD).GT.0) .AND.
     :         (MODEL_SPEC_TGROUP(IMOD,J).GT.0) ) THEN
            IF ( J .NE.
     :           MODEL_SPEC_TSTART(IMOD,
     :                             MODEL_SPEC_TGROUP(IMOD,J)) ) THEN
	      WRITE( OPSTRING, '('//PFMT//',1X,A)' ) PARSIG(J),
     :                                    '(constrained)'
            ELSE
	      WRITE( OPSTRING, '('//PFMT//')' ) PARSIG(J)
            END IF
          ELSE
	    WRITE( OPSTRING, '('//PFMT//')' ) PARSIG(J)
          END IF
	END IF

*      Format the parameter information. Only write model component name
*      for the first component in each model.
        IF ( J .EQ. MODEL_SPEC_ISTART(IMOD,NC) ) THEN
          WRITE(OTXT,'(A4,3X,A25,'//PFMT//',2X,A)')
     :               MODEL_SPEC_KEY(IMOD,NC),
     :               MODEL_SPEC_PARNAME(IMOD,J), PARAM(J),OPSTRING
          NC = NC + 1
        ELSE
          WRITE(OTXT,'(7X,A25,'//PFMT//',2X,A)')
     :              MODEL_SPEC_PARNAME(IMOD,J), PARAM(J), OPSTRING
        END IF

*      Write line describing parameters
        CALL AIO_WRITE( OCI, OTXT, STATUS )

      END DO

      END
