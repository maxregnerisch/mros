#!/bin/bash

set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error
#set -x

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

CMD=(setup_host debootstrap run_chroot build_iso)

DATE=`TZ="UTC" date +"%y%m%d-%H%M%S"`

function help() {
    # if $1 is set, use $1 as headline message in help()
    if [ -z ${1+x} ]; then
        echo -e "This script builds a bootable FreeBSD ISO image"
        echo -e
    else
        echo -e $1
        echo
    fi
    echo -e "Supported commands : ${CMD[*]}"
    echo -e
    echo -e "Syntax: $0 [start_cmd] [-] [end_cmd]"
    echo -e "\trun from start_cmd to end_end"
    echo -e "\tif start_cmd is omitted, start from first command"
    echo -e "\tif end_cmd is omitted, end with last command"
    echo -e "\tenter single cmd to run the specific command"
    echo -e "\tenter '-' as only argument to run all commands"
    echo -e
    exit 0
}

function find_index() {
    local ret;
    local i;
    for ((i=0; i<${#CMD[*]}; i++)); do
        if [ "${CMD[i]}" == "$1" ]; then
            index=$i;
            return;
        fi
    done
    help "Command not found : $1"
}

function chroot_enter_setup() {
    sudo mount --bind /dev chroot/dev
    sudo mount --bind /run chroot/run
    sudo chroot chroot mount -t devfs devfs /dev
}

function chroot_exit_teardown() {
    sudo chroot chroot umount /dev
    sudo umount chroot/dev
    sudo umount chroot/run
}

function check_host() {
    local os_ver
    os_ver=`uname -s`
    if [[ "$os_ver" != "FreeBSD" ]]; then
        echo "WARNING : OS is not FreeBSD and is untested"
    fi

    if [ $(id -u) -eq 0 ]; then
        echo "This script should not be run as 'root'"
        exit 1
    fi
}

# Load configuration values from file
function load_config() {
    if [[ -f "$SCRIPT_DIR/config.sh" ]]; then
        . "$SCRIPT_DIR/config.sh"
    elif [[ -f "$SCRIPT_DIR/default_config.sh" ]]; then
        . "$SCRIPT_DIR/default_config.sh"
    else
        >&2 echo "Unable to find default config file  $SCRIPT_DIR/default_config.sh, aborting."
        exit 1
    fi
}

# Verify that necessary configuration values are set and they are valid
function check_config() {
    local expected_config_version
    expected_config_version="0.4"

    if [[ "$CONFIG_FILE_VERSION" != "$expected_config_version" ]]; then
        >&2 echo "Invalid or old config version $CONFIG_FILE_VERSION, expected $expected_config_version. Please update your configuration file from the default."
        exit 1
    fi
}

function setup_host() {
    echo "=====> running setup_host ..."
    sudo pkg update
    sudo pkg install -y debootstrap squashfs-tools xorriso grub2-pc-bin mtools dosfstools unzip
    sudo mkdir -p chroot
}

function debootstrap() {
    echo "=====> running debootstrap ... will take a couple of minutes ..."
    sudo debootstrap  --arch=amd64 --variant=minbase $TARGET_FREEBSD_VERSION chroot $TARGET_FREEBSD_MIRROR
}

function run_chroot() {
    echo "=====> running run_chroot ..."

    chroot_enter_setup

    # Setup build scripts in chroot environment
    sudo ln -f $SCRIPT_DIR/chroot_build.sh chroot/root/chroot_build.sh
    sudo ln -f $SCRIPT_DIR/default_config.sh chroot/root/default_config.sh
    if [[ -f "$SCRIPT_DIR/config.sh" ]]; then
        sudo ln -f $SCRIPT_DIR/config.sh chroot/root/config.sh
    fi

    # Launch into chroot environment to build install image.
    sudo chroot chroot /usr/bin/env /root/chroot_build.sh -

    # Cleanup after image changes
    sudo rm -f chroot/root/chroot_build.sh
    sudo rm -f chroot/root/default_config.sh
    if [[ -f "chroot/root/config.sh" ]]; then
        sudo rm -f chroot/root/config.sh
    fi

    chroot_exit_teardown
}

function build_iso() {
    echo "=====> running build_iso ..."

    rm -rf image
    mkdir -p image/{casper,isolinux,install}

    # copy kernel files
    sudo cp chroot/boot/kernel/kernel image/casper/kernel
    sudo cp chroot/boot/kernel/kernel.symbols image/casper/kernel.symbols

    # memtest86
    sudo cp chroot/boot/memtest86+/memtest.bin image/install/memtest86

    # grub
    touch image/freebsd
    cat <<EOF > image/isolinux/grub.cfg

search --set=root --file /freebsd

insmod all_video

set default="0"
set timeout=30

menuentry "${GRUB_LIVEBOOT_LABEL}" {
   kfreebsd /casper/kernel boot=casper nopersistent toram quiet splash ---
}

menuentry "${GRUB_INSTALL_LABEL}" {
   kfreebsd /casper/kernel boot=casper only-ubiquity quiet splash ---
}

menuentry "Check disc for defects" {
   kfreebsd /casper/kernel boot=casper integrity-check quiet splash ---
}

menuentry "Test memory Memtest86+" {
   multiboot /install/memtest86
}
EOF

    # generate manifest
    sudo chroot chroot pkg info -q > image/casper/filesystem.manifest
    sudo cp -v image/casper/filesystem.manifest image/casper/filesystem.manifest-desktop
    for pkg in $TARGET_PACKAGE_REMOVE; do
        sudo sed -i "/$pkg/d" image/casper/filesystem.manifest-desktop
    done

    # compress rootfs
    sudo mksquashfs chroot image/casper/filesystem.squashfs \
        -noappend -no-duplicates -no-recovery \
        -wildcards \
        -e "var/cache/pkg/*" \
        -e "root/*" \
        -e "root/.*" \
        -e "tmp/*" \
        -e "tmp/.*" \
        -e "swapfile"
    printf $(sudo du -sx --block-size=1 chroot | cut -f1) > image/casper/filesystem.size

    # create diskdefines
    cat <<EOF > image/README.diskdefines
#define DISKNAME  ${GRUB_LIVEBOOT_LABEL}
#define TYPE  binary
#define TYPEbinary  1
#define ARCH  amd64
#define ARCHamd64  1
#define DISKNUM  1
#define DISKNUM1  1
#define TOTALNUM  0
#define TOTALNUM0  1
EOF

    # create iso image
    pushd $SCRIPT_DIR/image
    grub-mkrescue \
        -o "$SCRIPT_DIR/$TARGET_NAME.iso" \
        .

    popd
}

# =============   main  ================

# we always stay in $SCRIPT_DIR
cd $SCRIPT_DIR

load_config
check_config
check_host

# check number of args
if [[ $# == 0 || $# > 3 ]]; then help; fi

# loop through args
dash_flag=false
start_index=0
end_index=${#CMD[*]}
for ii in "$@";
do
    if [[ $ii == "-" ]]; then
        dash_flag=true
        continue
    fi
    find_index $ii
    if [[ $dash_flag == false ]]; then
        start_index=$index
    else
        end_index=$(($index+1))
    fi
done
if [[ $dash_flag == false ]]; then
    end_index=$(($start_index + 1))
fi

#loop through the commands
for ((ii=$start_index; ii<$end_index; ii++)); do
    ${CMD[ii]}
done

echo "$0 - Initial build is done!"
