# Jefes de los Apartamentos (decidido con el dueño, 22 oct 2026)

Hoy en los Apartamentos la portera es la jefa de todas las plantas. Pasan a tener, como el centro comercial
(`docs/CENTRO_COMERCIAL.md`, trozos 2 y 6), **cuatro minijefes al azar** y **un jefe final en la azotea**.

## Lo decidido

- **Minijefes:** portera, Glotón, Gymbro y jefe de bomberos. **Uno por planta, en orden al azar en cada partida y
  sin repetir** (como `minijefes` del centro en `edificios.gd`). Tamaño de zombi grande (lienzo de 72), como los del
  centro. Lo común ya está en `scripts/minijefe.gd` (aparece al entrar, barra grande, +25 % de vida por planta, se
  enfada a media vida, botín y mutación al caer). Desde el M3 (23 oct 2026), todos salen en medio de su sala y con
  su presentación: zoom de la cámara, grito y nombre en pantalla (`scripts/ui/presentacion.gd`).
- **Jefe final, siempre en la azotea:** el científico jefe. **Más grande de lo normal, como el gerente** (lienzo de 128,
  unos 117 px) y con **dos fases: en la segunda se transforma** (como el gerente con la jeringa).
- Mientras un jefe no esté hecho, en su sitio sale la portera (como en el centro).
- **Una sesión por jefe.** En PixelLab, decir el coste antes de generar. Los números son provisionales: se ajustan
  jugando. Si hay que cambiar algo del diseño, se cambia después.
- Las marcas, fuera: nada de logos, rayas ni nombres de marcas reales en la ropa.

## 1. El Glotón (minijefe; diseño del dueño)

**Aspecto:** grotesco y lento, va **a gatas**. Calzoncillos sucios, camiseta interior sin mangas sucia y calcetines
sucios. La **cabeza tan grande o más que el cuerpo**, llena de **ampollas de ácido** a punto de reventar. **Boca
gigante con varias filas de dientes** y **lenguas como látigos** que le salen de ella.

**Fase 1**
- Lento: la cabeza le pesa más que el cuerpo.
- Latigazos con las lenguas: hacen daño si te alcanzan.
- Durante **5 s** intenta aspirarte para comerte; si te alcanza, mucho daño.
- Cada golpe o disparo que le das salpica sangre ácida: **1 % de daño** a Johnny.

**Fase 2**
- El doble de lenguas.
- El doble de fuerza al aspirar.
- La sangre ácida, **2 %** por golpe.

*Nota de Claude:* con armas rápidas (MP5) el salpicón suma mucho; quizá uno cada medio segundo como mucho.

### ✅ Hecho (22 oct 2026): el Glotón y el sorteo, con el visto bueno del dueño

- **El sorteo:** `minijefes: ["portera", "gloton", "gymbro", "bombero"]` en la ficha `apartamentos` de `edificios.gd`
  y sus nombres en `MINIJEFES` (sin tienda: en los Apartamentos el piso del jefe se llama como siempre, «2ºC»).
  Donde toca uno sin hacer (Gymbro, bombero) sale la portera, y en la 4ª planta también (hasta que haya azotea).
  En `--captura` sin `--jefe`, la portera va en la planta baja; con `--jefe gloton`, él en la 1ª.
