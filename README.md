# Pokelua-rng-gen3
Script para ver el comportamiento del RNG en Pokemon Esmeralda.

Este script muestra los avances RNG segun los frames del juego (en emulador el juego va usualmente a 60 Frames Por Segundo), indica con el texto "R multiple" cuando hay más de 1 avance en 1 frame, eso podría indicar que sucedió algun evento aleatorio, o que se esta en batalla (donde el RNG avanza el doble de rapido). 

Por defecto este script funciona para Esmeralda, pues esta configurada con la semilla 0.
Aun estoy viendo la forma de que funcione para los otros juegos de la generación 3.

Nota1: El "16 bits" muestra el RNG en su valor según se utiliza en las mecánicas del juego, el "Hexa" muestra el valor completo (32 bits) según resulta directamente del algoritmo PRNG (LCG).

Nota2: El script lo probe con el emulador mGBA.

# Créditos
Para hacer este script me base en este:
https://github.com/Real96/PokeLua
