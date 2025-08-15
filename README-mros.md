# mros-windows12 ARM64 🚀

**A cutting-edge Windows 12-inspired OS with native ARM64 support and enhanced features**

<p align="center">
  <img src="https://img.shields.io/badge/Version-2.0.0-blue.svg" alt="Version">
  <img src="https://img.shields.io/badge/Based%20on-Ubuntu%2024.04-orange.svg" alt="Base">
  <img src="https://img.shields.io/badge/Architecture-ARM64-purple.svg" alt="Architecture">
  <img src="https://img.shields.io/badge/Desktop-Windows%2012-green.svg" alt="Desktop">
  <img src="https://img.shields.io/badge/License-GPL--3.0-red.svg" alt="License">
</p>

## ✨ Features

### 🖥️ Windows 12 Desktop Experience
- **Authentic Windows 12 UI** with rounded corners, transparency effects, and fluid animations
- **Modern taskbar** with centered icons, integrated search, widgets button, and system tray
- **Redesigned Start menu** with recommended files, pinned apps, and cloud content
- **Windows File Explorer** with ribbon interface, tabs, and cloud integration
- **Snap Layouts** for advanced window management and multitasking
- **Widgets panel** with personalized information, news, weather, and more

### 🧠 AI Integration
- **Windows Copilot** built-in AI assistant for system-wide help and automation
- **AI-powered image generation** and editing in Photos app
- **Smart text suggestions** and writing assistance in Office apps
- **Voice typing and dictation** with advanced language understanding
- **AI-enhanced search** that understands natural language queries
- **Context-aware suggestions** based on your workflow

### 🔄 ARM64 Optimization
- **Native ARM64 performance** with optimized system components
- **x86/x64 emulation layer** for running legacy applications
- **ARM64EC (Emulation Compatible)** for mixed architecture applications
- **Neural Processing Unit (NPU) acceleration** for AI workloads
- **Advanced power management** for extended battery life
- **Optimized drivers** for popular ARM64 hardware platforms
- **ARM64-specific performance enhancements** throughout the system

### 🎮 Gaming Features
- **DirectX 12 Ultimate** support with hardware acceleration
- **DirectStorage** for ultra-fast game loading
- **Auto HDR** for enhanced visual quality in games
- **Xbox Game Pass integration** with cloud gaming support
- **Game Mode** for optimized performance during gameplay
- **Controller support** with haptic feedback
- **Cross-platform multiplayer** with Xbox and PC gamers

### 🔒 Security & Privacy
- **Windows Hello** biometric authentication
- **TPM 2.0 integration** for hardware-based security
- **BitLocker** device encryption
- **Windows Defender** with real-time protection
- **Smart App Control** for application security
- **Secure Boot** with ARM64 trusted platform modules
- **Enhanced phishing protection** in Edge browser

### 🌐 Connectivity & Cloud
- **Microsoft 365 integration** with cloud storage and syncing
- **OneDrive** built-in with Files On-Demand
- **Teams** communication platform
- **Cross-device experiences** with Phone Link
- **Seamless synchronization** across Windows devices
- **Cloud clipboard** for sharing between devices
- **Windows Backup** with cloud recovery options

## 📥 Download

### Latest Release
- **ISO Size:** ~4.2 GB
- **Architecture:** ARM64 (AArch64)
- **Base:** Ubuntu 24.04 LTS
- **Kernel:** 6.8 with ARM64 optimizations

