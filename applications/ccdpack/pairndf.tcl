#+
#  Name:
#     pairndf.tcl
#
#  Purpose:
#     Script to do the work for the PAIRNDF application.
#
#  Language:
#     Tcl.
#
#  Description:
#     This script uses custom [incr Tcl] classes to present a GUI to the
#     user which allows interactive placement of pairs of NDFs.
#
#  External Variables:
#     MATPTS = list of lists of quads (Returned)
#        This gives a list of the centroided points for each of the 
#        pairs of NDFs which the user matched up.  It contains one 
#        element for each element of the PAIRS list.  Each element of
#        the list contains an entry for each of the points which waas
#        successfully centroided in both NDFs, and each of those
#        entries is a quad giving coordinates in each NDF, of the 
#        form {X1 Y1 X2 Y2}.
#     MAXCANV = integer (Given)
#        The maximum X or Y dimension of the canvas in which the initial
#        pair of NDFs is to be displayed.  If zero, there is no limit.
#     MAXPOS = integer (Given)
#        The maximum number of points which may be selected on the 
#        overlap region of any pair of NDFs.
#     NDFNAMES = list of strings (Given)
#        A list of strings giving the name of each of the NDFs which is
#        to be presented to the user for aligning using this script.
#     PAIRS = list of lists (Returned)
#        The script returns a list with one element for each pair of NDFs
#        which the user managed to match.  Each element of the list is 
#        of the form {I J NMAT XOFF YOFF}, where I and J are the indices
#        in the list NDFNAMES of the matched pair, NMAT is the number of
#        centroided points which were used to achieve the exact offsets,
#        and XOFF and YOFF are the position of the pixel index origin of
#        NDF J in pixel index coordinates of NDF I.
#     PERCHI = real (Given)
#        The percentile of the data above which all values should be 
#        plotted as the same colour.  Must be between 0 and 100.
#     PERCLO = real (Given)
#        The percentile of the data below which all values should be 
#        plotted as the same colour.  Must be between 0 and 100.
#     WINX = integer (Given and Returned)
#        X dimension of the window used for NDF display.
#     WINY = integer (Given and Returned)
#        Y dimension of the window used for NDF display.
#     ZOOM = real (Given and Returned)
#        The zoom factor for NDF display; may be limited by the value of
#        MAXCANV.
#
#  Authors:
#     MBT: Mark Taylor (STARLINK)
#
#  History:
#     4-SEP-2000 (MBT):
#        Original version.
#-


#  Set defaults for some arguments.
      foreach pair { { MAXCANV 0 } { MAXPOS 100 } { PERCLO 5 } { PERCHI 95 } \
                     { WINX 300 } { WINY 300 } { ZOOM 1 } } {
         if { ! [ info exists [ lindex $pair 0 ] ] } {
            eval set $pair
         }
      }

#  Perform miscellaneous initialisation.
      tasksetup

#  Initialise screen.
      wm withdraw .

#  Generate ndf objects for all of the NDFs in the input list.
      set nndf 0
      set ndflist {}
      foreach n $NDFNAMES {
         incr nndf
         set ndf [ ndf $n ]
         set ndfs($nndf) $ndf
         lappend ndflist $ndf
      }

#  Create an NDF pair alignment widget.
      set aligner [ ndfalign .a ]
      wm withdraw $aligner
      $aligner configure \
                         -title "PAIRNDF: %An -- %Bn" \
                         -info "%N (%h x %w) Frame: %f" \
                         -watchstate alignstate \
                         -percentiles [ list $PERCLO $PERCHI ] \
                         -zoom $ZOOM \
                         -geometry ${WINX}x${WINY} \
                         -uselabels 0 \
                         -maxpoints $MAXPOS

#  Set the pair selection criterion.
      set choosestate ""
      proc pairok { a b } {
         if { ( $a != "" && $b != "" ) && ( [ array size done ] == 0 || \
                                            [ array names done $a ] != "" || \
                                            [ array names done $b ] != "" ) } { 
            return 1 
         } else {
            return 0
         }
      }

#  Create an NDF chooser widget.
      set chooser [ eval ndfchoose .c $ndflist ]
      $chooser configure \
                         -title "PAIRNDF chooser" \
                         -watchstate choosestate \
                         -validpair [ code pairok %A %B ] \
                         -percentiles [ list $PERCLO $PERCHI ]

