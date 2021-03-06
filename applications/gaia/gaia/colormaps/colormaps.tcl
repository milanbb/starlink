#!../bin/rtdimage_wish
#
# E.S.O. - VLT project
#
# "@(#) $Id$"
#
# script to generate C code including static colormaps, so that the ,
# (binary) application doesn't have to be delivered with the colormap files.
#
# who             when       what
# --------------  ---------  ----------------------------------------
# Allan Brighton  19 Nov 97  Created

puts {
/*
 * E.S.O. - VLT project
 * "@(#) $Id$"
 *
 * Colormap definitions for RTD
 *
 * This file was generated by ../colormaps/colormaps.tcl  - DO NOT EDIT
 */

#include <ColorMapInfo.h>
#include <ITTInfo.h>

}

puts "void defineGaiaColormaps() {"

# colormaps
foreach file [glob -nocomplain *.lasc] {
    set fd [open $file]
    set name [file tail $file]
    set root [file rootname $name]
    set ar ${root}_lasc
    puts "\tstatic RGBColor $ar\[\] = {"
    while {[gets $fd line] != -1} {
	puts "\t\t{[join $line {, }]},"
    }
    puts "\t};"
    puts "\tnew ColorMapInfo(\"$name\", $ar);\n"
}

# itts
foreach file [glob -nocomplain *.iasc] {
    set fd [open $file]
    set name [file tail $file]
    set root [file rootname $name]
    set ar ${root}_iasc
    puts "\tstatic double $ar\[\] = {"
    while {[gets $fd line] != -1} {
	puts "\t\t[lindex $line 0],"
    }
    puts "\t};"
    puts "\tnew ITTInfo(\"$name\", $ar);\n"
}

puts "}"
exit 0
