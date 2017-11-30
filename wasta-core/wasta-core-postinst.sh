#!/bin/bash

# ==============================================================================
# wasta-core: wasta-core-postinst.sh
#
#   This script is automatically run by the postinst configure step on
#       installation of wasta-core-xenial.  It can be manually re-run, but is
#       only intended to be run at package installation.
#
#   2015-10-09 rik: initial script for wasta-core-xenial
#   2015-11-03 rik: correcting sed on 25adduser to change uid to 990
#       - adding wasta-text plymouth theme and settings as text.plymouth
#   2015-12-25 rik: initial xenial release - removed extension specific logic
#       as those have been refactored out to wasta-gnome-ext-3-18
#   2016-02-21 rik: refactored to remove any gnome-shell specific logic
#   2016-03-01 rik: removing ubuntu 'proposed' repository: not needed to get
#       cinnamon 2.8 anymore (has been moved to universe)
#   2016-07-19 rik: enabling ubuntu repositories with "deb .*" instead of
#       "deb.*" so that deb-src repos not all automatically enabled
#   2016-08-22 rik: legacy cleanup: removing 'at' jobs 49, 50 (were part of
#       64bit Beta ISOs)
#   2016-09-30 rik: usb_modeswitch.conf: enabling SetStorageDelay
#       - added LibreOffice 5.1 PPA
#   2016-12-13 rik: adding sil-2016.gpg key
#   2016-12-14 rik: fix "legacy cleanup" of pso in sources.list so don't
#       cause problems for the PNG users with local mirrors.
#   2017-08-28 rik: repository settings not re-activated IF #wasta detected
#       at end of repository line (indicating that some wasta process has
#       intentionally deactivated them)
#   2017-09-28 rik: only create apt.conf.d files if don't previously exist: this
#       way any user adjusted files will not be reset.
#   2017-11-30 rik: correcting sil repo insertion syntax (was wrapping series
#       name in quotes)
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
echo "*** Script Entry: wasta-core-postinst.sh"
echo

# Setup Diretory for later reference
DIR=/usr/share/wasta-core

SERIES=$(lsb_release -sc)

# ------------------------------------------------------------------------------
# Configure sources and apt settings
# ------------------------------------------------------------------------------
echo
echo "*** Making adjustments to software repository sources"
echo

APT_SOURCES=/etc/apt/sources.list

if ! [ -e $APT_SOURCES.wasta ];
then
    APT_SOURCES_D=/etc/apt/sources.list.d
else
    # wasta-offline active: adjust apt file locations
    echo
    echo "*** wasta-offline active, applying repository adjustments to /etc/apt/sources.list.wasta"
    echo
    APT_SOURCES=/etc/apt/sources.list.wasta
    if [ "$(ls -A /etc/apt/sources.list.d)" ];
    then
        echo
        echo "*** wasta-offline 'offline and internet' mode detected"
        echo
        # files inside /etc/apt/sources.list.d so it is active
        # wasta-offline "offline and internet mode": no change to sources.list.d
        APT_SOURCES_D=/etc/apt/sources.list.d
    else
        echo
        echo "*** wasta-offline 'offline only' mode detected"
        echo
        # no files inside /etc/apt/sources.list.d
        # wasta-offline "offline only mode": change to sources.list.d.wasta
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

# ensure all ubuntu repositories enabled (will ensure not commented out)
# DO NOT match any lines ending in #wasta
sed -i -e '/#wasta$/! s@.*\(deb .*ubuntu.com/ubuntu.* '$SERIES' \)@\1@' $APT_SOURCES
sed -i -e '/#wasta$/! s@.*\(deb .*ubuntu.com/ubuntu.* '$SERIES'-updates \)@\1@' $APT_SOURCES
sed -i -e '/#wasta$/! s@.*\(deb .*ubuntu.com/ubuntu.* '$SERIES'-security \)@\1@' $APT_SOURCES

# canonical.com lists include "partner" for things like skype, etc.
# DO NOT match any lines ending in #wasta
sed -i -e '/#wasta$/! s@.*\(deb .*canonical.com/ubuntu.* '$SERIES' \)@\1@' $APT_SOURCES

# legacy cleanup: PSO should NOT be in sources.list anymore (ubiquity will
#   remove when installing)
sed -i -e '\@http://packages.sil.org/ubuntu@d' $APT_SOURCES

