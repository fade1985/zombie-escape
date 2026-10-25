# El bestiario: cada enemigo del juego con su nombre, una frase y su dibujo de frente, para el programa
# «Colecciones» del ordenador de la sala de mantenimiento (ui/ordenador.gd). Un enemigo se apunta como visto la
# primera vez que nace en una partida (partida.gd, meter_zombi; el maniquí vivo lo apunta modista.gd y el gerente
# mutado, gerente.gd) y queda en el guardado para siempre ("bestiario"). Los que aún no se han visto, el ordenador
# los enseña sin dibujo y con «?».
#
# Campos de cada entrada (la clave es el tipo del enemigo, el de Partida.ZOMBIS; el maniquí y el gerente mutado no
# nacen por ahí y llevan la suya):
#   nombre     el que se lee en la ficha
#   frase      lo que cuenta de él (una pista de cómo se le gana)
#   edificios  en cuáles sale ("apartamentos", "centro"): cada edificio enseña los suyos
#   hoja       su SpriteFrames (el maniquí, un PNG entero)
#   recorte    el trozo dibujado dentro de la celda del fotograma de frente (sin los márgenes vacíos). Lo escribe
#              `py tools/recortes_bestiario.py` (repetir si cambia una hoja): así el juego no tiene que leer la imagen
#   retrato    la animación de frente de la que se saca el dibujo ("quieto_s" si la tiene; si no, "reposo_s")
#   escala     a cuánto se dibuja en la ficha (2, como en el juego; los tentáculos ya van a 1)
#   jefe       true en los jefes de planta y en el jefe final
#
# PARA CAMBIAR los nombres o las frases, aquí. Lo único que no hay que tocar es la clave de una entrada ya
# publicada: el guardado apunta los vistos por su clave.
class_name Bestiario

