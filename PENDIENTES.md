# Pendientes · fallos, mejoras y cosas por limar

Lista del dueño. Él dicta los puntos y Claude solo los apunta aquí.

- **No se trabaja en ningún punto hasta que el dueño lo pida** ("haz el F2", "el de la puerta del baño").
- Cuando un punto está hecho y tiene el visto bueno, **se borra de la lista** (no se tacha) en el mismo commit.
- Cada punto lleva un código fijo (`F` fallo, `M` mejora, `L` por limar) y un número que **no se vuelve a usar**
  aunque el punto se borre, para que "haz el F2" siempre señale al mismo.
- Una línea por punto, con lo justo para reconocerlo: dónde pasa y cómo se ve. Si hace falta más detalle, se
  pone debajo con sangría.

## Fallos

_(ninguno por ahora)_

## Mejoras

_(ninguna por ahora)_

## Por limar

- **L9.** En «Elige edificio», con el Centro comercial cerrado (candado), la tarjeta de los Apartamentos sale más ancha
  que la del candado (unos 312 px contra 300), porque lleva debajo el selector de alerta y este la ensancha. Con los
  dos abiertos miden lo mismo. Que las dos tarjetas midan siempre igual de ancho.
- **L10.** En «Elige edificio», las líneas con el punto «·» («4 plantas y azotea · 1 intento», «Completado ×1 · mejor
  tiempo…») salen unos 5 px más bajas que el resto de líneas del mismo tamaño. Parece que la letra del juego no tiene el
  «·» y lo dibuja con otra tipografía, que hace la línea más alta (la de las plantas mide 23 px en vez de 16). Ver si
  se puede evitar (otro separador que sí esté en la letra, o añadir el «·» a la letra) y mirar si pasa igual en otras
  pantallas.
