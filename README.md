# Pokelua-rng-gen3
Script para ver el comportamiento del RNG en la gen3.

Por defecto muestra los avances segun los frames, indica con el texto "RNG multiple" cuando hay más de 1 avance en 1 frame, eso podría indicar que sucedió algun evento aleatorio, o que se esta en batalla (donde el RNG avanza el doble de rapido). 

Este script por defecto funciona para Esmeralda pues esta configurada con la semilla 0, pero puede funcionar para los otros juegos de la generación 3, siempre y cuando se sepa su semilla. 

-El "16 bits" muestra el RNG en su valor según se utiliza en las mecánicas del juego.
-El "Hexa" muestra el valor completo (32 bits) según resulta directamente del algoritmo PRNG (LCG).

Nota: El script lo probe con el emulador mGBA.

# Crésitos
Para hacer este script me base en este:
https://github.com/Real96/PokeLua
