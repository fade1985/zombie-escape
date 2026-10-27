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
  `chorro_acido` (lanza ácido); el rayo del lanza rayos no tiene: se dibuja a código en `llamarada.gd`.
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
  al romperse o explotar: `soltar_racimo` de `proyectil.gd` y `granada.gd`). `bala.gd`. Lo que **se ve de la calidad**
  del arma en la mano (`AURA`, `traza()`; la Normal, nada): `aura_arma.gd` (hija de Johnny: la luz del color, el halo y
  las chispas de la punta del arma, que sale de `boca` o, en cuerpo a cuerpo, de `punta`), `tajo.gd` (la media luna del
  golpe, que suelta `johnny.golpear`) y la trazadora de la bala (`bala.calidad`). Se prueba con `--aura`.
- `armas_creadas.gd`: lo que hacen las armas con `efecto` (la descarga que aturde y salta, prender, la herida de
  ácido `Herida` y `con_acido`, `QUEMAN`); `chorro.gd`, las gotas de fuego y las chispas (ya no las echa ningún arma).
- `llamarada.gd`: la llama continua del lanzallamas, el chorro del lanza ácido y el rayo del lanza rayos (cono, daño
  cada 0,25 s, empuje, luz; `variante`: "llama", "acido" o "rayo". El rayo se dibuja a código —zigzag, ramitas y
  arcos—, tiene un cono más estrecho (`ABRE_RAYO`), aturde y la descarga salta de un zombi a otro: `buscar_blancos`,
  `electrocutar`). `goteo.gd`: la gota que cuelga de la boquilla del lanza ácido.
- `lanzables.gd`: molotov, granada, atraedora y congeladora: 3 a mano (`mano`, F cambia) y 8 de repuesto (`repuesto`);
  lo que cuesta uno en la tienda (`PRECIOS`). Cada paquete tiene su calidad y va en su hueco: su clave es el tipo y,
  si no es Normal, la calidad detrás (`"molotov:2"`; `clave`, `tipo_de`, `calidad_de`; el banco lo sube con
  `mejorar`).
  `granada.gd`: también la atraedora y la congeladora (cada una con su propio dibujo, su icono: `DIBUJOS_PROPIOS`).
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
  (también el de la portera) es `vapor_rabia.gd`; todos los avisos en el suelo de los jefes son `aviso.gd` (los
  pinta el shader `escenas/personajes/aviso.gdshader`, en cuadraditos de pixel art): las cargas (flechas que se
  encienden hasta la pared), los golpes, saltos y círculos (se llenan hacia fuera; pueden llegar hasta las paredes,
  cambiar de color y llevar ondas, como el aspirado del glotón), las barras rectas (lenguas, latigazos, alfileres,
  rayas de los disparos) y las flechas del giro del bombero. Se prueban con `--golpes`, `--franja` y `--avisos`. Heredan:
  - Apartamentos: `gloton.gd`, `gymbro.gd` (+ `pesa.gd`), `bombero.gd` (+ `bola_fuego.gd`).
  - Centro comercial: `antidisturbios.gd`, `cocinero.gd` (+ `cuchillo.gd`), `modista.gd` (+ `maniqui_vivo.gd`),
    `mascota.gd`.
  - Jefes finales de la azotea, que mutan a media vida (`mutar()`) y al caer llaman a `fin_del_edificio()`:
    `gerente.gd` (+ `contrato.gd`) y `cientifico_jefe.gd` (el doctor Salas). `helicoptero.gd`: el que llega al final (su cuerpo,
    `helicoptero.png` de PixelLab; los rotores y la luz de la aleta, por código) y suelta su escalera de cuerda sobre
    el helipuerto; al llegar Johnny a ella (`agarrada`) se acaba el edificio (`partida.subir_al_helicoptero`).
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
  `LISTA`), `historia.gd` (dosier y noticias; se edita sin tocar los `id`) y `bestiario.gd` (sus fichas;
  `recorte` lo calcula `tools/recortes_bestiario.py`).
