      FUNCTION CPFX (IX)
C
C Given an x coordinate IX in the plotter system, CPFX(IX) is an x
C coordinate in the fractional system.
C
      COMMON /IUTLCM/ LL,MI,MX,MY,IU(96)
      CPFX=FLOAT(IX-1)/(2.**MX-1.)
      RETURN
      END
