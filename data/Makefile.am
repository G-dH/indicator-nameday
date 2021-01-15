SUBDIRS = icons

dbdir = $(datadir)/indicator-nameday/db
db_DATA = \
            db/cs.names \
            db/cs.holidays \
            db/sk.names \
            db/sk.holidays

desktopdir = $(datadir)/applications
desktop_in_files = indicator-nameday.desktop.in
desktop_DATA = $(desktop_in_files:.desktop.in=.desktop)
@INTLTOOL_DESKTOP_RULE@

EXTRA_DIST = $(db_DATA)
