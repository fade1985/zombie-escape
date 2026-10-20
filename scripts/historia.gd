# La historia del juego: el "Proyecto VD-7". En cada planta hay un científico de Velaria muerto con una página
# del dosier de ese edificio; al cogerla se lee y queda guardada para siempre (Guardado: "paginas"). Todo lo
# encontrado se puede releer en el ordenador de la sala de mantenimiento (programa "Dosier").
# Un científico solo aparece mientras su página siga sin encontrar: así la historia no se repite.
#
# PARA CAMBIAR LA HISTORIA: todo el texto está aquí. Se puede reescribir cualquier página, cambiar nombres o
# añadir edificios nuevos (una entrada más en DOSIERES). Lo único que no hay que tocar es el "id" de una página
# ya publicada: el guardado de los jugadores apunta las encontradas por su id.
class_name Historia
extends RefCounted

const EMPRESA := "Velaria Bienestar"

# Un dosier por edificio (la clave es el id del edificio, el EDIFICIO de partida.gd). Cada página:
#   id       no cambiar una vez publicada
#   planta   en qué planta está el científico que la lleva
#   cuerpo   quién es el muerto (sale al encontrarlo)
#   look     los colores de su dibujo (persona.gd): todos llevan bata blanca
#   tipo     qué clase de papel es (sale arriba de la hoja)
#   titulo, texto, nota (lo escrito a mano al pie, o "")
const DOSIERES := {
	"apartamentos": {
		"titulo": "Dosier VD-7 · Apartamentos",
		"paginas": [
			{"id": "vd7_protocolo", "planta": 1, "cuerpo": "Dra. Inés Lozano, coordinadora del estudio",
				"look": {"skin": Color("#f1c27d"), "hair": Color("#2b2b2b")},
				"tipo": "HOJA DE INSCRIPCIÓN", "titulo": "Estudio vecinal de descanso",
				"texto": "Participantes: 38 vecinos de 41. Pago: 200 € por persona.\n\nDosis: una cápsula de VD-7 cada noche, a las 23:00. Las cápsulas se dejan en los buzones, en sobres sin marca, para no condicionar al sujeto.\n\nReparto y vigilancia: a cargo de una persona de confianza del edificio, ya contratada (ver anexo 4).",
				"nota": "Los 3 que no firmaron siguen viviendo aquí. ¿Qué hacemos con ellos?"},
			{"id": "vd7_diario", "planta": 2, "cuerpo": "Dr. Tomás Vidal, médico de guardia",
				"look": {"skin": Color("#c68642"), "hair": Color("#1d1b2c")},
				"tipo": "DIARIO DE TURNO", "titulo": "Noches 9 a 13",
				"texto": "Noche 9. El del 1ºA lleva tres días sin despertarse. No duerme: está de pie, con los ojos cerrados, mirando la pared de la cocina. Respira cuatro veces por minuto.\n\nNoche 11. Ya son doce. Si les hablas, nada. Si se cae un vaso, se giran todos a la vez hacia el ruido.\n\nNoche 12. El del 2ºC me ha mordido al tomarle el pulso. Es poca cosa. Lozano dice que no lo apunte.\n\nNoche 13. Tengo mucho sueño.",
				"nota": ""},
			{"id": "vd7_correo", "planta": 3, "cuerpo": "Andrés Peña, técnico de muestras",
				"look": {"skin": Color("#ffd2a8"), "hair": Color("#8a5a2b")},
				"tipo": "CORREO INTERNO IMPRESO", "titulo": "Asunto: RE: ¿virus?",
				"texto": "De: Dirección de Comunicación\nPara: Equipo de campo\n\nNo hay ningún virus, lo sabemos. Pero «virus» lo entiende todo el mundo, asusta lo justo y nadie pregunta por las cápsulas. Desde hoy el edificio está en cuarentena sanitaria.\n\nLo que pase dentro es la fase de campo: no intervengáis. Necesitamos 30 días de observación sin tratamiento.\n\nEl contagio por mordisco no estaba previsto. Ahora forma parte del estudio.\n\nBorrad este correo.",
				"nota": "No pienso borrarlo. Que lo lea alguien."},
			{"id": "vd7_anexo", "planta": 4, "cuerpo": "Ramón Gil, vigilante de Velaria",
				"look": {"skin": Color("#e0ac69"), "hair": Color("#9b93a0")},
				"tipo": "ANEXO 4 · CONFIDENCIAL", "titulo": "La colaboradora del edificio",
				"texto": "Funciones: repartir los sobres, apuntar quién entra y quién sale, avisar si algún vecino habla con la prensa. Pago: 1.500 € al mes y un año de alquiler gratis.\n\nDía 15: la colaboradora pide «algo para aguantar despierta». Se le da VD-7 sin decírselo, a dosis doble, para ver cómo reacciona un sujeto activo.\n\nDía 17: la colaboradora no duerme. No para. Ha cerrado el edificio por dentro: tiene todas las llaves.",
				"nota": "Retirad al personal de las plantas de arriba. YA."},
			{"id": "vd7_sujeto_cero", "planta": 5, "cuerpo": "Dr. Héctor Salas, director del estudio",
				"look": {"skin": Color("#f1c27d"), "hair": Color("#d9d1bd")},
				"tipo": "LISTA DE SUJETOS · SOLO DIRECCIÓN", "titulo": "Sujeto 0",
				"texto": "Vecinos: 38 de 38 con respuesta positiva al VD-7.\n\nSujeto 0: el conserje del edificio. No firmó nada. Ha tomado VD-7 durante 40 días con el café de la sala de mantenimiento (la cafetera se la regalamos nosotros).\n\nRespuesta: NINGUNA. Duerme normal. Sueña normal. Su sangre deshace el VD-7 en menos de una hora.\n\nPrioridad absoluta: llevarlo vivo a la sede. No es un superviviente. Es la cura. O es el arma.",
				"nota": "Si lees esto, conserje: no te fíes de la gente con bata. Tampoco de los que vengan a rescatarte."},
		],
	},
}