#  Loop until all the NDFs have been paired.
      while { [ array size done ] < $nndf } {

#  Get the user to pick a pair of NDFs.
         raise $chooser
         set pair ""
         while { [ llength $pair ] != 2 } {
            $chooser configure -state active
            tkwait variable choosestate

            set pair [ $chooser getpair ]
            set iA [ lindex $pair 0 ]
            set iB [ lindex $pair 1 ]

            if { [ $chooser cget -state ] == "done" } {
               set confirmtext "Not enough images have been paired\n"
               append confirmtext "to register them all.\n"
               append confirmtext "Do you really wish to exit?"
               iwidgets::messagedialog .md \
                  -modality application \
                  -bitmap questhead \
                  -title "PAIRNDF: Confirm exit" \
                  -text $confirmtext
               .md buttonconfigure Cancel -text "Abort PAIRNDF"
               .md buttonconfigure OK -text "Continue processing"
               .md hide Help
               set response [ .md activate ]
               destroy .md
               if { $response } {
                  set pair ""
               } else {
                  break
               }
            }
         }

#  Exit the loop if the user has indicated that the session is at an end.
         if { $choosestate == "done" } break

#  Log to the user.
         ccdlog "  "
         ccdlog "  Aligning NDFS $iA and $iB"

#  Load the NDF pair into the aligner widget and wait for the user to 
#  select some positions in common.
         raise $aligner
         $aligner loadndf A $ndfs($iA) $MAXCANV
         $aligner loadndf B $ndfs($iB) $MAXCANV
         $aligner activate
         tkwait variable alignstate
         set mc [ $aligner maxcanvas ]
         set MAXCANV [ $aligner maxcanvas ]

#  Get the resulting lists of points.
         set pA [ $aligner pointsndf A CURRENT ]
         set pB [ $aligner pointsndf B CURRENT ]
         set npoints [ llength $pA ]

#  We have a usable list of objects.  Try to centroid them.
         if { $npoints > 0 } {
            set pts {}
            for { set i 0 } { $i < $npoints } { incr i } {
               lappend pts [ list [ lindex [ lindex $pA $i ] 1 ] \
                                  [ lindex [ lindex $pA $i ] 2 ] \
                                  [ lindex [ lindex $pB $i ] 1 ] \
                                  [ lindex [ lindex $pB $i ] 2 ] ]
            }
	    set scale [ expr [ $aligner cget -zoom ] * \
                             [ $ndfs($iA) pixelsize CURRENT ] ]
            set offset [ ndfcentroffset $ndfs($iA) CURRENT $ndfs($iB) CURRENT \
                         $pts $scale ]
            set nmatch [ lindex $offset 0 ]

#  We have a successful match.
            if { $nmatch > 0 } {
               set xoff [ lindex $offset 1 ]
               set yoff [ lindex $offset 2 ]
               set matchpts [ lindex $offset 3 ]

#  Tell the user that the match succeeded.
               ccdlog \
               "    Centroiding successful: $nmatch/$npoints objects matched."

#  Add this datum to the results list.  By storing these in a hash at
#  this stage, we ensure we don't pass back duplicate pairings to the
#  calling routine.
               set pairs($iA,$iB) [ list $nmatch $xoff $yoff $matchpts ]

#  Record the fact that these images have been connected.
               set done($iA) 1
               set done($iB) 1

#  Visually reflect the fact that they have been connected.
               $chooser highlight $iA 1
               $chooser highlight $iB 1

#  No objects were matched between frames.
            } else {
               ccdlog "    Centroiding failed, no offset determined - ignored."
            }

#  There was an overlap, but the user failed to indicate any points to 
#  be centroided.
         } elseif { [ $aligner overlapping ] } {
            ccdlog "    No points selected in overlap - ignored."

#  The user decided there was no overlap between the selected images.
         } else {
            ccdlog "    Images do not overlap - ignored."
         }
      }

#  Write the returned PAIRS list.
      set PAIRS {}
      foreach key [ array names pairs ] {
         regexp {^([0-9]+),([0-9]+)$} $key dummy iA iB
         set val $pairs($key)
         set nmatch [ lindex $val 0 ]
         set xoff [ lindex $val 1 ]
         set yoff [ lindex $val 2 ]
         set matpts [ lindex $val 3 ]
         lappend PAIRS [ list $iA $iB $nmatch $xoff $yoff ]
         lappend MATPTS $matpts
      }

#  Destroy remaining windows.
      destroy $chooser
      destroy $aligner

# $Id$
