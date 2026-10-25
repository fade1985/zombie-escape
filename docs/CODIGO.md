# Mapa del código

## Raíz

- `project.godot`: escena de inicio, pantalla, pixel art nítido, teclas de cada acción, capas de choque.
- `default_bus_layout.tres`: buses de audio. `export_presets.cfg` y `vercel.json`: ver `WEB.md`.

## escenas/

- `menu_principal.tscn`: la escena de inicio (`scripts/ui/menu_principal.gd`).
- `partida.tscn`: Johnny y la pantalla (sitio, avisos, fundido). El mapa lo monta `partida.gd`; el HUD,
  `ui/hud.gd`; el minimapa, `minimapa.gd`; la pausa y el final, `ui/menus.gd`.
- `partida_prueba.tscn`: la misma escena con el script de la partida de prueba (`pruebas/partida_prueba.gd`); el
  menú la abre en vez de `partida.tscn` cuando se arranca con `--captura`.
- `salas/`: la sala de pruebas de las fases 1-3 (`bano.tscn` y `bano_tileset.tres`: las piezas y cuáles chocan).
- `personajes/`: `johnny.tscn`, un `zombi_<tipo>.tscn` por tipo (sus números en el Inspector), `portera.tscn`
  y los minijefes del centro comercial (`antidisturbios.tscn`, `cocinero.tscn`, `modista.tscn`, `mascota.tscn`) y
  su jefe final, en la azotea (`gerente.tscn`); los minijefes de los Apartamentos (`docs/JEFES_APARTAMENTOS.md`):
  `gloton.tscn`, `gymbro.tscn` y `bombero.tscn`, y su jefe final, en la azotea (`cientifico_jefe.tscn`).
- `armas/`: `bala.tscn` (bala y perdigones), `bala_zombi.tscn` (agua sucia de la portera y alfileres de la modista), `proyectil.tscn`
  (moco, botella de lejía, sartén del cocinero, molotov del jefe de bomberos y probetas del científico jefe, en parábola), `charco.tscn` y `explosion.tscn`.
- `luces/`: `lampara.tscn` (luz de suelo con sombras, luz de lo demás sin sombras y bombilla), `fuego.tscn` y
  `luz_suave.tres` (el degradado de todas).
- `muebles/`: un mueble por escena, con su choque y su `Sombra`.

## scripts/

**Personajes y combate**
- `johnny.gd`: moverse, vida, apuntar y atacar. La bala sale de la boca del arma y, si la línea de tiro (desde el centro
  de Johnny) pasa por un zombi, va derecha de la boca a él (`tiro`, `blanco_en_linea`; a quemarropa, con el zombi más
  cerca que la boca, sale de Johnny); antes iba paralela a esa línea y en diagonal pasaba por el lado. Al golpear andando, `escenas/personajes/cintura.gdshader` lo parte
  por la cintura: el cuerpo da el golpe y debajo otro dibujo (`Piernas`) sigue andando. Las skins (`skins.gd`):
  `vestir(id)` le cambia las hojas por las de esa skin sin cortarle la animación (`sostener` también coge la hoja de
  la skin al cambiar de arma); al empezar se pone la del guardado. Con el portero, `arma()` multiplica por 4 el daño de
  la fregona; con el gymbro, por 3 el de todas las armas cuerpo a cuerpo (la fregona, el bate y el cuchillo), y con el
  bombero, por 3 el de las que queman (`ArmasCreadas.QUEMAN`: el lanzallamas; `quema`,
  que también multiplica lo que sigue ardiendo el zombi que prenden). Con el bombero, `ignifugo()`: `pisar()` no apunta el
  fuego de los charcos ni del suelo, y las bolas de fuego, el cono y la botella del molotov del jefe de bomberos no le
  hacen nada (`bola_fuego.gd`, `bombero.gd`, `proyectil.gd`). `recibir_dano(cantidad, quien)`: "quien" es el que le pega (el zombi o el jefe; en lo que se lanza,
  balas, pesas, cuchillos, contratos, bolas de fuego y lo de `proyectil.gd`, su `dueno`), o nada si no es de nadie
  (charcos, agua con corriente, explosiones); con el glotón, `devolver(quien)` se lo cobra: el zombi muere y el jefe
  pierde un 10 % de su vida máxima (`morder()`). `caer(segundos)`: un tropezón (las mancuernas del gimnasio
  del Gymbro, los cubos de la portera): se queda tirado sin andar, atacar ni rodar, con el dibujo tumbado y estrellitas en la cabeza, y luego
  se levanta; rodando no se tropieza. `mejoras.gd`: sus atributos (el baseStats del JS).
- `armas.gd`: los números de las armas (la pistola, desde el 24 oct, es una Beretta 92 algo más grande de lo real,
  `conserje-48-pistola`, con su `boca`; las creadas, en `Armas.CREADAS`, son todas a distancia desde el 25 oct, cuando se
  quitaron del juego las nueve de cuerpo a cuerpo y el garfio, y cada una lleva su propia `hoja`: el lanzallamas, `conserje-48-lanzallamas`, con dos bombonas rojas de combustible a la espalda, una
  manguera negra hasta el tubo y el tubo sujeto con las dos manos apuntando, con el piloto encendido (desde el 25 oct no
  dispara: echa una llamarada continua, `llamarada.gd`, y Johnny la echa en la postura quieta de la hoja, la de apuntar; la
  hoja no lleva llamarada ni disparo, y su `boca` es la punta del tubo de cada postura quieta, medida en la hoja; casilla de
  96×96 con los pies en 48,72), y el desintegrador (en el juego se llama «Lanza ácido» desde el 25 oct; por dentro
  sigue siendo `desintegrador`), `conserje-48-desintegrador`, que desde el 25 oct es la del lanzallamas con las dos bombonas de la
  espalda en verde ácido y sin la llamita del piloto (no viene de PixelLab: la saca `tools/hoja_lanza_acido.py` de la hoja del
  lanzallamas; casilla de 96×96 con los pies en 48,72, y su `boca` es la punta del tubo de cada postura quieta, medida en la hoja), y la pistola eléctrica, `conserje-48-pistola-electrica`, con un táser azul marino (una batería gris
  con un borne rojo pegada debajo del cañón, dos electrodos metálicos en la boca con una chispita celeste, y al disparar el retroceso corto y una
  descarga celeste en zigzag de 60-90 píxeles; casilla de 180×168 con los pies en `pies` 90,88; su `boca` va a mano, sacada del centro de la
  chispita de los electrodos del dibujo quieto, porque la descarga es celeste y `arma.py` no encuentra ningún fogonazo naranja; las chispas que
  vuelan, aturden y saltan al zombi de al lado las pone el juego, `armas_creadas.gd` y `chorro.gd`; la hoja lleva `efectos` y andando se pinta
  la descarga encima del andar); con sus hojas de cada skin). Andando, `johnny.gd` solo pinta los `efectos_*` del disparo si la
  hoja los tiene. `bala.gd`.
- `armas_creadas.gd`: lo que hacen las armas creadas (la descarga que aturde y salta, prender, sangrar, el ácido…);
  `chorro.gd` (gotas de fuego, chispas de la pistola eléctrica y clavos de la bomba de clavos).
- `llamarada.gd`: la llama del lanzallamas, hija de Johnny. Mientras se ataca, `johnny.gd` (`echar_fuego`) la mantiene
  encendida en cada paso y gasta el depósito (`deposito`, 8 s; sin balas: `Armas.CREADAS.lanzallamas` no tiene cargador).
  Sale de la boca, estrecha, y se abre en cono hasta 10 casillas (la cortan las paredes), 45° entre los dos bordes
  (`ABRE`, 22,5° a cada lado; igual en el lanza ácido, y los dos dibujos se abren lo mismo). Va siempre recta, sin
  doblarse, y sale por donde apunta el tubo del dibujo, medido en `Armas.CANO_LANZALLAMAS` (las diagonales, a unos
  24°, no a 45°); Johnny mira hacia la dirección cuyo tubo apunte más hacia el zombi al que apunta (`blanco_en_linea`,
  como la bala) o hacia donde apunta (`johnny.mirar_con_chorro`), y si la de antes casi vale igual, se queda en ella
  (que no baile entre dos y la llama salte de boca). Con 8 dibujos, el zombi puede caer fuera del cono (en medio de
  dos, entre la diagonal y abajo, por ejemplo): entonces `echar_fuego` gira el chorro desde el tubo hacia él lo justo
  para que entre por el borde, con 3° de margen (`MARGEN_CHORRO`), medido en la pantalla, como se ve (de la boca al
  cuerpo); si ya estaba dentro, o no hay zombi, sale recto por el tubo (25 oct). Cada 0,25 s quita a todos los
  zombis de dentro su parte del daño por segundo (el de la receta, 30 × rareza) y los prende, y cada 0,5 s los empuja.
  Solo a los zombis (al jefe de bomberos, nada). El depósito se llena entero con lo que diga su `relleno` en
  `Armas.CREADAS` (el lanzallamas, una gasolina de la mochila; el lanza ácido, un bidón de ácido): solo, al vaciarse;
  con la R, solo vacío; al coger uno del suelo, también (`johnny.coger_relleno`, desde `partida.soltar_objeto`). Sin
  ninguno sale el aviso de `Armas.RELLENOS` («¡Sin gasolina!», «¡Sin ácido!») y saca la de cuerpo a cuerpo; cuántos
  lleva lo cuenta `johnny.rellenos()` (en la sala de pruebas de armas, sin fin: `deposito_sin_fin`). En el HUD
  (`ui/hud.gd`, `pintar_deposito`), una barra en vez de las balas, del color de lo que lo llena (`COLORES_DEPOSITO`:
  naranja de gasolina o verde de ácido), con su icono y cuántos lleva. Los lanzallamas y los lanza ácido viejos del
  baúl (con el daño de una gota) cogen el de ahora y la frase de la receta al cargar el guardado (`guardado.gd`). La dibuja su shader,
  `escenas/armas/llamarada.gdshader`, sobre un rectángulo que la cubre: en cada píxel del dibujo (de 2 unidades,
  alineados con el mundo) calcula lo caliente que está con un ruido que corre hacia fuera y lo pinta a bandas con los
  colores de `Llamas.FUEGO` (blanco y amarillo junto a la boca, naranja en medio, rojo en los bordes), con los bordes en
  damero y sin humo; contra una pared se aplasta y se abre. `llamarada.gd` le pasa dónde va, suelta
  chispas (`Particulas`), lleva una luz que alumbra alrededor (más en los sitios oscuros) y, al soltar, la llama se
  despega de la boca y se va.
  El lanza ácido (`Armas.CREADAS.desintegrador`, efecto `acido`) echa por aquí su chorro, con el mismo alcance, el
  mismo depósito, el mismo cono y el mismo daño por segundo (30 × rareza): lo dibuja
  `escenas/armas/chorro_acido.gdshader`, como ácido a presión (fino, recto y casi blanco al salir de la boquilla, se
  abre en abanico tanto como el cono, más claro y espeso en el centro, con vetas que corren hacia fuera
  y un rocío de gotitas alrededor, y lejos se rompe en rocío; contra la pared se aplasta y salpica), con los verdes del
  ácido. No alumbra, suena a agua a presión (`chorro_acido`, con la onda de ruido de `sonido.gd`), suelta gotitas que
  caen en vez de chispas y, en vez de prender, deja a los zombis la herida de ácido (sin charcos), que los tiñe de
  verde; al jefe de bomberos sí le quita vida (por `recibir_golpe`: su `herir()` es el de las llamas), y la herida
  solo lo tiñe. Su depósito se llena con los bidones de
  ácido que suelta el gordo (`objetos.gd`).
- `goteo.gd`: la gota de ácido que cuelga de la boquilla del lanza ácido mientras Johnny lo lleva de pie, sin echar
  el chorro y con ácido en el depósito: se hincha en el labio de abajo de la boquilla, cuelga estirándose, se suelta, cae
  al suelo y salpica un poquito con un «plic» (sin charco), y empieza otra. Se pinta a píxeles del dibujo, con forma de
  gota (fina arriba y gorda abajo). Johnny le dice en cada paso dónde está el labio (`gotear()`, con las `puntas` que
  trae la hoja en su `.tres`, de `tools/hoja_lanza_acido.py`); andando o echando el chorro, la gota se suelta. De
  espaldas no gotea (el tubo apunta hacia arriba).
- La munición (parte 2 del inventario nuevo): `Armas.MUNICION` (balas de pistola, que gastan la pistola y la MP5;
  cartuchos; pilas, de la pistola eléctrica; gasolina y bidón de ácido), 8 huecos de dos cargadores. En `johnny.gd`,
  `municion` (por tipos; la gasolina y el ácido son objetos de `partida.mochila`, que no ocupan casilla de la mochila:
  `Objetos.casillas`), `cargadores` (lo que quedaba en el de cada arma dejada), `reserva()`, `cuanta()`,
  `huecos_municion()`, `sitio()`, `meter_municion()` y `arma_de_caja()`. Prueba: `--captura --municion`.
  Sus dibujos (PixelLab, 25 oct; `assets/pixellab.json` → `municion-iconos`): `assets/ui/iconos/municion-pistola.png`,
  `municion-escopeta.png`, `municion-mp5.png` (la de la pistola en verde militar, `assets/sources/municion/verde_militar.py`),
  `obj-gasolina.png` y `obj-bidon_acido.png`, de 32×32. La caja que suelta un zombi (`partida.soltar_municion`) enseña
  la munición del arma que la recibiría (`partida.icono_caja`: con la MP5, la caja verde) y cambia si Johnny cambia de
  arma (`billete.gd`, `que_icono`); la munición, la gasolina y el ácido del suelo se ven un poco a oscuras (`billete.gd`,
  `a_oscuras`, con `escenas/luces/suelo_a_oscuras.gdshader`). Prueba: `--captura --municion-suelo`.
- `lanzables.gd`: molotov, granada y arrojadizas creadas (apuntar, lanzar; `Lanzables.tipos()`). Tres tipos a mano
  (`mano`, F cambia entre ellos) y ocho de repuesto (`repuesto`): `colocar`, `repasar`, `a_la_mano`, `al_repuesto`.
  `granada.gd`: también la atraedora, la congeladora, la lluvia ácida, la mina despertador, la nube somnífera (que
  suelta `nube.gd`) y la bomba de clavos. La bomba de aceite va como el molotov (`proyectil.gd`).
- `charco.gd` (veneno, lejía, vómito, fuego, ácido, aceite, que al acabar arde, el agua de los aspersores y el
  aceite hirviendo del cocinero, que no quema a quien lo tira) y `estados.gd` (lo que hacen los charcos; también el
  frío y el calambrazo de los peligros, y `frenado`).
- `peligros/`: los peligros de las tiendas del centro comercial. `peligros.gd` (sus números y dónde va cada uno, al
  generar la planta), `frio.gd` (la cámara frigorífica; congela a los zombis: `zombi.gd`), `fuego.gd` (la cocina del
  restaurante, que se extiende por casillas), `agua.gd` (el charco con corriente de la electrónica, su cable, las luces
  de las teles y lo oscura que se queda la tienda: `Luz.extra`; `arreglar()`, cuando el técnico arregla el cable y
  el agua deja de dar calambres) y `cuadro.gd` (el cuadro eléctrico). Y tres de los Apartamentos: `porqueria.gd`, la
  habitación del Glotón (sin muebles, `jefe-gloton` del catálogo; una franja de charcos y montones de mierda con
  ácido pegada a las paredes, con una elipse limpia perfecta en medio para pelear, siempre igual, como un ring, y un
  pasillo limpio de la puerta a ella: `Peligros.del_gloton`, `Peligros.franja_y_ovalo` y `Peligros.acceso`, el hueco
  de delante de la puerta y un pasillo de su ancho, recto hacia el centro de la sala (la puerta está en el centro de
  la pared); salpicaduras en la pared de arriba y pegotes en los lomos de las otras, el resplandor verde del ácido y el estado
  `porqueria`, que quema a Johnny al pisarla), y `tropiezos.gd`, las cosas tiradas por el suelo con las que se
  tropieza: las mancuernas del gimnasio del Gymbro (`Peligros.del_gymbro`, 12) y los cubos de fregar del cuarto de la
  limpieza de la portera (`Peligros.de_la_portera`, 10, de tres colores, dibujados a cuadraditos en `tropiezos.gd`),
  repartidos por el suelo libre (`Peligros.tirar_cosas`); al pisarlos, `johnny.caer` 2 s y la cosa sale rodando (el
  cubo, además, vuelca y salpica agua sucia). Cada cosa lleva su forma, con su tamaño, su dibujo y su aviso. Con las
  mancuernas va `luz_jefe.gd` (no es un peligro: la luz fija de las habitaciones de los jefes de los Apartamentos,
  la portera, el Glotón, el Gymbro y el bombero: 5 luces blancas sin latido ni sombras, siempre la última de sus
  peligros: `Peligros.LUZ_JEFE`, `Peligros.luz_de_jefe`, `planta.gd`; en el gimnasio, que no tiene lámparas, es la
  única, y en las otras tres se suma a lo suyo). Y
  `cerco.gd`, la habitación del jefe de bomberos («Apartamento en llamas», sin muebles: `jefe-bombero` del catálogo),
  que arde por el borde (`Peligros.del_bombero`: con la misma `Peligros.franja_y_ovalo` que la porquería del Glotón:
  en medio una elipse limpia perfecta, siempre igual, como un ring, y todo lo de fuera ardiendo hasta la pared, menos
  el pasillo de la puerta de entrada a la elipse, `Peligros.acceso`): quema como el
  fuego de la cocina, prende a los zombis (al bombero no) y la alumbra con sus luces (por el borde de la elipse, como
  las del ácido: `Peligros.luces_del_ovalo`); lo fijo se pinta una vez y las llamas, solo lo que
  se ve en pantalla.
- `zombi_guardia.gd` (escena `zombi_guardia.tscn`, hereda la del normal): el guardia de seguridad del centro
  comercial, que lleva la tarjeta (ronda, silbato, huye, se cansa). Lleva el dibujo del vigilante.
- Los zombis del centro comercial (parte 4): `zombi_vigilante.tscn` (hereda la del normal; solo cambian números y
  dibujo: vida 45, velocidad 85, porrazo de 12 con más alcance; también son los refuerzos del silbato) y
  `zombi_dependienta.gd`/`.tscn` (vida 20, velocidad 95; al despertar grita «¡OFERTAS!», despierta a toda la tienda
  y les mete prisa 5 s con `meter_prisa` de `zombi.gd`, un 30 % más rápidos; luego guarda las distancias y vuelve a
  gritar cada 8 s; acorralada, chilla en la cara: 6). Salen en las tiendas (`planta.gd`, `horda`).
