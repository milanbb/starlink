*+  SHOWXRT - Produces a 1 page summary of a ROSAT XRT observation
      SUBROUTINE SHOWXRT( STATUS )
*    Description :
*     Program to provide a summary of an XRT observation to a file
*     or to the screen. Gets the info. from the XRT header file -
*     Rootname.HDR. It may also be used to provide a list of the
*     MJDS of the on and off times of the XRT observation.
*    Parameters :
*     RAWDIR            = CHAR (read) Directory name
*     ROOTNAME          = CHAR (read) Rootname for header file
*     FILENAME          = CHAR (read) Ouput text file or TT for screen
*     SHOWOBS           = LOGICAL (read) Produce the observation listing ?
*     TIM
*    Method :
*    Deficiencies :
*    Bugs :
*    Authors :
*       Richard Saxton  (LTVAD::RDS)
*
*    History :
*
*         Nov 91 Original
*         Feb 92 : V1.5-2  Formats changed to handle large observation lengths
*                          e.g. 200 days. (RDS)
*         Apr 94 : V1.7-0  RATionalised for new release of asterix (LTVAD::JKA)
*      20 May 94 : V1.7-1  Use AIO for output (DJA)
*       6 Apr 98 : V2.2-1  Removed structures (RJV)
*       9 Feb 99 : V2.3-0  FITS file input (DGED)
*
*    Type Definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'PAR_ERR'
*    Global variables :
      INCLUDE 'XRTSRT_CMN'
      INCLUDE 'XRTHEAD_CMN'
*    Status :
      INTEGER                 STATUS
*    Functions :
      INTEGER CHR_LEN
        EXTERNAL CHR_LEN
*    Local Constants :
      CHARACTER*30            VERSION
         PARAMETER          ( VERSION = 'SHOWXRT Version 2.3-0')
      INTEGER MAXRAW
         PARAMETER          ( MAXRAW = 20 )

*    Local variables :
      LOGICAL LSHOW,LTIME

      INTEGER                 BLOCK
      INTEGER                 IUNIT             ! Logical I/O unit
      INTEGER                 NFILES            ! Number of files
*
      CHARACTER*100           FILES(MAXRAW)     ! File name aray
      CHARACTER*132           FILENAME
      CHARACTER*132           FITSDIR           ! Directory for FITS
      CHARACTER*132           FROOT             ! Root of FITS filename
      CHARACTER*5             ORIGIN            ! Origin of FITS file

*-
*   Version anouncement
      CALL MSG_PRNT(VERSION)

*   Initialize ASTERIX common blocks
      CALL AST_INIT
*
*  Get input file details
*  Get the current working directory
      CALL UTIL_GETCWD( FITSDIR, STATUS )
      CALL USI_DEF0C( 'RAWDIR', FITSDIR, STATUS )
      IF ( STATUS .NE. SAI__OK ) GOTO 999

      CALL USI_GET0C( 'RAWDIR', FITSDIR, STATUS )
*  Any FITS files?
      CALL UTIL_FINDFILE(FITSDIR, '*.fits', MAXRAW, FILES, NFILES,
     :                                                       STATUS)
