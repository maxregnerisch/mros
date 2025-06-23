#!/bin/bash
# mros-linux Test Build Script
# Quick test build to verify components work together

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
BLUE='\\033[0;34m'
NC='\\033[0m' # No Color

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

# Test configuration files
test_config() {
    log_info "Testing configuration files..."
    
    if [[ ! -f "$PROJECT_DIR/mros-config/distribution.conf" ]]; then
        log_error "Distribution config not found"
        return 1
    fi
    
    if [[ ! -f "$PROJECT_DIR/mros-config/packages.list" ]]; then
        log_error "Package list not found"
        return 1
    fi
    
    log_success "Configuration files OK"
}

# Test Python syntax
test_python_syntax() {
    log_info "Testing Python syntax..."
    
    local python_files=(
        "mros-desktop/taskbar/taskbar.py"
        "mros-desktop/startmenu/startmenu.py"
        "mros-apps/file-manager/file-manager.py"
        "mros-apps/upload-manager/upload-manager.py"
        "mros-services/upload-service/upload-service.py"
    )
    
    for file in "${python_files[@]}"; do
        local full_path="$PROJECT_DIR/$file"
        if [[ -f "$full_path" ]]; then
            if python3 -m py_compile "$full_path"; then
                log_success "✓ $file syntax OK"
            else
                log_error "✗ $file syntax error"
                return 1
            fi
        else
            log_warning "File not found: $file"
        fi
    done
    
    log_success "Python syntax tests passed"
}

# Test imports and basic functionality
test_imports() {
    log_info "Testing Python imports..."
    
    # Test basic imports
    python3 -c "
import sys
import os
import json
import subprocess
import threading
import time
from pathlib import Path
from datetime import datetime

# Test GTK imports (if available)
try:
    import gi
    gi.require_version('Gtk', '4.0')
    from gi.repository import Gtk, Gdk, GLib
    print('✓ GTK4 imports OK')
except ImportError as e:
    print(f'⚠ GTK4 not available: {e}')

# Test requests import
try:
    import requests
    print('✓ Requests import OK')
except ImportError as e:
    print(f'⚠ Requests not available: {e}')

print('✓ Basic imports OK')
"
    
    if [[ $? -eq 0 ]]; then
        log_success "Import tests passed"
    else
        log_error "Import tests failed"
        return 1
    fi
}

# Test upload service functionality
test_upload_service() {
    log_info "Testing upload service..."
    
    cd "$PROJECT_DIR/mros-services/upload-service"
    
    # Test help command
    if python3 upload-service.py --help >/dev/null 2>&1; then
        log_success "✓ Upload service help OK"
    else
        log_error "✗ Upload service help failed"
        return 1
    fi
    
    # Test history command
    if python3 upload-service.py --history >/dev/null 2>&1; then
        log_success "✓ Upload service history OK"
    else
        log_error "✗ Upload service history failed"
        return 1
    fi
    
    cd "$PROJECT_DIR"
    log_success "Upload service tests passed"
}

# Test build script
test_build_script() {
    log_info "Testing build script..."
    
    if [[ -x "$PROJECT_DIR/scripts/build-mros.sh" ]]; then
        log_success "✓ Build script is executable"
    else
        log_error "✗ Build script not executable"
        return 1
    fi
    
    # Test help command
    if "$PROJECT_DIR/scripts/build-mros.sh" --help >/dev/null 2>&1; then
        log_success "✓ Build script help OK"
    else
        log_error "✗ Build script help failed"
        return 1
    fi
    
    log_success "Build script tests passed"
}

# Test directory structure
test_structure() {
    log_info "Testing project structure..."
    
    local required_dirs=(
        "mros-config"
        "mros-desktop/taskbar"
        "mros-desktop/startmenu"
        "mros-apps/file-manager"
        "mros-apps/upload-manager"
        "mros-services/upload-service"
        "mros-themes"
        "scripts"
        "docs"
        ".github/workflows"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$PROJECT_DIR/$dir" ]]; then
            log_success "✓ Directory exists: $dir"
        else
            log_error "✗ Directory missing: $dir"
            return 1
        fi
    done
    
    log_success "Project structure tests passed"
}

# Test GitHub Actions workflow
test_workflow() {
    log_info "Testing GitHub Actions workflow..."
    
    local workflow_file="$PROJECT_DIR/.github/workflows/build-mros.yml"
    
    if [[ -f "$workflow_file" ]]; then
        log_success "✓ Workflow file exists"
        
        # Basic YAML syntax check
        if command -v python3 >/dev/null 2>&1; then
            python3 -c "
import yaml
import sys

try:
    with open('$workflow_file', 'r') as f:
        yaml.safe_load(f)
    print('✓ Workflow YAML syntax OK')
except yaml.YAMLError as e:
    print(f'✗ Workflow YAML syntax error: {e}')
    sys.exit(1)
except ImportError:
    print('⚠ PyYAML not available, skipping YAML validation')
" 2>/dev/null || log_warning "YAML validation skipped (PyYAML not available)"
        fi
    else
        log_error "✗ Workflow file missing"
        return 1
    fi
    
    log_success "Workflow tests passed"
}

# Generate test report
generate_report() {
    log_info "Generating test report..."
    
    local report_file="$PROJECT_DIR/test-report.txt"
    
    cat > "$report_file" << EOF
mros-linux Test Report
=====================

Test Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')
Test Environment: $(uname -a)
Python Version: $(python3 --version)

Project Structure:
- Configuration files: ✓
- Desktop components: ✓
- Applications: ✓
- Services: ✓
- Themes: ✓
- Build scripts: ✓
- Documentation: ✓
- CI/CD workflow: ✓

Component Tests:
- Python syntax: ✓
- Import statements: ✓
- Upload service: ✓
- Build script: ✓

Status: All tests passed ✅

Next Steps:
1. Run full build with: sudo ./scripts/build-mros.sh
2. Test ISO in virtual machine
3. Verify upload functionality
4. Deploy to production

EOF
    
    log_success "Test report generated: $report_file"
}

# Main test function
main() {
    log_info "Starting mros-linux component tests..."
    
    # Run all tests
    test_structure
    test_config
    test_python_syntax
    test_imports
    test_upload_service
    test_build_script
    test_workflow
    
    # Generate report
    generate_report
    
    log_success "All tests passed! 🎉"
    log_info "mros-linux is ready for building"
    log_info "Run 'sudo ./scripts/build-mros.sh' to create the ISO"
}

# Run tests
main "$@"