static func dosier(edificio: String) -> Dictionary:
	return DOSIERES.get(edificio, {"titulo": "", "paginas": []})


static func encontrada(s: Dictionary, id: String) -> bool:
	return id in s.paginas


# La página que lleva el científico de esa planta, si aún no se ha encontrado ({} si no hay o ya está)
static func pendiente(s: Dictionary, edificio: String, planta: int) -> Dictionary:
	for p in dosier(edificio).paginas:
		if p.planta == planta and not encontrada(s, p.id):
			return p
	return {}


# Apunta una página como encontrada
static func apuntar(id: String) -> void:
	Guardado.cambiar(func(g):
		if not id in g.paginas:
			g.paginas.append(id))


# ── La hoja ──
# Una página del dosier dibujada como un papel: amarillento, con letra de máquina de escribir, el tipo de
# documento arriba, un sello y la nota a mano al pie. La usan el aviso de la partida (menus.gd) y el ordenador.

const PAPEL := Color("#e9dfc4")
const PAPEL_BORDE := Color("#b8a983")
const TINTA := Color("#2a2520")
const ROJO := Color("#a3312b")
const BOLI := Color("#1f3c8a")


static func hoja(p: Dictionary, ancho := 560.0) -> PanelContainer:
	var papel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = PAPEL
	estilo.border_color = PAPEL_BORDE
	estilo.set_border_width_all(2)
	estilo.set_content_margin_all(18)
	estilo.shadow_color = Color(0, 0, 0, 0.45)
	estilo.shadow_size = 6
	estilo.shadow_offset = Vector2(4, 4)
	papel.add_theme_stylebox_override("panel", estilo)
	papel.custom_minimum_size.x = ancho
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 8)
	papel.add_child(columna)
	var arriba := HBoxContainer.new()
	columna.add_child(arriba)
	var tipo := texto(p.tipo, ROJO, 16)
	tipo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arriba.add_child(tipo)
	arriba.add_child(texto(EMPRESA.to_upper(), Color(TINTA, 0.55), 16))
	columna.add_child(texto(p.titulo, TINTA, 32))
	var raya := ColorRect.new()
	raya.color = Color(TINTA, 0.4)
	raya.custom_minimum_size.y = 2
	columna.add_child(raya)
	var cuerpo := texto(p.texto, TINTA, 16)
	cuerpo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(cuerpo)
	if p.nota != "":
		var nota := texto("— " + p.nota, BOLI, 16)
		nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nota.rotation_degrees = -1.0   # escrita a mano, un poco torcida
		columna.add_child(nota)
	return papel


static func texto(t: String, color: Color, tamano: int) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_font_size_override("font_size", tamano)
	return l
