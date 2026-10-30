# Lanzamiento · qué le falta al juego para venderlo

Lista escrita el 23 de octubre de 2026, cuando el juego ya tenía dos edificios, jefes con presentación, logros,
bestiario, dosier, reto del día, trajes, pantalla de opciones con cambio de teclas y el final del helicóptero.
Es la foto de **todo lo que hay que hacer cuando el juego esté pulido**, para no olvidarlo. No es una lista de
tareas en marcha: se retoma cuando el dueño lo diga, y entonces se decide el orden.

Lo que falta no es tanto "más juego" como lo que convierte un proyecto en un producto. Si hubiera que elegir por
dónde empezar: **nombre, versión de Windows e inglés**, porque todo lo demás depende de esos tres. Después, las
pruebas con desconocidos; con lo que salga de ahí, la página de Steam.

## 1. Lo que impide venderlo hoy

- [ ] **Versión de escritorio.** Hecho el 29 oct: el preset «Windows Desktop» (un solo `.exe`), la pantalla completa
      con F11 / Alt+Intro que se recuerda y la sala de pruebas fuera del juego exportado (`docs/ESCRITORIO.md`). Falta:
      probar el mando desde el primer menú y el juego en 1280×800, Linux (sello de Steam Deck) y Steam en sí. El `.exe` ya
      lleva el icono de Johnny (rcedit, `docs/ESCRITORIO.md`).
- [x] **Inglés.** Sin inglés se pierde casi todo el mercado de Steam. En marcha (29 oct 2026): el español es el idioma de
      origen y el inglés el segundo (`locale/en.po`, `Idioma.t`, selector en Opciones; cómo funciona y qué falta,
      en `docs/IDIOMAS.md`). Hecho: la infraestructura, el menú principal, «Elige edificio», Opciones y la interfaz
      (partida, pausa, HUD, inventario, baúl, tienda, ordenador) y los datos (armas, objetos, talentos, logros, mutaciones,
      trajes, eventos) y la voz del juego (historia, noticias, tutoriales, bestiario, supervivientes, gritos de los jefes).
      También el mundo (nombres de planta, sitio y tienda, neones y carteles) y lo dibujado en imágenes (cartel de
      planta y fotos de los tutoriales, con versión en inglés). **Todo el juego está ya pasado.** No hay nadie nativo que
      lo revise (decisión del dueño, 30 oct 2026): se sale con la traducción hecha y se corrige con los avisos de los
      jugadores. El botón «Avisar de un texto mal traducido» ya está en Opciones → General, con un formulario de Google del dueño
      (`Opciones.enlace_avisos`; si algún día hay Discord, se cambia el enlace).
      Hechos también **portugués de Brasil, alemán, francés, ruso y chino simplificado** (29 oct 2026; mismo plan, sin revisión
      nativa: el chino y el ruso, que son los que más pesan en Steam, ~22 % y ~9 %, son los primeros que vigilar). Fuentes nuevas para el
      cirílico y el chino, con licencia OFL (`docs/IDIOMAS.md`, «Las letras»; citadas en los créditos). Siguientes:
      turco, polaco, japonés y coreano («Añadir un idioma»).
- [ ] **Nombre propio.** "Zombie Escape" lo tienen docenas de juegos de móvil y Steam: no se encuentra buscando
      ni se puede registrar. **Decidido el 30 oct: «Johnny Rush: Zombie Escape»** (puesto ya en `project.godot`, en el
      `.exe`, en los docs y en el logo del menú, `assets/ui/logo.png`, que sale de `tools/logo.py`). Al
      mirarlo (30 oct): ningún juego de Steam ni de itch.io se llama así, pero «It's a Wrap!» (Chanko Studios / AMC
      Games, 2023) tiene un protagonista llamado Johnny Rush; `johnnyrush.com` está registrado desde 2008 y los
      perfiles `JohnnyRush` de YouTube y GitHub existen; `.net`, `.io`, `.games` y `.gg` parecían libres e
      `johnnyrush.itch.io` también. Marcas (30 oct): las búsquedas por web no dan ninguna «JOHNNY RUSH» en las
      clases 9 y 41, pero eso no vale como comprobación: TMview rechaza las consultas automáticas y la del USPTO
      solo funciona a mano. Falta hacerla a mano en TMview (EUIPO, EE. UU., Reino Unido y WIPO), con «johnny rush» y
      «rush», en las clases 9 (juegos descargables) y 41 (juegos en línea), y reservar dominio e itch.io. Si no encaja
      el personaje homónimo de Steam, replantearlo.
- [ ] **Pruebas con gente de fuera.** Hasta ahora lo han jugado los dos del equipo y el bot. Conseguir 10–20
      personas que no sepan nada del juego (itch.io con un formulario corto, Discord, amigos de amigos) y mirar:
      dónde mueren, dónde se aburren, cuánto dura una partida, si entienden el banco, el baúl y las mutaciones sin
      explicación, y si vuelven a jugar una segunda vez sin que nadie se lo pida.

## 2. Lo que lo haría comprarse y recomendarse

