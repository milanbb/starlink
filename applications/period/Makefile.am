## Process this file with automake to produce Makefile.in

bin_PROGRAMS = period
noinst_LTLIBRARIES = libperiod.la
dist_noinst_INCLUDES = PIVARS

period_SOURCES = period_main.f
period_LDADD = libperiod.la `fio_link` `$(srcdir)/period_link`

starnewsdir = $(datadir)/doc/@PACKAGE_NAME@-@PACKAGE_VERSION@
dist_starnews_DATA = period.news

dist_pkgdata_DATA = period_test.dat

stardocs_DATA = @STAR_LATEX_DOCUMENTATION@

##  The on-line help, special PERIOD format.
HELP_SOURCES = period_chisq.hlp period_freq.hlp period_output.hlp     \
period_select.hlp period_clean.hlp period_ft.hlp period_pdm.hlp       \
period_sig.hlp period_close.hlp period_help.hlp period_peaks.hlp      \
period_sine.hlp period_detrend.hlp period_input.hlp period_period.hlp \
period_status.hlp period_fake.hlp period_noise.hlp period_plt.hlp     \
period_string.hlp period_fit.hlp period_ogip.hlp period_quit.hlp      \
period_window.hlp period_fold.hlp period_open.hlp period_scargle.hlp

starhelp_DATA = $(HELP_SOURCES)

libperiod_la_SOURCES = period_add.f period_alloc.f period_alpha.f      \
period_autolim.f period_case.f period_clean.f period_convolv.f	       \
period_cval.f period_datastatus.f period_deall.f period_detrend.f      \
period_dfour.f period_fake.f period_fakechaos.f period_fakeperiod.f    \
period_fillb.f period_fit.f period_fold.f period_foldsortcycle.f       \
period_four1.f period_ft.f period_gasdev.f period_get1dint.f	       \
period_get2d.f period_help.f period_hwhm.f period_init2d.f	       \
period_input.f period_inputsortcycle.f period_intro.f		       \
period_loadoutall.f period_loadoutone.f period_log.f period_lsquar.f   \
period_maxloc.f period_mlsrar.f period_modsinecurve.f period_moment.f  \
period_noise.f period_noisenew.f period_noiseold.f period_ogip.f       \
period_ogipextns.f period_ogipsortcycle.f period_ogipstore.f	       \
period_output.f period_parse.f period_pdm.f period_performclean.f      \
period_performft.f period_performoutput.f period_performpdm.f	       \
period_period.f period_phase.f period_phasebin.f period_plt.f	       \
period_pltxyerr.f period_poly.f period_prepscargle.f period_put1d.f    \
period_putfitdata.f period_putxyerr.f period_putymean.f		       \
period_putypoly.f period_quit.f period_ran1.f period_readantares.f     \
period_readfree.f period_realft.f period_scargle.f period_select.f     \
period_setdata.f period_setdatasqrt.f period_setupwindow.f	       \
period_setx.f period_setxydata.f period_setxyedata.f period_setxyerr.f \
period_setxyiferr.f period_shellsort.f period_siginfogt.f	       \
period_siginfolt.f period_sine.f period_sinfit.f period_spread.f       \
period_status.f period_string.f period_strip.f period_subcmp.f	       \
period_window.f period_yandeshuffle.f period_yshuffle.f                \
period_writebell.f
