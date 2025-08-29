#!/bin/bash

# Build script for OsmocomBB FreeRTOS/POSIX using Docker

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

show_usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  build          Build mobile application (includes libosmocore dependency)"
    echo "  mobile         Build mobile application using autotools"
    echo "  layer23        Build Layer23 mobile application only"
    echo "  nofirmware     Build all host applications (mobile, osmocon, etc.)"
    echo "  libosmocore    Build libosmocore dependency only"
    echo "  dev            Start development environment with live source mounting"
    echo "  clean          Clean build artifacts"
    echo "  test           Test the built applications"
    echo "  shell          Enter interactive shell in build container"
    echo ""
    echo "Examples:"
    echo "  build.sh build         # Build mobile application with all dependencies"
    echo "  build.sh mobile        # Build mobile application using autotools"
    echo "  build.sh nofirmware    # Build all host applications"
    echo "  build.sh libosmocore   # Build libosmocore dependency only"
    echo "  build.sh dev           # Start dev container for live development"
    echo "  build.sh shell         # Interactive shell in build environment"
}

build_libosmocore() {
    print_header "Building libosmocore dependency"
    
    docker-compose build osmocom-bb-freertos
    if [ $? -eq 0 ]; then
        print_success "Docker image built successfully (includes libosmocore)"
        echo ""
        echo "libosmocore is built automatically as part of the Docker image."
        echo "It includes:"
        echo "  ✓ FreeRTOS adaptations"
        echo "  ✓ Pseudotalloc memory management"
        echo "  ✓ Socket compatibility layer"
        echo "  ✓ GSM protocol implementations"
        echo ""
        echo "Ready to build mobile application with:"
        echo "  ./build.sh build"
    else
        print_error "libosmocore build failed"
        exit 1
    fi
}

build_mobile() {
    print_header "Building mobile application using autotools"
    
    docker-compose build osmocom-bb-freertos
    if [ $? -eq 0 ]; then
        print_success "Dependencies ready (libosmocore + FreeRTOS)"
        
        # Build mobile application using autotools for FreeRTOS target
        docker-compose run --rm --entrypoint /bin/bash osmocom-bb-freertos -lc "set -e; \
            source scripts/freertos_env.sh; \
            cd src/host/layer23; \
            autoreconf -fi; \
            ./configure \$HOST_CONFARGS CFLAGS=\"\$CFLAGS\" LDFLAGS=\"\$LDFLAGS\" PKG_CONFIG_PATH=\"\$PKG_CONFIG_PATH\"; \
            make -j\$(nproc) -C src/mobile mobile"
        
        if [ $? -eq 0 ]; then
            print_success "Mobile application built successfully"
            echo ""
            echo "Mobile application available at: src/host/layer23/src/mobile/mobile"
        else
            print_error "Mobile application build failed"
            exit 1
        fi
    else
        print_error "Dependency build failed"
        exit 1
    fi
}

build_nofirmware() {
    print_header "Building all host applications (nofirmware target)"
    
    docker-compose build osmocom-bb-freertos
    if [ $? -eq 0 ]; then
        print_success "Dependencies ready (libosmocore + FreeRTOS)"
        
        # Build all host applications for FreeRTOS target
        docker-compose run --rm --entrypoint /bin/bash osmocom-bb-freertos -lc "set -e; \
            source scripts/freertos_env.sh; \
            cd src/host/layer23; \
            autoreconf -fi; \
            ./configure \$HOST_CONFARGS CFLAGS=\"\$CFLAGS\" LDFLAGS=\"\$LDFLAGS\" PKG_CONFIG_PATH=\"\$PKG_CONFIG_PATH\"; \
            make -j\$(nproc); \
            echo 'Layer23 applications built for FreeRTOS target'; \
            cd ../osmocon; \
            autoreconf -fi; \
            ./configure; \
            make -j\$(nproc); \
            echo 'osmocon built successfully'; \
            cd ../trxcon; \
            autoreconf -fi; \
            ./configure \$HOST_CONFARGS CFLAGS=\"\$CFLAGS\" LDFLAGS=\"\$LDFLAGS\" PKG_CONFIG_PATH=\"\$PKG_CONFIG_PATH\"; \
            make -j\$(nproc); \
            echo 'trxcon built for FreeRTOS target'"
        
        if [ $? -eq 0 ]; then
            print_success "All host applications built successfully"
            echo ""
            echo "Built applications:"
            echo "  - Mobile: src/host/layer23/src/mobile/mobile"
            echo "  - osmocon: src/host/osmocon/osmocon"  
            echo "  - trxcon: src/host/trxcon/trxcon"
            echo "  - Other Layer23 tools in src/host/layer23/src/"
        else
            print_error "Host applications build failed"
            exit 1
        fi
    else
        print_error "Dependency build failed"
        exit 1
    fi
}