- [x] **Principio y final.** Una historia mínima: quién es Johnny, por qué el edificio está así, un final que
      cierre. (Hecho el 30 oct: una introducción y un final por edificio, texto sobre negro y saltable; `ui/relato.gd`,
      prueba `--relato`. De momento no se pueden volver a ver.)
- [ ] **Final verdadero.** Si se quiere, un final verdadero al desbloquear algo.
- [x] **Tutorial disimulado.** La primera partida guía al jugador por el primer piso con las ayudas del HUD que ya
      existen, sin pantallas de texto. (Hecho el 29 oct: `guia.gd`, prueba `--guiado`.)
- [ ] **Horas de juego.** Un roguelike de precio bajo se espera que dé 8–15 horas hasta verlo todo. Lo barato es
      multiplicar lo que ya hay: niveles de ascensión (modificadores de dificultad acumulables, como Slay the
      Spire), los supervivientes rescatados como personajes jugables con su arma inicial, desbloqueos a largo plazo.
      Lo caro es un tercer edificio.
- [ ] **Sensación al jugar.** ~~Parada de un fotograma al golpear; sonidos con variaciones (que no suene el mismo
      archivo doscientas veces)~~ (hechas el 29 oct: `temblor.gd` y `sonido.gd`, prueba `--sensacion`); ~~música por capas que suba en hordas y jefes~~ (hecha el 29 oct: `sonido.gd`, prueba `--musica`); ~~pantalla de muerte que diga por qué
      has muerto y qué has desbloqueado, con "Otra vez" a un clic~~ (hecha el 29 oct: `menus.gd`, prueba `--derrota`); menú con algo de vida.
- [ ] **La música procedural a largo plazo.** Comprobar que no cansa tras diez horas; si cansa, temas fijos para
      menú, jefes y final.
- [ ] **Accesibilidad.** ~~Sacudida de pantalla~~ (hecha el 29 oct: «Temblor de pantalla» en Opciones → General,
      `temblor.gd`; quita también el parón de los golpes) y parpadeos ajustables (aviso de fotosensibilidad), texto
      legible a 1280×800 (Steam Deck), charcos verdes y rojos distinguibles sin color, opción de ralentizar el juego.
- [ ] **Robustez.** ~~Guardar al cambiar de planta para no perder la partida si se cierra~~ (hecho el 29 oct:
      `partida_guardada.gd`, «Continuar partida» en el menú, prueba `--continuar`); rendimiento con hordas
      grandes en un portátil flojo; cero errores en consola en una partida entera; archivo de registro que el
      jugador pueda mandar cuando algo falle; pruebas automáticas (`--captura`) antes de cada versión.

## 3. Lo de fuera del juego

- [ ] **Página de Steam con meses de antelación.** Se abre antes de salir para juntar listas de deseos. Hace falta:
      cápsula (ilustración, no captura), 5–10 capturas buenas, tráiler de 30–60 s, descripción en inglés y
      español, etiquetas bien puestas.
- [ ] **Demo.** Un edificio limitado, con el progreso que pase al juego completo. Es la forma más barata de
      conseguir listas de deseos en el Steam Next Fest.
- [ ] **Dónde contar el juego.** Cuenta en una red (la que el equipo vaya a mantener de verdad), gifs cortos de
      cosas que llamen la atención (jefes, armas creadas, hordas), Discord pequeño para los probadores.
- [ ] **Lo legal y de cobrar.** Cuenta de Steamworks; darse de alta como autónomo o empresa para poder facturar;
      formulario fiscal de Valve (W-8BEN); el IVA lo gestiona Valve. Revisar licencias de todo lo que no es
      nuestro: términos comerciales de PixelLab, fuentes, sonidos y su origen (la letra de los jefes, Jersey 25,
      es OFL: se puede vender, pero su licencia `assets/fuentes/jersey-25-OFL.txt` va con el juego y sale en los
      créditos). Clasificación por edades gratis desde Steam (cuestionario IARC). Créditos: hechos (29 oct), en
      Opciones → Créditos, con las letras, Godot y las herramientas (PixelLab, Claude) y todas las licencias; falta la línea
      de quién ha hecho el juego (`AUTORES`, en `opciones.gd`).
- [ ] **Precio y salida.** Con dos edificios, un Early Access honesto es defendible; si se sale completo, mejor
      con tres. Descuento de salida del 10–20 %.

| Dato | Referencia (octubre de 2026) |
|---|---|
| Precio orientativo | 4,99 a 7,99 € |
| Alta en Steam | 100 $ por juego; se devuelven al pasar 1.000 $ de ventas |
| Listas de deseos antes de salir | unas 7.000–10.000 para que Steam lo mueva solo |
| Duración esperada | 8–15 horas hasta verlo todo |

## Pendiente de decidir (preguntar al dueño cuando toque)

- Nombre definitivo del juego.
- Salir completo o en Early Access; con dos o tres edificios.
- Quién figura como vendedor en Steam (uno de los dos, o una empresa de ambos) y cómo se reparte.
- Qué red se mantiene para contar el juego.
- Si se contrata a alguien para la cápsula y el tráiler o se hace en casa.
