#!/bin/bash

# ==============================================================================
# wasta-core: app-installs.sh
#
#   2012-10-20 rik: Initial script - for Linux Mint 13 Maya Cinnamon
#   2013-01-03 rik: several adjustments, added superuser block.
#   2013-04-02 rik: Added "Make PDF Booklet" right click option
#   2013-06-12 rik: Added chmod 644 for copied resources.  Added a bit of 
#       testing logic to better support re-running.
#   2013-06-20 rik: Adding several adjustments:
#       -updating for Cinnamon 1.8.x compatibilty
#       -adding sil repository and basic sil fonts
#       -adding libreoffice 4.0 ppa
#       -replacing 'echo | tee ...' with one-liner sed append / delete
#   2013-08-14 jcl: Nemo Actions for A4 PDF booklet printing, image resizing.
#   2013-10-16 rik: Refactored into wasta-base-apps-upgrade.  Other sections moved
#       to wasta-base-setup preinst and postinst.
#   2013-11-26 jcl: superuser block: remove -l in su -l (wrong working directory
#       context) and added $* to pass command line parameters along.
#   2013-12-19 rik: locale cleanup, ia32-libs confirm for 64bit skype install
#       (this enables gtk theme to be used for 32bit apps, etc.)
#   2014-01-29 rik: added xmlstarlet
#   2014-02-03 rik: added extundelete
#   2014-06-02 rik: adding artha, glipper
#       - cleanup / updates for Mint 17
#       - adblock global firefox extension
#   2014-06-14 rik: removing skype autostart (now placed by wasta-base-setup
#       install).
#   2014-07-22 rik: adding btrfs-tools, imagemagick
#   2014-07-23 rik: adding linux-generic (to keep kernel up-to-date: mint
#       holds it back by using their "linux-kernel-generic" instead).
#   2014-07-25 rik: cleaning out prior adblock folder if found.
#   2014-12-17 rik: adding several apps for wl 14.04
#   2015-01-09 rik: adding LO 4.3 PPA here (won't force on users in postinst)
#   2015-01-21 rik: adding lightdm: can't login to gnome-shell from mdm
#   2015-06-18 rik: adding exfat-utils, exfat-fuse for exfat compatiblity
#   2015-07-27 rik: adding mdm: lightdm issues with cinnamon usb automount
#   2015-08-05 rik: adding error processing in case an apt command failed
#   2015-08-13 rik: holding casper, ubiquity-casper: new version 1.340.2 will
#       cause remastersys to go to a login screen when booting the Live Session
#   2015-08-15 rik: removing casper, ubiquity-casper hold (solved casper
#       issues.
#   2015-10-25 rik: refactoring for Ubuntu 15.10
#   2015-11-04 rik: adding mkusb-nox (usb-creator-gtk issue with 15.10)
#   2015-11-05 rik: adding tracker (gnome-shell file search / index tool)
#       - adding hddtemp
#       - adding gnome-sushi, unoconv (needed for sushi to show lo docs)
#   2015-11-10 rik: adding ubiquity (since needs tweaked in app-adjustments.sh)
#   2016-03-01 rik: minor updates for 16.04: removing clamtk-nautilus,
#       nautilus-converter, tracker*
#   2016-03-02 rik: adding glipper (gpaste seemed to hang Cinnamon 2.8?)
#   2016-04-27 rik: adding: goldendict, pandoc, vim
#       - removing: artha
#   2016-05-02 rik:
#       removing:
#           - linux-firmware-nonfre: not available for xenial
#       adding:
#           - audacity
#           - gimp
#           - zim, python-appindicator
#   2016-05-04 rik: adding:
#       - fbreader
#       - inkscape
#       - scribus
#   2016-07-28 rik: mtpfs, mtp-tools, sound-juicer, brasero additions
#   2016-08-22 rik: inotify-tools, wasta-ibus-xkb
#   2016-09-30 rik: adding "booketimposer" to replace pdfbklt
#       - removing gnome-sushi/unoconv since seems confusing for some
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
echo "*** Script Entry: app-installs.sh"
echo
# Setup Diretory for later reference
DIR=/usr/share/wasta-core

# if 'auto' parameter passed, run non-interactively
if [ "$1" == "auto" ];
then
    AUTO="auto"
    
    # needed for apt-get
    YES="--yes"
    
    # needed for gdebi
    INTERACTIVE="-n"
else
    AUTO=""
    YES=""
    INTERACTIVE=""
fi

# ------------------------------------------------------------------------------
# Configure sources and update settings and do update
# ------------------------------------------------------------------------------
echo
echo "*** Making adjustments to software repository sources"
echo

APT_SOURCES=/etc/apt/sources.list

if ! [ -e $APT_SOURCES.wasta ];
then
    APT_SOURCES=/etc/apt/sources.list
    APT_SOURCES_D=/etc/apt/sources.list.d