build_layer23() {
    print_header "Building Layer23 applications (includes mobile)"
    
    docker-compose build osmocom-bb-freertos
    if [ $? -eq 0 ]; then
        print_success "Dependencies ready (libosmocore + FreeRTOS)"
        
        # Build all Layer23 applications (mobile, misc tools, etc.) for FreeRTOS target
        docker-compose run --rm --entrypoint /bin/bash osmocom-bb-freertos -lc "set -e; \
            source scripts/freertos_env.sh; \
            cd src/host/layer23; \
            autoreconf -fi; \
            ./configure \$HOST_CONFARGS CFLAGS=\"\$CFLAGS\" LDFLAGS=\"\$LDFLAGS\" PKG_CONFIG_PATH=\"\$PKG_CONFIG_PATH\"; \
            make -j\$(nproc)"
        
        if [ $? -eq 0 ]; then
            print_success "Layer23 applications built successfully"
            echo ""
            echo "Built applications:"
            echo "  - Mobile: src/host/layer23/src/mobile/mobile"
            echo "  - Misc tools: src/host/layer23/src/misc/"
            echo "  - Modem: src/host/layer23/src/modem/modem"
        else
            print_error "Layer23 build failed"
            exit 1
        fi
    else
        print_error "Dependency build failed"
        exit 1
    fi
}

build_all() {
    print_header "Building mobile application with all dependencies"
    
    docker-compose build osmocom-bb-freertos
    if [ $? -eq 0 ]; then
        print_success "Dependencies built successfully (libosmocore + FreeRTOS)"
        
        # Build mobile application using autotools for FreeRTOS target
        print_header "Building mobile application for FreeRTOS"
        docker-compose run --rm --entrypoint /bin/bash osmocom-bb-freertos -lc "set -euo pipefail; \
            source scripts/freertos_env.sh; \
            cd src/host/layer23; \
            echo '[build] Running autoreconf'; autoreconf -fi; \
            echo '[build] Configuring layer23 for FreeRTOS'; \
            ./configure \$HOST_CONFARGS CFLAGS=\"\$CFLAGS\" LDFLAGS=\"\$LDFLAGS\" PKG_CONFIG_PATH=\"\$PKG_CONFIG_PATH\"; \
            echo '[build] Building mobile target'; \
            make -j\$(nproc) -C src/mobile mobile; \
            echo 'Mobile application built for FreeRTOS target'"
        
        if [ $? -eq 0 ]; then
            print_success "Mobile application build completed"
            echo ""
            echo "Built mobile application:"
            echo "  - Mobile application: src/host/layer23/src/mobile/mobile"
            echo "  - Dependencies: libosmocore + FreeRTOS libraries"
            echo ""
            echo "To extract mobile application:"
            echo "  docker-compose run --rm osmocom-bb-freertos tar -czf - src/host/layer23/src/mobile/mobile > mobile-app.tar.gz"
            echo ""
            echo "To run mobile application:"
            echo "  docker-compose run --rm osmocom-bb-freertos \"cd src/host/layer23/src/mobile && ./mobile --help\""
            echo ""
            echo "To test mobile application:"
            echo "  ./build.sh test"
        else
            print_error "Mobile application build failed"
            exit 1
        fi
    else
        print_error "Dependency build failed"
        exit 1
    fi
}