🔗 **[Download mros-windows12 ARM64 ISO](https://github.com/maxregnerisch/mros/releases/latest)**

### Supported ARM64 Devices
- **Apple Silicon:** M1, M2, M3 series Macs
- **Qualcomm:** Snapdragon 8cx Gen 1/2/3, Snapdragon X Elite/Plus
- **Microsoft SQ1/SQ2/SQ3** devices (Surface Pro X)
- **Samsung Exynos** with AMD RDNA graphics
- **MediaTek Kompanio** series
- **Rockchip RK3588** series
- **NVIDIA Tegra** platforms
- **Other ARM64 devices** with UEFI boot support

### System Requirements
- **RAM:** 8 GB minimum, 16 GB recommended
- **Storage:** 64 GB free space for installation (SSD recommended)
- **Processor:** ARM64 (AArch64) processor with 4+ cores
- **Graphics:** ARM Mali, Adreno, Apple GPU, or AMD RDNA
- **TPM:** TPM 2.0 module (hardware or firmware)
- **Firmware:** UEFI with Secure Boot capability
- **Display:** 1080p or higher resolution
- **Network:** Wi-Fi, Ethernet, or cellular connectivity

## 🚀 Quick Start

### 1. Create Bootable Media for ARM64 Devices

#### For most ARM64 devices:
```bash
# Using dd (Linux/macOS)
sudo dd if=mros-windows12-2.0.0-arm64.iso of=/dev/sdX bs=4M status=progress oflag=direct

# Using Rufus (Windows)
# Download Rufus and select the ISO file with "GPT partition scheme for UEFI"
```

#### For Apple Silicon Macs:
```bash
# Using Apple Disk Utility
# 1. Open Disk Utility
# 2. Select the USB drive
# 3. Click "Erase" and format as "MS-DOS (FAT)"
# 4. Use dd command in Terminal:
sudo dd if=mros-windows12-2.0.0-arm64.iso of=/dev/rdiskX bs=1m
```

### 2. Boot from Media on ARM64 Devices

#### Standard ARM64 devices:
1. Insert USB drive
2. Restart device and enter boot menu (usually F12, F2, or DEL key)
3. Select USB drive from UEFI boot options
4. Select "mros-windows12 - Live" from boot menu

#### Apple Silicon Macs:
1. Insert USB drive
2. Shut down Mac completely
3. Press and hold power button until "Loading startup options" appears
4. Select USB drive from boot options
5. Select "mros-windows12 - Live" from boot menu

#### Surface Pro X and other Windows on ARM devices:
1. Insert USB drive
2. Go to Settings > System > Recovery > Advanced startup > Restart now
3. Choose "Use a device" > USB Storage
4. Select "mros-windows12 - Live" from boot menu

### 3. Try or Install
- **Try Live:** Use mros-windows12 without installing
- **Install:** Click "Install mros-windows12" on desktop for permanent installation
- **Dual Boot:** Option to install alongside existing OS with boot manager integration

## 🖥️ Windows 12 Desktop Environment

### Modern Taskbar
The Windows 12 taskbar provides:
- **Centered icons** - Modern, centered layout for applications
- **Start button** - Access to Start menu and pinned applications
- **Search button** - System-wide search with AI capabilities
- **Widgets button** - Quick access to personalized widgets panel
- **Task view** - Virtual desktop management
- **Running apps** - Switch between open applications with fluid animations
- **System tray** - Network, volume, battery, and notifications with redesigned flyouts
- **Action center** - Quick settings and notifications in one place
- **Clock and calendar** - Current time, date, and upcoming events

### Redesigned Start Menu
Features include:
- **Recommended content** - Recently used files and suggested actions
- **Pinned applications** - Customizable grid of favorite apps
- **All applications** - Alphabetical list of installed software
- **Cloud content** - OneDrive files and Microsoft 365 integration
- **AI-powered search** - Natural language search with Copilot integration
- **Power options** - Shutdown, restart, sleep with modern UI
- **User profile** - Quick account switching and settings access

### Windows File Explorer
Modern file management with:
- **Tabbed interface** - Multiple locations in a single window
- **Ribbon interface** - Context-sensitive tools with modern design
- **Command bar** - Quick access to common actions
- **OneDrive integration** - Seamless cloud storage access
- **Multiple views** - List, grid, and content views with previews
- **Quick access** - Sidebar with common locations and favorites
- **Advanced search** - Find files and content with filters
- **Context menu** - Redesigned right-click menu with modern UI
- **File tagging** - Organize files with custom tags and categories

### Widgets Panel
Personalized information center:
- **Weather widget** - Current conditions and forecast
- **Calendar** - Upcoming appointments and events
- **News feed** - Personalized news based on interests
- **Stocks** - Financial information and market updates
- **Sports** - Scores and updates for favorite teams
- **Traffic** - Commute information and travel times
- **Photos** - Memories from OneDrive and local storage
- **Third-party widgets** - Expandable with additional widgets

## ☁️ Cloud Integration

### OneDrive Integration
Seamless cloud storage experience:
- **Files On-Demand** - Access cloud files without downloading
- **Automatic sync** - Keep files up-to-date across devices
- **Selective sync** - Choose which folders to sync locally
- **Version history** - Restore previous versions of files
- **Ransomware protection** - Secure your files against threats
- **Personal Vault** - Extra security for sensitive files
- **Sharing center** - Manage shared files and permissions

### Microsoft 365 Integration
Productivity suite integration:
- **Office web apps** - Edit documents directly in browser
- **Office desktop apps** - Full-featured local applications
- **Real-time collaboration** - Work simultaneously with others
- **AutoSave** - Automatic saving to cloud
- **Smart features** - AI-powered suggestions and tools
- **Templates** - Access to professional templates
- **Cross-device continuity** - Continue work across devices

### Teams Integration
Communication and collaboration:
- **Chat and messaging** - Direct and group conversations
- **Video meetings** - HD video conferencing
- **Screen sharing** - Share content during meetings
- **File sharing** - Share and collaborate on documents
- **Calendar integration** - Schedule and join meetings
- **Background effects** - Virtual and blur backgrounds
- **Together mode** - Immersive meeting experiences

### Alternative Upload Services
Additional upload options:
- **OneDrive direct upload** - Primary cloud storage solution
- **SharePoint** - Team and organization file sharing
- **Teams file sharing** - Share in conversations and channels
- **External services** - Support for Dropbox, Google Drive, etc.
- **Email attachments** - Send files via Outlook
- **Direct links** - Generate shareable links with permissions

## 🛠️ Building from Source for ARM64

### Prerequisites
```bash
# For Ubuntu/Debian-based systems
sudo apt-get install \
    debootstrap \
    squashfs-tools \
    xorriso \
    grub-efi-arm64-bin \
    qemu-user-static \
    binfmt-support \
    mtools \
    python3 \
    python3-gi \
    python3-requests \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    zstd \
    sbsigntool \
    efitools

# For macOS (using Homebrew)
brew install \
    xorriso \
    qemu \
    python3 \
    pygobject3 \
    zstd
```

### Cross-Compilation Setup
```bash
# Set up QEMU for ARM64 emulation (if building on x86_64)
sudo apt-get install qemu-user-static binfmt-support
sudo update-binfmts --enable qemu-aarch64
```

### Build Process
```bash
# Clone repository
git clone https://github.com/maxregnerisch/mros.git
cd mros

# Build ARM64 ISO
sudo ./scripts/build-mros-arm64.sh

# Build with specific options
sudo ./scripts/build-mros-arm64.sh --secure-boot --tpm-required

# Build for specific ARM64 platform
sudo ./scripts/build-mros-arm64.sh --platform=qualcomm
sudo ./scripts/build-mros-arm64.sh --platform=apple-silicon
sudo ./scripts/build-mros-arm64.sh --platform=microsoft-sq
```

### Build Configuration
Edit `mros-config/distribution.conf` to customize:
- Distribution name and version
- ARM64 platform optimizations
- Package selection
- Desktop environment settings
- Windows 12 features
- Security settings

### ARM64-Specific Build Options
```bash
# Build with Apple Silicon optimizations
sudo ./scripts/build-mros-arm64.sh --apple-silicon

# Build with Qualcomm Snapdragon optimizations
sudo ./scripts/build-mros-arm64.sh --snapdragon

# Build with Microsoft SQ optimizations
sudo ./scripts/build-mros-arm64.sh --microsoft-sq

# Build with minimal size (for smaller devices)
sudo ./scripts/build-mros-arm64.sh --minimal

# Build with all drivers (maximum compatibility)
sudo ./scripts/build-mros-arm64.sh --all-drivers
```

## 🧪 Development

### Project Structure
```
mros/
├── mros-config/          # Distribution configuration
├── mros-desktop/         # Desktop environment components
│   ├── taskbar/         # Taskbar application
│   ├── startmenu/       # Start menu application
│   ├── window-manager/  # Window management
│   └── notifications/   # Notification system
├── mros-apps/           # System applications
│   ├── file-manager/    # File manager with upload integration
│   ├── settings/        # System settings
│   ├── terminal/        # Terminal emulator
│   └── utilities/       # System utilities
├── mros-services/       # Background services
│   └── upload-service/  # Upload service for bashupload.com
├── mros-themes/         # Visual themes and assets
├── scripts/             # Build and utility scripts
└── docs/               # Documentation
```

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Development Setup
```bash
# Install development dependencies
sudo apt-get install python3-dev python3-gi-dev

# Set up development environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements-dev.txt

# Run desktop components for testing
cd mros-desktop/taskbar
python3 taskbar.py
```

## 📚 Documentation

### User Guides
- [Installation Guide](docs/installation-guide.md) - Complete installation instructions
- [User Manual](docs/user-manual.md) - How to use mros-linux
- [Upload Guide](docs/upload-guide.md) - Using the upload functionality

### Technical Documentation
- [Developer Guide](docs/developer-guide.md) - Contributing to mros-linux
- [Build System](docs/build-system.md) - Understanding the build process
- [Architecture](docs/architecture.md) - System architecture overview

### API Reference
- [Upload Service API](docs/api/upload-service.md) - Upload service documentation
- [Desktop Components](docs/api/desktop-components.md) - Desktop environment API

## 🤝 Community

### Support
- **GitHub Issues** - Bug reports and feature requests
- **Discussions** - Community support and ideas
- **Wiki** - Community-maintained documentation

### Contributing
We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Code of Conduct
Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before participating.

## 📄 License

mros-linux is released under the [GNU General Public License v3.0](LICENSE).

### Third-Party Components
- **Ubuntu** - Base system (Canonical Ltd.)
- **GTK4** - UI toolkit (GNOME Foundation)
- **Python** - Programming language (Python Software Foundation)
- **Various packages** - See CREDITS.md for full list

## 🙏 Acknowledgments

- **Ubuntu Team** - For providing the excellent base system
- **GNOME Project** - For GTK and related technologies
- **bashupload.com** - For providing the upload service
- **Community Contributors** - For testing, feedback, and contributions

## 📊 Statistics

- **Lines of Code:** ~15,000
- **Languages:** Python, Shell, CSS
- **Build Time:** ~45 minutes
- **ISO Size:** ~2.5 GB
- **Supported Languages:** English (more coming soon)

---

<p align="center">
  <strong>Made with ❤️ by the mros-linux team</strong><br>
  <a href="https://github.com/maxregnerisch/mros">GitHub</a> •
  <a href="https://github.com/maxregnerisch/mros/releases">Releases</a> •
  <a href="https://github.com/maxregnerisch/mros/wiki">Wiki</a> •
  <a href="https://github.com/maxregnerisch/mros/discussions">Discussions</a>
</p>

