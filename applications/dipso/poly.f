      SUBROUTINE POLY(XC,YC,N,ANGLE,EXPAND,XYRATIO,XS,YS,NS)
      REAL XS(NS), YS(NS)
      PARAMETER (PI=3.14159265)

      DTHETA = 2 * PI / N
      THETA = (3*PI + DTHETA)/2 + ANGLE
      FRACT=0.01
      XS(1) = FRACT*EXPAND*COS(THETA) + XC
      YS(1) = FRACT*EXPAND*SIN(THETA)*XYRATIO + YC
      NS=1
      DO J = 1,N
         THETA = THETA + DTHETA
         NS=NS+1
         XS(NS) = FRACT*EXPAND*COS(THETA) + XC
         YS(NS) = FRACT*EXPAND*SIN(THETA) * XYRATIO+ YC
      ENDDO
      END