enter_shell() {
    print_header "Entering Interactive Shell"
    
    # Build container first if not exists
    docker-compose build osmocom-bb-freertos
    
    # Enter interactive shell
    docker-compose run --rm shell
}

start_dev() {
    print_header "Starting Development Environment"
    
    docker-compose build osmocom-bb-freertos
    docker-compose run --rm dev
    
    if [ $? -eq 0 ]; then
        print_success "Development session completed"
        echo ""
        echo "Inside the container you can run:"
        echo "  mkdir -p build-cmake && cd build-cmake && cmake .. && make"
        echo "  cd src/host/layer23 && autoreconf -fi && ./configure && make"
        echo "  ./sync-from-refs.sh           # Sync from reference repo"
    else
        print_error "Failed to start development environment"
        exit 1
    fi
}

clean_build() {
    print_header "Cleaning Build Artifacts"
    
    # Clean local build directories
    rm -rf build-posix build-freertos build-test
    
    # Clean autotools generated files in source directories
    docker-compose run --rm osmocom-bb-freertos bash -c "
        cd src/host/layer23 && make distclean 2>/dev/null || true
        cd ../osmocon && make distclean 2>/dev/null || true  
        cd ../trxcon && make distclean 2>/dev/null || true
        cd ../virt_phy && make distclean 2>/dev/null || true
    " 2>/dev/null || true
    
    # Clean Docker artifacts
    docker-compose down
    docker system prune -f
    docker volume prune -f
    
    print_success "Build artifacts cleaned"
}

test_build() {
    print_header "Testing mobile application and dependencies"
    
    # Build container first
    docker-compose build osmocom-bb-freertos
    
    # Test libosmocore dependency
    echo "Testing libosmocore availability..."
    if docker-compose run --rm osmocom-bb-freertos bash -lc "pkg-config --exists libosmocore" >/dev/null 2>&1; then
        print_success "libosmocore libraries available"
    else
        print_warning "libosmocore libraries not found"
    fi
    
    # Test FreeRTOS headers
    echo "Testing FreeRTOS headers..."
    if docker-compose run --rm osmocom-bb-freertos bash -lc "test -f /workspace/deps/freertos/include/kernel/FreeRTOS.h" >/dev/null 2>&1; then
        print_success "FreeRTOS headers available"
    else
        print_warning "FreeRTOS headers not found"
    fi
    
    # Test mobile application if built
    echo "Testing mobile application..."
    if docker-compose run --rm osmocom-bb-freertos bash -lc "test -f src/host/layer23/src/mobile/mobile" >/dev/null 2>&1; then
        print_success "Mobile application binary found"
        # Test if it can show help
    if docker-compose run --rm osmocom-bb-freertos bash -lc "cd src/host/layer23/src/mobile && ./mobile --help" >/dev/null 2>&1; then
            print_success "Mobile application is executable"
        else
            print_warning "Mobile application may have runtime issues"
        fi
    else
        print_warning "Mobile application not found - run './build.sh build' first"
    fi
    
    # Test build environment
    echo "Testing build environment..."
    if docker-compose run --rm osmocom-bb-freertos bash -lc "source scripts/freertos_env.sh && echo 'Environment OK'" >/dev/null 2>&1; then
        print_success "Build environment ready"
    else
        print_warning "Build environment test failed"
    fi
    
    print_success "Testing completed"
}

# Main script logic
case "${1:-}" in
    build)
        build_all
        ;;
    mobile)
        build_mobile
        ;;
    layer23)
        build_layer23
        ;;
    nofirmware)
        build_nofirmware
        ;;
    libosmocore)
        build_libosmocore
        ;;
    dev)
        start_dev
        ;;
    shell)
        enter_shell
        ;;
    clean)
        clean_build
        ;;
    test)
        test_build
        ;;
    "")
        show_usage
        ;;
    *)
        print_error "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac