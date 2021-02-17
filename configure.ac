# configure.ac

AC_PREREQ([2.63])
AC_INIT([indicator-nameday],[0.4.5])
AC_CONFIG_SRCDIR([src/indicator-nameday.vala])
AC_CONFIG_HEADERS([config.h])
# AC_CONFIG_AUX_DIR(config)
AM_INIT_AUTOMAKE([no-dist-gzip dist-bzip2])


# Enable silent rules is available
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AM_MAINTAINER_MODE

#AC_PROG_MAKE_SET
AM_PROG_VALAC([0.30.0])
AM_PROG_CC_C_O
AC_PROG_INSTALL

GLIB_GSETTINGS

pkg_modules="glib-2.0 >= 2.24.1
             gobject-2.0 >= 2.24.1
             gtk+-3.0 >= 3.2
             appindicator3-0.1 >= 0.1"

VALA_PACKAGES="--pkg gtk+-3.0 --pkg appindicator3-0.1"
PKG_CHECK_MODULES(indicator_nameday, [$pkg_modules])
AC_SUBST(indicator_nameday_CFLAGS)
AC_SUBST(indicator_nameday_LIBS)
AC_SUBST(VALA_PACKAGES)

IT_PROG_INTLTOOL(0.51)
AC_SUBST(GETTEXT_PACKAGE, indicator-nameday)
#GETTEXT_PACKAGE=indicator-nameday
#AC_DEFINE_UNQUOTED([GETTEXT_PACKAGE], ["$GETTEXT_PACKAGE"], [Gettext Package])
#AC_SUBST(GETTEXT_PACKAGE)
#AM_GNU_GETTEXT_VERSION([0.18])
#AM_GLIB_GNU_GETTEXT

YELP_HELP_INIT

AC_CONFIG_FILES([
                  Makefile
                  src/Makefile
                  data/Makefile
                  data/icons/Makefile
                  po/Makefile.in
])


AC_OUTPUT
