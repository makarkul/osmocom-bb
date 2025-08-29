## Top-level unified Makefile (docker-driven) for FreeRTOS + Linux builds
## Supported targets: help (default), all, clean
## Usage: make [PLATFORM=freertos|linux] <target>

.PHONY: help all clean clean-freertos clean-linux mobile modem lib fetch fetch-deps fetch-refs _build_freertos _ensure_image _build_linux linux-mobile linux-modem host-faketrx

PLATFORM ?= freertos
# Build modem by default only on linux platform (GPRS stack removed on freertos)
ifeq ($(PLATFORM),freertos)
BUILD_MODEM ?= 0
else
BUILD_MODEM ?= 1
endif
DOCKER_COMPOSE ?= docker-compose
SERVICE_FREERTOS = osmocom-bb-freertos
SERVICE_LINUX = osmocom-bb-linux

## Container commands (only freertos implemented for now)
ifeq ($(PLATFORM),freertos)
BUILD_IMAGE_CMD = $(DOCKER_COMPOSE) build $(SERVICE_FREERTOS)
MOBILE_BUILD_CMD = $(DOCKER_COMPOSE) run --rm --entrypoint /bin/bash $(SERVICE_FREERTOS) -lc \
	"set -e; source scripts/freertos_env.sh; cd src/host/layer23; \
	 autoreconf -fi; \
	 ./configure $$HOST_CONFARGS CFLAGS=\"$$CFLAGS\" LDFLAGS=\"$$LDFLAGS\" PKG_CONFIG_PATH=\"$$PKG_CONFIG_PATH\"; \
	 make -C src/common liblayer23.a; \
	 make -C src/mobile mobile; \
	 ls -l src/common/liblayer23.a src/mobile/mobile"

MODEM_BUILD_CMD = $(DOCKER_COMPOSE) run --rm --entrypoint /bin/bash $(SERVICE_FREERTOS) -lc \
	"set -e; source scripts/freertos_env.sh; cd src/host/layer23; \
	 autoreconf -fi; \
	 ./configure $$HOST_CONFARGS CFLAGS=\"$$CFLAGS\" LDFLAGS=\"$$LDFLAGS\" PKG_CONFIG_PATH=\"$$PKG_CONFIG_PATH\"; \
	 make -C src/common liblayer23.a; \
	 echo '[info] Modem build skipped: GPRS stack removed for freertos platform'"
else ifeq ($(PLATFORM),linux)
BUILD_IMAGE_CMD = $(DOCKER_COMPOSE) build $(SERVICE_LINUX)
MOBILE_BUILD_CMD = $(DOCKER_COMPOSE) run --rm --entrypoint /bin/bash $(SERVICE_LINUX) -lc \
	"set -e; source scripts/linux_env.sh; cd src/host/layer23; \
	 autoreconf -fi; \
	 ./configure $$HOST_CONFARGS CFLAGS=\"$$CFLAGS\" LDFLAGS=\"$$LDFLAGS\" PKG_CONFIG_PATH=\"$$PKG_CONFIG_PATH\"; \
	 make -C src/common liblayer23.a; \
	 make -C src/mobile mobile; \
	 ls -l src/common/liblayer23.a src/mobile/mobile"

MODEM_BUILD_CMD = $(DOCKER_COMPOSE) run --rm --entrypoint /bin/bash $(SERVICE_LINUX) -lc \
	"set -e; source scripts/linux_env.sh; cd src/host/layer23; \
	 autoreconf -fi; \
	 ./configure $$HOST_CONFARGS CFLAGS=\"$$CFLAGS\" LDFLAGS=\"$$LDFLAGS\" PKG_CONFIG_PATH=\"$$PKG_CONFIG_PATH\"; \
	 make -C src/common liblayer23.a; \
	 make -C src/host/layer23/src/modem modem || echo '[warn] modem target may not exist'; \
	 ls -l src/common/liblayer23.a || true"
