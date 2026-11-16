# El jugador automático (el bot)

Un Johnny que juega solo para medir lo difícil que es el juego sin necesitar a gente que lo pruebe. No sustituye a
las personas: dice si algo es **difícil o fácil** y encuentra **fallos y atascos**, pero no si es **divertido**.

## Cómo se lanza

```bash
py tools/bot.py
```

Por defecto juega los tres edificios: 8 peleas con cada jefe y nivel, unas 360 peleas, alrededor de hora y media.
Abre una ventana del juego que va a toda prisa (no hace falta mirarla). Al acabar escribe la tabla del resumen en la
terminal y en `capturas/bot/resumen-<semilla>.md`. Cada pelea queda en `capturas/bot/jefes-<edificio>-<semilla>.jsonl`.

Opciones útiles:

```bash
py tools/bot.py --peleas 3 --edificios apartamentos --jefes portera,gloton
py tools/bot.py --niveles novato
py tools/bot.py --resumen 1611
```

La última vuelve a hacer el resumen de una tanda ya jugada, sin jugar.

Para ver cómo juega, una pelea con fotos cada 3 segundos (salen en `capturas/bot-<jefe>-<nivel>-<s>.png`):

```bash
"C:\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path . --fixed-fps 60 -- --captura --bot-jefes --jefes gloton --niveles bueno --peleas 1 --fotos-bot
```

No lances el bot a la vez que otra prueba `--captura`: comparten el guardado de prueba y se pisan.

## Cómo juega

Lo hace `scripts/pruebas/bot.gd`. No toca el juego: pulsa los mismos botones que una persona.

- **Ve lo mismo que una persona:**
  - los avisos de los ataques de los jefes (las franjas, los abanicos y las barras del suelo);
  - las balas y lo que le lanzan;
  - los charcos y los peligros del suelo (la porquería del Glotón, el cerco de fuego del bombero…);
  - los zombis.
- **Elige hacia dónde moverse** varias veces por segundo. Prueba 16 direcciones y se queda con la menos peligrosa.
  Mientras tanto, se mantiene a buena distancia del jefe, lo rodea hacia un lado y, si está en peligro, a veces hace la
  esquiva.
- **Apunta al jefe y dispara** (o al zombi más cercano si no ve al jefe). Cada tiro se desvía un poco a propósito, y le
  tira los molotovs y las granadas.
- **Tres niveles:**

| | Reacciona en | Desvío del tiro | Ve los avisos | Ve las balas | Esquiva | Tira lanzables |
|---|---|---|---|---|---|---|
| novato | 0,45 s | 14° | 45 % | 35 % | 20 % | 25 % |
| normal | 0,25 s | 7° | 75 % | 65 % | 50 % | 60 % |
| bueno | 0,12 s | 3° | 95 % | 90 % | 85 % | 90 % |

Las cifras de la tabla están en `NIVELES`, al principio de `bot.gd`, y se pueden cambiar. «Reacciona en» significa que
ve al jefe donde estaba hace ese rato y que tarda ese rato en enterarse de un aviso. «Ve los avisos» es la probabilidad
de darse cuenta de cada uno.

## Fase 1: las peleas contra los jefes

Lo hace `scripts/pruebas/prueba_bot.gd` (`--bot-jefes`). Cómo es cada pelea:

- **Johnny recién empezado:** la pistola y la fregona, 2 molotovs y 2 granadas, sin talentos ni mutaciones.
- **Munición de sobra:** 300 balas, para medir la pelea y no lo que se recoge antes por la planta.
- **Va solo,** sin el rescatado que acompaña.
- **El jefe está en la planta que le toca en el sorteo**, así que unas veces es más fuerte que otras (sube con la
  planta). La planta queda apuntada en cada pelea.
- **Para que no se caiga de verdad**, Johnny pelea con muchísima vida y la que tendría se lleva aparte. Cuando llega a 0,
  la pelea está perdida. Los tercios que pierde sí se le quitan, así que anda más despacio, como en el juego.
