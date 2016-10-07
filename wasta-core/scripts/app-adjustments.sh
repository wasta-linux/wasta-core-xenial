#!/bin/bash

# ==============================================================================
# wasta-core: app-adjustments.sh
#
# 2015-10-25 rik: initial script - pulled from other scripts
# 2015-11-06 rik: making gdebi default for deb files
#   - chromium app launcher processing
#   - gpaste, gcolor2 icon changes to use others available in Moka icon theme
# 2015-11-10 rik: ubiquity apt-setup: commenting out replace of sources.list:
#     we want to just go with what live-cd has, as often minor countries mirror
#     not very good: instead stick to main repo, user can later change if they
#     want.
#   - casper: added fix here instead of in postinst
# 2015-11-11 rik: removing ubiquity tweak: problem was with PinguyBuilder and
#     is now fixed in wasta-remastersys
#   - remove PinguyBuilder processing, add wasta-remastersys processing
# 2015-11-13 rik: fixing syntax of variables for wasta-remastersys.conf
# 2015-11-21 rik: updating wasta-remastersys.conf location
# 2016-04-27 rik: goldendict config updates (for http to https) and comment fix
#   - artha: removing tweaks (no longer installed in Wasta-Linux by default)
#   - wasta-remastersys: fixing splash screen background location
#   - defaults.list syntax corrections (do all at once instead of looping)
# 2016-05-04 rik: goldendict point to correct hunspell dictionary location
#   - webbrowser-app: hiding (brought in by unity-tweak-tool)
#   - meld: changing to 'Utility' so no 'Development' category by default
# 2016-05-09 rik: reverting gcolor2, gnome-search-tool icons as humanity
#   doesn't support gpick and catfish, so then would be empty (I had previously
#   put in these manually into hicolor, but then will prevent install of gpick
#   or catfish!)
# 2016-05-10 rik: moving to gcolor3, so taking out gcolor2 icon fix
# 2016-07-19 rik: adding xfce compatibility
#  - hiding ubuntu-amazon-default
#  - classicmenu-indicator: only show in unity
# 2016-08-22 rik: org.gnome.font-viewer: won't launch in 16.04 unless comment
#   out DBus line from desktop file.  Fixed for yakkety, not sure if will
#   backport to xenial.
# 2016-09-14 rik: adding wesay to "Education" category (removing from "Office")
# 2016-09-30 rik: removing chromium-app-launcher customization: Google has
#   deprecated it.
# 2016-10-07 rik: ubiquity: set to not show if found
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
echo "*** Script Entry: app-adjustments.sh"
echo

# Setup Diretory for later reference
DIR=/usr/share/wasta-core

# if 'auto' parameter passed, run non-interactively
if [ "$1" == "auto" ];
then
    AUTO="auto"
else
    AUTO=""
fi

# ------------------------------------------------------------------------------
# FIRST: Gnome Application Menu Cleanup
# ------------------------------------------------------------------------------
# backup gnome-applications.menu first (don't do time check: always static original to keep
if ! [ -e /etc/xdg/menus/gnome-applications.menu.save ];
then
    cp /etc/xdg/menus/gnome-applications.menu \
       /etc/xdg/menus/gnome-applications.menu.save
fi

# Delete 'Sundry' Category:
#   items here are duplicated in Accessories or System Tools so clean up to
#   just use those 2 categories: why do we want another category??
# Keeping for reference in case need to modify xml in the future:
#       xmlstarlet ed --inplace --delete '/Menu/Menu[Name="Sundry"]' \
#           /etc/xdg/menus/gnome-applications.menu

# get rid of gnome-applications.menu hard-coded category settings
#   (let desktops do that!!!)
sed -i -e "\@<Filename>@d" /etc/xdg/menus/gnome-applications.menu

# ------------------------------------------------------------------------------
# SECOND: Clean up individual applications that are in bad places
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# baobab
# ------------------------------------------------------------------------------
# Add to "Accessories" category (by removing from X-GNOME-Utilities)
if [ -e /usr/share/applications/org.gnome.baobab.desktop ];
then
    desktop-file-edit ---remove-category=X-GNOME-Utilities \
        /usr/share/applications/org.gnome.baobab.desktop
