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
  shaders: `cintura` (Johnny partido por la cintura al golpear andando; incluye `quemaduras.gdshaderinc` para arder
  como los zombis, `johnny.arder`, y de `Llamas` solo le queda la luz; prueba: `--captura --johnny-ardiendo`; y las manchas de ácido
  de los zombis cuando lleva algo que corroe, `Johnny.CORROEN`: el veneno del gordo, el ácido de la portera y la porquería del Glotón,
  M65; prueba: `--captura --reventon`), `destello` + `quemaduras.gdshaderinc` (destello,
  hielo, fuego y ácido de los enemigos; el "vomito" de los bañados por la Gastroenteritis, el estado `vomito` que pone
  su charco, solo para verse, 2 s, prueba `--captura --vomito`; y el "metal" del Gymbro con suplementos, que sube desde los pies y se desconcha
  con "pelado") y `brillo`.
- `armas/`: `bala`, `bala_zombi`, `proyectil`, `charco` y `explosion`; los shaders `llamarada` (lanzallamas) y
  `chorro_acido` (lanza ácido); el rayo del lanza rayos no tiene: se dibuja a código en `llamarada.gd`.
- `luces/`: `lampara.tscn`, `fuego.tscn`, `luz_suave.tres` y los shaders `niebla` y `suelo_a_oscuras`.

## scripts/

**Johnny y sus armas**
- `johnny.gd`: moverse, vida, apuntar y atacar (`tiro`, `blanco_en_linea`), recibir daño (`recibir_dano(cantidad,
  quien, peligro)`; quién le ha quitado vida la última vez queda en `golpe_de`: un enemigo, por su meta `"tipo"`, que
  lee `Bestiario.de` y le ponen al nacer `partida.meter_zombi`, la modista a sus maniquíes y los jefes al mutar; o un
  peligro de `Menus.PELIGROS`: el charco que más quema, `charco_que_quema`, el agua con corriente, el cable pelado o su
  granada, `explosion.de`), tropezar (`caer`) y despertarse tumbado tras una derrota (`despertar`), las skins (`vestir`, y sus ventajas en `arma()`, `ignifugo()`, `devolver()`), la
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
  `electrocutar`). `goteo.gd`: la gota que cuelga de la boquilla del lanza ácido, y la de sangre de la punta de la
  motosierra (`sangra` en `armas.gd`). La **motosierra** (6 nov): golpe lento y fuerte por encima de la cabeza
  (`golpe_dura`: su golpe dura 0,7 s y no 0,5), casilla de 112×112; su hoja sale de PixelLab y la sangre de la espada
  la pinta `tools/sangre_motosierra.py` (receta en `assets/pixellab.json` → `conserje-48-motosierra`); prueba `--motosierra`. La **katana**
  (6 nov): envainada a la cadera; el golpe es desenvainar con un corte de abajo arriba que deja una media luna de luz
  (casilla de 96×96 con los pies en 48,84; receta en `assets/pixellab.json` → `conserje-48-katana`); prueba `--katana`.
  La **gatling** (6 nov): arma a distancia con su propia munición, la cinta de balas (`"cinta"` en `Armas.MUNICION`);
  los cañones giran medio segundo antes de la primera bala (`arranque`; `johnny.gd`: `giro_t`, `girando()`), Johnny
  anda más despacio mientras dispara (`lenta`) y sin el empujón del dibujo (`sin_patada`); usa el fogonazo de la MP5
  (`fogonazo`). Receta en `assets/pixellab.json` → `conserje-48-gatling`; prueba `--gatling`.
  El **lanzagranadas** (6 nov): arma a distancia con su propia munición, las granadas de 40 mm (`"granadas_40"` en
  `Armas.MUNICION`); con `"granada": true` no dispara balas sino `granada_40.gd`, que vuela despacio y revienta al
  tocar a un zombi, una pared o al llegar a su alcance con la explosión de la granada de mano (también a Johnny, como
  mucho `Lanzables.DANO_JOHNNY`). Tambor de 6 que se recarga de una en una (`cartucho`); usa el fogonazo de la escopeta
  y su sonido `"lanzagranadas"`. Receta en `assets/pixellab.json` → `conserje-48-lanzagranadas`; prueba `--lanzagranadas`.
- `lanzables.gd`: molotov, granada, atraedora y congeladora, en **montones** (M18, 28 oct): cada hueco lleva un montón
  de una clave de hasta `MONTON` (2 desde la M74; más con la calidad y el Artificiero o Criogenia: `maximo`). 3 a mano (`mano`, una
  de cada clave, F cambia; sus cuentas en `cantidades`) y 4 de repuesto (`REPUESTO`, 8 hasta la M67; `repuesto` y sus cuentas en `en_repuesto`,
  con varios de la misma clave). Sin tope por tipo: se coge mientras quepa (`cabe`, `meter`: primero en sus montones
  sin llenar, luego en uno nuevo). Al acabarse el de la mano entra otro de repuesto (`repasar`, `relevo`: el de su
  clave, uno de su tipo o el primero). Un montón se señala por su sitio, el nombre de su casilla en el inventario
  (`"l1"`, `"e3"`: `clave_en`, `cuantos_en`, `sitio_de`, `quitar`, `mejorar`); `a_la_mano` y `al_repuesto`, por su
  número. Lo que cuesta uno en la tienda (`PRECIOS`). La clave de un montón es el tipo y, si no es Normal, la calidad
  detrás (`"molotov:2"`; `clave`, `tipo_de`, `calidad_de`; el banco lo sube con `mejorar`). Al completar el edificio
  van todos al baúl (`partida.equipo_encima`, `montones`), también los Normales; allí se juntan los del mismo tipo y
  calidad hasta 99 por casilla (`Objetos.arrojables_al_baul`, `caben_arrojables`) y salen de montón en montón
  («Sacar 3»). Se prueba con `--montones`. A los jefes, el fuego y las explosiones les hacen la mitad (`A_JEFES`,
  `a_jefe`: lo miran `explosion.gd`, `charco.gd` y `proyectil.gd`).
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
  `meter_barrera`, la burbuja dorada del grito de la dependienta (M80), la `diana` de la sala de armas, la señal `herido`). Normal, lento, rápido y vigilante solo cambian
  números en su `.tscn`. Heredan: `zombi_explosivo.gd`, `zombi_tentaculos.gd` (el latigazo: su hoja de PixelLab
  va al ritmo del aviso, `IMPACTO`; el tentáculo que pega le sale del hombro, `HOMBRO`, medido en su hoja en cada
  dirección; de espaldas va por delante del dibujo, en el nodo `delante`), `zombi_venenoso.gd`,
  `zombi_dependienta.gd` (su grito, «¡¡¡AAAHHH!!!», pone la barrera a los demás hasta que ella muere) y `zombi_guardia.gd` (el guardia de la tarjeta: ronda, silbato, huye).
  Los de Torre Velaria: `zombi_oficinista.gd` (guarda las distancias y tira tazas y grapadoras, `bala_zombi.gd`) y
  `zombi_escolta.gd` (el chaleco para media bala de frente, con `Zombi.de_bala`, que pone `bala.gd`; el táser deja a Johnny
  tieso con el `"calambre"` de `estados.gd`, desde `dar_zarpazo`, que cualquier tipo puede cambiar). Salen en los
  departamentos (`planta.gd`, `horda`: `OFICINISTAS` y `ESCOLTAS_SEGURIDAD`) y los escoltas, con la alarma de las cámaras.
  Pruebas: `--captura --edificio torre --oficinista` y `--escolta`.
  El cuerpo de choque de un zombi no puede ser mucho mayor que el radio de la navegación (18, `mapa.hornear`): si no,
  no cabe por los caminos que le salen. Por eso el del venenoso mide 18 aunque su `radio`, el de los golpes, sea 30.
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
  - Apartamentos: `gloton.gd` (+ `lengua.gd`), `gymbro.gd` (+ `pesa.gd`; con los suplementos se vuelve de metal, que se desconcha según pierde armadura y revienta
  en esquirlas al acabarse, con los sonidos "acero", "metalizar" y "chatarra"; prueba: `--captura --jefe gymbro --metal`), `bombero.gd` (+ `bola_fuego.gd` y `chorro_fuego.gd`, el fuego de los conos del giro: bocanadas de pixelfx que vuelan hasta la pared, se aplastan contra ella y acaban en humo; las balas rebotan en el borde de su burbuja, `bala.rebotar`, con un fogonazo y una onda, `bombero.onda_en`).
  - Centro comercial: `antidisturbios.gd`, `cocinero.gd` (+ `cuchillo.gd`; su Cocina central, `jefe-cocinero` en el catálogo, tiene tres fogones o freidoras en cada pared (arriba, izquierda y derecha) que en el combate rebosan aceite hirviendo, un charco "hirviendo" con `crece` que se va extendiendo: M82, prueba `--captura --edificio centro --jefe cocinero --cocina`), `modista.gd` (+ `maniqui_vivo.gd`),
    `mascota.gd`.
  - Torre Velaria: `directora.gd` (la directora de Recursos Humanos, + `cae_encima.gd`: su sello gigante y las cajas de cartón,
    que caen del techo con su marca en el suelo; el sello «despide» a Johnny, `johnny.despedir()`: unos segundos sin el arma de
    fuego. Su Despacho de Recursos Humanos, `jefe-directora` en el catálogo, con muebles fijos de la torre; prueba
    `--captura --edificio torre --jefe directora --despacho`). `informatico.gd` (el informático: tira teclados en abanico,
    `teclado.gd`; el cortocircuito, `cortocircuito.gd`: franjas del suelo que dan corriente por turnos, con chispitas antes; el
    apagón de su sala unos segundos, `Luz.evento`; enfadado se «reinicia» junto a otro armario. Pinta las lucecitas de los armarios
    de servidores, que lucen a oscuras. Su Centro de datos, `jefe-informatico` en el catálogo: pared de armarios y filas sueltas,
    `islas`; prueba `--captura --edificio torre --jefe informatico --datos`). `presentador.gd` (el presentador: el grito al
    micrófono, un cono en el suelo y una onda que empuja; los focos de su sala, cuyo haz sigue a Johnny y, si los mira, ponen la
    pantalla blanca; los cañones de confeti, `confeti.gd`, que revientan donde estaba Johnny. Sienta a su público de oficinistas
    en las butacas, `sentado` en `zombi.gd`: no se despiertan solos, el apuntado automático no los elige y, enfadado, los levanta a
    todos; si muere, se desploman con él. Su Plató de presentaciones, `jefe-presentador` en el catálogo: escenario con pantalla,
    atril y focos en la pared de arriba y filas de butacas, `islas` con `arriba`; prueba
    `--captura --edificio torre --jefe presentador --plato`). `becario.gd` (el becario: corre a la fotocopiadora más cercana y,
    con un destello, salen sus copias, `copia_becario.gd`, iguales pero sin sombra y más claras, que mueren de un golpe y no
    pegan hasta que se enfada; él se cambia de sitio con una y es el único que se refleja en el frontal de las fotocopiadoras
    cercanas. El carrito del correo, dibujado con código, embiste por una franja roja, `embestir` de `minijefe.gd`. Los vasos de
    café, `"cafe"` en `proyectil.gd`, dejan el charco `"cafe"` de `charco.gd`, que resbala. Si muere, las copias se deshacen en
    papeles. Su Sala de fotocopias, `jefe-becario` en el catálogo: tres fotocopiadoras, impresoras, archivadores y lámparas arriba,
    fuentes y plantas a los lados y dos filas de escritorios, `islas` con `arriba`; prueba
    `--captura --edificio torre --jefe becario --fotocopias`).
  - Jefes finales de la azotea, que mutan a media vida (`mutar()`) y al caer llaman a `fin_del_edificio()`:
    `gerente.gd` (+ `contrato.gd`; los tentáculos del mutado, `tentaculo.gd`: salen de tres puntos de su
    espalda, `RAICES`, y se mueven con el cuerpo en cada fotograma del latigazo, `MUEVE`) y `cientifico_jefe.gd`
    (el doctor Salas; las lenguas de la criatura, `lengua.gd`; lo seguido que ataca la criatura se mide con `--criatura`). `helicoptero.gd`: el que llega al final (su cuerpo,
    `helicoptero.png` de PixelLab; los rotores y la luz de la aleta, por código) y suelta su escalera de cuerda sobre
    el helipuerto; al llegar Johnny a ella (`agarrada`) se acaba el edificio (`partida.subir_al_helicoptero`).
- `bala_zombi.gd` (el agua sucia de la portera, gotas de pixel art, rojiza si está enfadada; el polvo de su giro; los
  alfileres de la modista y las tazas y grapadoras del oficinista, que dan vueltas), `salpicadura.gd`
  (lo que salpica una gota al chocar y su manchita, que se seca), `proyectil.gd` (lo que va en parábola: moco, lejía, molotov del bombero, sartén, probetas) y
  `explosion.gd` (lo que se ve es la explosión de pixelfx: `tools/pixelfx/explosion.js`, una copia de "small-explosion" más
  grande y sin las piedras ni la tierra, que caían en raya vista desde arriba; la exporta `exportar_explosion.mjs` en
  `explosion.png` y `explosion-brillo.png`, con sus dos capas; las pequeñas, a la mitad. Prueba: `--captura --explosion`).
- `charco.gd` (todos los charcos) y `estados.gd` (lo que hacen: veneno, frío, calambrazo, tirado, `frenado`...).
  El gordo (`zombi_venenoso.gd`) revienta al morir: `efecto_suelo.gd`, tipo `reventon` (la corona y las gotas de veneno, hojas de pixelfx) y
  el charco grande `reventon`, con burbujas gordas como las de "toxic-puddle" (`charco.pintar_burbujas_gordas`).
  `efecto_suelo.gd` hace los efectos de pixelfx que salen una vez en el suelo (sus tres hojas y el precalentado para que
  el primero no pare el juego); los otros tipos son `gases`, la nube del Flatulento (`mutaciones.gd`), del tamaño de su radio,
  y `molotov`, la botella al romperse (`proyectil.llamarada`: el chasquido, la gasolina que prende, llamas, chispas y
  cristales que saltan y resbalan; un efecto hecho para el juego, `tools/pixelfx/molotov.js`, exportado con
  `exportar.mjs`; se precalienta al lanzarla). Prueba: `--captura --molotov`.
  Y `sangre` (roja), `sangre-verde` (el venenoso) y `sangre-morada` (el de tentáculos): el zombi que muere de un golpe fuerte
  (un crítico, uno que empuja como una explosión, `Zombi.MUERTE_FUERTE`, o uno que le sobra media vida: `zombi.muerte_fuerte`)
  revienta en sangre (`partida.sangre`): un efecto hecho para el juego, `tools/pixelfx/reventon-sangre.js` y sus colores
  `-verde.js` y `-morada.js`; se precalienta al aparecer el primer zombi de cada color. Prueba: `--captura --reventon-sangre`.
  Y `chispazo`: la electricidad al dar a un zombi (M50), el `zap-hit` de pixelfx desde arriba (`tools/pixelfx/chispazo.js`):
  un nudo de rayitos a la altura del cuerpo, chispas que hacen eses y una quemadura de helecho en el suelo. Lo sueltan el
  lanza rayos en cada zombi que toca (`llamarada.golpe_de_rayo`; se precalienta al sacarlo) y `ArmasCreadas.rayo`.
- `relampago.gd` (`Relampago`): el rayo que salta de un sitio a otro (la descarga de un zombi a otro, el estallido de las
  Épicas de rayo y Pararrayos; lo suelta `ArmasCreadas.rayo`, con el chispazo donde da). Dibujado a código como los rayos de
  pixelfx: zigzag partido por la mitad con ramas, borde, cuerpo celeste y centro blanco, rehecho 20 veces por segundo y fuera
  en 0,22 s. Prueba: `--captura --chispazos`. El rayo continuo del lanza rayos (`llamarada.dibujar_rayo`) se traza y
  se entinta con lo mismo (`Relampago.trazar` y `pintar`).
- Escarcha (M51; `efecto_suelo.gd`, `escarcha` y `escarcha-zombi`): la congeladora ya no explota en fuego. Su explosión
  (`explosion.gd`, `helada`) hace el mismo daño pero suelta el estallido de escarcha de pixelfx (`tools/pixelfx/escarcha.js`,
  a la escala de su radio), con luz fría y sin quemadura en el suelo. Cada zombi que se congela (la congeladora y la cámara
  frigorífica, `zombi.congelar`) suelta la pequeña (`escarcha-zombi.js`). La congeladora usa el congelado de verdad
  (`zombi.congelar`: azul hielo con el shader, el dibujo parado, copos; cuenta para Mezcla explosiva). Prueba: `--captura --escarcha`.
  Y `deshielo`: cuando se le acaba el congelado, o muere congelado (`zombi.deshelar`), el hielo revienta en trozos
  (`tools/pixelfx/deshielo.js`, la idea del `ice-shatter` de pixelfx), con su sonido (`deshielo`).
- Golpes de los jefes (M58; `efecto_suelo.gd`, `pisoton` y `golpe-pared`, con la idea del `dirt-explosion` de pixelfx):
  el pisotón (`tools/pixelfx/golpe-suelo.js`: polvo, grietas, una onda por el suelo y cascotes) al aterrizar el Gymbro y
  la mascota y en el puñetazo del científico, a la escala de su zona (`EfectoSuelo.ONDA_PISOTON`); y el golpe contra la
  pared (`golpe-pared.js`: nube de yeso y cascotes) en `minijefe.estrellarse`. Se precalientan en `minijefe._ready`.
  Prueba: `--captura --impactos` (`--golpes` es otra: el aviso de los golpes cuerpo a cuerpo).
- La llamada de la atraedora (M52; `efecto_suelo.gd`, `llamada`): en cada pitido (`granada.gd`), dos ondas amarillas que
  se abren por el suelo y el ring-ring del despertador (`tools/pixelfx/llamada.js`); va de hija de la granada. Como pita
  cada vez más deprisa, las ondas también. Prueba: `--captura --llamada`.
- El lanzallamas y el lanza ácido al dar (M59 y M60; `efecto_suelo.gd`): en cada pellizco (`llamarada.quemar`), en cada
  zombi tocado, `chorro-fuego` (una bocanada que lo lame y sube) o `chorro-acido` (gotas, burbujas y vapor), y, si el chorro
  se corta en una pared, `pared-fuego` o `pared-acido` (más anchos; el ácido chorrea). Un efecto con cuatro versiones:
  `tools/pixelfx/chorro-golpe.js`, `-acido.js`, `chorro-pared.js` y `-acido.js`. Se precalientan al sacar el arma.
  Pruebas: `--captura --lanzallamas` y `--desintegrador`.
