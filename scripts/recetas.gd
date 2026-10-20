# Las recetas del banco de trabajo (src/recetas.js del JS). Cada receta junta dos ingredientes: objetos
# (objetos.gd) o armas de la tienda (fregona, bate, cuchillo). El arma que sale lleva una rareza al azar que
# multiplica su daño, y va al baúl (guardado: "baul_armas"). Que las armas creadas peguen es la fase 7b2:
# de momento se crean, se guardan y se ven.
#
# Campos de cada receta:
#   nombre     lo que sale
#   con        los dos ingredientes
#   hueco      "cuerpo" (cuerpo a cuerpo), "fuego" (a distancia) o "arrojadiza"
#   icono      de qué ingrediente se toma el dibujo (hasta que tenga el suyo)
#   dano       daño con rareza verde (provisional; en las arrojadizas, el de la explosión o el fuego)
#   unidades   las arrojadizas: cuántas salen (la rareza da más)
#   desc       qué hace, en una frase
class_name Recetas

const ARMAS := ["fregona", "bate", "cuchillo"]   # las armas que entran en las recetas

const LISTA := {
	"lanza": {"nombre": "Lanza", "con": ["fregona", "cuchillo"], "hueco": "cuerpo", "icono": "fregona", "dano": 11,
		"desc": "Alcance largo: una estocada estrecha que atraviesa"},
	"aplastacabezas": {"nombre": "Aplastacabezas", "con": ["bate", "clavos"], "hueco": "cuerpo", "icono": "bate", "dano": 21,
		"desc": "Empuja mucho y aturde un instante"},
	"bate_fuego": {"nombre": "Bate de fuego", "con": ["bate", "gasolina"], "hueco": "cuerpo", "icono": "bate", "dano": 20,
		"desc": "Cada golpe prende fuego"},
	"lanzallamas": {"nombre": "Lanzallamas", "con": ["pistola_agua", "gasolina"], "hueco": "fuego", "icono": "pistola_agua", "dano": 4,
		"desc": "Chorro de fuego corto con depósito; prende fuego"},
	"partecuerpos": {"nombre": "Partecuerpos", "con": ["bate", "cuchillas"], "hueco": "cuerpo", "icono": "bate", "dano": 22,
		"desc": "Golpe en arco ancho que hace sangrar"},
	"supersoplete": {"nombre": "Súpersoplete", "con": ["spray", "mechero"], "hueco": "fuego", "icono": "spray", "dano": 7,
		"desc": "Llamarada en cono, muy corta y muy fuerte"},
	"desintegrador": {"nombre": "Desintegrador", "con": ["pistola_agua", "lejia"], "hueco": "fuego", "icono": "lejia", "dano": 3,
		"desc": "Chorro de ácido: daño continuo y charco ácido"},
	"molotov": {"nombre": "Cóctel molotov", "con": ["alcohol", "trapo"], "hueco": "arrojadiza", "icono": "alcohol", "dano": 0, "unidades": 3,
		"desc": "Botellas que dejan un charco de fuego"},
	"atraedora": {"nombre": "Atraedora", "con": ["explosivos", "despertador"], "hueco": "arrojadiza", "icono": "despertador", "dano": 80, "unidades": 3,
		"desc": "Suena, atrae a los zombis 3 s y explota"},
	"congeladora": {"nombre": "Congeladora", "con": ["explosivos", "extintor"], "hueco": "arrojadiza", "icono": "extintor", "dano": 50, "unidades": 3,
		"desc": "Explota y deja a los zombis congelados 3 s"},
	"lluvia_acida": {"nombre": "Lluvia ácida", "con": ["explosivos", "lejia"], "hueco": "arrojadiza", "icono": "explosivos", "dano": 50, "unidades": 3,
		"desc": "Explota y deja un charco ácido grande"},
	"inmovilizadora": {"nombre": "Inmovilizadora", "con": ["taser", "bate"], "hueco": "cuerpo", "icono": "taser", "dano": 20,
		"desc": "La descarga aturde y salta a un zombi cercano"},
	"bumeran": {"nombre": "Bumerán segador", "con": ["llave_inglesa", "hacha"], "hueco": "fuego", "icono": "hacha", "dano": 14,
		"desc": "Se lanza, atraviesa zombis y vuelve a la mano; sin munición"},
	"latigo": {"nombre": "Látigo escorpión", "con": ["cuerda", "cuchillo"], "hueco": "cuerpo", "icono": "cuerda", "dano": 12,
		"desc": "Alcance largo y envenena"},
	"supermaza": {"nombre": "Súper maza", "con": ["fregona", "mancuernas"], "hueco": "cuerpo", "icono": "mancuernas", "dano": 24,
		"desc": "Lenta: golpe en círculo con temblor"},
}

# Las rarezas: probabilidad, cuánto multiplica el daño, unidades de más en las arrojadizas y el color del borde
const RAREZAS := {
	"verde": {"nombre": "Poco común", "prob": 0.75, "mul": 1.0, "extra": 0, "color": Color("#5fd35f")},
	"azul": {"nombre": "Rara", "prob": 0.20, "mul": 1.2, "extra": 1, "color": Color("#4aa3ff")},
	"morada": {"nombre": "Épica", "prob": 0.05, "mul": 1.45, "extra": 2, "color": Color("#c06bff")},
}
const GRIS := Color("#8a8494")   # los objetos y las armas de siempre

const HUECOS := {"cuerpo": "Cuerpo a cuerpo", "fuego": "A distancia", "arrojadiza": "Arrojadiza"}


# La receta que sale con estos dos ingredientes (en cualquier orden), o "" si no combinan
static func buscar(a: String, b: String) -> String:
	for id in LISTA:
		var con: Array = LISTA[id].con
		if (con[0] == a and con[1] == b) or (con[0] == b and con[1] == a):
			return id
	return ""


static func rareza_al_azar() -> String:
	var azar := randf()
	var acum := 0.0
	for r in RAREZAS:
		acum += RAREZAS[r].prob
		if azar < acum:
			return r
	return "verde"


# El arma creada que se guarda en el baúl: la receta con su rareza ya aplicada
static func crear(receta: String, rareza := "") -> Dictionary:
	if rareza == "":
		rareza = rareza_al_azar()
	var r: Dictionary = LISTA[receta]
	return {"receta": receta, "nombre": r.nombre, "hueco": r.hueco, "icono": r.icono, "desc": r.desc,
		"rareza": rareza, "dano": roundi(r.dano * RAREZAS[rareza].mul),
		"unidades": r.unidades + RAREZAS[rareza].extra if r.has("unidades") else 0}


# La línea de debajo del nombre: su daño (o sus unidades). La rareza ya se ve en el color del borde
static func detalle(a: Dictionary) -> String:
	return "%d unidades" % a.unidades if a.unidades > 0 else "daño %d" % a.dano
