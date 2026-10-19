# Las armas: solo datos, con los números del juego de navegador (src/weapons.js).
# Para añadir una, se copia una entrada y se cambian los números (y se le hace su hoja de Johnny).
#   tipo      "cuerpo" (cuerpo a cuerpo) o "fuego" (a distancia)
#   dano      daño por golpe (o por bala; la escopeta suelta varios perdigones)
#   ritmo     ataques por segundo
#   alcance   cuerpo a cuerpo: hasta dónde llega el golpe · de fuego: hasta dónde llega la bala
#   arco      cuerpo a cuerpo: grados del abanico que barre
#   empuje    cuánto echa para atrás al zombi (1 = normal)
#   hoja      las animaciones de Johnny con esa arma en la mano
#   pies      dónde caen los pies de Johnny en su hoja (en píxeles del dibujo): la escopeta es más alta
#   momento   en qué punto de la animación de golpe llega el arma (lo dice la hoja del juego)
#   De fuego: velocidad de la bala, perdigones, abertura (radianes entre el primero y el último perdigón),
#   temblor (cuánto se desvía cada bala al azar), cargador, recarga (segundos) y cartucho (recarga de uno en uno,
#   como la escopeta, y se puede disparar a mitad). "boca": dónde está la boca del arma en cada dirección, en
#   píxeles desde los pies (sale de la hoja .json del juego)
class_name Armas

const ORDEN := ["fregona", "bate", "cuchillo", "pistola", "escopeta", "mp5"]   # las teclas 1 a 6

# Lo que cuesta cada una en la tienda de armas del ordenador (price en src/weapons.js; 0 = gratis). La fregona
# no se vende: se lleva siempre
const PRECIOS := {"cuchillo": 10, "bate": 15, "pistola": 0, "escopeta": 30, "mp5": 40}

const DATOS := {
	"fregona": {
		"nombre": "Fregona", "tipo": "cuerpo", "dano": 8, "ritmo": 1.8, "alcance": 62.0, "arco": 140.0,
		"empuje": 2.0, "momento": 0.333, "pies": Vector2(48, 72),
		"hoja": preload("res://assets/sprites/conserje-48-guardia.tres"),
	},
	"bate": {
		"nombre": "Bate", "tipo": "cuerpo", "dano": 16, "ritmo": 1.6, "alcance": 66.0, "arco": 110.0,
		"empuje": 1.5, "momento": 0.333, "pies": Vector2(48, 72),
		"hoja": preload("res://assets/sprites/conserje-48-bate.tres"),
	},
	"cuchillo": {
		"nombre": "Cuchillo", "tipo": "cuerpo", "dano": 9, "ritmo": 4.0, "alcance": 46.0, "arco": 60.0,
		"empuje": 0.5, "momento": 0.333, "pies": Vector2(48, 72),
		"hoja": preload("res://assets/sprites/conserje-48-cuchillo.tres"),
	},
	"pistola": {
		"nombre": "Pistola", "tipo": "fuego", "dano": 10, "ritmo": 2.5, "alcance": 420.0, "velocidad": 620.0,
		"perdigones": 1, "abertura": 0.0, "temblor": 0.0, "empuje": 0.8, "cargador": 12, "recarga": 1.1,
		"cartucho": false, "pies": Vector2(48, 72),
		"hoja": preload("res://assets/sprites/conserje-48-pistola.tres"),
		"boca": {"s": Vector2(-2, -31), "se": Vector2(23, -20), "e": Vector2(30, -33), "ne": Vector2(27, -45),
			"n": Vector2(-1, -51), "no": Vector2(-20, -47), "o": Vector2(-30, -35), "so": Vector2(-21, -18)},
	},
	"escopeta": {
		"nombre": "Escopeta", "tipo": "fuego", "dano": 7, "ritmo": 1.0, "alcance": 260.0, "velocidad": 540.0,
		"perdigones": 5, "abertura": 0.55, "temblor": 0.06, "empuje": 1.2, "cargador": 6, "recarga": 0.45,
		"cartucho": true, "pies": Vector2(48, 96),
		"hoja": preload("res://assets/sprites/conserje-48-escopeta.tres"),
		"boca": {"s": Vector2(1, 9), "se": Vector2(26, -20), "e": Vector2(36, -32), "ne": Vector2(27, -48),
			"n": Vector2(12, -66), "no": Vector2(-28, -48), "o": Vector2(-39, -30), "so": Vector2(-35, -8)},
	},
	"mp5": {
		"nombre": "MP5", "tipo": "fuego", "dano": 4, "ritmo": 8.0, "alcance": 340.0, "velocidad": 640.0,
		"perdigones": 1, "abertura": 0.0, "temblor": 0.14, "empuje": 0.3, "cargador": 30, "recarga": 1.8,
		"cartucho": false, "pies": Vector2(48, 72),
		"hoja": preload("res://assets/sprites/conserje-48-mp5.tres"),
		"boca": {"s": Vector2(-1, 4), "se": Vector2(32, -23), "e": Vector2(33, -31), "ne": Vector2(27, -42),
			"n": Vector2(7, -61), "no": Vector2(-26, -40), "o": Vector2(-32, -30), "so": Vector2(-29, -21)},
	},
}
