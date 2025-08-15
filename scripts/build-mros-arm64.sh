#!/bin/bash
#
# mros-windows12 ARM64 Build Script
# This script builds a bootable and installable Windows 12-inspired OS for ARM64 devices
#

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$ROOT_DIR/build"
CONFIG_DIR="$ROOT_DIR/mros-config"
CHROOT_DIR="$BUILD_DIR/chroot"
IMAGE_DIR="$BUILD_DIR/image"
ISO_DIR="$BUILD_DIR/iso"

# Load configuration
source "$CONFIG_DIR/distribution.conf"

# Default values
PLATFORM="generic"
SECURE_BOOT=false
TPM_REQUIRED=false
MINIMAL=false
ALL_DRIVERS=false
UPLOAD=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --platform=*)
            PLATFORM="${1#*=}"
            shift
            ;;
        --apple-silicon)
            PLATFORM="apple-silicon"
            shift
            ;;
        --snapdragon)
            PLATFORM="qualcomm"
            shift
            ;;
        --microsoft-sq)
            PLATFORM="microsoft-sq"
            shift
            ;;
        --secure-boot)
            SECURE_BOOT=true
            shift
            ;;
        --tpm-required)
            TPM_REQUIRED=true
            shift
            ;;
        --minimal)
            MINIMAL=true
            shift
            ;;
        --all-drivers)
            ALL_DRIVERS=true
            shift
            ;;
        --upload)
            UPLOAD=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--platform=<platform>] [--secure-boot] [--tpm-required] [--minimal] [--all-drivers] [--upload]"
            echo "Platforms: generic, apple-silicon, qualcomm, microsoft-sq"
            exit 1
            ;;
    esac
done

# Print build configuration
echo "Building mros-windows12 ARM64 ISO"
echo "--------------------------------"
echo "Platform: $PLATFORM"
echo "Secure Boot: $SECURE_BOOT"
echo "TPM Required: $TPM_REQUIRED"
echo "Minimal Build: $MINIMAL"
echo "All Drivers: $ALL_DRIVERS"
echo "Upload ISO: $UPLOAD"
echo "--------------------------------"

# Create build directories
mkdir -p "$BUILD_DIR" "$CHROOT_DIR" "$IMAGE_DIR" "$ISO_DIR"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required tools
check_requirements() {
    echo "Checking build requirements..."
    
    local required_tools=(
        "debootstrap"
        "squashfs-tools"
        "xorriso"
        "grub-efi-arm64-bin"
        "qemu-user-static"
        "binfmt-support"
        "mtools"
    )
    
    local missing_tools=()
    
    for tool in "${required_tools[@]}"; do
        if ! command_exists "$tool"; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo "Error: The following required tools are missing:"
        for tool in "${missing_tools[@]}"; do
            echo "  - $tool"
        done
        echo "Please install them and try again."
        exit 1
    fi
    
    echo "All requirements satisfied."
}

# Bootstrap the base system
bootstrap_system() {
    echo "Bootstrapping base system..."
    
    if [ -f "$CHROOT_DIR/etc/os-release" ]; then
        echo "Chroot environment already exists. Skipping bootstrap."
        return
    fi
    
    # Bootstrap Ubuntu base system for ARM64
    sudo debootstrap \
        --arch=arm64 \
        --variant=minbase \
        --include=qemu-user-static \
        "$BASE_VERSION" \
        "$CHROOT_DIR" \
        http://ports.ubuntu.com/ubuntu-ports/
    
    # Configure external mount points
    sudo mount --bind /dev "$CHROOT_DIR/dev"
    sudo mount --bind /run "$CHROOT_DIR/run"
    
    # Copy QEMU for ARM64 emulation
    sudo cp /usr/bin/qemu-aarch64-static "$CHROOT_DIR/usr/bin/"
}

