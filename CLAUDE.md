# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains **OsmocomBB** (Osmocom Baseband), an open-source GSM baseband implementation that runs on mobile phones with Calypso chipsets, and **osmocom-demo**, a complete Docker-based GSM network simulation environment.

### Key Components

**OsmocomBB Core (`refs/osmocom-bb/`):**
- **Target Firmware** (`src/target/firmware/`): Firmware for Calypso-based phones (Layer 1 implementation)
- **Host Layer23** (`src/host/layer23/`): MS-side Layer 2/3 GSM protocol stack (LAPDm, GSM 04.08)
- **TRX Tools** (`src/host/trxcon/`, `src/target/trx_toolkit/`): TRX interface and virtual radio simulation
- **Virtual PHY** (`src/host/virt_phy/`): Virtual Layer 1 for simulation
- **Utilities** (`src/host/osmocon/`, `src/host/gprsdecode/`): Device communication and debugging tools

**Demo Environment (`refs/osmocom-demo/`):**
- Complete GSM network stack with Docker containers
- FakeTRX virtual radio interface for hardware-free testing
- Pre-configured core network components (HLR, MSC, BSC, STP)

## Architecture

### Code Structure
- **Target**: ARM firmware for Calypso DSP phones (Layer 1 radio functions)
- **Host**: Linux applications implementing Layers 2/3 of GSM protocol stack
- **Shared**: libosmocore-freertos library (from https://github.com/makarkul/libosmocore-freertos.git) providing common utilities and GSM protocol support with FreeRTOS adaptations

### Key Interfaces
- **L1CTL**: Communication protocol between Layer 1 (phone) and Layer 2/3 (PC)
- **RSLms**: Modified RSL protocol for L2/L3 interface (based on GSM TS 08.58)
- **TRX Interface**: Protocol for radio simulation and hardware abstraction

## Common Development Commands

### Building OsmocomBB

Navigate to `refs/osmocom-bb/src/` for all build operations:

```bash
cd refs/osmocom-bb/src/

# Build everything (requires ARM toolchain)
make

# Build individual components
make nofirmware     # Host tools only (layer23, osmocon, trxcon, etc.)
make firmware       # Target firmware for Calypso phones
make libosmocore-target  # Cross-compiled libosmocore for target

# Build specific host tools
make layer23        # Layer 2/3 implementation
make osmocon       # Phone communication tool  
make trxcon        # TRX connection bridge
make virtphy       # Virtual PHY
make gprsdecode    # GPRS protocol decoder

# Clean builds
make clean
make distclean
```

### Prerequisites for Building
- GNU ARM toolchain (arm-elf-gcc or arm-none-eabi-gcc)
- libosmocore system installation
- Standard build tools (autotools, make, gcc)

### Demo Environment Commands

Navigate to `refs/osmocom-demo/` for demo operations:

```bash
cd refs/osmocom-demo/

# FakeTRX Demo (recommended for macOS)
./faketrx-demo.sh start
./faketrx-demo.sh status
./faketrx-demo.sh logs [service-name]
./faketrx-demo.sh subscriber    # Add test subscriber
./faketrx-demo.sh stop

# Virtual Um Demo (Linux recommended)  
./virtual-um-demo.sh start
./virtual-um-demo.sh status
./virtual-um-demo.sh stop

# Manual docker-compose control
docker-compose -f docker-compose-faketrx.yml up -d
docker-compose -f docker-compose-virtual-um.yml up -d

# Monitor system status
./show-ue-status.sh
```

## Development Workflow

### Testing Setup
The demo environment provides a complete GSM simulation for testing:
- No physical hardware required
- Full protocol stack validation
- Network debugging and analysis

### Key Configuration Files
- `refs/osmocom-demo/configs/`: GSM network element configurations
- `refs/osmocom-bb/doc/examples/mobile/`: Mobile station example configs
- Target firmware build configurations in `src/target/firmware/Makefile`

### Important Build Notes
- **DO NOT** use the embedded libosmocore in `src/shared/libosmocore/` as system-wide library
- Cross-compilation requires `CROSS_HOST` environment variable (auto-detected from toolchain)
- Transmitter functionality disabled by default for regulatory compliance
- Enable with `CFLAGS += -DCONFIG_TX_ENABLE` in firmware Makefile (requires license)

### Development Focus Areas
- **Layer 1**: Radio timing, burst processing, frequency control (`src/target/firmware/layer1/`)
- **Layer 2/3**: GSM protocol implementation, mobility management (`src/host/layer23/src/`)
- **Virtual Radio**: TRX simulation and protocol testing (`src/target/trx_toolkit/`, `src/host/trxcon/`)
- **Network Testing**: End-to-end protocol validation using demo environment

### Coding Standards
- Follow Linux Kernel coding style
- Use libosmocore utilities for common operations
- Submit patches via Gerrit: https://gerrit.osmocom.org/
- Reference documentation: https://osmocom.org/projects/baseband/wiki/

## Testing and Validation

### Unit Testing
Build-specific testing varies by component - check individual `Makefile.am` files for test targets.

### Integration Testing
Use the demo environment for full protocol stack testing:
1. Start demo environment
2. Add test subscriber to HLR
3. Monitor mobile station attachment and operation
4. Validate protocol flows via logs and VTY interfaces

### Key Test Subscriber Configuration
- IMSI: 901700000000001
- Ki: 00112233445566778899aabbccddeeff  
- Algorithm: COMP128v1
- MSISDN: 12345