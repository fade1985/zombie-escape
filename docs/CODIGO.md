# Mapa del código

Una línea o dos por archivo, para saber dónde mirar. Lo fino (números, por qué se hizo así) está en los comentarios
de cada script; lo que se hizo y cuándo, en git. Si algo cambia de sitio o aparece un archivo nuevo, se apunta aquí
en una línea.

## Raíz

- `project.godot`: escena de inicio, pantalla, pixel art nítido, teclas de cada acción, capas de choque.
- `default_bus_layout.tres`: buses de audio. `export_presets.cfg` y `vercel.json`: ver `WEB.md`.
- `locale/<idioma>.po` (`en`, `pt_BR`, `de`, `fr`, `ru`, `zh_CN`): las traducciones (el español es el idioma de origen: cada texto del código es su clave). La
  carga `project.godot` (`[internationalization]`) y la pone al día `tools/traducciones.py`. Todo en `docs/IDIOMAS.md`.

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
  quien, peligro)`; quién le ha quitado vida la última vez queda en `golpe_de`: un enemigo, por su meta `"tipo"`, que
  lee `Bestiario.de` y le ponen al nacer `partida.meter_zombi`, la modista a sus maniquíes y los jefes al mutar; o un
  peligro de `Menus.PELIGROS`: el charco que más quema, `charco_que_quema`, el agua con corriente, el cable pelado o su
  granada, `explosion.de`), tropezar (`caer`), las skins (`vestir`, y sus ventajas en `arma()`, `ignifugo()`, `devolver()`), la
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
- `lanzables.gd`: molotov, granada, atraedora y congeladora, en **montones** (M18, 28 oct): cada hueco lleva un montón
  de una clave de hasta `MONTON` (5; más con la calidad y el Artificiero o Criogenia: `maximo`). 3 a mano (`mano`, una
  de cada clave, F cambia; sus cuentas en `cantidades`) y 8 de repuesto (`repuesto` y sus cuentas en `en_repuesto`,
  con varios de la misma clave). Sin tope por tipo: se coge mientras quepa (`cabe`, `meter`: primero en sus montones
  sin llenar, luego en uno nuevo). Al acabarse el de la mano entra otro de repuesto (`repasar`, `relevo`: el de su
  clave, uno de su tipo o el primero). Un montón se señala por su sitio, el nombre de su casilla en el inventario
  (`"l1"`, `"e3"`: `clave_en`, `cuantos_en`, `sitio_de`, `quitar`, `mejorar`); `a_la_mano` y `al_repuesto`, por su
  número. Lo que cuesta uno en la tienda (`PRECIOS`). La clave de un montón es el tipo y, si no es Normal, la calidad
  detrás (`"molotov:2"`; `clave`, `tipo_de`, `calidad_de`; el banco lo sube con `mejorar`). Al completar el edificio
  van todos al baúl (`partida.equipo_encima`, `montones`), también los Normales; allí se juntan los del mismo tipo y
  calidad hasta 99 por casilla (`Objetos.arrojables_al_baul`, `caben_arrojables`) y salen de montón en montón
  («Sacar 5»). Se prueba con `--montones`.
  `granada.gd`: también la atraedora y la congeladora (cada una con su propio dibujo, su icono: `DIBUJOS_PROPIOS`).
  Rebota en las paredes también en el aire (`choque_hasta`, con `mapa.muro_entre`) y en los muebles solo a ras de suelo;
  por eso lanzar de un toque (`mas_cercano`) no le apunta a un zombi tras una pared. El molotov vuela por encima de todo.
  Su explosión (y el congelado de la congeladora) tampoco pasa las paredes: lleva `explosion.paredes`, que la del zombi
  explosivo y la de Mezcla explosiva no llevan. Se prueba con `--granada-pared`.
- `sala_armas.gd`: la sala de pruebas (F9 desde cualquier sitio; F9 otra vez, de vuelta): la diana, todas las armas,
  las líneas de ayuda, el panel de daño y el baúl de pruebas (`Guardado.baul_prueba`: el de verdad no se toca). Al
  salir, Johnny vuelve a llevar lo que llevaba. Su panel de pruebas (tecla P) es `ui/panel_pruebas.gd`.

**Zombis, jefes y lo que hacen daño**
- `zombi.gd`: la base de todos (perseguir con navegación, zarpazos, arder y el ácido con su shader, `contagiar`,
  `meter_prisa`, la `diana` de la sala de armas, la señal `herido`). Normal, lento, rápido y vigilante solo cambian
  números en su `.tscn`. Heredan: `zombi_explosivo.gd`, `zombi_tentaculos.gd` (el latigazo: su hoja de PixelLab
  va al ritmo del aviso, `IMPACTO`; el tentáculo que pega le sale del hombro, `HOMBRO`, medido en su hoja en cada
  dirección; de espaldas va por delante del dibujo, en el nodo `delante`), `zombi_venenoso.gd`,
  `zombi_dependienta.gd` («¡OFERTAS!») y `zombi_guardia.gd` (el guardia de la tarjeta: ronda, silbato, huye).
  `barra_zombi.gd`: su barrita de vida. `sombra.gd`: la sombra de los pies de todos.
  `tentaculo.gd` (`Tentaculo`; se pinta con `trozos`, no con `draw_circle`: en la web se atascaba, ver `docs/WEB.md`): el tentáculo largo que pega, pintado con código, del zombi de tentáculos y de los
  latigazos del gerente mutado: levantado y enroscado durante el aviso, estirado como un látigo en el golpe; avisa
  con lo mismo que las cargas de los jefes (`Aviso`, la franja de flechas) y, como ellas, se para en las paredes
  y los muebles (`apuntar`). Cada uno le da sus colores, sacados de su hoja (`PALETA`: contorno, capas y
  ventosas, de aro o de puntitos), y sus medidas; los del zombi, oscurecidos como su dibujo en el juego (el
  shader de los zombis multiplica el dibujo por sí mismo y salen más oscuros que en la hoja).
  `lengua.gd` (`Lengua`, hereda de `Tentaculo`): las lenguas del latigazo del Glotón y de la criatura del
  científico. Lo mismo (franja de aviso, se paran en las paredes, capas con los colores de su hoja, sin ventosas
  y con el contorno de un píxel, `borde`), pero con otra forma: en el aviso no se pintan (las enrosca su dibujo) y
  en el golpe salen disparadas de la boca (`BOCAS`, medida en el fotograma del golpe en cada dirección), caen
  sobre el aviso culebreando y se recogen por el mismo camino (`lanzada`). Se prueban con `--lenguas`.
- `portera.gd`: la jefa por defecto, por estados.
- `minijefe.gd`: lo común de los jefes (vida y barra, enfadarse a media vida, llamar zombis, `danar()`,
  `quitar_vida()`, `morder()`, la embestida con su `franja()` y el atontado). El vapor de la cabeza al enfadarse
  (también el de la portera) es `vapor_rabia.gd`; todos los avisos en el suelo de los jefes son `aviso.gd` (los
  pinta el shader `escenas/personajes/aviso.gdshader`, en cuadraditos de pixel art): las cargas (flechas que se
  encienden hasta la pared; también los latigazos de tentáculos y lenguas), los golpes, saltos y círculos (se
  llenan hacia fuera; pueden llegar hasta las paredes, cambiar de color y llevar ondas, como el aspirado del
  glotón; los golpes cuerpo a cuerpo, los saltos de la mascota y del Gymbro, el círculo de la portera y la onda de
  la criatura, `Aviso.golpe`, se cortan donde chocarían con una pared o un mueble, porque no los atraviesan: solo
  dan a Johnny si no está `Aviso.tapado`, un rayo de la capa 1), las barras rectas (alfileres, rayas de los disparos: contratos, cuchillos y bolas de fuego de la
  criatura; se cortan donde el disparo se pararía en una pared o un mueble y ahí acaban en la estrella de las
  cargas; `Aviso.alcance`, medido en cada fotograma con un círculo del ancho de la barra y la capa 1) y las
  flechas del giro del bombero. Se prueban con
  `--golpes`, `--franja`, `--avisos`, `--disparos` (las barras junto a la pared y en campo abierto) y
  `--golpes-pared` (cada golpe, salto y onda con Johnny tras la pared, y su aviso cortado). Heredan:
  - Apartamentos: `gloton.gd` (+ `lengua.gd`), `gymbro.gd` (+ `pesa.gd`), `bombero.gd` (+ `bola_fuego.gd` y `chorro_fuego.gd`, el fuego de los conos del giro: bocanadas de pixelfx que vuelan hasta la pared, se aplastan contra ella y acaban en humo; las balas rebotan en el borde de su burbuja, `bala.rebotar`, con un fogonazo y una onda, `bombero.onda_en`).
  - Centro comercial: `antidisturbios.gd`, `cocinero.gd` (+ `cuchillo.gd`), `modista.gd` (+ `maniqui_vivo.gd`),
    `mascota.gd`.
  - Jefes finales de la azotea, que mutan a media vida (`mutar()`) y al caer llaman a `fin_del_edificio()`:
    `gerente.gd` (+ `contrato.gd`; los tentáculos del mutado, `tentaculo.gd`: salen de tres puntos de su
    espalda, `RAICES`, y se mueven con el cuerpo en cada fotograma del latigazo, `MUEVE`) y `cientifico_jefe.gd`
    (el doctor Salas; las lenguas de la criatura, `lengua.gd`). `helicoptero.gd`: el que llega al final (su cuerpo,
    `helicoptero.png` de PixelLab; los rotores y la luz de la aleta, por código) y suelta su escalera de cuerda sobre
    el helipuerto; al llegar Johnny a ella (`agarrada`) se acaba el edificio (`partida.subir_al_helicoptero`).
- `bala_zombi.gd` (el agua sucia de la portera, gotas de pixel art, rojiza si está enfadada; el polvo de su giro; y los
  alfileres de la modista), `salpicadura.gd`
  (lo que salpica una gota al chocar y su manchita, que se seca), `proyectil.gd` (lo que va en parábola: moco, lejía, molotov del bombero, sartén, probetas) y
  `explosion.gd`.
- `charco.gd` (todos los charcos) y `estados.gd` (lo que hacen: veneno, frío, calambrazo, tirado, `frenado`...).
- `peligros/`: `peligros.gd` (sus números y dónde va cada uno al generar la planta). Del centro comercial: `frio.gd`,
  `fuego.gd`, `agua.gd` (con `arreglar()`) y `cuadro.gd`. De las habitaciones de los jefes de los Apartamentos:
  `porqueria.gd` (Glotón), `tropiezos.gd` (mancuernas del Gymbro, cubos de la portera: sus dos dibujos, `cubo-de-pie.png` y `cubo-volcado.png`, salen de `tools/cubos.py`; la mancuerna, `mancuerna.png`, de `tools/mancuernas.py`, y la dibuja `Pesa.dibujar`, de `pesa.gd`, que usan también las pesas que lanza el Gymbro; se prueba con `--gimnasio` y `--pesas`), `cerco.gd` (bombero) y
  `luz_jefe.gd` (la luz fija de esas habitaciones).
- `calentador.gd` (monta los shaders grandes al abrir el menú, en una pantallita escondida, para que no paren el juego la
  primera vez que se usan: `docs/WEB.md`; si se añade un shader grande, va en su lista).
- `mutaciones.gd`, `llamas.gd` (colores y luz del fuego), `quemado.gd` (el cuerpo que muere ardiendo; cada hoja se lee de la
  tarjeta gráfica una sola vez, `solidos_de`), `cuerpo.gd` (el cuerpo de un enemigo al caer: si tendido se metería en una
  pared, resbala hasta quedar sobre el suelo; se prueba con `--cuerpo-pared`), `brillo.gd`
  (lo que luce a oscuras), `particulas.gd`, `impacto.gd` (la bala que da en una pared: el efecto Impact de la librería
  de efectos de Sprite Fusion, pasado a GDScript, más pequeño y del color de la estela; se prueba con `--impacto`),
  `mancha.gd`, `temblor.gd` (temblor de pantalla y parón de los golpes: el de
  cuerpo a cuerpo dura la `parada` de cada arma en `armas.gd`, más si mata o es crítico y más aún el golpe de gracia; hay
  también al matar a un jefe, en las explosiones que pillan a alguien y cuando le hacen daño a Johnny. No se suman, tras
  uno hay un respiro sin otro corto y la pausa lo corta; la música y el fundido a negro no se frenan. El ajuste
  «Temblor de pantalla» de Opciones (`ajustes.temblor`: 1, 0,5 o 0; `intensidad()`) multiplica el temblor y lo que dura
  cada parón: con 0 no hay ninguno de los dos. Se prueba con `--sensacion` y `--temblor`).
- `persona.gd`: una persona dibujada con formas, para quien no tenga hoja de PixelLab.

**Partida y progreso**
- `partida.gd`: la planta en juego (cambiar de sitio, puertas, llave o tarjeta y su guardia, jefes, escaleras,
  ascensor, dinero, soltar objetos y munición, pausa, fin). Salir de un sitio no lo reinicia: `montar` hace su mapa solo
  la primera vez (`hacer_mapa`) y al salir lo guarda entero en `mapas`, fuera de la escena, donde nada se mueve; al
  volver lo saca tal cual (`sacar_mapa`; lo que no hay que repetir va con `nuevo`, y `supervivientes.recoger` y
  `joyeria.recoger` quitan lo que ellos vuelven a poner). Lo que esté fuera del mapa y apunte a algo de dentro tiene que
  soltarlo al salir (la caza de los aliados) o mirar `is_inside_tree()` (las gotas de `particulas.gd`), porque los
  zombis guardados siguen existiendo. Al dejar la planta se tiran (`tirar_mapas`). En la partida de prueba no se guardan
  (`guarda_mapas`), salvo con `--volver`: las demás pruebas cambian la ficha de un sitio y cuentan con que se rehaga. La
  sala de pruebas y la exposición empiezan siempre de cero. La llave de los Apartamentos no está en el suelo: la lleva
  un zombi al azar de los apartamentos normales (`planta.gd` lo elige con `llave: true`; `zombi_de_la_llave`) y la
  suelta al caer. Y la entrada a la sala de pruebas (`pruebas`,
  `sitio_pruebas`, `en_pruebas`: allí los zombis no cuentan ni sueltan nada). Avisa a la prueba en
  `preparar_prueba()`, `ordenar_jefes_prueba()` y `empezar_prueba()` (en la partida de verdad no hacen nada).
- `edificios.gd`: la ficha de cada edificio, `MINIJEFES` y el sorteo de qué jefe va en cada planta
  (`orden_jefes`, `jefe_de()`).
- `alerta.gd` (niveles de alerta), `eventos.gd` (eventos sorpresa: apagón, incendio y horda; la horda no empieza hasta que Johnny llega al medio del pasillo y, a los 2 s del cartel, sale toda de golpe por los dos extremos, `soltar`; se prueba con `--evento horda`), `reto.gd` (el reto del
  día) y `joyeria.gd` (la cámara acorazada y su premio). Los engancha `partida.gd` (`preparar`, `al_montar`, `recoger`).
- `skins.gd`: las skins de Johnny (`LISTA`, sus ventajas, `de_jefe()`, `siguiente()` para la Z, `hoja()`).
- `objetos.gd`: los objetos (gasolina, bidón de ácido, batería y vendas), los de curar (`USABLES`: las vendas, 25, y el
  botiquín, 50, que además devuelve un tercio de vida perdido, `johnny.devolver_tercio`; van como las demás cosas de
  la mochila y del baúl, con su `TOPE` en la mochila: 2 y 3; se usan con la tecla 1 y la 2,
  `partida.usar_cura`, con casillas junto a la barra de vida en `ui/hud.gd` y botones en `ui/tactil.gd`; el botiquín y las
  vendas los sueltan los armaritos de los baños, uno y uno por piso, `partida.abrir_armarito`, y el botiquín lo prepara la Farmacéutica), qué sale en
  cada tienda (`TIENDAS`), los que suelta un solo zombi (`DE_UN_ZOMBI`), la mochila y el baúl de 32 casillas (un mismo objeto, 99 como mucho en cada una: `MONTON`; el baúl guarda cuántos hay
  y `objetos_baul` los reparte, y `caben_baul` dice cuántos más entran). Y las **piezas**
  de mejora de las armas (`PIEZAS`: cuerpo a cuerpo, a distancia, especial y arrojable): no salen al azar, las suelta
  cualquier zombi (`pieza_de_zombi()`, 6 %) y cada jefe (`piezas_de_jefe()`, 4), en `partida.meter_zombi`, y con la
  alerta salen más (`Alerta.mas_piezas()`). Su ficha dice para qué armas son (`PIEZA_PARA`); se gastan en el banco
  de trabajo (`inventario.gd`). Sus iconos, `assets/ui/iconos/obj-pieza_*.png` (PixelLab, 32×32; ver `assets/pixellab.json` → `piezas`).
  `talentos.gd` (tres ramas, `RAMAS`: Militar, Superviviente y Químico, cada talento una línea en `LISTA` y lo que hace
  en `aplicar_uno`, sobre los atributos de `mejoras.gd`; para lo que no es un número, `Mejoras.de_johnny` se los da a
  quien no tiene a Johnny a mano. Químico (M14): Catalizador suma daño al lanzallamas, al lanza ácido, al lanza rayos, al
  molotov y a la congeladora (`johnny.arma_de`, `lanzables.lanzar`); Guantes de goma quita daño de los estados
  (`johnny.gd`); Incendiario alarga lo que arden (`zombi.prender` y `contagiar`); Desatascador sube lo que come el ácido
  (`ArmasCreadas.con_acido`); Criogenia da congeladoras (`Lanzables.extra_talentos`) y las hace durar (`granada.gd`);
  Reacción en cadena y Residuo tóxico, al morir el zombi (`zombi.quimica_al_morir`: el estallido de las Épicas y un
  charco `residuo`, `charco.gd`), y Pararrayos, al recibir un golpe (`johnny.pararrayos`, con `Talentos.PARARRAYOS`).
  En el ordenador, una pestaña por rama (`ordenador.gd`, `rama_abierta`). Se prueba con `--quimico`. Revisión de
  Militar y Superviviente (M15): Durito llega a 3 (`guardado.gd` devuelve sin gastar los puntos que sobren si un talento
  admite menos), Ajolote cura solo hasta la mitad (`johnny.REGENERA_TOPE`), Ninja cada 5 s (`NINJA_ESPERA`), Puntería
  también lanza más lejos (`alcance_lanzar`, `lanzables.alcance()`) y Mirilla da un crítico de cada 3 disparos. Cada
  tarjeta con puntos dice lo que da ahora y con otro (`Talentos.efecto`), y los críticos salen en amarillo, grandes y con
  «!» (`Zombi.numero_golpe`, con `Zombi.critico`, que ponen `johnny.golpear` y `bala.gd`). Se prueba con
  `--equilibrio-talentos`. Niveles 4 y 5 (M16): cada rama llega a 36 puntos, con un talento de 3 puntos debajo de cada
  uno del nivel 3 y una «corona» de 1 punto que pide los tres del 4 al máximo (`"pide"` admite una lista:
  `Talentos.requisitos`, `faltan` y `nombres`, que usa la tarjeta bloqueada del ordenador). Militar: Frenesí y Gatillo
  fácil (`ritmo_cuerpo`, `ritmo_fuego` y `recarga`, en `johnny.arma_de`), Racimo (se suma al racimo de las Épicas en
  `lanzables.lanzar`) y Veterano (`critico` y `critico_x`, en `johnny.con_critico`). Superviviente: Blindaje (más
  `escudo`), Sombra (`esquiva_espera`), Segundo aliento (`johnny.quitar_vida`, una vez por planta: `aliento_usado`, que
  quita `partida.nueva_planta`) y Adrenalina (`johnny.adrenalina()`, con `Talentos.ADRENALINA`: el daño en `arma_de` y
  `lanzables.adrenalina()`, la velocidad al andar y el aviso en `avisar_adrenalina`). Químico: Napalm (`charco.extra`,
  desde `proyectil.caer`), Pegajoso (`zombi.ir_hacia`), Alto voltaje (`saltos`: el rayo del lanza rayos y el de
  Pararrayos) y Mezcla explosiva (`zombi.quimica_al_morir` con `efectos_puestos`; la marca del rayo, `zombi.electrico`,
  la pone `ArmasCreadas.aturdir`; la explosión lleva `a_johnny = false`, `explosion.gd`). Se prueba con
  `--talentos-altos`),
  `billete.gd` (lo que hay en el suelo: billetes, objetos, cajas), `minimapa.gd`.
- `idioma.gd` (autoload `Idioma`: el idioma del juego y `Idioma.t("texto")` / `Idioma.n("uno", "varios", n)` para traducir,
  también desde los `static`; se elige en Opciones, se guarda en `ajustes.idioma` y avisa con la señal `cambiado`; con
  `--captura` es español salvo con `--ingles`, y al cerrar cuenta los textos sin traducir. Cómo se escribe un texto,
  las tablas `# [traducir]` y la herramienta: `docs/IDIOMAS.md`; nombres fijos del inglés: `docs/GLOSARIO_EN.md`).