else
    # wasta-offline active: adjust apt file locations
    echo
    echo "*** wasta-offline active, applying repository adjustments to /etc/apt/sources.list.wasta"
    echo
    APT_SOURCES=/etc/apt/sources.list.wasta
    if [ -e /etc/apt/sources.list.d ];
    then
        echo
        echo "*** wasta-offline 'offline and internet' mode detected"
        echo
        # wasta-offline "offline and internet mode": no change to sources.list.d
        APT_SOURCES_D=/etc/apt/sources.list.d
    else
        echo
        echo "*** wasta-offline 'offline only' mode detected"
        echo
        # wasta-offline "offline only mode": change to sources.list.d location
        APT_SOURCES_D=/etc/apt/sources.list.d.wasta
    fi
fi

# first backup $APT_SOURCES in case something goes wrong
# delete $APT_SOURCES.save if older than 30 days
find /etc/apt  -maxdepth 1 -mtime +30 -iwholename $APT_SOURCES.save -exec rm {} \;

if ! [ -e $APT_SOURCES.save ];
then
    cp $APT_SOURCES $APT_SOURCES.save
fi

# FYI: repository signature keys added in the postinst!

# Add libreoffice 4.4 ppa
#if ! [ -e $APT_SOURCES_D/libreoffice-libreoffice-4-4-trusty.list ];
#then
#    echo
#    echo "*** Adding LibreOffice 4.4 PPA"
#    echo
#    echo "deb http://ppa.launchpad.net/libreoffice/libreoffice-4-4/ubuntu trusty main" | \
#        tee -a $APT_SOURCES_D/libreoffice-libreoffice-4-4-trusty.list
#    echo "# deb-src http://ppa.launchpad.net/libreoffice/libreoffice-4-4/ubuntu trusty main" | \
#        tee -a $APT_SOURCES_D/libreoffice-libreoffice-4-4-trusty.list

#    echo
#    echo "*** Removing LibreOffice 4.2 and 4.3 PPAs"
#    echo
#    rm -f $APT_SOURCES_D/libreoffice-libreoffice-4-3*
#    rm -f $APT_SOURCES_D/libreoffice-libreoffice-4-2*
#fi

apt-get update

    LASTERRORLEVEL=$?
    if [ "$LASTERRORLEVEL" -ne "0" ];
    then
        if [ "$AUTO" ];
        then
            echo
            echo "*** ERROR: apt-get command failed. You may want to re-run!"
            echo
        else
            echo
            echo "     --------------------------------------------------------"
            echo "     'APT' Error During Update / Installation"
            echo "     --------------------------------------------------------"
            echo
            echo "     An error was encountered with the last 'apt' command."
            echo "     You should close this script and re-start it, or"
            echo "     correct the error manually before proceeding."
            echo
            read -p "     Press any key to proceed..."
            echo
        fi
    fi

# ------------------------------------------------------------------------------
# Upgrade ALL
# ------------------------------------------------------------------------------

echo
echo "*** Install All Updates"
echo

apt-get $YES dist-upgrade

    LASTERRORLEVEL=$?
    if [ "$LASTERRORLEVEL" -ne "0" ];
    then
        if [ "$AUTO" ];
        then
            echo
            echo "*** ERROR: apt-get command failed. You may want to re-run!"
            echo
        else
            echo
            echo "     --------------------------------------------------------"
            echo "     'APT' Error During Update / Installation"
            echo "     --------------------------------------------------------"
            echo
            echo "     An error was encountered with the last 'apt' command."
            echo "     You should close this script and re-start it, or"
            echo "     correct the error manually before proceeding."
            echo
            read -p "     Press any key to proceed..."
            echo
        fi
    fi

# ------------------------------------------------------------------------------
# Standard package installs for all systems
# ------------------------------------------------------------------------------

echo
echo "*** Standard Installs"
echo

