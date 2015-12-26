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
sed -i -e 's@.*\(deb.*ubuntu.com/ubuntu.* xenial \)@\1@' $APT_SOURCES
sed -i -e 's@.*\(deb.*ubuntu.com/ubuntu.* xenial-updates \)@\1@' $APT_SOURCES
sed -i -e 's@.*\(deb.*ubuntu.com/ubuntu.* xenial-security \)@\1@' $APT_SOURCES

# canonical.com lists include "partner" for things like skype, etc.
sed -i -e 's@.*\(deb.*canonical.com/ubuntu.* xenial \)@\1@' $APT_SOURCES

# legacy cleanup: PSO should NOT be in sources.list anymore (ubiquity will
#   remove when installing)
sed -i -e '\@packages.sil.org@d' $APT_SOURCES

# add SIL repository to sources.list.d
#   (otherwise ubiquity comments out when installing)
if ! [ -e $APT_SOURCES_D/packages-sil-org-xenial.list ];
then
    echo
    echo "*** Adding SIL Repository"
    echo

    echo "deb http://packages.sil.org/ubuntu xenial main" | \
        tee $APT_SOURCES_D/packages-sil-org-xenial.list
    echo "# deb-src http://packages.sil.org/ubuntu xenial main" | \
        tee -a $APT_SOURCES_D/packages-sil-org-xenial.list
else
    # found, but ensure PSO main ACTIVE (user could have accidentally disabled)
    echo
    echo "*** SIL Repository already exists, ensuring active"
    echo
    sed -i -e 's@.*\(deb http://packages.sil.org\)@\1@' \
        $APT_SOURCES_D/packages-sil-org-xenial.list
fi

# add SIL Experimental repository to sources.list.d
#   (otherwise ubiquity comments out when installing)
if ! [ -e $APT_SOURCES_D/packages-sil-org-xenial-experimental.list ];
then
    echo
    echo "*** Adding SIL Experimental Repository (inactive)"
    echo

    echo "# deb http://packages.sil.org/ubuntu xenial-experimental main" | \
        tee $APT_SOURCES_D/packages-sil-org-xenial-experimental.list
    echo "# deb-src http://packages.sil.org/ubuntu xenial-experimental main" | \
        tee -a $APT_SOURCES_D/packages-sil-org-xenial-experimental.list
fi

# install repository Keys (done locally since wasta-offline could be active)
echo
echo "*** Adding Repository GPG Keys"
echo
apt-key add $DIR/keys/sil.gpg
apt-key add $DIR/keys/libreoffice-ppa.gpg
apt-key add $DIR/keys/wasta-linux-ppa.gpg
apt-key add $DIR/keys/gnome-ppa.gpg

# add Wasta-Linux PPA
if ! [ -e $APT_SOURCES_D/wasta-linux-ubuntu-wasta-xenial.list ];
then
    echo
    echo "*** Adding Wasta-Linux PPA"
    echo

    echo "deb http://ppa.launchpad.net/wasta-linux/wasta/ubuntu xenial main" | \
        tee $APT_SOURCES_D/wasta-linux-ubuntu-wasta-xenial.list
    echo "# deb-src http://ppa.launchpad.net/wasta-linux/wasta/ubuntu xenial main" | \
        tee -a $APT_SOURCES_D/wasta-linux-ubuntu-wasta-xenial.list
else
    # found, but ensure Wasta-Linux PPA ACTIVE (user could have accidentally disabled)
    echo
    echo "*** Wasta PPA already exists, ensuring active"
    echo
    sed -i -e '$a deb http://ppa.launchpad.net/wasta-linux/wasta/ubuntu xenial main' \
        -i -e '\@deb http://ppa.launchpad.net/wasta-linux/wasta/ubuntu xenial main@d' \
        $APT_SOURCES_D/wasta-linux-ubuntu-wasta-xenial.list
fi

# add Wasta-Apps PPA
if ! [ -e $APT_SOURCES_D/wasta-linux-ubuntu-wasta-apps-xenial.list ];
then
    echo
    echo "*** Adding Wasta-Linux Apps PPA"
    echo

    echo "deb http://ppa.launchpad.net/wasta-linux/wasta-apps/ubuntu xenial main" | \
        tee $APT_SOURCES_D/wasta-linux-ubuntu-wasta-apps-xenial.list
    echo "# deb-src http://ppa.launchpad.net/wasta-linux/wasta-apps/ubuntu xenial main" | \
        tee -a $APT_SOURCES_D/wasta-linux-ubuntu-wasta-apps-xenial.list
else
    # found, but ensure Wasta-Apps PPA ACTIVE (user could have accidentally disabled)
    echo
    echo "*** Wasta Apps PPA already exists, ensuring active"
    echo
    sed -i -e '$a deb http://ppa.launchpad.net/wasta-linux/wasta-apps/ubuntu xenial main' \
        -i -e '\@deb http://ppa.launchpad.net/wasta-linux/wasta-apps/ubuntu xenial main@d' \
        $APT_SOURCES_D/wasta-linux-ubuntu-wasta-apps-xenial.list
fi