- Los datos con texto (`armas.gd`, `objetos.gd`, `lanzables.gd`, `talentos.gd`, `logros.gd`, `mutaciones.gd`, `skins.gd`,
  `eventos.gd`, `averia.gd`, `joyeria.gd`, `barricada.gd`) guardan los textos en español en tablas `# [traducir]` y
  **sus funciones los devuelven ya traducidos** (`Armas.nombre`, `Objetos.nombre`, `Lanzables.uno/varios`,
  `Talentos.nombre_de/desc_de/nombre_rama`, `Logros.nombre_de/desc_de/nombre_tema`, `Skins.nombre/como/efecto`...): quien
  los enseña usa esas funciones, no la tabla directa (`docs/IDIOMAS.md`).
- `partida_guardada.gd` (la partida a medias: al empezar cada planta, una foto de lo que lleva la partida en `en_curso`
  del guardado; «Continuar partida» del menú vuelve al principio de esa planta, que sale igual porque la semilla de
  la partida, `Planta.semilla`, va en la foto; se borra al acabar la partida)
- `guardado.gd` (el guardado; al cargar quita lo que ya no está en el juego; el baúl son `baul`, los objetos, y
  `baul_equipo`, las armas y los arrojables con su calidad; los arrojables, juntos hasta 99 por casilla), `logros.gd` (40 desde el M17, 28 oct; uno =
  una línea en `LISTA`, con su apartado del ordenador, `tema`, de `TEMAS`. Los que salen de algo guardado llevan `mira`
  —skins, bestiario, páginas, objetos, rescatados, talentos, edificio completado— y los da por conseguidos el repaso,
  `revisar()`: al empezar, cada vez que se escribe el guardado (`Guardado.escrituras`), al acabar y al abrir el
  programa Logros; `meta()` y `hecho()` dicen cuánto piden y cuánto llevan. Lo que solo cuentan los logros —jefes,
  victorias, armas con las que se ha matado, reglas del reto— va en `logros_cuentas` del guardado. Los de jefes, en
  `jefe_sale` y `jefe_muerto`; los de ganar, en `partida_ganada`; varios a la vez salen en un solo aviso, `avisar`. En
  la partida de prueba el repaso va apagado, `repasar`, salvo en `--logros`. Con una de las ayudas de `AYUDAS`
  encendida, `sin_logros()` es cierto toda la partida y `cumplir` no apunta nada; los zombis de esas partidas van
  aparte, en `muertos_con_ayudas`, y no suman para Exterminador),
  `historia.gd` (dosier, noticias y relatos, con la historia resumida arriba; se edita sin tocar los `id` y todos los
  textos se ven con `--historia`, y los relatos con `--relato`) y `bestiario.gd` (sus fichas;
  `recorte` lo calcula `tools/recortes_bestiario.py`).
