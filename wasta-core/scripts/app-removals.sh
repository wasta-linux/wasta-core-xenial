#!/bin/bash

# ==============================================================================
# wasta-core: app-removals.sh
#
#   This script will remove apps deemed "unnecessary" for default users.
#
#   2013-10-16 rik: initial script
#   2013-11-26 jcl: superuser block: remove -l in su -l (wrong working directory
#       context) and added $* to pass command line parameters along.
#   2014-12-17 rik: adding software-center: now defaulting to mintinstall since
#       it works with wasta-offline.  USC doesn't.
#   2015-01-22 rik: adding mdm: now use lightdm
#   2015-07-27 rik: adding lightdm: now use mdm :-)
#   2015-10-25 rik: refactoring for Ubuntu 15.10 base
#   2015-11-04 rik: removing overlay-scrollbar* (15.10 still used for gtk2)\
#   2015-11-08 rik: removing appmenu-qt5: this prevents vlc from showing
#       in system tray.  See bug report:
#       https://bugs.launchpad.net/ubuntu/+source/appmenu-qt5/+bug/1514147
#
# ==============================================================================

# ------------------------------------------------------------------------------
# Check to ensure running as root
# ------------------------------------------------------------------------------
#   No fancy "double click" here because normal user should never need to run
if [ $(id -u) -ne 0 ]
then
	echo
	echo "You must run this script with sudo." >&2
	echo "Exiting...."
	sleep 5s
	exit 1
fi

# ------------------------------------------------------------------------------
# Initial Setup
# ------------------------------------------------------------------------------

echo
echo "*** Script Entry: app-removals.sh"
echo
# Setup Diretory for later reference
DIR=/usr/share/wasta-core

# if 'auto' parameter passed, run non-interactively
if [ "$1" == "auto" ];
then
    AUTO="auto"
    
    # needed for apt-get
    YES="--yes"
else
    AUTO=""
    YES=""
fi

# ------------------------------------------------------------------------------
# Base Packages to remove for all systems
# ------------------------------------------------------------------------------

echo
echo "*** Removing Unwanted Applications"
echo

# adobe-flash-properties-gtk: no need for flash setup tool
# appmenu-qt5: this prevents vlc from showing in system tray
#   https://bugs.launchpad.net/ubuntu/+source/appmenu-qt5/+bug/1514147
# deja-dup: we use wasta-backup
# empathy: chat client
# fonts-*: non-english fonts
# gdm: gnome display manager (we use lightdm)
# gnome-orca: screen reader
# landscape-client-ui-install: pay service only for big corporations
# overlay-scrollbar*: these are garbage (15.10 still used for gtk2)
# totem: not needed as vlc handles all video/audio
# transmission: normal users doing torrents probably isn't preferred
# ttf-* fonts: non-english font families
# unity-webapps-common: amazon, etc.
# webbrowser-app: ubuntu web browser (firefox only)
# xterm: not sure how got installed, but don't need since gnome-terminal


apt-get $YES purge \
    adobe-flash-properties-gtk \
    appmenu-qt5 \
    deja-dup \
    empathy-common \
    fonts-*tlwg* \
        fonts-khmeros-core \
        fonts-lao \
        fonts-nanum \
        fonts-takao-pgothic \
    gdm \
    gnome-orca \
    landscape-client-ui-install \
    overlay-scrollbar* \
    totem \
        totem-common \
        totem-plugins \
    transmission-common \
    ttf-indic-fonts-core \
        ttf-kacst-one \
        ttf-khmeros-core \
        ttf-punjabi-fonts \
        ttf-takao-pgothic \
        ttf-thai-tlwg \
        ttf-unfonts-core \
        ttf-wqy-microhei \
    unity-webapps-common \
    webbrowser-app \
    xterm

echo
echo "*** Script Exit: app-removals.sh"
echo

exit 0
