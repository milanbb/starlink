      SUBROUTINE SURFLIB_2DFT_CHOP (CHOP_THROW, CHOP_PA, PIXSIZE,
     :     IDIMS, FT_DATA, FT_VARIANCE, WT_DATA, WT_VARIANCE, STATUS)
*+
*  Name:
*    SURFLIB_2DFT_CHOP
 
*  Purpose:
*     Calculate the FT of the 2D chop throw

*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL SURFLIB_2DFT_CHOP (CHOP_THROW, CHOP_PA, PIXSIZE,
*    :     IDIMS, FT_DATA, FT_VARIANCE, WT_DATA, WT_VARIANCE, STATUS)

*  Description:
*     Given the chop parameters calculate the FT of the chop.
*     The dual beam chop is treated as two delta functions of
*     opposite sign separated by the chop throw and centred at the
*     middle of the data array. The Fourier transform of this function
*     is a sine wave in the direction of the chop (zero at the middle
*     beam) with wavelength related to the spatial frequency of the
*     array (pixel spacing).
      

*  Arguments:
*     CHOP_THROW                  = REAL (Given)
*           chop throw in arcsec
*     CHOP_PA                     = REAL (Given)
*           position angle of chop. Positive is anti-clockwise
*           from North. This angle is in degrees.
*     PIXSIZE                     = REAL (Given)
*           pixel size in arcsec
*     IDIMS ( 2 )                  = INTEGER (Given)
*           dimensions of arrays
*     FT_DATA (IDIMS(1), IDIMS(2)) = REAL (Returned)
*           data array containing F.T. of chop
*     FT_VARIANCE (IDIMS(1), IDIMS(2))       = REAL (Returned)
*           variance on DATA; set to 0
*     WT_DATA (IDIMS(1), IDIMS(2)) = REAL (Returned)
*           data array containing weight of chop
*     WT_VARIANCE (IDIMS(1), IDIMS(2))       = REAL (Returned)
*           variance on DATA; set to 0
*     STATUS                      = INTEGER (Given and returned)
*           global status
 
*  Method:
 
*  Deficiencies:
 
*    Bugs:
 
*    Authors:
 
*    History:
*     $Log$
*     Revision 1.1  1998/04/28 00:30:53  timj
*     Initial revision
*
 
*-
 
*  Type Definitions:
      IMPLICIT NONE
 
*  Global constants:
      INCLUDE 'SAE_PAR'
 
*  Arguments Given:
      REAL    CHOP_THROW
      REAL    CHOP_PA
      REAL    PIXSIZE
      INTEGER IDIMS ( 2 )
 
*  Arguments Returned:
      REAL    FT_DATA (IDIMS(1), IDIMS(2))
      REAL    FT_VARIANCE (IDIMS(1), IDIMS(2))
      REAL    WT_DATA (IDIMS(1), IDIMS(2))
      REAL    WT_VARIANCE (IDIMS(1), IDIMS(2))
 
*  Status:
      INTEGER STATUS
 
*  External references:
 
*  Global variables:
 
*  Local Constants:
      REAL    PI 
      PARAMETER (PI = 3.141592654)
 
*  Local variables:
      REAL    COS_PA            ! Cosine of the position angle
      REAL    DX                ! X Distance from centre (unrotated)
      REAL    DY                ! Y distance from centre (unrotated)
      REAL    HALF_CHOP         ! Half the chop in pixels
      REAL    RPA               ! Position angle in radians
      REAL    RX                ! X distance from centre in rotated frame
      REAL    RY                ! Y distance from centre in rotated frame
      REAL    SC                ! Scale size of FT
      REAL    SIN_PA            ! Sine of the position angle
      REAL    TAN_PA            ! Tangent of the position angle
      REAL    TOT               ! Total size of image in the chop direction
      REAL    VAL               ! Value for current pixel
      INTEGER X                 ! X position in output image
      REAL    XCEN              ! Position of image centre (X)
      INTEGER Y                 ! Y position in output image
      REAL    YCEN              ! Position of image centre (Y)
 
*  Internal References :
 
*  Local data:
 
*.
 
      IF (STATUS .NE. SAI__OK) RETURN
 
*     Calculate half the chop in pixels
      HALF_CHOP = CHOP_THROW / (2.0 * PIXSIZE)
 
*     Centre of image
      XCEN = REAL(IDIMS(1) + 1 ) / 2.0
      YCEN = REAL(IDIMS(2) + 1 ) / 2.0

*     Convert CHOP_PA to radians and precaclulate SIN and COS
      RPA = CHOP_PA * PI / 180.0
      SIN_PA = SIN(RPA)
      COS_PA = COS(RPA)

*     Calculate spatial frequency of the FT
*     This is related to the pixel spacing and the size of the
*     image

*     First find the extent of the data in the
*     rotated frame. For PA 0 this corresponds to IDIMS(2)
*     and for PA 90 this is IDIMS(1)

      TAN_PA = TAN(RPA)

*     Factor of 2 comes from being symmetric about XCEN,YCEN

      DX = 2.0 * MIN( XCEN, ABS(YCEN * TAN_PA) )
      
      IF (ABS(TAN_PA) .LT. 1.0E-20) THEN
         DY = 2.0 * YCEN
      ELSE
         DY = 2.0 * MIN ( YCEN, ABS(XCEN/ TAN_PA) )
      END IF

      TOT = SQRT ( DX**2 + DY**2 )

*     This is really the a case of calculating the chop throw
*     as a fraction of the image size in the rotated frame.

      SC = HALF_CHOP / TOT

      

*     In order to handle rotation the FT is no longer constant
*     for constant X or Y
*     This means we have to calculate it separately for each
*     output pixel.

      DO X = 1, IDIMS(1)

*     Calculate distance of X pixel from X centre
         DX = XCEN - REAL(X)    ! X counts backwards

         DO Y = 1, IDIMS(2)

*     Calculate distance of Y pixel from Y centre
            DY = REAL(Y) - YCEN

*     Rotate -- FT depends on X distance from centre 
*     of rotated frame
            RX =  DX * COS_PA + DY * SIN_PA
            RY = -DX * SIN_PA + DY * COS_PA

*     Calculate FT
            VAL = -2.0 * SIN (2.0 * PI * SC * RY)

            FT_DATA(X, Y) = VAL
            FT_VARIANCE(X, Y) = 0.0
            WT_DATA(X, Y) = VAL ** 2
            WT_VARIANCE(X, Y) = 0.0

         END DO

      END DO
 
      END
