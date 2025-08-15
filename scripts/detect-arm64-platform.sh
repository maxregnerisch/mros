#!/bin/bash
#
# ARM64 Platform Detection Script for mros-windows12
# This script detects the ARM64 platform and loads appropriate drivers
#

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
DRIVERS_DIR="$ROOT_DIR/mros-drivers/arm64"
LOG_FILE="/var/log/mros-platform-detect.log"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Create log file
touch "$LOG_FILE"
log "Starting ARM64 platform detection"

# Function to detect Apple Silicon
detect_apple_silicon() {
    if [ -f /proc/device-tree/compatible ]; then
        if grep -q "apple" /proc/device-tree/compatible; then
            log "Detected Apple Silicon platform"
            
            # Determine specific model
            if grep -q "t8103" /proc/device-tree/compatible; then
                MODEL="M1"
            elif grep -q "t8112" /proc/device-tree/compatible; then
                MODEL="M2"
            elif grep -q "t8120" /proc/device-tree/compatible; then
                MODEL="M3"
            else
                MODEL="Unknown Apple Silicon"
            fi
            
            log "Apple Silicon model: $MODEL"
            return 0
        fi
    fi
    
    return 1
}

# Function to detect Qualcomm Snapdragon
detect_qualcomm() {
    if [ -f /proc/cpuinfo ]; then
        if grep -q "Qualcomm" /proc/cpuinfo || grep -q "Kryo" /proc/cpuinfo; then
            log "Detected Qualcomm Snapdragon platform"
            
            # Try to determine specific model
            if grep -q "SC8280" /sys/devices/soc0/soc_id 2>/dev/null; then
                MODEL="Snapdragon 8cx Gen 3"
            elif grep -q "SC8180" /sys/devices/soc0/soc_id 2>/dev/null; then
                MODEL="Snapdragon 8cx Gen 1/2"
            elif grep -q "X1E80100" /sys/devices/soc0/soc_id 2>/dev/null; then
                MODEL="Snapdragon X Elite"
            else
                MODEL="Unknown Snapdragon"
            fi
            
            log "Qualcomm model: $MODEL"
            return 0
        fi
    fi
    
    return 1
}

# Function to detect Microsoft SQ
detect_microsoft_sq() {
    if [ -f /proc/cpuinfo ]; then
        if grep -q "Microsoft" /proc/cpuinfo || grep -q "SQ" /sys/devices/virtual/dmi/id/product_name 2>/dev/null; then
            log "Detected Microsoft SQ platform"
            
            # Try to determine specific model
            if grep -q "Surface Pro X" /sys/devices/virtual/dmi/id/product_name 2>/dev/null; then
                if grep -q "SQ3" /sys/devices/virtual/dmi/id/product_version 2>/dev/null; then
                    MODEL="SQ3"
                elif grep -q "SQ2" /sys/devices/virtual/dmi/id/product_version 2>/dev/null; then
                    MODEL="SQ2"
                else
                    MODEL="SQ1"
                fi
            else
                MODEL="Unknown SQ"
            fi
            
            log "Microsoft SQ model: $MODEL"
            return 0
        fi
    fi
    
    return 1
}

# Function to detect Samsung Exynos
detect_samsung_exynos() {
    if [ -f /proc/cpuinfo ]; then
        if grep -q "Exynos" /proc/cpuinfo || grep -q "Samsung" /sys/devices/soc0/soc_id 2>/dev/null; then
            log "Detected Samsung Exynos platform"
            
            # Try to determine specific model
            if grep -q "2200" /sys/devices/soc0/soc_id 2>/dev/null; then
                MODEL="Exynos 2200"
            elif grep -q "2100" /sys/devices/soc0/soc_id 2>/dev/null; then
                MODEL="Exynos 2100"
            else
                MODEL="Unknown Exynos"
            fi
            
            log "Samsung Exynos model: $MODEL"
            return 0
        fi
    fi
    
    return 1
}

# Function to detect MediaTek
detect_mediatek() {
    if [ -f /proc/cpuinfo ]; then
        if grep -q "MediaTek" /proc/cpuinfo || grep -q "MT" /sys/devices/soc0/soc_id 2>/dev/null; then
            log "Detected MediaTek platform"
            
            # Try to determine specific model
            if grep -q "MT8195" /sys/devices/soc0/soc_id 2>/dev/null; then
                MODEL="Kompanio 1200"
            elif grep -q "MT8192" /sys/devices/soc0/soc_id 2>/dev/null; then
                MODEL="Kompanio 820"
            else
                MODEL="Unknown Kompanio"
            fi
            
            log "MediaTek model: $MODEL"
            return 0
        fi
    fi
    
    return 1
}

# Function to detect Rockchip
detect_rockchip() {
    if [ -f /proc/cpuinfo ]; then
        if grep -q "Rockchip" /proc/cpuinfo || grep -q "RK" /sys/devices/soc0/soc_id 2>/dev/null; then
            log "Detected Rockchip platform"
            
            # Try to determine specific model
            if grep -q "RK3588" /sys/devices/soc0/soc_id 2>/dev/null; then
                MODEL="RK3588"
            elif grep -q "RK3399" /sys/devices/soc0/soc_id 2>/dev/null; then
                MODEL="RK3399"
            else
                MODEL="Unknown Rockchip"
            fi
            
            log "Rockchip model: $MODEL"
            return 0
        fi
    fi
    
    return 1
}

