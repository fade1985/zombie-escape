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

(Se rellena con cada tanda.)
