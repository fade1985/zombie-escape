# La historia del juego: el "Proyecto VD-7". En cada planta hay un muerto (casi siempre, un científico de Velaria)
# con una página del dosier de ese edificio; al cogerla se lee y queda guardada para siempre (Guardado: "paginas").
# Todo lo encontrado se puede releer en el ordenador de la sala de mantenimiento (programa "Dosier").
# Un muerto solo aparece mientras su página siga sin encontrar: así la historia no se repite. La última página del
# centro comercial no la lleva un muerto: la suelta el gerente al caer (del_jefe).
#
# PARA CAMBIAR LA HISTORIA: todo el texto está aquí. Se puede reescribir cualquier página, cambiar nombres o
# añadir edificios nuevos (una entrada más en DOSIERES). Lo único que no hay que tocar es el "id" de una página
# ya publicada: el guardado de los jugadores apunta las encontradas por su id.
#
# Las NOTICIAS (fase B): emisiones de Canal 8 que se ven en el programa "Noticias" del ordenador. Van saliendo
# según se avanza (al empezar, al encontrar ciertas páginas, al completar el edificio) y en cada una Velaria
# cambia un poco su versión para tapar el experimento. Las vistas quedan en el guardado ("noticias_vistas").
class_name Historia
extends RefCounted

const EMPRESA := "Velaria Bienestar"