# Configure the chroot environment
configure_chroot() {
    echo "Configuring chroot environment..."
    
    # Create setup script
    cat > "$BUILD_DIR/chroot_setup.sh" << EOF
#!/bin/bash
set -e

# Mount points
mount none -t proc /proc
mount none -t sysfs /sys
mount none -t devpts /dev/pts

# Environment
export HOME=/root
export LC_ALL=C

# Set hostname
echo "mros-windows12" > /etc/hostname

# Configure apt sources
cat > /etc/apt/sources.list << EOL
deb http://ports.ubuntu.com/ubuntu-ports/ ${BASE_VERSION} main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ ${BASE_VERSION}-updates main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ ${BASE_VERSION}-security main restricted universe multiverse
EOL

# Update package lists
apt-get update

# Install systemd
apt-get install -y libterm-readline-gnu-perl systemd-sysv

# Configure machine-id
dbus-uuidgen > /etc/machine-id
ln -fs /etc/machine-id /var/lib/dbus/machine-id

# Divert initctl
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl

# Upgrade packages
apt-get -y upgrade

# Install essential packages
apt-get install -y \
    sudo \
    ubuntu-standard \
    casper \
    discover \
    laptop-detect \
    os-prober \
    network-manager \
    resolvconf \
    net-tools \
    wireless-tools \
    locales \
    grub-common \
    grub-efi-arm64 \
    grub-efi-arm64-bin \
    grub2-common

# Install kernel
apt-get install -y --no-install-recommends linux-generic-arm64

# Install graphical installer
apt-get install -y \
    ubiquity \
    ubiquity-casper \
    ubiquity-frontend-gtk \
    ubiquity-slideshow-ubuntu \
    ubiquity-ubuntu-artwork

# Install desktop environment
apt-get install -y \
    plymouth-theme-ubuntu-logo \
    ubuntu-gnome-desktop \
    ubuntu-gnome-wallpapers

# Install ARM64-specific packages
apt-get install -y \
    firmware-linux \
    firmware-linux-nonfree \
    mesa-vulkan-drivers \
    libvulkan1 \
    vulkan-tools

# Platform-specific optimizations
if [ "$PLATFORM" = "apple-silicon" ]; then
    # Apple Silicon specific packages
    apt-get install -y \
        firmware-apple \
        apple-silicon-support
elif [ "$PLATFORM" = "qualcomm" ]; then
    # Qualcomm specific packages
    apt-get install -y \
        firmware-qcom-media \
        qcom-compute-drivers
elif [ "$PLATFORM" = "microsoft-sq" ]; then
    # Microsoft SQ specific packages
    apt-get install -y \
        firmware-microsoft \
        microsoft-sq-drivers
fi

# Install all drivers if requested
if [ "$ALL_DRIVERS" = "true" ]; then
    apt-get install -y \
        firmware-misc-nonfree \
        firmware-atheros \
        firmware-brcm80211 \
        firmware-iwlwifi \
        firmware-libertas \
        firmware-realtek \
        firmware-zd1211
fi

# Install security packages if requested
if [ "$SECURE_BOOT" = "true" ]; then
    apt-get install -y \
        shim-signed \
        sbsigntool \
        efitools
fi

if [ "$TPM_REQUIRED" = "true" ]; then
    apt-get install -y \
        tpm2-tools \
        libtss2-dev
fi

# Install additional applications
apt-get install -y \
    firefox \
    libreoffice \
    gimp \
    vlc \
    htop \
    neofetch \
    curl \
    wget \
    zip \
    unzip

# Clean up
apt-get clean
rm -rf /tmp/* /var/tmp/*
rm -rf /var/lib/apt/lists/*
rm -f /etc/resolv.conf
EOF

    # Make script executable
    chmod +x "$BUILD_DIR/chroot_setup.sh"
    
    # Execute setup script in chroot
    sudo cp "$BUILD_DIR/chroot_setup.sh" "$CHROOT_DIR/"
    sudo chroot "$CHROOT_DIR" /chroot_setup.sh
    sudo rm "$CHROOT_DIR/chroot_setup.sh"
}

# Create bootable image
create_bootable_image() {
    echo "Creating bootable image..."
    
    # Create image directory structure
    mkdir -p "$IMAGE_DIR/casper" "$IMAGE_DIR/boot/grub" "$IMAGE_DIR/EFI/BOOT"
    
    # Copy kernel and initrd
    sudo cp "$CHROOT_DIR/boot/vmlinuz"* "$IMAGE_DIR/casper/vmlinuz"
    sudo cp "$CHROOT_DIR/boot/initrd.img"* "$IMAGE_DIR/casper/initrd"
    
    # Create grub.cfg
    cat > "$IMAGE_DIR/boot/grub/grub.cfg" << EOF
set timeout=10
set default=0

loadfont unicode

set menu_color_normal=white/black
set menu_color_highlight=black/light-gray

menuentry "Try mros-windows12 ARM64 without installing" {
    linux /casper/vmlinuz boot=casper quiet splash ---
    initrd /casper/initrd
}

menuentry "Install mros-windows12 ARM64" {
    linux /casper/vmlinuz boot=casper only-ubiquity quiet splash ---
    initrd /casper/initrd
}

menuentry "Check disc for defects" {
    linux /casper/vmlinuz boot=casper integrity-check quiet splash ---
    initrd /casper/initrd
}
EOF

    # Create manifest
    sudo chroot "$CHROOT_DIR" dpkg-query -W --showformat='${Package} ${Version}\n' | sudo tee "$IMAGE_DIR/casper/filesystem.manifest"
    sudo cp -v "$IMAGE_DIR/casper/filesystem.manifest" "$IMAGE_DIR/casper/filesystem.manifest-desktop"
    sudo sed -i '/ubiquity/d' "$IMAGE_DIR/casper/filesystem.manifest-desktop"
    sudo sed -i '/casper/d' "$IMAGE_DIR/casper/filesystem.manifest-desktop"
    sudo sed -i '/discover/d' "$IMAGE_DIR/casper/filesystem.manifest-desktop"
    sudo sed -i '/laptop-detect/d' "$IMAGE_DIR/casper/filesystem.manifest-desktop"
    sudo sed -i '/os-prober/d' "$IMAGE_DIR/casper/filesystem.manifest-desktop"
    
    # Create squashfs
    sudo mksquashfs "$CHROOT_DIR" "$IMAGE_DIR/casper/filesystem.squashfs" -comp zstd -Xcompression-level 19
    
    # Write filesystem.size
    printf $(sudo du -sx --block-size=1 "$CHROOT_DIR" | cut -f1) > "$IMAGE_DIR/casper/filesystem.size"
    
    # Create diskdefines
    cat > "$IMAGE_DIR/README.diskdefines" << EOF
#define DISKNAME  mros-windows12 ARM64
#define TYPE  binary
#define TYPEbinary  1
#define ARCH  arm64
#define ARCHarm64  1
#define DISKNUM  1
#define DISKNUM1  1
#define TOTALNUM  0
#define TOTALNUM0  1
EOF
}

# Create ISO image
create_iso() {
    echo "Creating ISO image..."
    
    # Create UEFI boot image
    grub-mkstandalone \
        --format=arm64-efi \
        --output="$IMAGE_DIR/EFI/BOOT/BOOTAA64.EFI" \
        --locales="" \
        --fonts="" \
        "boot/grub/grub.cfg=$IMAGE_DIR/boot/grub/grub.cfg"
    
    # Create FAT16 UEFI boot disk image
    dd if=/dev/zero of="$IMAGE_DIR/efiboot.img" bs=1M count=10
    mkfs.vfat "$IMAGE_DIR/efiboot.img"
    mmd -i "$IMAGE_DIR/efiboot.img" ::/EFI ::/EFI/BOOT
    mcopy -i "$IMAGE_DIR/efiboot.img" "$IMAGE_DIR/EFI/BOOT/BOOTAA64.EFI" ::/EFI/BOOT/
    
    # Generate md5sum.txt
    pushd "$IMAGE_DIR"
    find . -type f -print0 | xargs -0 md5sum | grep -v -e 'md5sum.txt' -e 'efiboot.img' > md5sum.txt
    popd
    
    # Create ISO
    xorriso \
        -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "mros-windows12-ARM64" \
        -output "$ISO_DIR/mros-windows12-$VERSION-arm64.iso" \
        -eltorito-alt-boot \
        -e efiboot.img \
        -no-emul-boot \
        -append_partition 2 0xef "$IMAGE_DIR/efiboot.img" \
        -m "efiboot.img" \
        "$IMAGE_DIR"
    
    echo "ISO created: $ISO_DIR/mros-windows12-$VERSION-arm64.iso"
}

# Sign the bootloader for Secure Boot
sign_bootloader() {
    if [ "$SECURE_BOOT" = "true" ]; then
        echo "Signing bootloader for Secure Boot..."
        
        # Generate keys if they don't exist
        if [ ! -f "$BUILD_DIR/sb.key" ]; then
            openssl req -new -x509 -newkey rsa:2048 -keyout "$BUILD_DIR/sb.key" -out "$BUILD_DIR/sb.crt" \
                -nodes -days 3650 -subj "/CN=mros-windows12 Secure Boot/"
        fi
        
        # Sign the bootloader
        sbsign --key "$BUILD_DIR/sb.key" --cert "$BUILD_DIR/sb.crt" \
            --output "$IMAGE_DIR/EFI/BOOT/BOOTAA64.EFI.signed" \
            "$IMAGE_DIR/EFI/BOOT/BOOTAA64.EFI"
        
        # Replace unsigned bootloader with signed one
        mv "$IMAGE_DIR/EFI/BOOT/BOOTAA64.EFI.signed" "$IMAGE_DIR/EFI/BOOT/BOOTAA64.EFI"
        
        # Update the EFI boot image
        mmd -i "$IMAGE_DIR/efiboot.img" ::/EFI ::/EFI/BOOT
        mcopy -i "$IMAGE_DIR/efiboot.img" "$IMAGE_DIR/EFI/BOOT/BOOTAA64.EFI" ::/EFI/BOOT/
    fi
}

# Upload ISO if requested
upload_iso() {
    if [ "$UPLOAD" = "true" ]; then
        echo "Uploading ISO..."
        
        ISO_PATH="$ISO_DIR/mros-windows12-$VERSION-arm64.iso"
        
        if command_exists curl; then
            echo "Uploading to bashupload.com..."
            curl -T "$ISO_PATH" https://bashupload.com
        else
            echo "Error: curl is required for uploading."
            exit 1
        fi
    fi
}

# Clean up
cleanup() {
    echo "Cleaning up..."
    
    # Unmount chroot directories
    if mountpoint -q "$CHROOT_DIR/dev"; then
        sudo umount "$CHROOT_DIR/dev"
    fi
    
    if mountpoint -q "$CHROOT_DIR/run"; then
        sudo umount "$CHROOT_DIR/run"
    fi
    
    if mountpoint -q "$CHROOT_DIR/proc"; then
        sudo umount "$CHROOT_DIR/proc"
    fi
    
    if mountpoint -q "$CHROOT_DIR/sys"; then
        sudo umount "$CHROOT_DIR/sys"
    fi
    
    if mountpoint -q "$CHROOT_DIR/dev/pts"; then
        sudo umount "$CHROOT_DIR/dev/pts"
    fi
}

# Main function
main() {
    check_requirements
    bootstrap_system
    configure_chroot
    create_bootable_image
    sign_bootloader
    create_iso
    upload_iso
    cleanup
    
    echo "Build completed successfully!"
    echo "ISO location: $ISO_DIR/mros-windows12-$VERSION-arm64.iso"
}

# Run main function
main

exit 0