# adobe-flashplugin: flash
# aisleriot: solitare game
# apt-rdepends: reverse dependency lookup
# apt-xapian-index: for synpatic indexing
# audacity: audio editing
# asunder: cd ripper
# bookletimposer: pdf booklet / imposition tool
# brasero: CD/DVD burner
# btrfs-tools: filesystem utilities
# cheese: webcam recorder, picture taker
# cifs-utils: "common internet filesystem utils" for fileshare utilities, etc.
# clamtk, clamtk-nautilus: GUI for clamav antivirus tool
# classicmenu-indicator: categorized app menu for unity
# dconf-cli, dconf-tools: gives tools for making settings adjustments
# debconf-utils: needed for debconf-get-selections, etc. for debconf configure
# diodon: clipboard manager
# dos2unix: convert line endings of text files to / from windows to unix
# exfat-fuse, exfat-utils: compatibility for exfat formatted disks
# extundelete: terminal utility to restore deleted files
# fbreader: e-book reader
# font-manager: GUI for managing fonts
# fonts-crosextra-caladea: metrically compatible with "Cambria"
# fonts-crosextra-carlito: metrically compatible with "Calibri"
# fonts-sil-*: standard SIL fonts
# gcolor3: color picker
# gdebi: graphical .deb installer
# gimp: advanced graphics editor
# git: command-line git
# goldendict: more advanced dictionary/thesaurus tool than artha
# gnome-clocks: multi-timezone clocks, timers, alarms
# gnome-font-viewer: better than "font-manager" for just viewing a font file.
# gnome-nettool: network tool GUI (traceroute, lookup, etc)
# gnome-search-tool: more in-depth search than nemo gives
# gparted: partition manager
# grsync: GUI rsync tool
# gufw: GUI for "uncomplicated firewall"
# hardinfo: system profiler
# hddtemp: harddrive temp checker
# htop: process browser
# httrack: website download utility
# imagemagick: terminal utilty for image resizing, etc. (needed for nemo
#   image resize action)
# inkscape: vector graphics editor
# inotify-tools: terminal utility to watch for file changes
# iperf: terminal utility for network bandwidth measuring
# keepassx: password manager
# klavaro: typing tutor
# kmfl-keyboard-ipa: ipa keyboard for kmfl
# lame: MP3 encoder
# libdvd-pkg: enables DVD playback (downloads and installs libdvdcss2)
# libreoffice-base
# libreoffice-sdbc-hsqldb: db backend for LO base
# libreoffice-style-tango: color icon set (more usable than 14.04 "human")
# libtext-pdf-perl: provides pdfbklt (make A5 booklet from pdf)
# meld: graphical text file compare utility
# mkusb-nox: teminal usb creator (15.10 issue with usb-creator-gtk)
# modem-manager-gui: Check balance, top up, check signal strength, etc.
# mtpfs, mtp-tools: media-transfer-protocol tools: needed for smartphones
# myspell-en-gb: spell checker for English (UK): needed for Libre Office
# nautilus-compare: nautilus integration with meld
# openshot-qt: video editor (-qt is the 2.x series)
#   openshot-doc: documentation for openshot
#   frei0r-plugins: visual effects for openshot
# pandoc: general markup converter
# pinta: MS Paint alternative: more simple for new users than gimp
# python-appindicator: needed for zim app-indicator (maybe others?)
# rhythmbox: music manager
# scribus: desktop publisher
# shotwell: photo editor / manager (can edit single files easily)
# simplescreenrecorder: 
# skype
#    libpulse0:i386: needed for skype sound to work, not listed as dependency
# soundconverter: convert audio formats
# sound-juicer: rip CDs
# ssh: remote access
# software-center: re-adding until gnome-software does what we need it
#   to do.
# synaptic: more advanced package manager
# testdisk: photorec tool for recovery of deleted files
# traceroute: terminal utility
# ttf-mscorefonts-installer: installs standard Microsoft fonts
# ubiquity ubiquity-slideshow-ubuntu:
#   add here since needs tweaking for ethiopia (in app-adjustments.sh)
# ubuntu-restricted-extras: mp3, flash, etc.
# ubuntu-wallpapers-*: wallpaper collections
# unity-tweak-tool: unity desktop settings tweak tool
#   - NOT including because pulls in unity-webapps-tool which brings in
#     amazon, etc.
# vim: command-line text editor
# vlc: play any audio or video files
# wasta-backup: GUI for rdiff-backup
# wasta-ibus-xkb: setup of xkb keyboards for ibus input method menu
# wasta-menus: applicationmenu limiting system
# wasta-offline: offline updates and installs
# wasta-remastersys: create ISO of system
# wasta-resources-core: wasta-core documentation and resources
# wavemon: terminal utility for wireless network diagonstics
# xmlstarlet: terminal utility for reading / writing to xml files
# xsltproc: xslt, xml conversion program
# xul-ext-lightning: Thunderbird Lightning (calendar) Extension
# youtube-dl: terminal utility for youtube / video downloads
# zim, python-appindicator:

apt-get $YES install \
    adobe-flashplugin \
    aisleriot \
    apt-rdepends \
    apt-xapian-index \
    audacity \
    asunder \
    bookletimposer \
    brasero \
    btrfs-tools \
    cheese \
    cifs-utils \
    clamtk clamtk-nautilus \
    classicmenu-indicator \
    dconf-cli \
        dconf-tools \
    debconf-utils \
    diodon \
    dos2unix \
    exfat-fuse \
        exfat-utils \
    extundelete \
    fbreader \
    font-manager \
    fonts-crosextra-caladea \
    fonts-crosextra-carlito \
    fonts-sil-andika \
        fonts-sil-andika-compact \
        fonts-sil-charissil \
        fonts-sil-doulossil \
        fonts-sil-gentiumplus \
        fonts-sil-gentiumpluscompact \
    gcolor3 \
    gdebi \
    gimp \
    git \
    goldendict \
        goldendict-wordnet \
    gnome-clocks \
    gnome-font-viewer \
    gnome-nettool \
    gnome-search-tool \
    gparted \
    grsync \
    gufw \
    hardinfo \
    hddtemp \
    htop \
    httrack \
    kmfl-keyboard-ipa \
    imagemagick \
    inkscape \
    inotify-tools \
    iperf \
    keepassx \
    klavaro \
    lame \
    libdvd-pkg \
    libreoffice-base \
    libreoffice-sdbc-hsqldb \
    libreoffice-style-tango \
    libtext-pdf-perl \
    meld \
    mkusb-nox \
    modem-manager-gui \
    mtpfs mtp-tools \
    nautilus-compare \
    openshot-qt frei0r-plugins \
    pandoc \
    pinta \
    python-appindicator \
    rhythmbox \
    scribus scribus-doc scribus-template \
    shotwell \
    simplescreenrecorder \
    skype \
        libpulse0:i386\
    soundconverter \
    sound-juicer \
    ssh \
    software-center \
    synaptic \
    testdisk \
    traceroute \
    ttf-mscorefonts-installer \
    ubiquity ubiquity-slideshow-ubuntu \
    ubuntu-restricted-extras \
    ubuntu-wallpapers-karmic \
    ubuntu-wallpapers-utopic \
    ubuntu-wallpapers-vivid \
    ubuntu-wallpapers-wily \
    vim \
    vlc \
    wasta-backup \
    wasta-ibus-xkb \
    wasta-menus \
    wasta-offline \
    wasta-remastersys \
    wasta-resources-core \
    wavemon \
    xmlstarlet \
    xsltproc \
    xul-ext-lightning \
    youtube-dl \
    zim

    LASTERRORLEVEL=$?
    if [ "$LASTERRORLEVEL" -ne "0" ];
    then
        if [ "$AUTO" ];
        then
            echo
            echo "*** ERROR: apt-get command failed. You may want to re-run!"
            echo
        else
            echo
            echo "     --------------------------------------------------------"
            echo "     'APT' Error During Update / Installation"
            echo "     --------------------------------------------------------"
            echo
            echo "     An error was encountered with the last 'apt' command."
            echo "     You should close this script and re-start it, or"
            echo "     correct the error manually before proceeding."
            echo
            read -p "     Press any key to proceed..."
            echo
        fi
    fi

# ------------------------------------------------------------------------------
# Language Support Files: install
# -----------------------------------------------------------------------------
echo
echo "*** Installing Language Support Files"
echo

SYSTEM_LANG=$(locale | grep LANG= | cut -d= -f2 | cut -d_ -f1)
INSTALL_APPS=$(check-language-support -l $SYSTEM_LANG)

apt-get $YES install $INSTALL_APPS

# ------------------------------------------------------------------------------
# 32-bit installs if needed for 64 bit machines
# ------------------------------------------------------------------------------
# get machine architecture so will either install 64bit or 32bit
MACHINE_TYPE=$(uname -m)

if [ $MACHINE_TYPE == 'x86_64' ];
then
    echo
    echo "*** 64-bit detected. Installing packages for 32-bit apps"
    echo
    # packages needed for skype, etc. to be able to match gtk theme
    # always assume yes
    apt-get --yes install gtk2-engines-murrine:i386 gtk2-engines-pixbuf:i386
    LASTERRORLEVEL=$?
    if [ "$LASTERRORLEVEL" -ne "0" ];
    then
        if [ "$AUTO" ];
        then
            echo
            echo "*** ERROR: apt-get command failed. You may want to re-run!"
            echo
        else
            echo
            echo "     --------------------------------------------------------"
            echo "     'APT' Error During Update / Installation"
            echo "     --------------------------------------------------------"
            echo
            echo "     An error was encountered with the last 'apt' command."
            echo "     You should close this script and re-start it, or"
            echo "     correct the error manually before proceeding."
            echo
            read -p "     Press any key to proceed..."
            echo
        fi
    fi
fi

# ------------------------------------------------------------------------------
# Reconfigure libdvd-pkg to get libdvdcss2 installed
# ------------------------------------------------------------------------------
# during the install of libdvd-pkg it can't in turn install libdvdcss2 since
#   another dpkg process is already active, so need to do it again
dpkg-reconfigure libdvd-pkg

# ------------------------------------------------------------------------------
# Clean up apt cache
# ------------------------------------------------------------------------------
# not doing since we may want those packages to
#apt-get autoremove
#apt-get autoclean

echo
echo "*** Script Exit: app-installs.sh"
echo

exit 0
