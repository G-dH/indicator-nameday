bin_PROGRAMS = indicator-nameday

indicator_nameday_SOURCES = config.vapi indicator-nameday.vala

AM_CPPFLAGS = \
	-include config.h \
	$(indicator_nameday_CFLAGS) \
	-DVERSION=\"$(VERSION)\" \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\" \
	-DLOCALEDIR=\"$(localedir)\" \
	-DPKGDATADIR=\"$(pkgdatadir)\" \
	-DDATADIR=\"$(datadir)/indicator-nameday\" 

indicator_nameday_VALAFLAGS = @VALA_PACKAGES@

#indicator_nameday_CFLAGS = \
#-w \
#-DVERSION=\"$(VERSION)\" \
#-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\" \
#-DDATADIR=\""$(datadir)/indicator-nameday"\" \
#-DLOCALEDIR=\"$(datadir)/locale\" \
#$(INDICATOR_NAMEDAY_CFLAGS)

indicator_nameday_LDADD = $(indicator_nameday_LIBS)

CLEANFILES = *.h *.c *.stamp