*  If no files - exit
      IF (NFILES .LE. 0) THEN
         STATUS = SAI__ERROR
         CALL MSG_PRNT ('SHOWXRT : Error - No FITS file found')
         CALL MSG_PRNT ('SHOWXRT : Uses RDF FITS files only.')
         CALL MSG_PRNT ('SHOWXRT : Please use VERSION V2.2-1 for SDF'
     :                                                //'file input')
         GOTO 999
      END IF
*
*  Get root name of FITS file
      CALL USI_GET0C ('ROOTNAME', FROOT, STATUS )
*  Append extension of FITS extension containing header
      FILENAME = FROOT(1:CHR_LEN(FROOT)) // '_bas.fits'

*  Does file exist?
      CALL UTIL_FINDFILE(FITSDIR, FILENAME, MAXRAW, FILES, NFILES,
     :                                                       STATUS)
      IF (NFILES .LE. 0) THEN
         STATUS = SAI__ERROR
         CALL MSG_PRNT ('SHOWXRT : Error - Header file not found')
         GOTO 999
      END IF
*
      IF (STATUS .NE. SAI__OK) GOTO 999
*
      FILENAME = FITSDIR(1:CHR_LEN(FITSDIR))//'/'//FILENAME
      CALL MSG_PRNT('SHOWXRT : Using FITS file : '// FILENAME)

*  Open the FITS fIle
      CALL FIO_GUNIT(IUNIT, STATUS)
      CALL FTOPEN(IUNIT, FILENAME, 0, BLOCK, STATUS)
      IF ( STATUS .NE. SAI__OK ) THEN
	 CALL MSG_SETC('FNAM',FILENAME)
         CALL MSG_PRNT('SHOWXRT : Error - opening file ^FNAM **')
         GOTO 999
      ENDIF
*
*  Read in header
      ORIGIN = 'RDF'
      CALL RAT_RDHEAD(IUNIT, ORIGIN, STATUS)
*
      IF ( STATUS .NE. SAI__OK ) GOTO 999
*
*  Close FITS files
      CALL FTCLOS(IUNIT, STATUS)
      CALL FIO_PUNIT(IUNIT, STATUS)
*
*   Produce an observation summary ?
      CALL USI_GET0L('SHOWOBS', LSHOW, STATUS)

*   Produce a list of ON/OFF times ?
      CALL USI_GET0L('TIMLIST', LTIME, STATUS)

*   Write observation description
      CALL SHOWXRT_OUT(LSHOW, LTIME,  STATUS)

 999  CALL AST_CLOSE
      CALL AST_ERR( STATUS )

      END


*+  SHOWXRT_OUT - Outputs description of observation
      SUBROUTINE SHOWXRT_OUT(LSHOW, LTIME,   STATUS)
*    Description :
*    History :
*    Type definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
*    Global variables :
      INCLUDE 'XRTHEAD_CMN'
*    Import :
      LOGICAL LSHOW                      ! Produce an observation summary ?
      LOGICAL LTIME                      ! Produce a list of On/OFF times ?
*    Import-Export :
*     <declarations and descriptions for imported/exported arguments>
*    Export :
*     <declarations and descriptions for exported arguments>
*    Status :
      INTEGER STATUS
*    Local constants :
      DOUBLE PRECISION DTOR
         PARAMETER(DTOR = 3.1415926535 / 180.)
*    Local variables :
      CHARACTER*79 SBUF
      CHARACTER*20 TSTRING1,TSTRING2
      CHARACTER*10 RASTRING,DECSTRING
      DOUBLE PRECISION ENDMJD                 ! Last MJD of the obs.
      DOUBLE PRECISION SMJD,EMJD              ! Start and end MJDs of each slot
      DOUBLE PRECISION EXPOS
      REAL RA,DEC
      INTEGER LP
      INTEGER IND1A,IND1B,IND2A,IND2B
      CHARACTER*24 CSTRING1,CSTRING2 ! Time strings
      INTEGER MUNIT

      INTEGER			AID			! AIO identifier
      INTEGER			OWIDTH			! output width
*-

*    Check status
      IF ( STATUS .NE. SAI__OK ) RETURN

*    Produce an observation summary if wanted
      IF (LSHOW) THEN

*      Get name of output file for obs. summary
        CALL AIO_ASSOCO( 'SUMFILE', 'LIST', AID, OWIDTH, STATUS )
        IF (STATUS .NE. SAI__OK) GOTO 999

*      Convert base time to character string
        CALL CONV_MJDDAT(HEAD_BASE_MJD, TSTRING1)

*      Convert end time to char. string
        ENDMJD = HEAD_BASE_MJD + HEAD_TEND(HEAD_NTRANGE) / 86400.
        CALL CONV_MJDDAT(ENDMJD, TSTRING2)

*      Output general info.
        CALL AIO_BLNK( AID, STATUS )
        WRITE( SBUF,1010) HEAD_OBSERVER, HEAD_TITLE, HEAD_FILTER
 1010   FORMAT( 1X, 'ROR_ID: ',A12,2X,'TARGET :',A12,'FILTER :', A8 )
        CALL AIO_WRITE( AID, SBUF, STATUS )
        CALL AIO_BLNK( AID, STATUS )
        WRITE(SBUF,1015) TSTRING1, TSTRING2
 1015   FORMAT(1X,'Start_time : ',A20,2X,'End_time : ',A20)
        CALL AIO_WRITE( AID, SBUF, STATUS )

*      Write SASS version id.
        CALL AIO_BLNK( AID, STATUS )
        CALL MSG_SETC( 'SASS', HEAD_SASS_DATE )
        CALL AIO_WRITE( AID, ' SASS version: ^SASS', STATUS )
        CALL AIO_BLNK( AID, STATUS )

*      Write detector ID
        CALL MSG_SETC( 'DET', HEAD_DETECTOR )
        CALL AIO_WRITE( AID, ' Detector : ^DET', STATUS )
        CALL AIO_BLNK( AID, STATUS )

*      Header for ON/OFF times
        CALL AIO_WRITE( AID, ' Observation slots : '/
     :            /'(secs from start_time)', STATUS )

*      Write list of ON/OFF times
        CALL AIO_WRITE( AID, '      ON        OFF     Duration',
     :                  STATUS )
        EXPOS = 0.0D0
        DO LP=1,HEAD_NTRANGE
          WRITE(SBUF,1020)HEAD_TSTART(LP),HEAD_TEND(LP),
     :                  (HEAD_TEND(LP)-HEAD_TSTART(LP))
          CALL AIO_WRITE( AID, SBUF, STATUS )
          EXPOS = EXPOS + HEAD_TEND(LP) - HEAD_TSTART(LP)
        END DO
 1020   FORMAT(2X, F10.1, 1X, F10.1, 1X, F10.1)
        CALL AIO_BLNK( AID, STATUS )

*      Write exposure time
        WRITE( SBUF,1030) HEAD_TEND(HEAD_NTRANGE) / 86400.0D0
 1030   FORMAT(1X,'Total elapsed time (days):',F7.2)
        CALL AIO_WRITE( AID, SBUF, STATUS )
        CALL MSG_SETR( 'EXP', EXPOS )
        CALL AIO_WRITE( AID, ' Total slot duration       '/
     :                  /': ^EXP seconds', STATUS )
        CALL AIO_BLNK( AID, STATUS )

*      Write RA and DEC of observation
        RA = HEAD_AXIS_RA * DTOR
        DEC = HEAD_AXIS_DEC * DTOR
        CALL STR_RRADTOC( RA, 'HH:MM:SS.S', RASTRING, STATUS )
        CALL STR_RRADTOC( DEC, 'SDD:MM:SS', DECSTRING, STATUS )
        CALL MSG_SETC( 'RA', RASTRING )
        CALL MSG_SETC( 'DEC', DECSTRING )
        CALL AIO_WRITE( AID, ' RA: ^RA DEC: ^DEC', STATUS )

*      Close device
        CALL AIO_CANCL( 'SUMFILE', STATUS )

      END IF

*    Produce a list of ON/OFF times if wanted
      IF (LTIME) THEN

*      Get logical unit
        CALL FIO_GUNIT(MUNIT, STATUS)
*
         IF (STATUS .NE. SAI__OK) THEN
            CALL MSG_PRNT('Error getting unit for output file')
            GOTO 999
         ENDIF
*
*   Open the output file
         OPEN(UNIT=MUNIT, FILE='XRT_TIMES.LIS', STATUS='NEW')
*
         DO LP=1,HEAD_NTRANGE
            SMJD = HEAD_BASE_MJD + HEAD_TSTART(LP)/86400.0D0
            EMJD = HEAD_BASE_MJD + HEAD_TEND(LP)/86400.0D0
*
*    Convert start and stop time to an MJD and put an M in front of it.
            WRITE(CSTRING1, FMT='(E23.15)')SMJD
            CALL CHR_FANDL(CSTRING1,IND1A,IND1B)
*
            WRITE(CSTRING2, FMT='(E23.15)')EMJD
            CALL CHR_FANDL(CSTRING2,IND2A,IND2B)
*
*      Write these two MJDs to the output file
            WRITE(MUNIT, 1000)CSTRING1(IND1A:IND1B),
     &                              CSTRING2(IND2A:IND2B)
         ENDDO
*
1000     FORMAT(1X,'M',A,4X,'M',A)
*
         CALL FIO_PUNIT(MUNIT, STATUS)

      END IF
*
999   CONTINUE
*
      END