- `tutoriales.gd`: los tutoriales (`LISTA`: grupo, título, icono, cuándo sale y sus líneas, con las teclas entre
  llaves, que salen las del jugador, las del mando o los botones del móvil: `texto()`, `tecla()`), los vistos
  (`Guardado` → `tutoriales`; `toca`, `apuntar`, `olvidar`) y el ajuste de Ayudas. Cada uno sale una sola vez: los
  pide `partida.tutorial(id)` (la mayoría, en `mirar_tutoriales`; el ordenador, la taquilla, el banco, el baúl y la
  mutación sacan el suyo antes de abrirse), `eventos.gd`, `supervivientes.gd` y el menú (el de la alerta). Se prueba
  con `--tutorial`.
- `guia.gd`: el tutorial disimulado de la primera partida (la planta baja de los Apartamentos, con los tutoriales
  encendidos): en vez de las ventanas de `CUBRE`, pistas encima de Johnny con la tecla en amarillo (`PISTAS`: moverse,
  esquivar, atacar, sacar la pistola, recargar, curarse, lanzar y el jefe), la casilla del HUD que late (`hud.latido`),
  una flecha en el suelo hacia la puerta que toca, una llavecita sobre el zombi de la llave y un primer apartamento
  fácil (3 zombis, sin la llave, vendas en el armarito). Lo enseñado se apunta como visto nada más salir la pista, se
  haga o no: tras morir en la primera partida, la siguiente no repite con ventanas lo que ya salió (solo sacará lo que
  la guía no llegó a enseñar). Sale en la partida 1 o si se pidió con «Que vuelvan a salir todos» (`Tutoriales.olvidar`
  apunta `guia_otra_vez`). Se prueba con `--guiado` y, con un jugador que no hace caso, `--guiado --sin-hacer`.