else
$(error Unsupported PLATFORM=$(PLATFORM). Use freertos or linux)
endif

.DEFAULT_GOAL := help


help:
	@echo "OsmocomBB unified Makefile (Docker)"
	@echo "-----------------------------------"
	@echo "Targets:"
	@echo "  help      Show this help (default)"
	@echo "  fetch     Clone/update external deps (deps/ & refs/) - auto-called by build targets"
	@echo "  lib       Build libosmocore (via docker image)"
	@echo "  mobile    Build only the mobile application"
	@echo "  modem     Attempt to build modem (stubbed / skipped on freertos)"
	@echo "  all       Build mobile and (optionally) modem (controlled by BUILD_MODEM)"
	@echo "  host-faketrx  Build FakeTRX host tool subset (mobile + trxcon; no firmware/virtphy)"
	@echo "  clean     Remove build artifacts & containers"
	@echo "Variables:"
	@echo "  PLATFORM=freertos|linux (default freertos)"
	@echo "  BUILD_MODEM=0|1 (default 0 on freertos, 1 on linux)"
	@echo "Examples:"
	@echo "  make mobile" 
	@echo "  make BUILD_MODEM=1 all"
	@echo "  make clean"
	@echo "Notes:"
	@echo "  - Dependencies are fetched automatically (checks for empty folders)"
	@echo "  - Modem build requires GPRS libraries which are removed in freertos profile"
	@echo "  - Use FORCE_FETCH=1 to force updates during fetch"
	@echo "  - Override *_REF vars (e.g., LIBOSMOCORE_REF=branchname)"
	@echo "  - deps/ and refs/ folders are git-ignored for clean development"

# External reference versions
FREERTOS_KERNEL_REF ?= V11.0.1
FREERTOS_TCP_REF ?= V4.1.0
LIBOSMOCORE_REF ?= master
OSMOCOM_BB_REF ?= master
FORCE_FETCH ?= 0

fetch: fetch-platform-check fetch-deps fetch-refs
	@echo "[fetch] Completed for PLATFORM=$(PLATFORM)"

.PHONY: fetch-platform-check
fetch-platform-check:
	@if [ "$(origin PLATFORM)" != "command line" ]; then \
		echo "[fetch] PLATFORM not specified, defaulting to '$(PLATFORM)'. Use e.g. 'make PLATFORM=freertos fetch'"; \
	fi
	@if [ "$(PLATFORM)" != "freertos" ] && [ "$(PLATFORM)" != "linux" ]; then \
		echo "[fetch] Unsupported PLATFORM='$(PLATFORM)'. Use freertos or linux."; exit 2; \
	fi