- `zombi.gd`: la base de todos (perseguir con navegación, zarpazos, golpes); normal, lento y rápido solo cambian
  números. `zombi_explosivo.gd`, `zombi_tentaculos.gd` y `zombi_venenoso.gd` heredan y añaden su ataque. Con
  `diana` es la de la sala de pruebas de armas: no pierde vida, no ataca y vuelve a su sitio (`casa`). La señal
  `herido` avisa de cada daño (golpe o bala, o fuego y charcos). Arder y el ácido se los pinta su shader
  (`Zombi.quemaduras`, con `fuego` y `acido`; `escenas/personajes/destello.gdshader`, el del destello y el hielo, que
  lo tiene todo en `quemaduras.gdshaderinc`): el fuego, llamas que suben desde los pies, lenguas cortas por encima y
  chispas (de `Llamas` solo lleva su luz naranja: `Llamas.cuerpo`); el ácido, manchas verdes que crecen, con burbujas
  y gotas, y una luz verde que late (`Brillo.luz_acido`). Lo que luce brilla a oscuras: `brillo.gd` le pone encima
  una copia del dibujo, sin penumbra, que solo pinta eso. A los jefes, el ácido igual (`ArmasCreadas.Herida`).
  Además de quitar vida un rato, cada uno hace lo suyo: el fuego se contagia (`contagiar`: cada medio segundo, el
  que arde prende a los zombis que tiene pegados, 1,5 s; al apagarse se queda un rato chamuscado y no se vuelve a
  prender así; números en `Lanzables.MOLOTOV`), y el ácido les come la armadura (`ArmasCreadas.con_acido`: mientras
  lo llevan, la herida o el de un charco, todo les quita un 50 % más, también a los jefes; a Johnny, no).
- `sala_armas.gd`: la sala de pruebas de armas (F11 en la planta baja; el sitio, `sala_armas` de `planta.gd`, y la
  monta `mapa.gd`): la diana en el centro, todas las armas (coma y punto; las del banco, creadas en el acto), munición
  sin fin pero recargando, las líneas de ayuda en el suelo (alcance, a quién apunta, por dónde irá la bala, el círculo
  donde le da a cada zombi y el camino de verdad de cada bala) y el panel con la ficha del arma y el recuento. Al
  salir, Johnny vuelve a llevar sus armas y balas. Prueba: `--captura --armas`.
- `portera.gd`: la jefa, por estados (charcos de ácido, embestida, grito "¡VECINOS!"; números en sus constantes).
- `minijefe.gd`: lo común de los cuatro minijefes del centro comercial (vida y barra, enfadarse a media vida con
  vapor, llamar zombis, moverse, recibir golpes con `danar()` para cambiar el daño, `quitar_vida()`, `morder()` (el
  10 % de la skin del glotón, sin pasar por `danar()`), morir; y la carrera en línea
  recta, `embestir()` con `pared_chocada()` y `estrellarse()`, con su `franja()` roja de aviso y el estado "atontado"
  con estrellitas). Cada uno hereda y pone sus ataques: `bombero.gd` (minijefe de los Apartamentos: el fuego no le
  hace nada, `inmune_fuego`; bolas de fuego `bola_fuego.gd` en abanico de 15 grados (`BOLAS`: 3, enfadado 5, cada
  `ESPERA_BOLAS`: 2,2 s, enfadado 1,6), giro con el lanzallamas en el centro de la sala con un
  cono de fuego de 40 grados (`ABERTURA`, `en_cono`) dibujado con código a cuadraditos (`cono` y `llama`; en el suelo,
  `abanico`), que llega hasta la pared en todo su ancho (`medir_conos`: `RAYOS` rayos de borde a borde, cada uno con
  `hasta_la_pared`, por el plano del piso: atraviesa los muebles), gira hacia un lado al azar (las flechas del aviso) y
  no se cruza rodando; mientras gira, una burbuja de
  fuego (`pintar_burbuja`, como la cúpula del científico jefe pero sin vida propia) le hace `invulnerable` y brilla
  donde le dan (`rebote`), molotovs `proyectil.gd` "molotov_jefe" con charcos de fuego (`MOLOTOVS`: 2, donde está
  Johnny y donde va a estar; enfadado 3, en fila; separados por lo menos `SEPARA_MOLOTOV`; cada `ESPERA_MOLOTOV`: 4,0 s,
  enfadado 2,8) y hachazo si
  Johnny se le pega; enfadado arde él mismo y deja un rastro de fuego al andar), `gymbro.gd` (minijefe de los Apartamentos: torbellino con
  los brazos abiertos, salto encima de Johnny y pesas en curva, `pesa.gd`; enfadado, armadura de suplementos con su
  barra debajo de la de vida, que se come la mitad del daño), `gloton.gd` (minijefe de los Apartamentos: a gatas, latigazo
  de lenguas en abanico, aspira 5 s tirando de Johnny hacia la boca, hasta el borde de la elipse limpia de su habitación, cada vez más fuerte y mucho más de cerca, y se lo come si llega, sangre ácida al pegarle; una
  explosión le corta lo que hace), `antidisturbios.gd` (escudo por delante y doble por la espalda,
  porrazo, carga que le atonta si se estrella, silbato), `cocinero.gd` (a media distancia: abanico de cuchillos, lluvia
  de cuchillos con su marca en el suelo, sartén de aceite hirviendo y cuchillazo), `modista.gd` (se esconde entre los
  maniquíes de su tienda y se cambia de sitio con uno, alfileres, tijeretazo; enfadada, despierta 3 maniquíes:
  `maniqui_vivo.gd`, que solo se mueven si Johnny no los mira) y `mascota.gd` (embestida con franja roja; enfadada,
  tres seguidas que rebotan en las paredes y solo la marean al estrellarse en la última; salto: se agacha, vuela 0,8 s
  sin poder dársele, con su sombra creciendo en el suelo, y cae quitando 18 en un círculo; el dibujo del salto va por
  fotogramas —`DESPEGUE`, `ATERRIZA`— y la altura la pone el código, `ALTURA_SALTO`; mareada usa el golpe, con
  balanceo). Las explosiones les dan "de lleno" (`explosion.gd`); a Johnny la carga le pone el estado "tirado"
  (`estados.gd`). El jefe final del centro comercial, `gerente.gd`, también hereda de `minijefe.gd`: anda hacia
  Johnny y lanza contratos en abanico (con rayas rojas de aviso), da un maletinazo de cerca (trozo de suelo rojo) y,
  si quedan pocos zombis, grita «¡A TRABAJAR!» y llegan dos dependientas y un vigilante; los fotogramas en los que
  sueltan los papeles y cae el maletín, en `SUELTA` y `GOLPE`. A media vida no se enfada: se pincha VD-7 (estado
  "jeringa", sin que se le pueda dar) y `mutar()` le cambia el dibujo por el del mutado (`jefe-gerente-mutado`, más
  grande: radio, `arriba` y sombra también), con un fogonazo verde. El mutado (`pensar_mutado()`, `animar_mutado()`)
  es más rápido y hace latigazos de tentáculo (tres franjas en abanico; los tentáculos largos, con código) y la
  embestida de `minijefe.gd` (si se estrella, atontado). Antes de mutar no puede caer (`danar()` le deja con 1).
  Al caer el mutado, la partida llama a `fin_del_edificio()`: su página del dosier y el helicóptero.
  El jefe final de los Apartamentos, `cientifico_jefe.gd` (el doctor Salas, `docs/JEFES_APARTAMENTOS.md`, apartado 4),
  sigue la misma receta: se mantiene a distancia (`huir()` por el mapa de navegación), tira probetas (tipos
  `probeta_*` de `proyectil.gd`, con anillos rojos donde caen), llama sujetos, les inyecta suero (más vida, más
  rápidos, pegan más; `inyectar()`) y se mete en una cúpula de cristal (`cupula`: los golpes se los lleva ella, con la
  barra azul de "armadura"; `danar()`). A media vida se pincha y `mutar()` le cambia por la criatura
  (`jefe-criatura`): lenguas-látigo (franjas y lenguas con código), puñetazo al suelo con onda expansiva (`onda()`) y
  escupitajos de fuego (`bola_fuego.gd`). Al caer, también `fin_del_edificio()`.
- `helicoptero.gd`: el helicóptero de Velaria que llega a la azotea cuando cae el gerente (dibujado con código, a
  cuadraditos): viene volando, se queda encima del helipuerto con el rotor girando y un foco (una luz de verdad) que
  busca a Johnny por el suelo. No ataca.
- `bala_zombi.gd`, `proyectil.gd` (moco, lejía, ácido, molotov, bomba de aceite, la sartén del cocinero y las
  probetas del científico jefe en parábola), `cuchillo.gd` (los cuchillos del cocinero, dibujados con código: lanzados en línea recta o cayendo sobre
  su marca; se quedan clavados un rato), `contrato.gd` (los contratos del gerente, dibujados con código: vuelan
  girando, cortan 10 y al toparse con algo caen al suelo), `explosion.gd`.
- `persona.gd`: una persona dibujada con formas (drawHuman del JS; sabe también lo de cada oficio: chaleco, bata,
  cascos, moño, bigote, martillo). Los seis supervivientes ya no la usan: van con su hoja de PixelLab (`aliado.gd`,
  `HOJAS`); `aliado.gd` la sigue sabiendo usar para quien no tenga hoja.
