#!/bin/bash
# mros-linux Build Script
# Build a complete mros-linux distribution with Windows 12-like UI

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_DIR/mros-config/distribution.conf"

# Default values
WORK_DIR="$HOME/mros-build"
CHROOT_DIR="$WORK_DIR/chroot"
IMAGE_DIR="$WORK_DIR/image"
SCRATCH_DIR="$WORK_DIR/scratch"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log_info "Loading configuration from $CONFIG_FILE"
        source <(grep -E '^[A-Z_]+=.*' "$CONFIG_FILE" | sed 's/^/export /')
    else
        log_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local required_packages=(
        "debootstrap"
        "squashfs-tools"
        "xorriso"
        "grub-pc-bin"
        "grub-efi-amd64-bin"
        "mtools"
        "python3"
        "python3-gi"
        "python3-requests"
    )
    
    local missing_packages=()
    
    for package in "${required_packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            missing_packages+=("$package")
        fi
    done
    
    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        log_error "Missing required packages: ${missing_packages[*]}"
        log_info "Install them with: sudo apt-get install ${missing_packages[*]}"
        exit 1
    fi
    
    log_success "All prerequisites satisfied"
}

# Setup build environment
setup_build_env() {
    log_info "Setting up build environment..."
    
    # Create directories
    sudo rm -rf "$WORK_DIR"
    mkdir -p "$WORK_DIR" "$CHROOT_DIR" "$IMAGE_DIR" "$SCRATCH_DIR"
    
    log_success "Build environment ready"
}

# Bootstrap base system
bootstrap_system() {
    log_info "Bootstrapping base system..."
    
    local base_version="${BASE_VERSION:-22.04}"
    local architecture="${ARCHITECTURE:-amd64}"
    
    sudo debootstrap \
        --arch="$architecture" \
        --variant=minbase \
        --components=main,restricted,universe,multiverse \
        jammy \
        "$CHROOT_DIR" \
        http://archive.ubuntu.com/ubuntu/
    
    log_success "Base system bootstrapped"
}

# Configure base system
configure_base_system() {
    log_info "Configuring base system..."
    
    # Copy DNS configuration
    sudo cp /etc/resolv.conf "$CHROOT_DIR/etc/"
    
    # Mount necessary filesystems
    sudo mount --bind /dev "$CHROOT_DIR/dev"
    sudo mount --bind /run "$CHROOT_DIR/run"
    sudo mount -t proc proc "$CHROOT_DIR/proc"
    sudo mount -t sysfs sysfs "$CHROOT_DIR/sys"
    sudo mount -t devpts devpts "$CHROOT_DIR/dev/pts"
    
    # Configure sources.list
    cat <<EOF | sudo tee "$CHROOT_DIR/etc/apt/sources.list"
deb http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse
EOF
    
    # Update package lists
    sudo chroot "$CHROOT_DIR" apt-get update
    
    log_success "Base system configured"
}

# Helper function to install packages with error handling
install_package_group() {
    local group_name="$1"
    shift
    local packages=("$@")
    
    log_info "Installing $group_name..."
    
    for package in "${packages[@]}"; do
        if sudo chroot "$CHROOT_DIR" apt-cache show "$package" >/dev/null 2>&1; then
            log_info "Installing $package..."
            if ! sudo chroot "$CHROOT_DIR" apt-get install -y "$package"; then
                log_warning "Failed to install $package, continuing..."
            fi
        else
            log_warning "Package $package not available, skipping..."
        fi
    done
}

