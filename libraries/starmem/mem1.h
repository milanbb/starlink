#if !defined ( STAR_MEM1_INCLUDED )   /* Include file only once */
#define STAR_MEM1_INCLUDED

/*
*  Name:
*     mem1.h

*  Purpose:
*     Private include file for starmem

*  Description:
*     This include file declares the private interface to the
*     starmem library.

*  Authors:
*     TIMJ: Tim Jenness (JAC, Hawaii)

*  History:
*     08-FEB-2006 (TIMJ):
*        Original version.

*  Copyright:
*     Copyright (C) 2006 Particle Physics and Astronomy Research Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public
*     License along with this program; if not, write to the Free
*     Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
*     MA 02111-1307, USA

*/

/* State variables - set in mem1_globals.c */
extern int STARMEM_USE_GC;
extern int STARMEM_INITIALISED;

/* STAR_MEM1_INCLUDED */
#endif