- `mutaciones.gd`, `llamas.gd`, `quemado.gd` (el cuerpo que muere ardiendo), `brillo.gd` (lo que arde o tiene ácido
  brilla a oscuras), `particulas.gd`, `mancha.gd`.

**Partida y progreso**
- `edificios.gd`: la ficha de cada edificio (Apartamentos, Centro comercial) y el elegido en el menú; `MINIJEFES`,
  el nombre de cada minijefe y de su tienda. La partida sortea al empezar qué minijefe va en cada planta
  (`orden_jefes`, `jefe_de()`; si aún no está hecho, la portera) y `planta.gd` lo apunta en `planta.jefe` y `el_jefe`.
  El jefe final de la azotea va en `final` y `el_final` (el gerente); `partida.final_de()` lo reconoce: su barra dice
  su nombre y no lleva el 25 % más por planta ni la mutación al caer.
- `partida.gd`: la planta en juego (cambiar de sitio, puerta cerrada hasta limpiar el piso, llave o tarjeta y su
  guardia, portera, escaleras, el ascensor arreglado a la sala de mantenimiento —`arreglar_ascensor()`, que añade
  la sala de la planta baja a la planta en juego—, dinero, pausa, fin) y las teclas de prueba. Lo de `--captura` está aparte, en
  `pruebas/partida_prueba.gd`.
- `alerta.gd`: los niveles de alerta (parte 8): la regla de cada nivel, los números (constantes) y lo que la partida
  le pregunta (`mas_zombis()`, `velocidad()`, `jefe_vida()`, `jefe_enfado()`, `botiquin()`, `guardia()`, `oido()`,
  `dolares_extra()`, `prob_rareza()`). El nivel de la partida, en `Alerta.nivel` (lo pone "Elige edificio"); la más
  alta abierta y la elegida de cada edificio, en el guardado (`alerta_max`, `alerta`). Con la Alerta 5 en los
  Apartamentos la llave la lleva un vecino (`planta.gd` lo apunta con `"llave": true` en sus zombis;
  `partida.gd`, `vecino_de_la_llave()`). La prueba: `--captura --alerta N` (`probar_alerta()`, en
  `pruebas/partida_prueba.gd`).
- `eventos.gd`: los eventos sorpresa (parte 8): una de cada cuatro plantas (nunca la última ni, dentro, la sala del
  jefe o la de mantenimiento), al pisar su pasillo, con un cartel grande: apagón (`Luz.evento` y las lámparas a
  `fuerza` 0), alarma de incendios (charcos `"agua"` de `charco.gd`, la lluvia y los cables con calambrazos: clases
  `Lluvia` y `Cable` de dentro) y horda por las escaleras (tres oleadas por la puerta de las escaleras; los que
  quedan esperan en el pasillo; premio al final). Los números, en sus constantes. Lo engancha `partida.gd` en
  `nueva_planta()`, `montar()` (`recoger()` y `al_montar()`) y `poner_lugar()` (`etiqueta()`). La prueba:
  `--captura --evento X` (`probar()`).
- `reto.gd`: el reto del día (parte 8): cada día el edificio sale igual para todo el mundo (la semilla de las
  plantas, `Planta.semilla`, sale de la fecha y del edificio: `semilla_de()`; la partida pone también el dado de
  siempre con ella al empezar) y con una regla rara de `REGLAS`, la misma para los dos edificios (`regla_de()`).
  «Elige edificio» lo pone con `empezar()` (y `quitar()` para una partida normal). La partida pregunta a sus
  funciones donde se aplica cada regla: `sin_municion()` (`partida.gd` y `johnny.gd`), `oscuras()`
  (`eventos.gd`, `al_montar`, con lo del apagón), `sin_curas()` (`partida.gd`, `supervivientes.gd` y `objetos.gd`),
  `velocidad()`, `vida()` (`aplicar_talentos`), `mas_zombis()` (`planta.gd` y la horda) y `oido()` (`zombi.gd`). La marca de hoy de cada edificio, en el guardado (`retos`, `Guardado.RETO`):
  `ficha()` (de otro día, se empieza de cero), `apuntar()` (al acabar, en `terminar()` de `partida.gd`, que no toca el
  progreso del edificio) y `marca()` y `texto_tarjeta()` para los textos. La prueba: `--captura --reto si` (o
  `--reto <regla>`; `probar_reto()` en `pruebas/partida_prueba.gd`).
- `joyeria.gd`: la cámara acorazada de la joyería (parte 10): la puerta blindada (`mapa/puerta_bano.gd` con `acero`),
  el lector (arrimarse a la puerta: con la tarjeta dorada abre; sin ella, la segunda vez dispara la apertura de
  emergencia), la alarma (cuenta atrás de 40 s con su barra en pantalla, sirena y grupos de zombis por la entrada o
  por una habitación: `grupo()`) y la tarjeta dorada, que suelta el guardia de esa planta (`soltar_dorada`, desde
  `_al_caer_guardia` de `partida.gd`; `Mapa.poner_llave(..., dorada)` y su señal `dorada_cogida`). Al abrirse, el
  premio dentro (`preparar_premio`, `poner_premio`, `coger_premio`: un arma creada morada de una receta sabida, que
  va a la mano como al sacarla del baúl, y el fajo de billetes) y el logro «Caja fuerte». El estado, en
  `planta.joyeria` (lo crea `planta.gd`). Lo engancha `partida.gd` como los eventos (`preparar`, `al_montar`,
  `recoger`). La prueba: `--captura --edificio centro --joyeria` (`probar_joyeria()` en `pruebas/partida_prueba.gd`).
- `skins.gd`: las skins de Johnny, que se desbloquean haciendo algo y se quedan para siempre: `LISTA` (nombre, `efecto`
  (lo que hace llevarla puesta, tal cual sale en la taquilla; cómo es por fuera, no: eso ya se ve en Johnny),
  cómo se consigue, `jefe`, el que la suelta, y su ventaja: `fregona`, por cuánto se multiplica su daño; `cuerpo`, lo
  mismo con todas las armas cuerpo a cuerpo; `mordisco`, lo que pierde el jefe que te hace daño; `quema`, por cuánto se
  multiplica el daño de las armas que queman; `ignifugo`, si el fuego no le hace nada), `puesta()` y `poner()` (el guardado, `skin`), `tenidas()` y `desbloquear()`
  (`skins`), `de_jefe(tipo)` (la que suelta ese jefe al caer por primera vez: `partida.gd`, con su aviso),
  `siguiente()` (la tecla Z), `hoja(de_siempre, id)` (la hoja de esa skin para un arma: `conserje-48-<arma>-<id>.tres`),
  `fregona(id)`, `cuerpo(id)`, `mordisco(id)`, `quema(id)` e `ignifugo(id)`. **El portero** (la suelta la portera): viejo de pelo largo blanco, coleta y barba, con
  el pañuelo de siempre, y la fregona × 4. **El glotón** (la suelta el Glotón): calvo y con la cara convertida en una
  boca llena de dientes; quien le hace daño lo paga (`johnny.devolver()`): un zombi normal (o un maniquí) muere al
  momento y un jefe pierde un 10 % de su vida máxima, directo a la vida (`morder()` en `minijefe.gd` y `portera.gd`: ni
  la armadura del Gymbro, ni el escudo del antidisturbios, ni la cúpula del científico lo paran; el científico y el
  gerente, antes de pincharse, no caen). **El gymbro** (la suelta el Gymbro): calvo, con el pañuelo de siempre y
  barba negra; las armas cuerpo a cuerpo hacen el triple de daño (la fregona, el bate y el cuchillo; el golpe de Ninja y los
  martillazos del ferretero, no). **El bombero** (la suelta el
  jefe de bomberos): un casco de bombero ajustado, negro con la raya amarilla, que tapa el pelo y el pañuelo; las armas
  que queman hacen el triple de daño (el lanzallamas, la llama y la quemadura;
  el molotov y la bomba de aceite, por `dano_lanzar` en `lanzables.gd`), y también lo que sigue
  ardiendo el zombi (`zombi.prender(quema)`); las armas de fuego de siempre, no. Y el fuego no le hace nada: el del
  suelo y los charcos (también el aceite hirviendo del cocinero), el seguir ardiendo al salir, y el cono, las bolas, el
  aro y los molotovs del jefe de bomberos (y las bolas de fuego del científico); el hachazo y las explosiones, sí. Sus hojas son las de siempre
  con la cabeza cambiada (`tools/cara.py`). Se
  eligen en la taquilla del vestuario (`ui/taquilla.gd`). La prueba: `--captura --skins` (`probar_skins()`).