- **Si la pelea dura más de 3 minutos,** se da por no acabada.

Lo que todavía no hace: usar los bidones contra el jefe, curarse, cambiar de arma a propósito ni recoger cosas.

## Fase 2: partidas enteras

```bash
py tools/bot.py --partidas 6 --edificios apartamentos
```

Lo hace `scripts/pruebas/prueba_bot.gd` (`--bot-partida`). El bot juega una partida de verdad desde la sala de
mantenimiento, como una persona:

1. Sale al pasillo.
2. Entra en cada apartamento sin limpiar (el más cercano primero) y va a por los zombis, también los dormidos.
3. Recoge la llave cuando cae.
4. Abre la puerta del jefe, lo mata y elige una de las dos mutaciones al azar.
5. Sube por las escaleras… hasta que muere, acaba el edificio o se atasca.

Cómo es cada partida:

- Johnny empieza como en las peleas de los jefes, pero con **su munición y su vida de verdad**, y se cura con las vendas
  y el botiquín que encuentre.
- Las páginas, la tele y los tutoriales, si salen, los cierra.
- Cada partida tiene **su propio guardado** (`guardado-bot-<semilla>`), así que se puede jugar a la vez que otra prueba.
- **Si se queda 20 s sin moverse ni pelear**, saca una foto (`capturas/bot/atasco-…png`) y lo apunta. Al tercer atasco,
  deja la partida.

Lo apunta todo en `capturas/bot/partida-<edificio>-<nivel>-<semilla>.jsonl`, planta a planta:

- lo que tarda;
- la vida con la que llega al jefe;
- quién le quita vida;
- de qué muere.

`tools/bot.py --partidas N` lo resume en `capturas/bot/resumen-partidas-<semilla>.md`.

Lo que todavía no hace:
- **Torre Velaria:** no lee los terminales del código, así que se queda sin abrir la puerta del jefe.
- No usa los muebles, la tienda ni el ordenador.
- No compra talentos entre partida y partida. Eso es la fase 3: cuántas partidas hacen falta para pasarse un edificio.

## Resultados

### Primera tanda (16 nov 2026)

Los números exactos están en `capturas/bot/resumen-1611.md` (fase 1) y `resumen-partidas-500.md` / `-600.md`
(fase 2). Esa carpeta no va en git, así que lo importante se copia aquí.

Cómo leerlo: el bot es **un jugador que empieza de cero**, sin talentos, sin la tienda y sin mutaciones. No dice si
el juego está bien de dificultad para quien ya ha jugado varias partidas; dice **qué se encuentra alguien la primera
vez** y **qué jefes se salen de lo normal**.

#### 1. La portera es un muro para quien empieza (lo más importante)

En las partidas enteras (fase 2), **las 31 partidas acaban en la planta 1**, contra la portera, con los tres niveles.
No pasa ninguna.

- **Johnny llega bien de vida** (74–97 de 100). La planta no le cuesta.
- **Llega con pocas balas para ella:** 72–104 de media. La portera tiene 600 de vida y la pistola quita 10, así que
  hacen falta **60 balas acertando todas**, y además salen sus rápidos.
- **Se queda sin balas a mitad de pelea** y acaba con la fregona, de 19 a 52 s de media, hasta que muere.
- **Con munición de sobra (fase 1), el mismo bot la gana 8 de 8** (normal y bueno) en unos 30 s.

Qué quiere decir: **lo que decide la pelea es la munición, no la habilidad.** Ideas para que lo decidas tú (no he
tocado nada):

- más balas en la planta 1, o unas cuantas en el cuarto del jefe;
- la portera con menos vida (por ejemplo, 400);
- que la fregona sea más útil contra ella.

Ojo: un jugador de verdad puede que apunte mejor o pegue mejor con la fregona que el bot. Merece la pena que lo pruebes
tú con un guardado nuevo y cuentes las balas.

