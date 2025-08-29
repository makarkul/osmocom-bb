# OsmocomBB for FreeRTOS/POSIX

This repository contains a FreeRTOS/POSIX port of OsmocomBB (Osmocom Baseband), enabling GSM Layer 2/3 protocol stack to run on embedded systems with FreeRTOS or POSIX-compatible systems.

## Project Structure

```
├── src/                    # Main source code
│   ├── shared/
│   │   ├── libosmocore/   # Official libosmocore (git submodule)
│   │   └── l1gprs.c       # Shared L1 GPRS implementation
│   ├── host/              # Host-side applications
│   │   ├── layer23/       # Layer 2/3 GSM protocol stack
│   │   ├── trxcon/        # TRX connection bridge
│   │   ├── virt_phy/      # Virtual PHY layer
│   │   └── osmocon/       # Phone communication utility
│   └── include/           # Shared header files
├── deps/                  # Dependencies (git submodules)
│   ├── freertos-kernel/   # FreeRTOS kernel
│   └── freertos-plus-tcp/ # FreeRTOS+TCP networking stack
├── refs/                  # Reference repositories (not tracked)
│   └── osmocom-bb/        # Original osmocom-bb source
└── sync-from-refs.sh      # Script to sync from reference repo
```

## Build Targets

- **FreeRTOS**: Embedded systems with FreeRTOS RTOS
- **POSIX**: Linux, macOS, and other POSIX-compatible systems

## Prerequisites

### For FreeRTOS Build
- ARM GCC toolchain (arm-none-eabi-gcc)
- CMake 3.16 or later
- FreeRTOS-compatible target hardware

### For POSIX Build
- GCC or Clang
- CMake 3.16 or later
- libosmocore dependencies (may need system installation)

## Building

### Initialize Submodules

```bash
git submodule update --init --recursive
```

### FreeRTOS Build

```bash
mkdir build-freertos && cd build-freertos
cmake .. -DTARGET_FREERTOS=ON -DTARGET_POSIX=OFF
make
```

### POSIX Build

```bash
mkdir build-posix && cd build-posix
cmake .. -DTARGET_FREERTOS=OFF -DTARGET_POSIX=ON
make
```

### Cross-compilation for ARM

```bash
mkdir build-arm && cd build-arm
cmake .. -DCMAKE_TOOLCHAIN_FILE=../cmake/arm-toolchain.cmake
make
```

## Configuration Options

- `TARGET_FREERTOS`: Enable FreeRTOS target (default: ON)
- `TARGET_POSIX`: Enable POSIX target (default: ON)
- `ENABLE_TX`: Enable transmitter functionality (default: OFF, requires license)
- `BUILD_SHARED_LIBS`: Build shared libraries (default: OFF)

## Syncing with Upstream

To pull updates from the reference osmocom-bb repository:

```bash
./sync-from-refs.sh
```

This script:
1. Syncs source code from `refs/osmocom-bb/`
2. Updates the libosmocore submodule
3. Preserves local CMake build files
4. Creates backups of existing files

## Components

### Core Libraries

- **libosmocore**: Core utilities, timers, message buffers, GSM utilities
- **libosmogsm**: GSM protocol implementations (Layer 2/3)
- **libosmovty**: VTY (command-line interface) system

### Applications

- **mobile**: Mobile station implementation
- **bcch_scan**: Broadcast channel scanner
- **ccch_scan**: Common control channel scanner  
- **cell_log**: Cell information logger

### Utilities

- **osmocon**: Phone communication tool
- **trxcon**: TRX connection bridge
- **virtphy**: Virtual PHY for simulation

### FakeTRX Minimal Host Subset

For containerized FakeTRX demos where only userspace tools are needed and no virtual Um path is required, build just `mobile` and `trxcon`:

```
make PLATFORM=linux host-faketrx
```

This omits:
- Firmware / osmocon
- virtphy (GSMTAP virtual Um)
- Scanners (bcch_scan, cell_log, etc.)

Use when pairing with `fake_trx.py` plus `osmo-bts-trx` in a core network stack.

## FreeRTOS Adaptations

The FreeRTOS port includes:

- Conditional compilation to exclude POSIX-specific code
- Integration with FreeRTOS+TCP for networking
- FreeRTOS task and timer APIs instead of pthread
- Embedded-friendly memory management

## Development

### Adding New Features

1. Implement features in the appropriate `src/` directory
2. Update CMakeLists.txt files as needed
3. Use conditional compilation for platform-specific code:
   ```c
   #ifdef TARGET_FREERTOS
   // FreeRTOS-specific implementation
   #else
   // POSIX implementation  
   #endif
   ```

### Testing

For testing with a complete GSM network simulation, see the demo environment in `refs/osmocom-demo/`.

## License

This project follows the same licensing as the original OsmocomBB project. See individual source files for specific license information.

## Contributing

Contributions should follow the Linux Kernel coding style and be submitted as pull requests.

## Regulatory Notice

GSM operates in licensed spectrum. In most jurisdictions, you need a license from a regulatory authority to transmit. The default build disables transmitter functionality for regulatory compliance.