# Un dosier por edificio (la clave es el id del edificio, el EDIFICIO de partida.gd). Del dosier:
#   titulo
#   nota     lo que explica el ordenador debajo del título
#   falta    lo que dice el ordenador en el sitio de una página aún sin encontrar (%s = la planta)
# Cada página:
#   id       no cambiar una vez publicada
#   planta   en qué planta está el muerto que la lleva
#   cuerpo   quién es el muerto (sale al encontrarlo)
#   look     los colores de su dibujo (cientifico.gd): piel y pelo, y bata blanca si no se dice otra cosa
#            ("ropa": la chaqueta o la blusa, "pantalon", "tarjeta": la tarjeta del pecho)
#   tipo     qué clase de papel es (sale arriba de la hoja)
#   titulo, texto, nota (lo escrito a mano al pie, o "")
# Las páginas con "jefe" no las lleva un muerto de la planta: las suelta el jefe del edificio al caer
# (del_jefe). Esas dicen además "donde" (el sitio, en vez de la planta) y "falta" (su propio aviso).
const DOSIERES := {
	"apartamentos": {
		"titulo": "Dosier VD-7 · Apartamentos",
		"nota": "Cada científico de Velaria muerto en el edificio lleva una página, y la última la lleva el director del estudio. Lo que encuentres queda aquí para siempre.",
		"falta": "Esta página falta. La lleva un científico de Velaria caído en la %s.\n\nBúscalo en una partida.",
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
			{"id": "vd7_anexo", "planta": 4, "cuerpo": "Dr. Ramón Gil, investigador de Velaria",
				"look": {"skin": Color("#e0ac69"), "hair": Color("#9b93a0")},
				"tipo": "ANEXO 4 · CONFIDENCIAL", "titulo": "La colaboradora del edificio",
				"texto": "Funciones: repartir los sobres, apuntar quién entra y quién sale, avisar si algún vecino habla con la prensa. Pago: 1.500 € al mes y un año de alquiler gratis.\n\nDía 15: la colaboradora pide «algo para aguantar despierta». Se le da VD-7 sin decírselo, a dosis doble, para ver cómo reacciona un sujeto activo.\n\nDía 17: la colaboradora no duerme. No para. Ha cerrado el edificio por dentro: tiene todas las llaves.",
				"nota": "Retirad al personal de las plantas de arriba. YA."},
			# La última no la lleva un muerto: la suelta el científico jefe (el director del estudio) al caer en la
			# azotea (del_jefe)
			{"id": "vd7_sujeto_cero", "planta": 5, "jefe": true, "donde": "azotea",
				"falta": "Esta página falta. La lleva el director del estudio, arriba del todo, en la azotea.

Tendrás que quitársela.",
				"cuerpo": "Dr. Héctor Salas, director del estudio",
				"look": {"skin": Color("#f1c27d"), "hair": Color("#d9d1bd")},
				"tipo": "LISTA DE SUJETOS · SOLO DIRECCIÓN", "titulo": "Sujeto 0",
				"texto": "Vecinos: 38 de 38 con respuesta positiva al VD-7.\n\nSujeto 0: el conserje del edificio. No firmó nada. Ha tomado VD-7 durante 40 días con el café de la sala de mantenimiento (la cafetera se la regalamos nosotros).\n\nRespuesta: NINGUNA. Duerme normal. Sueña normal. Su sangre deshace el VD-7 en menos de una hora.\n\nPrioridad absoluta: llevarlo vivo a la sede. No es un superviviente. Es la cura. O es el arma.",
				"nota": "Si lees esto, conserje: no te fíes de la gente con bata. Tampoco de los que vengan a rescatarte."},
		],
	},
	# «Turno infinito»: el gerente del centro pone VD-7 en el café de sus empleados para que trabajen sin parar, y
	# quiere entregarle a Johnny a Velaria a cambio de «la dosis buena» (docs/historial/CENTRO_COMERCIAL.md, Historia)
	"centro": {
		"titulo": "Dosier VD-7 · Centro comercial",
		"nota": "En cada planta hay un cuerpo con una página, y la última la lleva el gerente. Lo que encuentres queda aquí para siempre.",
		"falta": "Esta página falta. Está junto a un cuerpo, en la %s.\n\nBúscalo en una partida.",
		"paginas": [
			{"id": "cc_albaran", "planta": 1, "cuerpo": "Julián Mora, farmacéutico de Velaria",
				"look": {"skin": Color("#e0ac69"), "hair": Color("#4a3426")},
				"tipo": "ALBARÁN DE ENTREGA", "titulo": "Pedido para la farmacia",
				"texto": "Producto: «Velaria Noche», somnífero. 10.000 cajas de 20 cápsulas.\n\nCada cápsula: un cuarto de dosis de VD-7. Venta libre, sin receta. Precio: 3,99 €.\n\nColocar junto a las cajas, a la altura de los ojos. Cartel: «Duerme como un bebé».\n\nSi un cliente pregunta por el edificio del número 14, se le atiende fuera de la tienda.",
				"nota": "¿Sin receta? ¿En serio? Yo esto no lo vendo."},
			{"id": "cc_turno", "planta": 2, "cuerpo": "Dra. Elena Ruiz, técnica de Velaria",
				"look": {"skin": Color("#ffd2a8"), "hair": Color("#b5651d")},
				"tipo": "CONTRATO · CONFIDENCIAL", "titulo": "Programa «Turno infinito»",
				"texto": "Entre Velaria Bienestar y la gerencia del centro comercial.\n\nVelaria entrega el VD-7 gratis. El centro lo pone en la cafetera de la sala de descanso de los empleados, a dosis completa. Los empleados no deben saberlo.\n\nObjetivo: turnos de 20 horas, sin cansancio y sin quejas.\n\nEl centro se ahorra las horas extra. Velaria se queda con los datos de 312 empleados.",
				"nota": "La cajera de la 3 lleva 31 horas de pie. Sonríe. No parpadea."},
			{"id": "cc_incidencias", "planta": 3, "cuerpo": "Manuel Ortega, jefe de seguridad del centro",
				"look": {"skin": Color("#c68642"), "hair": Color("#2b2b2b"), "ropa": Color("#2f3b5c"),
					"pantalon": Color("#23283a"), "tarjeta": Color("#d9b44a")},
				"tipo": "PARTE DE INCIDENCIAS", "titulo": "Turno de noche",
				"texto": "02:10. Cerrado al público desde las 22:00. Las cajas siguen abiertas. Los cajeros cobran a nadie.\n\n03:40. La de la tienda de ropa dobla la misma camiseta. Lleva así desde las once.\n\n04:15. Les hablo y no contestan. Tienen los ojos cerrados. Siguen trabajando.\n\n05:00. Llamo al gerente. Dice que no es una incidencia: «Rinden más que nunca».\n\n05:30. Gómez sigue haciendo la ronda. Pasa por mi lado cada diez minutos. No me mira. Pita el silbato a nadie.",
				"nota": "Esta noche no me tomo el café."},
			{"id": "cc_correo", "planta": 4, "cuerpo": "Lucía Benet, secretaria del gerente",
				"look": {"skin": Color("#f1c27d"), "hair": Color("#1d1b2c"), "ropa": Color("#a34a6a"),
					"pantalon": Color("#3a3a46"), "tarjeta": Color("#e8e8e0")},
				"tipo": "CORREO IMPRESO · GERENCIA", "titulo": "Asunto: El conserje",
				"texto": "De: Gerencia del centro comercial\nPara: Velaria Bienestar, Dirección\n\nEl conserje del 14 está en el centro. Lo veo en las cámaras: sube planta por planta, como si buscara algo.\n\nNo voy a llamar a la policía. Lo retengo hasta que llegue vuestro equipo. He cerrado las salidas, y mis empleados no se cansan.\n\nA cambio, quiero la dosis buena. La de verdad.",
				"nota": "Lleva cuatro días sin dormir. Dice que ya no le hace falta."},
			# La última no la lleva un muerto: la suelta el gerente al caer en la azotea (del_jefe). La azotea y el
			# gerente llegan en el trozo 6 de la parte 4
			{"id": "cc_recogida", "planta": 5, "jefe": true, "donde": "azotea",
				"falta": "Esta página falta. La lleva el gerente del centro, arriba del todo, en la azotea.\n\nTendrás que quitársela.",
				"cuerpo": "Arturo Salcedo, gerente del centro",
				"look": {"skin": Color("#f1c27d"), "hair": Color("#6e6a64")},
				"tipo": "ORDEN DE RECOGIDA · URGENTE", "titulo": "Recogida del Sujeto 0",
				"texto": "Lugar: helipuerto de la azotea del centro comercial. Hora: en cuanto avise el gerente.\n\nCarga: el Sujeto 0, el conserje del 14. Vivo. Atado si hace falta. No gastéis VD-7 con él: no le hace nada.\n\nDestino: Torre Velaria, nuestra sede. Directo al laboratorio de la planta 40.\n\nEl gerente no viaja. Lo que pidió no se le entrega. Mandadle una jeringa para que aguante hasta que lleguemos.",
				"nota": "Me prometieron la dosis buena. Me mandaron una jeringa y esta hoja."},
		],
	},
}


