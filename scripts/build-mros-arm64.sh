#!/bin/bash
# mros-windows12 ARM64 Build Script
# Build a complete mros-windows12 distribution with Windows 12-like UI for ARM64 architecture

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_DIR/mros-config/distribution.conf"

# Default values
WORK_DIR="${WORK_DIR:-$HOME/mros-build}"
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
        "isolinux"
        "syslinux-utils"
        "mtools"
        "python3"
        "python3-gi"
        "python3-requests"
        "qemu-user-static"
        "binfmt-support"
        "zstd"
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

# Bootstrap base system for ARM64
bootstrap_system() {
    log_info "Bootstrapping ARM64 base system..."
    
    local base_version="${BASE_VERSION:-24.04}"
    local architecture="${ARCHITECTURE:-arm64}"
    
    # Set up QEMU for ARM64 emulation
    sudo apt-get install -y qemu-user-static binfmt-support
    
    # Bootstrap the system
    sudo debootstrap \
        --arch="$architecture" \
        --variant=minbase \
        --components=main,restricted,universe,multiverse \
        --include=qemu-user-static \
        noble \
        "$CHROOT_DIR" \
        http://ports.ubuntu.com/ubuntu-ports/
    
    log_success "ARM64 base system bootstrapped"
}

# Configure base system
configure_base_system() {
    log_info "Configuring ARM64 base system..."
    
    # Copy DNS configuration
    sudo cp /etc/resolv.conf "$CHROOT_DIR/etc/"
    
    # Mount necessary filesystems
    sudo mount --bind /dev "$CHROOT_DIR/dev"
    sudo mount --bind /run "$CHROOT_DIR/run"
    sudo mount -t proc proc "$CHROOT_DIR/proc"
    sudo mount -t sysfs sysfs "$CHROOT_DIR/sys"
    sudo mount -t devpts devpts "$CHROOT_DIR/dev/pts"
    
    # Configure sources.list for ARM64
    cat <<EOF | sudo tee "$CHROOT_DIR/etc/apt/sources.list"
deb http://ports.ubuntu.com/ubuntu-ports/ noble main restricted universe multiverse
deb-src http://ports.ubuntu.com/ubuntu-ports/ noble main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ noble-security main restricted universe multiverse
deb-src http://ports.ubuntu.com/ubuntu-ports/ noble-security main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ noble-updates main restricted universe multiverse
deb-src http://ports.ubuntu.com/ubuntu-ports/ noble-updates main restricted universe multiverse
EOF
    
    # Update package lists
    sudo chroot "$CHROOT_DIR" apt-get update
    
    log_success "ARM64 base system configured"
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

# Install packages for ARM64
install_packages() {
    log_info "Installing packages for ARM64..."
    
    # Update package lists first
    sudo chroot "$CHROOT_DIR" apt-get update
    
    # Install essential packages
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
        linux-generic-arm64
    
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
        python3-cairo-dev \
        pipewire
    
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
    
    log_success "Packages installed for ARM64"
}

# Install ARM64 specific drivers
install_arm64_drivers() {
    log_info "Installing ARM64 specific drivers..."
    
    # Create ARM64 drivers directory
    sudo mkdir -p "$CHROOT_DIR/usr/share/mros/drivers/arm64"
    
    # Copy ARM64 drivers
    sudo cp -r "$PROJECT_DIR/mros-drivers/arm64"/* "$CHROOT_DIR/usr/share/mros/drivers/arm64/"
    
    # Make driver scripts executable
    sudo find "$CHROOT_DIR/usr/share/mros/drivers" -name "*.sh" -exec chmod +x {} \;
    
    log_success "ARM64 drivers installed"
}

# Install mros desktop environment
install_mros_desktop() {
    log_info "Installing mros-windows12 desktop environment..."
    
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
    
    log_success "mros-windows12 desktop environment installed"
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

    # Windows 12 specific launchers
    cat <<'EOF' | sudo tee "$CHROOT_DIR/usr/bin/mros-widgets"
#!/bin/bash
cd /usr/share/mros/desktop/windows12/widgets
python3 widgets.py "$@"
EOF

    cat <<'EOF' | sudo tee "$CHROOT_DIR/usr/bin/mros-action-center"
#!/bin/bash
cd /usr/share/mros/desktop/windows12/action-center
python3 action-center.py "$@"
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
    
    # Create mros.desktop file
    cat <<EOF | sudo tee "$CHROOT_DIR/usr/share/xsessions/mros-windows12.desktop"
[Desktop Entry]
Name=mros-windows12
Comment=Windows 12-inspired desktop environment for ARM64
Exec=/usr/bin/mros-session
Type=Application
EOF
    
    # Create mros-session script
    cat <<'EOF' | sudo tee "$CHROOT_DIR/usr/bin/mros-session"
#!/bin/bash
# Start mros-windows12 desktop session

# Start window manager
openbox &

# Start taskbar
mros-taskbar &

# Start Windows 12 widgets
mros-widgets &

# Start Windows 12 action center
mros-action-center &

# Start background services
mros-upload-service &

# Wait for window manager to exit
wait
EOF
    
    # Make session script executable
    sudo chmod +x "$CHROOT_DIR/usr/bin/mros-session"
    
    log_success "Desktop session created"
}

# Create autostart entries
create_autostart_entries() {
    log_info "Creating autostart entries..."
    
    # Create mros-taskbar autostart
    cat <<EOF | sudo tee "$CHROOT_DIR/etc/xdg/autostart/mros-taskbar.desktop"
[Desktop Entry]
Type=Application
Name=mros Taskbar
Comment=Windows 12-inspired taskbar
Exec=mros-taskbar
Terminal=false
Categories=Utility;
EOF
    
    # Create mros-upload-service autostart
    cat <<EOF | sudo tee "$CHROOT_DIR/etc/xdg/autostart/mros-upload-service.desktop"
[Desktop Entry]
Type=Application
Name=mros Upload Service
Comment=Background service for file uploads
Exec=mros-upload-service
Terminal=false
Categories=Utility;
EOF

    # Create Windows 12 widgets autostart
    cat <<EOF | sudo tee "$CHROOT_DIR/etc/xdg/autostart/mros-widgets.desktop"
[Desktop Entry]
Type=Application
Name=Windows 12 Widgets
Comment=Windows 12-inspired widgets panel
Exec=mros-widgets
Terminal=false
Categories=Utility;
EOF

    # Create Windows 12 action center autostart
    cat <<EOF | sudo tee "$CHROOT_DIR/etc/xdg/autostart/mros-action-center.desktop"
[Desktop Entry]
Type=Application
Name=Windows 12 Action Center
Comment=Windows 12-inspired action center
Exec=mros-action-center
Terminal=false
Categories=Utility;
EOF
    
    log_success "Autostart entries created"
}

# Install themes
install_themes() {
    log_info "Installing Windows 12 themes..."
    
    # Create theme directories
    sudo mkdir -p "$CHROOT_DIR/usr/share/themes"
    sudo mkdir -p "$CHROOT_DIR/usr/share/icons"
    
    # Copy Windows 12 theme
    sudo cp -r "$PROJECT_DIR/mros-themes/windows12-theme" "$CHROOT_DIR/usr/share/themes/Windows12"
    
    # Set default theme
    sudo mkdir -p "$CHROOT_DIR/etc/skel/.config/gtk-4.0"
    cat <<EOF | sudo tee "$CHROOT_DIR/etc/skel/.config/gtk-4.0/settings.ini"
[Settings]
gtk-theme-name=Windows12
gtk-icon-theme-name=Windows12
gtk-font-name=Segoe UI 10
gtk-cursor-theme-name=Windows12
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
EOF
    
    log_success "Windows 12 themes installed"
}

# Configure system
configure_system() {
    log_info "Configuring system..."
    
    # Set hostname
    echo "${NAME:-mros-windows12}" | sudo tee "$CHROOT_DIR/etc/hostname"
    
    # Configure hosts file
    cat <<EOF | sudo tee "$CHROOT_DIR/etc/hosts"
127.0.0.1 localhost
127.0.1.1 ${NAME:-mros-windows12}

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF
    
    # Configure live user
    sudo chroot "$CHROOT_DIR" useradd -m -s /bin/bash "${LIVE_USER:-windows}"
    echo "${LIVE_USER:-windows}:${LIVE_PASSWORD:-live}" | sudo chroot "$CHROOT_DIR" chpasswd
    
    # Add live user to sudo group
    sudo chroot "$CHROOT_DIR" usermod -aG sudo "${LIVE_USER:-windows}"
    
    # Configure autologin
    if [[ "${AUTO_LOGIN:-true}" == "true" ]]; then
        sudo mkdir -p "$CHROOT_DIR/etc/lightdm"
        cat <<EOF | sudo tee "$CHROOT_DIR/etc/lightdm/lightdm.conf"
[SeatDefaults]
autologin-user=${LIVE_USER:-windows}
autologin-user-timeout=0
user-session=mros-windows12
EOF
    fi
    
    # Configure casper for live system
    sudo chroot "$CHROOT_DIR" apt-get install -y casper
    
    log_success "System configured"
}

# Cleanup chroot before creating squashfs
cleanup_chroot() {
    log_info "Cleaning up chroot..."
    
    # Remove apt cache
    sudo chroot "$CHROOT_DIR" apt-get clean
    
    # Remove temporary files
    sudo rm -rf "$CHROOT_DIR/tmp"/*
    
    # Unmount filesystems
    sudo umount -lf "$CHROOT_DIR/dev/pts" 2>/dev/null || true
    sudo umount -lf "$CHROOT_DIR/dev" 2>/dev/null || true
    sudo umount -lf "$CHROOT_DIR/proc" 2>/dev/null || true
    sudo umount -lf "$CHROOT_DIR/sys" 2>/dev/null || true
    sudo umount -lf "$CHROOT_DIR/run" 2>/dev/null || true
    
    log_success "Chroot cleaned up"
}

# Create squashfs filesystem
create_squashfs() {
    log_info "Creating squashfs filesystem..."
    
    # Check if ISO structure exists
    if [[ ! -d "$IMAGE_DIR/casper" ]]; then
        log_error "ISO structure not found. Make sure create_iso_structure() is called before create_squashfs()"
        exit 1
    fi
    
    local compression="${COMPRESSION:-zstd}"
    local compression_level="${COMPRESSION_LEVEL:-19}"
    
    # Remove existing filesystem.squashfs if it exists
    if [[ -f "$IMAGE_DIR/casper/filesystem.squashfs" ]]; then
        log_info "Removing existing filesystem.squashfs..."
        sudo rm -f "$IMAGE_DIR/casper/filesystem.squashfs"
    fi
    
    log_info "Creating squashfs with compression: $compression"
    sudo mksquashfs \
        "$CHROOT_DIR" \
        "$IMAGE_DIR/casper/filesystem.squashfs" \
        -comp "$compression" \
        -processors $(nproc)
    
    if [[ ! -f "$IMAGE_DIR/casper/filesystem.squashfs" ]]; then
        log_error "Failed to create filesystem.squashfs"
        exit 1
    fi
    
    # Create filesystem.size
    log_info "Creating filesystem.size..."
    printf $(sudo du -sx --block-size=1 "$CHROOT_DIR" | cut -f1) | sudo tee "$IMAGE_DIR/casper/filesystem.size"
    
    log_success "Squashfs filesystem created successfully"
    log_info "Filesystem size: $(ls -lh "$IMAGE_DIR/casper/filesystem.squashfs" | awk '{print $5}')"
}

# Install GRUB for ARM64
install_grub_files() {
    log_info "Installing boot files for ARM64..."
    
    # Create EFI directory
    sudo mkdir -p "$IMAGE_DIR/EFI/BOOT"
    
    # Copy GRUB EFI files for ARM64
    if [[ -f /usr/lib/grub/arm64-efi/grub.efi ]]; then
        sudo cp /usr/lib/grub/arm64-efi/grub.efi "$IMAGE_DIR/EFI/BOOT/BOOTAA64.EFI"
    else
        log_warning "GRUB EFI file for ARM64 not found, trying alternative locations..."
        # Try alternative locations
        for path in /usr/share/grub /boot/grub; do
            if [[ -f "$path/arm64-efi/grub.efi" ]]; then
                sudo cp "$path/arm64-efi/grub.efi" "$IMAGE_DIR/EFI/BOOT/BOOTAA64.EFI"
                break
            fi
        done
    fi
    
    # Create GRUB configuration
    create_grub_config
    
    log_success "Boot files installed for ARM64"
}

# Create GRUB configuration for ARM64
create_grub_config() {
    log_info "Creating GRUB configuration for ARM64..."
    
    # Create GRUB directory
    sudo mkdir -p "$IMAGE_DIR/boot/grub"
    
    # Create grub.cfg
    cat <<EOF | sudo tee "$IMAGE_DIR/boot/grub/grub.cfg"
set default=0
set timeout=10

menuentry "Start ${NAME:-mros-windows12} ARM64" {
    linux /casper/vmlinuz boot=casper quiet splash ---
    initrd /casper/initrd
}

menuentry "Start ${NAME:-mros-windows12} ARM64 (safe mode)" {
    linux /casper/vmlinuz boot=casper xforcevesa nomodeset quiet splash ---
    initrd /casper/initrd
}

menuentry "Check disc for defects" {
    linux /casper/vmlinuz boot=casper integrity-check quiet splash ---
    initrd /casper/initrd
}
EOF
    
    # Copy grub.cfg to EFI directory
    sudo cp "$IMAGE_DIR/boot/grub/grub.cfg" "$IMAGE_DIR/EFI/BOOT/"
    
    log_success "GRUB configuration created for ARM64"
}

# Create ISO structure
create_iso_structure() {
    log_info "Creating ISO structure for ARM64..."
    
    # Create directories
    log_info "Creating directory structure..."
    mkdir -p "$IMAGE_DIR"/{casper,boot/grub,EFI/BOOT,.disk}
    
    # Verify directories were created
    for dir in casper boot/grub EFI/BOOT .disk; do
        if [[ ! -d "$IMAGE_DIR/$dir" ]]; then
            log_error "Failed to create directory: $IMAGE_DIR/$dir"
            exit 1
        fi
    done
    
    # Copy kernel and initrd
    log_info "Copying kernel and initrd..."
    if ! sudo cp "$CHROOT_DIR/boot/vmlinuz-"* "$IMAGE_DIR/casper/vmlinuz" 2>/dev/null; then
        log_error "Failed to copy kernel from $CHROOT_DIR/boot/"
        log_error "Available files:"
        ls -la "$CHROOT_DIR/boot/" || true
        exit 1
    fi
    
    if ! sudo cp "$CHROOT_DIR/boot/initrd.img-"* "$IMAGE_DIR/casper/initrd" 2>/dev/null; then
        log_error "Failed to copy initrd from $CHROOT_DIR/boot/"
        log_error "Available files:"
        ls -la "$CHROOT_DIR/boot/" || true
        exit 1
    fi
    
    # Create disk info
    create_disk_info
    
    log_success "ISO structure created for ARM64"
}

# Create disk info
create_disk_info() {
    log_info "Creating disk info..."
    
    # Create .disk directory files
    echo "${NAME:-mros-windows12} ${VERSION:-2.0.0} ARM64" > "$IMAGE_DIR/.disk/info"
    echo "${NAME:-mros-windows12}" > "$IMAGE_DIR/.disk/release_notes_url"
    touch "$IMAGE_DIR/.disk/base_installable"
    echo "full_cd/single" > "$IMAGE_DIR/.disk/cd_type"
    
    log_success "Disk info created"
}

# Create bootable ISO for ARM64
create_iso() {
    log_info "Creating bootable ISO for ARM64..."
    
    local iso_name="${ISO_NAME:-mros-windows12-2.0.0-arm64.iso}"
    local iso_path="$WORK_DIR/$iso_name"
    
    # Install GRUB boot files
    install_grub_files
    
    # Create ISO with UEFI boot for ARM64
    log_info "Creating ISO with UEFI boot for ARM64..."
    
    xorriso -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "MROS-WIN12-ARM64" \
        -eltorito-alt-boot \
        -e EFI/BOOT/BOOTAA64.EFI \
        -no-emul-boot \
        -append_partition 2 0xef "$IMAGE_DIR/EFI/BOOT/BOOTAA64.EFI" \
        -output "$iso_path" \
        "$IMAGE_DIR"
    
    # Create checksums
    log_success "ISO created: $iso_path"
    log_info "Size: $(du -h "$iso_path" | cut -f1)"
}

# Upload ISO to bashupload.com
upload_iso() {
    log_info "Uploading ISO to bashupload.com..."
    
    local iso_name="${ISO_NAME:-mros-windows12-2.0.0-arm64.iso}"
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
    log_info "Starting mros-windows12 ARM64 build process..."
    
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
    install_arm64_drivers
    install_mros_desktop
    install_themes
    
    # Configure system
    configure_system
    
    # Create ISO
    cleanup_chroot
    create_iso_structure
    create_squashfs
    create_iso
    
    # Upload ISO
    if [[ "${1:-}" == "--upload" ]]; then
        upload_iso
    fi
    
    log_success "mros-windows12 ARM64 build completed successfully!"
    log_info "ISO location: $WORK_DIR/${ISO_NAME:-mros-windows12-2.0.0-arm64.iso}"
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [--upload] [--platform=PLATFORM] [--help]"
        echo "  --upload              Upload ISO to bashupload.com after build"
        echo "  --platform=PLATFORM   Optimize for specific ARM64 platform (apple-silicon, snapdragon, microsoft-sq)"
        echo "  --help                Show this help message"
        exit 0
        ;;
    --platform=*)
        PLATFORM="${1#*=}"
        log_info "Building for ARM64 platform: $PLATFORM"
        main
        ;;
    *)
        main "$@"
        ;;
esac

