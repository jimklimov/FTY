# This Makefile is processed both for cross-compiling with
#   gmake BUILD_ARCH=armv7l build/...
# and for native compilation. The "ifeq" below makes it have
# no effect for the latter case.

# NOTE: This recipe is a work in progress for fun and PoC
# There are some components that can not get built with just
# cross-compiler and *:armhf packages, and not all packages
# for different ARCHs may be installed in same env on debian.
# Maybe a dedicated container might do...

OE_ARCH:=$(strip $(shell uname -m))

HELP_ADDONS += "Makefile-local note: This build scenario is customized for"
ifeq ($(OE_ARCH),armv7l)
HELP_ADDONS += "Native ARM builds, OE_ARCH='$(OE_ARCH)'"
arm:
	@echo "Native ARM: OE_ARCH='$(OE_ARCH)'"
else
HELP_ADDONS += "Crosslink ARM builds, OE_ARCH='$(OE_ARCH)'"
arm:
	@echo "Crosslink ARM: OE_ARCH='$(OE_ARCH)'"


BUILD_ARCH = armv7l
ARCH = armv7l
export ARCH
export BUILD_ARCH

CROSS_PREFIX = arm-linux-gnueabihf
CROSS_COMPILE_PREFIX = $(CROSS_PREFIX)-
export CROSS_COMPILE_PREFIX
export CROSS_PREFIX

### Not quite linaro, but...
#LINARO_ROOTDIR=/usr/local/uclinux-dist/arm-linux-gnueabi-tools-20140823
#CROSS_PREFIX = arm-linux-gnueabi-20140823
#CROSS_COMPILE_PREFIX=arm-linux-gnueabi-20140823-

#LINARO_ROOTDIR=/opt/gcc-linaro-4.9-2014.11-x86_64_arm-linux-gnueabihf
#LINARO_ROOTDIR=/opt/gcc-linaro-4.9-2015.02-3-x86_64_arm-linux-gnueabihf
LINARO_ROOTDIR=/opt/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf
#LINARO_ROOTDIR=/opt/gcc-linaro-6.3.1-2017.05-x86_64_arm-linux-gnueabihf

PATH:=/usr/lib/ccache:$(LINARO_ROOTDIR)/$(CROSS_PREFIX)/libc/sbin:$(LINARO_ROOTDIR)/$(CROSS_PREFIX)/libc/usr/sbin:$(LINARO_ROOTDIR)/$(CROSS_PREFIX)/libc/usr/bin:$(LINARO_ROOTDIR)/bin:$(PATH)
export PATH

CROSS_INCLUDES =
CROSS_INCLUDES += -isystem$(LINARO_ROOTDIR)/include
CROSS_INCLUDES += -isystem$(LINARO_ROOTDIR)/$(CROSS_PREFIX)/libc/usr/include
CROSS_INCLUDES += -isystem$(LINARO_ROOTDIR)/$(CROSS_PREFIX)/include
CROSS_INCLUDES += -isystem/usr/include
CROSS_INCLUDES += -isystem/usr/include/$(CROSS_PREFIX)

###MARCH = -march=armv7 -mfloat-abi=hard
# Customize for our IPC CPUs:
# Marvell Armada 375:
MARCH = -march=armv7-a -mcpu=cortex-a9 -mfpu=neon -mhard-float -mthumb
QEMU_CPU = cortex-a9
export QEMU_CPU

CROSS_CFLAGS = $(MARCH)
CROSS_CFLAGS += -fPIC
#CROSS_CFLAGS += --sysroot=/srv/libvirt/rootfs/fty-arm-devel/

CFLAGS += $(CROSS_INCLUDES) $(CROSS_CFLAGS)
CXXFLAGS += $(CROSS_INCLUDES) $(CROSS_CFLAGS)
CPPFLAGS += $(CROSS_INCLUDES)

LDFLAGS += -L$(LINARO_ROOTDIR)/lib
LDFLAGS += -L$(LINARO_ROOTDIR)/$(CROSS_PREFIX)/libc/usr/lib
LDFLAGS += -L$(LINARO_ROOTDIR)/$(CROSS_PREFIX)/libc/lib
LDFLAGS += -L$(LINARO_ROOTDIR)/$(CROSS_PREFIX)/lib
LDFLAGS += -L/lib/$(CROSS_PREFIX)
LDFLAGS += -L/usr/lib/$(CROSS_PREFIX)

