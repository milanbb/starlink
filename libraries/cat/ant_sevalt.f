
*+
*  Name:
*    ant_sevalt

*  Copyright:
*    Copyright (C) 2006 Particle Physics & Astronomy Research Council.
*    All Rights Reserved.

*  Licence:
*    This program is free software; you can redistribute it and/or
*    modify it under the terms of the GNU General Public License as
*    published by the Free Software Foundation; either version 2 of
*    the License, or (at your option) any later version.
*
*    This program is distributed in the hope that it will be
*    useful,but WITHOUT ANY WARRANTY; without even the implied
*    warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*    PURPOSE. See the GNU General Public License for more details.
*
*    You should have received a copy of the GNU General Public License
*    along with this program; if not, write to the Free Software
*    Foundation, Inc., 51 Franklin Street,Fifth Floor, Boston, MA
*    02110-1301, USA

*-
*

*    Numeric types are in ant_sevalx.gn

*
*    Logical version.

      SUBROUTINE ANT_SEVALL (XID, NROW, NULFLG, VALUE, STATUS)
      IMPLICIT NONE

      INTEGER XID, NROW
      LOGICAL NULFLG
      LOGICAL VALUE
      INTEGER STATUS

      CALL ANT_XEVALL (XID, NROW, NULFLG, VALUE, STATUS)

      END

*
*    Character version.

      SUBROUTINE ANT_SEVALC (XID, NROW, NULFLG, VALUE, STATUS)
      IMPLICIT NONE

      INTEGER XID, NROW
      LOGICAL NULFLG
      CHARACTER VALUE*(*)
      INTEGER STATUS

      CALL ANT_XEVALC (XID, NROW, NULFLG, VALUE, STATUS)

      END