- `supervivientes.gd` (el encerrado en su baño, la horda, los vecinos) y `aliado.gd` (cada superviviente que te
  acompaña; sus hojas, en `HOJAS`). Los rescates propios: `escolta.gd` (farmacéutica), `averia.gd` (técnico) y
  `barricada.gd` (ferretero).
- `pantalla.gd` (autoload): cómo llena la imagen la ventana (`escala_para`, sin bordes y con los píxeles exactos si se puede;
  la prueba es `--escala`) y la pantalla completa del ordenador; arranca como se dejó y la cambian F11 y Alt+Intro
  (`Tactil.pantalla_completa()` la cambia y la guarda). Se prueba con `--pantalla`. Ver `docs/ESCRITORIO.md`.
- `formas.gd` (`Formas`): `disco`, `arco`, `poligono` y `polilinea`, lo mismo que `draw_circle`, `draw_arc`, `draw_colored_polygon` y
  `draw_polyline` pero pintado con primitivas: en la web, 200 polígonos por fotograma tardan un segundo (`docs/WEB.md`).
  Todo el juego pinta con ellas. Se prueba con `--formas` (píxel a píxel contra las de CanvasItem) y `--dibujos`.
- `sonido.gd` (autoload: efectos sintetizados y música; cada efecto cambia un poco al azar de tono y de volumen cada
  vez que suena, salvo los `"fijo"` de los menús y los avisos, y los que llevan ruido se graban en 3 versiones; se
  prueba con `--sensacion`. La música va por capas: cada canción son dos `.ogg` que suenan a la vez, la base y la que
  sube y baja, y `MOMENTOS` dice cuáles se oyen según el momento (`Sonido.musica("menu" | "horda" | "jefe" | "")`) y
  los zombis despiertos, que cuenta cada medio segundo: explorando, la batería entra con uno; en la horda, la melodía,
  con `MUCHOS` (6); con el jefe, la melodía, cuando sale. Suben en 1 s y bajan tras 5 s sin hacer falta; se prueba con
  `--musica`), `controles.gd` (las teclas cambiadas en Opciones).