const LISTA := {
	"normal": {"nombre": "El vecino",
		"frase": "El vecino de toda la vida. Ya no saluda en la escalera: ahora muerde.",
		"edificios": ["apartamentos", "centro"], "hoja": "res://assets/sprites/zombi-normal.tres",
		"recorte": Rect2i(35, 33, 23, 46), "retrato": "reposo_s", "escala": 2, "jefe": false},
	"lento": {"nombre": "El arrastrado",
		"frase": "Le falta la mitad de abajo y no se ha enterado. Se arrastra con las manos y lo deja todo perdido.",
		"edificios": ["apartamentos", "centro"], "hoja": "res://assets/sprites/zombi-lento.tres",
		"recorte": Rect2i(27, 50, 34, 27), "retrato": "quieto_s", "escala": 2, "jefe": false},
	"rapido": {"nombre": "El crío",
		"frase": "Un crío con gorra y chándal que corre como un demonio. Frena fatal: apártate y se pasa de largo.",
		"edificios": ["apartamentos", "centro"], "hoja": "res://assets/sprites/zombi-rapido.tres",
		"recorte": Rect2i(37, 38, 19, 41), "retrato": "quieto_s", "escala": 2, "jefe": false},
	"explosivo": {"nombre": "El dinamitero",
		"frase": "Un hombretón con gabardina. Cuando la abre no es para enseñarte nada bueno: corre.",
		"edificios": ["apartamentos", "centro"], "hoja": "res://assets/sprites/zombi-explosivo.tres",
		"recorte": Rect2i(29, 31, 33, 51), "retrato": "quieto_s", "escala": 2, "jefe": false},
	"tentaculos": {"nombre": "El de los tentáculos",
		"frase": "Apenas se mueve, pero cuando marca la raya roja, no te quedes en ella.",
		"edificios": ["apartamentos", "centro"], "hoja": "res://assets/sprites/zombi-tentaculos-gpt.tres",
		"recorte": Rect2i(35, 19, 57, 97), "retrato": "reposo_s", "escala": 1, "jefe": false},
	"venenoso": {"nombre": "El gordo",
		"frase": "Guarda las distancias y escupe un moco que deja el suelo envenenado.",
		"edificios": ["apartamentos", "centro"], "hoja": "res://assets/sprites/zombi-venenoso.tres",
		"recorte": Rect2i(38, 51, 65, 67), "retrato": "quieto_s", "escala": 2, "jefe": false},
	"portera": {"nombre": "La portera",
		"frase": "Lo tenía todo controlado: las llaves, los recibos y ahora a los vecinos. La fregona no es para limpiar.",
		"edificios": ["apartamentos"], "hoja": "res://assets/sprites/jefe-portera.tres",
		"recorte": Rect2i(32, 36, 59, 70), "retrato": "quieto_s", "escala": 2, "jefe": true},
	"dependienta": {"nombre": "La dependienta",
		"frase": "Lleva 31 horas de pie y sigue sonriendo. Cuando grita «¡OFERTAS!», la tienda entera se despierta.",
		"edificios": ["centro"], "hoja": "res://assets/sprites/zombi-dependienta.tres",
		"recorte": Rect2i(39, 33, 19, 46), "retrato": "quieto_s", "escala": 2, "jefe": false},
	"vigilante": {"nombre": "El vigilante",
		"frase": "Sigue haciendo la ronda. Si oye un silbato, viene corriendo con la porra por delante.",
		"edificios": ["centro"], "hoja": "res://assets/sprites/zombi-vigilante.tres",
		"recorte": Rect2i(36, 33, 23, 46), "retrato": "quieto_s", "escala": 2, "jefe": false},
	# el guardia comparte dibujo con el vigilante
	"guardia": {"nombre": "El guardia de la tarjeta",
		"frase": "Lleva la tarjeta de la planta y lo sabe. Pita, huye y se cansa: ese es tu momento.",
		"edificios": ["centro"], "hoja": "res://assets/sprites/zombi-vigilante.tres",
		"recorte": Rect2i(36, 33, 23, 46), "retrato": "quieto_s", "escala": 2, "jefe": false},
	"antidisturbios": {"nombre": "El antidisturbios",
		"frase": "Con el escudo delante no le entra nada. Rodéalo: por la espalda duele el doble.",
		"edificios": ["centro"], "hoja": "res://assets/sprites/jefe-antidisturbios.tres",
		"recorte": Rect2i(29, 27, 63, 71), "retrato": "quieto_s", "escala": 2, "jefe": true},
	"cocinero": {"nombre": "El cocinero",
		"frase": "Sigue en su cocina, y la carta es cuchillos y aceite hirviendo. No te quedes bajo las marcas.",
		"edificios": ["centro"], "hoja": "res://assets/sprites/jefe-cocinero.tres",
		"recorte": Rect2i(30, 31, 64, 71), "retrato": "quieto_s", "escala": 2, "jefe": true},
	"modista": {"nombre": "La modista",
		"frase": "Se esconde entre los maniquíes y te cose a alfileres. Fíjate en cuál le brillan los ojos.",
		"edificios": ["centro"], "hoja": "res://assets/sprites/jefe-modista.tres",
		"recorte": Rect2i(40, 21, 29, 71), "retrato": "quieto_s", "escala": 2, "jefe": true},
	# el maniquí vivo (maniqui_vivo.gd) no tiene hoja: su dibujo es el mueble entero
	"maniqui": {"nombre": "El maniquí",
		"frase": "Quieto mientras lo miras. No le des la espalda.",
		"edificios": ["centro"], "hoja": "res://assets/sprites/mueble-tallmannequin.png",
		"recorte": Rect2i(0, 0, 30, 69), "retrato": "", "escala": 2, "jefe": false},
	"mascota": {"nombre": "La mascota",
		"frase": "Un oso de peluche gigante con alguien dentro. Embiste, salta y, si se estrella, ve estrellitas.",
		"edificios": ["centro"], "hoja": "res://assets/sprites/jefe-mascota.tres",
		"recorte": Rect2i(18, 23, 52, 69), "retrato": "quieto_s", "escala": 2, "jefe": true},
	"gerente": {"nombre": "El gerente",
		"frase": "Arturo Salcedo, director del centro. Sus contratos cortan y su jeringuilla lleva VD-7.",
		"edificios": ["centro"], "hoja": "res://assets/sprites/jefe-gerente.tres",
		"recorte": Rect2i(40, 37, 77, 117), "retrato": "quieto_s", "escala": 2, "jefe": true},
	"gerente_mutado": {"nombre": "El gerente mutado",
		"frase": "Ya no le hace falta dormir. Ni el traje. Cuatro tentáculos y el helicóptero esperando en la azotea.",
		"edificios": ["centro"], "hoja": "res://assets/sprites/jefe-gerente-mutado.tres",
		"recorte": Rect2i(17, 31, 127, 127), "retrato": "quieto_s", "escala": 2, "jefe": true},
	# los minijefes de los Apartamentos (docs/historial/JEFES_APARTAMENTOS.md)
	"gloton": {"nombre": "El Glotón",
		"frase": "Va a gatas y quiere comerte: cuando abra la boca, sal del cono. Su sangre es ácida: cada golpe tuyo te salpica.",
		"edificios": ["apartamentos"], "hoja": "res://assets/sprites/jefe-gloton.tres",
		"recorte": Rect2i(33, 26, 66, 66), "retrato": "quieto_s", "escala": 2, "jefe": true},
	"gymbro": {"nombre": "El Gymbro",
		"frase": "Gira con los brazos abiertos, salta encima de ti y te tira pesas. Con sus suplementos, la armadura se come la mitad del daño.",
		"edificios": ["apartamentos"], "hoja": "res://assets/sprites/jefe-gymbro.tres",
		"recorte": Rect2i(31, 34, 70, 66), "retrato": "quieto_s", "escala": 2, "jefe": true},
	"bombero": {"nombre": "El jefe de bomberos",
		"frase": "El fuego no le hace nada: cambia de arma. Cuando gire, corre delante del cono de fuego, hacia donde marcan las flechas. De cerca, cuidado con el hacha.",
		"edificios": ["apartamentos"], "hoja": "res://assets/sprites/jefe-bombero.tres",
		"recorte": Rect2i(27, 36, 68, 70), "retrato": "quieto_s", "escala": 2, "jefe": true},
	# el jefe final de los Apartamentos (la azotea) y en lo que se convierte (lo apunta cientifico_jefe.gd al mutar)
	"cientifico_jefe": {"nombre": "El doctor Salas",
		"frase": "Héctor Salas, director del estudio del VD-7. Tira probetas, mejora a sus sujetos y se esconde en una cúpula de cristal: rómpela.",
		"edificios": ["apartamentos"], "hoja": "res://assets/sprites/jefe-cientifico.tres",
		"recorte": Rect2i(28, 33, 61, 119), "retrato": "quieto_s", "escala": 2, "jefe": true},
	"criatura": {"nombre": "La criatura",
		"frase": "Lo que queda del doctor con su propia dosis: la boca del Glotón, los brazos del Gymbro y el fuego del bombero. Sal de sus franjas y de su onda.",
		"edificios": ["apartamentos"], "hoja": "res://assets/sprites/jefe-criatura.tres",
		"recorte": Rect2i(22, 47, 116, 115), "retrato": "quieto_s", "escala": 2, "jefe": true},
}


# Los que salen en un edificio, en el orden de LISTA
static func de_edificio(edificio: String) -> Array:
	return LISTA.keys().filter(func(id): return edificio in LISTA[id].edificios)


# ¿Ya se ha visto alguna vez? (s es el guardado)
static func visto(s: Dictionary, id: String) -> bool:
	return id in s.get("bestiario", [])


# ── Apuntar ──
# Se llama cada vez que nace un enemigo (muchas veces por sala), así que no puede reescribir el guardado cada
# vez: se recuerda lo que ya está apuntado y solo se escribe la primera vez que se ve uno nuevo. Lo recordado se
# vuelve a leer si cambia el archivo de guardado (la prueba con --captura usa otro) o si alguien más lo ha
# escrito desde entonces (coger un objeto, comprar...), por si lo han cambiado
static var apuntados := {}        # {id: true}: lo que ya está en el guardado
static var apuntados_de := ""     # de qué archivo son (Guardado.archivo)
static var apuntados_en := -1     # con cuántas escrituras llevaba el guardado al leerlos (Guardado.escrituras)


static func apuntar(id: String) -> void:
	if not id in LISTA:
		return
	if apuntados_de != Guardado.archivo or apuntados_en != Guardado.escrituras:
		apuntados = {}
		for v in Guardado.cargar().bestiario:
			apuntados[v] = true
		apuntados_de = Guardado.archivo
		apuntados_en = Guardado.escrituras
	if id in apuntados:
		return
	Guardado.cambiar(func(g):
		if not id in g.bestiario:
			g.bestiario.append(id)
			g.colecciones_nuevo = true)
	apuntados[id] = true
	apuntados_en = Guardado.escrituras   # la escritura es nuestra: lo recordado sigue valiendo