- Recoger y curar (M53 y M56; `efecto_suelo.gd`): `recoger`, el destello dorado al coger algo del suelo (`billete.gd`:
  billetes, lanzables, objetos, armas y munición; `tools/pixelfx/recoger.js`), y `curacion`, la médica cura a Johnny
  (`aliado.curar`; `curacion.js`, rehecha en la M66: un círculo de luz verde con un anillo a sus pies, una columna de luz que
  le sube alrededor, cruces con borde y chispitas, de hijo de Johnny; ya no hay raya de la médica a Johnny). Prueba: `--captura --recoger-curar`.
- El desfibrilador (M55; `efecto_suelo.gd`, `desfibrilador`): cuando Johnny cae con el talento y vuelve con toda la vida
  (`johnny.recibir_dano`), dos descargas en el pecho (rayitos, chispas y un anillo eléctrico) y luego un latido verde de
  electrocardiograma sobre la cabeza (`tools/pixelfx/desfibrilador.js`, de hijo de Johnny). Se precalienta en
  `johnny.preparar_fogonazo` si tiene el talento. Prueba: `--captura --desfibrilador`.
- Elegir una mutación (M54; `efecto_suelo.gd`, `mutar`, en vez del anillo morado de antes): en `partida.elegir_mutacion`,
  Johnny se enciende de morado, dos hebras de ADN le suben enroscadas, ondas blandas por el suelo y burbujitas
  (`tools/pixelfx/mutar.js`, de hijo de Johnny). Se precalienta al abrir el recuadro. Prueba: `--captura --mutaciones`.
- El rugido de los jefes (M57; `efecto_suelo.gd`, `rugido`): en su presentación (`ui/presentacion.gd`), al gritar, ondas
  de sonido que salen de la cabeza (con borde oscuro, para que se lean en cualquier suelo), un destello rojizo y una onda
  de polvo a sus pies con piedrecitas (`tools/pixelfx/rugido.js`). Va junto al jefe, no de hijo (hay jefes que crecen);
  los que entran escondidos (la Modista) no lo llevan. Prueba: `--captura --presentacion` (`captura-presentacion-rugido.png`).
- Los tentáculos de Tentacular (M29; `efecto_suelo.gd`, `tentaculos`, en vez del anillo morado): cuando la mutación
  empuja (`mutaciones.actuar`), seis tentáculos le salen a Johnny de la cintura, restallan ondulando hasta donde llega el
  empujón (escala: su radio / `EfectoSuelo.RADIO_TENTACULOS`), dan en el suelo (onda y baba) y se recogen enroscándose; los
  que van hacia arriba de la pantalla, detrás de él (`tools/pixelfx/tentaculos.js`, de hijo de Johnny). Se precalienta en
  `mutaciones._physics_process`. Prueba: `--captura --tentacular` (`--tentaculos` es la del zombi de tentáculos).
- `fogonazo.gd`: el fogonazo de pixelfx de los disparos de Johnny (pistola, MP5 y escopeta; lo suelta `johnny.disparar`).
  Dos partes con su color y su brillo: la llama, ya girada en 9 ángulos (hacia la izquierda, dada la vuelta; la pistola
  con 2 formas y la MP5 con 3, que se turnan) y el humo, en 5 rumbos y sin girar (siempre sube). Se ordena como las balas
  y se precalienta al coger el arma (`johnny.preparar_fogonazo`). El fogonazo dibujado en las hojas de Johnny sigue
  debajo. Prueba: `--captura --fogonazos`. También los supervivientes que disparan (`aliado.disparar`, con
  `Aliado.FOGONAZO_ARMA`): el policía, el de la pistola, y el militar, el de la MP5; se precalienta al aparecer
  (`aliado.preparar_fogonazo`). Prueba: `--captura --fogonazos-aliados`.
- `chispa.gd`: la chispa de pixelfx ("hit-spark") de las balas al dar a un zombi (la suelta `bala.chocar`): del color de
  la estela (normal, crítica, cada calidad; la Épica que atraviesa, morada), más pequeña con los perdigones, en 5
  direcciones (hacia la izquierda, dada la vuelta) y con las chispas cayendo al suelo. Por encima de los personajes.
  Contra las paredes sigue `impacto.gd`. Se precalienta con el fogonazo. Prueba: `--captura --chispas`.
- La trazadora de las balas (`bala.gd`, `_draw`), en código y no con hojas para que valga para cualquier ángulo y color:
  el cuerpo gordo de siempre y, como el "bullet-tracer" de pixelfx, una cola fina que se enfría, parpadea y acaba a
  trozos, y chispitas que suelta y caen (`mover_chispitas`). Prueba: `--captura --trazadora`.
- `peligros/`: `peligros.gd` (sus números y dónde va cada uno al generar la planta). Del centro comercial: `frio.gd`,
  `fuego.gd`, `agua.gd` (con `arreglar()`) y `cuadro.gd`. De las habitaciones de los jefes de los Apartamentos:
  `porqueria.gd` (Glotón), `tropiezos.gd` (mancuernas del Gymbro, cubos de la portera: sus dos dibujos, `cubo-de-pie.png` y `cubo-volcado.png`, salen de `tools/cubos.py`; la mancuerna, `mancuerna.png`, de `tools/mancuernas.py`, y la dibuja `Pesa.dibujar`, de `pesa.gd`, que usan también las pesas que lanza el Gymbro; se prueba con `--gimnasio` y `--pesas`; al tropezar, Johnny se cae de espaldas, se queda tumbado y se levanta con sus dibujos de PixelLab, sin el arma: `johnny.caer`, hoja `conserje-48-caida`, que monta `tools/caida.py`, y la de cada skin, `tools/caida_skins.py`; se prueba con una skin con `--skin X`), `cerco.gd` (bombero) y
  `luz_jefe.gd` (la luz fija de esas habitaciones).
  De los departamentos de Torre Velaria: `viento.gd` (el ventanal roto de Marketing y Dirección: arrastra a Johnny y tira a
  los zombis por la ventana, que cuentan sin cuerpo ni botín: `partida.gd`, meta `"ventana"`), `camaras.gd` (Informática y
  Seguridad: la alarma y los refuerzos, dos escoltas de Velaria; se rompen de un tiro desde `bala.gd`, `romper_en`), `gas.gd` y `valvula.gd`
  (Recursos Humanos: duerme a los zombis y los despierta frenéticos, `zombi.gd` `gasear`; a Johnny no le hace nada).
  Pruebas: `--captura --edificio torre --viento`, `--camaras` y `--gas`.
  Y `laboratorio.gd`, la planta 40 de la torre (`planta.gd`, `laboratorio`, en lugar de la azotea; suelo y pared
  `laboratorio`): la cabina blindada de la presidenta (dibujada con código, con `presidenta.png` dentro, de
  `py tools/presidenta_hoja.py`), las 6 cápsulas (muebles `capsule`/`capsuleopen`), las mesas (`labbench`), los láseres, el gas
  (a los zombis los pone frenéticos al momento) y la puerta del helipuerto, que se abre al caer el jefe (`partida.gd`,
  `fin_del_edificio`: no baja el helicóptero). La partida le pasa el jefe (`mapa.laboratorio.jefe`); a media vida, o con
  `romper_cabina()`, la cabina se rompe y queda en automático. Prueba: `--captura --edificio torre --laboratorio`.
  El jefe de la planta 40 es `sujeto_1.gd` (el Sujeto 1, extends `Minijefe`; números en sus `const`): anda hacia Johnny,
  rueda de lado cuando le van a dar (la bala le pregunta, `esquivar_bala()` en `bala.gd`: 1 de cada 3, como mucho cada 2,5 s),
  fregonazo en abanico (`Aviso.golpe`) y cubos de agua en curva (`proyectil.gd` "cubo", con su anillo; dejan el charco
  "agua_cubo" de `charco.gd`, que resbala 6 s). A media vida se parte (`partir()`): llama a `romper_cabina()`, saca dos mitades
  (la misma escena con `mitad = true`, más pequeñas y rápidas) y él se queda de **mando** invisible, fuera del grupo
  "zombis": su vida es la suma de las dos (la barra) y cae cuando caen las dos, así `partida.gd` y `laboratorio.gd` lo tratan
  como a cualquier jefe. Al caer una, la otra se enfada (`enfadar()`). Prueba: `--captura --edificio torre --jefe sujeto_1
  --sujeto`.
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
  ascensor, dinero, soltar objetos y munición, pausa, fin). Cada planta, más dura (M72, en `meter_zombi`): los jefes de
  planta, `JEFE_POR_PLANTA` (×1,35) de vida por planta, y los demás zombis, `ZOMBI_POR_PLANTA` (+10 %) de vida y de
  zarpazo por planta (el guardia, solo el zarpazo: su vida ya sube en `poner_guardia`); prueba `--dificultad`, que da
  los números de cada planta y los de antes. Desde la planta baja, además, zarpazos más fuertes (el `dano` de cada
  escena de zombi: normal y lento 12, rápido 10, dependienta 8, vigilante y guardia 15) y menos respiro tras un golpe
  (`johnny.INVULNERABLE`, 0,7 s). Tras una derrota (M31: `pesadilla` en el guardado), la
  partida siguiente empieza con `despertar`: sale de negro, Johnny tumbado en la sala de mantenimiento se levanta
  (`johnny.despertar`, con los dibujos del tropezón) y dice una de `FRASES_DESPERTAR`; prueba `--despertar`. Salir de un sitio no lo reinicia: `montar` hace su mapa solo
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
- `edificios.gd`: la ficha de cada edificio (apartamentos, centro y torre), `MINIJEFES` y el sorteo de qué jefe va en cada planta
  (`orden_jefes`, `jefe_de()`).
