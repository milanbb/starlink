#if HAVE_CONFIG_H
# include <config.h>
#endif

/* System includes */
#include <stdlib.h>

/* Private includes */
#include "mem.h"
#include "mem1.h"


/*
*  Name:
*     starRealloc

*  Purpose:
*     Starlink memory re-allocator

*  Invocation:
*     void * starRealloc( void * ptr, size_t size );

*  Description:
*     This function re-allocates memory using the memory management scheme
*     selected with a call to starMemInit(). Its interface is deliberately
*     intended to match the ANSI-C standard and so can be a drop in
*     replacement for system realloc(). The new memory may or may not be
*     initialised.

*  Parameters:
*     ptr = void * (Given)
*        Pointer to memory to be expanded/contracted. This memory will be
*        freed if the realloc() is successful. If it fails for any reason the
*        memory will remain unmodified. Can be a NULL pointer on entry.
*     size = size_t (Given)
*        New size, in bytes, of this memory area.

*  Returned Value:
*     starCalloc = void * (Returned)
*        Pointer to newly-allocated memory. NULL if the memory could not be 
*        obtained.

*  Authors:
*     TIMJ: Tim Jenness (JAC, Hawaii)

*  History:
*     09-FEB-2006 (TIMJ):
*        Original version.

*  Notes:
*     - The Garbage Collector malloc is only available if starMemInit() has
*       been invoked from the main program (not library) before this call.
*     - This routine should not be used to reallocate memory allocated by
*       the system malloc.
*     - This memory must be freed either by starFree() or starFreeForce()
*       and never the system free().

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

void * starRealloc( void * ptr, size_t size ) {
  void * tmp = NULL;

#if HAVE_GC_H
  if (STARMEM_USE_GC) {
    if (ptr == NULL) {
      tmp = starMalloc( size );
    } else {
      tmp = GC_REALLOC( ptr, size );
    }
    /*    printf("Realloc %ld bytes for pointer %p into %p\n",size,ptr,tmp);*/
    return tmp;
  }
#endif

  /* No GC so use system */
  return realloc( ptr, size );
}