- **El Glotón** (`scripts/gloton.gd`, `escenas/personajes/gloton.tscn`). Los números que han quedado (provisionales,
  se ajustan jugando): vida 480 (+25 % por planta), velocidad 55, 8 por contacto.
  - *Latigazo:* si te ve a menos de 280, aviso de 0,6 s (franjas rojas) y 3 lenguas en abanico (separadas 0,4 rad,
    250 de largo): 16 de daño y empujón. Cada 2,4 s. Las lenguas largas las dibuja el código por encima de él.
  - *Aspirar:* si te ve a entre 90 y 420, grita «¡HAMBRE!», 0,8 s de aviso con el cono verde en el suelo (±0,85 rad)
    y 5 s tirando de ti hacia la boca (te suma 120 de velocidad hacia él; andando hacia atrás se resiste, esquivando
    no tira y con una pared en medio tampoco), mientras se va girando hacia ti (2 rad/s). Si llegas a su boca te
    come: 30 de daño, te escupe lejos y te deja tirado. Cada 10 s.
  - *Sangre ácida:* cada golpe o bala que le das te quita el 1 % de la vida máxima (mínimo 1), uno cada 0,5 s como
    mucho, con gotas verdes y su chisporroteo.
  - Una granada (explosión) le corta lo que esté haciendo (0,6 s tambaleándose): así se para el aspirado.
  - *Enfadado* («¡TENGO HAMBRE!»): 6 lenguas (separadas 0,27 rad), tira el doble (240), ácido al 2 %, latigazo cada
    1,6 s y aspira cada 7 s.
- **Dibujo:** modelo a 72 y 5 animaciones en PixelLab (46 generaciones; detalle y textos en `assets/pixellab.json` →
  `apartamentos-jefes` → `gloton-72`). Hoja con `py tools/jefe_hoja.py gloton-72 jefe-gloton`.
- Tecla de prueba **7** (los demás minijefes de los Apartamentos irán en 8, 9...); sale en la exposición (F9,
  alargada 5 casillas) y en el bestiario («El Glotón», 18 fichas). `--captura --jefe gloton` comprueba la sangre
  ácida y el aspirado (lo escribe en la terminal) y saca `captura-jefe.png` con el latigazo.
- Pegas conocidas: el andar a gatas es sutil (más balanceo que paso); de espaldas, el latigazo enseña una lengua por
  encima de la cabeza.

### ✅ Hecho (22 oct 2026, M2 de `PENDIENTES.md`): su habitación

- **Sin más muebles que 3 o 4 lámparas de pie** (`catalogo.gd`, `jefe-gloton`; `planta.gd` pone `apt.tipo`): el dueño
  las quiso dejar para que haya luz además de la linterna. En su lugar, **su porquería**: un peligro como los de las
  tiendas (`scripts/peligros/porqueria.gd`; los números en `Peligros.PORQUERIA`), decidido al generar la planta
  (`Peligros.del_gloton`) y que sigue igual al volver.
  - **El suelo:** una **franja pegada a las paredes** que cubre cerca de un 45 % de la habitación, y en medio una
    **elipse limpia, la zona de pelea** (el dueño, 23 oct: que no se pueda rodear al Glotón bordeando la habitación y
    haya que luchar cerca de él); la elipse es perfecta y siempre igual, como un ring (el dueño, 23 oct: sin nada al
    azar, como el fuego del bombero; lo que cambia de una partida a otra es dónde caen los montones). Un montón de
    mierda en un 22 % de las casillas sucias. De la puerta de entrada a la elipse, un **pasillo limpio** (ahí
    aparece Johnny): el hueco de delante de la puerta y, del mismo ancho (unas 5 casillas), un pasillo hacia el centro
    de la sala; con la puerta en medio de la pared cae dentro del hueco y cerca de una esquina, donde la franja es más
    gruesa, sale en diagonal (el dueño, 23 oct: con la puerta en una esquina el hueco solo no llegaba a la elipse y
    había que pisar porquería para entrar; `Peligros.acceso`). Dibujado
    a cuadraditos como el fuego de la cocina, con burbujas de ácido que revientan y moscas sobre los montones.
    **Las paredes:** la de arriba con salpicaduras que gotean (texturas hechas con código, como adornos de
    las caras de muro) y los lomos de las otras tres, que se ven desde arriba, con pegotes en un 40 % de sus casillas.
    Y el ácido **reluce** con 8 luces verdosas suaves que laten, repartidas por el borde de la elipse.
  - **Quema:** estado `porqueria` (`estados.gd`), **7 de vida por segundo** pisándola y 1 s de escozor al salir, con
    gotas marrones; la esquiva la cruza sin daño, como los charcos. A los zombis (y a él) no les hace nada. Al entrar,
    el aviso «¡Qué peste! El suelo está lleno de mierda con ácido: no la pises».
  - Prueba: `--captura --jefe gloton --porqueria` (`captura-porqueria.png` y `captura-porqueria-medio.png`).