- `alerta.gd` (niveles de alerta), `eventos.gd` (eventos sorpresa: apagón, incendio y horda; en el incendio, los aspersores dejan charcos y en 4 de ellos (2 en los sitios pequeños) cae un cable pelado que electrocuta sin parar, con los rayos siempre a la vista y un calambrazo cada 0,5 s a quien lo pise, `Cable`, se prueba con `--evento incendio`; la horda no empieza hasta que Johnny llega al medio del pasillo y, a los 2 s del cartel, sale toda de golpe por los dos extremos, `soltar`; se prueba con `--evento horda`), `reto.gd` (el reto del
  día; su tarjeta en «Elige edificio» dice la regla, tu marca y el premio de hoy, `texto_tarjeta`; se juega una vez al día: el intento se gasta al empezar y el botón sale apagado hasta mañana, `jugado`) y `joyeria.gd` (la cámara acorazada y su premio). Los engancha `partida.gd` (`preparar`, `al_montar`, `recoger`).
- `skins.gd`: las skins de Johnny (`LISTA`, sus ventajas, `de_jefe()`, `siguiente()` para la Z, `hoja()`): el portero, el
  glotón, el gymbro, el bombero, el doctor Salas (M36: `doble()`, un objeto de más la mitad de las veces que un zombi
  suelta uno, en `partida.gd`; se consigue matando al doctor Salas), el cocinero (M90: `cura()`, las vendas y los
  botiquines curan un 50 % más, en `partida.cura_de`), el antidisturbios (M90: `aguante()`, tras un golpe 1,2 s sin
  recibir otro en vez de 0,7, y `firme()`, nada le tira al suelo; en `johnny.gd`: `recibir_dano`, `pisar` y `caer`) y
  la modista (M90: `camuflaje()`, los zombis dormidos no se despiertan porque Johnny entre en su habitación y le ven a
  la mitad de distancia; en `zombi.vigilar` y en `zombi_guardia.gd`), la mascota (M90: `rapidez()`, anda un 15 % más
  rápido; en `johnny.gd`, al andar) y el gerente (M90: `comision()`, la mitad de los billetes valen $2; en
  `partida.valor_billete`). Y las cinco de Torre Velaria (parte 9): la directora (`despido()`, «Despido»: el primer golpe
  a un zombi dormido, o dormido por el gas, lo mata; en `zombi.recibir_golpe`, que mira la skin con `puesta_en()`), el
  informático (`invisible()`, las cámaras no le ven, en `peligros/camaras.ve`; y `linterna()`, la linterna llega un 50 %
  más lejos, en `luz/luz.gd`, `_process`), el presentador (`municion()`, las cajas de munición dan un 30 % más, en
  `johnny.sumar_municion`), el becario (`copia()`, «Copia de seguridad»: una vez por partida, al caer, se levanta con
  25 de vida; en `johnny.recibir_dano`, después del desfibrilador, con `copia_usada`, que va en la partida guardada) y el
  Sujeto 1 (`mutacion()`, empieza cada partida eligiendo una mutación: `partida.mutacion_al_empezar`). En la taquilla
  (`ui/taquilla.gd`) ya no caben todas: la lista se desliza (`ALTO_LISTA`).
- `objetos.gd`: los objetos (gasolina, bidón de ácido, batería y vendas), los de curar (`USABLES`: las vendas, 25, y el
  botiquín, 40 (M72: antes 50), que además devuelve un tercio de vida perdido, `johnny.devolver_tercio`; van como las demás cosas de
  la mochila y del baúl, con su `TOPE` en la mochila: 2 y 3, pero en su grupo «Curas» (`CURAS`, 4 casillas, M67: `casillas` las
  pone al final y `ocupadas` cuenta solo las de «Objetos»); se usan con la tecla 1 y la 2,
  `partida.usar_cura`, con casillas junto a la barra de vida en `ui/hud.gd` y botones en `ui/tactil.gd`; el botiquín y las
  vendas los sueltan los armaritos de los baños, contando por toda la planta un botiquín y dos de vendas (`Planta.ARMARITO_CADA`; M72: antes, uno y uno por piso), `partida.abrir_armarito`, y el botiquín lo prepara la Farmacéutica), qué sale en
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
  En el ordenador, las tres ramas a la vez (`arbol_talentos.gd`, ver más abajo). Se prueba con `--quimico`. Desde el 6 nov
  cada punto se compra en su talento con los dólares ahorrados (`Talentos.PRECIOS`, por fila del árbol: 5, 10, 15, 20
  y 25 $; `Talentos.precio` y `subir`), y lo gastado se apunta en `dolares_talentos` del guardado; ya no hay puntos de
  talento que comprar (los que tenían los guardados viejos sin gastar, `guardado.gd` los cambia por dólares a 10 $).
  «Resetear talentos» (M32): quita todos los puntos, gratis pero sin devolver lo gastado (desde el 6 nov; antes devolvía
  todo menos 20 $), con una ventanita que pregunta «¿Seguro?» (`Talentos.resetear`, `ordenador.resetear_talentos`, `preguntar_reseteo`, `aviso`); se prueba con
  `--comprar-talentos`. Revisión de
  Militar y Superviviente (M15): Durito llega a 3 (`guardado.gd` devuelve en dólares los puntos que sobren si un talento
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
  la partida, `Planta.semilla`, va en la foto; se borra al acabar la partida. Una foto de antes de la M67 con más de 4
  arrojables de repuesto: los que sobran pasan al baúl al continuar, `sobrantes_al_baul`)
- `guardado.gd` (el guardado; al cargar quita lo que ya no está en el juego; el baúl son `baul`, los objetos, y
  `baul_equipo`, las armas y los arrojables con su calidad; los arrojables, juntos hasta 99 por casilla. Tres huecos
  (M45): el progreso de cada uno en `guardado.json` (el 1, el de siempre), `guardado-2.json` y `guardado-3.json`; los
  ajustes de Opciones, de los tres, en `guardado-ajustes.json` con el hueco en uso. `base` es el nombre sin `.json`
  (la prueba usa `usar("user://guardado-prueba")`), `elegir_hueco`, `hueco_usado`, `borrar_hueco`), `huecos.gd`
  (`Huecos`, la pantalla «Elige partida» del menú: una tarjeta por hueco con su resumen o «Vacía», y «Borrar partida»
  con confirmación; elegir uno monta el menú otra vez; se prueba con `--huecos`), `logros.gd` (40 desde el M17, 28 oct, y 42 con los dos de la torre, 5 nov; uno =
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
  textos se ven con `--historia`, y los relatos con `--relato`; los de Torre Velaria, solos, con `--historia-torre`. En la
  torre las páginas dicen su planta como «vestíbulo» o «planta 10» (`donde(p, edificio)`) y la última la suelta el Sujeto 1
  en el «laboratorio») y `bestiario.gd` (sus fichas;
  `recorte` lo calcula `tools/recortes_bestiario.py`).
- `tutoriales.gd`: los tutoriales (`LISTA`: grupo, título, icono, cuándo sale y sus líneas, con las teclas entre
  llaves, que salen las del jugador, las del mando o los botones del móvil: `texto()`, `tecla()`), los vistos
  (`Guardado` → `tutoriales`; `toca`, `apuntar`, `olvidar`) y el ajuste de Ayudas. Cada uno sale una sola vez: los
  pide `partida.tutorial(id)` (la mayoría, en `mirar_tutoriales`; el ordenador, la taquilla, el banco, el baúl y la
  mutación sacan el suyo antes de abrirse; las vendas sacan «curas» y el botiquín, «botiquin», el suyo aparte
  y fuera de la guía, que solo enseña las vendas: M62), `eventos.gd`, `supervivientes.gd` y el menú (el de la alerta). Se prueba
  con `--tutorial`.
- `guia.gd`: el tutorial disimulado de la primera partida (la planta baja de los Apartamentos, con los tutoriales
  encendidos): en vez de las ventanas de `CUBRE`, pistas encima de Johnny con la tecla en amarillo (`PISTAS`: moverse,
  esquivar, atacar, sacar la pistola, recargar, curarse, lanzar y el jefe), la casilla del HUD que late (`hud.latido`),
  una flecha en el suelo hacia la puerta que toca, una llavecita sobre el zombi de la llave y un primer apartamento
  fácil (3 zombis, sin la llave, vendas en el armarito). Lo enseñado se apunta como visto nada más salir la pista, se
  haga o no: tras morir en la primera partida, la siguiente no repite con ventanas lo que ya salió (solo sacará lo que
  la guía no llegó a enseñar). Sale en la partida 1 o si se pidió con «Que vuelvan a salir todos» (`Tutoriales.olvidar`
  apunta `guia_otra_vez`). Se prueba con `--guiado` y, con un jugador que no hace caso, `--guiado --sin-hacer`. La
  ventana de los tercios sí sale con la guía, al perder el primero (M35; `--guiado --tercios`).
