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
- **M80** Zombi dependienta: su grito, en vez de meter prisa (hoy despierta la tienda y los zombis van un 30 % más
  rápido durante 5 s, `meter_prisa`), pone a los zombis una barrera de invulnerabilidad que no se quita hasta que
  ella muere. Para más adelante.
- **M81** Centro comercial: en cada tienda, dentro del almacén, un baño para los empleados con un botiquín (en su
  armarito, como los de los apartamentos). Para más adelante (va bien con la M77).
- **M82** Jefe cocinero, más difícil: su sala (la Cocina central) lleva muebles de cocina en las paredes que
  sueltan aceite ardiendo, y ese aceite se va extendiendo por la habitación durante el combate (aparte de la
  sartén que ya tira él, `cocinero.gd` y `charco.gd`). Para más adelante.
- **M83** Guardia de la tarjeta (pasillo del centro comercial): que siga huyendo, pero más deprisa para que cueste
  más pillarlo (hoy huye a 165 y Johnny anda a 210), que toque el silbato más a menudo (hoy al verte y a media vida)
  y que lleguen más guardias a protegerle, que también corran como él. En `zombi_guardia.gd` (los refuerzos, la
  señal «silbato» de la partida). Para más adelante.
- **M84** Centro comercial: muchos más zombis en cada tienda, que ahora casi no hay ninguno. Los zombis de más de
  la M19 (`EXTRA_POR_SALA` en `planta.gd`, `horda`) se pusieron solo en los apartamentos y las tiendas se quedaron
  con el presupuesto de antes. Para más adelante.
- **M85** Jefe mascota (la Juguetería): durante el combate salen sin parar zombis jóvenes de los que corren
  (el rápido, «El crío» del bestiario). En `mascota.gd`. Para más adelante.
- **M86** Centro comercial: las páginas del dosier las sueltan también científicos muertos de Velaria (con su bata,
  como en los apartamentos), y se borran los que hay ahora (el jefe de seguridad y la secretaria, dibujados con formas:
  `cientifico.gd`). Para más adelante.


## Por limar