## 2. El Gymbro (minijefe; diseño del dueño)

**Aspecto:** muy musculoso, con **cuádriceps y manos gigantes** comparados con el resto del cuerpo; **arrastra las
manos** por el suelo de lo grandes que son. Calvo y con barba, **la piel se le cae a cachos**. Torso desnudo,
pantalón de chándal y zapatillas deportivas de estilo clásico, **sin marca ni rayas**.

**Fase 1**
- Embiste con los brazos abiertos, formando un torbellino a su paso.
- Salta e intenta caer encima de Johnny.
- Lanza pesas como proyectiles.

**Fase 2**
- Se toma unos suplementos: **barra de armadura** (encima de la de vida); mientras dure, solo le entra el **50 %**
  del daño.
- Hasta **2 torbellinos seguidos**.
- El salto dura la mitad.
- El doble de pesas.

### ✅ Hecho (22 oct 2026): el Gymbro, con el visto bueno del dueño

- **El Gymbro** (`scripts/gymbro.gd`, `escenas/personajes/gymbro.tscn`; las pesas, `scripts/pesa.gd`). Ya sale en el
  sorteo (no la portera en su lugar). Los números que han quedado (provisionales, se ajustan jugando): vida 540 (+25 %
  por planta), velocidad 75, 10 por contacto.
  - *Torbellino:* si está a entre 90 y 460, franja roja tan ancha como sus brazos (0,7 s) y sale girando en línea
    recta a 400 durante 1,1 s: 20 de daño, manotazo hacia un lado y te tira (esquivando, pasa de largo). Si se come
    una pared, mareado 1,6 s con estrellitas. Cada 3,6 s.
  - *Salto:* a entre 120 y 450, se agacha 0,45 s y está 1,1 s en el aire (no se le puede dar) con la sombra donde va
    a caer: 24 de daño en un círculo de 100 y te tira. Cada 5 s.
  - *Pesas:* a más de 160, 2 mancuernas en curva (0,9 s), una a donde estás y otra a donde vas a estar, cada una con
    su círculo rojo: 18 de daño y empujón. Se quedan 3 s tiradas. Cada 4,2 s.
  - *Enfadado* («¡HORA DE LOS SUPLEMENTOS!»): armadura del 30 % de su vida máxima, con su barra azul acero encima de
    la de vida (`armadura_jefe()` en `partida.gd`) y un brillo azul alrededor; cada golpe va mitad a la vida y mitad
    a la armadura hasta que se acaba («¡SIN SUPLEMENTOS!»). Además: 2 torbellinos seguidos (el segundo con menos
    aviso), salto de 0,55 s, 4 pesas (las otras dos, alrededor de Johnny) y todo más seguido (torbellino 2,8 s,
    salto 3,5 s, pesas 3 s).
- **Dibujo:** modelo a 72 y 6 animaciones en PixelLab (46 generaciones; detalle y textos en `assets/pixellab.json` →
  `apartamentos-jefes` → `gymbro-72`). El torbellino solo de frente (es una vuelta entera); hacia el oeste, andar,
  golpe y muerte son los del este en espejo. Hoja con `py tools/jefe_hoja.py gymbro-72 jefe-gymbro`.
- Tecla de prueba **8**; sale en la exposición (F9, alargada otras 5 casillas) y en el bestiario («El Gymbro», 19
  fichas). `--captura --jefe gymbro` comprueba la armadura y las pesas (lo escribe en la terminal) y saca
  `captura-jefe.png` con el torbellino.
