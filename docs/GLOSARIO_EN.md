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
- Numeración de plantas: como en Estados Unidos, la de la calle ya es la 1ª (*1st floor*): las plantas y las puertas van un
  número por encima del español (`Planta.CALLE_ES_LA_PRIMERA`), y así cuadran con los textos que cuentan la de la calle como
  la 1 («planta %d»: *floor %d*).
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
| Ajolote (talento) | Axolotl | antes Lobezno / Wolverine: se cambió el 29 oct porque Wolverine es marca de Marvel |
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
| partida | run | «Abandonar partida» → *Abandon run*; «Jugar otra vez» → *Play again*; «Otra vez» (cartel de derrota) → *Try again* |
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
| Talentos: Durito · Larguirucho · Desatascador · Fabricante · Artificiero · Tirador · Mirilla · Ajolote | Tough Cookie · Lanky · Drain Cleaner · Bomb Maker · Demolitions · Gunner · Scope · Axolotl |
| Logros: Alerta naranja / máxima · Sube, conserje · Liquidación total · Visto y no visto · Sin tiritas | Orange Alert / Red Alert · Going Up · Everything Must Go · In a Flash · No Band-Aids |
| Logros: Comunidad de vecinos · Chatarrero · Caja fuerte · Ninguna regla me para | Tenants' Association · Packrat · Safecracker · No Rule Stops Me |
| Mutaciones: Tentacular · Gastroenteritis · Insensible · Caníbal · Ansiedad · Endurecimiento · Locura · Flatulento | Tentacular · Gastroenteritis · Numb · Cannibal · Anxiety · Thick Skin · Madness · Flatulent |
| Trajes: Conserje · El portero · El glotón · El gymbro · El bombero | Janitor · The Super · The Glutton · The Gymbro · The Fireman |
| pasillo · cámara acorazada · tarjeta dorada | hallway · vault · gold card |
| apertura de emergencia · cuadro eléctrico · palanca · cable (pelado) · horda | emergency override · electrical panel · lever · wire · horde |
| las viviendas | living quarters |

## Elegidos en la fase 4 (por confirmar)

La voz del juego. Los gritos y los chistes se **adaptaron** (no se tradujeron palabra por palabra). Siguen sin traducir, a propósito:
Johnny, Velaria, Marta Ruiz, VD-7, los nombres en inglés que ya tenía el juego (*NO PAIN, NO GAIN!*).

| Español | Inglés |
|---|---|
| Supervivientes (sin artículo, con mayúscula): Policía · Militar · Médica · Farmacéutica · Ferretero · Técnico | Cop · Soldier · Doctor · Pharmacist · Hardware Guy · Technician |
| Zombis: el vecino · el reptante · el niño · el dinamitero · el de los tentáculos · el gordo · la dependienta · el vigilante · el guardia · el maniquí | the Neighbor · the Crawler · the Kid · the Bomber · the Tentacle Guy · the Fat Man · the Sales Clerk · the Security Guard · the Keycard Guard · the Mannequin |
| Jefes: la criatura · el gerente mutado | the Creature · the Mutated Manager |
| Gritos de la portera: ¡QUE ACABO DE FREGAR! · ¡VECINOS! · ¡LEJÍA! · ¡ÁCIDO! · ¡A BARRER! | I JUST MOPPED! · TENANTS! · BLEACH! · ACID! · CLEAN SWEEP! |
| Gerente: ¡A TRABAJAR! · ¡AQUÍ NO PARA NADIE! | BACK TO WORK! · NOBODY CLOCKS OUT! |
| Gymbro: ¡HORA DE LOS SUPLEMENTOS! · ¡SIN SUPLEMENTOS! | SUPPLEMENT TIME, BRO! · OUT OF SUPPS! |
| Bombero · mascota · cocinero · modista | FIRE DRILL! / FIVE-ALARM FIRE! · FREE HUGS! / PLAYTIME! · PIPING HOT! / INTO THE POT! · HSSSS! / TIME FOR A FITTING! |
| Antidisturbios: ¡ATRÁS! · ¡QUEDAS DETENIDO! | GET BACK! · YOU'RE UNDER ARREST! |
| Glotón: ¡HAMBRE! · ¡ÑAM! | HUNGRY! · CHOMP! |
| Dr. Salas: ¡MÁS SUJETOS! · ¡NO ME TOCARÁS! | MORE TEST SUBJECTS! · HANDS OFF, JANITOR! |
| Zombis: ¡OFERTAS! (dependienta) | BIG SALE! (en el bestiario: *SALE!*; igualar) |
| durmiente · noctámbulo | sleeper · nightwalker |
| Sujeto 0 · «Asunto:» | Subject 0 · «Subject:» |
| Torre Velaria · Turno infinito · Dirección · SOLO DIRECCIÓN · Velaria Noche | Velaria Tower · Endless Shift · Head Office · DIRECTOR ONLY · Velaria Night |
| Canal 8 | Channel 8 |
| almacén · cámara (frigorífica) · rebotica · probadores · taquillas | storeroom · freezer · back room · fitting rooms · lockers |
| Tutoriales: lanzables · truco · piezas de mejora · peligros de las tiendas · vida en tercios | throwables · perk · upgrade parts · store hazards · health in thirds |

Las noticias y los documentos hablan en dólares, como el resto del juego (*$300*, *$3.99*; hasta el 29 oct, en euros).

## Elegidos en la fase 5 (por confirmar)

El mundo. Las plantas se nombran así para que valgan detrás de «the» y en minúscula («You fell on the 1st floor of the Apartments»).

| Español | Inglés |
|---|---|
| Planta baja · 1ª, 2ª, 3ª, 4ª planta · Azotea | 1st floor · 2nd, 3rd, 4th, 5th floor · Rooftop (cartel dibujado: *FLOOR 1, 2, 3, 4*) |
| Puertas de los pisos: Bajo C · 1ºD | 1C · 2D (en las frases: *apt. 1C*, *the key to apt. 2D*) |
| Vestuario · Despacho · Taller · Gimnasio · Cuarto de la limpieza · Mantenimiento | Locker room · Office · Workshop · Gym · Janitor's closet · Maintenance |
| Salón · Cocina · Baño (principal) · Dormitorio (de matrimonio, individual) · Pasillo | Living room · Kitchen · Bathroom (Main bathroom) · Bedroom (Master, Single) · Hallway |
| Apartamento / tienda destrozado/a · Apartamento en llamas | Wrecked apartment / store · Burning apartment |
| Tiendas: Supermercado · Ferretería · Electrónica · Restaurante · Tienda de ropa · Farmacia · Joyería | Supermarket · Hardware Store · Electronics · Restaurant · Clothing Store · Pharmacy · Jewelry Store |
| Neones: SUPER · FERRETERIA · ELECTRO · BURGER · MODA · FARMACIA · JOYAS | SUPER · HARDWARE · ELECTRO · BURGER · FASHION · PHARMACY · JEWELS |
| Salas: Almacén · Cámara frigorífica · Taquillas · Probadores · Rebotica · Aseo · Trastienda · Cámara acorazada | Storeroom · Freezer · Lockers · Fitting rooms · Back room · Restroom · Stockroom · Vault |
| TRASTEROS (cartel) | STORAGE |
| Cerrada con llave · Cerrada: hace falta una tarjeta de acceso | Locked: you need the key · Locked: you need an access card |
