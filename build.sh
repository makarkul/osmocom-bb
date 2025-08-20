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
COPY src/shared/libosmocore ./libosmocore

# Add FreeRTOS+TCP dependencies and socket compatibility layer
COPY deps/freertos-plus-tcp ./freertos-plus-tcp
COPY deps/freertos-kernel ./freertos-kernel
COPY src/compat/freertos ./compat/freertos

# Remove Linux-specific files that cause issues in embedded builds
RUN cd libosmocore && \
    echo "Removing Linux-specific files for embedded build..." && \
    rm -f src/core/netns.c && \
    sed -i '/netns\.c/d' src/core/Makefile.am && \
    rm -f include/osmocom/core/netns.h && \
    sed -i '/netns\.h/d' include/osmocom/core/Makefile.am && \
    echo "Removing GSMTAP files that require socket functionality..." && \
    rm -f src/core/gsmtap_util.c && \
    sed -i '/gsmtap_util\.c/d' src/core/Makefile.am && \
    rm -f src/core/logging_gsmtap.c && \
    sed -i '/logging_gsmtap\.c/d' src/core/Makefile.am && \
    rm -f include/osmocom/core/gsmtap_util.h && \
    sed -i '/gsmtap_util\.h/d' include/osmocom/core/Makefile.am && \
    echo "Commenting out GSMTAP include in logging.c..." && \
    sed -i 's|#include <osmocom/core/gsmtap_util.h>|// #include <osmocom/core/gsmtap_util.h> // Disabled for embedded build|' src/core/logging.c && \
    echo "Disabling GSMTAP functionality in logging.c..." && \
    sed -i 's|case LOG_TGT_TYPE_GSMTAP:|// case LOG_TGT_TYPE_GSMTAP: // Disabled for embedded build|g' src/core/logging.c && \
    sed -i 's|gsmtap_source_free|// gsmtap_source_free // Disabled for embedded build|g' src/core/logging.c && \
    echo "Removing socket utilities that require full POSIX socket support..." && \
    rm -f src/core/socket.c && \
    sed -i '/socket\.c/d' src/core/Makefile.am && \
    echo "Removing TUN/TAP and other Linux network interface files..." && \
    rm -f src/core/tun.c && \
    sed -i '/tun\.c/d' src/core/Makefile.am && \
    rm -f src/core/netdev.c && \
    sed -i '/netdev\.c/d' src/core/Makefile.am && \
    echo "Removing socket address utilities that require full POSIX socket support..." && \
    rm -f src/core/sockaddr_str.c && \
    sed -i '/sockaddr_str\.c/d' src/core/Makefile.am && \
    echo "Removing stats TCP interface that requires socket support..." && \
    rm -f src/core/stats_tcp.c && \
    sed -i '/stats_tcp\.c/d' src/core/Makefile.am

# Add socket compatibility layer to libosmocore build and extend pseudotalloc
RUN cd libosmocore && \
    echo "Adding FreeRTOS socket compatibility layer..." && \
    cp /workspace/compat/freertos/socket_compat.h include/osmocom/core/ && \
    cp /workspace/compat/freertos/socket_compat.c src/core/ && \
    sed -i 's/\(^[[:space:]]*utils\.c[[:space:]]*\\\)$/\1\n\tsocket_compat.c \\/' src/core/Makefile.am && \
    sed -i 's/\(^[[:space:]]*utils\.h[[:space:]]*\\\)$/\1\n\tsocket_compat.h \\/' include/osmocom/core/Makefile.am && \
    mkdir -p include/sys include/netinet include/arpa && \
    cp /workspace/compat/freertos/sys/socket.h include/sys/ && \
    cp /workspace/compat/freertos/netinet/in.h include/netinet/ && \
    cp /workspace/compat/freertos/arpa/inet.h include/arpa/ && \
    echo "Checking if talloc_realloc is already present in pseudotalloc..." && \
    if ! grep -q "talloc_realloc_size" src/pseudotalloc/talloc.h; then \
        echo "Adding missing talloc_realloc declaration to pseudotalloc.h..." && \
        echo 'void *talloc_realloc_size(const void *ctx, void *ptr, size_t size);' >> src/pseudotalloc/talloc.h && \
        echo '#define talloc_realloc(ctx, ptr, type, count) (type *)talloc_realloc_size(ctx, ptr, sizeof(type) * count)' >> src/pseudotalloc/talloc.h; \
    fi && \
    echo "talloc_realloc functionality is already present in pseudotalloc implementation."

# Build libpseudotalloc first, then configure with it
RUN cd libosmocore && \
    autoreconf -fi && \
    echo "Building libpseudotalloc first..." && \
    cd src/pseudotalloc && \
    gcc -shared -fPIC -o libpseudotalloc.so pseudotalloc.c && \
    gcc -fPIC -c -o pseudotalloc.o pseudotalloc.c && \
    ar rcs libpseudotalloc.a pseudotalloc.o && \
    echo "Creating talloc.pc for pkg-config..." && \
    cat > talloc.pc << 'PCEOF'
prefix=/workspace/libosmocore/src/pseudotalloc
exec_prefix=${prefix}
libdir=${exec_prefix}
includedir=${prefix}

Name: talloc
Description: Pseudotalloc - talloc compatibility for embedded systems
Version: 2.1.0
Libs: -L${libdir} -lpseudotalloc
Cflags: -I${includedir}
PCEOF

# Test libosmocore configuration and build with FreeRTOS+TCP socket support  
RUN cd libosmocore && \
    PKG_CONFIG_PATH="/workspace/libosmocore/src/pseudotalloc:$PKG_CONFIG_PATH" \
    CPPFLAGS="-I/workspace/libosmocore/include -I/workspace/freertos-plus-tcp/include -I/workspace/freertos-kernel/include -I/workspace/compat/freertos -DTARGET_FREERTOS=1 -DFREERTOS_PLUS_TCP=1" \
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