# ── Las noticias ──
const CANAL := "Canal 8"
const REPORTERA := "Marta Ruiz"

# Cada emisión:
#   id        no cambiar una vez publicada (el guardado apunta las vistas por su id)
#   pagina    sale al encontrar esa página del dosier ("" = no depende de ninguna)
#   victoria  sale al completar ese edificio ("" = no depende)
#   (si no depende de nada, sale desde la primera partida)
#   titular   el rótulo de abajo de la pantalla (corto: unas 30 letras)
#   texto     lo que cuenta la reportera
#   sitio     dónde está la reportera (la calle de detrás, ui/tele.gd): "centro" en las del centro comercial; si no
#             está, delante del número 14
const NOTICIAS := [
	{"id": "n_cierre", "pagina": "", "victoria": "",
		"titular": "Cierran un edificio por un virus",
		"texto": "Buenas noches. Les hablo desde la puerta del número 14, donde la empresa Velaria Bienestar ha cerrado el edificio esta mañana. Según Velaria, varios vecinos tienen un virus muy contagioso. «La situación está controlada», nos dicen. Piden a todo el mundo que no se acerque."},
	{"id": "n_estudio", "pagina": "vd7_protocolo", "victoria": "",
		"titular": "¿Un estudio con los vecinos?",
		"texto": "Algunos familiares aseguran que a los vecinos del 14 se les pagaba por «probar algo para dormir». Velaria lo niega: «Fue una campaña de salud. Repartimos folletos y vitaminas, nada más». El edificio sigue cerrado y no se deja pasar a la prensa."},
	{"id": "n_correo", "pagina": "vd7_correo", "victoria": "",
		"titular": "Un correo dice: no hay virus",
		"texto": "Canal 8 ha recibido un correo interno de Velaria. En él se lee: «No hay ningún virus, lo sabemos». La empresa dice que el correo es falso. Y añade que, si algún vecino está enfermo, será por «un somnífero en mal estado, de otra marca». Aún no se sabe qué marca."},
	{"id": "n_portera", "pagina": "vd7_anexo", "victoria": "",
		"titular": "¿Dónde está la portera?",
		"texto": "Nadie ha visto a la portera del 14 desde el cierre. Los vecinos de la calle dicen que trabajaba para Velaria. La empresa responde que era «una vecina con problemas que nunca trabajó para nosotros». Por la noche, desde fuera, se oyen golpes en las plantas de arriba."},
	{"id": "n_buscado", "pagina": "", "victoria": "apartamentos",
		"titular": "Velaria busca a un conserje",
		"texto": "Última hora: el edificio está en silencio. Velaria dice que el «virus» ya está vencido y que todo era un malentendido. Pero hoy busca a un empleado de mantenimiento desaparecido. Si lo ven, no se acerquen y llamen al teléfono de Velaria. Dicen que es muy importante para ellos. ¿Por qué?"},
	# El centro comercial: «Turno infinito»
	{"id": "n_reformas", "sitio": "centro", "pagina": "", "victoria": "apartamentos",
		"titular": "El centro cierra «por reformas»",
		"texto": "Buenas noches. El centro comercial de la avenida cierra por las noches desde hoy, «por reformas». Pero los vecinos ven las luces encendidas hasta el amanecer, y gente moviéndose dentro. Velaria, que tiene allí una farmacia, dice que no sabe nada: «Nosotros solo alquilamos un local»."},
	{"id": "n_velaria_noche", "sitio": "centro", "pagina": "cc_albaran", "victoria": "",
		"titular": "Velaria vende su somnífero",
		"texto": "Ya está a la venta «Velaria Noche», el nuevo somnífero de Velaria. Sin receta y a 3,99 €. Las cajas se agotan en horas. ¿Es lo mismo que se probó en el edificio del 14? Velaria lo niega: «Es una fórmula nueva, natural y segura. La tomamos nosotros todas las noches»."},
	{"id": "n_turnos", "sitio": "centro", "pagina": "cc_turno", "victoria": "",
		"titular": "Empleados que no vuelven a casa",
		"texto": "Varias familias denuncian que sus parientes, empleados del centro comercial, no vuelven a casa desde hace días. Si llaman a la tienda, alguien coge el teléfono y repite el precio de una oferta. El centro dice que hacen horas extra, «voluntarias y bien pagadas». Velaria no quiere hacer comentarios."},
	{"id": "n_audio", "sitio": "centro", "pagina": "cc_correo", "victoria": "",
		"titular": "Se filtra un audio del gerente",
		"texto": "Canal 8 ha recibido un audio. Se oye al gerente del centro comercial, al teléfono: «Sí, lo tengo aquí. No se irá. Mis empleados no duermen, y él tendrá que dormir alguna vez». Velaria dice que no conoce a ese señor y que, si ha tomado algo suyo, «no habrá leído el prospecto»."},
	{"id": "n_helicoptero", "sitio": "centro", "pagina": "", "victoria": "centro",
		"titular": "Un helicóptero en la azotea",
		"texto": "Última hora: esta madrugada, un helicóptero de Velaria ha aterrizado en la azotea del centro comercial. A los diez minutos ha despegado otra vez... vacío. Velaria dice que era «un vuelo de reparto de medicinas». Y vuelve a buscar a su empleado de mantenimiento. Ahora, con recompensa."},
]


