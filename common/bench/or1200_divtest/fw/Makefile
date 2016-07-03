# or1200-divtest fw Makefile
# 2016, rok.krajnc@gmail.com

### paths ###
HEX2MEM_DIR = ../../sw/hex2mem/
HEX2MIF_DIR = ../../sw/hex2mif/


### tools ###

# make sure or32-elf-gcc is in path, or comment next line and set path
OR32_TOOLCHAIN_PATH=

ifndef OR32_TOOLCHAIN_PATH
OR32_TOOLCHAIN_PATH=/opt/or32-elf-1.0rc1/bin/
endif

ifndef CROSS_COMPILE
CROSS_COMPILE = $(OR32_TOOLCHAIN_PATH)or32-elf-
endif


### programs ###
AS      = $(CROSS_COMPILE)as
LD      = $(CROSS_COMPILE)ld
CC      = $(CROSS_COMPILE)gcc
AR      = $(CROSS_COMPILE)ar
NM      = $(CROSS_COMPILE)nm
STRIP   = $(CROSS_COMPILE)strip
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump
RANLIB  = $(CROSS_COMPILE)ranlib
XXD     = xxd
HEX2MEM = $(HEX2MEM_DIR)hex2mem.py
HEX2MIF = $(HEX2MIF_DIR)hex2mif.py


### flags ###
CFLAGS +=   -W -Wall -Wpadded -Winline -std=gnu99 -g \
            -O0 \
            -fno-builtin -nostdlib \
            -mhard-mul -mhard-div

#            -Wl,--relax \
#            -fno-strict-aliasing \
#            -fomit-frame-pointer -ffreestanding -static -combine -fwhole-program \
#            -msoft-mul -msoft-div

LDFLAGS +=

XXDFLAGS=-ps -c 4
HEXFLAGS=-w 8 -s 1024 -n


### variables ###
BUILD_USER=\"$(USER)\"
BUILD_T=$$(date +%Y-%m-%d)
BUILD_TIME=\"$(BUILD_T)\"
#BUILD_N=$$(cat build_num.txt)
#BUILD_NUM=\"$(BUILD_N)\"
#BUILD_R=$$(git rev-parse --verify HEAD)
#BUILD_REV=\"$(BUILD_R)\"

BINDIR=bin
OBJDIR=obj


### fw specific ###

# include dirs
CINCLUDES +=

# headers
HEADERS=spr_defs.h or32_defs.h

# asm sources
ASM_SOURCES=start.S

# common sources
COMMON_SOURCES=main.c
 
# all sources
ALL_SOURCES = $(ASM_SOURCES) $(COMMON_SOURCES)

# linker script
RAM_LD=ram.ld
LD_SCRIPT=$(RAM_LD)
CFLAGS+=-DRAM_FW
MSG=Making RAM image ...


### build rules ###

# all
all: bin bin/or1200_divtest.hex

bin:
	@mkdir -p bin

bin/or1200_divtest.or32: bin Makefile $(LD_SCRIPT) $(ALL_SOURCES)
	@echo $(MSG)
	@echo $@
	@$(CC) -Wl,-Map,$(@:.or32=.map) -D__BUILD_USER=$(BUILD_USER) -D__BUILD_TIME=$(BUILD_TIME) -D__BUILD_NUM=$(BUILD_NUM) -D__BUILD_REV=$(BUILD_REV) $(CFLAGS) $(CINCLUDES) $(ALL_SOURCES) -T$(LD_SCRIPT) -o $@
	@$(OBJDUMP) -DSx $@ > $(@:.or32=.dis.S)

bin/or1200_divtest.bin: bin/or1200_divtest.or32
	@echo $@
	@$(OBJCOPY) -O binary $< $@

bin/or1200_divtest.hex : bin/or1200_divtest.bin
	@echo $@
	@$(XXD) $(XXDFLAGS) $(@:.hex=.bin) > $@

# clean
clean:
	@echo clean
	@rm -rf ./bin

