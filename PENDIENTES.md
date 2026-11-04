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
- **M80** Zombi dependienta: su grito, en vez de meter prisa (hoy despierta la tienda y los zombis van un 30 % más
  rápido durante 5 s, `meter_prisa`), pone a los zombis una barrera de invulnerabilidad que no se quita hasta que
  ella muere. Para más adelante.
- **M81** Centro comercial: en cada tienda, dentro del almacén, un baño para los empleados con un botiquín (en su
  armarito, como los de los apartamentos). Para más adelante (va bien con la M77).
- **M82** Jefe cocinero, más difícil: su sala (la Cocina central) lleva muebles de cocina en las paredes que
  sueltan aceite ardiendo, y ese aceite se va extendiendo por la habitación durante el combate (aparte de la
  sartén que ya tira él, `cocinero.gd` y `charco.gd`). Para más adelante.


## Por limar

