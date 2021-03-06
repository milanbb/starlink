      SUBROUTINE CORRECT( STATUS )
*+
*  Name:
*     CORRECT

*  Purpose:
*     Normalise a binned dataset in time

*  Language:
*     Starlink Fortran

*  Type of Module:
*     ASTERIX task

*  Invocation:
*     CALL CORRECT( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     Normalises binned datasets in time, ie. converts the input file
*     with units X to X/second (X could be counts, or counts per unit
*     area).

*  Usage:
*     correct {parameter_usage}

*  Environment Parameters:
*     INP = CHAR (read)
*        Input dataset name
*     OVER = LOGICAL (read)
*        Overwrite the input file?
*     OUT = CHAR (read)
*        Output dataset. Only used if OVER is false
*     TEXP = REAL (read)
*        Exposure time. Only used if not present in file
*     POISS = LOGICAL (read)
*        Copy data to variance if not present on input?

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
*     The complexity of the operation required depends on the components
*     present in the input.
*
*      T_RESOLVED = NO
*      IF LIVE_TIMEs are present THEN
*        T_RESOLVED = YES
*      END IF
*      IF header.EFF_EXPOSURE is present
*        TEXP = HEADER.EFF_EXPOSURE
*      ELSE IF header.EXPOSURE_TIME is present
*        TEXP = HEADER.EXPOSURE_TIME
*      ELSE
*        TEXP = user supplied exposure time
*      ENDIF
*      Divide data by TEXP
*      IF T_RESOLVED and input dataset has a time axis
*        Correct for dead time as function(T)
*      END IF

*  Accuracy:
*     {routine_accuracy}

*  Timing:
*     {routine_timing}

*  Implementation Status:
*     {routine_implementation_status}

*  External Routines Used:
*     {name_of_facility_or_package}:
*        {routine_used}...

*  Implementation Deficiencies:
*     {routine_deficiencies}...

*  References:
*     {task_references}...

*  Keywords:
*     correct, usage:public

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     12 Nov 1993 V1.7-0 (DJA):
*        Original version
*     24 Nov 1994 V1.8-0 (DJA):
*        Now use USI for user interface
*     30 Jul 1995 V1.8-1 (DJA):
*        Preliminary ADI conversions
*      5 Sep 1995 V1.8-2 (DJA):
*        Better treatment of live times
*     12 Sep 1995 V2.0-0 (DJA):
*        Full ADI port.
*     18 Dec 1995 V2.0-1 (DJA):
*        Silly bug handling non-existent live times fixed.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'ADI_PAR'

*  Status:
      INTEGER			STATUS             	! Global status

*  External References:
      EXTERNAL                  CHR_LEN
        INTEGER                 CHR_LEN

*  Local Constants:
      INTEGER                   MAXHTEXT
        PARAMETER               ( MAXHTEXT = 8 )

      CHARACTER*30		VERSION
        PARAMETER		( VERSION = 'CORRECT Version 2.2-0' )

*  Local Variables:
      CHARACTER*80		HTXT(MAXHTEXT)		! History text
      CHARACTER*80		TEXT			!
      CHARACTER*80		WHERE			! Where does the time come from?

      REAL                      DEADC        		! Dead time correction
      REAL                      TEXP         		! Exposure time

      INTEGER			APTR			! Axis data pointer
      INTEGER			AWPTR			! Axis widths pointer
      INTEGER			DCPTR			! Dead time corr array
      INTEGER			DIMS(ADI__MXDIM)	! Dimensions
      INTEGER			DPTR			! Data pointer
      INTEGER			IFID			! Input dataset id
      INTEGER                   NDIM			! Dimensionality
      INTEGER                   NELM			! Total no. of points
      INTEGER                   NLINES			! No. lines of history
      INTEGER                   NSLOT			! No. of LIVE_TIME slots
      INTEGER			OFID			! Output dataset id
      INTEGER			ON_PTR, OFF_PTR, DUR_PTR! LIVE_TIME data
      INTEGER			QPTR			! Quality pointer
      INTEGER                   T_AX 			! Time axis number
      INTEGER			TIMID			! I/p timing
      INTEGER                   TLEN			! Length of a string!
      INTEGER			VPTR			! Variance pointer

      LOGICAL			AXNORM			! T axis normalised?
      LOGICAL			GOT_TEXP		! Got an exposure time?
      LOGICAL 			L_ON, L_OFF, L_DUR	! LIVE_TIME components?
      LOGICAL			LIVE_OK			! LIVE_TIME ok?
      LOGICAL			OK			! General validity test
      LOGICAL			OVER			! Overwrite input
      LOGICAL                   POISS			! Create Poisson var'ce
      LOGICAL			QOK			! Quality present?
      LOGICAL			T_RESOLVED		! Got live times?
      LOGICAL			VOK			! Variance present?
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Version id
      CALL MSG_PRNT( VERSION )

*  Initialise ASTERIX
      CALL AST_INIT()

*  Overwrite input?
      CALL USI_GET0L( 'OVER', OVER, STATUS )
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*  Get either one or two dataset names
      IF ( OVER ) THEN
        CALL USI_ASSOC( 'INP', 'BinDS', 'UPDATE', IFID, STATUS )
        CALL ADI_CLONE( IFID, OFID, STATUS )

      ELSE
        CALL USI_ASSOC( 'INP', 'BinDS', 'READ', IFID, STATUS )
        CALL USI_CLONE( 'INP', 'OUT', 'BinDS', OFID, STATUS )

      END IF

*  See if corrected structure is there
      CALL PRF_GET( OFID, 'CORRECTED.EXPOSURE', OK, STATUS )
      IF ( OK ) THEN
        STATUS = SAI__ERROR
        CALL ERR_REP( ' ', 'This dataset has already been '/
     :                               /'corrected!', STATUS )
      END IF
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*  Get input data
      CALL BDI_CHK( OFID, 'Data', OK, STATUS )
      CALL BDI_GETSHP( OFID, ADI__MXDIM, DIMS, NDIM, STATUS )
      IF ( .NOT. OK ) THEN
        STATUS = SAI__ERROR
        CALL ERR_REP( ' ', 'Invalid numeric data', STATUS )
        GOTO 99
      END IF
      CALL BDI_MAPR( OFID, 'Data', 'UPDATE', DPTR, STATUS )
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*  Total number of data points
      CALL ARR_SUMDIM( NDIM, DIMS, NELM )

*  Variance present?
      CALL BDI_CHK( OFID, 'Variance', VOK, STATUS )
      IF ( VOK ) THEN
        CALL BDI_MAPR( OFID, 'Variance', 'UPDATE', VPTR, STATUS )

*  Given user option of creating Poisson array
      ELSE
        CALL USI_GET0L( 'POISS', POISS, STATUS )
        IF ( STATUS .NE. SAI__OK ) GOTO 99

*    Create variance array from data?
        IF ( POISS ) THEN
          CALL BDI_MAPR( OFID, 'Variance', 'WRITE', VPTR, STATUS )
          CALL ARR_COP1R( NELM, %VAL(DPTR), %VAL(VPTR), STATUS )
          VOK = (STATUS.EQ.SAI__OK)
        END IF

      END IF
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*  Quality present?
      CALL BDI_CHK( OFID, 'Quality', QOK, STATUS )
      IF ( QOK ) THEN
        CALL BDI_MAPL( OFID, 'LogicalQuality', 'READ', QPTR, STATUS )
      END IF
      IF ( STATUS .NE. SAI__OK ) GOTO 99

*  Initialise
      T_RESOLVED = .FALSE.
      GOT_TEXP = .FALSE.

*  Get timing info
      CALL TCI_GETID( OFID, TIMID, STATUS )
      IF ( TIMID .NE. ADI__NULLID ) THEN

*    Are the 3 supported live time objects present?
        CALL ADI_THERE( TIMID, 'LiveOn', L_ON, STATUS )
        CALL ADI_THERE( TIMID, 'LiveOff', L_OFF, STATUS )
        CALL ADI_THERE( TIMID, 'LiveDur', L_DUR, STATUS )
        LIVE_OK = (L_ON .AND. L_OFF .AND. L_DUR)

*    We must have ON, OFF and DURATION
        IF ( (L_ON.OR.L_OFF.OR.L_DUR) .AND. .NOT. LIVE_OK ) THEN
          CALL MSG_PRNT( '** LIVE_TIME structure does not contain'/
     :               /' expected components and will be ignored **' )

        ELSE IF ( LIVE_OK ) THEN

*      Map live time data
          CALL ADI_CSIZE( TIMID, 'LiveOn', NSLOT, STATUS )
          CALL ADI_CMAPR( TIMID, 'LiveOn', 'READ', ON_PTR, STATUS )
          CALL ADI_CMAPR( TIMID, 'LiveOff', 'READ', OFF_PTR, STATUS )
          CALL ADI_CMAPR( TIMID, 'LiveDur', 'READ', DUR_PTR, STATUS )

*      Set flags
          T_RESOLVED = (STATUS.EQ.SAI__OK)
          WHERE = 'LIVE_TIME slots'

        END IF

*    Effective exposure present?
        CALL ADI_THERE( TIMID, 'EffExposure', OK, STATUS )
        IF ( OK ) THEN
          CALL ADI_CGET0R( TIMID, 'EffExposure', TEXP, STATUS )
          IF ( STATUS .EQ. SAI__OK ) THEN
            IF ( .NOT. LIVE_OK ) THEN
              WHERE = 'effective exposure time'
            END IF
            GOT_TEXP = .TRUE.
          END IF
        END IF

*    Try simple exposure time
        IF ( .NOT. GOT_TEXP ) THEN
          CALL ADI_THERE( TIMID, 'Exposure', OK, STATUS )
          IF ( OK ) THEN
            CALL ADI_CGET0R( TIMID, 'Exposure', TEXP, STATUS )
            IF ( STATUS .EQ. SAI__OK ) THEN
              IF ( .NOT. LIVE_OK ) THEN
                WHERE = 'exposure time in header'
              END IF
              GOT_TEXP = .TRUE.
            END IF
          END IF
        END IF

      END IF

*  Default dead time correction
      DEADC = 1.0

*  Time resolved correction possible? We only do this if dataset contains
*  a time like axis
      IF ( T_RESOLVED ) THEN

*    Look for time axis
        CALL BDI0_FNDAXC( OFID, 'T', T_AX, STATUS )
        IF ( STATUS .NE. SAI__OK ) THEN
          CALL ERR_ANNUL( STATUS )
          T_AX = 0
        END IF

*    No time axis?
        IF ( T_AX .EQ. 0 ) THEN
          CALL CORRECT_DEAD0( NSLOT, %VAL(ON_PTR), %VAL(OFF_PTR),
     :                             %VAL(DUR_PTR), DEADC, STATUS )
          T_RESOLVED = .FALSE.

        ELSE

*      Warn if not 1st dimension
          IF ( T_AX .NE. 1 ) THEN
            CALL MSG_PRNT( '** CORRECT cannot handle dead time '/
     :             /'correction unless the time axis is the **' )
            CALL MSG_PRNT( '** first axis. Swap the axes using '/
     :             /'AXORDER and CORRECT should work ok...  **' )
            T_RESOLVED = .FALSE.
            LIVE_OK = .FALSE.

          ELSE

*        Map time axis data and widths
            CALL BDI_AXMAPR( OFID, T_AX, 'Data', 'READ', APTR, STATUS )
            CALL BDI_AXMAPR( OFID, T_AX, 'Width', 'READ', AWPTR,
     :                       STATUS )

*        Has data been normalised wrt the time axis already?
            CALL BDI_AXGET0L( OFID, T_AX, 'Normalised', AXNORM, STATUS )

*        If it has, we have to denormalise and renormalise again afterwards
            IF ( AXNORM ) THEN

*          Pad dimensions to 7D
              CALL AR7_PAD( NDIM, DIMS, STATUS )

*          Issue warning
              CALL MSG_PRNT( 'Denormalising wrt time axis...' )

*          Denormalise data
              CALL AR7_DENORM( %VAL(AWPTR), DIMS, T_AX, %VAL(DPTR),
     :                         STATUS )

*          and variance if present
              IF ( VOK ) THEN
                CALL AR7_DENORMV( %VAL(AWPTR), DIMS, T_AX, %VAL(DPTR),
     :                           STATUS )
              END IF

            END IF

*        Construct dead time correction array
            CALL DYN_MAPR( 1, DIMS(T_AX), DCPTR, STATUS )

*        Find dead time correction as function of time
            CALL CORRECT_DEAD1( DIMS(T_AX), %VAL(APTR), %VAL(AWPTR),
     :                          NSLOT, %VAL(ON_PTR), %VAL(OFF_PTR),
     :                          %VAL(DUR_PTR), %VAL(DCPTR), STATUS )

          END IF

        END IF

      END IF

*  Inform user of where we got the exposure time
      IF ( GOT_TEXP ) THEN
        CALL MSG_SETR( 'T', TEXP )
        CALL MSG_SETC( 'WHERE', WHERE )
        CALL MSG_PRNT( 'Exposure of ^T seconds derived from ^WHERE' )

      ELSE

*    Get it from the user
        CALL USI_GET0R( 'TEXP', TEXP, STATUS )
        IF ( STATUS .NE. SAI__OK ) GOTO 99

*    Write it to the file
        CALL ADI_CPUT0R( TIMID, 'Exposure', TEXP, STATUS )
        CALL TCI_PUTID( OFID, TIMID, STATUS )

      END IF

*  Simply divide the data by the exposure time multiplied by the global
*  dead time correction.
      CALL CORRECT_INT( NELM, %VAL(DPTR), VOK, %VAL(VPTR), QOK,
     :                  %VAL(QPTR), TEXP*DEADC, STATUS )

*  Time resolved and dataset has time axis
      IF ( LIVE_OK ) THEN

        IF ( T_RESOLVED ) THEN

          CALL MSG_PRNT( 'Performing time resolved dead time '/
     :                                          /'correction' )

*      Apply the dead time correction to each time slice
          CALL CORRECT_DEADCOR( DIMS(T_AX), NELM/DIMS(T_AX),
     :                          %VAL(DCPTR), %VAL(DPTR), VOK,
     :                          %VAL(VPTR), QOK, %VAL(QPTR), STATUS )

        ELSE IF ( DEADC .NE. 1.0 ) THEN
          CALL MSG_SETR( 'D', DEADC )
          CALL MSG_PRNT( 'Applied a total dead time correction of ^D' )

        END IF

*    Release live times
        CALL ADI_CUNMAP( TIMID, 'LiveOn', ON_PTR, STATUS )
        CALL ADI_CUNMAP( TIMID, 'LiveOff', OFF_PTR, STATUS )
        CALL ADI_CUNMAP( TIMID, 'LiveDur', DUR_PTR, STATUS )

      END IF

*  Renormalise?
      IF ( AXNORM .AND. T_RESOLVED ) THEN

*    Issue warning
        CALL MSG_PRNT( 'Renormalising wrt time axis...' )

*    Renormalise data
        CALL AR7_NORM( %VAL(AWPTR), DIMS, T_AX, %VAL(DPTR), STATUS )

*    and variance if present
        IF ( VOK ) THEN
          CALL AR7_NORMV( %VAL(AWPTR), DIMS, T_AX, %VAL(VPTR), STATUS )
        END IF

      END IF

*  Adjust the data units
      CALL BDI_GET0C( OFID, 'Units', TEXT, STATUS )
      IF ( TEXT .GT. ' ' ) THEN
        CALL BDI_PUT0C( OFID, 'Units', TEXT(:CHR_LEN(TEXT)) //
     :                  ' / second', STATUS )
      END IF

*  Flag dataset as corrected
      CALL PRF_SET( OFID, 'CORRECTED.EXPOSURE', .TRUE., STATUS )
      IF ( LIVE_OK ) THEN
        CALL PRF_SET( OFID, 'CORRECTED.DEAD_TIME', .TRUE., STATUS )
      END IF

*  Update HISTORY
      CALL HSI_ADD( OFID, VERSION, STATUS )
      HTXT(1) = 'Input {INP}'
      NLINES = MAXHTEXT
      CALL USI_TEXT( 1, HTXT, NLINES, STATUS )
      CALL HSI_PTXT( OFID, NLINES, HTXT, STATUS )
      CALL MSG_SETR( 'TEXP', TEXP )
      CALL MSG_MAKE( 'Corrected for exposure time of ^TEXP seconds',
     :               TEXT, TLEN )
      CALL HSI_PTXT( OFID, 1, TEXT(:TLEN), STATUS )
      IF ( LIVE_OK ) THEN
        IF ( T_RESOLVED ) THEN
          TEXT = 'Performed time resolved dead time correction'
        ELSE IF ( DEADC .NE. 1.0 ) THEN
          CALL MSG_SETR( 'DEAD', DEADC )
          CALL MSG_MAKE( 'Applied a total dead time correction of ^D',
     :                   TEXT, TLEN )
        END IF
        CALL HSI_PTXT( OFID, 1, TEXT, STATUS )
      END IF

*    Tidy up
 99   CALL AST_CLOSE()
      CALL AST_ERR( STATUS )

      END



*+  CORRECT_INT - Normalise a binned dataset in time
      SUBROUTINE CORRECT_INT( N, DATA, VOK, VAR, QOK, QUAL, TEXP,
     :                        STATUS )
*
*    Description :
*
*     Divides DATA by TEXP taking account of quality and variance
*
*    Method :
*
*    Deficiencies :
*    Bugs :
*    Authors :
*
*     David J. Allan (ROSAT,BHVAD::DJA)
*
*    History :
*
*     12 Nov 93 : Original (DJA)
*
*    Type definitions :
*
      IMPLICIT NONE
*
*    Global constants :
*
      INCLUDE 'SAE_PAR'
*
*    Import :
*
      INTEGER			N			! Number of data points
      LOGICAL			VOK			! Variance present?
      REAL                      VAR(*) 			! Input variance
      LOGICAL			QOK			! Quality present?
      LOGICAL                   QUAL(*) 		! Input quality
      REAL			TEXP			! Exposure time
*
*    Import / Export :
*
      REAL                      DATA(*) 		! Input & output data
*
*    Status :
*
      INTEGER 			STATUS
*
*    Local variables :
*
      INTEGER			I			! Loop over data

      LOGICAL			OK			! General validity test
*-

*    Check status
      IF ( STATUS .NE. SAI__OK ) RETURN

*    Set default for no quality present
      OK = .TRUE.

*    Loop over data
      DO I = 1, N
        IF ( QOK ) OK = QUAL(I)

*      This point ok?
        IF ( OK ) THEN

*        Correct it
          DATA(I) = DATA(I) / TEXP

*        Correct variance if present
          IF ( VOK ) THEN
            VAR(I) = VAR(I) / (TEXP**2)
          END IF

        END IF

      END DO

      END



*+  CORRECT_DEAD0 - Finds the total dead time correction from LIVE_TIME data
      SUBROUTINE CORRECT_DEAD0( N, ON, OFF, DUR, DEADC, STATUS )
*
*    Description :
*
*     Accumulates a time integrated dead time correction given the LIVE_TIME
*     start and stop times + actual instrument duration during that interval.
*     The definition of DUR is such that DUR(i) <= (OFF(i)-ON(i)).
*
*    Method :
*
*    Deficiencies :
*    Bugs :
*    Authors :
*
*     David J. Allan (ROSAT,BHVAD::DJA)
*
*    History :
*
*     12 Nov 93 : Original (DJA)
*
*    Type definitions :
*
      IMPLICIT NONE
*
*    Global constants :
*
      INCLUDE 'SAE_PAR'
*
*    Import :
*
      INTEGER			N			! Number of data points
      REAL                      ON(*), OFF(*) 		! On and off times
      REAL                      DUR(*) 			! Durations
*
*    Export :
*
      REAL			DEADC			! Dead time correction
*
*    Status :
*
      INTEGER 			STATUS
*
*    Local variables :
*
      INTEGER			I			! Loop over data
*-

*    Check status
      IF ( STATUS .NE. SAI__OK ) RETURN

*    Accumluate dead time correction
      DEADC = 0.0
      DO I = 1, N
        DEADC = DEADC + (OFF(I)-ON(I))/DUR(I)
      END DO

      END


*+  CORRECT_DEAD1 - Dead time correction from LIVE_TIME data as function of T
      SUBROUTINE CORRECT_DEAD1( NAX, AX, AXWID, N, ON, OFF, DUR,
     :                          DEADC, STATUS )
*
*    Description :
*
*     Calculates the dead time correction as a function of time given a
*     series of time bin centres and widths, and a set of LIVE_TIME data.
*
*    Method :
*
*     FOR each time bin
*       Identify those contributing LIVE_TIME slots
*       Zero the accumulated exposure for this time bin
*       FOR each such slot
*         Calculate the amount of overlap between the time bin and slot
*         Add the contribution from the overlap region allowing for the
*         average dead time correction over the LIVE_TIME slot.
*       NEXT live time slot
*     NEXT time bin
*
*    Deficiencies :
*    Bugs :
*    Authors :
*
*     David J. Allan (ROSAT,BHVAD::DJA)
*
*    History :
*
*     12 Nov 93 : Original (DJA)
*
*    Type definitions :
*
      IMPLICIT NONE
*
*    Global constants :
*
      INCLUDE 'SAE_PAR'
*
*    Import :
*
      INTEGER			NAX			! Number of time points
      REAL                      AX(*), AXWID(*) 	! Time bin centre/width
      INTEGER			N			! Number of data points
      REAL                      ON(*), OFF(*) 		! On and off times
      REAL                      DUR(*) 			! Durations
*
*    Export :
*
      REAL			DEADC(*)		! Dead time as fn(T)
*
*    Status :
*
      INTEGER 			STATUS
*
*    Local variables :
*
      REAL			DLO, DHI		! Overlap region
      REAL 			TEXP			! Exposure into a bin
      REAL			TLO, THI		! Extrema of time bin

      INTEGER			I, J			! Loop over data
      INTEGER			JLO, JHI		! LIVE_TIME bin indices
*-

*    Check status
      IF ( STATUS .NE. SAI__OK ) RETURN

*    Loop over time bins
      DO I = 1, NAX

*      Zero the exposure accumulator
        TEXP = 0.0

*      The extrema of this time bin
        TLO = AX(I) - AXWID(I)/2.0
        THI = AX(I) + AXWID(I)/2.0

*      Find indices of all LIVE_TIME slots which contribute to this time bin.
*      The binary search routine rounds down to the nearest index number so
*      add on an extra bin at the top end and do a test in the next loop.
        CALL ARR_BSRCHR( N, ON, TLO, JLO, STATUS )
        CALL ARR_BSRCHR( N, OFF, THI, JHI, STATUS )
        JHI = JHI + 1

*      Loop over the LIVE_TIME bins contributing to the current time bin
        DO J = JLO, JHI

*        Check that this LIVE_TIME bin does actually overlap our time bin.
*        One of the live time boundaries must lie inside our time bin, or
*        they must lie to the left and right.
          IF ( ((ON(J).GE.TLO) .AND. (ON(J).LE.THI)) .OR.
     :         ((OFF(J).GE.TLO) .AND. (OFF(J).LE.THI)) .OR.
     :         ((ON(J).LT.TLO) .AND. (OFF(J).GT.THI)) ) THEN

*          Workout the overlap of the LIVE_TIME slot and the time bin
            DLO = MAX(TLO,ON(J))
            DHI = MIN(THI,OFF(J))

*          Work out how much real exposure has gone into this time bin
*          from this LIVE_TIME slot
            TEXP = TEXP + (DHI-DLO) * (OFF(J)-ON(J)) / DUR(J)

          END IF

        END DO

*      The units of the input data are unnormalised, eg. just counts. The
*      dead time correction factor is therefore simply the sum of the
*      exposure contributions from the various LIVE_TIME bins divided by the
*      bin width.
        DEADC(I) = TEXP / AXWID(I)

      END DO

      END


*+  CORRECT_DEADCOR - Apply dead time correction
      SUBROUTINE CORRECT_DEADCOR( NTAX, NT, DEADC, DATA, VOK, VAR, QOK,
     :                            QUAL, STATUS )
*
*    Description :
*
*     Applies dead time correction to a stack of 1-d arrays.
*
*    Method :
*
*    Deficiencies :
*    Bugs :
*    Authors :
*
*     David J. Allan (ROSAT,BHVAD::DJA)
*
*    History :
*
*     12 Nov 93 : Original (DJA)
*
*    Type definitions :
*
      IMPLICIT NONE
*
*    Global constants :
*
      INCLUDE 'SAE_PAR'
*
*    Import :
*
      INTEGER			NTAX			! No. point per T slice
      INTEGER			NT			! No. slices
      REAL                      DATA(NTAX,NT) 		! Input data
      LOGICAL			VOK			! Variance present?
      REAL                      VAR(NTAX,NT) 		! Input variance
      LOGICAL			QOK			! Quality present?
      LOGICAL                   QUAL(NTAX,NT) 		! Input quality
      REAL			DEADC(NTAX)		! Dead time as fn(T)
*
*    Status :
*
      INTEGER 			STATUS
*
*    Local variables :
*
      INTEGER			I, J			! Loops over data
      LOGICAL                   OK			! This data point ok?
*-

*    Check status
      IF ( STATUS .NE. SAI__OK ) RETURN

*    Set default for no quality present
      OK = .TRUE.

*    For each series in the stack
      DO J = 1, NT

*      Correct each series
        DO I = 1, NTAX

*        Check quality if present
          IF ( QOK ) OK = QUAL(I,J)

*        This point ok?
          IF ( OK ) THEN

*          Correct it
            DATA(I,J) = DATA(I,J) * DEADC(I)

*          Correct variance if present
            IF ( VOK ) THEN
              VAR(I,J) = VAR(I,J) * (DEADC(I)**2)
            END IF

          END IF

        END DO

      END DO

      END