fi

# ------------------------------------------------------------------------------
# casper: "live session" fixes
# ------------------------------------------------------------------------------
# live session userid coded to 999, but this conflicts with vbox user ids
# change to 990
#if [ -e /usr/share/initramfs-tools/scripts/casper-bottom/25adduser ];
#then
#    sed -i -e 's@user-uid [0-9]*@user-uid 990@' \
#        /usr/share/initramfs-tools/scripts/casper-bottom/25adduser
#fi
# FIXED in wasta-remastersys? not needed xenial?

# ------------------------------------------------------------------------------
# checkbox-converged
# ------------------------------------------------------------------------------
# hide if found
if [ -e /usr/share/applications/checkbox-converged.desktop ];
then
    # sending output to /dev/null because desktop file has errors from
    #   ubuntu that I am not fixing (such as using a non-quoted "$" in exec)
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/checkbox-converged.desktop >/dev/null 2>&1 || true;
fi

# ------------------------------------------------------------------------------
# cinnamon-settings-users
# ------------------------------------------------------------------------------
# show and add to XFCE Settings Manager
if [ -e /usr/share/applications/cinnamon-settings-users.desktop ];
then
    desktop-file-edit --add-only-show-in=XFCE \
        /usr/share/applications/cinnamon-settings-users.desktop

    desktop-file-edit --add-category=X-XFCE-SettingsDialog \
        /usr/share/applications/cinnamon-settings-users.desktop

    desktop-file-edit --add-category=X-XFCE-SystemSettings \
        /usr/share/applications/cinnamon-settings-users.desktop
fi

# ------------------------------------------------------------------------------
# clamtk-gnome
# ------------------------------------------------------------------------------
# hide if found since clamtk already in main menu
if [ -e /usr/share/applications/clamtk-gnome.desktop ];
then
    # sending output to /dev/null because desktop file has errors from
    #   ubuntu that I am not fixing (such as using a non-quoted "$" in exec)
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/clamtk-gnome.desktop >/dev/null 2>&1 || true;
fi

# ------------------------------------------------------------------------------
# classicmenu-indicator
# ------------------------------------------------------------------------------
#classicmenu-indicator: only show in unity
if [ -x /usr/bin/classicmenu-indicator ];
then
    desktop-file-edit --add-only-show-in=Unity \
        /usr/share/applications/classicmenu-indicator.desktop
fi

# ------------------------------------------------------------------------------
# evince (pdf viewer)
# ------------------------------------------------------------------------------
if [ -e /usr/share/applications/evince.desktop ];
then
    # remove from "Graphics": already in "Office"
    desktop-file-edit --remove-category=Graphics \
        /usr/share/applications/evince.desktop
fi

# ------------------------------------------------------------------------------
# file-roller
# ------------------------------------------------------------------------------
if [ -e /usr/share/applications/file-roller.desktop ];
then
    # hide from menu: only needed on nemo/nautilus right click
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/file-roller.desktop
fi

# ------------------------------------------------------------------------------
# font-manager
# ------------------------------------------------------------------------------
# change to "Utility" ("Accessories"): default is "Graphics"
if [ -e /usr/share/applications/font-manager.desktop ];
then
    desktop-file-edit --add-category=Utility \
        /usr/share/applications/font-manager.desktop

    desktop-file-edit --remove-category=Graphics \
        /usr/share/applications/font-manager.desktop
fi

# ------------------------------------------------------------------------------
# gimp
# ------------------------------------------------------------------------------
if [ -x /usr/bin/gimp ];
then
    # add "Advanced" to comment
    desktop-file-edit --set-comment="Advanced image and photo editor" \
        /usr/share/applications/gimp.desktop
fi

