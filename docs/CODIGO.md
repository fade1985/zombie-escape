# Mapa del código

Una línea o dos por archivo, para saber dónde mirar. Lo fino (números, por qué se hizo así) está en los comentarios
de cada script; lo que se hizo y cuándo, en git. Si algo cambia de sitio o aparece un archivo nuevo, se apunta aquí
en una línea.

## Raíz

- `project.godot`: escena de inicio, pantalla, pixel art nítido, teclas de cada acción, capas de choque.
- `default_bus_layout.tres`: buses de audio. `export_presets.cfg` y `vercel.json`: ver `WEB.md`.

## escenas/

- `menu_principal.tscn`: la escena de inicio. `partida.tscn`: Johnny y la pantalla (el mapa lo monta `partida.gd`).
- `partida_prueba.tscn`: la misma con el script de prueba; el menú la abre en vez de la otra con `--captura`.
- `personajes/`: `johnny.tscn`, un `zombi_<tipo>.tscn` por tipo (sus números en el Inspector) y uno por jefe. Los
  shaders: `cintura` (Johnny partido por la cintura al golpear andando), `destello` + `quemaduras.gdshaderinc` (destello,
  hielo, fuego y ácido de los enemigos) y `brillo`.
- `armas/`: `bala`, `bala_zombi`, `proyectil`, `charco` y `explosion`; los shaders `llamarada` (lanzallamas) y
  `chorro_acido` (lanza ácido).
- `luces/`: `lampara.tscn`, `fuego.tscn`, `luz_suave.tres` y los shaders `niebla` y `suelo_a_oscuras`.

## scripts/

**Johnny y sus armas**
- `johnny.gd`: moverse, vida, apuntar y atacar (`tiro`, `blanco_en_linea`), recibir daño (`recibir_dano(cantidad,
  quien)`), tropezar (`caer`), las skins (`vestir`, y sus ventajas en `arma()`, `ignifugo()`, `devolver()`), la
  munición (`municion`, `reserva()`, `meter_municion()`, `arma_de_caja()`) y el depósito del lanzallamas y el lanza
  ácido (`echar_fuego`, `rellenos()`, `coger_relleno`). `mejoras.gd`: sus atributos.
- `armas.gd`: los números de cada arma (`DATOS`, `PRECIOS`), su hoja y su `boca`, la munición (`MUNICION`) y lo que
  llena cada depósito (`relleno`, `RELLENOS`). El lanza ácido, por dentro, se llama `desintegrador`. `familia()`:
  cuerpo a cuerpo, A distancia o especial (por dentro, las dos últimas son de tipo `"fuego"`). Las **calidades**
  (`CALIDADES`: Normal, Poco común, Rara y Épica, con su color, su daño, lo de su familia y las piezas que cuesta
  subir a ella en el banco, `coste()`: los arrojables, más baratos; `con_calidad()`, `que_da()`, `al_baul()`,
  `pieza()`): cada arma que lleva Johnny tiene la suya (`johnny.calidades`, `johnny.base()`; lleva una
  de cada arma: `partida.llevar_arma`) y el baúl guarda armas y paquetes de arrojables con la suya. La **Épica**
  (`EPICA`) trae además un truco de su familia (`TRUCO`, `truco()`): golpe de gracia (cada 4 golpes, uno crítico:
  `johnny.golpear`), balas que atraviesan (`bala.gd`, `atraviesa`, estela morada), estallido (el zombi que mata
  revienta y pasa su efecto: `ArmasCreadas.estallido`, desde `llamarada.gd` y `chorro.gd`) y racimo (2 más pequeños
  al romperse o explotar: `soltar_racimo` de `proyectil.gd` y `granada.gd`). `bala.gd`.
- `armas_creadas.gd`: lo que hacen las armas con `efecto` (la descarga que aturde y salta, prender, la herida de
  ácido `Herida` y `con_acido`, `QUEMAN`); `chorro.gd`, las gotas de fuego y las chispas.
