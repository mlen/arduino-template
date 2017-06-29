# Arduino root
USE_ARDUINO ?= yes
ARDUINO     ?= /usr/share/arduino

# Check for variable definitions
CHECK_VARIABLES = TARGET F_CPU DEVICE BOARD MCU PARTNO
$(foreach v,$(CHECK_VARIABLES), $(if $(findstring undefined,$(origin $v)),$(error Error: variable $v is not defined)))

# Upload parameters
PORT     ?= /dev/uart0
PROTOCOL ?= arduino
BAUDRATE ?= 115200

# Sources
SRC_SUFFIXES = .c .cc .S .cpp
SRCS = $(wildcard $(addprefix src/*,$(SRC_SUFFIXES)))
OBJS = $(addsuffix .o,$(patsubst src%,build%,$(SRCS)))

# Computed values
ifeq ($(USE_ARDUINO),yes)
	ARDUINO_LIBS = $(ARDUINO)/hardware/arduino/avr/libraries
	LIBS_DIRS = $(foreach lib,$(LIBS),$(ARDUINO_LIBS)/$(lib)/src)
	LIBS_SRCS = $(foreach lib,$(LIBS_DIRS),$(wildcard $(addprefix $(lib)/*,$(SRC_SUFFIXES))))
	LIBS_INCL = $(foreach lib,$(LIBS_DIRS),-I$(lib))
	LIBS_OBJS = $(foreach lib,$(LIBS),$(addsuffix .o,$(patsubst $(ARDUINO_LIBS)/$(lib)/src%,build%,$(LIBS_SRCS))))

	ARDUINO_CORE = $(ARDUINO)/hardware/arduino/avr/cores/arduino
	ARDUINO_PINS = $(ARDUINO)/hardware/arduino/avr/variants/$(BOARD)
	ARDUINO_INCL = -I$(ARDUINO_PINS) -I$(ARDUINO_CORE)
	ARDUINO_SRCS = $(filter-out $(ARDUINO_CORE)/main.cpp,$(wildcard $(addprefix $(ARDUINO_CORE)/*,$(SRC_SUFFIXES))))
	ARDUINO_OBJS = $(addsuffix .o,$(patsubst $(ARDUINO_CORE)%,build%,$(ARDUINO_SRCS)))
endif

VPATH = src $(ARDUINO_CORE) $(LIBS_DIRS)

# Tools and default flags
FLAGS    = -flto -fno-devirtualize -no-pie -fno-PIC -fno-PIE -Os -pipe -DF_CPU=$(F_CPU) -mmcu=$(MCU) -D__AVR_$(DEVICE)__ $(ARDUINO_INCL) $(LIBS_INCL)
CFLAGS   = -std=gnu11 $(FLAGS) $(CUSTOM_CFLAGS)
CXXFLAGS = -std=gnu++14 $(FLAGS) $(CUSTOM_CXXFLAGS)
LDFLAGS  = -flto -no-pie -DF_CPU=$(F_CPU) -mmcu=$(MCU) $(CUSTOM_LDFLAGS)
ASFLAGS  = -no-pie -fno-PIC -fno-PIE -pipe -DF_CPU=$(F_CPU) -mmcu=$(MCU) -D__AVR_$(DEVICE)__ $(CUSTOM_ASFLAGS)
CC       = avr-gcc
CXX      = avr-g++
AS       = avr-as
OBJCOPY  = avr-objcopy
SIZE     = avr-size

# Targets
firmware: build/$(TARGET).hex

flash: build/$(TARGET).hex
	@echo "FLASH $^"
	@avrdude -c $(PROTOCOL) -P $(PORT) -p $(PARTNO) -D -U flash:w:build/$(TARGET).hex:i

build/$(TARGET).elf: $(OBJS) $(ARDUINO_OBJS) $(LIBS_OBJS)
	@echo "LD    $@"
	@$(CC) -o $@ $(LDFLAGS) $^ $(LOADLIBES) $(LDLIBS)

build/%.c.o: %.c
	@echo "CC    $@"
	@mkdir -p $(dir $@)
	@$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

build/%.cc.o: %.cc
	@echo "CXX   $@"
	@mkdir -p $(dir $@)
	@$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

build/%.cpp.o: %.cpp
	@echo "CXX   $@"
	@mkdir -p $(dir $@)
	@$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

build/%.S.o: %.S
	@echo "AS    $@"
	@mkdir -p $(dir $@)
	@$(CC) $(CPPFLAGS) $(ASFLAGS) -c $< -o $@

build/%.hex: build/%.elf
	@echo "HEX   $@"
	@$(OBJCOPY) -O ihex -j .text -j .data $< $@
	@$(SIZE) $@

clean:
	$(RM) -r build

.PHONY: clean firmware flash
