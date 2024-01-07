#!/bin/bash

# This script provides common customization options for the ISO
# 
# Usage: Copy this file to config.sh and make changes there.  Keep this file (default_config.sh) as-is
#   so that subsequent changes can be easily merged from upstream.  Keep all customiations in config.sh

# The version of BSD to generate.  Successfully tested: FreeBSD 13.0, OpenBSD 6.9, NetBSD 9.2
# See the respective BSD websites for details
export TARGET_BSD_VERSION="FreeBSD 13.0"

# The BSD Mirror URL. It's better to change for faster download.
# More mirrors see: https://www.freebsd.org/doc/handbook/mirrors.html
export TARGET_BSD_MIRROR="https://ftp.freebsd.org/pub/FreeBSD/releases/amd64/13.0-RELEASE/"

# The packaged version of the BSD kernel to install on target image.
# See the respective BSD websites for details
export TARGET_KERNEL_PACKAGE="GENERIC"

# The file (no extension) of the ISO containing the generated disk image,
# the volume id, and the hostname of the live environment are set from this name.
export TARGET_NAME="bsd-from-scratch"

# The text label shown in GRUB for booting into the live environment
export GRUB_LIVEBOOT_LABEL="Try BSD FS without installing"

# The text label shown in GRUB for starting installation
export GRUB_INSTALL_LABEL="Install BSD FS"

# Packages to be removed from the target system after installation completes succesfully
export TARGET_PACKAGE_REMOVE="
    ubiquity \
    casper \
    discover \
    laptop-detect \
    os-prober \
"

# Package customisation function.  Update this function to customize packages
# present on the installed system.
function customize_image() {
    # install graphics and desktop
    pkg install -y \
    xorg \
    xfce

    # useful tools
    pkg install -y \
    clamav \
    terminator \
    curl \
    vim \
    nano \
    less

    # purge
    pkg remove -y \
    transmission-gtk \
    transmission-common \
    gnome-mahjongg \
    gnome-mines \
    gnome-sudoku \
    aisleriot \
    hitori
}

# Used to version the configuration.  If breaking changes occur, manual
# updates to this file from the default may be necessary.
export CONFIG_FILE_VERSION="0.4"