- `llamarada.gd`: la llama continua del lanzallamas y el chorro del lanza ácido (cono, daño cada 0,25 s, empuje,
  luz). `goteo.gd`: la gota que cuelga de la boquilla del lanza ácido.
- `lanzables.gd`: molotov, granada, atraedora y congeladora: 3 a mano (`mano`, F cambia) y 8 de repuesto (`repuesto`);
  lo que cuesta uno en la tienda (`PRECIOS`). Cada paquete tiene su calidad y va en su hueco: su clave es el tipo y,
  si no es Normal, la calidad detrás (`"molotov:2"`; `clave`, `tipo_de`, `calidad_de`; el banco lo sube con
  `mejorar`).
  `granada.gd`: también la atraedora y la congeladora.
- `sala_armas.gd`: la sala de pruebas (F11 desde cualquier sitio; F11 otra vez, de vuelta): la diana, todas las armas,
  las líneas de ayuda, el panel de daño y el baúl de pruebas (`Guardado.baul_prueba`: el de verdad no se toca). Al
  salir, Johnny vuelve a llevar lo que llevaba. Su panel de pruebas (tecla P) es `ui/panel_pruebas.gd`.

**Zombis, jefes y lo que hacen daño**
- `zombi.gd`: la base de todos (perseguir con navegación, zarpazos, arder y el ácido con su shader, `contagiar`,
  `meter_prisa`, la `diana` de la sala de armas, la señal `herido`). Normal, lento, rápido y vigilante solo cambian
  números en su `.tscn`. Heredan: `zombi_explosivo.gd`, `zombi_tentaculos.gd`, `zombi_venenoso.gd`,
  `zombi_dependienta.gd` («¡OFERTAS!») y `zombi_guardia.gd` (el guardia de la tarjeta: ronda, silbato, huye).
  `barra_zombi.gd`: su barrita de vida. `sombra.gd`: la sombra de los pies de todos.
- `portera.gd`: la jefa por defecto, por estados.
- `minijefe.gd`: lo común de los jefes (vida y barra, enfadarse a media vida, llamar zombis, `danar()`,
  `quitar_vida()`, `morder()`, la embestida con su `franja()` y el atontado). El vapor de la cabeza al enfadarse
  (también el de la portera) es `vapor_rabia.gd`; los avisos en el suelo de las cargas (flechas que se encienden
  hasta la pared) y de los golpes cuerpo a cuerpo (arcos que se encienden), `aviso.gd` (los pinta el shader
  `escenas/personajes/aviso.gdshader`; también los de la portera). Heredan:
  - Apartamentos: `gloton.gd`, `gymbro.gd` (+ `pesa.gd`), `bombero.gd` (+ `bola_fuego.gd`).
  - Centro comercial: `antidisturbios.gd`, `cocinero.gd` (+ `cuchillo.gd`), `modista.gd` (+ `maniqui_vivo.gd`),
    `mascota.gd`.
  - Jefes finales de la azotea, que mutan a media vida (`mutar()`) y al caer llaman a `fin_del_edificio()`:
    `gerente.gd` (+ `contrato.gd`) y `cientifico_jefe.gd` (el doctor Salas). `helicoptero.gd`: el que llega al final.
- `bala_zombi.gd` (el agua sucia de la portera, gotas de pixel art, rojiza si está enfadada; el polvo de su giro; y los
  alfileres de la modista), `salpicadura.gd`
  (lo que salpica una gota al chocar y su manchita, que se seca), `proyectil.gd` (lo que va en parábola: moco, lejía, molotov del bombero, sartén, probetas) y
  `explosion.gd`.
- `charco.gd` (todos los charcos) y `estados.gd` (lo que hacen: veneno, frío, calambrazo, tirado, `frenado`...).
- `peligros/`: `peligros.gd` (sus números y dónde va cada uno al generar la planta). Del centro comercial: `frio.gd`,
  `fuego.gd`, `agua.gd` (con `arreglar()`) y `cuadro.gd`. De las habitaciones de los jefes de los Apartamentos:
  `porqueria.gd` (Glotón), `tropiezos.gd` (mancuernas del Gymbro, cubos de la portera), `cerco.gd` (bombero) y
  `luz_jefe.gd` (la luz fija de esas habitaciones).
