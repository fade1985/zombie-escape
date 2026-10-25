# El trailer

El trailer lo graba el propio juego: Johnny juega solo una serie de escenas preparadas, con los textos en pantalla,
y al final sale el logo. Así sale siempre igual de limpio y se vuelve a sacar con un comando cada vez que cambien
los dibujos.

## Sacarlo

Desde la carpeta del juego:

```
py tools/trailer.py
```

Tarda unos 6-10 minutos (el Movie Maker de Godot graba fotograma a fotograma, más despacio que de verdad) y deja en
`exportar/trailer/` (no va en git):

- `trailer.mp4`: el trailer, 1920×1080 a 60 fps, con los sonidos del juego y la canción «Turno de noche».
- `trailer.gif`: 6 segundos de pelea, pequeño, para redes y la página de Steam.
- `fotogramas/`: lo grabado, por si se quiere montar otra vez (`py tools/trailer.py --montar`, en segundos) con otra
  música u otro volumen. Ocupa unos gigas: se puede borrar.

Para verlo sin grabar (con la ventana normal, para probar cambios): `"<Godot>_console.exe" --path . -- --captura --trailer`.

## Cómo va

- **Las escenas y los textos:** `scripts/pruebas/trailer.gd` (`grabar_trailer()`), una escena detrás de otra. Cada
  una monta un sitio (`entrar()`), le mete zombis (`soltar_zombis()`), le da un arma a Johnny y pone su texto
  (`rotulo()`). Johnny va en el modo asistido (apunta y dispara solo), con munición sin fin y sin poder caer.
- **La pantalla:** 960×540 (16:9, lo que piden Steam y YouTube) agrandada por 2. `tools/trailer.py` lo pone en un
  `override.cfg` mientras graba y lo quita al acabar.
- **El sonido:** en el trailer suenan los efectos (la prueba normal va sin sonido) y la música se apaga: la pone el
  montaje entera, sin cortes entre escenas.

## El guion de ahora

| Texto | Lo que se ve |
|---|---|
| Eres Johnny. El conserje. | La sala de mantenimiento, con la fregona |
| El edificio está infestado. | Un piso a oscuras, con la linterna, y zombis |
| Limpia piso a piso. | Una habitación llena y la escopeta |
| Busca armas. | El bate y la MP5 |
| Compra lo que necesites. | La tienda del ordenador; luego el lanzallamas, el lanza ácido y la pistola eléctrica |
| Guarda lo que encuentres. | El inventario |
| Sobrevive a ellos. | El Glotón (con su presentación) y el Gymbro |
| Nunca es el mismo edificio. | Cuatro pisos distintos, muy seguidos |
| *(logo)* Próximamente en Steam | — |

No sale nada de fabricar armas (el banco quedó con dos recetas: no se anuncia).
