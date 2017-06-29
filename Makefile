# Arduino root
ARDUINO = /usr/share/arduino

# Target name
TARGET = blinky

# Board details
DEVICE = -D__AVR_ATmega328P__
BOARD  = eightanaloginputs
F_CPU  = 16000000L
MCU    = atmega328p
PARTNO = m328p

# Upload parameters
PORT     ?= /dev/uart0
PROTOCOL ?= arduino
BAUDRATE ?= 115200

# Sources
SRC_SUFFIXES = .c .cc .S .cpp
SRCS = $(wildcard $(addprefix src/*,$(SRC_SUFFIXES)))
OBJS = $(addsuffix .o,$(patsubst src%,build%,$(SRCS)))

# Computed values
ARDUINO_CORE = $(ARDUINO)/hardware/arduino/avr/cores/arduino
ARDUINO_PINS = $(ARDUINO)/hardware/arduino/avr/variants/$(BOARD)
ARDUINO_INCL = -I$(ARDUINO_PINS) -I$(ARDUINO_CORE)
ARDUINO_SRCS = $(filter-out $(ARDUINO_CORE)/main.cpp,$(wildcard $(addprefix $(ARDUINO_CORE)/*,$(SRC_SUFFIXES))))
ARDUINO_OBJS = $(addsuffix .o,$(patsubst $(ARDUINO_CORE)%,build/core%,$(ARDUINO_SRCS)))

# Tools and default flags
FLAGS    = -flto -fno-devirtualize -no-pie -fno-PIC -fno-PIE -Os -pipe -DF_CPU=$(F_CPU) -mmcu=$(MCU) $(DEVICE) $(ARDUINO_INCL)
CFLAGS   = -std=gnu11 $(FLAGS)
CXXFLAGS = -std=gnu++14 $(FLAGS)
LDFLAGS  = -flto -no-pie -DF_CPU=$(F_CPU) -mmcu=$(MCU)
ASFLAGS  = -no-pie -fno-PIC -fno-PIE -pipe -DF_CPU=$(F_CPU) -mmcu=$(MCU) $(DEVICE)
CC       = avr-gcc
CXX      = avr-g++
AS       = avr-as
OBJCOPY  = avr-objcopy
SIZE     = avr-size

# Targets
firmware: build/$(TARGET).hex

flash: build/$(TARGET).hex
	@echo "FLASH $@"
	@avrdude -c $(PROTOCOL) -P $(PORT) -p $(PARTNO) -D -U flash:w:build/$(TARGET).hex:i

build/$(TARGET).elf: $(OBJS) $(ARDUINO_OBJS)
	@echo "LD    $@"
	@$(CC) -o $@ $(LDFLAGS) $^ $(LOADLIBES) $(LDLIBS)

build/%.c.o: src/%.c
	@echo "CC    $@"
	@mkdir -p $(dir $@)
	@$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

build/%.cc.o: src/%.cc
	@echo "CXX   $@"
	@mkdir -p $(dir $@)
	@$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

build/%.cpp.o: src/%.cpp
	@echo "CXX   $@"
	@mkdir -p $(dir $@)
	@$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

build/%.S.o: src/%.S
	@echo "AS    $@"
	@mkdir -p $(dir $@)
	@$(CC) $(CPPFLAGS) $(ASFLAGS) -c $< -o $@

build/core/%.c.o: $(ARDUINO_CORE)/%.c
	@echo "CC    $@"
	@mkdir -p $(dir $@)
	@$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

build/core/%.cc.o: $(ARDUINO_CORE)/%.cc
	@echo "CXX   $@"
	@mkdir -p $(dir $@)
	@$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

build/core/%.cpp.o: $(ARDUINO_CORE)/%.cpp
	@echo "CXX   $@"
	@mkdir -p $(dir $@)
	@$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

build/core/%.S.o: $(ARDUINO_CORE)/%.S
	@echo "AS    $@"
	@mkdir -p $(dir $@)
	@$(CC) $(CPPFLAGS) $(ASFLAGS) -c $< -o $@

build/%.hex: build/%.elf
	@echo "HEX   $@"
	@$(OBJCOPY) -O ihex -j .text -j .data $< $@
	@$(SIZE) $@

clean:
	rm -rf build

.PHONY: clean firmware flash
.SUFFIXES:
