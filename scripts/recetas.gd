# Las recetas del banco de trabajo (src/recetas.js del JS). Cada receta junta dos ingredientes: objetos
# (objetos.gd) o armas de la tienda (fregona, bate, cuchillo). Las 15 primeras se hacen con lo de los
# Apartamentos; las seis de "mezclan los dos edificios" piden una cosa de casa y otra del centro comercial, y las
# tres últimas, solo cosas del centro (parte 6 de docs/CENTRO_COMERCIAL.md). El arma que sale lleva una rareza al azar que
# multiplica su daño, y va al baúl (guardado: "baul_armas"). Desde el baúl se sacan para una partida; lo que
# hacen está en Armas.CREADAS y armas_creadas.gd (fase 7b2).
#
# Campos de cada receta:
#   nombre     lo que sale
#   con        los dos ingredientes
#   hueco      "cuerpo" (cuerpo a cuerpo), "fuego" (a distancia) o "arrojadiza"
#   icono      de qué ingrediente se toma el dibujo (hasta que tenga el suyo; la lanza, el aplastacabezas, el bate de
#              fuego, el partecuerpos, la inmovilizadora, el látigo, la súper maza, el mangual, el bate helado, el látigo
#              eléctrico, el lanzallamas, el supersoplete, el desintegrador, el bumerán, la pistola eléctrica y el garfio ya lo tienen: assets/ui/iconos/lanza.png, aplastacabezas.png,
#              bate_fuego.png, partecuerpos.png, inmovilizadora.png, latigo.png, supermaza.png, mangual.png, bate_helado.png,
#              latigo_electrico.png, lanzallamas.png, supersoplete.png, desintegrador.png, bumeran.png, pistola_electrica.png y garfio.png, de tools/icono_lanza.py, icono_aplastacabezas.py,
#              icono_bate_fuego.py, icono_partecuerpos.py, icono_inmovilizadora.py, icono_latigo.py, icono_supermaza.py,
#              icono_mangual.py, icono_bate_helado.py, icono_latigo_electrico.py, icono_lanzallamas.py e
#              icono_supersoplete.py, icono_desintegrador.py, icono_bumeran.py, icono_pistola_electrica.py e icono_garfio.py). Se lee siempre de
#              aquí (icono_de), no del arma guardada en el baúl,
#              para que las ya creadas cojan el dibujo nuevo
#   dano       daño con rareza verde (provisional; en las arrojadizas, el de la explosión o el fuego)
#   unidades   las arrojadizas: cuántas salen (la rareza da más)
#   desc       qué hace, en una frase
#   edificio   con lo de qué edificio se hace: "apartamentos" (las 15 primeras), "mezcla" (una cosa de casa y otra
#              del centro comercial) o "centro" (solo cosas del centro). Las Colecciones del ordenador cuentan las
#              de "mezcla" y "centro" en el centro comercial (de_edificio)
class_name Recetas

const ARMAS := ["fregona", "bate", "cuchillo"]   # las armas que entran en las recetas

const LISTA := {
	"lanza": {"nombre": "Lanza", "con": ["fregona", "cuchillo"], "hueco": "cuerpo", "icono": "lanza", "dano": 11,
		"desc": "Alcance largo: una estocada estrecha que atraviesa", "edificio": "apartamentos"},
	"aplastacabezas": {"nombre": "Aplastacabezas", "con": ["bate", "clavos"], "hueco": "cuerpo", "icono": "aplastacabezas", "dano": 21,
		"desc": "Empuja mucho y aturde un instante", "edificio": "apartamentos"},
	"bate_fuego": {"nombre": "Bate de fuego", "con": ["bate", "gasolina"], "hueco": "cuerpo", "icono": "bate_fuego", "dano": 20,
		"desc": "Cada golpe prende fuego", "edificio": "apartamentos"},
	"lanzallamas": {"nombre": "Lanzallamas", "con": ["pistola_agua", "gasolina"], "hueco": "fuego", "icono": "lanzallamas", "dano": 4,
		"desc": "Chorro de fuego corto con depósito; prende fuego", "edificio": "apartamentos"},
	"partecuerpos": {"nombre": "Partecuerpos", "con": ["bate", "cuchillas"], "hueco": "cuerpo", "icono": "partecuerpos", "dano": 22,
		"desc": "Golpe en arco ancho que hace sangrar", "edificio": "apartamentos"},
	"supersoplete": {"nombre": "Súpersoplete", "con": ["spray", "mechero"], "hueco": "fuego", "icono": "supersoplete", "dano": 7,
		"desc": "Llamarada en cono, muy corta y muy fuerte", "edificio": "apartamentos"},
	"desintegrador": {"nombre": "Desintegrador", "con": ["pistola_agua", "lejia"], "hueco": "fuego", "icono": "desintegrador", "dano": 3,
		"desc": "Chorro de ácido: daño continuo y charco ácido", "edificio": "apartamentos"},
	"molotov": {"nombre": "Cóctel molotov", "con": ["alcohol", "trapo"], "hueco": "arrojadiza", "icono": "alcohol", "dano": 0, "unidades": 3,
		"desc": "Botellas que dejan un charco de fuego", "edificio": "apartamentos"},
	"atraedora": {"nombre": "Atraedora", "con": ["explosivos", "despertador"], "hueco": "arrojadiza", "icono": "despertador", "dano": 80, "unidades": 3,
		"desc": "Suena, atrae a los zombis 3 s y explota", "edificio": "apartamentos"},
	"congeladora": {"nombre": "Congeladora", "con": ["explosivos", "extintor"], "hueco": "arrojadiza", "icono": "extintor", "dano": 50, "unidades": 3,
		"desc": "Explota y deja a los zombis congelados 3 s", "edificio": "apartamentos"},
	"lluvia_acida": {"nombre": "Lluvia ácida", "con": ["explosivos", "lejia"], "hueco": "arrojadiza", "icono": "explosivos", "dano": 50, "unidades": 3,
		"desc": "Explota y deja un charco ácido grande", "edificio": "apartamentos"},
	"inmovilizadora": {"nombre": "Inmovilizadora", "con": ["taser", "bate"], "hueco": "cuerpo", "icono": "inmovilizadora", "dano": 20,
		"desc": "La descarga aturde y salta a un zombi cercano", "edificio": "apartamentos"},
	"bumeran": {"nombre": "Bumerán segador", "con": ["llave_inglesa", "hacha"], "hueco": "fuego", "icono": "bumeran", "dano": 14,
		"desc": "Se lanza, atraviesa zombis y vuelve a la mano; sin munición", "edificio": "apartamentos"},
	"latigo": {"nombre": "Látigo escorpión", "con": ["cuerda", "cuchillo"], "hueco": "cuerpo", "icono": "latigo", "dano": 12,
		"desc": "Alcance largo y envenena", "edificio": "apartamentos"},
	"supermaza": {"nombre": "Súper maza", "con": ["fregona", "mancuernas"], "hueco": "cuerpo", "icono": "supermaza", "dano": 24,
		"desc": "Lenta: golpe en círculo con temblor", "edificio": "apartamentos"},
	# mezclan los dos edificios: una cosa de casa y otra del centro comercial
	"pistola_electrica": {"nombre": "Pistola eléctrica", "con": ["pistola_agua", "bateria"], "hueco": "fuego", "icono": "pistola_electrica", "dano": 5,
		"desc": "Chorro eléctrico: aturde y salta al zombi de al lado", "edificio": "mezcla"},
	"bomba_aceite": {"nombre": "Bomba de aceite", "con": ["trapo", "aceite"], "hueco": "arrojadiza", "icono": "aceite", "dano": 22, "unidades": 3,
		"desc": "Deja un charco que resbala y a los 2 s arde", "edificio": "mezcla"},
	"mangual": {"nombre": "Mangual", "con": ["mancuernas", "cadena"], "hueco": "cuerpo", "icono": "mangual", "dano": 16,
		"desc": "Golpe girando que echa lejos a todos los de alrededor", "edificio": "mezcla"},
	"mina_despertador": {"nombre": "Mina despertador", "con": ["despertador", "bombona"], "hueco": "arrojadiza", "icono": "bombona", "dano": 90, "unidades": 2,
		"desc": "Se queda en el suelo y explota cuando pasa un zombi", "edificio": "mezcla"},
	"nube_somnifera": {"nombre": "Nube somnífera", "con": ["spray", "jeringuilla"], "hueco": "arrojadiza", "icono": "jeringuilla", "dano": 0, "unidades": 3,
		"desc": "Una nube de gas que duerme a los zombis unos segundos", "edificio": "mezcla"},
	"garfio": {"nombre": "Garfio", "con": ["cuerda", "perchas"], "hueco": "fuego", "icono": "garfio", "dano": 8,
		"desc": "Engancha a un zombi y lo arrastra hasta ti; sin munición", "edificio": "mezcla"},
	# solo del centro comercial
	"bate_helado": {"nombre": "Bate helado", "con": ["bate", "hielo_seco"], "hueco": "cuerpo", "icono": "bate_helado", "dano": 17,
		"desc": "Cada golpe congela un momento", "edificio": "centro"},
	"latigo_electrico": {"nombre": "Látigo eléctrico", "con": ["cable", "bateria"], "hueco": "cuerpo", "icono": "latigo_electrico", "dano": 12,
		"desc": "Alcance largo: la descarga aturde y salta a otro zombi", "edificio": "centro"},
	"bomba_clavos": {"nombre": "Bomba de clavos", "con": ["cinta_americana", "clavos"], "hueco": "arrojadiza", "icono": "cinta_americana", "dano": 40, "unidades": 3,
		"desc": "Explota y lanza clavos en todas direcciones que hacen sangrar", "edificio": "centro"},
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
		acum += Alerta.prob_rareza(r, RAREZAS[r].prob)   # con alerta, salen mejores (alerta.gd)
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


# ── Las recetas aprendidas ──
# En el banco solo se crea un arma si se sabe su receta. El molotov se sabe de serie; las demás las sueltan los
# jefes al morir, en un papel que hay que ir a recoger (partida.gd, soltar_receta). Se guardan para siempre
# (guardado: "recetas"), aunque Johnny muera.
const DE_SERIE := ["molotov"]


# Las que sabe ya (con las de serie, por si el guardado es viejo)
static func sabidas(s: Dictionary) -> Array:
	var lista: Array = DE_SERIE.duplicate()
	for id in s.get("recetas", []):
		if id in LISTA and not id in lista:
			lista.append(id)
	return lista


static func sabe(s: Dictionary, id: String) -> bool:
	return id in sabidas(s)


# La apunta como sabida, para siempre
static func aprender(id: String) -> void:
	Guardado.cambiar(func(g):
		if not id in g.recetas:
			g.recetas.append(id))


# La que suelta un jefe: una al azar de las que aún no se saben, sin contar las que ya están en el suelo sin
# recoger ("en_suelo"). "" si ya no queda ninguna
static func para_soltar(s: Dictionary, en_suelo: Array) -> String:
	var quedan := LISTA.keys().filter(func(id): return not sabe(s, id) and not id in en_suelo)
	return "" if quedan.is_empty() else quedan.pick_random()


# El dibujo del arma que sale (el molotov, la lanza, el aplastacabezas, el bate de fuego, el partecuerpos, la inmovilizadora, el látigo y la súper maza tienen el suyo;
# las demás, de momento, el de un ingrediente)
static func icono_de(id: String) -> String:
	return "molotov" if id == "molotov" else Objetos.icono(LISTA[id].icono)


# ── Colecciones (el programa del ordenador) ──
# Las creadas alguna vez se apuntan en el guardado ("creadas"), y el ordenador las cuenta por edificio.

# Las que se hacen con lo de un edificio, en el orden de LISTA: en los Apartamentos, las 15 primeras; en el centro
# comercial, las de "mezcla" y las de "centro" (9). Otro valor: todas
static func de_edificio(edificio: String) -> Array:
	match edificio:
		"apartamentos":
			return LISTA.keys().filter(func(id): return LISTA[id].edificio == "apartamentos")
		"centro":
			return LISTA.keys().filter(func(id): return LISTA[id].edificio != "apartamentos")
	return LISTA.keys()


# Apunta un arma como creada alguna vez (en el banco de trabajo, ui/inventario.gd)
static func apuntar_creada(id: String) -> void:
	if not id in LISTA:
		return
	Guardado.cambiar(func(g):
		if not id in g.creadas:
			g.creadas.append(id)
			g.colecciones_nuevo = true)