- `mutaciones.gd`, `llamas.gd` (colores y luz del fuego), `quemado.gd` (el cuerpo que muere ardiendo), `brillo.gd`
  (lo que luce a oscuras), `particulas.gd`, `mancha.gd`, `temblor.gd` (temblor de pantalla y parón de los golpes).
- `persona.gd`: una persona dibujada con formas, para quien no tenga hoja de PixelLab.

**Partida y progreso**
- `partida.gd`: la planta en juego (cambiar de sitio, puertas, llave o tarjeta y su guardia, jefes, escaleras,
  ascensor, dinero, soltar objetos y munición, pausa, fin) y la entrada a la sala de pruebas (`pruebas`,
  `sitio_pruebas`, `en_pruebas`: allí los zombis no cuentan ni sueltan nada). Avisa a la prueba en
  `preparar_prueba()`, `ordenar_jefes_prueba()` y `empezar_prueba()` (en la partida de verdad no hacen nada).
- `edificios.gd`: la ficha de cada edificio, `MINIJEFES` y el sorteo de qué jefe va en cada planta
  (`orden_jefes`, `jefe_de()`).
- `alerta.gd` (niveles de alerta), `eventos.gd` (eventos sorpresa: apagón, incendio, horda), `reto.gd` (el reto del
  día) y `joyeria.gd` (la cámara acorazada y su premio). Los engancha `partida.gd` (`preparar`, `al_montar`, `recoger`).
- `skins.gd`: las skins de Johnny (`LISTA`, sus ventajas, `de_jefe()`, `siguiente()` para la Z, `hoja()`).
- `objetos.gd`: los objetos (gasolina, bidón de ácido, batería y vendas), los que se usan (`USABLES`), qué sale en
  cada tienda (`TIENDAS`), los que suelta un solo zombi (`DE_UN_ZOMBI`), la mochila y el baúl de 32. Y las **piezas**
  de mejora de las armas (`PIEZAS`: cuerpo a cuerpo, a distancia, especial y arrojable): no salen al azar, las suelta
  cualquier zombi (`pieza_de_zombi()`, 6 %) y cada jefe (`piezas_de_jefe()`, 4), en `partida.meter_zombi`, y con la
  alerta salen más (`Alerta.mas_piezas()`). Su ficha dice para qué armas son (`PIEZA_PARA`); se gastan en el banco
  de trabajo (`inventario.gd`). Sus iconos, `assets/ui/iconos/obj-pieza_*.png` (PixelLab, 32×32; ver `assets/pixellab.json` → `piezas`).
  `talentos.gd`, `billete.gd` (lo que hay en el suelo: billetes, objetos, cajas), `minimapa.gd`.
- `guardado.gd` (el guardado; al cargar quita lo que ya no está en el juego; el baúl son `baul`, los objetos, y
  `baul_equipo`, las armas y los paquetes de arrojables con su calidad), `logros.gd` (uno = una línea en
  `LISTA`), `historia.gd` (dosier, noticias y la cafetera; se edita sin tocar los `id`) y `bestiario.gd` (sus fichas;
  `recorte` lo calcula `tools/recortes_bestiario.py`).
- `supervivientes.gd` (el encerrado en su baño, la horda, los vecinos) y `aliado.gd` (cada superviviente que te
  acompaña; sus hojas, en `HOJAS`). Los rescates propios: `escolta.gd` (farmacéutica), `averia.gd` (técnico) y
  `barricada.gd` (ferretero).
- `sonido.gd` (autoload: efectos sintetizados y música), `controles.gd` (las teclas cambiadas en Opciones).

