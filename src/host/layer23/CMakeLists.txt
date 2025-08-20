# CMake build for Layer23 - FreeRTOS/POSIX adaptation
cmake_minimum_required(VERSION 3.16)

# Common Layer23 sources
set(LAYER23_COMMON_SOURCES
    src/common/apn.c
    src/common/apn_fsm.c
    src/common/l1ctl.c
    src/common/l1ctl_lapdm_glue.c
    src/common/l1l2_interface.c
    src/common/logging.c
    src/common/main.c
    src/common/ms.c
    src/common/networks.c
    src/common/sap_fsm.c
    src/common/sap_interface.c
    src/common/sap_proto.c
    src/common/settings.c
    src/common/sim.c
    src/common/subscriber.c
    src/common/support.c
    src/common/sysinfo.c
    src/common/utils.c
    src/common/vty.c
)

# Mobile application sources
set(LAYER23_MOBILE_SOURCES
    src/mobile/app_mobile.c
    src/mobile/gsm322.c
    src/mobile/gsm411_sms.c
    src/mobile/gsm414.c
    src/mobile/gsm44068_gcc_bcc.c
    src/mobile/gsm480_ss.c
    src/mobile/gsm48_cc.c
    src/mobile/gsm48_mm.c
    src/mobile/gsm48_rr.c
    src/mobile/mnccms.c
    src/mobile/primitives.c
    src/mobile/tch.c
    src/mobile/transaction.c
    src/mobile/vty_interface.c
)

# Misc applications sources - not needed for mobile-only build
# set(LAYER23_MISC_SOURCES ...)

# Platform-specific source filtering
if(TARGET_FREERTOS)
    # Remove POSIX-specific sources for FreeRTOS
    list(REMOVE_ITEM LAYER23_COMMON_SOURCES
        src/common/gps.c  # GPS functionality may need adaptation
    )
    list(REMOVE_ITEM LAYER23_MOBILE_SOURCES
        src/mobile/gapk_io.c
        src/mobile/mncc_sock.c
        src/mobile/tch_data_sock.c
        src/mobile/tch_voice.c
    )
    # Remove scripting support for embedded
    list(REMOVE_ITEM LAYER23_MOBILE_SOURCES
        src/mobile/script_lua.c
    )
    list(APPEND LAYER23_MOBILE_SOURCES
        src/mobile/script_nolua.c
    )
else()
    # Include all sources for POSIX
    list(APPEND LAYER23_COMMON_SOURCES
        src/common/gps.c
    )
    list(APPEND LAYER23_MOBILE_SOURCES
        src/mobile/gapk_io.c
        src/mobile/main.c
        src/mobile/mncc_sock.c
        src/mobile/script_lua.c
        src/mobile/tch_data.c
        src/mobile/tch_data_sock.c
        src/mobile/tch_voice.c
    )
    # No misc sources needed for mobile-only build
endif()

# Create libraries - only common and mobile for our use case
add_library(layer23_common ${LAYER23_COMMON_SOURCES})
add_library(layer23_mobile ${LAYER23_MOBILE_SOURCES})

# Include directories
target_include_directories(layer23_common PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${LIBOSMOCORE_INCLUDE_DIR}
)

target_include_directories(layer23_mobile PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${LIBOSMOCORE_INCLUDE_DIR}
)

# Add dependency on libosmocore external project
add_dependencies(layer23_common libosmocore)
add_dependencies(layer23_mobile libosmocore)

# Link with libosmocore libraries
target_link_libraries(layer23_common 
    ${LIBOSMOCORE_LIB_DIR}/libosmocore.a
    ${LIBOSMOCORE_LIB_DIR}/libosmogsm.a
    ${LIBOSMOCORE_LIB_DIR}/libosmovty.a
)
target_link_libraries(layer23_mobile layer23_common)

# Create mobile application executable (if POSIX)
if(TARGET_POSIX)
    add_executable(mobile src/mobile/main.c)
    add_dependencies(mobile libosmocore)
    target_include_directories(mobile PRIVATE ${LIBOSMOCORE_INCLUDE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/include)
    target_link_libraries(mobile layer23_mobile layer23_common)
endif()

# Install libraries
install(TARGETS layer23_common layer23_mobile
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

# Install mobile application for POSIX
if(TARGET_POSIX)
    install(TARGETS mobile
        RUNTIME DESTINATION bin
    )
endif()