- **Su habitación, un gimnasio** (23 oct, M6 de `PENDIENTES.md`): las paredes llenas de máquinas, una detrás de otra
  (`jefe-gymbro` en `catalogo.gd`, `llenar` en `muebles.gd`): cinta de correr, banco de press, máquina de poleas,
  estante de mancuernas, pila de discos, taquillas y bancos, y 3 lámparas de pie. Las máquinas cuentan como pared
  para el torbellino. Por el suelo, 12 mancuernas (`peligros/tropiezos.gd`): al pisarlas, Johnny se cae 2 s sin poder
  moverse, atacar ni rodar (no quita vida) y la mancuerna sale rodando; rodando se pasan sin caer. Al Gymbro y a los
  zombis no les hacen nada. Prueba: `--captura --jefe gymbro --gimnasio`.

## 3. El jefe de bomberos (minijefe; aspecto de Claude, con visto bueno)

**Aspecto:** grande y ancho, con el **traje ignífugo chamuscado y abierto por el pecho**, que deja ver brasas por
dentro, como si ardiera por dentro. **Casco con la visera rota que echa humo**, la botella de oxígeno de la espalda
hecha **depósito de gasolina** y una **manguera que escupe fuego** en vez de agua. Por las grietas de la piel asoma
la lumbre.

**Fase 1**
- El traje lo protege: **el fuego no le hace nada** (molotov, lanzallamas, bate de fuego...), así que obliga a
  cambiar de arma.
- Bolas de fuego: daño al dar y daño con el tiempo.
- Se pone en el centro de la sala y **gira con el lanzallamas**: daño al dar y con el tiempo.
- Molotovs que dejan charcos de fuego: daño al entrar y con el tiempo.
- **Hachazo de bombero** si Johnny se le pega (para que pegarle de cerca no salga gratis).

**Fase 2**
- El doble de bolas de fuego, de lenguas de fuego en el giro y de charcos.
- **Se le rompe el traje y entra en llamas:** deja un rastro de fuego al andar.

### ✅ Hecho (22 oct 2026): el jefe de bomberos, con el visto bueno del dueño

- **El jefe de bomberos** (`scripts/bombero.gd`, `escenas/personajes/bombero.tscn`; las bolas de fuego,
  `scripts/bola_fuego.gd`). Ya sale en el sorteo (no la portera en su lugar). Los números que han quedado
  (provisionales, se ajustan jugando): vida 560 (+25 % por planta), velocidad 70, 10 por contacto.
  - *Inmune al fuego:* el molotov (ni el fogonazo ni el charco), el lanzallamas y el súpersoplete, el fuego del bate
    de fuego y el aceite ardiendo no le quitan nada; grita «¡INMUNE!». Los golpes, las balas y las explosiones, sí.
    Por dentro: `inmune_fuego` en el jefe, que miran `proyectil.gd` y `armas_creadas.gd`; los charcos de fuego le
    llaman a `prender()`, que aquí no hace nada.
  - *Bolas de fuego:* si estás a más de 100, una bola recta a 340 (dibujada con código, con su luz y chispas): 14 de
    daño y te deja ardiendo 1,5 s (8 por segundo). Se para en paredes y muebles. Cada 2,8 s.
  - *Giro con el lanzallamas* (rehecho el 23 oct, M8 de `PENDIENTES.md`): si estás a menos de 440, grita «¡A ARDER!»,
    se va al centro de la sala en la que está (hasta 5 s) y avisa 1 s: la franja roja por donde empieza, apuntándote,
    y dos anillos de flechas rojas en el suelo que dicen hacia qué lado va a girar (cada giro, uno al azar). Luego da
    algo más de una vuelta entera, 6,6 s a 1 rad/s (una vuelta en 6,3 s), con una lengua de fuego que **llega siempre
    hasta la pared** (atraviesa los muebles) y mide 60 de ancho (más estrecha al salir de la manguera): 10 de daño y
    ardes 1,5 s (10 por segundo), **también rodando** (la voltereta no la cruza); a los demás zombis los prende. Como
    la sala arde por el borde, **solo se libra quien corre delante de la lengua, en su mismo sentido**: a tope de vida,
    a unas 6 casillas del jefe se le sigue el paso (con poca vida, Johnny anda más lento y tiene que arrimarse más);
    corriendo en contra o quieto, te alcanza. Cada 15 s. Una explosión (granada) se lo corta (0,7 s tambaleándose).
  - *Su habitación, en llamas* (M8): «Apartamento en llamas», sin muebles (`jefe-bombero` del catálogo) y con todo el
    borde ardiendo (`peligros/cerco.gd`, `Peligros.del_bombero`), **una elipse fija, como un ring** (el dueño, 23
    oct): en medio, una elipse limpia perfecta donde se pelea, siempre igual (sin nada al azar), y todo lo de fuera
    ardiendo hasta la pared, cerca de un 45 % de la habitación (se reparte igual que la porquería del Glotón);
    el pasillo de la puerta de entrada a la elipse no arde (el mismo que el de la porquería del Glotón, hacia el
    centro de la sala, en diagonal si la puerta cae cerca de una esquina). No se apaga: quema como el fuego de
    la cocina (12 por segundo y 2 s más al salir; rodando se cruza, como los charcos) y prende a los zombis; al
    bombero no le hace nada. Da la luz de la sala (10 luces de fuego repartidas por el borde de la elipse).
  - *Molotovs:* a entre 140 y 520, uno en curva (0,9 s) a donde estás, con su marca roja en el suelo
    (`proyectil.gd`, tipo `molotov_jefe`): 6 si te pilla al caer y un charco de fuego algo más pequeño que el de
    Johnny (`charco.gd`, 4 s): 12 por segundo dentro y 2 s más al salir. Cada 4,6 s.
  - *Hachazo:* si te le pegas (a menos de 64 + tu radio), levanta el hacha 0,4 s (arco rojo en el suelo) y la baja:
    22 de daño y empujón (esquivando, nada; si falla, clava el hacha en el suelo). Cada 1,6 s.
  - *Enfadado* («¡TODO ARDE!»): se le rompe el traje y arde él mismo (llamas encima, `llamas.gd`): deja un rastro de
    fuego al andar (un charco pequeño, del 35 %, de 2 s, cada 44 unidades). Además: 2 bolas (la segunda a donde vas
    a estar), 2 lenguas de fuego opuestas en el giro (hay que correr entre las dos, a su paso: si vas más deprisa te
    comes la de delante y si vas más despacio te alcanza la de detrás), 2 molotovs (el segundo a donde vas a estar),
    todo más seguido (bolas 1,9 s, giro 12 s, molotovs 3,2 s) y el primer giro enfadado a los 2 s como mucho.
- **Dibujo:** modelo a 72 y 6 animaciones en PixelLab (42 generaciones; detalle y textos en `assets/pixellab.json` →
  `apartamentos-jefes` → `bombero-72`). El giro solo de frente (es una vuelta entera: el juego elige el fotograma
  según hacia dónde apunta la lengua); hacia el oeste, todo es el este en espejo (`tools/espejo_oeste.py`). Hoja con
  `py tools/jefe_hoja.py bombero-72 jefe-bombero`. Las lenguas, las bolas, los molotovs y los avisos salen con código.
- Tecla de prueba **9**; sale en la exposición (F9, alargada otras 5 casillas) y en el bestiario («El jefe de bomberos»,
  20 fichas). `--captura --jefe bombero` comprueba la inmunidad (lanzallamas, molotov y charco), un golpe normal, las
  bolas y los molotovs (lo escribe en la terminal) y saca `captura-jefe.png` con el giro. `--captura --jefe bombero
  --llamas` prueba su habitación en llamas y el giro: que arde todo el borde menos el pasillo de la puerta, que en medio
  queda la elipse limpia perfecta (igual con otra semilla), que de la puerta se llega al centro sin pisar el fuego,
  esté donde esté la puerta, que la lengua llega a la pared y que corriendo en su
  sentido no te quema, pero en contra, rodando o (enfadado) fuera del hueco entre las dos lenguas, sí (ver
  `docs/CONTROLES.md`).
- Pegas conocidas: el andar y el golpe (tambaleo) son sutiles; al lanzar de frente PixelLab pintó una bola de fuego
  pegada al cuerpo (queda como el fogonazo del lanzamiento).

## 4. El científico jefe (jefe final de la azotea; de Claude, con visto bueno)

Grande como el gerente (lienzo de 128). Encaja con la historia de Velaria (`docs/CENTRO_COMERCIAL.md`): es quien
estaba detrás de lo que pasa en el edificio.

**Fase 1: el científico.** Bata blanca manchada, gafas de laboratorio y una jeringa enorme. Rápido, no pega de cerca:
- Lanza **probetas** que dejan charcos de colores: ácido, veneno y uno que resbala (los estados ya existen).
- **Inyecta suero a los zombis** de la azotea y los hace más fuertes.
- Se esconde tras una **cúpula de cristal** que hay que romper.

**Transformación** (a media vida): se pincha a sí mismo; se le revienta la bata y crece (como la mutación del
gerente: fogonazo, temblor y rugido).

**Fase 2: la criatura.** Una masa enorme hecha con trozos de los otros jefes (**la boca del Glotón, los brazos del
Gymbro y el fuego del bombero**), como si fuera él quien los hubiera creado. Ataques que los recuerdan:
lenguas-látigo, puñetazos al suelo con onda expansiva y escupitajos de fuego.

### ✅ Hecho (22 oct 2026): la azotea y el científico jefe, con el visto bueno del dueño

- **La azotea de los Apartamentos** (commit `76f6bfad`): la 5ª planta ya es la azotea, como en el centro (`azotea`,
  `final` y `el_final` en su ficha de `edificios.gd`; `planta.gd` pone los aparatos de cada edificio, `APARATOS`):
  depósitos de agua, antenas y tendederos nuevos (PixelLab, 3 generaciones con las guías de
  `py tools/guias_azotea.py apartamentos`; en `catalogo.gd`, `watertank`, `antennas` y `clothesline`) más chimeneas y
  extractores. La última página del dosier («Sujeto 0», `vd7_sujeto_cero` en `historia.gd`) ya no la lleva un
  muerto: la suelta el doctor Salas al caer, y luego llega el helicóptero de Velaria, como con el gerente.
- **El doctor Salas** (`scripts/cientifico_jefe.gd`, `escenas/personajes/cientifico_jefe.tscn`; hereda de
  `minijefe.gd`, con la receta de la jeringa y la mutación del gerente). Vida 1500 justa (sin el 25 % por planta),
  8 por contacto; la barra dice «El doctor Salas». Los números que han quedado (provisionales, se ajustan jugando):
  - *A distancia:* velocidad 95; a más de 430 se acerca y a menos de 220 se aleja (por el mapa de navegación: contra
    el murete, de lado).
  - *Probetas:* a menos de 540, tres de golpe (ácido, veneno y aceite, que resbala: tipos `probeta_*` de
    `proyectil.gd`, dibujadas con código) en curva de 0,85 s, con aviso de 0,55 s (anillos rojos de 50 donde caen: a
    ti, a donde vas y alrededor); 6 al caer (el aceite, 0) y los charcos de siempre (`charco.gd`). Cada 3 s.
  - *Sujetos:* si queda como mucho 1 zombi, levanta la jeringa («¡MÁS SUJETOS!», 1,2 s) y llegan un vecino, un
    rápido y un venenoso, repartidos a su alrededor. Cada 14 s.
  - *Suero:* si hay zombis sin inyectar a menos de 480, levanta la jeringa («¡DOSIS DOBLE!») y lanza un rayo verde a
    los 3 más cercanos: vida máxima ×1,6 (y se les suma), velocidad ×1,3 (también en su agente de navegación), +6 de
    daño y se ven verdes. Cada 9 s.
  - *Cúpula:* cada 14 s, si ya le han hecho daño (vida por debajo del 92 %), sube una cúpula de cristal (0,4 s) y se
    queda dentro hasta 7 s: los golpes se los lleva la cúpula (140; `danar()` devuelve 0; se ve en la barra azul fina
    de «armadura» de `partida.gd`), no hace daño por contacto y desde dentro tira 2 probetas cada 1,6 s. Al
    rompérsela: cristales, «¡MI CÚPULA!» y 0,9 s tambaleándose (ahí se le da bien). Su propio fuego (el aceite al
    secarse) no le quema: `charco.gd` le pasa el `dueno` al charco de fuego.
  - *A media vida* («¡AÚN NO HE TERMINADO!»): baja la cúpula si la tiene, te aparta, se pincha (2,6 s, sin que se le
    pueda dar) y muta (1,3 s): fogonazo verde, temblor, rugido y trozos de la bata. Antes no puede caer (se queda
    con 1).