fetch-deps: fetch-platform-check
	@echo "[fetch-deps] Ensuring dependencies in deps/ (PLATFORM=$(PLATFORM))"
	@mkdir -p deps
	@if [ ! -d deps/freertos-kernel ] || [ -z "$$(ls -A deps/freertos-kernel 2>/dev/null)" ]; then \
		echo "  - cloning FreeRTOS-Kernel ($(FREERTOS_KERNEL_REF))"; \
		rm -rf deps/freertos-kernel; \
		git clone --depth 1 --branch $(FREERTOS_KERNEL_REF) https://github.com/FreeRTOS/FreeRTOS-Kernel.git deps/freertos-kernel; \
	elif [ "$(FORCE_FETCH)" = "1" ]; then \
		echo "  - updating FreeRTOS-Kernel"; \
		(cd deps/freertos-kernel && git fetch --depth 1 origin $(FREERTOS_KERNEL_REF) && git checkout -f $(FREERTOS_KERNEL_REF)); \
	else echo "  - freertos-kernel exists and is populated (skip)"; fi
	@if [ ! -d deps/freertos-plus-tcp ] || [ -z "$$(ls -A deps/freertos-plus-tcp 2>/dev/null)" ]; then \
		echo "  - cloning FreeRTOS-Plus-TCP ($(FREERTOS_TCP_REF))"; \
		rm -rf deps/freertos-plus-tcp; \
		git clone --depth 1 --branch $(FREERTOS_TCP_REF) https://github.com/FreeRTOS/FreeRTOS-Plus-TCP.git deps/freertos-plus-tcp; \
	elif [ "$(FORCE_FETCH)" = "1" ]; then \
		echo "  - updating FreeRTOS-Plus-TCP"; \
		(cd deps/freertos-plus-tcp && git fetch --depth 1 origin $(FREERTOS_TCP_REF) && git checkout -f $(FREERTOS_TCP_REF)); \
	else echo "  - freertos-plus-tcp exists and is populated (skip)"; fi
	@if [ ! -d deps/libosmocore ] || [ -z "$$(ls -A deps/libosmocore 2>/dev/null)" ]; then \
		echo "  - cloning libosmocore ($(LIBOSMOCORE_REF))"; \
		rm -rf deps/libosmocore; \
		git clone https://github.com/makarkul/libosmocore.git deps/libosmocore && (cd deps/libosmocore && git checkout $(LIBOSMOCORE_REF)); \
	elif [ "$(FORCE_FETCH)" = "1" ]; then \
		echo "  - updating libosmocore"; \
		(cd deps/libosmocore && git fetch origin $(LIBOSMOCORE_REF) && git checkout -f $(LIBOSMOCORE_REF)); \
	else echo "  - libosmocore exists and is populated (skip)"; fi

fetch-refs: fetch-platform-check
	@echo "[fetch-refs] Ensuring reference sources in refs/ (PLATFORM=$(PLATFORM))"
	@mkdir -p refs
	@if [ ! -d refs/osmocom-bb ] || [ -z "$$(ls -A refs/osmocom-bb 2>/dev/null)" ]; then \
		echo "  - cloning osmocom-bb ($(OSMOCOM_BB_REF))"; \
		rm -rf refs/osmocom-bb; \
		git clone https://gitea.osmocom.org/phone-side/osmocom-bb.git refs/osmocom-bb && (cd refs/osmocom-bb && git checkout $(OSMOCOM_BB_REF)); \
	elif [ "$(FORCE_FETCH)" = "1" ]; then \
		echo "  - updating osmocom-bb"; \
		(cd refs/osmocom-bb && git fetch origin $(OSMOCOM_BB_REF) && git checkout -f $(OSMOCOM_BB_REF)); \
	else echo "  - osmocom-bb exists and is populated (skip)"; fi

ifeq ($(BUILD_MODEM),1)
all: fetch-deps lib mobile modem
else
all: fetch-deps lib mobile
	@echo "[info] Modem skipped (BUILD_MODEM=$(BUILD_MODEM), PLATFORM=$(PLATFORM))"
endif

lib: fetch-deps _ensure_image
	@if [ "$(PLATFORM)" = "freertos" ]; then \
	  echo "[lib] libosmocore + FreeRTOS baked into image (PLATFORM=$(PLATFORM))"; \
	else \
	  echo "[lib] libosmocore baked into linux image (PLATFORM=$(PLATFORM))"; \
	fi
	@echo "[lib] To rebuild with new refs adjust Docker build args (FREERTOS_*_REF, LIBOSMOCORE_REF) and run: make PLATFORM=$(PLATFORM) lib" 

mobile: fetch-deps _ensure_image
	@if [ "$(PLATFORM)" = "freertos" ]; then echo "[freertos] Building mobile"; else echo "[linux] Building mobile"; fi
	@$(MOBILE_BUILD_CMD)
	@echo "Built mobile binary (PLATFORM=$(PLATFORM)): src/host/layer23/src/mobile/mobile"

modem: _ensure_image
	@if [ "$(PLATFORM)" = "freertos" ]; then \
		echo "[freertos] Modem build not supported (GPRS stack removed)"; \
	else \
		echo "[linux] Building modem"; \
		$(MODEM_BUILD_CMD); \
	fi

