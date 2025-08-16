#!/bin/bash
# ARM64 Platform Detection Script for mros-windows12
# This script detects the ARM64 platform and loads the appropriate drivers

set -e

# Log file
LOG_FILE="/var/log/mros-platform-detection.log"

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

log "Starting ARM64 platform detection..."

# Detect Apple Silicon
detect_apple_silicon() {
    if grep -q "Apple" /proc/cpuinfo 2>/dev/null || [ -d "/sys/firmware/devicetree/base/compatible" ] && grep -q "apple" /sys/firmware/devicetree/base/compatible 2>/dev/null; then
        log "Detected Apple Silicon platform"
        return 0
    fi
    return 1
}

# Detect Qualcomm Snapdragon
detect_qualcomm() {
    if grep -q "Qualcomm" /proc/cpuinfo 2>/dev/null || grep -q "Snapdragon" /proc/cpuinfo 2>/dev/null; then
        log "Detected Qualcomm Snapdragon platform"
        return 0
    fi
    return 1
}

# Detect Microsoft SQ
detect_microsoft_sq() {
    if grep -q "Microsoft SQ" /proc/cpuinfo 2>/dev/null || dmidecode -t system | grep -q "Surface" 2>/dev/null; then
        log "Detected Microsoft SQ platform"
        return 0
    fi
    return 1
}

# Detect MediaTek
detect_mediatek() {
    if grep -q "MediaTek" /proc/cpuinfo 2>/dev/null || grep -q "MT" /proc/cpuinfo 2>/dev/null; then
        log "Detected MediaTek platform"
        return 0
    fi
    return 1
}

# Detect Rockchip
detect_rockchip() {
    if grep -q "Rockchip" /proc/cpuinfo 2>/dev/null || grep -q "RK" /proc/cpuinfo 2>/dev/null; then
        log "Detected Rockchip platform"
        return 0
    fi
    return 1
}

# Detect NVIDIA Tegra
detect_nvidia_tegra() {
    if grep -q "NVIDIA" /proc/cpuinfo 2>/dev/null || grep -q "Tegra" /proc/cpuinfo 2>/dev/null; then
        log "Detected NVIDIA Tegra platform"
        return 0
    fi
    return 1
}

# Load platform-specific drivers
load_platform_drivers() {
    local platform="$1"
    log "Loading drivers for $platform platform..."
    
    # Source platform-specific configuration
    if [ -f "/usr/share/mros/drivers/arm64/$platform/config.sh" ]; then
        source "/usr/share/mros/drivers/arm64/$platform/config.sh"
    fi
    
    # Load platform-specific drivers
    if [ -f "/usr/share/mros/drivers/arm64/$platform/load-drivers.sh" ]; then
        bash "/usr/share/mros/drivers/arm64/$platform/load-drivers.sh"
    fi
    
    log "Drivers for $platform platform loaded successfully"
}

# Main detection logic
if detect_apple_silicon; then
    load_platform_drivers "apple"
elif detect_qualcomm; then
    load_platform_drivers "qualcomm"
elif detect_microsoft_sq; then
    load_platform_drivers "microsoft"
elif detect_mediatek; then
    load_platform_drivers "mediatek"
elif detect_rockchip; then
    load_platform_drivers "rockchip"
elif detect_nvidia_tegra; then
    load_platform_drivers "nvidia"
else
    log "Unknown ARM64 platform detected, loading generic drivers"
    load_platform_drivers "generic"
fi

log "ARM64 platform detection completed"
exit 0

