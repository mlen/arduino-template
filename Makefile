# Arduino root
ARDUINO  = /usr/share/arduino

# Target name
TARGET   = blinky

# CPU speed and model
F_CPU    = 16000000L
MCU      = atmega328p
PARTNO   = m328p

# Upload parameters
PORT     = /dev/uart0
PROTOCOL = arduino
BAUDRATE = 115200

# Tools and default flags
CFLAGS   = -no-pie -fno-PIC -fno-PIE -Os -pipe -DF_CPU=$(F_CPU) -mmcu=$(MCU)
CXXFLAGS = $(CFLAGS)
CC       = avr-gcc
CXX      = avr-g++
AS       = avr-as
OBJCOPY  = avr-objcopy
SIZE     = avr-size

firmware: $(TARGET).hex

flash: $(TARGET).hex
	avrdude -c $(PROTOCOL) -P $(PORT) -p $(PARTNO) -v -U flash:w:$(TARGET).hex:i

$(TARGET).elf: $(TARGET).o
	$(CC) -o $@ $(CFLAGS) $<

%.hex: %.elf
	$(OBJCOPY) -O ihex -j .text -j .data $< $@
	$(SIZE) $@

clean:
	rm -f *.hex *.elf *.o

.PHONY: clean