# add GNOME PPA (needed for "pure experience", but watch to see if breaks unity)
if ! [ -e $APT_SOURCES_D/gnome3-team-ubuntu-gnome3-xenial.list ];
then
    echo
    echo "*** Adding GNOME PPA"
    echo

    echo "deb http://ppa.launchpad.net/gnome3-team/gnome3/ubuntu xenial main" | \
        tee $APT_SOURCES_D/gnome3-team-ubuntu-gnome3-xenial.list
    echo "# deb-src http://ppa.launchpad.net/gnome3-team/gnome3/ubuntu xenial main" | \
        tee -a $APT_SOURCES_D/gnome3-team-ubuntu-gnome3-xenial.list
else
    # found, but ensure GNOME PPA ACTIVE (user could have accidentally disabled)
    echo
    echo "*** GNOME PPA already exists, ensuring active"
    echo
    sed -i -e '$a deb http://ppa.launchpad.net/gnome3-team/gnome3/ubuntu xenial main' \
        -i -e '\@deb http://ppa.launchpad.net/gnome3-team/gnome3/ubuntu xenial main@d' \
        $APT_SOURCES_D/gnome3-team-ubuntu-gnome3-xenial.list
fi

# apt-get adjustments
# have apt-get not get language translation files for faster updates.
echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/99translations

# have apt-get not use cache: Internet caching by ISPs cache broken packages
#   causing apt-get to get hash sum mismatches, badsigs, etc.
echo 'Acquire::http::No-Cache "True";' > /etc/apt/apt.conf.d/99nocache

# have apt-get not use proxy: Internet caching by ISPs cache broken packages
#   causing apt-get to get hash sum mismatches, badsigs, etc.
echo 'Acquire::BrokenProxy "True";' > /etc/apt/apt.conf.d/99brokenproxy

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
# LightDM setup
# ------------------------------------------------------------------------------
if [ -e /usr/sbin/lightdm ];
then
    # tweak default lightdm logos to match wasta linux instead of Ubuntu:
    echo
    echo "*** Making LightDM adjustments"
    echo

    # set gnome logo to wasta-linux icon
    cp $DIR/resources/wl-round-22.png \
        /usr/share/unity-greeter/gnome_badge.png
fi

# ------------------------------------------------------------------------------
# set wasta-logo as Plymouth Theme
# ------------------------------------------------------------------------------
# only do if wasta-logo not current default.plymouth
# below will return *something* if wasta-logo found in default.plymouth
#   '|| true; needed so won't return error=1 if nothing found
WASTA_PLY_THEME=$(cat /etc/alternatives/default.plymouth | \
    grep ImageDir=/lib/plymouth/themes/wasta-logo || true;)
# if variable is still "", then need to set default.plymouth
if [ -z "$WASTA_PLY_THEME" ];
then
    echo
    echo "*** Setting Plymouth Theme to wasta-logo"
    echo
    # add wasta-logo to default.plymouth theme list
    update-alternatives --install /lib/plymouth/themes/default.plymouth default.plymouth \
        /lib/plymouth/themes/wasta-logo/wasta-logo.plymouth 100

    # set wasta-logo as default.plymouth
    update-alternatives --set default.plymouth \
        /lib/plymouth/themes/wasta-logo/wasta-logo.plymouth

    # update
    update-initramfs -u
    
    # update grub (to get rid of purple grub boot screen)
    update-grub
else
    echo
    echo "*** Plymouth Theme already set to wasta-logo.  No update needed."
    echo
fi

# FYI: text.plymouth doesn't seem to work if ModuleName isn't "ubuntu-text"
WASTA_PLY_TEXT=$(cat /etc/alternatives/text.plymouth | \
    grep itle=Wasta-Linux || true;)
# if variable is still "", then need to set text.plymouth
if [ -z "$WASTA_PLY_TEXT" ];
then
    echo
    echo "*** Setting Plymouth TEXT Theme to wasta-text"
    echo

    # add wasta-text to text.plymouth theme list
    update-alternatives --install /lib/plymouth/themes/text.plymouth text.plymouth \
        /lib/plymouth/themes/wasta-text/wasta-text.plymouth 100

    # set wasta-text as text.plymouth
    update-alternatives --set text.plymouth \
        /lib/plymouth/themes/wasta-text/wasta-text.plymouth

    # update
    update-initramfs -u
else
    echo
    echo "*** Plymouth TEXT Theme already set to wasta-logo.  No update needed."
    echo
fi

# ------------------------------------------------------------------------------
# ibus fixes
# ------------------------------------------------------------------------------

# set as system-wide default input method:
# rik: removing for 15.10: I think not needed 
# im-config -n ibus

# set as current user default input method:
# rik: not sure if needed: seems that ibus properly triggering (??)
#sudo -u $(logname) im-config -n ibus

# ??do I need to set for new users also?

# ------------------------------------------------------------------------------
# Autostart Applications Adjustments
# ------------------------------------------------------------------------------

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

# some logs need different ownership than "root:root": remastersys doesn't do this right
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

# ------------------------------------------------------------------------------
# Firefox: set global default theme to 'arc-darker-theme'
# ------------------------------------------------------------------------------
sed -i -e '$a pref("general.skins.selectedSkin", "arc-darker-theme");' \
    -i -e '\#general.skins.selectedSkin#d' \
    /etc/firefox/syspref.js

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
# Finished
# ------------------------------------------------------------------------------
echo
echo "*** Script Exit: wasta-core-postinst.sh"
echo

exit 0