# ------------------------------------------------------------------------------
# goldendict
# ------------------------------------------------------------------------------
if [ -x /usr/bin/goldendict ];
then
    # for all users, correct http to https for wikipedia and wiktionary sources
    #   (suppress errors if no user has initialized goldendict)
    sed -i -e "s@http://\(.*\).wikipedia.org@https://\1.wikipedia.org@" \
        /home/*/.goldendict/config >/dev/null 2>&1
    sed -i -e "s@http://\(.*\).wiktionary.org@https://\1.wiktionary.org@" \
        /home/*/.goldendict/config >/dev/null 2>&1
    # for all users, correct hunspell dictionary path
    #   (suppress errors if no user has initialized goldendict)
    sed -i -e 's@\(hunspell dictionariesPath\).*@\1="/usr/share/hunspell"/>@' \
        /home/*/.goldendict/config >/dev/null 2>&1

    # fix comment
    desktop-file-edit --set-comment="Dictionary / Thesaurus tool" \
        /usr/share/applications/goldendict.desktop
fi

# ------------------------------------------------------------------------------
# gnome-font-viewer
# ------------------------------------------------------------------------------
# hide because font-manager better.  User will only need
#   gnome-font-viewer when double-clicking a font file.  Font-Manager installed
#   by install-default-apps.sh
if [ -e /usr/share/applications/org.gnome.font-viewer.desktop ] && [ -e /usr/share/applications/font-manager.desktop ];
then
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/org.gnome.font-viewer.desktop
fi

# rik: 16.04 issue launching gnome-font-viewer: see this report:
# http://askubuntu.com/questions/804639/font-viewer-not-running-in-ubuntu-16-04
# "solution" is to comment out DBus line.  This should be fixed in future
# versions but not sure if it will get backported to xenial or not
if [ -e /usr/share/applications/org.gnome.font-viewer.desktop ];
then
    sed -i -e 's@^\(DBus\)@#\1@' \
        /usr/share/applications/org.gnome.font-viewer.desktop
fi

# ------------------------------------------------------------------------------
# gnome-power-statistics
# ------------------------------------------------------------------------------
# always show
if [ -e /usr/share/applications/gnome-power-statistics.desktop ];
then
    desktop-file-edit --remove-key=OnlyShowIn \
        /usr/share/applications/gnome-power-statistics.desktop
fi

# ------------------------------------------------------------------------------
# gnome-screenshot
# ------------------------------------------------------------------------------
# Add to "Accessories" category (by removing from X-GNOME-Utilities)
if [ -e /usr/share/applications/org.gnome.Screenshot.desktop ];
then
    desktop-file-edit ---remove-category=X-GNOME-Utilities \
        /usr/share/applications/org.gnome.Screenshot.desktop
fi

# ------------------------------------------------------------------------------
# gnome-search-tool
# ------------------------------------------------------------------------------
# add keyword "find" to comments for main menu search help
if [ -e /usr/share/applications/gnome-search-tool.desktop ];
then
    desktop-file-edit --set-comment="Find or Locate documents and folders on this computer by name or content" \
        /usr/share/applications/gnome-search-tool.desktop

    # default icon of "system-search" seems overridden by low-res icon, change
    # to catfish instead
    # 16.04: reverting hack, as some icons sets don't have catfish
    desktop-file-edit --set-icon=system-search \
        /usr/share/applications/gnome-search-tool.desktop
fi

# ------------------------------------------------------------------------------
# ibus-setup
# ------------------------------------------------------------------------------
# add to XFCE Settings Manager
if [ -e /usr/share/applications/ibus-setup.desktop ];
then
    # Sending any output to null (don't want to worry user)
    desktop-file-edit --add-category=X-XFCE-SettingsDialog \
        /usr/share/applications/ibus-setup.desktop > /dev/null 2>&1 || true;

    # Sending any output to null (don't want to worry user)
    desktop-file-edit --add-category=X-XFCE-HardwareSettings \
        /usr/share/applications/ibus-setup.desktop > /dev/null 2>&1 || true;
fi

# ------------------------------------------------------------------------------
# image-magick
# ------------------------------------------------------------------------------
# we want command-line only
if [ -e /usr/share/applications/display-im6.desktop ];
then
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/display-im6.desktop
fi

if [ -e /usr/share/applications/display-im6.q16.desktop ];
then
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/display-im6.q16.desktop
fi

# ------------------------------------------------------------------------------
# input-method
# ------------------------------------------------------------------------------
# hide if found (we use ibus as default input method)
if [ -e /usr/share/applications/im-config.desktop ];
then
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/im-config.desktop
fi

# ------------------------------------------------------------------------------
# libreoffice-math
# ------------------------------------------------------------------------------
# remove from 'science and education' to reduce number of categories
if [ -e /usr/share/applications/libreoffice-math.desktop ];
then
    desktop-file-edit ---remove-category=Science \
        /usr/share/applications/libreoffice-math.desktop

    desktop-file-edit ---remove-category=Education \
        /usr/share/applications/libreoffice-math.desktop
fi

# ------------------------------------------------------------------------------
# meld
# ------------------------------------------------------------------------------
# change to "Utility" ("Accessories"): default is "Development" (only item
#   in that category, so we are trying to not have "Programming" by default)
if [ -e /usr/share/applications/meld.desktop ];
then
    desktop-file-edit --add-category=Utility \
        /usr/share/applications/meld.desktop

    desktop-file-edit --remove-category=Development \
        /usr/share/applications/meld.desktop
fi

# ------------------------------------------------------------------------------
# modem-manager-gui
# ------------------------------------------------------------------------------
# change "Categories" to "Utility" ("Accessories"): default is "System

if [ -e /usr/share/applications/modem-manager-gui.desktop ];
then
    desktop-file-edit --add-category=Network \
        /usr/share/applications/modem-manager-gui.desktop

    desktop-file-edit --remove-category=System \
        /usr/share/applications/modem-manager-gui.desktop

    # show in all desktops
    desktop-file-edit --remove-key=OnlyShowIn \
        /usr/share/applications/modem-manager-gui.desktop
    
    # modify comment so easier to find on search
    desktop-file-edit --set-comment="3G USB Modem Manager" \
        /usr/share/applications/modem-manager-gui.desktop
fi

# ------------------------------------------------------------------------------
# onboard (on-screen keyboard)
# ------------------------------------------------------------------------------
if [ -e /usr/share/applications/onboard.desktop ];
then
    # remove from "Accessibility" (only 2 items there): already in "Utility"
    desktop-file-edit --remove-category=Accessibility \
        /usr/share/applications/onboard.desktop
fi

# ------------------------------------------------------------------------------
# OpenJDK Policy Tool
# ------------------------------------------------------------------------------
if [ -e /usr/share/applications/openjdk-7-policytool.desktop ];
then
    # Hide GUI from start menu
    # Send output to /dev/null since there are warnings generated
    #   by the comment fields
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/openjdk-7-policytool.desktop  >/dev/null 2>&1 || true;
fi

if [ -e /usr/share/applications/openjdk-8-policytool.desktop ];
then
    # Hide GUI from start menu
    # Send output to /dev/null since there are warnings generated
    #   by the comment fields
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/openjdk-8-policytool.desktop  >/dev/null 2>&1 || true;
fi

# ------------------------------------------------------------------------------
# orca (screen reader)
# ------------------------------------------------------------------------------
if [ -e /usr/share/applications/orca.desktop ];
then
    # remove from "Accessibility" (only 2 items there): already in "Utility"
    desktop-file-edit --remove-category=Accessibility \
        /usr/share/applications/orca.desktop
fi

# ------------------------------------------------------------------------------
# PulseAudio Control
# ------------------------------------------------------------------------------
# add to XFCE Settings Manager
if [ -e /usr/share/applications/pavucontrol.desktop ];
then
    desktop-file-edit --add-category=X-XFCE-SettingsDialog \
        /usr/share/applications/pavucontrol.desktop

    desktop-file-edit --add-category=X-XFCE-HardwareSettings \
        /usr/share/applications/pavucontrol.desktop
fi

# ------------------------------------------------------------------------------
# software-properties-gnome,gtk
# ------------------------------------------------------------------------------
if [ -e /usr/share/applications/software-properties-gnome.desktop ];
then
    # rename to "Software Settings" or else get confused with "Software Updates"
    desktop-file-edit --set-name="Software Settings" \
        /usr/share/applications/software-properties-gnome.desktop
fi

if [ -e /usr/share/applications/software-properties-gtk.desktop ];
then
    # rename to "Software Settings" or else get confused with "Software Updates"
    desktop-file-edit --set-name="Software Settings" \
        /usr/share/applications/software-properties-gtk.desktop
fi

# ------------------------------------------------------------------------------
# ubiquity
# ------------------------------------------------------------------------------
if [ -e /usr/share/ubiquity/localechooser-apply ];
then
    # ET is hard-coded to 'am' language, regardless of what user chose
    #   remove this override: Amharic is not wanted as hardcoded language
    #   Most Ethiopians will use English
    sed -i -e '\@deflang=am@d' /usr/share/ubiquity/localechooser-apply
fi

# always hide (this comes from ubiquity-frontend-gtk, which we want installed
#   so it doesn't have to be downloaded by wasta-remastersys)
if [ -e /usr/share/applications/ubiquity.desktop ];
then
    # sending output to /dev/null because desktop file has errors from
    #   ubuntu that I am not fixing (invalid use of "'" in Exec line)
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/ubiquity.desktop >/dev/null 2>&1 || true;
fi

# ------------------------------------------------------------------------------
# ubuntu-amazon-default
# ------------------------------------------------------------------------------
# always hide
if [ -e /usr/share/applications/vim.desktop ];
then
    # hide from main menu (terminal only)
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/vim.desktop
fi

# ------------------------------------------------------------------------------
# unity-lens-photos
# ------------------------------------------------------------------------------
#unity-lens-photos: only show in unity
if [ -e /usr/share/applications/unity-lens-photos.desktop ];
then
    desktop-file-edit --add-only-show-in=Unity \
        /usr/share/applications/unity-lens-photos.desktop
fi

# ------------------------------------------------------------------------------
# ubuntu-amazon-default
# ------------------------------------------------------------------------------
if [ -e /usr/share/applications/ubuntu-amazon-default.desktop ];
then
    # hide from main menu
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/ubuntu-amazon-default.desktop
fi

# ------------------------------------------------------------------------------
# wasta-remastersys
# ------------------------------------------------------------------------------
WASTA_REMASTERSYS_CONF=/etc/wasta-remastersys/wasta-remastersys.conf
if [ -e "$WASTA_REMASTERSYS_CONF" ];
then
    # change to wasta-linux splash screen
    sed -i -e 's@SPLASHPNG=.*@SPLASHPNG="/usr/share/wasta-core/resources/wasta-linux-vga.png"@' \
        "$WASTA_REMASTERSYS_CONF"
    
    # set default CD Label and ISO name
    WASTA_ID="$(sed -n "\@^ID=@s@^ID=@@p" /etc/wasta-release)"
    WASTA_VERSION="$(sed -n "\@^VERSION=@s@^VERSION=@@p" /etc/wasta-release)"
    ARCH=$(uname -m)
    if [ $ARCH == 'x86_64' ];
    then
        WASTA_ARCH="64bit"
    else
        WASTA_ARCH="32bit"
    fi
    WASTA_DATE=$(date +%F)
    
    sed -i -e "s@LIVECDLABEL=.*@LIVECDLABEL=\"$WASTA_ID $WASTA_VERSION $WASTA_ARCH\"@" \
           -e "s@CUSTOMISO=.*@CUSTOMISO=\"$WASTA_ID-$WASTA_VERSION-$WASTA_ARCH-$WASTA_DATE.iso\"@" \
        "$WASTA_REMASTERSYS_CONF"
fi

# ------------------------------------------------------------------------------
# web2py
# ------------------------------------------------------------------------------
# hide if found (Paratext installs but don't want to clutter menu)
if [ -e /usr/share/applications/web2py.desktop ];
then
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/web2py.desktop
fi

# ------------------------------------------------------------------------------
# webbrowser-app
# ------------------------------------------------------------------------------
# hide if found (unity-tweak-tool installs it)
if [ -e /usr/share/applications/webbrowser-app.desktop ];
then
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/webbrowser-app.desktop
fi

# ------------------------------------------------------------------------------
# wesay
# ------------------------------------------------------------------------------
# change to "Education": default is "Office" (other SIL apps all to Education)
if [ -e /usr/share/applications/sil-wesay.desktop ];
then
    desktop-file-edit --add-category=Education \
        /usr/share/applications/sil-wesay.desktop

    desktop-file-edit --remove-category=Office \
        /usr/share/applications/sil-wesay.desktop
fi

if [ -e /usr/share/applications/sil-wesay-config.desktop ];
then
    desktop-file-edit --add-category=Education \
        /usr/share/applications/sil-wesay-config.desktop

    desktop-file-edit --remove-category=Office \
        /usr/share/applications/sil-wesay-config.desktop
fi

# ------------------------------------------------------------------------------
# xdiagnose
# ------------------------------------------------------------------------------
# hide if found
if [ -e /usr/share/applications/xdiagnose.desktop ];
then
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/xdiagnose.desktop
fi

# ------------------------------------------------------------------------------
# xfce4-appfinder
# ------------------------------------------------------------------------------
# hide from all desktops even from xfce (only used via shortcut)
# if [ -e /usr/share/applications/xfce4-appfinder.desktop ];
# then
#     desktop-file-edit --set-key=NoDisplay --set-value=true \
#         /usr/share/applications/xfce4-appfinder.desktop
# fi

# ------------------------------------------------------------------------------
# xfce4-power-manager-settings
# ------------------------------------------------------------------------------
# Only show in xfce
if [ -e /usr/share/applications/xfce4-power-manager-settings.desktop ];
then
    desktop-file-edit --remove-key=NotShowIn \
        /usr/share/applications/xfce4-power-manager-settings.desktop

    desktop-file-edit --add-only-show-in=XFCE \
        /usr/share/applications/xfce4-power-manager-settings.desktop
fi

# ------------------------------------------------------------------------------
# xfce4-xscreenshooter
# ------------------------------------------------------------------------------
# hide all desktops even from xfce (use gnome instead)
if [ -e /usr/share/applications/xfce4-xscreenshooter.desktop ];
then
    desktop-file-edit --set-key=NoDisplay --set-value=true \
        /usr/share/applications/xfce4-xscreenshooter.desktop
fi

# ------------------------------------------------------------------------------
# zim
# ------------------------------------------------------------------------------
#if [ -x /usr/bin/zim ];
#then
    # TODO:if no current .config/zim then copy it from /etc/skel
    # this is needed to enable trayicon plugin by default
#fi

# ------------------------------------------------------------------------------
# Default Application Fixes: ??? better command to do this ???
# ------------------------------------------------------------------------------

echo
echo "*** Adjusting default applications"
echo

# preferred way to set defaults is with xdg-mime (but its man says that the
#   default function shouldn't be used as root?)

# rik: to find "filetype" for file: xdg-mime query filetype <filename>

sed -i \
    -e 's@\(audio.*\)=.*@\1=vlc.desktop@' \
    -e 's@\(video.*\)=.*@\1=vlc.desktop@' \
    -e 's@totem.desktop@vlc.desktop@' \
    -e 's@\(text/plain\)=.*@\1=org.gnome.gedit.desktop@' \
    -e 's@\(application/x-deb\)=.*@\1=gdebi.desktop@' \
    -e 's@\(application/x-debian-package\)=.*@\1=gdebi.desktop@' \
    -e 's@\(text/xml\)=.*@\1=org.gnome.gedit.desktop@' \
    -e '$a application/x-extension-htm=firefox.desktop' \
    -e '$a application/x-font-ttf=org.gnome.font-viewer.desktop' \
    -e '$a application/x-shellscript=org.gnome.gedit.desktop' \
    -e '\@application/x-extension-htm=@d' \
    -e '\@application/x-font-ttf=@d' \
    -e '\@application/x-shellscript=@d' \
    /etc/gnome/defaults.list \
    /usr/share/applications/defaults.list \
    /usr/share/gnome/applications/defaults.list \

# ------------------------------------------------------------------------------
# Finished
# ------------------------------------------------------------------------------
echo
echo "*** Script Exit: app-adjustments.sh"
echo

exit 0