- `supervivientes.gd` (el encerrado en su baño, la horda, los vecinos; la horda dura 1 minuto de cerradura con unos 150 zombis en grupos cada vez más seguidos y por tramos de 20 s, `HORDA` y `TIPOS`, M40) y `aliado.gd` (cada superviviente que te
  acompaña; sus hojas, en `HOJAS`; sus disparos despiertan a los zombis dormidos, como los de Johnny, M43, `--oido-aliados`; en la horda, delante de la puerta, trastea en la cerradura: echado hacia ella, a empujones, con chispitas que lucen a oscuras y un clic, `trastear`, M63). Los rescates propios: `escolta.gd` (farmacéutica), `averia.gd` (técnico),
  `barricada.gd` (ferretero) y `copia.gd` (el informático joven de la torre, id `programador`: protegerle 60 s mientras
  copia los archivos, con las cámaras saltando; su precio de empleado, `Supervivientes.precio`, y lo de acompañar:
  `abre_codigo` y `informatico_cerca`, que ciega las cámaras; `--edificio torre --programador`) y `valvulas.gd` (la
  limpiadora de noche, id `limpiadora`: encerrada en el aseo de Recursos Humanos, que en su planta es el cuarto de la
  limpieza, `Planta.cuarto_limpieza`, con el gas dentro; hay que cerrar las tres válvulas del departamento, una por rejilla
  y para siempre (`Peligros.gas` con `tres`), con los zombis dormidos por el gas que despiertan frenéticos al cerrar una cerca
  o con un golpe, `Zombi.espabilar_gas`; ya rescatada, la fregona barre 200° en vez de 140°, `Supervivientes.FREGONA_ANCHA`;
  acompañando, friega los charcos de `Charco.FREGABLES` con su gesto, `Aliado.fregar`; `--edificio torre --limpiadora`) y
  `tornos.gd` (la recepcionista, id `recepcionista`: siempre en el vestíbulo, la planta 1, detrás del mostrador con la
  persiana bajada, `Planta.mostrador`, `Planta.mostrador_fijo` y `Tornos.Persiana`; sube al llegar Johnny; al unirse, abre
  los tornos con su tarjeta 60 s mientras entran zombis por las puertas del vestíbulo, y los tornos los frenan a 0,45,
  `Tornos.freno` desde `Zombi.ir_hacia`, con la zona amarilla en el suelo; ya rescatada, al llegar a cada planta dice dónde
  está lo que abre la sala del jefe, `Supervivientes.pista` y `avisar_pista`; acompañando, grita «¡Detrás!» si un zombi va
  a pegar a Johnny por la espalda en medio segundo, `Aliado.avisar`; `--edificio torre --recepcionista`).
- `pantalla.gd` (autoload): cómo llena la imagen la ventana (`escala_para`, sin bordes y con los píxeles exactos si se puede;
  la prueba es `--escala`) y la pantalla completa del ordenador; arranca como se dejó y la cambian F11 y Alt+Intro
  (`Tactil.pantalla_completa()` la cambia y la guarda). Se prueba con `--pantalla`. Ver `docs/ESCRITORIO.md`. En la web, pide
  al navegador que deje Esc para el juego mientras dura la pantalla completa (`QUEDARSE_ESC`, ver `docs/WEB.md`), y a cada
  mando que se enchufa le pasa `Controles.ordenar_mando` (M73).
- `formas.gd` (`Formas`): `disco`, `arco`, `poligono` y `polilinea`, lo mismo que `draw_circle`, `draw_arc`, `draw_colored_polygon` y
  `draw_polyline` pero pintado con primitivas: en la web, 200 polígonos por fotograma tardan un segundo (`docs/WEB.md`).
  Todo el juego pinta con ellas. Se prueba con `--formas` (píxel a píxel contra las de CanvasItem) y `--dibujos`.
- `sonido.gd` (autoload: efectos sintetizados y música; cada efecto cambia un poco al azar de tono y de volumen cada
  vez que suena, salvo los `"fijo"` de los menús y los avisos, y los que llevan ruido se graban en 3 versiones; se
  prueba con `--sensacion`. La música va por capas: cada canción son dos `.ogg` que suenan a la vez, la base y la que
  sube y baja, y `MOMENTOS` dice cuáles se oyen según el momento (`Sonido.musica("menu" | "horda" | "jefe" | "")`) y
  los zombis despiertos, que cuenta cada medio segundo: explorando, la batería entra con uno; en la horda, la melodía,
  con `MUCHOS` (6); con el jefe, la melodía, cuando sale. Suben en 1 s y bajan tras 5 s sin hacer falta; se prueba con
  `--musica`), `controles.gd` (las teclas cambiadas en Opciones; y `con_mando`, si se juega con el mando: lo último que se ha tocado,
  que mira `pantalla.gd` con `fijarse`, M44; y `ordenar_mando`, que en la web da el orden estándar a los mandos que el
  navegador no reconoce, para que su L2 no sea Start, M73, ver `docs/CONTROLES.md`).

