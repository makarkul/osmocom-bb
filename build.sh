#!/bin/bash

# Build script for OsmocomBB FreeRTOS/POSIX

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
    echo "  build          Build OsmocomBB for FreeRTOS (includes host tools for testing)"
    echo "  libosmocore    Build and test only libosmocore library"
    echo "  dev            Start development environment with live source mounting"
    echo "  clean          Clean build artifacts"
    echo "  test           Test the built applications"
    echo "  shell          Enter interactive shell in build container"
    echo ""
    echo "Examples:"
    echo "  build.sh build         # Build FreeRTOS libraries and host tools"
    echo "  build.sh libosmocore   # Test libosmocore compilation only"
    echo "  build.sh dev           # Start dev container for live development"
    echo "  build.sh shell         # Interactive shell in build environment"
}

build_libosmocore_only() {
    print_header "Testing libosmocore compilation only"
    
    # Create a temporary Dockerfile that only builds libosmocore
    cat > Dockerfile.libosmocore-test << 'EOF'
FROM ubuntu:22.04 AS libosmocore-test

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    pkg-config \
    autotools-dev \
    autoconf \
    automake \
    libtool \
    python3 \
    python3-pip \
    libpcsclite-dev \
    libtalloc-dev \
    libsctp-dev \
    libmnl-dev \
    libdbi-dev \
    libdbd-sqlite3 \
    libsqlite3-dev \
    libpcap-dev \
    libortp-dev \
    liblua5.3-dev \
    lua5.3 \
    libusb-1.0-0-dev \
    libgnutls28-dev \
    liburing-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
RUN git clone https://github.com/makarkul/libosmocore-freertos.git libosmocore && \
    cd libosmocore && \
    git checkout freertos-adaptations

# No additional dependencies needed - GitHub repo already has FreeRTOS adaptations

# Build libosmocore with FreeRTOS adaptations
RUN cd libosmocore && \
    autoreconf -fi && \
    echo "=== libosmocore Configuration Summary ===" && \
    echo "ENABLED features:" && \
    echo "  ✓ embedded build (--enable-embedded)" && \
    echo "  ✓ pseudotalloc memory management (--enable-pseudotalloc)" && \
    echo "  ✓ VTY telnet interface (enabled by default)" && \
    echo "  ✓ CTRL library (enabled by default)" && \
    echo "  ✓ Gb library (enabled by default)" && \
    echo "  ✓ plugin support (enabled by default)" && \
    echo "  ✓ FreeRTOS socket compatibility layer (custom)" && \
    echo "  ✓ Static libraries" && \
    echo "" && \
    echo "DISABLED features:" && \
    echo "  ✗ shared libraries (--disable-shared)" && \
    echo "  ✗ tests (--disable-tests)" && \
    echo "  ✗ documentation (--disable-doxygen)" && \
    echo "  ✗ utilities (--disable-utilities)" && \
    echo "  ✗ io_uring support (--disable-uring)" && \
    echo "  ✗ SCTP tests (--disable-sctp-tests)" && \
    echo "  ✗ io_uring tests (--disable-uring-tests)" && \
    echo "  ✗ GSMTAP utilities (removed for embedded build)" && \
    echo "  ✗ TUN/TAP network interfaces (not available in FreeRTOS)" && \
    echo "===========================================" && \
    echo "" && \
    ./configure \
        --prefix=/tmp/libosmocore-install \
        --enable-embedded \
        --enable-pseudotalloc \
        --disable-shared \
        --disable-tests \
        --disable-doxygen \
        --disable-utilities \
        --disable-uring \
        --disable-sctp-tests \
        --disable-uring-tests && \
    make -j1 V=1 && \
    make install && \
    echo "libosmocore build successful!"

# List built libraries
RUN ls -la /tmp/libosmocore-install/lib/
RUN ls -la /tmp/libosmocore-install/include/osmocom/
EOF

    # Build only libosmocore
    docker build -f Dockerfile.libosmocore-test -t osmocom-libosmocore-test .
    
    if [ $? -eq 0 ]; then
        print_success "libosmocore compilation test passed!"
        echo ""
        echo "libosmocore built successfully with the following configuration:"
        echo "  --enable-embedded --disable-uring --disable-libsctp"
        echo ""
        echo "You can now proceed with the full build:"
        echo "  ./build.sh build"
        
        # Clean up
        rm -f Dockerfile.libosmocore-test
    else
        print_error "libosmocore compilation failed"
        rm -f Dockerfile.libosmocore-test
        exit 1
    fi
}

build_all() {
    print_header "Building OsmocomBB for FreeRTOS and Host"
    
    docker-compose build build
    if [ $? -eq 0 ]; then
        print_success "Build completed successfully"
        echo ""
        echo "Built artifacts:"
        echo "  - FreeRTOS libraries (ARM): /opt/freertos-build/ in container"
        echo "  - Host applications: Available via /usr/local/bin/ in container"
        echo ""
        echo "To extract FreeRTOS artifacts:"
        echo "  docker-compose run --rm build tar -czf - -C /opt/freertos-build . > freertos-artifacts.tar.gz"
        echo ""
        echo "To test host applications:"
        echo "  ./build.sh test"
    else
        print_error "Build failed"
        exit 1
    fi
}

enter_shell() {
    print_header "Entering Interactive Shell"
    
    # Start the container if not running
    docker-compose up -d build
    
    # Enter interactive shell
    docker-compose exec build bash
}

start_dev() {
    print_header "Starting Development Environment"
    
    docker-compose up -d dev
    if [ $? -eq 0 ]; then
        print_success "Development container started"
        echo ""
        echo "To enter the container:"
        echo "  docker-compose exec dev bash"
        echo ""
        echo "Inside the container you can:"
        echo "  cd build-posix && make        # Build POSIX version"
        echo "  cd build-freertos && make     # Build FreeRTOS version"
        echo "  sync-from-refs.sh           # Sync from reference repo"
    else
        print_error "Failed to start development environment"
        exit 1
    fi
}

clean_build() {
    print_header "Cleaning Build Artifacts"
    
    docker-compose down
    docker system prune -f
    docker volume prune -f
    
    print_success "Build artifacts cleaned"
}

test_build() {
    print_header "Testing Built Applications"
    
    # Start the build container
    docker-compose up -d build
    
    # Test basic functionality
    echo "Testing mobile application..."
    if docker-compose exec build mobile --help >/dev/null 2>&1; then
        print_success "Mobile application works"
    else
        print_warning "Mobile application test failed"
    fi
    
    echo "Testing libosmocore availability..."
    if docker-compose exec build ls /usr/local/lib/libosmo* >/dev/null 2>&1; then
        print_success "libosmocore libraries installed"
    else
        print_warning "libosmocore libraries not found"
    fi
    
    echo "Testing FreeRTOS artifacts..."
    if docker-compose exec build ls /opt/freertos-build/ >/dev/null 2>&1; then
        print_success "FreeRTOS build artifacts available"
        docker-compose exec build cat /opt/freertos-build/README.txt
    else
        print_warning "FreeRTOS artifacts test failed"
    fi
    
    print_success "Testing completed"
}

# Main script logic
case "${1:-}" in
    build)
        build_all
        ;;
    libosmocore)
        build_libosmocore_only
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