# add SIL repository to sources.list.d
#   (otherwise ubiquity comments out when installing)
if ! [ -e $APT_SOURCES_D/packages-sil-org-$SERIES.list ];
then
    echo
    echo "*** Adding SIL Repository"
    echo

    echo "deb http://packages.sil.org/ubuntu $SERIES main" | \
        tee $APT_SOURCES_D/packages-sil-org-$SERIES.list
    echo "# deb-src http://packages.sil.org/ubuntu $SERIES main" | \
        tee -a $APT_SOURCES_D/packages-sil-org-$SERIES.list
else
    # found, but ensure PSO main ACTIVE (user could have accidentally disabled)
    # DO NOT match any lines ending in #wasta
    sed -i -e '/#wasta$/! s@.*\(deb http://packages.sil.org\)@\1@' \
        $APT_SOURCES_D/packages-sil-org-$SERIES.list
fi

# add SIL Experimental repository to sources.list.d
#   (otherwise ubiquity comments out when installing)
if ! [ -e $APT_SOURCES_D/packages-sil-org-$SERIES-experimental.list ];
then
    echo
    echo "*** Adding SIL Experimental Repository (inactive)"
    echo

    echo "# deb http://packages.sil.org/ubuntu $SERIES-experimental main" | \
        tee $APT_SOURCES_D/packages-sil-org-$SERIES-experimental.list
    echo "# deb-src http://packages.sil.org/ubuntu $SERIES-experimental main" | \
        tee -a $APT_SOURCES_D/packages-sil-org-$SERIES-experimental.list
fi

# install repository Keys (done locally since wasta-offline could be active)
echo
echo "*** Adding Repository GPG Keys"
echo
apt-key add $DIR/keys/sil.gpg
apt-key add $DIR/keys/sil-2016.gpg
apt-key add $DIR/keys/libreoffice-ppa.gpg
apt-key add $DIR/keys/wasta-linux-ppa.gpg

# add Wasta-Linux PPA
if ! [ -e $APT_SOURCES_D/wasta-linux-ubuntu-wasta-$SERIES.list ];
then
    echo
    echo "*** Adding Wasta-Linux PPA"
    echo

    echo "deb http://ppa.launchpad.net/wasta-linux/wasta/ubuntu $SERIES main" | \
        tee $APT_SOURCES_D/wasta-linux-ubuntu-wasta-$SERIES.list
    echo "# deb-src http://ppa.launchpad.net/wasta-linux/wasta/ubuntu $SERIES main" | \
        tee -a $APT_SOURCES_D/wasta-linux-ubuntu-wasta-$SERIES.list
else
    # found, but ensure Wasta-Linux PPA ACTIVE (user could have accidentally disabled)
    # DO NOT match any lines ending in #wasta
    sed -i -e '/#wasta$/! s@.*\(deb http://ppa.launchpad.net\)@\1@' \
        $APT_SOURCES_D/wasta-linux-ubuntu-wasta-$SERIES.list
fi

# add Wasta-Apps PPA
if ! [ -e $APT_SOURCES_D/wasta-linux-ubuntu-wasta-apps-$SERIES.list ];
then
    echo
    echo "*** Adding Wasta-Linux Apps PPA"
    echo

    echo "deb http://ppa.launchpad.net/wasta-linux/wasta-apps/ubuntu $SERIES main" | \
        tee $APT_SOURCES_D/wasta-linux-ubuntu-wasta-apps-$SERIES.list
    echo "# deb-src http://ppa.launchpad.net/wasta-linux/wasta-apps/ubuntu $SERIES main" | \
        tee -a $APT_SOURCES_D/wasta-linux-ubuntu-wasta-apps-$SERIES.list
else
    # found, but ensure Wasta-Apps PPA ACTIVE (user could have accidentally disabled)
    # DO NOT match any lines ending in #wasta
    sed -i -e '/#wasta$/! s@.*\(deb http://ppa.launchpad.net\)@\1@' \
        $APT_SOURCES_D/wasta-linux-ubuntu-wasta-apps-$SERIES.list
fi

# add LibreOffice 5.1 PPA
if ! [ -e $APT_SOURCES_D/libreoffice-ubuntu-libreoffice-5-1-$SERIES.list ];
then
    echo
    echo "*** Adding LibreOffice 5.1 PPA"
    echo
    echo "deb http://ppa.launchpad.net/libreoffice/libreoffice-5-1/ubuntu $SERIES main" | \
        tee $APT_SOURCES_D/libreoffice-ubuntu-libreoffice-5-1-$SERIES.list
    echo "# deb-src http://ppa.launchpad.net/libreoffice/libreoffice-5-1/ubuntu $SERIES main" | \
        tee -a $APT_SOURCES_D/libreoffice-ubuntu-libreoffice-5-1-$SERIES.list
else
    # found, but ensure Wasta-Linux PPA ACTIVE (user could have accidentally disabled)
    # DO NOT match any lines ending in #wasta
    sed -i -e '/#wasta$/! s@.*\(deb http://ppa.launchpad.net\)@\1@' \
        $APT_SOURCES_D/libreoffice-ubuntu-libreoffice-5-1-$SERIES.list
fi

# apt-get adjustments
# 2017-09-28 rik: updating to NOT replace files if they already exist.
#   We don't want to reset them IF the user has manually modified these files.

# have apt-get not get language translation files for faster updates.
if ! [ -e /etc/apt/apt.conf.d/99translations ];
then
    echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/99translations
fi

# have apt-get not use cache: Internet caching by ISPs cache broken packages
#   causing apt-get to get hash sum mismatches, badsigs, etc.
if ! [ -e /etc/apt/apt.conf.d/99nocache ];
then
    echo 'Acquire::http::No-Cache "True";' > /etc/apt/apt.conf.d/99nocache
fi

# have apt-get not use proxy: Internet caching by ISPs cache broken packages
#   causing apt-get to get hash sum mismatches, badsigs, etc.
if ! [ -e /etc/apt/apt.conf.d/99brokenproxy ];
then
    echo 'Acquire::BrokenProxy "True";' > /etc/apt/apt.conf.d/99brokenproxy
fi

# remove any partial updates: these are often broken if they exist
if [ -e /var/lib/apt/lists/partial/ ];
then
    rm -r /var/lib/apt/lists/partial/
fi

# ------------------------------------------------------------------------------
# openssh server re-config
# ------------------------------------------------------------------------------
# machines created from ISO from Remastersys 3.0.4 stock will have some key files
#   missing needed for ssh server to work correctly

# don't print out errors (so will be blank if ssh not installed)
OPENSSH_INSTALLED=$(dpkg --status openssh-server 2>/dev/null \
    | grep Status: | grep installed || true;)
if [ "${OPENSSH_INSTALLED}" ];
then
    echo
    echo "*** Reconfiguring openssh-server"
    echo
    # This command will just re-create missing files: will not change existing
    #   settings
    dpkg-reconfigure openssh-server
fi

# ------------------------------------------------------------------------------
# set wasta-logo as Plymouth Theme
# ------------------------------------------------------------------------------
# only do if wasta-logo not current default.plymouth
# below will return *something* if wasta-logo found in default.plymouth
#   '|| true; needed so won't return error=1 if nothing found
WASTA_PLY_THEME=$(cat /etc/alternatives/default.plymouth | \
    grep ImageDir=/usr/share/plymouth/themes/wasta-logo || true;)
# if variable is still "", then need to set default.plymouth
if [ -z "$WASTA_PLY_THEME" ];
then
    echo
    echo "*** Setting Plymouth Theme to wasta-logo"
    echo
    # add wasta-logo to default.plymouth theme list
    update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth \
        /usr/share/plymouth/themes/wasta-logo/wasta-logo.plymouth 100

    # set wasta-logo as default.plymouth
    update-alternatives --set default.plymouth \
        /usr/share/plymouth/themes/wasta-logo/wasta-logo.plymouth

    # update
    update-initramfs -u
    
    # update grub (to get rid of purple grub boot screen)
    update-grub
else
    echo
    echo "*** Plymouth Theme already set to wasta-logo.  No update needed."
    echo
fi

WASTA_PLY_TEXT=$(cat /etc/alternatives/text.plymouth | \
    grep title=Wasta-Linux || true;)
# if variable is still "", then need to set text.plymouth
if [ -z "$WASTA_PLY_TEXT" ];
then
    echo
    echo "*** Setting Plymouth TEXT Theme to wasta-text"
    echo

    # add wasta-text to text.plymouth theme list
    update-alternatives --install /usr/share/plymouth/themes/text.plymouth text.plymouth \
        /usr/share/plymouth/themes/wasta-text/wasta-text.plymouth 100

    # set wasta-text as text.plymouth
    update-alternatives --set text.plymouth \
        /usr/share/plymouth/themes/wasta-text/wasta-text.plymouth

    # update
    update-initramfs -u
else
    echo
    echo "*** Plymouth TEXT Theme already set to wasta-text.  No update needed."
    echo
fi

# ------------------------------------------------------------------------------
# call app-adjustments.sh
# ------------------------------------------------------------------------------
echo
echo "*** Calling app-adjustments.sh script"
echo
bash $DIR/scripts/app-adjustments.sh

# ------------------------------------------------------------------------------
# log permissions cleanup
# ------------------------------------------------------------------------------

# ??? needed?
# some logs need different ownership than "root:root"
# remastersys doesn't do this right, check if fixed in wasta-remastersys?
chown -f syslog:adm /var/log/syslog*
chown -f syslog:adm /var/log/auth.log*
chown -f syslog:adm /var/log/kern.log*
chown -f syslog:adm /var/log/mail.log*

# ------------------------------------------------------------------------------
# disable apport error reporting
# ------------------------------------------------------------------------------
if [ -e /etc/default/apport ];
then
    echo
    echo "*** Disabling apport error reporting"
    echo
    sed -i -e 's@enabled=1@enabled=0@' /etc/default/apport
else
    cat << EOF > /etc/default/apport
enabled=0
EOF
fi

# ------------------------------------------------------------------------------
# usb_modeswitch: enable SetStorageDelay
# ------------------------------------------------------------------------------
if [ -e /etc/usb_modeswitch.conf ];
then
    echo
    echo "*** usb_modeswitch: enabling SetStorageDelay"
    echo
    sed -i -e 's@#.*\(SetStorageDelay\)=.*@\1=4@' /etc/usb_modeswitch.conf

    # LEGACY fix: original sed changed =4 to =4=4
    sed -i -e 's@=4=4@=4@g' /etc/usb_modeswitch.conf
fi

# ------------------------------------------------------------------------------
# Dconf / Gsettings Default Value adjustments
# ------------------------------------------------------------------------------
# Values in /usr/share/glib-2.0/schemas/z_10_wasta-core.gschema.override
#   will override Ubuntu defaults.
# Below command compiles them to be the defaults
echo
echo "*** Updating dconf / gsettings default values"
echo

# MAIN System schemas: we have placed our override file in this directory
# Sending any "error" to null (if key not found don't want to worry user)
glib-compile-schemas /usr/share/glib-2.0/schemas/ > /dev/null 2>&1 || true;

# Some Unity dconf values have no schema, need to manually set:
# /org/compiz/profiles/unity/plugins/unityshell/icon-size 32   NO SCHEMA
# /org/compiz/profiles/unity/plugins/expo/x-offset 48   NO SCHEMA

# ------------------------------------------------------------------------------
# Disable GNOME Overlay Scrollbars
# ------------------------------------------------------------------------------
# prior to 15.10, done by removing overlay-scrollbar*, but now Ubuntu uses
#   Gnome's overlay scrollbars, which can't be removed but can be disabled
sed -i -e '$a GTK_OVERLAY_SCROLLING=0' \
    -i -e '\#GTK_OVERLAY_SCROLLING#d' \
    /etc/environment

# ------------------------------------------------------------------------------
# Reduce "Swappiness"
# ------------------------------------------------------------------------------
# https://sites.google.com/site/easylinuxtipsproject/first
#   (default is 60, which means it goes to swap too quickly when low ram)
sed -i -e '$a vm.swappiness=10' \
    -i -e '\#vm.swappiness#d' \
    /etc/sysctl.conf

# ???Needed 15.10/16/04???
# ------------------------------------------------------------------------------
# Allow Shockwave Flash videos to play in browser
# ------------------------------------------------------------------------------
# Fix from here: http://askubuntu.com/questions/7240/how-do-i-play-swf-files

#sed -i -e "s@vnd.adobe.flash.movie@x-shockwave-flash@" \
#    /usr/share/mime/packages/freedesktop.org.xml

#update-mime-database /usr/share/mime

# ------------------------------------------------------------------------------
# Legacy Cleanup
# ------------------------------------------------------------------------------
# original 16.04 64bit BETA ISOs had 2 active "at" jobs.  Need to remove
if [ "$(atq | grep 49)" ];
then
    echo
    echo "*** removing legacy 'at' job 49"
    echo
    atrm 49
fi

if [ "$(atq | grep 50)" ];
then
    echo
    echo "*** removing legacy 'at' job 50"
    echo
    atrm 50
fi

# ------------------------------------------------------------------------------
# Finished
# ------------------------------------------------------------------------------
echo
echo "*** Script Exit: wasta-core-postinst.sh"
echo

exit 0