**ui/**
- `hud.gd` (con la barra del escudo, M22: pegada encima de la de vida, a media altura, con su marco `barra-escudo.png`,
  sacado de `barra-vida.png` cogiendo solo algunas de sus filas para que no se deformen los remaches; mientras se ve,
  las balas y el depósito suben encima de ella; `mover_escudo`, `pintar_escudo`, `con_escudo`; se prueba con
  `--escudo`). El escudo (Acero, Blindaje, Endurecimiento: `johnny.escudo`, M23) se gasta antes que la vida: en
  `johnny.quitar_vida`, todo lo que le quitan (golpes, charcos, el ácido del Glotón) sale del escudo, ya rebajado por
  Durito, y lo que sobra del golpe que lo rompe, de la vida.
- `cuenta_atras.gd` (`CuentaAtras.dibujar`, M64): la cuenta atrás de arriba, la misma para la horda del rescate, la
  barricada, la avería y la joyería: la barra en el marco de la barra de vida (`barra-vida.png`, ×1,5), llena como la
  sangre (brillo arriba, sombra abajo) y el texto encima con contorno, sin caja; los últimos diez segundos, el número
  en grande. Cada uno le pasa su texto, sus colores y lo hecho.
- `barra_jefe.gd` (la barra de los jefes, con la de armadura), `presentacion.gd` (la entrada de cada
  jefe), `menus.gd` (pausa y fin; el cartel del final dice al caer
  quién te ha pillado, `quien_te_pilla`: el dibujo, el nombre y la frase del bestiario o el icono y el consejo de su
  peligro; lo conseguido en la partida, que saca `partida.conseguido` comparando el guardado con `al_empezar`; y «Otra vez»,
  también con la R, que no hace caso hasta pasado `ESPERA_FIN`; se prueba con `--derrota`), `menu_principal.gd` (menú y «Elige edificio»; en la web, «Salir» no puede cerrar la pestaña y abre una despedida, M46, `--despedida`; al lado de Tutorial y Opciones, el hueco en uso, «Partida 1», que abre `huecos.gd`; si se cambia el idioma en Opciones, se
  monta otra vez), `opciones.gd` (con el botón de idioma; al cambiarlo se rehace entera, `reconstruir`; en General, el botón «Avisar de un texto mal traducido» a continuación de los idiomas (`enlace_avisos`, el formulario de Google del dueño; vacío no sale,
  y en español tampoco; se prueba con `--idioma`), el temblor de
  pantalla (`TEMBLORES`) y, en el móvil, todo dentro de una caja con barra porque no cabe; la pestaña Créditos, con `AUTORES` y
  `LETRAS_DE_OTROS`, y sus licencias, `texto_de_licencias`: las de esas letras y las de Godot y sus piezas), `tactil.gd`
  (controles del móvil), `tema.gd` (aspecto; a la letra normal le faltan `·` `×` `<` `>` `…` `—`: los saca de Jersey 25, su
  respaldo), `ambiente.gd` (viñeteado, poca vida, escarcha), `botones.gd`
  (autoload: el saltito de los botones), `tele.gd` (la tele de las noticias: el mueble, la calle de detrás (la del 14, la del centro o la de la torre, según el
  `sitio` de la noticia) y la reportera son dibujos de PixelLab de `assets/ui/tele/`; la boca al hablar y el parpadeo, a mano. Lo que dice la reportera va con letras de 32 (M75) y por
  trozos, los que caben en el cuadro (`partir`, que mide con el mismo texto; en chino, letra a letra): al pulsar, el siguiente).
- `arbol_talentos.gd`: el árbol de talentos de ConserjeOS (TALENTOS.EXE), desde el 6 nov. Una chapa oscura con las tres
  ramas a la vez, cada una de su color (`COLORES`: Militar rojo, Superviviente verde, Químico amarillo), dibujada con
  código (`_draw`): cada talento es un hexágono con su icono y sus cuadraditos, y las rayas al que pide se encienden al
  llenarlo. Encima de cada hexágono, un botón transparente `b_<id>`. La ficha (qué hace, ahora y con otro, qué abre y
  el pie con el precio) sale al lado del que está bajo el ratón o, con el teclado, el mando o el dedo, del marcado
  (`quien`, `modo`); con el dedo, el primer toque solo la enseña y el segundo compra (`al_pulsar`, `listo`). Las flechas
  van de hexágono en hexágono sin escaparse al escritorio (`poner_vecinos`). Prueba: `--arbol-talentos`. La chapa, sus
  colores y el marcador de lo ahorrado los comparte con la tienda de armas: están en `chapa.gd`.
- `chapa.gd`: lo que comparten el árbol de talentos y la tienda de armas: los colores de la chapa oscura (`BORDE`,
  `CHAPA`, `REMACHE`, `TEXTO`, `AMARILLO`...), `dibujar` (el marco con sus remaches) y `dibujar_ahorrado` (el billete y
  la pantallita de caja registradora, con cada cifra sobre un «8» apagado; `caja_ahorrado` dice dónde acaba).
- `tienda_armas.gd`: la tienda de armas de ConserjeOS (ARMAS.EXE), desde el 6 nov. Todo a la vez, sin desplazarse: a la
  izquierda, una fila por grupo (`GRUPOS`: Cuerpo a cuerpo, A distancia y Especiales, de `Armas.familia`, y Arrojables,
  de `Lanzables.PRECIOS`) con sus casillas (el icono, sin precio: sale en la ficha; lo que llevas con el borde verde y lo lleno, además, con «LLENO», apagada si no llega:
  `estado`). A la derecha, la ficha fija de lo elegido: el dibujo ×3, los medidores de 10 cuadraditos (`medidas`,
  `valor`; cada uno contra el arma de la tienda que más tiene de eso, `maximos`), qué hace (`INVENTARIO.QUE_HACE`), sus
  números (`ordenador.resumen_corto`) y el botón «Comprar» (`b_comprar`, sin foco: compra lo de la ficha; si ya la llevas dice «Comprada»). Sin nada
  elegido (al abrir con el ratón), la ficha explica la tienda (`nota`: la calidad Normal, el baúl y lo de
  esta partida). Lo elegido es, con el ratón, la última casilla por la que pasó (se queda al ir hacia «Comprar»); con
  el teclado, el mando o el dedo, la marcada (`quien`); tras comprar se rehace con lo comprado elegido. Con el dedo, el
  primer toque enseña y el segundo compra (`al_pulsar`, `listo`). Los textos largos se parten a mano (`partir`; en
  chino, letra a letra). Prueba: `--tienda-armas` (con fotos en alemán, ruso y chino). Las armas que tienen sus
  dibujos de la tienda (`assets/ui/tienda/<id>.png`, 48 en diagonal, para la casilla, y `<id>-grande.png`, 96x48 en
  horizontal, para la ficha a ×2; `dibujo_tienda`, de PixelLab: `assets/pixellab.json` → `tienda-dibujos`) los usan; las
  demás, el icono de siempre.
- `archivador_logros.gd`: los logros de ConserjeOS (LOGROS.EXE), desde el 7 nov. La misma chapa oscura, como un
  archivador: arriba, lo ahorrado y, a la derecha, «Logros 10/42» y «Por cobrar $X». A la izquierda, un botón por página
  (`b_tema_<tema>`): «Resumen» y uno por apartado de `Logros.TEMAS`, con su barrita, su cuenta y un «!» si tiene algo por
  cobrar; las barras, en amarillo mientras falta y en verde al completarlas. A la derecha, la página (`pagina`, que se queda al rehacer la ventana):
  el Resumen enseña lo que hay por cobrar (los que no caben, «Y N más»; si no hay nada, «Casi lo tienes»: los que se
  hacen varias veces y van más avanzados) y «Cómo vas», una barra con todos y una por apartado; un apartado, sus logros
  en filas (`b_<id>`: icono, nombre, su barra si `meta` > 1, lo que pide cortado con «...» y la placa del premio: apagada,
  amarilla «Cobrar $X» o verde «Hecho»). Pulsar una fila cobra (`ordenador.cobrar_logro`); lo que pide, entero, sale en la
  línea de abajo. `programa_logros` lo monta, le pone a cada botón su línea de abajo y decide qué se marca. Prueba:
  `--archivador-logros`.
- `carpeta_dosier.gd`: el Dosier de ConserjeOS (DOSIER.TXT), desde el 7 nov. La ventana va maximizada (tapa los iconos)
  y, encima de la chapa oscura, una carpeta de archivo marrón con una pestaña por edificio (`b_edificio_<id>`, «Apartamentos
  2/5»). A la izquierda, las páginas del edificio como fichas (`b_<id>`: en papel las
  encontradas, con «Página N» y su título; arrancadas las que faltan, solo con «Página N»); a la derecha, la hoja de la que se mira,
  con un clip (cambia al pasar por una ficha, `ver`). El edificio y la página se quedan al rehacer la ventana
  (`recordado`, `recordada`). Sin desplazarse. `programa_dosier` lo monta y le pone a cada botón su línea de abajo (quién
  la llevaba o dónde buscarla). Prueba: `--dosier-carpeta` (también si cabe cada hoja, en alemán, ruso y chino).
- `hoja_dosier.gd`: una página del dosier dibujada como expediente de Velaria Corp. (`Historia.hoja()` y
  `hoja_arrancada()`; la usan la ventanita de página encontrada, `menus.pagina`, y la carpeta). Papel viejo con motitas y
  un cerco de café; el logo de Velaria (`assets/ui/velaria-logo.png`, 24x24, de `tools/logo_velaria.py`, sacado de la imagen de GPT: una luna creciente
  morada en un círculo azul marino; lo eligió el dueño el 7 nov y es el logo de Velaria para todo), «Investigación del sueño», código de
  barras y referencia (`VD7-AP-01`: edificio y número); la franja con el edificio, «HALLADO EN» y n / total; el tipo, el
  título, el sello de «CONFIDENCIAL»; el texto a todo lo ancho (la foto del muerto se quitó el 7 nov) y la nota en un
  pósit (amarillo, con la esquina doblada, pequeño y casi cuadrado: las notas son cortas; la nota, letra a letra como escrita a mano con boli, `a_mano_en`, siempre a 16), pegado abajo a la derecha; las últimas líneas del texto se estrechan para dejarle sitio. Mide de alto lo que necesita: si pasa de `alto_max`, prueba con la letra más pequeña y la
  cabecera compacta (`PRUEBAS`); nunca corta texto. La arrancada es el trozo de arriba, roto, con `Historia.falta()`.
- `ordenador.gd`: ConserjeOS (talentos, tienda de armas, logros, Dosier, Noticias, Colecciones). Al comprar o subir algo
  el programa se rehace entero: `marcar` deja cada desplazamiento en su sitio sin que se note (arriba, al abrirlo; se
  prueba con `--ordenador-arriba`, con clics de verdad). Con el teclado o el mando, Godot solo pasa a un botón que se
  vea: `encadenar` le dice a cada botón de una lista con desplazamiento cuál tiene encima y debajo (`--ordenador-teclado`). La tienda es
  `tienda_armas.gd` (`programa_armas` la monta y le pone a cada casilla su línea de abajo); los arrojables se compran de
  uno en uno con `comprar_lanzable`, mientras quepan. Con dos armas de ese tipo, `comprar_arma` manda la de repuesto al baúl (`partida.repuesto_al_baul`) antes de `llevar_arma`, solo en la tienda. Cada programa se abre con sus desplazamientos arriba (`marcar()`: marca el botón y, pasado un fotograma, ya colocado todo, deja cada desplazamiento en su sitio; al volver a abrir el mismo tras comprar o subir algo, donde estaban). Se prueba con `--ordenador-arriba`. Los iconos con algo nuevo (`MESA.novedades`: Noticias, Colecciones y Logros por cobrar)
  llevan el rótulo en amarillo y un «!» que bota en la esquina (`marca_nuevo`); se ponen y se quitan con `poner_aviso`, y
  `refrescar_avisos()` los pone al día con el guardado al abrir Colecciones, ver una noticia o cobrar un logro, sin tener
  que apagar (y al apagar también se pone al día el «!» de la mesa). Y los avisos de sucesos, además de la
  línea de abajo (`partida.decir`), dan un grito grande encima de Johnny como el de la llave (`partida.gran_aviso`: noticias
  nuevas, logro y skin nueva); la skin sin ver se apunta en `skins_nuevo` del guardado hasta que se abre la taquilla.
  Se prueba con `--novedades` y `--avisos-ordenador` (que se quitan al mirar o cobrar).
- `inventario.gd`: el inventario «todo a la vista» (en medio, la mochila y la munición, 8 y 8, y abajo dos grupos de 4: los
  arrojables de repuesto y las curas, `cuadro`; las curas siguen siendo casillas "m" de la mochila, las últimas), el baúl (`pintar_baul`, `cosas_baul`: objetos, armas y
  arrojables; `guardar_equipo`, `sacar_equipo`), el banco de trabajo (`pintar_banco`, `en_banco`, `no_mejora`,
  `mejorar`: sube un nivel un arma o un paquete, de lo que lleva o del baúl, con las piezas de la mochila y del baúl)
  y arrastrar con ratón o dedo (`levantar`, `destinos`, `soltar_en`). `taquilla.gd`: la ventanita de las skins.
- `raton.gd`: el ratón durante la partida: escondido jugando en el modo asistido (salvo apuntando un lanzable), la
  mirilla (dibujada en el código, `MIRILLA`) en el libre y la flecha con un menú abierto. Prueba: `--captura --raton`.
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
  habitación de los pisos de los Apartamentos: los que quepan, lejos de la
  puerta (`LEJOS_PUERTA`), de los muebles y de los otros. Sin esos 2 había unos 13 por piso; con ellos, unos 27. La prueba
  `--zombis-sala` los cuenta por habitación. En las tiendas del centro comercial, `EXTRA_TIENDA` (M84): 14 de más en la
  sala de venta, 1 en los baños y 3 en las demás salas; de unos 9 por tienda a unos 27. Los cuenta `--zombis-tienda`.
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
  puerta abajo), y la habitación de cada jefe; `tienda.gd` da cada tienda: desde la M77, todas fijas, dibujadas con letras en `Tienda.PLANOS` (la electrónica, con su
  charco: `~`; todas con su aseo de empleados y su botiquín, M81), leídas con `Apartamento.del_plano` y con sus muebles puestos a mano
  (`colocados` de `<sala>-<tipo>` en `catalogo.gd`, `Muebles.de_tienda`; se miran con `--tiendas-fijas`); la galería, igual
  (`colocados` de `"galeria"`, se mira con `--galeria`). Los departamentos de Torre Velaria (el tercer edificio,
  `docs/PLAN_TERCER_EDIFICIO.md`) también son tipos de `Tienda.TIPOS`, con `"edificio": "torre"`: toman el plano de una
  tienda del centro (`"presta"`, `Tienda.plano_de`), pero con muebles propios (`colocados` de `<sala>-<tipo>`, puestos con
  `py tools/muebles_torre.py` a partir de los de esa tienda), suelos y paredes propios (`Mapa.ESTILO_TIENDA`) y su rótulo
  iluminado en vez del neón (`neon.gd`, `iluminado`); su pasillo es el de `Catalogo.SALAS["torre"]` y el vestíbulo, el de
  `"vestibulo"` (`Planta.generar`, `estilo_pasillo`), con el ventanal de la ciudad de noche (`ventanal.gd`) en vez de
  escaparates y el cartel de la planta (0, 10...40) dibujado en `puerta.gd` (`cartel_torre`); se miran con
  `--edificio torre --torre` y `--edificio torre --departamentos` (`--tipo X`);
  `viviendas.gd`, el pasillo de los rescatados (nueve habitaciones: las de la torre, `TORRE`, la cuarta de arriba, la
  cuarta de abajo y la del fondo, con su puerta de lado; las de quien aún no está en `Supervivientes.DATOS`, cerradas). Se ve como una casa por dentro desde arriba ("cajas" en el sitio): cada
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
  tablas siguen con la hoja vista desde arriba. Dentro de una abierta (`zombi.en_puerta`, en su `arrimo`) los zombis pasan
  apretados: sin esquivarse ni chocar entre ellos (`zombi.pedir_velocidad`), y el venenoso y el de tentáculos no se
  plantan ahí a atacar, para no taponarla. Se prueba con `--puertas` y, con un grupo de cada tipo, `--atasco-puertas`.
- `puerta.gd` (las salidas) y `cartel_salida.gd`: las de la pared de arriba se ven de frente; las de la de abajo, que se ve por detrás,
  son el hueco en el muro con la hoja vista desde arriba (`puerta-abajo.png`). La salida de incendios es la puerta de las escaleras, al fondo del
  pasillo, en el muro de la derecha. Se abre cuando cae el jefe de la planta (`jefa_muerta` en `partida.gd`, que llama a
  `actualizar_puertas`). Vista desde arriba, es una hoja de chapa roja fina metida en el hueco, con su barra antipánico
  de aluminio sobresaliendo hacia el pasillo y las escaleras detrás (`puerta-salida.png`, 36 × 36). Encima, en la pared de
  arriba, un cartel EXIT (`cartel-salida-apagado.png` / `-encendido.png`, 36 × 13) que `mapa.gd` crea junto a la puerta y
  que la puerta enciende (`abierta`): apagado es verde oscuro y sin luz; al caer el jefe arranca con unos parpadeos y se
  queda verde vivo, sin que le afecte la penumbra, con halo y una luz verde de verdad (la de `lampara.gd`); si Johnny
  vuelve a una planta ya pasada, nace encendido. Dibujados a mano con `py tools/puerta_salida.py` (a esa anchura PixelLab
  no dibuja). Se prueba con `--salida`.
- `cara_pared.gd`, `neon.gd` (el letrero de neón de las tiendas y el rótulo iluminado de los departamentos de la torre), `ventanal.gd` (el ventanal con la ciudad de noche del pasillo de la torre); `ordenador.gd` (la mesa; `novedades(s)` dice qué programas tienen algo nuevo), `arrimable.gd`, `zona_usar.gd` (la zona de delante de esos muebles: con Johnny en ella, se abren con atacar; `johnny.ante_mueble` hace que ese clic no dispare),
  `exclamacion.gd` (el «!» que bota encima de la mesa del ordenador y de la taquilla mientras haya algo nuevo; se
  pone con una `condicion` y se mira cada segundo)
  (baúl, banco, taquilla), `armarito.gd`, `cientifico.gd` (el muerto con su página), `terminal.gd` (los ordenadores con
  las tres cifras del código de la sala del jefe en Torre Velaria: `Planta.codigo` y `partida.poner_terminales`),
  `valla.gd` (la del helipuerto de la azotea).

**luz/**: `luz.gd` (penumbra de cada sitio, luz de Johnny, fogonazos), `lampara.gd`, `fuego.gd`.

**pruebas/**: lo que solo se usa con `--captura`.
- `captura.gd` (clase `Captura`): `activa()`, `dato("--jefe", "antidisturbios")` y `foto("captura-x.png")` (la guarda en `capturas/`, que lleva un `.gdignore` para que Godot no la importe).
  Y el seguro de las pruebas: el menú pasa a la partida con `Captura.ir_a_la_partida()`, que antes de abrir la de prueba
  mira que compile (si no, `diagnosticar()` carga uno a uno los archivos de `scripts/pruebas/` para que cada uno cuente su
  error y su línea) y, si no, cierra con el código 2; y `vigilar()` (puesto por el menú con `--captura`, salvo en el trailer)
  cierra con el código 1 al primer error de script a mitad de una prueba, y con su reloj, si la prueba se cuelga sin error
  (150 s; la larga, 900; `--limite N` lo cambia), diciendo si el juego estaba en pausa (una página del dosier o el relato
  paran los `create_timer(s, false)`: en la prueba, esperar ahí con `create_timer(s, true)`). En los dos casos dice
  `ERROR DE LA PRUEBA: …` en la terminal: nunca más una prueba en negro que no acaba.
- La partida de prueba va en una cadena de archivos por tema, cada uno hereda del anterior: `prueba_comun.gd` (hereda
  de `partida.gd`) → `prueba_jefes_salas.gd` → `prueba_jefes.gd` → `prueba_armas.gd` → `prueba_skins.gd` →
  `prueba_inventario.gd` → `prueba_fotos.gd` → `prueba_sitios.gd` → `prueba_reglas.gd` → `prueba_larga.gd` →
  `partida_prueba.gd`, el último, que los tiene todos. Al principio de `partida_prueba.gd` está la lista de opciones
  (`--jefe`, `--armas`, `--inventario`...) con el archivo de cada una.
- `prueba_idioma.gd` (`PruebaIdioma`, fuera de la cadena: la lanza el menú con `--idioma`): el menú, Opciones y «Elige
  edificio» en el idioma de la prueba y el cambio de idioma en caliente. `--ingles` pone cualquier prueba en inglés.
- `prueba_huecos.gd` (`PruebaHuecos`, fuera de la cadena: la lanza el menú con `--huecos`): con sus propios archivos,
  el guardado viejo pasa al hueco 1, cambiar de hueco no cambia los ajustes, la pantalla «Elige partida» y borrar un hueco.
- `prueba_mando.gd` (`PruebaMando`, fuera de la cadena: la lanza el menú con `--mando`): A y B del mando en el menú
  principal (JUGAR, «Elige edificio», Opciones, Tutorial) y los botones de mando de mentira que usa también
  `probar_mando()` de `prueba_varias.gd` (la pausa, Opciones, un tutorial, el inventario, la taquilla, el ordenador, una
  página, el panel de pruebas y el cartel del final). También `mando_web` (`--mandoweb`, la lanza `partida_prueba.gd`, solo
  en la web): enchufa desde el navegador un mando de mentira sin orden estándar y otro con él, y mira que el L2 lance sin
  abrir la pausa (M73).

## assets/

- `sprites/`: las hojas (`.png` + `.json`) y sus animaciones (`.tres`). Hoja nueva →
  `py tools/hacer_frames.py assets/sprites/<nombre>`.
- `musica/`: «El último inquilino» (menús y explorar: `el-ultimo-inquilino-base.ogg` y `-bateria.ogg`) y «Turno de
  noche» (hordas y jefes: `turno-de-noche-base.ogg` y `-melodia.ogg`), las capas que suenan a la vez (`CANCIONES` y
  `MOMENTOS` de `sonido.gd`). En el ordenador cada canción empieza en un compás al azar; en la web, siempre al principio
  (ver `docs/WEB.md`).
- `ui/` (HUD, menús e iconos; `ui/tutorial/`, las fotos de las fichas de los tutoriales), `fuentes/` (la de siempre, nítida a 16 y 32, y `jersey-25.ttf` de los jefes, nítida a
  25 y 50, que va siempre con su licencia `jersey-25-OFL.txt`), `tiles/`, `pruebas/` (montajes para revisar dibujos).
- `sources/`: originales (con `.gdignore`). `pixellab.json`: todo lo generado en PixelLab (no va en el juego exportado: solo lo
  usan las herramientas).
- Los dibujos se importan **sin relleno en lo transparente** (`fix_alpha_border=false`, también por defecto para los nuevos, en
  `[importer_defaults]` de `project.godot`) y con la compresión WebP sin pérdida al máximo (`rendering/textures/webp_compression`):
  se ven idénticos y pesan un tercio menos (M47, ver «Lo que pesa la web» en `docs/WEB.md`).
- `web/carga.html`: la página de la web, con su pantalla de carga (ver `docs/WEB.md`).

## tools/

- **El trailer:** `trailer.py` lo graba con el Movie Maker de Godot y lo monta con ffmpeg (ver `docs/TRAILER.md`).
- **Lo dibujado en otro idioma:** `cartel_planta_idiomas.py` hace los carteles de planta con la palabra de cada idioma («FLOOR»,
  «ANDAR», «ETAGE»: `cartel-planta-N-<idioma>.png`) y `fotos_tutorial.py <idioma>` recorta las fotos de los tutoriales de las
  capturas sacadas con `--lang <idioma>` (`assets/ui/tutorial/<idioma>/`).
- **El número de la planta, gastado:** los carteles limpios están en `assets/sources/cartel/limpios/` (ahí escriben `guias_cartel.py sprites`
  y `cartel_planta_idiomas.py`) y `cartel_roto.py` saca de ellos los del juego (`assets/sprites/cartel-planta-*.png`), con la pintura
  pelada, un desconchón y grietas. Si se toca un cartel, hay que pasarlo otra vez; la palabra se protege para que se lea.
- **Las puertas sucias:** `puertas_sucias.py` saca de cada puerta de madera limpia su copia `-sucia.png`, con mugre, arañazos, huellas de
  manos y sangre (lo que lleva cada una, a mano en `RECETAS`). Las de piso y las de dentro de frente son tres dibujos, para que no sean todas
  iguales. Las limpias se quedan para las zonas seguras (`ZONAS_SEGURAS` en `mapa.gd`). Si se regenera una puerta, hay que pasarlo otra vez.
- **La puerta de la pared de abajo:** `puerta_abajo.py` hace `puerta-abajo.png`, el hueco en el muro con su marco y la hoja vista desde arriba
  (esa pared se ve por detrás), en tres modelos: madera sucia, madera limpia y cristal del centro comercial; la pinta `puerta.gd`.
- **Las placas de los pisos, rotas:** `placas_rotas.py` hace las hojas `placa-rota-pared.png` (torcidas en su sitio, las de la pared de
  arriba) y `placa-rota-suelo.png` (arrancadas y tiradas, las de la de abajo), con las letras A, B, C y D, píxel a píxel; las pinta `puerta.gd`.
- **Las traducciones:** `traducciones.py` recoge los textos del código, pone al día los `locale/*.po` y avisa de lo que falta
  o está mal (`py tools/traducciones.py`; antes de cada commit que toque textos). Ver `docs/IDIOMAS.md`.
- **La letra del juego:** `arreglar_tildes_fuente.py` pone bien las tildes (á é í ó ú y mayúsculas), el punto de la í y los ¿ ¡ de
  `assets/fuentes/zombie-scape-ui.ttf` (ver `docs/IDIOMAS.md`, «Las tildes de la letra del juego»); después, `--headless --path . --import`.
- **La sala de mantenimiento, sin sangre:** `sala_sin_sangre.py` saca las copias limpias de suelos y paredes (`suelo-vestuario`,
  `pared-vestuario`, `suelo-despacho`, `pared-despacho`: las de siempre las usan los pisos y siguen con su sangre) y
  limpia los muebles que la llevan pintada (baúl, banco, ducha, váter, estante de botes). Si se regenera un mueble, hay que pasarlo otra vez.
- **El taller de la sala de mantenimiento:** `taller_vinilo.py` saca su suelo de vinilo gris con motitas (`suelo-taller`, 128x128) y
  su pared blanca con el zócalo del mismo vinilo (`pared-taller`) de dos imágenes de GPT (`assets/sources/taller-*-gpt.webp`).
  El baúl (`baul.png`, 42x23, también el de la sala de pruebas), un arcón de plástico negro: `baul_plastico.py` lo pasa a mano píxel a
  píxel copiando el dibujo de GPT (`assets/sources/baul-plastico-gpt.webp`; reducido sin más se emborronaba). Ocupa 78x36 en el suelo.
  En las paredes de los lados del taller, debajo de sus puertas, tuberías (`boilerpipes`, las blancas de la caldera, a la izquierda;
  `firepipes`, las rojas de incendios, a la derecha, donde antes iba el carro de la limpieza): `taller_tuberias.py` las recorta de la
  imagen de GPT (`assets/sources/taller-tuberias-gpt.webp`) como originales de lado, y `importar.py` las pasa a sprite.
  La puerta del despacho al taller, metálica (`PUERTA_BANO.METAL`, la elige `mapa.poner_hojas`): `puerta_metal.py` copia la forma
  de los dibujos de lado de la de madera y la pinta a mano como la foto del dueño (`assets/sources/puerta-metal-foto.webp`): verde
  oscuro, con la manilla plateada y el bombín.
- **Efectos de pixelfx** (el plugin de efectos pixel art, MIT, `git clone https://github.com/patch-gg/pixelfx`):
  `pixelfx/exportar.mjs` saca un efecto en tres hojas para Godot (detrás del personaje, delante y el brillo, que se suma)
  y `pixelfx/escudo-fuego.js` es la burbuja de fuego del jefe de bomberos (`escudo-fuego-*.png`, en `bombero.gd`):
  `node tools/pixelfx/exportar.mjs <pixelfx> tools/pixelfx/escudo-fuego.js assets/sprites`.
  `pixelfx/reventon-veneno.js` es el reventón del gordo ("acid-splash" pasado a vista desde arriba, `reventon-veneno-*.png`):
  `node tools/pixelfx/exportar.mjs <pixelfx> tools/pixelfx/reventon-veneno.js assets/sprites`.
  `pixelfx/nube-gases.js` es la nube del Flatulento ("poison-cloud" desde arriba, `nube-gases-*.png`), igual.
  `pixelfx/escudo-cristal.js` es lo mismo en azul y más pequeño: la cúpula del científico jefe (`escudo-cristal-*.png`,
  en `cientifico_jefe.gd`; las balas rebotan en su borde igual que en la burbuja del bombero, con `colores_escudo()`).
  `pixelfx/explosion.js` y `exportar_explosion.mjs`: la explosión (`node tools/pixelfx/exportar_explosion.mjs <pixelfx>
  assets/sprites`, y copiar el origen que escribe en `ORIGEN` de `explosion.gd`). `hojas.mjs` pinta las capas que se le
  pidan ("front", y "back" para la explosión).
  `caida.py` monta la hoja del tropiezo de Johnny (`conserje-48-caida`: caer y levantarse de PixelLab, colocados para que
  no den saltos y quede tumbado en el suelo): `py tools/caida.py`. Luego `py tools/caida_skins.py` saca la de cada skin:
  busca en cada dibujo la cabeza de siempre y cuánto está girada, la borra y pega encima la de la skin girada igual
  (`cara.py` no sirve aquí: busca la cabeza derecha). Con `muestra`, `capturas/captura-caida-<skin>.png` para revisarla.
  `pixelfx/fogonazo.js` son los fogonazos ("muzzle-pistol", "muzzle-smg" y "muzzle-shotgun" partidos en llama y humo,
  sin casquillo) y `pixelfx/exportar_fogonazo.mjs` los saca girados y recortados (`fogonazo-<arma>-<parte>*.png`) y
  escribe las medidas para `TIPOS` de `fogonazo.gd`: `node tools/pixelfx/exportar_fogonazo.mjs <pixelfx> assets/sprites`.
  `pixelfx/chispa.js` es la chispa de las balas ("hit-spark" con tallas, colores y apuntando a cualquier lado) y
  `pixelfx/exportar_chispa.mjs` la saca (`chispa-bala*.png` y `chispa-perdigon*.png`) con las medidas para `chispa.gd`:
  `node tools/pixelfx/exportar_chispa.mjs <pixelfx> assets/sprites`. Los dos exportadores con variantes comparten
  `pixelfx/hojas.mjs` (dibujar cada variante, recortar y pegar en las hojas).
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
  quita el parpadeo de espaldas, que confundía el arma con unos ojos; `PYTHONPATH=tools py tools/hoja_lanza_rayos.py`),
  `bate_metal.py` (el bate de aluminio con el mango de cinta negra: busca el bate de madera en cada dibujo por su forma,
  porque comparte los colores con la piel, y lo repinta; lee `assets/sources/conserje-48-bate/hoja-madera.png`, los
  golpes que no acierta van a mano en `AJUSTES` y `py tools/bate_metal.py muestra` deja antes y después en `capturas/`) y
  `cara.py` (las skins: `py tools/cara.py <skin> [arma]`). Al final de todos, `respiracion.py`: rehace el reposo de
  todas las hojas de Johnny y sus skins (solo sube el pecho, la cabeza quieta; dos respiraciones en 6 s, con el
  parpadeo) y conserva las puntas del lanza ácido. Va después porque los otros esperan el reposo viejo de 20 dibujos:
  si se rehace una hoja con ellos, se vuelve a pasar `py tools/respiracion.py` (las que ya están hechas no las toca).
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
  `pruebas/trailer.gd`): no está dibujado a mano, lo genera `py tools/logo.py`; la pantalla de carga de la web, `assets/web/carga.html`, lleva una copia
  metida dentro: si cambia el logo, ver «La pantalla de carga» en `docs/WEB.md` (el programa de `src/titulo.js` del juego JS, pasado a
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
