## Process this file with automake to produce Makefile.in

lib_LTLIBRARIES = libfio.la libfio_adam.la
dist_bin_SCRIPTS = fio_link fio_link_adam
noinst_PROGRAMS = make-errno-err

libfio_la_SOURCES = \
	$(BLOCK_DATA_STANDALONE) \
	$(F_ROUTINES) \
	$(FPP_ROUTINES) \
	$(PLATFORM_F)
libfio_adam_la_SOURCES = \
	$(BLOCK_DATA_ADAM) \
	$(F_ROUTINES_ADAM)

include_HEADERS = $(PUBLIC_INCLUDES)
include_MESSAGES = FIO_ERR

stardocs_DATA = @STAR_LATEX_DOCUMENTATION@

make_errno_err_SOURCES = make-errno-err.c

#  List of Fortran routines required for building the package.  This is
#  just a list of all the Fortran source files (excluding BLOCK DATA
#  routines, which are treated separately).
F_ROUTINES = \
        fio1_chkfd.f \
        fio1_getfd.f \
        fio_close.f \
        fio_erase.f \
        fio_fname.f \
        fio_gunit.f \
        fio_open.f \
        fio_punit.f \
        fio_read.f \
        fio_readf.f \
        fio_rep.f \
        fio_rwind.f \
        fio_serr.f \
        fio_start.f \
        fio_stop.f \
        fio_test.f \
        fio_unit.f \
        fio_write.f \
        rio_close.f \
        rio_erase.f \
        rio_open.f \
        rio_read.f \
        rio_write.f

#  List of Fortran routines which are specific to the operation under ADAM
F_ROUTINES_ADAM = \
        fio1_chkfp.f \
        fio1_fndfp.f \
        fio1_getfp.f \
        fio_activ.f \
        fio_annul.f \
        fio_assoc.f \
        fio_cancl.f \
        fio_deact.f \
        rio_annul.f \
        rio_assoc.f \
        rio_cancl.f

FPP_ROUTINES = \
        fio1_open.F \
        rio1_open.F

# Platform-specific Fortran routines.  See corresponding stanza in configure.ac
PLATFORM_F = \
        fio1_serr.f

#  List of Fortran BLOCK DATA routines, for both the standalone and
# ADAM versions of the library.
BLOCK_DATA_STANDALONE = fio_blk.f
BLOCK_DATA_ADAM = fiopa_blk.f

#  List of public include files.  These are include files which form
#  part of the package and may be required by users of it.
PUBLIC_INCLUDES = FIO_PAR

#  List of private include files.  These are additional include files
#  which form part of the package and are required in order to build
#  it, but which are not required by users of it, and which are not installed
PRIVATE_INCLUDES = \
        FIO_SYS \
        FIOFIL_CMN \
        FIOGO_CMN \
        FIOGOPA_CMN \
        FIOUNT_CMN \
        FIOPAR_SYS \
        FIOPA_CMN \
        ERRNO_ERR \
        FIO1_SERR_PC_LINUX

# ERRNO_ERR is generated from make-errno-err
ERRNO_ERR:  make-errno-err
	-rm -f ERRNO_ERR
	$(srcdir)/make-errno-err

# and required by fio1_serr
fio1_serr.lo: ERRNO_ERR

## Create FIO1_SERR_PC_LINUX from the processed source.
FIO1_SERR_PC_LINUX: FIO1_SERR_PC_LINUX.F
	rm -f $@
	$(FPP) $(FPPFLAGS) $(DEFAULT_INCLUDES) $(CPPFLAGS) FIO1_SERR_PC_LINUX.F $(FPP_OUTPUT)
	test -f $@ || mv FIO1_SERR_PC_LINUX.f $@
	rm -f FIO1_SERR_PC_LINUX.tmp
	echo "* Generated from FIO1_SERR_PC_LINUX.F using preprocessor $(FPP)" > FIO1_SERR_PC_LINUX.tmp
	echo "* DO NOT EDIT THIS FILE" >> FIO1_SERR_PC_LINUX.tmp
	grep '^ .*[^ ]' $@ >> FIO1_SERR_PC_LINUX.tmp
	rm -f $@
	mv FIO1_SERR_PC_LINUX.tmp $@

BUILT_SOURCES = $(PRIVATE_INCLUDES) $(include_MESSAGES)

# fiotest is an ADAM monolith
# Note that fio_test.f is not used anywhere but there is no calling
# program for it to run as a test

TESTS = fiotest
check_MONOLITHS = fiotest

# no variable fiotest_TASKS -- fiotest is an ATASK
fiotest_SOURCES = fiotest.f
fiotest_LDADD = `$(srcdir)/fio_link_adam`

dist_starnews_DATA = fio.news
dist_pkgdata_DATA = LICENCE

EXTRA_DIST = sun_iosdef_sun_solaris sun_iosdef_sun fio1_serr.f_apple_darwin \
             fio1_serr.f_dec_osf fio1_serr.fdefault fio1_serr.f_linux_gnu \
             fio1_serr.fmips fio1_serr.f_pc_cygwin fio1_serr.f_pc_linux \
             fio1_serr.f_sun fio1_serr.f_sun_solaris fio1_serr.fvax \
             FIOGO_CMN FIO_SYS FIOFIL_CMN FIOUNT_CMN FIOGOPA_CMN FIOPAR_SYS \
             FIOPA_CMN FIO1_SERR_PC_LINUX.F

CLEANFILES = CREATEFILE.DAT NEWFILE.DAT fiotest fiotest.ifc FIO1_SERR_PC_LINUX