**ui/**
- `hud.gd` (con la barra del escudo, M22: pegada encima de la de vida, a media altura, con su marco `barra-escudo.png`,
  sacado de `barra-vida.png` cogiendo solo algunas de sus filas para que no se deformen los remaches; mientras se ve,
  las balas y el depósito suben encima de ella; `mover_escudo`, `pintar_escudo`, `con_escudo`; se prueba con
  `--escudo`). El escudo (Acero, Blindaje, Endurecimiento: `johnny.escudo`, M23) se gasta antes que la vida: en
  `johnny.quitar_vida`, todo lo que le quitan (golpes, charcos, el ácido del Glotón) sale del escudo, ya rebajado por
  Durito, y lo que sobra del golpe que lo rompe, de la vida.
- `barra_jefe.gd` (la barra de los jefes, con la de armadura), `presentacion.gd` (la entrada de cada
  jefe), `menus.gd` (pausa y fin; el cartel del final dice al caer
  quién te ha pillado, `quien_te_pilla`: el dibujo, el nombre y la frase del bestiario o el icono y el consejo de su
  peligro; lo conseguido en la partida, que saca `partida.conseguido` comparando el guardado con `al_empezar`; y «Otra vez»,
  también con la R, que no hace caso hasta pasado `ESPERA_FIN`; se prueba con `--derrota`), `menu_principal.gd` (menú y «Elige edificio»; si se cambia el idioma en Opciones, se
  monta otra vez), `opciones.gd` (con el botón de idioma; al cambiarlo se rehace entera, `reconstruir`; en General, el botón «Avisar de un texto mal traducido» a continuación de los idiomas (`enlace_avisos`, el formulario de Google del dueño; vacío no sale,
  y en español tampoco; se prueba con `--idioma`), el temblor de
  pantalla (`TEMBLORES`) y, en el móvil, todo dentro de una caja con barra porque no cabe; la pestaña Créditos, con `AUTORES` y
  `LETRAS_DE_OTROS`, y sus licencias, `texto_de_licencias`: las de esas letras y las de Godot y sus piezas), `tactil.gd`
  (controles del móvil), `tema.gd` (aspecto; a la letra normal le faltan `·` `×` `<` `>` `…` `—`: los saca de Jersey 25, su
  respaldo), `ambiente.gd` (viñeteado, poca vida, escarcha), `botones.gd`
  (autoload: el saltito de los botones), `tele.gd` (la tele de las noticias: el mueble, la calle de detrás y la reportera son dibujos de PixelLab de
  `assets/ui/tele/`; la boca al hablar y el parpadeo, a mano).
- `ordenador.gd`: ConserjeOS (talentos, tienda de armas, logros, Dosier, Noticias, Colecciones). Al comprar o subir algo
  el programa se rehace entero: `marcar` deja cada desplazamiento en su sitio sin que se note (arriba, al abrirlo; se
  prueba con `--ordenador-arriba`, con clics de verdad). Con el teclado o el mando, Godot solo pasa a un botón que se
  vea: `encadenar` le dice a cada botón de una lista con desplazamiento cuál tiene encima y debajo (`--ordenador-teclado`). La tienda, en cuatro
  secciones (`SECCIONES` y los arrojables, que se compran de uno en uno con `comprar_lanzable`, mientras quepan). Con dos armas de ese tipo, `comprar_arma` manda la de repuesto al baúl (`partida.repuesto_al_baul`) antes de `llevar_arma`, solo en la tienda. Cada programa se abre con sus desplazamientos arriba (`marcar()`: marca el botón y, pasado un fotograma, ya colocado todo, deja cada desplazamiento en su sitio; al volver a abrir el mismo tras comprar o subir algo, donde estaban). Se prueba con `--ordenador-arriba`. Los iconos con algo nuevo (`MESA.novedades`: Noticias, Colecciones y Logros por cobrar)
  llevan el rótulo en amarillo y un «!» que bota en la esquina (`marca_nuevo`); se ponen y se quitan con `poner_aviso`, y
  `refrescar_avisos()` los pone al día con el guardado al abrir Colecciones, ver una noticia o cobrar un logro, sin tener
  que apagar (y al apagar también se pone al día el «!» de la mesa). Y los avisos de sucesos, además de la
  línea de abajo (`partida.decir`), dan un grito grande encima de Johnny como el de la llave (`partida.gran_aviso`: noticias
  nuevas, logro y skin nueva); la skin sin ver se apunta en `skins_nuevo` del guardado hasta que se abre la taquilla.
  Se prueba con `--novedades` y `--avisos-ordenador` (que se quitan al mirar o cobrar).
- `inventario.gd`: el inventario «todo a la vista», el baúl (`pintar_baul`, `cosas_baul`: objetos, armas y
  arrojables; `guardar_equipo`, `sacar_equipo`), el banco de trabajo (`pintar_banco`, `en_banco`, `no_mejora`,
  `mejorar`: sube un nivel un arma o un paquete, de lo que lleva o del baúl, con las piezas de la mochila y del baúl)
  y arrastrar con ratón o dedo (`levantar`, `destinos`, `soltar_en`). `taquilla.gd`: la ventanita de las skins.
- `tutorial.gd`: la ventana de un tutorial nuevo (`ventana`, con el juego parado; no hace caso las primeras décimas)
  y el apartado Tutorial del menú principal y de la pausa (`lista`: los temas por grupos, los no vistos con «???»,
  y la ficha del elegido). La ficha (`ficha()`) lleva su foto de `assets/ui/tutorial/`.
- `relato.gd`: los textos de la historia sobre negro (`Historia.RELATOS`): la introducción y un final por edificio, cada
  uno una sola vez (`relatos` en el guardado; no salen en el reto, y una partida continuada no pasa por la introducción
  pero sí saca el final). Las líneas salen solas,
  cualquier pulsación saca la siguiente y cierra al final; Esc o B la saltan. La abre `partida.ver_relato`: la
  introducción, al final de `_ready`, y los finales, en `subir_al_helicoptero`, antes del cartel del final.
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
  Los zombis de un piso (`horda`): un presupuesto (`BASE`, `POR_NIVEL`, el coste de cada tipo en `COSTE`) repartido por
  el tamaño de las habitaciones y, aparte, `EXTRA_POR_SALA` (2) zombis baratos (lentos, normales o rápidos) en cada
  habitación de los pisos de los Apartamentos, no en las tiendas del centro comercial: los que quepan, lejos de la
  puerta (`LEJOS_PUERTA`), de los muebles y de los otros. Sin esos 2 había unos 13 por piso; con ellos, unos 27. La prueba
  `--zombis-sala` los cuenta por habitación.
  La sala de mantenimiento se ve como las viviendas ("cajas": vestuario, despacho y taller, cada uno en su caja de
  tabiques con oscuro alrededor), y también los dos edificios enteros: el pasillo de los Apartamentos, sus pisos, las
  habitaciones de sus jefes y su azotea, y la galería del centro comercial, sus tiendas, las de sus minijefes y su azotea. La azotea, al aire libre, sin tabique que suba (`mapa.al_aire`): su murete, del mismo gris muy oscuro que
  los tabiques (`TABIQUE.COLOR`) y plano, y arriba la ciudad en su cara, con el cielo encima. Con "cajas", solo hay cara de pared donde el tabique de arriba sigue a los lados
  (`mapa.cara_de_caja`): encima de una puerta de lado entre dos estancias no sale cara, el tabique se ve plano.
  Por dónde se llega: solo la planta baja (el portal del edificio) tiene una puerta de llegada a la izquierda; en las
  demás plantas se entra por las escaleras de la derecha, las mismas por las que se sale de la de abajo, y el pasillo no
  tiene puerta a la izquierda; y la azotea (desde el 28 oct) tiene su puerta de llegada a la derecha, como la salida de
  incendios (`puerta_de_llegada()` de `partida.gd` da la que toca; se prueba con `--llegada`).
  La azotea lleva en el centro el helipuerto elevado (`PLATAFORMA`, con la rampa a la derecha, frente a la puerta de llegada: `plataforma()`,
  `rampa()`, `huella_helipuerto()`), sin aparatos encima ni su dibujo; es el ring del jefe final: espera arriba
  (`esperando` en `minijefe.gd`) y, al subir Johnny, `valla.gd` cierra la rampa hasta que cae (`partida.mirar_ring`).
  Su borde choca en la capa 4 (`CAPA_BORDE`: para a los que andan, no a las balas). Sus aparatos van siempre en el
  mismo sitio (`APARATOS`, uno por edificio; ninguno cerca de la puerta, de la rampa ni del helipuerto: lo mira `--azotea`). No tiene más puerta que la de llegada: se sale por la escalera del helicóptero. Se prueba con `--azotea`.
  `apartamento.gd` da cada piso, que es siempre el mismo (dibujado con letras en `PLANO_PASILLO`, volteado cuando la
  puerta da arriba; sus muebles, solo los puestos a mano: `colocados` en `catalogo.gd`, por ahora el dormitorio de matrimonio con la
  puerta abajo), y la habitación de cada jefe; `tienda.gd` genera cada tienda;
  `viviendas.gd`, el pasillo de los rescatados. Se ve como una casa por dentro desde arriba ("cajas" en el sitio): cada
  habitación y el pasillo, cerrados por sus tabiques de una casilla de grueso, lisos y de un gris muy oscuro (`tabique.gd` y
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
- `cara_pared.gd`, `neon.gd`; `ordenador.gd` (la mesa; `novedades(s)` dice qué programas tienen algo nuevo), `arrimable.gd`,
  `exclamacion.gd` (el «!» que bota encima de la mesa del ordenador y de la taquilla mientras haya algo nuevo; se
  pone con una `condicion` y se mira cada segundo)
  (baúl, banco, taquilla), `armarito.gd`, `cientifico.gd` (el muerto con su página),
  `valla.gd` (la del helipuerto de la azotea).

**luz/**: `luz.gd` (penumbra de cada sitio, luz de Johnny, fogonazos), `lampara.gd`, `fuego.gd`.

**pruebas/**: lo que solo se usa con `--captura`.
- `captura.gd` (clase `Captura`): `activa()`, `dato("--jefe", "antidisturbios")` y `foto("captura-x.png")` (la guarda en `capturas/`, que lleva un `.gdignore` para que Godot no la importe).
  Y el seguro de las pruebas: el menú pasa a la partida con `Captura.ir_a_la_partida()`, que antes de abrir la de prueba
  mira que compile (si no, `diagnosticar()` carga uno a uno los archivos de `scripts/pruebas/` para que cada uno cuente su
  error y su línea) y, si no, cierra con el código 2; y `vigilar()` (puesto por el menú con `--captura`, salvo en el trailer)
  cierra con el código 1 al primer error de script a mitad de una prueba. En los dos casos dice
  `ERROR DE LA PRUEBA: …` en la terminal: nunca más una prueba en negro que no acaba.
- La partida de prueba va en una cadena de archivos por tema, cada uno hereda del anterior: `prueba_comun.gd` (hereda
  de `partida.gd`) → `prueba_jefes_salas.gd` → `prueba_jefes.gd` → `prueba_armas.gd` → `prueba_skins.gd` →
  `prueba_inventario.gd` → `prueba_fotos.gd` → `prueba_sitios.gd` → `prueba_reglas.gd` → `prueba_larga.gd` →
  `partida_prueba.gd`, el último, que los tiene todos. Al principio de `partida_prueba.gd` está la lista de opciones
  (`--jefe`, `--armas`, `--inventario`...) con el archivo de cada una.
- `prueba_idioma.gd` (`PruebaIdioma`, fuera de la cadena: la lanza el menú con `--idioma`): el menú, Opciones y «Elige
  edificio» en el idioma de la prueba y el cambio de idioma en caliente. `--ingles` pone cualquier prueba en inglés.
- `prueba_mando.gd` (`PruebaMando`, fuera de la cadena: la lanza el menú con `--mando`): A y B del mando en el menú
  principal (JUGAR, «Elige edificio», Opciones, Tutorial) y los botones de mando de mentira que usa también
  `probar_mando()` de `prueba_varias.gd` (la pausa, Opciones, un tutorial, el inventario, la taquilla, el ordenador, una
  página, el panel de pruebas y el cartel del final).

## assets/

- `sprites/`: las hojas (`.png` + `.json`) y sus animaciones (`.tres`). Hoja nueva →
  `py tools/hacer_frames.py assets/sprites/<nombre>`.
- `musica/`: «El último inquilino» (menús y explorar: `el-ultimo-inquilino-base.ogg` y `-bateria.ogg`) y «Turno de
  noche» (hordas y jefes: `turno-de-noche-base.ogg` y `-melodia.ogg`), las capas que suenan a la vez (`CANCIONES` y
  `MOMENTOS` de `sonido.gd`). En el ordenador cada canción empieza en un compás al azar; en la web, siempre al principio
  (ver `docs/WEB.md`).
- `ui/` (HUD, menús e iconos; `ui/tutorial/`, las fotos de las fichas de los tutoriales), `fuentes/` (la de siempre, nítida a 16 y 32, y `jersey-25.ttf` de los jefes, nítida a
  25 y 50, que va siempre con su licencia `jersey-25-OFL.txt`), `tiles/`, `pruebas/` (montajes para revisar dibujos).
- `sources/`: originales (con `.gdignore`). `pixellab.json`: todo lo generado en PixelLab.

## tools/

- **El trailer:** `trailer.py` lo graba con el Movie Maker de Godot y lo monta con ffmpeg (ver `docs/TRAILER.md`).
- **Lo dibujado en otro idioma:** `cartel_planta_idiomas.py` hace los carteles de planta con la palabra de cada idioma («FLOOR»,
  «ANDAR», «ETAGE»: `cartel-planta-N-<idioma>.png`) y `fotos_tutorial.py <idioma>` recorta las fotos de los tutoriales de las
  capturas sacadas con `--lang <idioma>` (`assets/ui/tutorial/<idioma>/`).
- **Las traducciones:** `traducciones.py` recoge los textos del código, pone al día los `locale/*.po` y avisa de lo que falta
  o está mal (`py tools/traducciones.py`; antes de cada commit que toque textos). Ver `docs/IDIOMAS.md`.
- **La letra del juego:** `arreglar_tildes_fuente.py` pone bien las tildes (á é í ó ú y mayúsculas), el punto de la í y los ¿ ¡ de
  `assets/fuentes/zombie-scape-ui.ttf` (ver `docs/IDIOMAS.md`, «Las tildes de la letra del juego»); después, `--headless --path . --import`.
- **Efectos de pixelfx** (el plugin de efectos pixel art, MIT, `git clone https://github.com/patch-gg/pixelfx`):
  `pixelfx/exportar.mjs` saca un efecto en tres hojas para Godot (detrás del personaje, delante y el brillo, que se suma)
  y `pixelfx/escudo-fuego.js` es la burbuja de fuego del jefe de bomberos (`escudo-fuego-*.png`, en `bombero.gd`):
  `node tools/pixelfx/exportar.mjs <pixelfx> tools/pixelfx/escudo-fuego.js assets/sprites`.
  `pixelfx/escudo-cristal.js` es lo mismo en azul y más pequeño: la cúpula del científico jefe (`escudo-cristal-*.png`,
  en `cientifico_jefe.gd`; las balas rebotan en su borde igual que en la burbuja del bombero, con `colores_escudo()`).
  `pixelfx/bocanadas.mjs` hace `bocanadas-fuego.png`, las bocanadas de fuego y de humo de "fire-breath" en 10 tamaños y
  10 edades, para el chorro del lanzallamas del bombero (`node tools/pixelfx/bocanadas.mjs <pixelfx> assets/sprites`).
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
- **Texturas:** `textura_suelo.py`, `textura_pared.py`, `textura_tapa.py`, `suelo_salon.py` (el suelo de nogal del salón), `azotea.py` (ver
  `FONDOS.md`).
- **Iconos:** `icono_*.py` (los objetos son todos de PixelLab, 32×32: ya no queda ninguno hecho con código),
  `hacer_casillas.py`, `recortes_bestiario.py`.
- **El logo** (`assets/ui/logo.png`, «JOHNNY RUSH» grande y «ZOMBIE ESCAPE» pequeño debajo; lo ponen `menu_principal.gd` y el final de
  `pruebas/trailer.gd`): no está dibujado a mano, lo genera `py tools/logo.py` (el programa de `src/titulo.js` del juego JS, pasado a
  Python: cada letra es una cuadrícula de 5×7 con relieve, babas y un filo crema). Las letras están en `LETRAS` (J, H, N, Y, R y U son
  las añadidas al pasar al nombre nuevo), los colores en `REPARTOS` (`py tools/logo.py todas` los enseña todos juntos; el elegido es
  `VARIANTE`) y `py tools/logo.py viejo` rehace el logo de antes, idéntico, para comprobar que el programa no ha cambiado.
- **Fotos de los tutoriales:** `fotos_tutorial.py` recorta de las capturas de la prueba (520 × 180, a tamaño real) la
  foto de cada ficha; al lado de cada una, la prueba que saca su captura: `py tools/fotos_tutorial.py [id...]`.
- **Ver sin jugar:** `ver_dibujos.tscn` (foto de los dibujos hechos con código) y `probar_sonido.gd` (los efectos en
  `tools/efectos/*.wav`, que no van a git).
- **Música de 8 bits:** `motor-8bit.mjs` y las canciones (`el-ultimo-inquilino.mjs`, `turno-de-noche.mjs`,
  `villancico-8bit.mjs`, de prueba). `node tools/<canción>.mjs` saca el `.wav` y el `.ogg`; con `--veces 4`, en bucle.
  Por capas: cada instrumento dice su `capa` (y la percusión y demás, la suya en `capas` de `crearMotor`), `guardar()`
  saca un `.wav` por capa, a la misma ganancia, que sumados suenan como la canción entera, y la partitura pasa cada uno
  a su `.ogg`. El trailer suma las capas al montar.

## docs/

- `historial/`: los planes ya terminados (`CENTRO_COMERCIAL.md`, `JEFES_APARTAMENTOS.md`). Solo para saber por qué se
  decidió algo; lo que vale es el código.
- `IDIOMAS.md` (cómo se traduce el juego y cómo se escribe un texto nuevo) y `GLOSARIO_EN.md` (cómo se dice cada nombre en inglés).
- `PIXEL_ART.md`, `PIXELLAB.md`, `ZOMBIS.md`, `FONDOS.md`, `MAPA.md`: del juego JS y de lo dibujado después; valen
  para las ideas y los números.
