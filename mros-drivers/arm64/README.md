# ARM64 Drivers for mros-windows12

This directory contains platform-specific drivers and configurations for various ARM64 platforms supported by mros-windows12.

## Supported Platforms

### Apple Silicon
- M1, M2, M3 series Macs
- Drivers for Apple GPU, Neural Engine, and other Apple-specific hardware

### Qualcomm
- Snapdragon 8cx Gen 1/2/3
- Snapdragon X Elite/Plus
- Adreno GPU drivers
- Hexagon DSP drivers

### Microsoft
- SQ1/SQ2/SQ3 processors (Surface Pro X)
- Microsoft-specific firmware and drivers

### MediaTek
- Kompanio series
- Mali GPU drivers

### Rockchip
- RK3588 series
- Mali GPU drivers

### NVIDIA
- Tegra platforms
- NVIDIA GPU drivers

## Driver Installation

The appropriate drivers are automatically detected and installed during the boot process based on the detected hardware platform.

## Adding New Drivers

To add support for a new ARM64 platform:

1. Create a new directory under the appropriate platform folder
2. Add the necessary driver files and configuration
3. Update the platform detection script to recognize the new hardware
4. Test on the target platform

## Platform Detection

The platform detection script (`detect-platform.sh`) automatically identifies the ARM64 platform and loads the appropriate drivers during system boot.

