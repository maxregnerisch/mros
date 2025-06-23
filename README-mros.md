# mros-linux 🚀

**A modern Linux distribution with Windows 12-inspired UI and integrated cloud upload functionality**

<p align="center">
  <img src="https://img.shields.io/badge/Version-1.0.0-blue.svg" alt="Version">
  <img src="https://img.shields.io/badge/Based%20on-Ubuntu%2022.04-orange.svg" alt="Base">
  <img src="https://img.shields.io/badge/Desktop-mros--desktop-green.svg" alt="Desktop">
  <img src="https://img.shields.io/badge/License-GPL--3.0-red.svg" alt="License">
</p>

## ✨ Features

### 🖥️ Modern Desktop Environment
- **Windows 12-inspired UI** with rounded corners, transparency effects, and modern animations
- **Custom taskbar** with integrated search, running applications, and system tray
- **Start menu** with pinned apps, search functionality, and quick access to system tools
- **Modern file manager** with ribbon interface and cloud upload integration

### ☁️ Integrated Upload Functionality
- **One-click upload** to bashupload.com directly from the file manager
- **Upload manager** with progress tracking and history
- **Automatic URL copying** to clipboard after successful uploads
- **Batch upload support** for multiple files and folders

### 🎨 Visual Design
- **Blur effects** and transparency throughout the interface
- **Smooth animations** and transitions
- **Consistent theming** across all applications
- **Modern iconography** and typography

### 🛠️ System Features
- **Live CD** - Boot directly from USB/DVD without installation
- **Full installation** support with guided installer
- **Hardware detection** and automatic driver installation
- **Pre-installed applications** including Firefox, LibreOffice, GIMP, and more

## 📥 Download

### Latest Release
- **ISO Size:** ~2.5 GB
- **Architecture:** x86_64 (64-bit)
- **Base:** Ubuntu 22.04 LTS

🔗 **[Download mros-linux ISO](https://github.com/maxregnerisch/mros/releases/latest)**

### System Requirements
- **RAM:** 4 GB minimum, 8 GB recommended
- **Storage:** 25 GB free space for installation
- **Processor:** 64-bit x86 processor
- **Graphics:** DirectX 9 compatible or better

## 🚀 Quick Start

### 1. Create Bootable Media
```bash
# Using dd (Linux/macOS)
sudo dd if=mros-linux-1.0.0-amd64.iso of=/dev/sdX bs=4M status=progress

# Using Rufus (Windows)
# Download Rufus and select the ISO file
```

### 2. Boot from Media
1. Insert USB drive or DVD
2. Restart computer and boot from media
3. Select "mros-linux - Live" from boot menu
4. Wait for desktop to load

### 3. Try or Install
- **Try Live:** Use mros-linux without installing
- **Install:** Click "Install mros-linux" on desktop for permanent installation

## 🖥️ Desktop Environment

### Taskbar
The mros taskbar provides:
- **Start button** - Access applications and system functions
- **Search bar** - Find apps, files, and web content
- **Running apps** - Switch between open applications
- **System tray** - Network, volume, battery, and notifications
- **Clock** - Current time and date

### Start Menu
Features include:
- **Pinned applications** - Quick access to favorite apps
- **All applications** - Browse installed software
- **Search functionality** - Find anything quickly
- **Power options** - Shutdown, restart, sleep
- **Upload button** - Quick access to upload manager

### File Manager
Modern file management with:
- **Ribbon interface** - Context-sensitive tools
- **Cloud upload** - Direct integration with bashupload.com
- **Multiple views** - List, grid, and thumbnail views
- **Quick access** - Sidebar with common locations
- **Search** - Find files and folders instantly

## ☁️ Upload Functionality

### Upload Service
The integrated upload service provides:
- **Drag & drop** upload from file manager
- **Right-click context menu** for quick uploads
- **Progress tracking** with notifications
- **Upload history** with download links
- **Automatic clipboard** copying of URLs

### Upload Manager
Manage your uploads with:
- **Upload queue** - See active and pending uploads
- **History view** - Access previous uploads
- **Settings** - Configure upload preferences
- **Batch operations** - Upload multiple files/folders

### Supported Upload Types
- **Individual files** - Any file type up to 500MB
- **Multiple files** - Batch upload with progress tracking
- **Folders** - Recursive upload of entire directories
- **Archives** - Automatic compression for folder uploads

## 🛠️ Building from Source

### Prerequisites
```bash
sudo apt-get install \\
    debootstrap \\
    squashfs-tools \\
    xorriso \\
    grub-pc-bin \\
    grub-efi-amd64-bin \\
    mtools \\
    python3 \\
    python3-gi \\
    python3-requests
```

### Build Process
```bash
# Clone repository
git clone https://github.com/maxregnerisch/mros.git
cd mros

# Build ISO
sudo ./scripts/build-mros.sh

# Build and upload to bashupload.com
sudo ./scripts/build-mros.sh --upload
```

### Build Configuration
Edit `mros-config/distribution.conf` to customize:
- Distribution name and version
- Package selection
- Desktop environment settings
- Upload service configuration

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