LDFLAGS += -Wl,--rpath,$(LINARO_ROOTDIR)/lib
LDFLAGS += -Wl,--rpath,$(LINARO_ROOTDIR)/$(CROSS_PREFIX)/libc/usr/lib
LDFLAGS += -Wl,--rpath,$(LINARO_ROOTDIR)/$(CROSS_PREFIX)/libc/lib
LDFLAGS += -Wl,--rpath,$(LINARO_ROOTDIR)/$(CROSS_PREFIX)/lib
LDFLAGS += -Wl,--rpath,/lib/$(CROSS_PREFIX)
LDFLAGS += -Wl,--rpath,/usr/lib/$(CROSS_PREFIX)

# Somehow, cross-builds miss this one
LDFLAGS += -lm

# To avoid use of ccache export CCACHE=" "
ifeq ($(CCACHE),)
  CCACHE=$(shell which ccache 2>/dev/null | egrep '^/' | head -1)
endif

#JOBS=-j$(shell cat /proc/cpuinfo | grep ^processor | wc -l)
#export JOBS

#CC=$(CROSS_COMPILE_PREFIX)gcc$(GCC_VERSION_SUFFIX)
CC=$(CCACHE) $(CROSS_COMPILE_PREFIX)gcc$(GCC_VERSION_SUFFIX)
CXX=$(CCACHE) $(CROSS_COMPILE_PREFIX)g++$(GCC_VERSION_SUFFIX)
AR=$(CROSS_COMPILE_PREFIX)ar
LD=$(CROSS_COMPILE_PREFIX)ld
NM=$(CROSS_COMPILE_PREFIX)nm
STRIP=$(CROSS_COMPILE_PREFIX)strip
OBJDUMP=$(CROSS_COMPILE_PREFIX)objdump
OBJCOPY=$(CROSS_COMPILE_PREFIX)objcopy
RANLIB=$(CROSS_COMPILE_PREFIX)ranlib
AS=$(CROSS_COMPILE_PREFIX)as
export CC
export CXX
export AR
export LD
export NM
export STRIP
export OBJDUMP
export OBJCOPY
export RANLIB
export AS

CONFIG_OPTS += --enable-cross-compile --host=$(CROSS_PREFIX) --target=$(CROSS_PREFIX) --build=x86_64-linux-gnu

# Custom options for gsl
MAKE_COMMON_ARGS_gsl = CCNAME="$(CC)" CCPLUS="$(CXX)" CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)"

# Custom options for cxxtools : ensure C++11 for the cross-compiler,
# and don't use unsupported ARM instructions via custom ASM code
CXXTOOLS_ATOMICITY_PTHREAD=1
export CXXTOOLS_ATOMICITY_PTHREAD

CONFIG_OPTS_cxxtools = CXXFLAGS="$(CXXFLAGS) -std=c++11" CFLAGS="$(CFLAGS) -std=c11"
CONFIG_OPTS_cxxtools += --with-atomictype=pthread

CONFIG_OPTS_tntnet = CXXTOOLS_ATOMICITY_PTHREAD=1 CXXFLAGS="$(CXXFLAGS) -std=c++11 -DCXXTOOLS_ATOMICITY_PTHREAD=1" CFLAGS="$(CFLAGS) -std=c11 -DCXXTOOLS_ATOMICITY_PTHREAD=1"
CONFIG_OPTS_tntdb  = CXXTOOLS_ATOMICITY_PTHREAD=1 CXXFLAGS="$(CXXFLAGS) -std=c++11 -DCXXTOOLS_ATOMICITY_PTHREAD=1" CFLAGS="$(CFLAGS) -std=c11 -DCXXTOOLS_ATOMICITY_PTHREAD=1"

#CONFIG_OPTS_nut = CXXFLAGS="$(CXXFLAGS) -std=c++11" CFLAGS="$(CFLAGS) -std=c11"

# Custom options for fty-mdns-sd failing with system headers
#CONFIG_OPTS_fty-mdns-sd = --disable-Werror
endif
