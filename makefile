###############################################################################
# Copyright (c) 2019 Alexander Kubrak. Apache-2.0 license. 
###############################################################################

#Toolchain: https://developer.arm.com/open-source/gnu-toolchain/gnu-rm/downloads

OUTDIR       = build
LIBDIR       = libraries
COMPILERDIR ?= ~/path/to/gcc-arm-none-eabi-8-2019-q3-update/bin

CPU          = cortex-m7
FPU          = fpv5-sp-d16
FLOATABI     = hard
OPTIMIZATION = -O0 -g3 -ggdb

DEFINITIONS  = -DNDEBUG \
               -DTOOLCHAIN_GCC \
               -DTOOLCHAIN_GCC_ARM \
               -D__CORTEX_M7 \
               -D__FPU_PRESENT \
               -DARM_MATH_CM7 \
               -DSTM32F7 \
               -DSTM32F746 \
               -DSTM32F746xG \
               -DSTM32F746NG \
               -DUSE_HAL_DRIVER \
               -DDISCO_F746NG \
               -DTARGET_DISCO_F746NG \
               -DDEVICE_INTERRUPTIN \
               -DDEVICE_SERIAL \
               -DDEVICE_FLASH \
               -D__MBED__=1 \
               -DHSE_VALUE=25000000 \
               -DMBED_APPLICATION_SUPPORT=1 \
               -DMBED_CONF_PLATFORM_FORCE_NON_COPYABLE_ERROR=0 \
               -DMBED_CONF_PLATFORM_DEFAULT_SERIAL_BAUD_RATE=9600 \
               -DMBED_CONF_PLATFORM_STDIO_CONVERT_NEWLINES=0 \
               -DMBED_CONF_TARGET_LSE_AVAILABLE=1 \
               -DMBED_CONF_PLATFORM_STDIO_BAUD_RATE=9600 \
               -DCLOCK_SOURCE=USE_PLL_HSE_XTAL \
               -DMBED_CONF_PLATFORM_STDIO_FLUSH_AT_EXIT=1 \
               -DMBED_CONF_TARGET_USB_SPEED=1 \
               -DFLASH_SIZE='((uint32_t)0x100000)' \
               -DADDR_FLASH_SECTOR_0='((uint32_t)0x08000000)'\
               -DADDR_FLASH_SECTOR_1='((uint32_t)0x08008000)'\
               -DADDR_FLASH_SECTOR_2='((uint32_t)0x08010000)'\
               -DADDR_FLASH_SECTOR_3='((uint32_t)0x08018000)'\
               -DADDR_FLASH_SECTOR_4='((uint32_t)0x08020000)'\
               -DADDR_FLASH_SECTOR_5='((uint32_t)0x08040000)'\
               -DADDR_FLASH_SECTOR_6='((uint32_t)0x08080000)'\
               -DADDR_FLASH_SECTOR_7='((uint32_t)0x080C0000)'

###############################################################################
# resources
###############################################################################

PROJDIR  := $(shell pwd)
PROJNAME := $(notdir $(PROJDIR))
FOLDERS  := $(shell ls -R . | grep : | sed 's/://')

ASSOURCES  := $(wildcard $(addsuffix /*.S,   $(FOLDERS)))
CSOURCES   := $(wildcard $(addsuffix /*.c,   $(FOLDERS)))
CPPSOURCES := $(wildcard $(addsuffix /*.cpp, $(FOLDERS)))

HEADERS := $(addprefix -I", $(addsuffix ", $(FOLDERS)))

LINKERS := $(addprefix -T", $(addsuffix ", $(wildcard $(addsuffix /*.ld, $(FOLDERS)))))

OBJECTS := $(addprefix $(OUTDIR)/, $(ASSOURCES:.S=.o))
OBJECTS += $(addprefix $(OUTDIR)/, $(CSOURCES:.c=.o))
OBJECTS += $(addprefix $(OUTDIR)/, $(CPPSOURCES:.cpp=.o))

LIBRARIES := $(addprefix -l, \
               $(subst .a, , \
                 $(subst $(LIBDIR)/lib, , \
                   $(wildcard $(addsuffix /*.a, $(LIBDIR))) \
                  ) \
                ) \
              )
  
###############################################################################
# compiler settings
###############################################################################

     CC = $(COMPILERDIR)/arm-none-eabi-gcc
    CPP = $(COMPILERDIR)/arm-none-eabi-g++
OBJCOPY = $(COMPILERDIR)/arm-none-eabi-objcopy
   SIZE = $(COMPILERDIR)/arm-none-eabi-size

CORE = -mcpu=$(CPU) -mthumb -mfloat-abi=$(FLOATABI) -mfpu=$(FPU)

FLAGS = $(CORE) $(OPTIMIZATION) $(DEFINITIONS) $(HEADERS) -MMD \
        -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers \
        -fmessage-length=0 -fno-exceptions -fno-builtin -Wno-strict-aliasing \
        -fno-delete-null-pointer-checks -Wno-unused-variable \
        -Wno-sign-compare -Wno-maybe-uninitialized \
        -ffunction-sections -fdata-sections -funsigned-char \
        -fomit-frame-pointer

ASFLAGS = $(FLAGS) -x assembler-with-cpp -g

CFLAGS = $(FLAGS) -std=gnu99

CPPFLAGS = $(FLAGS) -std=gnu++98 -fno-rtti -Wvla

LDFLAGS = $(CORE) $(OPTIMIZATION) $(LINKERS) \
          -Wl,-Map=$(OUTDIR)/$(PROJNAME).map \
          -Wl,--gc-sections -lm -Wl,--wrap,main -Wl,--wrap,_malloc_r \
          -Wl,--wrap,_free_r -Wl,--wrap,_realloc_r -Wl,--wrap,_memalign_r \
          -Wl,--wrap,_calloc_r -Wl,--wrap,exit -Wl,--wrap,atexit \
          -Wl,-n

###############################################################################
# build targets
###############################################################################

-include $(OBJECTS:.o=.d)

.PHONY: all build clean

all: $(OUTDIR)/$(PROJNAME).elf \
     $(OUTDIR)/$(PROJNAME).bin \
     $(OUTDIR)/$(PROJNAME).siz

build: all

$(OUTDIR)/$(PROJNAME).elf: $(OBJECTS)
	@echo linker: $@
	@$(CPP) $(LDFLAGS) -o $@ $^ -L$(LIBDIR) $(LIBRARIES)

$(OUTDIR)/$(PROJNAME).bin: $(OUTDIR)/$(PROJNAME).elf
	@echo binary: $@
	@$(OBJCOPY) -O binary $^ $@

$(OUTDIR)/$(PROJNAME).siz: $(OUTDIR)/$(PROJNAME).elf
	@$(SIZE) --format=berkeley $^

$(OUTDIR)/%.o: %.S
	@echo gcc: $(@F)
	@mkdir -p $(@D)
	@$(CC) -c $(ASFLAGS) '$<' -o '$@'

$(OUTDIR)/%.o: %.c
	@echo gcc: $(@F)
	@mkdir -p $(@D)
	@$(CC) -c $(CFLAGS) '$<' -o '$@'

$(OUTDIR)/%.o: %.cpp
	@echo g++: $(@F)
	@mkdir -p $(@D)
	@$(CPP) -c $(CPPFLAGS) '$<' -o '$@'

$(OBJECTS): makefile

clean:
	@rm -rf $(OUTDIR)

###############################################################################
