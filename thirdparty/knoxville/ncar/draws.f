      SUBROUTINE DRAWS (MX1,MY1,MX2,MY2,IDRAW,IMARK)
C
C THIS ROUTINE DRAWS THE VISIBLE PART OF THE LINE CONNECTING
C (MX1,MY1) AND (MX2,MY2).  IF IDRAW .NE. 0, THE LINE IS DRAWN.
C IF IMARK .NE. 0, THE VISIBILITY ARRAY IS MARKED.
C
      LOGICAL         VIS1       ,VIS2
      DIMENSION       PXS(2)     ,PYS(2)
      COMMON /SRFBLK/ LIMU(1024) ,LIML(1024) ,CL(41)     ,NCL        ,
     1                LL         ,FACT       ,IROT       ,NDRZ       ,
     2                NUPPER     ,NRSWT      ,BIGD       ,UMIN       ,
     3                UMAX       ,VMIN       ,VMAX       ,RZERO      ,
     4                IOFFP      ,NSPVAL     ,SPVAL      ,BIGEST
      EXTERNAL        SRFABD
      DATA STEEP/5./
      DATA MX,MY/0,0/
C
C MAKE LINE LEFT TO RIGHT.
C
      MMX1 = MX1
      MMY1 = MY1
      MMX2 = MX2
      MMY2 = MY2
      IF (MMX1.EQ.NSPVAL .OR. MMX2.EQ.NSPVAL) RETURN
      IF (MMX1 .GT. MMX2) GO TO  10
      NX1 = MMX1
      NY1 = MMY1
      NX2 = MMX2
      NY2 = MMY2
      GO TO  20
   10 NX1 = MMX2
      NY1 = MMY2
      NX2 = MMX1
      NY2 = MMY1
   20 IF (NUPPER .LT. 0) GO TO 180
C
C CHECK UPPER VISIBILITY.
C
      VIS1 = NY1 .GE. (LIMU(NX1)-1)
      VIS2 = NY2 .GE. (LIMU(NX2)-1)
C
C VIS1 AND VIS2 TRUE MEANS VISIBLE.
C
      IF (VIS1 .AND. VIS2) GO TO 120
C
C VIS1 AND VIS2 FALSE MEANS INVISIBLE.
C
      IF (.NOT.(VIS1 .OR. VIS2)) GO TO 180
C
C FIND CHANGE POINT.
C
      IF (NX1 .EQ. NX2) GO TO 110
      DY = FLOAT(NY2-NY1)/FLOAT(NX2-NX1)
      NX1P1 = NX1+1
      FNY1 = NY1
      IF (VIS1) GO TO  60
      DO  30 K=NX1P1,NX2
         MX = K
         MY = FNY1+FLOAT(K-NX1)*DY
         IF (MY .GT. LIMU(K)) GO TO  40
   30 CONTINUE
   40 IF (ABS(DY) .GE. STEEP) GO TO  90
   50 NX1 = MX
      NY1 = MY
      GO TO 120
   60 DO  70 K=NX1P1,NX2
         MX = K
         MY = FNY1+FLOAT(K-NX1)*DY
         IF (MY .LT. LIMU(K)) GO TO  80
   70 CONTINUE
   80 IF (ABS(DY) .GE. STEEP) GO TO 100
      NX2 = MX
      NY2 = MY
      GO TO 120
   90 IF (LIMU(MX) .EQ. 0) GO TO  50
      NX1 = MX
      NY1 = LIMU(NX1)
      GO TO 120
  100 NX2 = MX
      NY2 = LIMU(NX2)
      GO TO 120
  110 IF (VIS1) NY2 = MIN0(LIMU(NX1),LIMU(NX2))
      IF (VIS2) NY1 = MIN0(LIMU(NX1),LIMU(NX2))
  120 IF (IDRAW .EQ. 0) GO TO 150