# «Colecciones completas» del panel de pruebas (ui/panel_pruebas.gd): todo encontrado y visto, para probar el programa Colecciones
static func todo_visto() -> void:
	Guardado.cambiar(func(g):
		g.encontrados = Objetos.NOMBRES.keys()
		g.bestiario = LISTA.keys()
		g.colecciones_nuevo = true)


# ── El retrato ──
# El dibujo de frente de cada uno, recortado a los píxeles dibujados (sin los márgenes vacíos de la celda de la
# hoja), para que en la ficha salgan centrados y a su tamaño. Se hace una vez por enemigo y se recuerda
static var retratos := {}   # {id: Texture2D}


static func retrato(id: String) -> Texture2D:
	if not id in retratos:
		retratos[id] = recortar(id)
	return retratos[id]


# Un AtlasTexture con solo el trozo dibujado del primer fotograma de la animación de frente (o del PNG entero, si
# la "hoja" es un PNG): el "recorte" calculado por tools/recortes_bestiario.py o, si una entrada no lo trae, el que
# salga de mirar la imagen. Si algo falla, una textura vacía y un aviso: nunca null
static func recortar(id: String) -> Texture2D:
	if not id in LISTA:
		push_warning("Bestiario: «%s» no está en la lista" % id)
		return PlaceholderTexture2D.new()
	var d: Dictionary = LISTA[id]
	var recurso: Resource = load(d.hoja)
	var hoja: Texture2D = null   # el PNG entero
	var celda := Rect2i()        # dónde está el fotograma dentro del PNG
	if recurso is SpriteFrames:
		var frames := recurso as SpriteFrames
		if frames.has_animation(d.retrato) and frames.get_frame_count(d.retrato) > 0:
			var fotograma: Texture2D = frames.get_frame_texture(d.retrato, 0)
			if fotograma is AtlasTexture:
				hoja = (fotograma as AtlasTexture).atlas
				celda = Rect2i((fotograma as AtlasTexture).region)
			elif fotograma:
				hoja = fotograma
				celda = Rect2i(0, 0, fotograma.get_width(), fotograma.get_height())
	elif recurso is Texture2D:
		hoja = recurso as Texture2D
		celda = Rect2i(0, 0, hoja.get_width(), hoja.get_height())
	if hoja == null:
		push_warning("Bestiario: no hay dibujo para «%s» (%s, %s)" % [id, d.hoja, d.retrato])
		return PlaceholderTexture2D.new()
	var usado: Rect2i = d.get("recorte", Rect2i())
	if usado.size.x <= 0 or usado.size.y <= 0:
		# sin recorte calculado: se mira la imagen (en el escritorio va bien; en la web, mejor tenerlo calculado)
		var imagen: Image = hoja.get_image()
		usado = imagen.get_region(celda).get_used_rect() if imagen else Rect2i()
	if usado.size.x <= 0 or usado.size.y <= 0:
		push_warning("Bestiario: el dibujo de «%s» está vacío" % id)
		return PlaceholderTexture2D.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = hoja
	atlas.region = Rect2(celda.position + usado.position, usado.size)
	return atlas