- `talentos.gd` (árbol y compra de puntos), `objetos.gd` (los 18 objetos; los que se usan desde el inventario, `USABLES`:
  el botiquín de la farmacéutica, las vendas de la farmacia y el bocadillo del supermercado, con lo que curan, que no
  entran en recetas ni van al baúl: `partida.usar_objeto()` y `cura_de()`; mochila, baúl de 32 casillas, con
  `al_baul()` y `cabe_baul()` para guardar en él, lo que
  sueltan los zombis: en los Apartamentos, los 10 de siempre (el mechero, que solo entraba en el súpersoplete, la llave inglesa y el hacha, que solo
  entraban en el bumerán, y las cuchillas, el táser, la cuerda y las mancuernas, que solo entraban en las de cuerpo a cuerpo y el garfio, se
  quitaron el 25 oct; con ellas, también la cadena, el cable, el hielo seco y las perchas del centro comercial); en el centro comercial, la lista de la tienda donde cae
  el zombi, `TIENDAS`, y en el pasillo, la de una tienda cualquiera; y los que solo suelta un zombi, `DE_UN_ZOMBI`, 1 de
  cada 4 veces y en los dos edificios: los explosivos, el dinamitero, y el bidón de ácido, que llena el lanza ácido, el
  gordo; no salen al azar ni de los jefes), `recetas.gd` (11 recetas y rarezas: 6 de los
  Apartamentos, 4 que mezclan los dos edificios y 1 solo del centro; el 25 oct se quitaron la lanza, el súpersoplete, el
  bumerán, el garfio y las nueve de cuerpo a cuerpo: el aplastacabezas, el bate de fuego, el partecuerpos, la
  inmovilizadora, el látigo escorpión, la súper maza, el mangual, el bate helado y el látigo eléctrico. La fregona, el
  bate y el cuchillo ya no entran en ninguna, pero el banco sigue sabiendo gastarlos, `Recetas.ARMAS`; solo se crean las aprendidas, `recetas` del
  guardado: el molotov de serie y las demás, en el papel que suelta cada jefe al morir, `soltar_receta` de
  `partida.gd`, una al azar sin repetir; la prueba `--captura` las prueba en `probar_soltar_recetas`), `billete.gd`, `minimapa.gd` (con el técnico
  rescatado, `camaras`: un puntito por zombi en cada sala). La prueba
  `--captura` cuenta el reparto de cada sitio (`probar_objetos` de `pruebas/partida_prueba.gd`) y saca `captura-objetos-nuevos.png`,
  `captura-banco-todo.png` y `captura-baul-todo.png`; luego prueba cada arma nueva contra zombis (`probar_recetas`)
  y saca `captura-arma-<receta>.png`.
- `guardado.gd`: el guardado entre partidas. Para Colecciones: `encontrados` (objetos cogidos alguna vez), `creadas`
  (armas creadas alguna vez en el banco), `bestiario` (enemigos vistos) y `colecciones_nuevo` (hay algo nuevo desde
  la última vez que se abrió el programa; el icono avisa). Un guardado de antes los rellena una vez con lo del baúl.
  Para el reto del día: `retos` (la ficha de hoy de cada edificio, `RETO`: fecha, regla, intentos, planta, completado
  y tiempo). Las skins de Johnny (`skins.gd`): `skin` (la puesta) y `skins` (las desbloqueadas).
- `logros.gd`: la lista de logros (añadir uno = una línea en `LISTA`) y sus avisos.
- `historia.gd`: el texto del dosier de cada edificio (`DOSIERES`: Apartamentos y centro comercial), la hoja de
  papel y las noticias de Canal 8 (`NOTICIAS`, con cuándo sale cada una; las vistas en `noticias_vistas` del
  guardado). La última página del centro no la lleva un muerto: la suelta el gerente al caer (`del_jefe`; la
  partida la enseña con `pagina_del_jefe()`). También el guiño de la cafetera (`CAFETERA`: lo dice la farmacéutica,
  `supervivientes.gd`). Para cambiar la historia se edita aquí, sin tocar los `id`. Las páginas encontradas se
  guardan para siempre (`paginas` del guardado) y el programa Dosier del ordenador enseña las de todos los edificios.
- `bestiario.gd`: las 17 fichas del bestiario de Colecciones (`LISTA`: cada enemigo con su nombre, su frase, en qué
  edificios sale, su hoja de sprites y la animación de frente). `apuntar(id)` lo llama `meter_zombi` de `partida.gd`
  con cada enemigo que nace (y el gerente al mutar, y la modista con el maniquí vivo): visto = ha aparecido en la
  sala donde estás; apunta en memoria y solo escribe el guardado la primera vez. `retrato(id)` da el dibujo de
  frente recortado a lo dibujado (el `recorte` de cada ficha lo calcula `py tools/recortes_bestiario.py`; repetirlo si
  cambia una hoja). `todo_visto()` es la tecla F8. Los textos se retocan aquí, sin tocar los `id`.
- `supervivientes.gd` (el superviviente encerrado en su baño, la horda, los vecinos en sus viviendas) y
  `aliado.gd` (cada superviviente: sigue a Johnny, dispara o cura, fuerza la cerradura; los que atacan van a por los
  zombis que ven aunque rompan la fila, `cazar`, y vuelven a su puesto cuando no queda ninguno a la vista; al acabar
  la presentación de un jefe esperan 1 s sin cazar ni atacar, `calma`; los seis se dibujan con su
  hoja de PixelLab, `HOJAS` → `assets/sprites/superviviente-<id>`, al tamaño de Johnny: reposo, andar, lo suyo en las
  8 direcciones y caído; la bala, la cura, el martillazo y la descarga llegan en su fotograma, `fogonazo`; la
  farmacéutica no tiene acción). En `DATOS`, los seis:
  los tres de los Apartamentos y los tres del centro comercial, con su tienda y su habitación (`planta.gd` pone
  su tienda en su planta: `Planta.tienda_fija`), sus gritos y su mejora (el ferretero no tiene). Ya rescatados viven
  en las viviendas (`mapa/viviendas.gd`): al montarlas, `colocar_vecinos()` pone a cada uno en su habitación
  (`Viviendas.casa(id)`: en medio, menos el técnico, `Viviendas.SITIO`). La mejora de la farmacéutica: `botiquin_al_empezar()` (lo llama `partida.gd` al empezar) mete un botiquín en la mochila, que se
  usa desde el inventario (`partida.usar_objeto`). El guiño de la cafetera (`guino_cafetera`: la primera vez que
  Johnny entra en la habitación de la farmacéutica con ella rescatada, en su sitio o acompañándole; lo vigila
  `sala_cafe`, y `cafetera` en el guardado). Lo suyo al acompañarte: disparar, curar, martillazos, descarga que
  aturde y charcos a medias (`johnny.gd` pregunta a `Aliado.charcos_a_medias`).
- `escolta.gd`: el rescate propio de la farmacéutica (llevarla herida hasta las escaleras, con zombis saliendo por
  las puertas del pasillo); la cuelga `supervivientes.gd` y `partida.gd` le pregunta antes de cruzar una puerta.
- `averia.gd`: el rescate propio del técnico (bajar la palanca del cuadro y aguantar a oscuras, con zombis entrando
  por las habitaciones de la tienda, mientras arregla el cable del agua); igual que la escolta. Su prueba también
  prueba su mejora (el minimapa con los zombis y las pantallas de su habitación).
- `barricada.gd`: el rescate propio del ferretero (la puerta de su almacén con tablas; al limpiar la tienda se
  cierra la entrada y hay que defender la puerta mientras las quita, con zombis entrando por las habitaciones o la
  entrada). Lo que aporrean los zombis es un punto invisible delante de la puerta (`Diana`, en el grupo "presa").
  La cuelga `supervivientes.gd`.
- `sonido.gd` (autoload): efectos sintetizados como en `src/sfx.js` y la música (`Sonido.tocar("compra")`,
  `Sonido.musica("jefe")`). Además de las ondas del JS, una de ruido (`ruido`: un siseo), para el chorro del lanza ácido.
- `sala.gd`: la sala de pruebas (hornea la navegación, tandas mezcladas, F2-F7 y P, su `--captura`).