**ui/**
- `hud.gd`, `barra_jefe.gd` (la barra de los jefes, con la de armadura), `presentacion.gd` (la entrada de cada
  jefe), `menus.gd` (pausa y fin), `menu_principal.gd` (menú y «Elige edificio»), `opciones.gd`, `tactil.gd`
  (controles del móvil), `tema.gd` (aspecto), `ambiente.gd` (viñeteado, poca vida, escarcha), `botones.gd`
  (autoload: el saltito de los botones), `tele.gd` (la tele de las noticias).
- `ordenador.gd`: ConserjeOS (talentos, tienda de armas, logros, Dosier, Noticias, Colecciones). La tienda, en cuatro
  secciones (`SECCIONES` y los arrojables, que se compran de uno en uno con `comprar_lanzable`).
- `inventario.gd`: el inventario «todo a la vista», el baúl (`pintar_baul`, `cosas_baul`: objetos, armas y
  arrojables; `guardar_equipo`, `sacar_equipo`), el banco de trabajo (`pintar_banco`, `en_banco`, `no_mejora`,
  `mejorar`: sube un nivel un arma o un paquete, de lo que lleva o del baúl, con las piezas de la mochila y del baúl)
  y arrastrar con ratón o dedo (`levantar`, `destinos`, `soltar_en`). `taquilla.gd`: la ventanita de las skins.
- `panel_pruebas.gd`: el panel de la sala de pruebas (tecla P allí): jefes (a media vida, quietos), zombis, las ayudas
  que se encienden y se apagan, Johnny invencible, la diana, ir a la exposición o a la sala de un jefe y lo de las
  antiguas teclas de prueba (mutaciones, objeto, piezas al baúl, Colecciones, científico).

**mapa/**
- `mapa.gd`: monta un sitio (suelos, paredes, choques, muebles, peligros, niebla, navegación; escaparates y neones del
  centro, la azotea, las viviendas). Estilos de cada sala: `ESTILO_DE`, `ESTILO_TIENDA`, `PASILLOS`.
  `acustica_en(pos)`: cómo suena ahí la pistola, "seca", "eco" o "duro", según el sitio y el uso de la habitación.
- `planta.gd`: la planta, sus zombis y sus salas especiales (mantenimiento, exposición, pruebas de armas, azotea).
  `apartamento.gd` y `tienda.gd` generan cada piso o tienda (`apartamento.gd` tiene también el piso con pasillo en T,
  `probar_pasillo`, que de momento solo sale con `--piso-pasillo`); `viviendas.gd`, el pasillo de los rescatados.
- `catalogo.gd` (qué muebles lleva cada sala), `muebles.gd` (dónde va cada uno; `islas`, `fijos`), `mueble.gd`.
- `cara_pared.gd`, `puerta.gd`, `puerta_bano.gd`, `placa.gd`, `neon.gd`; `ordenador.gd` (la mesa), `arrimable.gd`
  (baúl, banco, taquilla), `armarito.gd`, `cientifico.gd` (el muerto con su página), `cafetera.gd`, `camaras.gd`.

**luz/**: `luz.gd` (penumbra de cada sitio, luz de Johnny, fogonazos), `lampara.gd`, `fuego.gd`.

**pruebas/**: lo que solo se usa con `--captura`.
- `captura.gd` (clase `Captura`): `activa()`, `dato("--jefe", "antidisturbios")` y `foto("captura-x.png")`.
- La partida de prueba va en una cadena de archivos por tema, cada uno hereda del anterior: `prueba_comun.gd` (hereda
  de `partida.gd`) → `prueba_jefes_salas.gd` → `prueba_jefes.gd` → `prueba_armas.gd` → `prueba_skins.gd` →
  `prueba_inventario.gd` → `prueba_fotos.gd` → `prueba_sitios.gd` → `prueba_reglas.gd` → `prueba_larga.gd` →
  `partida_prueba.gd`, el último, que los tiene todos. Al principio de `partida_prueba.gd` está la lista de opciones
  (`--jefe`, `--armas`, `--inventario`...) con el archivo de cada una.

## assets/

- `sprites/`: las hojas (`.png` + `.json`) y sus animaciones (`.tres`). Hoja nueva →
  `py tools/hacer_frames.py assets/sprites/<nombre>`.
- `musica/`: `el-ultimo-inquilino.ogg` (menús y explorar) y `turno-de-noche.ogg` (peleas); se eligen en `CANCIONES`
  de `sonido.gd`.
- `ui/` (HUD, menús e iconos), `fuentes/` (la de siempre, nítida a 16 y 32, y `jersey-25.ttf` de los jefes, nítida a
  25 y 50, que va siempre con su licencia `jersey-25-OFL.txt`), `tiles/`, `pruebas/` (montajes para revisar dibujos).
- `sources/`: originales (con `.gdignore`). `pixellab.json`: todo lo generado en PixelLab.

## tools/

- **El trailer:** `trailer.py` lo graba con el Movie Maker de Godot y lo monta con ffmpeg (ver `docs/TRAILER.md`).
- **Hojas de PixelLab:** `bajar_zip.py`, `bajar.py`, `bajar_fotogramas.py` (bajar), `hacer_frames.py` (hoja →
  animaciones), `jefe_hoja.py` (jefes: `py tools/jefe_hoja.py gloton-72 jefe-gloton`; cada jefe en su ficha `JEFES`),
  `superviviente.py`, `zombi.py` + `png.py`, `piel.py`, `espejo_oeste.py`, `hoja.py` (hoja de revisión).
- **Johnny con un arma:** se monta con `tools/arma.py` del juego JS (`PYTHONPATH=tools py
  C:/Users/angel/Projects/game/tools/arma.py conserje-48-<arma>`; la receta, en la skill `arma-nueva` de ese juego).
  Si el arma se sale de la casilla, `celda`, `pivote` y `lienzo_ataque` en su `arma.json`; si el fogonazo no es
  naranja, sin `boca: fogonazo` y la boca a mano en `armas.gd`; `andar.ciclo` y `andar.espejo` para el andar. Retoques:
  `andar_arma.py`, `ritmo_andar.py`, `juntar_piernas.py`, `zapato_negro.py`, `hoja_lanza_acido.py` (la del lanza
  ácido sale de la del lanzallamas) y `cara.py` (las skins: `py tools/cara.py <skin> [arma]`).
- **Bocetos para pedir muebles a PixelLab:** `guias_*.py`, `guia_cientifico.py`, `banco_mantenimiento.py`,
  `baul_mantenimiento.py`, `ordenador_mantenimiento.py`, `taquilla.py`, `centro_sprites.py`, `importar.py` (muebles
  nuevos → sprites; lee `catalogo.gd`), `despixelar.py`, `dibujos_7b.py`, `cientifico_muerto.py`.
- **Texturas:** `textura_suelo.py`, `textura_pared.py`, `textura_tapa.py`, `azotea.py` (ver
  `FONDOS.md`).
- **Iconos:** `icono_*.py`, `objetos16.py` (solo la batería y las vendas, de 16×16: los demás objetos son de PixelLab),
  `hacer_casillas.py`, `recortes_bestiario.py`.
- **Ver sin jugar:** `ver_dibujos.tscn` (foto de los dibujos hechos con código) y `probar_sonido.gd` (los efectos en
  `tools/efectos/*.wav`, que no van a git).
- **Música de 8 bits:** `motor-8bit.mjs` y las canciones (`el-ultimo-inquilino.mjs`, `turno-de-noche.mjs`,
  `villancico-8bit.mjs`, de prueba). `node tools/<canción>.mjs` saca el `.wav` y el `.ogg`; con `--veces 4`, en bucle.

## docs/

- `historial/`: los planes ya terminados (`CENTRO_COMERCIAL.md`, `JEFES_APARTAMENTOS.md`). Solo para saber por qué se
  decidió algo; lo que vale es el código.
- `PIXEL_ART.md`, `PIXELLAB.md`, `ZOMBIS.md`, `FONDOS.md`, `MAPA.md`: del juego JS y de lo dibujado después; valen
  para las ideas y los números.