- **La criatura** (otra hoja, `jefe-criatura`; radio 48, 14 por contacto, velocidad 100; se apunta en el bestiario
  al mutar):
  - *Lenguas-látigo:* a menos de 350, tres franjas rojas en abanico (±0,4 rad, 330 de largo, 0,65 s) y las lenguas
    (con código, desde la boca): 18 y empujón. Cada 2,2 s.
  - *Puñetazo al suelo:* a menos de 240, un círculo rojo de 210 (0,75 s) y la onda, que crece 0,4 s: 24, empujón y
    te tira al suelo; si estás esquivando cuando te pasa, nada. Cada 3,2 s.
  - *Escupitajos de fuego:* a más de 230 y a la vista, tres rayas rojas (0,5 s) y tres bolas de fuego en abanico
    (`bola_fuego.gd`: 12 y ardes 1,5 s). Cada 3,6 s.
  - Al caer: la página del «Sujeto 0» y el helicóptero (`fin_del_edificio()` de `partida.gd`).
- **Dibujo:** el científico a 128 (117 px; 8 generaciones el modelo y 13 las animaciones: andar y probetas en 5
  direcciones, con el oeste en espejo con `py tools/espejo_oeste.py --lado`; suero y jeringa solo de frente) y la
  criatura a 128 (8 el modelo y 25 las animaciones: andar, lenguas, puñetazo, escupir y muerte en 5 direcciones, el
  oeste en espejo). Con la azotea, 57 generaciones. Hojas con `py tools/jefe_hoja.py cientifico-jefe-128 jefe-cientifico`
  y `criatura-128 jefe-criatura`; detalle y textos en `assets/pixellab.json` → `apartamentos-jefes`. Las probetas, el
  rayo del suero, la cúpula, las lenguas, la onda y las bolas salen con código.
- Tecla de prueba **0** (la N también lleva derecho a la azotea); sale en la exposición (F9, alargada otras 8
  casillas) y en el bestiario («El doctor Salas» y «La criatura», 22 fichas). `--captura` (Apartamentos) acaba en la
  azotea y comprueba probetas, cúpula, suero, jeringa, mutación, lenguas, puñetazo, fuego, la página y el
  helicóptero (`captura-cientifico*.png` y `captura-criatura*.png`).
- Pegas conocidas: el andar de frente (del científico y de la criatura) es sobre todo balanceo; de frente, a las
  probetas se les quitaron dos fotogramas en los que la probeta se veía enorme al venir hacia la cámara.

## Orden de trabajo (una sesión cada uno)

1. ✅ **Glotón**, y de paso el sorteo de minijefes en los Apartamentos (`minijefes` en su ficha de `edificios.gd`;
   donde toque uno sin hacer, la portera). Hecho el 22 oct.
2. ✅ **Gymbro.** Hecho el 22 oct.
3. ✅ **Jefe de bomberos.** Hecho el 22 oct.
4. ✅ **Científico jefe**, y de paso la azotea en los Apartamentos (`azotea` y `final` en su ficha, como el centro).
   Hecho el 22 oct.

Cada uno: modelo en PixelLab (coste antes) → visto bueno del aspecto → animaciones → su script (hereda de
`minijefe.gd`) → ficha del bestiario → prueba → visto bueno del dueño → commit y push solo de sus archivos.
