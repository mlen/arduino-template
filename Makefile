# Target name
TARGET = blinky

# Board details
F_CPU  = 16000000L
DEVICE = ATmega328P
BOARD  = eightanaloginputs
MCU    = atmega328p
PARTNO = m328p

# Custom libs
# LIBS = HID

include arduino.mk
