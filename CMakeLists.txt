cmake_minimum_required(VERSION 3.16)
project(osmocom-bb-freertos C)

# Set C standard
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Build configuration options
option(BUILD_SHARED_LIBS "Build shared libraries" OFF)
option(ENABLE_TX "Enable transmitter functionality (requires license)" OFF)
option(TARGET_FREERTOS "Build for FreeRTOS" ON)
option(TARGET_POSIX "Build for POSIX" ON)

# Compiler flags
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wextra")
set(CMAKE_C_FLAGS_DEBUG "-g -O0")
set(CMAKE_C_FLAGS_RELEASE "-O2 -DNDEBUG")

if(TARGET_FREERTOS)
    add_definitions(-DTARGET_FREERTOS=1)
    # FreeRTOS specific flags
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -ffunction-sections -fdata-sections")
    
    # Note: FreeRTOS kernel and FreeRTOS+TCP need proper configuration
    # For now, we'll just build the libraries without the full RTOS
    # add_subdirectory(deps/freertos-kernel)
    # add_subdirectory(deps/freertos-plus-tcp)
endif()

if(ENABLE_TX)
    add_definitions(-DCONFIG_TX_ENABLE=1)
endif()

# Include directories
include_directories(
    ${CMAKE_SOURCE_DIR}/src/include
    ${LIBOSMOCORE_INCLUDE_DIR}
    ${CMAKE_SOURCE_DIR}/src/host/layer23/include
)

if(TARGET_FREERTOS)
    include_directories(
        ${CMAKE_SOURCE_DIR}/deps/freertos-kernel/include
        ${CMAKE_SOURCE_DIR}/deps/freertos-plus-tcp/include
    )
endif()

# Build libosmocore using its native build system first
include(ExternalProject)

ExternalProject_Add(libosmocore
    GIT_REPOSITORY https://github.com/makarkul/libosmocore-freertos.git
    GIT_TAG freertos-adaptations
    CONFIGURE_COMMAND sh -c "cd <SOURCE_DIR> && autoreconf -fi && ./configure --prefix=${CMAKE_BINARY_DIR}/libosmocore-install --enable-embedded --disable-shared --disable-tests --disable-doxygen --disable-utilities --disable-uring --disable-libsctp --disable-sctp-tests --disable-uring-tests"
    BUILD_COMMAND sh -c "cd <SOURCE_DIR> && make -j${CMAKE_BUILD_PARALLEL_LEVEL}"
    INSTALL_COMMAND sh -c "cd <SOURCE_DIR> && make install"
    BUILD_IN_SOURCE 1
)

# Add libosmocore to our include and library paths
set(LIBOSMOCORE_INCLUDE_DIR ${CMAKE_BINARY_DIR}/libosmocore-install/include)
set(LIBOSMOCORE_LIB_DIR ${CMAKE_BINARY_DIR}/libosmocore-install/lib)

# Add layer23 after libosmocore
add_subdirectory(src/host/layer23)

# Optional components (only if CMakeLists.txt exists)
if(TARGET_POSIX)
    if(EXISTS "${CMAKE_SOURCE_DIR}/src/host/trxcon/CMakeLists.txt")
        add_subdirectory(src/host/trxcon)
    endif()
    if(EXISTS "${CMAKE_SOURCE_DIR}/src/host/virt_phy/CMakeLists.txt")
        add_subdirectory(src/host/virt_phy)
    endif()
    if(EXISTS "${CMAKE_SOURCE_DIR}/src/host/osmocon/CMakeLists.txt")
        add_subdirectory(src/host/osmocon)
    endif()
endif()