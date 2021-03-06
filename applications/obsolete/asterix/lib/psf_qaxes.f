*+  PSF_QAXES - Return axis id's
      SUBROUTINE PSF_QAXES( PSID, X_AX, Y_AX, E_AX, T_AX, STATUS )
*
*    Authors :
*
*     David J. Allan (ROSAT, University of Birmingham)
*
*    History :
*
*     28 Jun 93 : Original (DJA)
*     15 Dec 93 : Use internal axis call (DJA)
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
      INTEGER                  PSID                    ! Psf handle
*
*    Export :
*
      INTEGER                  X_AX, Y_AX, E_AX, T_AX  ! Axis id's
*
*    Status :
*
      INTEGER                  STATUS
*-

*  Check status
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Call internal routine
      CALL PSF0_GETAXID( PSID, X_AX, Y_AX, E_AX, T_AX, STATUS )

      END