host-faketrx: fetch-deps _ensure_image
	@echo "[host-faketrx] Building FakeTRX set: mobile, trxcon (no firmware/osmocon/virtphy)"
	@if [ "$(PLATFORM)" = "freertos" ]; then src_env=scripts/freertos_env.sh; else src_env=scripts/linux_env.sh; fi; \
	  $(DOCKER_COMPOSE) run --rm --entrypoint /bin/bash $(SERVICE_$(shell echo $(PLATFORM) | tr a-z A-Z)) -lc "set -e; source $$src_env; \
	  cd src/host/layer23; autoreconf -fi; ./configure $$HOST_CONFARGS CFLAGS=\"$$CFLAGS\" LDFLAGS=\"$$LDFLAGS\" PKG_CONFIG_PATH=\"$$PKG_CONFIG_PATH\"; \
	  make -C src/common liblayer23.a; make -C src/mobile mobile; \
	  cd ../../trxcon; autoreconf -fi; ./configure $$HOST_CONFARGS; make; \
	  echo '[host-faketrx] Built:'; ls -1 src/host/layer23/src/mobile/mobile src/host/trxcon/src/trxcon 2>/dev/null || true"
	@echo "[host-faketrx] Done"
	@if [ "$(PLATFORM)" = "freertos" ]; then \
		echo "[freertos] Modem build not supported (GPRS stack removed)"; \
	else \
		echo "[linux] Building modem"; \
		$(MODEM_BUILD_CMD); \
	fi

_build_freertos: mobile

_ensure_image:
	@echo "Ensuring Docker image for PLATFORM=$(PLATFORM) is built"
	@$(BUILD_IMAGE_CMD)

clean:
	@if [ "$(origin PLATFORM)" = "command line" ]; then \
		echo "[clean] PLATFORM specified: $(PLATFORM)"; \
		if [ "$(PLATFORM)" = "freertos" ]; then $(MAKE) clean-freertos; \
		elif [ "$(PLATFORM)" = "linux" ]; then $(MAKE) clean-linux; \
		else echo "Unknown PLATFORM=$(PLATFORM)"; exit 2; fi; \
	else \
		echo "[clean] No PLATFORM specified: cleaning all platforms"; \
		$(MAKE) clean-freertos; \
		$(MAKE) clean-linux; \
	fi
	@echo "Clean aggregate complete"

clean-freertos:
	@echo "[clean-freertos] Cleaning FreeRTOS build artifacts"
	-$(DOCKER_COMPOSE) run --rm --entrypoint /bin/bash $(SERVICE_FREERTOS) -lc "cd src/host/layer23 && make distclean 2>/dev/null || true" >/dev/null 2>&1 || true
	@echo "[clean-freertos] Removing libosmocore freertos build dir"
	-$(DOCKER_COMPOSE) run --rm --entrypoint /bin/bash $(SERVICE_FREERTOS) -lc "cd deps/libosmocore && rm -rf build-freertos 2>/dev/null || true" >/dev/null 2>&1 || true
	- rm -rf deps/libosmocore/build-freertos 2>/dev/null || true
	@echo "[clean-freertos] Docker compose down + prune"
	-$(DOCKER_COMPOSE) down >/dev/null 2>&1 || true
	-docker system prune -f >/dev/null 2>&1 || true
	-docker volume prune -f >/dev/null 2>&1 || true
	@echo "[clean-freertos] Done"

clean-linux:
	@echo "[clean-linux] Cleaning Linux build artifacts"
	-$(DOCKER_COMPOSE) run --rm --entrypoint /bin/bash $(SERVICE_LINUX) -lc "cd src/host/layer23 && make distclean 2>/dev/null || true" >/dev/null 2>&1 || true
	- rm -rf build-linux 2>/dev/null || true
	@echo "[clean-linux] Docker compose down + prune (linux)"
	-$(DOCKER_COMPOSE) down >/dev/null 2>&1 || true
	@echo "[clean-linux] Done"