**pruebas/**: lo que solo se usa en las pruebas sin jugar (`--captura`).
- `captura.gd` (clase `Captura`): `Captura.activa()` (si se ha arrancado con `--captura`), `Captura.dato("--jefe",
  "antidisturbios")` (lo que va detrás de esa palabra en la línea de órdenes) y `Captura.foto("captura-x.png")`
  (guarda lo que se ve en la pantalla). Lo usan todas las pruebas, también las de `supervivientes.gd`, `eventos.gd`,
  `averia.gd`, `escolta.gd` y `barricada.gd`.
- `partida_prueba.gd`: la partida de prueba. Es `partida.gd` (la hereda: tiene todo lo suyo) más las fotos y lo
  que cuenta en la terminal. Sin nada más, la prueba larga (`_process`: un apartamento, el jefe, menús, ordenador,
  inventario, recetas, supervivientes, historia, colecciones...; con `--edificio centro`, en el centro comercial, con
  el antidisturbios en la 1ª planta, u otro minijefe con `--jefe cocinero`, `--jefe modista` o `--jefe mascota`, y al
  final la azotea; en los Apartamentos, la portera en la planta baja o el minijefe de `--jefe gloton` / `--jefe gymbro` / `--jefe bombero` en la 1ª). `probar_colecciones` deja en el guardado parte de lo que hay, saca el escritorio con el aviso
  (`captura-escritorio-nuevo.png`), los objetos del edificio (`captura-colecciones.png`), la ficha del vecino
  (`captura-bestiario.png`) y la del gerente sin ver (`captura-bestiario-falta.png`), y cuenta en la terminal lo
  encontrado, creado y visto de cada edificio.
  Con `--fotos-tiendas` (una foto de cada tienda y de la galería, `captura-tienda-<tipo>.png` y
  `captura-galeria-<n>.png`, y las de los peligros, `captura-peligro-<...>.png`), `--fotos-luz`, `--fotos-ayudas`,
  `--alerta N`, `--evento X`, `--reto si` (`probar_reto`: el reto del día), `--joyeria` (`probar_joyeria`: la cámara
  acorazada), `--skins` (`probar_skins`: las skins de Johnny), `--baul` (`probar_baul`: guardar en el baúl lo
  de la mochila), `--repuesto` (`probar_repuesto`: dos armas de cada tipo, la de la mano y la de repuesto), `--banco` (`probar_banco`: las 13 armas creadas quitadas del juego (la lanza, el súpersoplete, el bumerán, el garfio y las nueve de cuerpo a cuerpo) y los 11 objetos quitados (el mechero, la llave inglesa, el hacha, las cuchillas, el táser, la cuerda, las mancuernas, la cadena, las perchas, el hielo seco y el cable), de antes en el guardado, desaparecen al cargar, y la pistola eléctrica se queda; luego el banco,
  las recetas y las Colecciones, sin la prueba larga),
  `--lanzallamas` (`probar_lanzallamas`: el lanzallamas de la llamarada continua, su icono y su daño por segundo en el baúl (también el de uno de antes) y en el banco, sus números y su boca sin chispitas, que las balas no le valen; en la sala de pruebas de armas, 1 s de llama que quema a los zombis a 120 y a 250 y no toca al de 430, sin quitarle vida a Johnny ni dejar fuego en el suelo, a oscuras alumbrando, despegándose de la boca al soltar, aplastada contra la pared, el depósito que se llena solo con una gasolina, «¡Sin gasolina!» y la gasolina cogida del suelo (con la barra naranja), la llama hacia zombis entre dos direcciones (sale recto por el tubo; su cono de 45° le da al que no está justo en la línea, y al del hueco entre la diagonal y abajo, que queda fuera, el chorro se le gira lo justo para que entre por el borde), la postura de apuntar y la llama saliendo del tubo en las 8 direcciones, andando igual que sin echar fuego y con las 4 skins, `captura-lanzallamas-<baul, llama, oscuro, apagando, pared, recto, hueco, sin-gasolina, dirección, andando o skin>.png`), `--desintegrador` (`probar_desintegrador`: el lanza ácido, un lanzallamas de ácido: su nombre, su icono y su hoja (la del lanzallamas con las bombonas verdes), sus números y su boca; en la sala de pruebas de armas, la gota de ácido que cuelga de la boquilla y cae, 1 s de chorro que quita vida y deja la herida de ácido a los zombis a 120 y a 250 y no toca al de 430, sin charcos ni luz y soltando la gota al echarlo, despegándose de la boquilla al soltar, contra la pared, el depósito que se llena solo con un bidón de ácido, «¡Sin ácido!» (una gasolina no le vale) y el bidón cogido del suelo (con la barra verde), hacia zombis entre dos direcciones (sale recto por el tubo; su cono de 45° le da al que no está justo en la línea, y al del hueco entre la diagonal y abajo, que queda fuera, el chorro se le gira lo justo para que entre por el borde), en las 8 direcciones y con las 4 skins (con las puntas de la gota en su hoja) y el jefe de bomberos, al que el ácido sí le quita vida; también los del baúl con el daño de una gota, que cogen el de ahora, y que los bidones solo los suelta el gordo, 1 de cada 4 veces, y salen en las Colecciones de los dos edificios, `captura-desintegrador-<baul, gota, cae, chorro, soltando, pared, recto, hueco, sin-acido, bidon, dirección, gota-dirección o skin>.png`), `--pistola-electrica` (`probar_pistola_electrica`: la pistola eléctrica con su dibujo propio, su icono en el baúl y en el banco, su hoja y su boca sin chispitas de adorno, que la chispa a 120 quita vida al zombi y lo aturde, salta al que tiene al lado y también lo aturde, no toca al de 330, que gasta una bala por disparo, que disparando andando sigue andando con los efectos encima y el retroceso, la descarga dibujada y las chispas saliendo del mismo sitio en las 8 direcciones y con las 4 skins, `captura-pistola-electrica-<baul, chispa, andando, dirección o skin>.png`)
  o `--ascensor` (`probar_ascensor`: bajar en el ascensor a la sala y volver), solo esa parte. `partida.gd` la avisa en tres momentos de su `_ready()`:
  `preparar_prueba()`, `ordenar_jefes_prueba()` y `empezar_prueba()` (en la partida de verdad no hacen nada).

**ui/**

- `barra_jefe.gd` (`BarraJefe`): la barra de vida de todos los jefes, arriba en el centro (el nodo `Pantalla/Jefa` de
  `partida.tscn`), con el mismo estilo que la de Johnny en `hud.gd`: el marco oxidado `barra-vida.png` alargado a 400
  repitiendo su trozo de en medio (las puntas con remaches no se estiran), la sangre roja con su brillo, lo perdido en
  claro antes de bajar, el temblor al recibir un golpe y la vida en números. Con el jefe enfadado (`fase` 2) la sangre
  da un fogonazo, se vuelve rojo fuego y late. Encima, su nombre (`Nombre`) con la letra de los jefes, Jersey 25
  (`Tema.FUENTE_JEFE`, a 25); debajo, la barra fina de armadura (`Armadura`, del Gymbro y la cúpula del científico:
  la hace `partida.armadura_jefe()` y la pinta `pintar_armadura`). `partida.gd` le pone `jefe`, `max_value` y `value`.
- `presentacion.gd`: la presentación de cada jefe al aparecer: todo se queda quieto, la cámara hace zoom sobre él
  entre dos franjas negras mientras grita (su estado «grito», un foco, menos el Gymbro: `SIN_FOCO`, se ve con la luz
  de su gimnasio, y el rugido; sin frase escrita, que con el zoom
  no se leía) y sale su nombre en grande (con la letra de los jefes, a 50); Johnny se calla mientras tanto (lo que
  estuviera diciendo, como el aviso de la habitación, y lo que fuera a decir: `partida.decir` lo guarda en
  `pendiente`) y lo dice al acabar;
  a los 2,2 s vuelve la cámara y empieza la pelea; las mutaciones (`Mutaciones.TRAS_PRESENTACION`) y los
  acompañantes que atacan (`aliado.gd`, `calma`: siguen en la fila sin cazar ni atacar) esperan 1 s más. Los que
  entran a su manera (la Modista, escondida) solo reciben
  franjas, nombre y rugido. La monta `partida.gd` al sacar al jefe (en la prueba se salta, salvo con `--presentacion`);
  mientras dura no se puede pausar ni abrir el inventario. El jefe sale siempre en medio de su sala
  (`mapa.centro_libre`; en la azotea, en el helipuerto). El desplazamiento de la cámara va por `Temblor.desplazamiento`
  (`temblor.gd`), que se suma a la sacudida; `johnny.quedarse_quieto()` lo deja parado del todo.
- `tema.gd` (aspecto de menús y HUD), `hud.gd`, `menus.gd`, `menu_principal.gd` (menú y "Elige edificio": la tarjeta de cada edificio, el selector de alerta y el botón del reto del día con tu marca de hoy), `opciones.gd` (pantalla de Opciones: modo de atacar, música, sonido, ajustes del móvil, ayudas y tabla de controles para cambiarlos; los cambios los pone y guarda `scripts/controles.gd`), `tactil.gd` (controles del móvil; su tamaño, transparencia y vibración se leen de `ajustes` con `Tactil.ajustar()`).
- `ordenador.gd`: la pantalla de ConserjeOS (puntos, talentos, tienda de armas, logros, Dosier, Noticias y
  Colecciones: por cada edificio, los objetos encontrados, las armas creadas y las páginas del dosier, en porcentaje,
  y el bestiario con cada enemigo visto, su dibujo y su frase; el icono avisa con «¡NUEVO!» mientras
  `colecciones_nuevo` del guardado esté puesto). `inventario.gd`: inventario (ponerse, usar y tirar), baúl (sacar armas y guardar a mano lo de la mochila: `pintar_guardar`, `guardar`, `guardar_todo`; la prueba, `--captura --baul`, `probar_baul()`) y banco. `taquilla.gd`: la ventanita de la
  taquilla de Johnny (la abre `partida.abrir_taquilla` al arrimarse): Johnny de muestra con la skin marcada
  (`marcar`: su hoja de la fregona; en silueta si aún no se tiene) y la lista para ponerse una (`elegir`:
  `Skins.poner` y `johnny.vestir`), con la cara de cada una de icono (`assets/ui/iconos/skin-<id>.png`) y, debajo del
  nombre, su efecto (las que faltan, cómo se consiguen; el conserje, «Sin efecto especial»). Cada carta es un marco
  con el botón detrás, que crece si la frase parte en dos líneas, y `igualar` las deja todas tan altas como la más alta.
- `tele.gd`: la tele de las noticias, dibujada con código. `ambiente.gd`: viñeteado, pantalla roja con poca vida y escarcha con frío.
- `botones.gd` (autoload): el saltito de los botones.

**mapa/**
- `apartamento.gd` (genera un apartamento como `apartment.js`; la habitación de un jefe, de los Apartamentos y del
  centro comercial, con la puerta de entrada siempre en el centro de la pared), `tienda.gd` (genera una tienda del centro
  comercial, con el mismo tipo de plano; sus tipos, en `TIPOS`: la joyería, parte 10, no se sortea, sale una por
  partida en la planta de `Planta.joyeria_planta`), `planta.gd` (la planta, sus zombis, la sala de mantenimiento —tres
  estancias de 10 × 10 una al lado de otra, el vestuario, el despacho y el taller (`SALA_ESTANCIAS`), hecha como un
  apartamento: su `apt`, con todas las estancias ya vistas, sin niebla; la puerta del pasillo, abajo en el despacho, y
  la de las viviendas, a la derecha del taller; sus muebles de adorno, del catálogo, los pone ella, y el ordenador, el
  banco, el baúl, la taquilla y el corcho, `mapa.gd` (`ORDENADOR_X`, `BANCO_X`...), con el suelo y la pared de cada
  estancia en `ESTILO_MANTENIMIENTO`—; la de
  exposición y la de pruebas de armas; en el centro comercial, la última planta es la azotea: `azotea` y `aparatos`), `viviendas.gd` (las
  viviendas de los supervivientes rescatados, detrás de la puerta de la derecha de la sala de mantenimiento: un pasillo
  largo con seis habitaciones, tres arriba para los de los Apartamentos y tres abajo para los del centro comercial,
  hecho como un apartamento —su `apt`, con niebla por habitación—; siempre igual: `habitacion(id)` y `casa(id)` dicen
  dónde está cada una y dónde espera cada uno; qué puertas se abren lo decide `mapa.gd` al montarlo), `catalogo.gd` (muebles de cada sala; en las tiendas, por tipo: "tienda-<tipo>"; la tienda de un minijefe, si
  tiene la suya: "jefe-modista"; la habitación de un minijefe de los Apartamentos: "jefe-gloton", "jefe-gymbro", "jefe-portera";
  `planta.gd` la elige por el jefe de la planta, también cuando la portera sale por defecto; las viviendas: "pasillo-viviendas" y
  "habitacion-<id>", de momento vacías: cada sala con "tipo" busca "<uso>-<tipo>" en `Muebles.de_apartamento`),
  `muebles.gd` (dónde va cada uno; en las salas de venta, también filas en medio: `islas`; en el gimnasio, tres
  paredes con las máquinas siempre en el mismo orden y repartidas parejas de punta a punta: `fijos`), `mueble.gd`
  (monta uno).
- `mapa.gd`: monta un sitio (suelos, tapas, caras de pared, choques, muebles, peligros, niebla, navegación; y
  `muro_entre(a, b)`, la primera pared que corta una línea sin contar los muebles: la usa el vómito de Gastroenteritis;
  en el cuarto de la limpieza de la portera, `colgados`: fregonas y cubos colgados en la pared de arriba). Los suelos y
  paredes de cada sala salen de `ESTILO_DE` (pisos), `ESTILO_TIENDA` (tiendas: por uso, o por `"<uso>-<tipo>"` si ese
  tipo tiene el suyo, como el mármol de la joyería) y `PASILLOS` (el pasillo de cada
  edificio); en el centro comercial pone además los escaparates, los neones y los restos sueltos, y en la azotea
  su hormigón, el murete con la ciudad detrás y el helipuerto pintado. En las viviendas (`poner_viviendas`), con el
  guardado de ese momento: la placa de cada puerta (`placa.gd`), las de los que faltan por rescatar cerradas con una
  hoja (`puerta_bano.gd`) y sin descubrir, las de los rescatados abiertas y ya descubiertas, las cámaras del técnico
  y la cafetera de Johnny junto a la farmacéutica.
  `cara_pared.gd`, `puerta.gd` (las de la pared de arriba, dibujos de PixelLab: `puerta-piso` en los Apartamentos,
  `puerta-tienda` de cristal en el centro comercial y `puerta-servicio` de acero en la sala de mantenimiento de los dos;
  las de los otros muros, el ascensor y las escaleras, con código; también la escalera de incendios de la azotea, las placas con la letra de cada piso y el cartel de la planta junto al ascensor; encima de las puertas ya no se escribe adónde llevan, ni dentro de las estancias ni en el pasillo ni en la azotea), `puerta_bano.gd` (la del superviviente, y la de las habitaciones cerradas de las viviendas; de frente, el dibujo `puerta-bano`), `placa.gd` (la placa de latón con el nombre de cada habitación de las viviendas), `neon.gd` (el letrero de neón de una tienda).
- `ordenador.gd` (la mesa), `arrimable.gd` (baúl, banco y la taquilla de las skins: `TAQUILLA_X` en `mapa.gd`; ni la
  mesa ni estos llevan su nombre escrito debajo),
  `armarito.gd` (botiquín), `cientifico.gd` (el
  científico muerto con su página: sprite de PixelLab en tres capas, con la piel y el pelo de su página; los que
  no son científicos, con su ropa y aún dibujados con código), `cafetera.gd` (la de Johnny, en la
  habitación de la farmacéutica de las viviendas, a su derecha: `CAFETERA_JUNTO` en `mapa.gd`; dibujada con código), `camaras.gd` (las pantallas de las cámaras de
  seguridad, detrás del técnico, en su habitación de las viviendas).

**luz/**: `luz.gd` (penumbra de cada sitio, con lo de más de la tienda de electrónica y del apagón; luz de Johnny, fogonazos), `lampara.gd`, `fuego.gd`.

## assets/

- `sprites/`: copia de los sprites del JS (`.png` + `.json` + `manifest.json`); los `.tres` de al lado son sus
  animaciones. Hoja nueva → `py tools/hacer_frames.py assets/sprites/zombi-normal`.
- `musica/`: las dos canciones de 8 bits hechas aquí (ver `tools/`): `el-ultimo-inquilino.ogg` (los menús y
  explorar las plantas) y `turno-de-noche.ogg` (peleas). Suenan en bucle; la de cada momento se elige en
  `CANCIONES` de `sonido.gd` (con sus compases, para que entre siempre al principio de uno).
- `ui/`, `fuentes/`: HUD y menús del JS (la fuente es nítida a 16 y 32). En `fuentes/` también, la letra de los
  nombres de los jefes: `jersey-25.ttf` (Jersey 25, de Google Fonts; nítida a 25 y 50), con su licencia OFL
  `jersey-25-OFL.txt`, que tiene que ir siempre con ella. `tiles/`: texturas para los TileSets.
- `sources/`: originales (lleva `.gdignore`). `pixellab.json`: todo lo generado en PixelLab.

## tools/

`hacer_frames.py` (hoja → animaciones; si el `.json` de la hoja trae `durations` en una dirección, cada dibujo dura lo que diga); las hojas de Johnny con un arma se montan con `tools/arma.py` del juego JS, que no está aquí (`PYTHONPATH=tools py C:/Users/angel/Projects/game/tools/arma.py conserje-48-<arma>`, con lo de `assets/sources/conserje-48-<arma>/` y su `arma.json`; la receta entera, en la skill `arma-nueva` del juego JS; las últimas, el lanzallamas y el desintegrador; lo que se aprendió con el látigo, el látigo eléctrico, la súper maza y el mangual, que se quitaron el 25 oct: si el arma se sale de la casilla de siempre (una cuerda que se estira, un giro que rodea a Johnny), lleva `celda`, `pivote` y `lienzo_ataque` en su `arma.json`; las de a distancia llevan en `ataque` `boca: fogonazo`, `impacto` 0, `efectos` y fotogramas empezando por el disparo (lo que se aprendió con el súpersoplete, que se quitó el 25 oct: con algo amarillo en el arma, `sin_tinte` vacío, porque `arma.py` cree que la llama tiñe a Johnny y le quita casi toda; y con una llamarada larga, la boca que calcula, la del centro de la llamarada, no vale: se saca del piloto del dibujo quieto y va a mano en `armas.gd`); el desintegrador, también de a distancia, `celda` [152, 136] y `pivote` [66, 90] (el chorro llega a 62 píxeles a un lado, 82 al otro, 87 hacia arriba y 39 hacia abajo), solo 2 fotogramas y `duracion` 0,079 s (ritmo 12), `margen_efectos` 9 y SIN `boca: fogonazo`: con ácido verde `arma.py` no encuentra ningún fogonazo naranja y falla con «no encuentro el fogonazo», así que no escribe `muzzle` y la boca va a mano en `armas.gd`, sacada de la punta blanca de la boquilla; `efectos` sí funciona con el chorro verde; lo que se aprendió con el bumerán y el garfio, que se quitaron el 25 oct, y vale para las que se lanzan: `celda` [94, 92] y `pivote` [45, 76] (el brazo llega a 41 píxeles a un lado, 45 al otro, 72 hacia arriba y 12 hacia abajo), 5 fotogramas por dirección y `duracion` 0,6 s que empiezan en el lanzamiento (el brazo ya estirado, porque el bumerán sale al empezar `attack`), SIN `boca: fogonazo` ni `efectos` (la boca, la mano, va a mano en `armas.gd`, y andando no hay gesto), con el andar del oeste en espejo del este, `andar.espejo`); el script elige solo el tramo del andar, y con la maza y la cadena de la súper maza y el mangual fallaba: para eso está `andar.ciclo`, que lo pone a mano); `superviviente.py` (monta la hoja de un superviviente con lo de PixelLab: reposo a
mano, andar alineado, acción con el fogonazo limpio, si la tiene, y caído; `py tools/superviviente.py policia`);
para los zombis nuevos, las herramientas del JS copiadas aquí: `piel.py`
(la piel a verde; admite otro tono de origen, la fila de los zapatos y la saturación máxima), `bajar_zip.py`, `bajar.py` y `bajar_fotogramas.py` (bajar de PixelLab; el último, una animación fotograma a fotograma con las URL de `get_character`, cuando el zip aún no deja, y monta una tira para mirarla), `espejo_oeste.py` (la animación hacia el oeste con la del este en espejo), `ritmo_andar.py` (iguala el ritmo del paso de Johnny en unas direcciones sin tocar los dibujos: cada dibujo dura según cuánto cambian las piernas hasta el siguiente; `py tools/ritmo_andar.py conserje-48-pistola south north`), `juntar_piernas.py` (cierra las piernas abiertas a lo ancho en unos dibujos del paso: cada fila de las piernas, más hacia dentro cuanto más abajo, con el zapato entero; `py tools/juntar_piernas.py conserje-48-pistola south 4,5 3`), `andar_arma.py` (rehace las filas de andar de la hoja de Johnny con un arma con los dibujos de PixelLab que se elijan en `arma.json` → `andar` → `fotogramas`, saltando los que repiten postura; además pone los pies siempre a la altura de Johnny quieto, quita los grises sueltos bajo los zapatos, pinta de marrón los zapatos de `zapatos_negros` y da menos tiempo a los dibujos casi repetidos en las direcciones de `ritmo_parejo`; hoy, la fregona), `hoja.py` (hoja de
revisión) y `zombi.py` (+ `png.py`: monta la hoja del zombi; con `"sangre_en_todo"` oscurece la sangre también en
el dibujo quieto y con `"sueltos"` quita los chorros que salen volando, en `assets/sources/<zombi>/zombi.json`); `jefe_hoja.py` (las vistas y animaciones de PixelLab de un minijefe de 72 → hoja y `.tres`:
`py tools/jefe_hoja.py antidisturbios-72 jefe-antidisturbios`, `cocinero-72 jefe-cocinero`, `modista-72 jefe-modista` o
`mascota-72 jefe-mascota`, la portera: `portera-72 jefe-portera`, el Glotón: `gloton-72 jefe-gloton`, el Gymbro: `gymbro-72 jefe-gymbro`, el jefe de bomberos: `bombero-72 jefe-bombero`, y los jefes finales, de 128: `gerente-128 jefe-gerente` y `gerente-mutado-128 jefe-gerente-mutado`, `cientifico-jefe-128 jefe-cientifico` y `criatura-128 jefe-criatura`; las animaciones de cada uno, en su
ficha `JEFES` (con la lista, los fotogramas por
segundo y, si el lienzo no es de 72, el punto de los pies; la embestida de la mascota y la del gerente mutado llevan
un 5.º dato: quitar el primer fotograma; y opciones: `"sangre"`, `"motas"` por animación y `"sin"` para quitar fotogramas
sueltos); alinea por los pies los lienzos
de PixelLab, borra las motas sueltas, oscurece la sangre si la ficha lo pide y dice el `offset` del Sprite; lo que
falte, con la vista quieta), `espejo_oeste.py` (las animaciones hacia el oeste, dando la vuelta a las del este;
con `--lado`, también suroeste y noroeste y las vistas quietas, para ahorrar generaciones), `texturas_bano.py`, `importar.py` (muebles nuevos → sprites; lee
`catalogo.gd`), `textura_suelo.py`, `textura_pared.py` y `textura_tapa.py` (suelos, paredes y tapas: ver `FONDOS.md`),
`icono_alerta.py` (el triángulo de los niveles de alerta), `guias_centro.py` (bocetos para pedir a PixelLab muebles rectos, y quitarles el fondo; `guias_azotea.py`, los de los
aparatos de la azotea; `guias_gimnasio.py`, las máquinas del gimnasio del Gymbro; `guias_limpieza.py`, los muebles del cuarto de la
limpieza de la portera y lo que cuelga de su pared, que también pasa a sprite; `guias_puertas.py`, las puertas vistas de
frente, que también pasa a sprites `puerta-<piso|tienda|servicio|bano>`; `banco_mantenimiento.py`, `baul_mantenimiento.py` y
`ordenador_mantenimiento.py`, el banco de trabajo, el baúl y la mesa del ordenador de la sala de mantenimiento, que también
pasan a sprite; el de la mesa, además, le quita la sombra azulada que PixelLab pinta debajo; `guias_mantenimiento.py`, los
muebles nuevos de sus estancias —plato de ducha, banco largo, váter y lavabo de lado, estantería con botes, papelera— y
el corcho del despacho, que también pasa a sprite, y les quita lo azulado que PixelLab pinta alrededor), `azotea.py` (las texturas de la azotea: hormigón, murete con la ciudad de noche, su tapa y el
helipuerto, dibujadas con código), `centro_sprites.py`
(escaparates y restos del centro comercial → sprites), `despixelar.py` (de PixelLab y Gemini), `dibujos_7b.py` (el armarito del baño), `taquilla.py` (la taquilla de las skins), `cara.py` (las skins de Johnny: pega
la cabeza nueva que hizo PixelLab en sus 8 dibujos quietos en todos los dibujos de las nueve hojas de armas (también la del lanzallamas, la del desintegrador y la de la pistola eléctrica; con `py tools/cara.py <skin> <arma>`, solo la de esa arma), buscándola por
el pañuelo rojo; lo que sobra del pelo de siempre alrededor, según la skin (`SOBRA`): teñido del pelo nuevo (el portero),
quitado con lo que sobre del pañuelo (el glotón, calvo y sin pañuelo), quitado solo el pelo, respetando el pañuelo y sus
puntas al viento (el gymbro, calvo con pañuelo), o quitado como en el glotón con un casco (el bombero: el casco va por
detrás de los brazos y las manos, `delante()`, y lo que se sale de la cabeza de siempre solo se pinta donde quede aire;
las bombonas rojas del lanzallamas se miran como si fueran grises, `COMO_GRIS`, porque el rojo lo confundía con la piel
y el pañuelo y la cabeza nueva quedaba detrás de ellas, y lo mismo las verdes del lanza ácido); saca `conserje-48-<arma>-<skin>.png` y `.tres` y los iconos
de la taquilla; con `muestra`, el antes y el después de cada hoja en `captura-cara-<arma>.png`), `hoja_lanza_acido.py` (la
hoja de Johnny con el lanza ácido, `conserje-48-desintegrador`, sacada de la del lanzallamas: cada rojo de las bombonas por su
verde, con el verde del ácido, #c7e04a, en el medio, y la llamita del piloto borrada en cada dibujo, buscándola cerca de la
punta del tubo, con sus chispitas y el naranja con el que encendía la punta, y los huecos que deja en las perneras, de frente,
rellenos; también apunta en el `.tres` (`metadata/puntas`) el labio de abajo de la boquilla de cada dibujo de reposo, de
donde cuelga la gota de `goteo.gd`; con `muestra`, la punta de todos los dibujos antes y después en `captura-lanza-acido.png`; luego, las skins con
`cara.py <skin> desintegrador`), `objetos16.py`
(los 18 objetos a 16×16; el bidón de ácido es el de la gasolina con el rojo cambiado por el verde del ácido), `icono_dosier.py`, `icono_noticias.py`, `icono_colecciones.py` (el álbum de pegatinas de
Colecciones), `recortes_bestiario.py` (escribe en `bestiario.gd` el trozo dibujado de cada retrato), `icono_receta.py` (el papel de las recetas), `icono_lanzallamas.py` (el icono del lanzallamas: un depósito rojo de gas con la válvula gris, un tubo largo de metal gris en diagonal con una empuñadura negra, una manguera negra en bucle y una llamita naranja y amarilla en la punta), `icono_desintegrador.py` (el icono del lanza ácido, el desintegrador por dentro: el del lanzallamas con el depósito verde de ácido y, en vez de la llamita, una gota de ácido que cuelga de la boquilla y otra pequeña que cae), `icono_pistola_electrica.py` (el icono de la pistola eléctrica: un táser azul marino visto de lado, con una batería gris con un borne rojo y un rayito amarillo pegada debajo, dos electrodos metálicos en la boca y un arco de chispas celestes entre ellos), `icono_pistola.py` (el icono de la pistola, que también usa la MP5: una
Beretta 92 de lado, con la corredera larga y el cañón de acero asomando por el hueco de arriba, el puntito rojo, el
guardamonte redondo hueco y la empuñadura inclinada con las cachas de rombos), `zapato_negro.py` (arregla en una hoja de andar ya montada un zapato que PixelLab dibujó relleno de negro con un borde gris claro, solo con Pillow: `py tools/zapato_negro.py <sprite> north 8`; hay que repetirlo si se vuelve a montar la hoja; se hizo para la súper maza, que se quitó el 25 oct, y usa los colores de su hoja), `cientifico_muerto.py` (parte el científico muerto en cuerpo, piel y pelo), `hacer_casillas.py` (marcos de las casillas del HUD), `ver_dibujos.tscn` (foto de los dibujos hechos con
código) y `probar_sonido.gd` (guarda los efectos en `tools/efectos/*.wav`, no van a git).
Música de 8 bits: `motor-8bit.mjs` (ondas de consola, percusión, eco y el .wav en bucle) y las canciones hechas con
él, cada una con su partitura: `el-ultimo-inquilino.mjs` (los menús y explorar), `turno-de-noche.mjs` (peleas) y
`villancico-8bit.mjs` (prueba, no está en el juego).
`node tools/<canción>.mjs` saca el .wav en `tools/efectos/` y `assets/musica/<canción>.ogg` ya a su volumen; con `--veces 4`, además,
el .wav repetido para oír si cansa en bucle.

## docs/ (del juego JS)

`PIXEL_ART.md`, `PIXELLAB.md`, `ZOMBIS.md`, `FONDOS.md`, `MAPA.md`: hablan del JS (`src/…`); valen para las ideas y
los números.
