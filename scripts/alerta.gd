# La mejora del compuesto VD-7 (M121, 16 nov; hasta entonces, «los niveles de alerta», como las ascensiones de The
# Binding of Isaac): de la mejora 1 a la 5, por edificio. Cada nivel hace a todos los enemigos (durmientes y jefes) un
# 20 % más fuertes en cuatro cosas: vida, daño, velocidad al andar y velocidad de ataque. En la mejora 5, el doble
# (+100 %). Y (17 nov, lo pidió el dueño) un 20 % más de durmientes por nivel en cada apartamento, tienda o
# departamento (planta.gd, horda). Nada más: sin premios de ningún tipo (antes daba más dólares y materiales) y sin las
# reglas de antes (jefes que se enfadan antes, botiquines a la mitad, el guardia el doble, escoltas en la torre...).
#
# Se desbloquean de una en una: completar un edificio abre su mejora 1; completarlo con la 1, la 2, y así. La más alta
# abierta y la elegida van en el progreso de cada edificio del guardado (alerta_max y alerta: los nombres de siempre).
# Se eligen en "Elige edificio" (menu_principal.gd), que pone aquí el nivel de la partida antes de empezarla.
#
# Quién pregunta: partida.gd (meter_zombi: la vida, la velocidad y el ritmo de cada enemigo al salir), johnny.gd
# (recibir_dano: el daño que le hacen), planta.gd (horda: cuántos durmientes) y los enemigos con su "ritmo" (zombi.gd, minijefe.gd y portera.gd: lo deprisa que
# atacan). Para cambiar los números, las constantes de abajo.
class_name Alerta

const MAX := 5
const VIDA := 0.2        # la vida de más de los enemigos por cada nivel
const DANO := 0.2        # el daño de más que hacen a Johnny por cada nivel
const VELOCIDAD := 0.2   # lo que andan más deprisa por cada nivel
const ATAQUE := 0.2      # lo que atacan más deprisa por cada nivel (avisan antes, dan el golpe antes, esperan menos)
const DURMIENTES := 0.2  # los durmientes de más por cada nivel
# La base de todo (17 nov, lo pidió el dueño: eran demasiado difíciles): sin mejora, todos los enemigos (jefes incluidos)
# con un 20 % menos de vida, de daño, de velocidad al andar y de velocidad de ataque. Las mejoras suben desde aquí
const BASE := 0.8

# El nivel de la partida que se juega (0 = sin mejora)
static var nivel := 0


# Por cuánto se multiplica cada cosa con el nivel de ahora (sin mejora, BASE; con la mejora 5, el doble de BASE)
static func vida() -> float:
	return BASE * (1.0 + VIDA * nivel)


static func dano() -> float:
	return BASE * (1.0 + DANO * nivel)


static func velocidad() -> float:
	return BASE * (1.0 + VELOCIDAD * nivel)


static func ataque() -> float:
	return BASE * (1.0 + ATAQUE * nivel)


# (sin BASE: la base solo los hace más flojos, no menos)
static func durmientes() -> float:
	return 1.0 + DURMIENTES * nivel


# El nombre corto («Mejora 3», en el selector de "Elige edificio") y el largo («Mejora 3 del compuesto VD-7», al empezar
# la partida y en los logros)
static func nombre(n := nivel) -> String:
	return Idioma.t("Mejora %d") % n if n > 0 else Idioma.t("Sin mejora")


static func nombre_largo(n := nivel) -> String:
	return Idioma.t("Mejora %d del compuesto VD-7") % n if n > 0 else Idioma.t("Sin mejora")


# Lo que trae un nivel, en el idioma del jugador («Enemigos +40 %: cantidad, vida, daño, velocidad y ataque»). "_edificio": no
# cambia de un edificio a otro (antes, la torre tenía su Alerta 5)
static func regla(n := nivel, _edificio := "") -> String:
	return Idioma.t("Enemigos +%d %%: cantidad, vida, daño, velocidad y ataque") % roundi(VIDA * n * 100)


static func resumen(n := nivel, edificio := "") -> String:
	return Idioma.t("Como siempre") if n <= 0 else regla(n, edificio)