- `supervivientes.gd` (el encerrado en su baño, la horda, los vecinos) y `aliado.gd` (cada superviviente que te
  acompaña; sus hojas, en `HOJAS`). Los rescates propios: `escolta.gd` (farmacéutica), `averia.gd` (técnico) y
  `barricada.gd` (ferretero).
- `sonido.gd` (autoload: efectos sintetizados y música), `controles.gd` (las teclas cambiadas en Opciones).

**ui/**
- `hud.gd`, `barra_jefe.gd` (la barra de los jefes, con la de armadura), `presentacion.gd` (la entrada de cada
  jefe), `menus.gd` (pausa y fin), `menu_principal.gd` (menú y «Elige edificio»), `opciones.gd`, `tactil.gd`
  (controles del móvil), `tema.gd` (aspecto), `ambiente.gd` (viñeteado, poca vida, escarcha), `botones.gd`
  (autoload: el saltito de los botones), `tele.gd` (la tele de las noticias: el mueble, la calle de detrás y la reportera son dibujos de PixelLab de
  `assets/ui/tele/`; la boca al hablar y el parpadeo, a mano).
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
  `poner_caras` pone la cara (el papel, de 3 casillas) a cada pared con suelo debajo, y a los tabiques que cuelgan de una
  pared con suelo encima (`tabique_colgado`) les sube la tapa del muro hasta lo alto de la pared de al lado (`tapa` de
  `cara_pared.gd`), para que cada habitación quede cerrada a su altura y no se vea el suelo de arriba en un hueco.
- `planta.gd`: la planta, sus zombis y sus salas especiales (mantenimiento, exposición, pruebas de armas, azotea).
  La sala de mantenimiento se ve como las viviendas ("cajas": vestuario, despacho y taller, cada uno en su caja de
  tabiques con oscuro alrededor), y también el pasillo de los Apartamentos, sus pisos y las habitaciones de sus jefes (el centro
  comercial y la azotea, todavía no). Con "cajas", solo hay cara de pared donde el tabique de arriba sigue a los lados
  (`mapa.cara_de_caja`): encima de una puerta de lado entre dos estancias no sale cara, el tabique se ve plano.
  Por dónde se llega: solo la planta baja (el portal del edificio) y la azotea tienen una puerta de llegada a la izquierda;
  en las demás plantas se entra por las escaleras de la derecha, las mismas por las que se sale de la de abajo, y el pasillo
  no tiene puerta a la izquierda (`puerta_de_llegada()` de `partida.gd` da la que toca; se prueba con `--llegada`).
  La azotea lleva en el centro el helipuerto elevado (`PLATAFORMA`, con la rampa a la izquierda: `plataforma()`,
  `rampa()`, `huella_helipuerto()`), sin aparatos encima ni su dibujo; es el ring del jefe final: espera arriba
  (`esperando` en `minijefe.gd`) y, al subir Johnny, `valla.gd` cierra la rampa hasta que cae (`partida.mirar_ring`).
  Su borde choca en la capa 4 (`CAPA_BORDE`: para a los que andan, no a las balas). Sus aparatos van siempre en el
  mismo sitio (`APARATOS`, uno por edificio). No tiene más puerta que la de llegada: se sale por la escalera del helicóptero. Se prueba con `--azotea`.
  `apartamento.gd` da cada piso, que es siempre el mismo (dibujado con letras en `PLANO_PASILLO`, volteado cuando la
  puerta da arriba; sus muebles, solo los puestos a mano: `colocados` en `catalogo.gd`, por ahora el dormitorio de matrimonio con la
  puerta abajo), y la habitación de cada jefe; `tienda.gd` genera cada tienda;
  `viviendas.gd`, el pasillo de los rescatados. Se ve como una casa por dentro desde arriba ("cajas" en el sitio): cada
  habitación y el pasillo, cerrados por sus tabiques de una casilla de grueso, lisos y claros (`tabique.gd` y
  `mapa.poner_tabiques`); solo la pared de arriba de cada uno tiene altura (su cara y, encima, su tabique, con los de los
  lados subiendo hasta él), los demás tabiques se ven planos y el muro que sobra alrededor se ve oscuro,
  como fuera del mapa (`mapa.FUERA`). Las de arriba tapan sus tres últimas filas (la pared del pasillo) y el pasillo, las suyas (la de las
  de abajo): `Viviendas.TAPADAS`. Sus habitaciones son los trasteros del edificio: todas iguales, de chapa
  crema acanalada con el suelo de hormigón gris azulado y la puerta azul lisa con pomo de metal (`suelo-`, `pared-`,
  `techo-` y `puerta-trastero`, de `tools/trastero.py`; la puerta, `trastero` en `puerta_bano.gd`). Cada una lleva un colchón en el suelo en la esquina de arriba a la derecha, con la
  almohada descolocada y la colcha del color del superviviente, y una estantería metálica vacía en la esquina de arriba a
  la izquierda (algo separada de ella): `colocados` de `habitacion-<id>` en `catalogo.gd`. Los dos, de PixelLab con las
  guías de `tools/guias_trasteros.py` (la del colchón sale de la cama de siempre, sin cabecero ni pie); los colores de la
  colcha, con `tools/camas_viviendas.py` (a partir de `assets/sources/viviendas/colchon.png`).
  El pasillo es el de una zona de trasteros: el mismo suelo de hormigón con una línea amarilla pintada a lo largo
  (`linea-trastero`, la pinta `mapa.dibujar_fondo` a la altura que dice `"linea"` en la sala del pasillo) y la misma
  chapa con una franja de chapa lagrimada abajo (`pared-trastero-pasillo`), las dos de `tools/trastero.py`; contra la
  pared de arriba, cajas de cartón apiladas (`boxstack`, `boxpile`) y carretillas cargadas (`handtruck`), de PixelLab con
  las guías de `tools/guias_trasteros.py` (`colocados` de `pasillo-viviendas` en `catalogo.gd`, lejos de las puertas), y
  en la pared de arriba, a la izquierda de la primera puerta, el cartel de «TRASTEROS» (`cartel_trasteros.gd`: placa
  azul con letras blancas de `Tema.FUENTE`). El pasillo empieza y acaba donde las habitaciones (`ENTRADA` y `FINAL`, 0).
- `catalogo.gd` (qué muebles lleva cada sala), `muebles.gd` (dónde va cada uno; `islas`, `fijos`, `de_piso` para los puestos a mano), `mueble.gd`.
- `puerta_bano.gd`: las puertas de dentro. Una en cada hueco entre habitaciones de los pisos, las tiendas y la sala de
  mantenimiento (`libre`, las pone `mapa.poner_hojas`): cerradas al empezar, las abren Johnny y los suyos al arrimarse y
  los zombis despiertos empujando medio segundo, y se quedan abiertas (`abierta` en su hueco). Cerradas paran la luz,
  las balas, la vista de los zombis y la niebla. Y las cerradas con llave (su hueco lleva `cerrada`): el baño del
  superviviente, las viviendas sin rescatar y la cámara acorazada de la joyería (`acero`). Las viviendas de los ya
  rescatados llevan la suya abierta del todo (`libre` y `abierta` desde el principio: no choca ni tapa la luz; la
  pone `mapa.poner_viviendas`). Llenan el hueco: de frente,
  con su marco y, encima, el dintel (un trozo de `cara_pared.gd` con `desde`, que pone `mapa.poner_caras`); de lado,
  sobre su umbral. De frente, abierta del todo es un dibujo de PixelLab (`puerta-bano-abierta.png`, la puerta casi de
  canto con su canto, su pomo y su sombra; la hace `tools/puerta_abierta.py`: guía con nuestra puerta, PixelLab,
  recolor al marrón de la cerrada); mientras gira, se tuerce por código a 63 grados (`GIRO`). La de lado (tabiques
  verticales; `hoja_de_lado`) cerrada es `puerta-bano-lado-cerrada.png`, un tablón de madera fino con su pomo de latón
  que sobresale por los dos lados (16 × 32, dibujado en `py tools/puerta_lado_cerrada.py` con la madera y el pomo de la
  puerta de frente: a 5 píxeles de ancho PixelLab no puede dibujar nada); al abrirse gira la puerta de verdad hacia la habitación de
  la derecha y abierta del todo (153 grados, `GIRO_LADO`) es `puerta-bano-abierta-lado.png`: de pie junto a la pared, con
  la bisagra arriba del hueco (`py tools/puerta_abierta.py guia lado`). La blindada de acero y la del almacén con
  tablas siguen con la hoja vista desde arriba. Se prueba con `--puertas`.
- `puerta.gd` (las salidas) y `cartel_salida.gd`: la salida de incendios es la puerta de las escaleras, al fondo del
  pasillo, en el muro de la derecha. Se abre cuando cae el jefe de la planta (`jefa_muerta` en `partida.gd`, que llama a
  `actualizar_puertas`). Vista desde arriba, es una hoja de chapa roja fina metida en el hueco, con su barra antipánico
  de aluminio sobresaliendo hacia el pasillo y las escaleras detrás (`puerta-salida.png`, 36 × 36). Encima, en la pared de
  arriba, un cartel EXIT (`cartel-salida-apagado.png` / `-encendido.png`, 36 × 13) que `mapa.gd` crea junto a la puerta y
  que la puerta enciende (`abierta`): apagado es verde oscuro y sin luz; al caer el jefe arranca con unos parpadeos y se
  queda verde vivo, sin que le afecte la penumbra, con halo y una luz verde de verdad (la de `lampara.gd`); si Johnny
  vuelve a una planta ya pasada, nace encendido. Dibujados a mano con `py tools/puerta_salida.py` (a esa anchura PixelLab
  no dibuja). Se prueba con `--salida`.
- `cara_pared.gd`, `neon.gd`; `ordenador.gd` (la mesa), `arrimable.gd`
  (baúl, banco, taquilla), `armarito.gd`, `cientifico.gd` (el muerto con su página),
  `valla.gd` (la del helipuerto de la azotea).

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
  ácido sale de la del lanzallamas), `hoja_lanza_rayos.py` (la del lanza rayos, blanco y gris: monta con `arma.py` y
  quita el parpadeo de espaldas, que confundía el arma con unos ojos; `PYTHONPATH=tools py tools/hoja_lanza_rayos.py`) y
  `cara.py` (las skins: `py tools/cara.py <skin> [arma]`).
- **La salida de incendios:** `puerta_salida.py` dibuja a mano, sin PixelLab, la puerta roja de las escaleras y el
  cartel EXIT (apagado y encendido): `py tools/puerta_salida.py`.
- **Bocetos para pedir muebles a PixelLab:** `guias_*.py`, `guia_cientifico.py`, `banco_mantenimiento.py`,
  `baul_mantenimiento.py`, `ordenador_mantenimiento.py`, `botiquin.py` (el del baño; sus bocetos, `guias_botiquin.py`),
  `taquilla.py`, `helicoptero.py` (el helicóptero de Velaria), `tele.py` (la tele de las Noticias), `centro_sprites.py`, `importar.py` (muebles
  nuevos → sprites; lee `catalogo.gd`), `camas_viviendas.py` (el colchón con la colcha de cada superviviente), `trastero.py` (suelo, pared y puertas de los trasteros de las viviendas, y la pared con chapa lagrimada y la línea amarilla de su pasillo), `guias_trasteros.py` (las cajas y la carretilla de ese pasillo, y la estantería y el colchón de sus habitaciones), `despixelar.py`, `dibujos_7b.py`, `cientifico_muerto.py`.
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