# Las noticias ya emitidas (las que se pueden ver en el ordenador), en su orden
static func noticias_emitidas(s: Dictionary) -> Array:
	return NOTICIAS.filter(func(n): return emitida(s, n))


static func emitida(s: Dictionary, n: Dictionary) -> bool:
	if n.pagina != "" and not encontrada(s, n.pagina):
		return false
	if n.victoria != "" and not s.edificios.get(n.victoria, {}).get("completado", false):
		return false
	return true


# Las emitidas que aún no se han visto
static func noticias_nuevas(s: Dictionary) -> Array:
	return noticias_emitidas(s).filter(func(n): return not n.id in s.noticias_vistas)


# Apunta una noticia como vista
static func ver_noticia(id: String) -> void:
	Guardado.cambiar(func(g):
		if not id in g.noticias_vistas:
			g.noticias_vistas.append(id))


static func dosier(edificio: String) -> Dictionary:
	return DOSIERES.get(edificio, {"titulo": "", "nota": "", "falta": "Esta página falta (%s).", "paginas": []})


static func encontrada(s: Dictionary, id: String) -> bool:
	return id in s.paginas


# La página que lleva el científico de esa planta, si aún no se ha encontrado ({} si no hay o ya está). Las que
# suelta el jefe no: esas no las lleva ningún muerto
static func pendiente(s: Dictionary, edificio: String, planta: int) -> Dictionary:
	for p in dosier(edificio).paginas:
		if p.planta == planta and not p.get("jefe", false) and not encontrada(s, p.id):
			return p
	return {}


# La página que suelta el jefe del edificio al caer, si aún no se ha encontrado ({} si no hay o ya está): en el
# centro comercial, la orden de recogida del gerente; en los Apartamentos, la lista de sujetos del científico jefe.
# La pide partida.pagina_del_jefe() al caer él en la azotea
static func del_jefe(s: Dictionary, edificio: String) -> Dictionary:
	for p in dosier(edificio).paginas:
		if p.get("jefe", false) and not encontrada(s, p.id):
			return p
	return {}


# Dónde está una página: su planta o, si la suelta el jefe, su sitio ("azotea")
static func donde(p: Dictionary) -> String:
	return p.get("donde", Planta.nombre_planta(p.planta).to_lower())


# Lo que dice el ordenador en el sitio de una página aún sin encontrar
static func falta(edificio: String, p: Dictionary) -> String:
	return p.get("falta", dosier(edificio).falta % donde(p))


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