C
C DRAW VISIBLE PART OF LINE.
C
      IF (IROT) 130,140,130
  130 CONTINUE
      PXS(1) = FLOAT(NY1)
      PXS(2) = FLOAT(NY2)
      PYS(1) = FLOAT(1024-NX1)
      PYS(2) = FLOAT(1024-NX2)
      CALL GPL (2,PXS,PYS)
      GO TO 150
  140 CONTINUE
      PXS(1) = FLOAT(NX1)
      PXS(2) = FLOAT(NX2)
      PYS(1) = FLOAT(NY1)
      PYS(2) = FLOAT(NY2)
      CALL GPL (2,PXS,PYS)
  150 IF (IMARK .EQ. 0) GO TO 180
      IF (NX1 .EQ. NX2) GO TO 170
      DY = FLOAT(NY2-NY1)/FLOAT(NX2-NX1)
      FNY1 = NY1
      DO 160 K=NX1,NX2
         LIMU(K) = FNY1+FLOAT(K-NX1)*DY
  160 CONTINUE
      GO TO 180
  170 LIMU(NX1) = MAX0(NY1,NY2)
  180 IF (NUPPER) 190,190,370
C
C SAME IDEA AS ABOVE, BUT FOR LOWER SIDE.
C
  190 IF (MMX1 .GT. MMX2) GO TO 200
      NX1 = MMX1
      NY1 = MMY1
      NX2 = MMX2
      NY2 = MMY2
      GO TO 210
  200 NX1 = MMX2
      NY1 = MMY2
      NX2 = MMX1
      NY2 = MMY1
  210 VIS1 = NY1 .LE. (LIML(NX1)+1)
      VIS2 = NY2 .LE. (LIML(NX2)+1)
      IF (VIS1 .AND. VIS2) GO TO 310
      IF (.NOT.(VIS1 .OR. VIS2)) GO TO 370
      IF (NX1 .EQ. NX2) GO TO 300
      DY = FLOAT(NY2-NY1)/FLOAT(NX2-NX1)
      NX1P1 = NX1+1
      FNY1 = NY1
      IF (VIS1) GO TO 250
      DO 220 K=NX1P1,NX2
         MX = K
         MY = FNY1+FLOAT(K-NX1)*DY
         IF (MY .LT. LIML(K)) GO TO 230
  220 CONTINUE
  230 IF (ABS(DY) .GE. STEEP) GO TO 280
  240 NX1 = MX
      NY1 = MY
      GO TO 310
  250 DO 260 K=NX1P1,NX2
         MX = K
         MY = FNY1+FLOAT(K-NX1)*DY
         IF (MY .GT. LIML(K)) GO TO 270
  260 CONTINUE
  270 IF (ABS(DY) .GE. STEEP) GO TO 290
      NX2 = MX
      NY2 = MY
      GO TO 310
  280 IF (LIML(MX) .EQ. 1024) GO TO 240
      NX1 = MX
      NY1 = LIML(NX1)
      GO TO 310
  290 NX2 = MX
      NY2 = LIML(NX2)
      GO TO 310
  300 IF (VIS1) NY2 = MAX0(LIML(NX1),LIML(NX2))
      IF (VIS2) NY1 = MAX0(LIML(NX1),LIML(NX2))
  310 IF (IDRAW .EQ. 0) GO TO 340
      IF (IROT) 320,330,320
  320 CONTINUE
      PXS(1) = FLOAT(NY1)
      PXS(2) = FLOAT(NY2)
      PYS(1) = FLOAT(1024-NX1)
      PYS(2) = FLOAT(1024-NX2)
      CALL GPL (2,PXS,PYS)
      GO TO 340
  330 CONTINUE
      PXS(1) = FLOAT(NX1)
      PXS(2) = FLOAT(NX2)
      PYS(1) = FLOAT(NY1)
      PYS(2) = FLOAT(NY2)
      CALL GPL (2,PXS,PYS)
  340 IF (IMARK .EQ. 0) GO TO 370
      IF (NX1 .EQ. NX2) GO TO 360
      DY = FLOAT(NY2-NY1)/FLOAT(NX2-NX1)
      FNY1 = NY1
      DO 350 K=NX1,NX2
         LIML(K) = FNY1+FLOAT(K-NX1)*DY
  350 CONTINUE
      RETURN
  360 LIML(NX1) = MIN0(NY1,NY2)
  370 RETURN
      END