#### 2. Los jefes, uno a uno (fase 1, con munición de sobra)

Cada jefe salió en la planta que le tocó en el sorteo, y **cada planta lo hace un 35 % más duro** (y el Centro un 30 % y
la Torre un 60 % más que los Apartamentos). Por eso los de las plantas 1 y 2 se ganan y los demás no: es lo esperado
para un Johnny sin mutaciones.

Gana el bot **bueno** (de 8 peleas):

| Apartamentos | | Centro | | Torre | |
|---|---|---|---|---|---|
| Portera (p1) | 8 | Modista (p1) | 8 | Becario (p1) | 8 |
| Gymbro (p2) | 8 | Antidisturbios (p2) | 3 | Informático (p2) | 0 |
| Glotón (p3) | 0 | Mascota (p3) | 0 | Presentador (p3) | 1 |
| Bombero (p4) | 0 | Cocinero (p4) | 8 | Directora (p4) | 0 |
| Doctor Salas (final) | 0 | Gerente (final) | 0 | Sujeto 1 (final) | 0 |

Lo que se sale de lo normal:

- **Cocinero, demasiado fácil:** en la planta 4 lo gana 8 de 8, y el bot normal 5 de 8.
- **Informático, muy difícil para su planta:** en la planta 2, 0 de 8. Todo el daño es suyo, no de sus vecinos.
- **Mascota:** el 70–80 % del daño se lo hacen sus crías (los rápidos), no ella.
- **Antidisturbios:** el 70–95 % del daño es de los vigilantes que llama.
- **Bombero:** el 55–73 % es del fuego del suelo.
- **Glotón:** la porquería hace un 20–36 %. Las veces que pierde, el Glotón se queda con un 30 % de vida.
- **Directora:** la mitad del daño es de los oficinistas.
- **Los tres finales:** no los gana nunca, ni el bueno. Les deja un 58–70 % de vida.

#### 3. Atascos (fallos del bot o del mapa, por revisar)

En la fase 2 el bot se quedó atascado 15 veces, sobre todo el bueno, porque es el que más va a por todos los zombis.
Las fotos están en `capturas/bot/atasco-*.png`. Se repiten sitios con semillas distintas:

- **Bajo C, la puerta de arriba del pasillo interior,** con Johnny en (1216–1225, 381–385) y queriendo ir unos 90 px
  hacia arriba. Pasó con las semillas 12 y 603.
- **Un pasillo con un armario marcado en amarillo debajo,** con Johnny en (526–570, 546) y queriendo ir unos 100 px
  hacia abajo (semillas 500 y 600). En la foto Johnny está pegado a la pared, encima del armario.

Lo más probable es que **el camino del bot pase por donde Johnny no cabe** (una puerta o un mueble); es decir, que el
fallo sea del bot. Pero si un zombi se queda en un sitio al que no se puede llegar, el apartamento no se limpia y
también le pasaría a una persona. Merece la pena mirarlo.

#### 4. Fallos del bot que hay que tener en cuenta

- **Sus propias granadas** le hacen hasta un 23 % del daño (Becario). Una persona lanzaría mejor.
- **Con la fregona pelea mal:** quiere acercarse para pegar, pero a la vez huye de estar pegado al jefe, así que pega
  poco. Eso empeora lo de la portera (punto 1).
- No usa los bidones, no cambia de arma a propósito, no compra en la tienda.

### Siguientes pasos

1. **Probar la portera tú** con un guardado nuevo, contando las balas, para ver si el muro es del juego o del bot.
2. **Fase 3:** que el bot compre talentos entre partidas y medir **cuántas partidas hacen falta** para pasarse cada
   edificio, que es lo que de verdad dice si el juego es largo o corto.
3. **Torre Velaria:** enseñar al bot a leer los terminales del código.
4. **Calibrar el bot contigo:** juegas tú un par de peleas, se comparan los números, y se ajusta qué nivel de bot se
   parece a ti.
