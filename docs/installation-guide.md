# mros-linux Installation Guide

This guide will walk you through installing mros-linux on your computer.

## System Requirements

### Minimum Requirements
- **Processor:** 64-bit x86 processor (Intel/AMD)
- **RAM:** 4 GB
- **Storage:** 25 GB free space
- **Graphics:** DirectX 9 compatible graphics card
- **Network:** Internet connection (recommended)

### Recommended Requirements
- **Processor:** Dual-core 2.0 GHz or faster
- **RAM:** 8 GB or more
- **Storage:** 50 GB free space (SSD recommended)
- **Graphics:** Modern graphics card with hardware acceleration
- **Network:** Broadband internet connection

## Download mros-linux

1. Visit the [mros-linux releases page](https://github.com/maxregnerisch/mros/releases)
2. Download the latest ISO file (e.g., `mros-linux-1.0.0-amd64.iso`)
3. Verify the download using the provided checksums

### Verify Download (Optional but Recommended)
```bash
# Check SHA256 checksum
sha256sum mros-linux-1.0.0-amd64.iso
# Compare with the provided checksum

# Check MD5 checksum
md5sum mros-linux-1.0.0-amd64.iso
# Compare with the provided checksum
```

## Create Installation Media

### Option 1: USB Drive (Recommended)

#### On Linux
```bash
# Find your USB device
lsblk

# Create bootable USB (replace /dev/sdX with your USB device)
sudo dd if=mros-linux-1.0.0-amd64.iso of=/dev/sdX bs=4M status=progress oflag=sync

# Alternative using cp
sudo cp mros-linux-1.0.0-amd64.iso /dev/sdX
sync
```

#### On Windows
1. Download [Rufus](https://rufus.ie/) or [balenaEtcher](https://www.balena.io/etcher/)
2. Insert USB drive (8GB or larger)
3. Open Rufus/Etcher
4. Select the mros-linux ISO file
5. Select your USB drive
6. Click "Start" or "Flash"

#### On macOS
```bash
# Find your USB device
diskutil list

# Unmount the USB drive (replace diskX with your USB device)
diskutil unmountDisk /dev/diskX

# Create bootable USB
sudo dd if=mros-linux-1.0.0-amd64.iso of=/dev/rdiskX bs=4m

# Eject the USB drive
diskutil eject /dev/diskX
```

### Option 2: DVD
1. Use your preferred DVD burning software
2. Burn the ISO file to a DVD-R or DVD+R disc
3. Verify the burn was successful

## Boot from Installation Media

### Configure BIOS/UEFI
1. Insert the USB drive or DVD
2. Restart your computer
3. Enter BIOS/UEFI setup (usually F2, F12, Del, or Esc during startup)
4. Navigate to Boot settings
5. Set USB/DVD as first boot device
6. Save and exit

### Boot Menu
1. Restart your computer
2. Press the boot menu key (usually F12, F11, or Esc)
3. Select your USB drive or DVD from the list
4. Press Enter

## Installation Process

### 1. Boot Screen
When mros-linux starts, you'll see the boot menu:
- **mros-linux - Live**: Boot into live environment
- **mros-linux - Live (safe mode)**: Boot with basic graphics drivers

Select the first option and press Enter.

### 2. Live Desktop
After booting, you'll see the mros desktop:
- The system is running from the USB/DVD
- You can test all features before installing
- Your changes won't be saved unless you install

### 3. Start Installation
1. Double-click "Install mros-linux" on the desktop
2. Or click the Start button → Install mros-linux

### 4. Language and Region
1. Select your language
2. Choose your region/timezone
3. Select keyboard layout
4. Click "Continue"

### 5. Installation Type
Choose your installation type:

#### Option A: Erase Disk and Install (Recommended for new users)
- **Warning**: This will erase all data on the selected disk
- Select the disk to install on
- Click "Install Now"

#### Option B: Manual Partitioning (Advanced users)
- Create custom partitions
- Recommended partition scheme:
  - `/` (root): 20-30 GB (ext4)
  - `/home`: Remaining space (ext4)
  - `swap`: 2-4 GB (swap)
  - `/boot/efi`: 512 MB (FAT32, for UEFI systems)

### 6. User Account
1. Enter your full name
2. Choose a username (lowercase, no spaces)
3. Set a strong password
4. Confirm password
5. Choose computer name
6. Select login options:
   - Require password to log in (recommended)
   - Log in automatically
   - Encrypt home folder (optional)

### 7. Installation Progress
- The installer will copy files and configure the system
- This typically takes 15-30 minutes
- You can continue using the live system during installation

### 8. Installation Complete
1. Click "Restart Now"
2. Remove the USB drive or DVD when prompted
3. Press Enter to restart

## First Boot

### 1. Initial Setup
After restarting, mros-linux will boot from your hard drive:
1. Select "mros Desktop" from the login screen (if multiple options)
2. Enter your username and password
3. Press Enter or click "Sign In"

### 2. Welcome Screen
The first boot will show a welcome screen:
- System information
- Quick tour of features
- Links to documentation
- Upload service setup

### 3. System Updates
1. Open the Start menu
2. Go to Settings → System → Updates
3. Click "Check for Updates"
4. Install any available updates
5. Restart if required

## Post-Installation Setup

### 1. Configure Upload Service
1. Open Upload Manager from Start menu
2. Go to Settings tab
3. Configure upload preferences:
   - Auto-copy URLs to clipboard
   - Show upload notifications
   - Upload history retention

### 2. Install Additional Software
1. Open Start menu → Software Center
2. Browse or search for applications
3. Click "Install" for desired software

Popular additions:
- **Development**: VS Code, Git, Docker
- **Media**: VLC, Spotify, OBS Studio
- **Graphics**: Inkscape, Blender, Krita
- **Games**: Steam, Lutris, RetroArch

### 3. Customize Desktop
1. Right-click on desktop → Settings
2. Customize:
   - Wallpaper and themes
   - Taskbar position and size
   - Start menu layout
   - Window effects and animations

### 4. Set Up File Sharing
1. Open File Manager
2. Go to Settings → Upload
3. Configure bashupload.com integration:
   - Default upload settings
   - File size limits
   - Auto-upload folders

## Troubleshooting

### Boot Issues

#### System Won't Boot from USB/DVD
- Verify the installation media was created correctly
- Check BIOS/UEFI boot order
- Try different USB ports
- Disable Secure Boot (if enabled)
- Try safe mode boot option

#### Black Screen After Boot
- Try safe mode boot option
- Check graphics card compatibility
- Update BIOS/UEFI firmware
- Try different display connection (HDMI, VGA, etc.)

### Installation Issues

#### Installation Fails
- Check system requirements
- Verify ISO file integrity (checksums)
- Try different installation media
- Check hard drive health
- Ensure sufficient free space

#### Partitioning Errors
- Use GParted to check disk health
- Backup important data first
- Try manual partitioning
- Check for disk encryption

### Hardware Issues

#### Wi-Fi Not Working
1. Open Terminal (Ctrl+Alt+T)
2. Check network devices: `lspci | grep -i network`
3. Install additional drivers: `sudo ubuntu-drivers autoinstall`
4. Restart system

#### Graphics Issues
1. Install proprietary drivers:
   - NVIDIA: `sudo apt install nvidia-driver-470`
   - AMD: Usually works out of the box
2. Restart system
3. Check Settings → Display for resolution options

#### Audio Issues
1. Check volume levels in system tray
2. Open Settings → Sound
3. Select correct output device
4. Install PulseAudio volume control: `sudo apt install pavucontrol`

## Getting Help

### Documentation
- [User Manual](user-manual.md) - Complete user guide
- [FAQ](faq.md) - Frequently asked questions
- [Troubleshooting](troubleshooting.md) - Common issues and solutions

### Community Support
- [GitHub Discussions](https://github.com/maxregnerisch/mros/discussions) - Community help
- [GitHub Issues](https://github.com/maxregnerisch/mros/issues) - Bug reports
- [Wiki](https://github.com/maxregnerisch/mros/wiki) - Community documentation

### Professional Support
For enterprise or professional support, contact the mros-linux team through GitHub.

## Next Steps

After successful installation:
1. Read the [User Manual](user-manual.md) to learn about mros-linux features
2. Explore the upload functionality with the [Upload Guide](upload-guide.md)
3. Join the community discussions to share feedback and get help
4. Consider contributing to the project if you're a developer

Welcome to mros-linux! 🎉