# Install packages
install_packages() {
    log_info "Installing packages..."
    
    # Update package lists first
    sudo chroot "$CHROOT_DIR" apt-get update
    
    # Install essential packages (removed obsolete packages)
    install_package_group "essential packages" \
        ubuntu-standard \
        casper \
        laptop-detect \
        os-prober \
        network-manager \
        systemd-resolved \
        net-tools \
        wireless-tools \
        locales \
        linux-generic
    
    # Install desktop environment dependencies
    install_package_group "desktop environment packages" \
        xorg \
        xinit \
        python3 \
        python3-gi \
        python3-gi-cairo \
        gir1.2-gtk-4.0 \
        python3-requests \
        python3-pil \
        libgtk-4-1 \
        libgtk-4-dev \
        python3-cairo \
        python3-cairo-dev
    
    # Install multimedia and utilities
    install_package_group "multimedia and utility packages" \
        firefox \
        thunar \
        gnome-terminal \
        gedit \
        gnome-calculator \
        vlc \
        gimp \
        libreoffice \
        curl \
        wget \
        git \
        htop \
        neofetch \
        tree \
        zip \
        unzip \
        nano \
        vim \
        sudo
    
    log_success "Packages installed"
}

# Install mros desktop environment
install_mros_desktop() {
    log_info "Installing mros desktop environment..."
    
    # Create mros directories
    sudo mkdir -p "$CHROOT_DIR/usr/share/mros"
    sudo mkdir -p "$CHROOT_DIR/usr/share/mros/desktop"
    sudo mkdir -p "$CHROOT_DIR/usr/share/mros/apps"
    sudo mkdir -p "$CHROOT_DIR/usr/share/mros/services"
    sudo mkdir -p "$CHROOT_DIR/usr/share/mros/themes"
    sudo mkdir -p "$CHROOT_DIR/usr/bin"
    sudo mkdir -p "$CHROOT_DIR/etc/xdg/autostart"
    
    # Copy mros desktop components
    sudo cp -r "$PROJECT_DIR/mros-desktop"/* "$CHROOT_DIR/usr/share/mros/desktop/"
    sudo cp -r "$PROJECT_DIR/mros-apps"/* "$CHROOT_DIR/usr/share/mros/apps/"
    sudo cp -r "$PROJECT_DIR/mros-services"/* "$CHROOT_DIR/usr/share/mros/services/"
    sudo cp -r "$PROJECT_DIR/mros-themes"/* "$CHROOT_DIR/usr/share/mros/themes/"
    
    # Make scripts executable
    sudo find "$CHROOT_DIR/usr/share/mros" -name "*.py" -exec chmod +x {} \;
    
    # Create launcher scripts
    create_launcher_scripts
    
    # Create desktop session
    create_desktop_session
    
    # Create autostart entries
    create_autostart_entries
    
    log_success "mros desktop environment installed"
}

# Create launcher scripts
create_launcher_scripts() {
    log_info "Creating launcher scripts..."
    
    # mros-taskbar launcher
    cat <<'EOF' | sudo tee "$CHROOT_DIR/usr/bin/mros-taskbar"
#!/bin/bash
cd /usr/share/mros/desktop/taskbar
python3 taskbar.py "$@"
EOF
    
    # mros-startmenu launcher
    cat <<'EOF' | sudo tee "$CHROOT_DIR/usr/bin/mros-startmenu"
#!/bin/bash
cd /usr/share/mros/desktop/startmenu
python3 startmenu.py "$@"
EOF
    
    # mros-file-manager launcher
    cat <<'EOF' | sudo tee "$CHROOT_DIR/usr/bin/mros-file-manager"
#!/bin/bash
cd /usr/share/mros/apps/file-manager
python3 file-manager.py "$@"
EOF
    
    # mros-upload-manager launcher
    cat <<'EOF' | sudo tee "$CHROOT_DIR/usr/bin/mros-upload-manager"
#!/bin/bash
cd /usr/share/mros/apps/upload-manager
python3 upload-manager.py "$@"
EOF
    
    # mros-upload-service launcher
    cat <<'EOF' | sudo tee "$CHROOT_DIR/usr/bin/mros-upload-service"
#!/bin/bash
cd /usr/share/mros/services/upload-service
python3 upload-service.py "$@"
EOF
    
    # Make launchers executable
    sudo chmod +x "$CHROOT_DIR/usr/bin/mros-"*
    
    log_success "Launcher scripts created"
}

# Create desktop session
create_desktop_session() {
    log_info "Creating desktop session..."
    
    # Create mros session directory
    sudo mkdir -p "$CHROOT_DIR/usr/share/xsessions"
    
    # Create mros.desktop session file
    cat <<EOF | sudo tee "$CHROOT_DIR/usr/share/xsessions/mros.desktop"
[Desktop Entry]
Name=mros Desktop
Comment=mros-linux Desktop Environment
Exec=/usr/bin/mros-session
Type=Application
DesktopNames=mros
EOF
    
    # Create session script
    cat <<'EOF' | sudo tee "$CHROOT_DIR/usr/bin/mros-session"
#!/bin/bash

# Set environment variables
export XDG_CURRENT_DESKTOP=mros
export XDG_SESSION_DESKTOP=mros
export DESKTOP_SESSION=mros

# Start X11 compositor (if needed)
# compton -b &

# Set wallpaper
if command -v feh >/dev/null 2>&1; then
    feh --bg-fill /usr/share/mros/themes/windows12-theme/wallpaper.jpg &
fi

# Start mros desktop components
mros-taskbar &

# Start window manager (using openbox as lightweight WM)
if command -v openbox >/dev/null 2>&1; then
    exec openbox-session
else
    # Fallback to basic X session
    exec /usr/bin/x-session-manager
fi
EOF
    
    sudo chmod +x "$CHROOT_DIR/usr/bin/mros-session"
    
    log_success "Desktop session created"
}

# Create autostart entries
create_autostart_entries() {
    log_info "Creating autostart entries..."
    
    # Taskbar autostart
    cat <<EOF | sudo tee "$CHROOT_DIR/etc/xdg/autostart/mros-taskbar.desktop"
[Desktop Entry]
Type=Application
Name=mros Taskbar
Exec=mros-taskbar
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
    
    log_success "Autostart entries created"
}

# Configure system settings
configure_system() {
    log_info "Configuring system settings..."
    
    # Set hostname
    echo "${NAME:-mros-linux}" | sudo tee "$CHROOT_DIR/etc/hostname"
    
    # Configure hosts
    cat <<EOF | sudo tee "$CHROOT_DIR/etc/hosts"
127.0.0.1   localhost
127.0.1.1   ${NAME:-mros-linux}

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF
    
    # Configure locales
    sudo chroot "$CHROOT_DIR" locale-gen en_US.UTF-8
    sudo chroot "$CHROOT_DIR" update-locale LANG=en_US.UTF-8
    
    # Configure timezone
    sudo chroot "$CHROOT_DIR" ln -sf /usr/share/zoneinfo/UTC /etc/localtime
    
    # Create live user
    sudo chroot "$CHROOT_DIR" useradd -m -s /bin/bash "${LIVE_USER:-mros}"
    sudo chroot "$CHROOT_DIR" usermod -aG sudo "${LIVE_USER:-mros}"
    
    # Set live user password
    echo "${LIVE_USER:-mros}:${LIVE_PASSWORD:-live}" | sudo chroot "$CHROOT_DIR" chpasswd
    
    # Configure autologin
    if [[ "${AUTO_LOGIN:-true}" == "true" ]]; then
        sudo mkdir -p "$CHROOT_DIR/etc/systemd/system/getty@tty1.service.d"
        cat <<EOF | sudo tee "$CHROOT_DIR/etc/systemd/system/getty@tty1.service.d/override.conf"
[Service]
ExecStart=
ExecStart=-/sbin/agetty --noissue --autologin ${LIVE_USER:-mros} %I \$TERM
Type=idle
EOF
    fi
    
    log_success "System configured"
}

# Install additional themes and assets
install_themes() {
    log_info "Installing themes and assets..."
    
    # Install openbox (lightweight window manager)
    sudo chroot "$CHROOT_DIR" apt-get install -y openbox obconf
    
    # Install feh for wallpaper
    sudo chroot "$CHROOT_DIR" apt-get install -y feh
    
    # Create wallpaper directory
    sudo mkdir -p "$CHROOT_DIR/usr/share/mros/themes/windows12-theme"
    
    # Create a simple wallpaper (placeholder)
    cat <<'EOF' | sudo tee "$CHROOT_DIR/usr/share/mros/themes/windows12-theme/create_wallpaper.py"
#!/usr/bin/env python3
from PIL import Image, ImageDraw, ImageFont
import os

# Create a Windows 12-style wallpaper
width, height = 1920, 1080
image = Image.new('RGB', (width, height), color='#0078d4')

# Add gradient effect
draw = ImageDraw.Draw(image)
for y in range(height):
    alpha = y / height
    color = (
        int(0 + (120 - 0) * alpha),
        int(120 + (212 - 120) * alpha),
        int(212 + (255 - 212) * alpha)
    )
    draw.line([(0, y), (width, y)], fill=color)

# Save wallpaper
image.save('/usr/share/mros/themes/windows12-theme/wallpaper.jpg', 'JPEG', quality=95)
print("Wallpaper created successfully")
EOF
    
    # Create wallpaper
    sudo chroot "$CHROOT_DIR" python3 /usr/share/mros/themes/windows12-theme/create_wallpaper.py
    
    log_success "Themes and assets installed"
}

# Clean up chroot environment
cleanup_chroot() {
    log_info "Cleaning up chroot environment..."
    
    # Clean package cache
    sudo chroot "$CHROOT_DIR" apt-get clean
    sudo chroot "$CHROOT_DIR" apt-get autoremove -y
    
    # Remove temporary files
    sudo rm -rf "$CHROOT_DIR/tmp/*"
    sudo rm -rf "$CHROOT_DIR/var/tmp/*"
    
    # Clear bash history
    sudo rm -f "$CHROOT_DIR/root/.bash_history"
    sudo rm -f "$CHROOT_DIR/home/${LIVE_USER:-mros}/.bash_history"
    
    # Unmount filesystems
    sudo umount -lf "$CHROOT_DIR/dev/pts" 2>/dev/null || true
    sudo umount -lf "$CHROOT_DIR/sys" 2>/dev/null || true
    sudo umount -lf "$CHROOT_DIR/proc" 2>/dev/null || true
    sudo umount -lf "$CHROOT_DIR/run" 2>/dev/null || true
    sudo umount -lf "$CHROOT_DIR/dev" 2>/dev/null || true
    
    log_success "Chroot environment cleaned"
}

# Create squashfs filesystem
create_squashfs() {
    log_info "Creating squashfs filesystem..."
    
    local compression="${COMPRESSION:-xz}"
    local compression_level="${COMPRESSION_LEVEL:-6}"
    
    sudo mksquashfs \
        "$CHROOT_DIR" \
        "$IMAGE_DIR/casper/filesystem.squashfs" \
        -comp "$compression" \
        -Xbcj x86 \
        -Xdict-size 100% \
        -processors $(nproc)
    
    # Create filesystem.size
    printf $(sudo du -sx --block-size=1 "$CHROOT_DIR" | cut -f1) | sudo tee "$IMAGE_DIR/casper/filesystem.size"
    
    log_success "Squashfs filesystem created"
}

# Create ISO structure
create_iso_structure() {
    log_info "Creating ISO structure..."
    
    # Create directories
    mkdir -p "$IMAGE_DIR"/{casper,isolinux,install,.disk}
    
    # Copy kernel and initrd
    sudo cp "$CHROOT_DIR/boot/vmlinuz-"* "$IMAGE_DIR/casper/vmlinuz"
    sudo cp "$CHROOT_DIR/boot/initrd.img-"* "$IMAGE_DIR/casper/initrd"
    
    # Create grub configuration
    create_grub_config
    
    # Create disk info
    create_disk_info
    
    log_success "ISO structure created"
}

# Create GRUB configuration
create_grub_config() {
    log_info "Creating GRUB configuration..."
    
    mkdir -p "$IMAGE_DIR/boot/grub"
    
    cat <<EOF > "$IMAGE_DIR/boot/grub/grub.cfg"
search --set=root --file /casper/filesystem.squashfs

insmod all_video

set default="0"
set timeout=10

menuentry "${NAME:-mros-linux} ${VERSION:-1.0.0} - Live" {
   linux /casper/vmlinuz boot=casper quiet splash ---
   initrd /casper/initrd
}

menuentry "${NAME:-mros-linux} ${VERSION:-1.0.0} - Live (safe mode)" {
   linux /casper/vmlinuz boot=casper xforcevesa quiet splash ---
   initrd /casper/initrd
}
EOF
    
    log_success "GRUB configuration created"
}

# Create disk info
create_disk_info() {
    log_info "Creating disk info..."
    
    # Create .disk directory files
    echo "${NAME:-mros-linux} ${VERSION:-1.0.0}" > "$IMAGE_DIR/.disk/info"
    echo "${NAME:-mros-linux}" > "$IMAGE_DIR/.disk/release_notes_url"
    touch "$IMAGE_DIR/.disk/base_installable"
    echo "full_cd/single" > "$IMAGE_DIR/.disk/cd_type"
    
    log_success "Disk info created"
}

# Create bootable ISO
create_iso() {
    log_info "Creating bootable ISO..."
    
    local iso_name="${ISO_NAME:-mros-linux-1.0.0-amd64.iso}"
    local iso_path="$WORK_DIR/$iso_name"
    
    # Create hybrid ISO
    xorriso -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "${NAME:-mros-linux}" \
        -eltorito-boot boot/grub/bios.img \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        --eltorito-catalog boot/grub/boot.cat \
        --grub2-boot-info \
        --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
        -eltorito-alt-boot \
        -e EFI/BOOT/grubx64.efi \
        -no-emul-boot \
        -append_partition 2 0xef isolinux/efiboot.img \
        -output "$iso_path" \
        -graft-points \
            "." \
            /boot/grub/bios.img=boot/grub/bios.img \
            /EFI/BOOT/grubx64.efi=EFI/BOOT/grubx64.efi \
            "$IMAGE_DIR"
    
    # Create checksums
    cd "$WORK_DIR"
    sha256sum "$iso_name" > "${iso_name}.sha256"
    md5sum "$iso_name" > "${iso_name}.md5"
    
    log_success "ISO created: $iso_path"
    log_info "Size: $(du -h "$iso_path" | cut -f1)"
    log_info "SHA256: $(cat "${iso_path}.sha256" | cut -d' ' -f1)"
}

# Upload ISO to bashupload.com
upload_iso() {
    log_info "Uploading ISO to bashupload.com..."
    
    local iso_name="${ISO_NAME:-mros-linux-1.0.0-amd64.iso}"
    local iso_path="$WORK_DIR/$iso_name"
    
    if [[ -f "$iso_path" ]]; then
        # Use mros upload service
        if command -v mros-upload-service >/dev/null 2>&1; then
            mros-upload-service "$iso_path"
        else
            # Fallback to curl
            log_info "Uploading with curl..."
            local upload_url=$(curl -T "$iso_path" https://bashupload.com/"$iso_name" 2>/dev/null)
            if [[ $? -eq 0 && -n "$upload_url" ]]; then
                log_success "ISO uploaded successfully!"
                log_info "Download URL: $upload_url"
                echo "$upload_url" > "$WORK_DIR/download_url.txt"
            else
                log_error "Failed to upload ISO"
            fi
        fi
    else
        log_error "ISO file not found: $iso_path"
    fi
}

# Main build function
main() {
    log_info "Starting mros-linux build process..."
    
    # Load configuration
    load_config
    
    # Check prerequisites
    check_prerequisites
    
    # Setup build environment
    setup_build_env
    
    # Bootstrap and configure system
    bootstrap_system
    configure_base_system
    
    # Install packages and mros desktop
    install_packages
    install_mros_desktop
    install_themes
    
    # Configure system
    configure_system
    
    # Create ISO
    cleanup_chroot
    create_squashfs
    create_iso_structure
    create_iso
    
    # Upload ISO
    if [[ "${1:-}" == "--upload" ]]; then
        upload_iso
    fi
    
    log_success "mros-linux build completed successfully!"
    log_info "ISO location: $WORK_DIR/${ISO_NAME:-mros-linux-1.0.0-amd64.iso}"
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [--upload] [--help]"
        echo "  --upload    Upload ISO to bashupload.com after build"
        echo "  --help      Show this help message"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
