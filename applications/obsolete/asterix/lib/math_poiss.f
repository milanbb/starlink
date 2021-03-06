*+  MATH_POISS - Returns a random number according to the Poisson distribution
*                given the mean of the distribution
      INTEGER FUNCTION MATH_POISS(LAMB)
*
*    Description :
*
*    History :
*
*      9 Mar 90:  Original (BHVAD::SRD)
*     25 Oct 93 : Don't make assumption that LAMB>15 is Gaussian. Use new NAG
*                 routine in release 15. (DJA)
*     11 Jun 97 : Convert to PDA (RB)
*     22 Jun 98 : Make seed varry every second and with PID (RB)
*
*    Type definitions :
*
      IMPLICIT NONE
*
*    Import :
*
      REAL LAMB
*
*    Functions :
*
      EXTERNAL PDA_RNPOI
      INTEGER PDA_RNPOI
*
*    Local variables :
*
      INTEGER SEED, TICKS, PID, STATUS
      LOGICAL INITIALISE
*
*    Local Data :
*
      DATA INITIALISE/.TRUE./
*-

*    Initialise random number generator
      IF ( INITIALISE ) THEN
        STATUS = 0
        CALL PSX_TIME( TICKS, STATUS )
        CALL PSX_GETPID( PID, STATUS )
        SEED = 1000 * (( TICKS / 4 ) / 1000 ) + 4 * MOD( TICKS, 1000 )
     :                                        + 4 * MOD( PID, 1000 )
        IF ( MOD( SEED, 2 ) .EQ. 0 ) SEED = SEED + 1
        CALL PDA_RNSED( SEED )
        INITIALISE=.FALSE.
      END IF

*    Poisson distribution
      MATH_POISS = PDA_RNPOI( LAMB )

      END

