################################################################################
# Paths to Trusted Services source and output
################################################################################
TS_PATH			?= $(ROOT)/trusted-services
TS_BUILD_PATH		?= $(OUT_PATH)/ts-build
TS_INSTALL_PREFIX	?= $(OUT_PATH)/ts-install

################################################################################
# Secure Partitions
################################################################################
.PHONY: ffa-sp-all ffa-sp-all-clean ffa-sp-all-realclean

optee-os-common: ffa-sp-all
optee-os-clean: ffa-sp-all-clean

ffa-sp-all-realclean:
	rm -rf $(TS_INSTALL_PREFIX)/opteesp

ifneq ($(COMPILE_S_USER),64)
$(error Trusted Services SPs only support AArch64)
endif

# Helper macro to build and install Trusted Services Secure Partitions (SPs).
# Invokes CMake to configure, and make to build and install the SP. (CMake's
# Makefile generator backend is used, we can run make in the build directory).
# Adds the SP output image to the optee_os_sp_paths list and complies the SP
# manifest dts to dtb.
#
# For information about the additional dependencies of the project, please see
# https://trusted-services.readthedocs.io/en/latest/developer/software-requirements.html
#
# Parameter list:
# 1 - SP deployment name (e.g. internal-trusted-storage, crypto, etc.)
# 2 - SP canonical UUID (e.g. dc1eef48-b17a-4ccf-ac8b-dfcff7711b14)
# 3 - SP additional build flags (e.g. -DTS_PLATFORM=<...>)
define build-sp
.PHONY: ffa-$1-sp
ffa-$1-sp:
	CROSS_COMPILE=$(subst $(CCACHE),,$(CROSS_COMPILE_S_USER)) cmake -G"Unix Makefiles" \
		-S $(TS_PATH)/deployments/$1/opteesp -B $(TS_BUILD_PATH)/$1 \
		-DCMAKE_INSTALL_PREFIX=$(TS_INSTALL_PREFIX) \
		-DCMAKE_C_COMPILER_LAUNCHER=$(CCACHE) $(SP_COMMON_FLAGS) $3
	$$(MAKE) -C $(TS_BUILD_PATH)/$1 install
	dtc -I dts -O dtb -o $(TS_INSTALL_PREFIX)/opteesp/manifest/$2.dtb \
				$(TS_INSTALL_PREFIX)/opteesp/manifest/$2.dts

.PHONY: ffa-$1-sp-clean
ffa-$1-sp-clean:
	$$(MAKE) -C $(TS_BUILD_PATH)/$1 clean

.PHONY: ffa-$1-sp-realclean
ffa-$1-sp-realclean:
	rm -rf $(TS_BUILD_PATH)/$1

ffa-sp-all: ffa-$1-sp
ffa-sp-all-clean: ffa-$1-sp-clean
ffa-sp-all-realclean: ffa-$1-sp-realclean

optee_os_sp_paths += $(TS_INSTALL_PREFIX)/opteesp/bin/$2.stripped.elf
endef

# Add the list of SP paths to the optee_os config
OPTEE_OS_COMMON_EXTRA_FLAGS += SP_PATHS="$(optee_os_sp_paths)"
