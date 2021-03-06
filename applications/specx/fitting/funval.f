*  History:
*     19 Nov 1993 (hme):
*        TABs removed.
C-----------------------------------------------------------------------
C
      SUBROUTINE FUNVAL(VAR,RESID,GRAD,SUMSQ,IFL)
C
C     VAR;    VECTOR OF INDEPENDENT PARAMETERS
C
C     RESID;  N POINT ARRAY CONTAINING DIFFERENCES OF FUNCTION
C             TO BE FITTED AND DATA
C
C     GRAD;   JACOBIAN MATRIX.  CONTAINS ALL DERIVATIVES OF F(I),I=1,N
C             W.R.T VAR(1),FOLLOWED BY DERIVS. W.R.T. VAR(2),ETC
C
C     SUMSQ;  CALCULATED SUM OF SQUARED RESIDUALS
C
C     IFL;    FLAG TO BE SET (EQ.1) IF NEW GRAD,RESID TO BE CALCULATED,
C             ELSE ROUTINE CALCULATES SUMSQ ONLY.
C
C     X(N);   ARRAY CONTAINING X-VALUES OF BASELINE POINTS
C
C     Y(N);   ARRAY CONTAINING DATA TO BE FITTED
C
C     BL(N);  FITTED FUNCTION AT X(I),I=1,N
C
C     NPARAM; TOTAL NUMBER OF PARAMETERS NEEDED BY FUNVAL
C
C     NP;     1+ORDER OF POLYNOMIAL PART OF FUNCTION
C
C     NS;     NUMBER OF (HARMONIC) SINUSOIDS BEING FITTED
C
      INTEGER K(20)
      REAL*4  VAR(1),RESID(1),GRAD(1),SNTHJJ(20),CSTHJJ(20)
      REAL*8  SUMSQ,RESIDX

      INCLUDE 'SPECX_PARS'

      COMMON/GFUNC/X(LSPMAX),Y(LSPMAX),N,NPARAM
      COMMON/SINFT/NP,NS,DUMMY(29)
C
C     SET FLAGS ETC, INITIAL VALUES
C
      SUMSQ=0.D0
      PI=3.141593
      NP1=NP
      NPER=NP+1
      KK=1
C
C     WRITE TO K(NPARAM); CONTAINS STARTING POINTS IN GRAD FOR EACH VECTOR
C                         OF DERIVATIVES
C
      DO 10 I=1,NPARAM
      K(I)=KK
   10 KK=KK+N
C
C     CALCULATE SIN AND COS OF PHASE ANGLES FOR EACH HARMONIC
C
      IF(NS.EQ.0)   GO TO 15
      DO 18 I=1,NS
      JJ=2*I+NPER
      SNTHJJ(I)=SIN(VAR(JJ))
   18 CSTHJJ(I)=COS(VAR(JJ))
C
C     CALCULATE FITTED VALUE OF FUNCTION AT EACH DATA POINT
C
   15 DO 100 I=1,N
      YHAT=0.0
C
C ****FIRST THE POLYNOMIAL TERM
C
      XP=1.
      DO 20 J=1,NP1
      YHAT=YHAT+VAR(J)*XP
   20 XP=XP*X(I)
C
C ****THEN THE SINUSOIDAL TERMS
C
      IF(NS.EQ.0)   GO TO 50
      ANG=2.*PI*X(I)/VAR(NPER)
      SINX=SIN(ANG)
      COSX=COS(ANG)
      SINNX=SINX
      COSNX=COSX
      DO 30 J=1,NS
      JJ=2*J+NP1
      SNJ=SINNX*CSTHJJ(J)-COSNX*SNTHJJ(J)
      YHAT=YHAT+VAR(JJ)*SNJ
      CNX=COSNX
      SNX=SINNX
      SINNX=SNX*COSX+SINX*CNX
   30 COSNX=CNX*COSX-SNX*SINX
C
C ****COMPUTE RESIDUAL
C
   50 RESIDX=Y(I)-YHAT
      SUMSQ=SUMSQ+RESIDX*RESIDX
C
C     IF IFL NOT SET COMPUTE DERIVATIVES
C
C     THIS IS DONE IN EXACTLY THE SAME WAY AS COMPUTATION OF Y(I)
C     GRAD IS INDIRECTLY ADDRESSED VIA K(J)
C
      IF(IFL.EQ.2)   GO TO 100
      XP=1
      DO 40 J=1,NP1
      M=K(J)
      GRAD(M)=-XP
   40 XP=XP*X(I)
      IF(NS.EQ.0)   GO TO 60
      GP1=0.0
      ANG=ANG/VAR(NPER)
      DDP1=ANG
      SINNX=SINX
      COSNX=COSX
      DO 70 J=1,NS
      JJ=2*J+NP1
      M=K(JJ)
      M1=K(JJ+1)
      SNJ=SINNX*CSTHJJ(J)-COSNX*SNTHJJ(J)
      CSJ=COSNX*CSTHJJ(J)+SINNX*SNTHJJ(J)
      GRAD(M)=-SNJ
      GRAD(M1)=VAR(JJ)*CSJ
      GP1=GP1+VAR(JJ)*CSJ*DDP1
      DDP1=DDP1+ANG
      CNX=COSNX
      SNX=SINNX
      SINNX=SNX*COSX+SINX*CNX
   70 COSNX=CNX*COSX-SNX*SINX
      M=K(NPER)
      GRAD(M)=GP1
   60 DO 80 J=1,NPARAM
   80 K(J)=K(J)+1
      RESID(I)=RESIDX
  100 CONTINUE
      RETURN
      END


