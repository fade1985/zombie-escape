# Glosario del inglés · cómo se dice cada cosa

Para que el inglés suene siempre igual. **Provisional hasta que lo apruebe el dueño** (antes de empezar con los datos:
armas, objetos, talentos, logros...). Si cambia un nombre, se cambia aquí y en `locale/en.po` (buscar y reemplazar).

## Reglas

- **Inglés americano** (*apartment*, *elevator*, *janitor*, *flashlight*, *gray*...).
- El tono del español se mantiene: seco, algo irónico, frases cortas. Los gritos de los jefes se **adaptan**, no se
  traducen palabra por palabra (¡QUE ACABO DE FREGAR! → *I JUST MOPPED!*).
- Títulos y nombres propios en **Title Case** (*Daily Challenge*, *Choose a building*); los botones de acción, solo la
  primera en mayúscula (*Reset controls*). Los avisos en pantalla, sin punto final, como en español.
- Comillas y apóstrofos **rectos** (`"` `'`): a la letra del juego le faltan los rizados.
- Numeración de plantas: el juego cuenta «planta baja, 1ª planta…» y los textos con número («planta %d») conservan la
  cuenta del juego. Por decidir: *Ground floor / Floor 1* (como el cartel del ascensor) o contar desde 1.
- Un texto en inglés **no puede llevar otros `%d`/`%s`** que el español (lo comprueba `tools/traducciones.py`).

## Nombres

| Español | Inglés | Notas |
|---|---|---|
| Johnny, el conserje | Johnny, the janitor | |
| la portera (jefa de los Apartamentos) | the super | de *building superintendent*; por decidir |
| el gerente | the manager | |
| el doctor Salas | Dr. Salas | |
| el Glotón | the Glutton | |
| el Gymbro | the Gymbro | ya es una palabra inglesa |
| el jefe de bomberos | the fire chief | |
| el antidisturbios | the riot cop | |
| el cocinero / la modista / la mascota | the cook / the seamstress / the mascot | |
| los Apartamentos | the Apartments | |
| el Centro comercial | the Shopping Mall | |
| Oficina de seguridad · Cocina central · Taller de costura · Juguetería | Security Office · Main Kitchen · Sewing Shop · Toy Store | tiendas de los minijefes |
| el Reto del día | the Daily Challenge | |
| Alerta (nivel) | Alert (level) | «Alerta 3» → *Alert 3* |
| Ayudas (opciones de accesibilidad) | Assists | |
| Lobezno (talento) | Wolverine | marca de Marvel: valorar cambiarlo en los dos idiomas |
| arrojables | throwables | molotov, granadas, atraedora, congeladora |
| baúl · mochila | stash · backpack | por confirmar |
| dólares · puntos · piezas | dollars · points · parts | |
| logro · bestiario · dosier | achievement · bestiary · dossier | |

## Interfaz

| Español | Inglés |
|---|---|
| JUGAR · Salir · Volver | PLAY · Quit · Back |
| Opciones · Controles · Mando · Teclado y ratón | Options · Controls · Gamepad · Keyboard and mouse |
| Pantalla completa | Fullscreen |
| Modo de atacar: Asistido / Apuntar libre | Attack mode: Assisted / Free aim |
| Intro · Mayús · Borrar | Enter · Shift · Backspace |
| Sí / No | Yes / No |

## Elegidos en la fase 2 (por confirmar)

Salieron al pasar la interfaz; las fases siguientes tienen que igualarlos (nombres de armas, objetos, supervivientes...).

| Español | Inglés | Notas |
|---|---|---|
| Objetos · Munición · Arrojables | Items · Ammo · Throwables | los tres apartados de la mochila |
| Cuerpo a cuerpo · A distancia · En la mano · De repuesto | Melee · Ranged · In hand · Spare | |
| Seguir (cerrar el inventario) · Continuar (pausa) · Seguir (página del dosier) | Resume · Resume · Continue | «Seguir» lleva contexto `inventario` |
| Ponérmela · Tirar al suelo · Destruir | Equip · Drop · Destroy | |
| Baúl (del taller) · Banco de trabajo · Taquilla | Stash · Workbench · Locker (*Johnny's Locker*) | |
| Calidades: Normal, Poco común, Rara, Épica | Normal, Uncommon, Rare, Epic | |
| gasolina · bidón de ácido · baterías | gas can · acid drum · batteries | tipos de munición de depósito |
| piezas (cuerpo a cuerpo, a distancia, especial, arrojable) | parts (melee, ranged, special, throwable) | |
| Tienda de armas · Cambiar (en la tienda) | Weapon Shop · Trade | |
| partida | run | «Abandonar partida» → *Abandon run*; «Jugar otra vez» → *Play again* |
| ConserjeOS · CONSERJE OS 95 | JanitorOS · JANITOR OS 95 | los nombres de archivo de las ventanas (PUNTOS.EXE...) también se traducen |
| Canal 8 | Channel 8 | `Historia.CANAL` (fase 4) |
| ¡NOTICIAS NUEVAS! | BREAKING NEWS! | |
| ¡Piso limpio! | All clear! | también vale en las tiendas |
| Joyería · Farmacéutica | Jewelry Store · Pharmacist | los supervivientes van **sin artículo** («The %s moves into their room») |
| Vida · Crítico | Health · Crit chance | las filas de la pausa |

## Elegidos en la fase 3 (por confirmar)

Los datos. Los nombres de armas, munición, piezas y arrojables se fijaron antes de escribir (están en cada ficha); los de talentos y logros
son **adaptaciones**, no traducciones literales.

| Español | Inglés |
|---|---|
| Fregona · Bate · Cuchillo · Pistola · Escopeta · MP5 | Mop · Bat · Knife · Pistol · Shotgun · MP5 |
| Lanzallamas · Lanza ácido · Lanza rayos | Flamethrower · Acid launcher · Lightning gun |
| Balas de pistola · Cartuchos · Gasolina · Bidón de ácido · Batería | Pistol bullets · Shells · Gas can · Acid drum · Battery |
| Molotov · Granada · Atraedora · Congeladora | Molotov · Grenade · Decoy · Freeze bomb |
| Truco (de la Épica) | Perk |
| Ramas: Militar · Superviviente · Químico | Military · Survivor · Chemist |
| Talentos: Durito · Larguirucho · Desatascador · Fabricante · Artificiero · Tirador · Mirilla · Lobezno | Tough Cookie · Lanky · Drain Cleaner · Bomb Maker · Demolitions · Gunner · Scope · Wolverine |
| Logros: Alerta naranja / máxima · Sube, conserje · Liquidación total · Visto y no visto · Sin tiritas | Orange Alert / Red Alert · Going Up · Everything Must Go · In a Flash · No Band-Aids |
| Logros: Comunidad de vecinos · Chatarrero · Caja fuerte · Ninguna regla me para | Tenants' Association · Packrat · Safecracker · No Rule Stops Me |
| Mutaciones: Tentacular · Gastroenteritis · Insensible · Caníbal · Ansiedad · Endurecimiento · Locura · Flatulento | Tentacular · Gastroenteritis · Numb · Cannibal · Anxiety · Thick Skin · Madness · Flatulent |
| Trajes: Conserje · El portero · El glotón · El gymbro · El bombero | Janitor · The Super · The Glutton · The Gymbro · The Fireman |
| pasillo · cámara acorazada · tarjeta dorada | hallway · vault · gold card |
| apertura de emergencia · cuadro eléctrico · palanca · cable (pelado) · horda | emergency override · electrical panel · lever · wire · horde |
| las viviendas | living quarters |