# Function to detect NVIDIA Tegra
detect_nvidia_tegra() {
    if [ -f /proc/cpuinfo ]; then
        if grep -q "NVIDIA" /proc/cpuinfo || grep -q "Tegra" /sys/devices/soc0/family 2>/dev/null; then
            log "Detected NVIDIA Tegra platform"
            
            # Try to determine specific model
            if grep -q "Orin" /sys/devices/soc0/soc_id 2>/dev/null; then
                MODEL="Tegra Orin"
            elif grep -q "Xavier" /sys/devices/soc0/soc_id 2>/dev/null; then
                MODEL="Tegra Xavier"
            else
                MODEL="Unknown Tegra"
            fi
            
            log "NVIDIA Tegra model: $MODEL"
            return 0
        fi
    fi
    
    return 1
}

# Function to load platform-specific drivers
load_platform_drivers() {
    local platform=$1
    local model=$2
    
    log "Loading drivers for $platform ($model)"
    
    # Check if platform directory exists
    if [ ! -d "$DRIVERS_DIR/$platform" ]; then
        log "Error: Platform directory not found: $DRIVERS_DIR/$platform"
        return 1
    fi
    
    # Load platform configuration
    if [ -f "$DRIVERS_DIR/$platform/platform.conf" ]; then
        log "Loading platform configuration from $DRIVERS_DIR/$platform/platform.conf"
        source "$DRIVERS_DIR/$platform/platform.conf"
    else
        log "Warning: Platform configuration not found"
    fi
    
    # Load boot firmware if available
    if [ -f "$DRIVERS_DIR/$platform/boot/boot-firmware.bin" ]; then
        log "Loading boot firmware"
        # Implementation depends on platform-specific requirements
    fi
    
    # Load GPU drivers
    if [ -d "$DRIVERS_DIR/$platform/gpu" ]; then
        log "Loading GPU drivers"
        for driver in "$DRIVERS_DIR/$platform/gpu"/*.ko; do
            if [ -f "$driver" ]; then
                log "Loading kernel module: $(basename "$driver")"
                insmod "$driver" || log "Failed to load $(basename "$driver")"
            fi
        done
    fi
    
    # Load network drivers
    if [ -d "$DRIVERS_DIR/$platform/network" ]; then
        log "Loading network drivers"
        for driver in "$DRIVERS_DIR/$platform/network"/*.ko; do
            if [ -f "$driver" ]; then
                log "Loading kernel module: $(basename "$driver")"
                insmod "$driver" || log "Failed to load $(basename "$driver")"
            fi
        done
    fi
    
    # Load audio drivers
    if [ -d "$DRIVERS_DIR/$platform/audio" ]; then
        log "Loading audio drivers"
        for driver in "$DRIVERS_DIR/$platform/audio"/*.ko; do
            if [ -f "$driver" ]; then
                log "Loading kernel module: $(basename "$driver")"
                insmod "$driver" || log "Failed to load $(basename "$driver")"
            fi
        done
    fi
    
    # Load input drivers
    if [ -d "$DRIVERS_DIR/$platform/input" ]; then
        log "Loading input drivers"
        for driver in "$DRIVERS_DIR/$platform/input"/*.ko; do
            if [ -f "$driver" ]; then
                log "Loading kernel module: $(basename "$driver")"
                insmod "$driver" || log "Failed to load $(basename "$driver")"
            fi
        done
    fi
    
    # Load other drivers
    for dir in "$DRIVERS_DIR/$platform"/*; do
        if [ -d "$dir" ] && [ "$(basename "$dir")" != "boot" ] && \
           [ "$(basename "$dir")" != "gpu" ] && [ "$(basename "$dir")" != "network" ] && \
           [ "$(basename "$dir")" != "audio" ] && [ "$(basename "$dir")" != "input" ]; then
            log "Loading drivers from $(basename "$dir")"
            for driver in "$dir"/*.ko; do
                if [ -f "$driver" ]; then
                    log "Loading kernel module: $(basename "$driver")"
                    insmod "$driver" || log "Failed to load $(basename "$driver")"
                fi
            done
        fi
    done
    
    log "Finished loading drivers for $platform"
    return 0
}

# Main function
main() {
    log "Starting ARM64 platform detection"
    
    # Detect platform
    if detect_apple_silicon; then
        PLATFORM="apple-silicon"
    elif detect_qualcomm; then
        PLATFORM="qualcomm"
    elif detect_microsoft_sq; then
        PLATFORM="microsoft-sq"
    elif detect_samsung_exynos; then
        PLATFORM="samsung-exynos"
    elif detect_mediatek; then
        PLATFORM="mediatek"
    elif detect_rockchip; then
        PLATFORM="rockchip"
    elif detect_nvidia_tegra; then
        PLATFORM="nvidia-tegra"
    else
        log "Unknown ARM64 platform, using generic drivers"
        PLATFORM="generic"
        MODEL="Generic ARM64"
    fi
    
    # Create platform identification file
    echo "PLATFORM=$PLATFORM" > /etc/mros/platform.conf
    echo "MODEL=$MODEL" >> /etc/mros/platform.conf
    
    # Load platform-specific drivers
    load_platform_drivers "$PLATFORM" "$MODEL"
    
    log "Platform detection and driver loading completed"
    return 0
}

# Run main function
main

exit 0

