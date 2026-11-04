# Pendientes · fallos, mejoras y cosas por limar

Lista del dueño. Él dicta los puntos y Claude solo los apunta aquí.

- **No se trabaja en ningún punto hasta que el dueño lo pida** ("haz el F2", "el de la puerta del baño").
- Cuando un punto está hecho y tiene el visto bueno, **se borra de la lista** (no se tacha) en el mismo commit.
- Cada punto lleva un código fijo (`F` fallo, `M` mejora, `L` por limar) y un número que **no se vuelve a usar**
  aunque el punto se borre, para que "haz el F2" siempre señale al mismo.
- Una línea por punto, con lo justo para reconocerlo: dónde pasa y cómo se ve. Si hace falta más detalle, se
  pone debajo con sangría.

## Fallos

## Mejoras

- **M77** Centro comercial fijo, como los apartamentos: la galería y cada tienda, siempre iguales y con lo de dentro
  puesto a mano, en vez de generarse al azar (hoy `tienda.gd` genera cada tienda). Para más adelante.
- **M78** Botiquines de los apartamentos: uno solo por apartamento en vez de dos, y en un baño elegido al azar (no
  siempre el mismo). Hoy los armaritos de la planta van por turnos (un botiquín y luego dos de vendas:
  `armaritos` en `planta.gd`). Para más adelante.
- **M79** Zombi dependienta: cuando grita, que encima de ella salga «!!!AAAHHH¡¡¡» (hoy sale «¡OFERTAS!»:
  `gritar` en `zombi_dependienta.gd`). Para más adelante.


## Por limar

