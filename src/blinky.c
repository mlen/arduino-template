#include <Arduino.h>

#define LED_BUILTIN 13

int main() {
    init();

    pinMode(LED_BUILTIN, OUTPUT);

    while (true) {
        digitalWrite(LED_BUILTIN, HIGH);
        delay(1000);
        digitalWrite(LED_BUILTIN, LOW);
        delay(1000);
    }

    return 0;
}
