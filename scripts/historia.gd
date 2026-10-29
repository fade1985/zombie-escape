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
# Las NOTICIAS: emisiones de Canal 8 que se ven en el programa "Noticias" del ordenador. Van saliendo según se
# avanza (al empezar, al encontrar ciertas páginas, al completar el edificio): las páginas que encuentra Johnny le
# llegan a la reportera como de «una fuente de dentro», y en cada una Velaria cambia un poco su versión para tapar
# el experimento. Las vistas quedan en el guardado ("noticias_vistas").
#
# La historia, en corto (la decidió el dueño el 28 oct): el VD-7 de Velaria Corp. se vende para dormir, pero deja
# a la gente dormida y moviéndose, con el cuerpo pudriéndose y un hambre que muerde; el mordisco cambia el ADN del
# mordido. Los científicos llaman «durmientes» a los zombis y «sonámbulos» a los jefes de planta (sujetos con más
# dosis, que mutan más y dicen frases). El 14 es de Velaria: lo llenó de sujetos traídos en camiones y su propia
# seguridad lo precintó. Los tres supervivientes de los Apartamentos vinieron con los científicos (la médica, el
# policía y lo que queda de la escolta militar). Johnny es el Sujeto 0: no se convierte. Salas se pincha VD-7 puro
# para estar «por encima del ser humano». Marta Ruiz, la reportera, es hermana de Elena Ruiz (cc_turno).
#
# IDIOMAS: los textos están aquí en español (en los dosieres, cada línea con texto lleva al final la marca de traducir;
# las noticias van entre las dos marcas) y el inglés, en locale/en.po (docs/IDIOMAS.md). Para enseñarlos, titulo_de(),
# cuerpo_de(), titular_de(), texto_de(), canal(), donde(), falta() y hoja() los dan ya traducidos. En los dosieres no
# se marca el bloque entero porque las líneas de los colores (look) no son texto.
class_name Historia
extends RefCounted

const EMPRESA := "Velaria Corp."   # no-tr

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
		"titulo": "Dosier VD-7 · Apartamentos",   # [traducir]
		"nota": "Cada muerto de Velaria en el edificio lleva una página, y la última la lleva el director del estudio. Lo que encuentres queda aquí para siempre.",   # [traducir]
		"falta": "Esta página falta. La lleva alguien de Velaria caído en la %s.\n\nBúscalo en una partida.",   # [traducir]
		"paginas": [
			{"id": "vd7_protocolo", "planta": 1, "cuerpo": "Dra. Inés Lozano, coordinadora del estudio",   # [traducir]
				"look": {"skin": Color("#f1c27d"), "hair": Color("#2b2b2b")},
				"tipo": "PLAN DE CAMPO · CONFIDENCIAL", "titulo": "Estudio de descanso",   # [traducir]
				"texto": "Edificio: el número 14. Velaria Corp. lo ha comprado entero: nadie puede husmear.\n\nSujetos: 120, traídos de noche en camiones por el garaje de atrás, donde no los ve nadie. Gente sin casa, con deudas o enferma. Les damos piso y $300 al mes.\n\nDosis: una pastilla de VD-7 cada noche, a las 23:00.\n\nPersonal: una médica, para vigilar a los sujetos; un policía de uniforme, para que se fíen; y una escolta militar, por si algo sale mal. La portera trabaja para nosotros.",   # [traducir]
				"nota": "Salas dice que a esta gente no la va a echar de menos nadie. Por eso la ha elegido."},   # [traducir]
			{"id": "vd7_diario", "planta": 2, "cuerpo": "Tomás Vidal, enfermero de noche",   # [traducir]
				"look": {"skin": Color("#c68642"), "hair": Color("#1d1b2c")},
				"tipo": "DIARIO DE TURNO", "titulo": "Noches 6 a 13",   # [traducir]
				"texto": "Noche 6. Funciona. El del 1ºA, que no pegaba ojo desde hacía años, ronca a las 23:10.\n\nNoche 9. Siguen dormidos, pero se levantan. Andan, abren la nevera, vuelven a la cama. Con los ojos cerrados.\n\nNoche 12. Ya no vuelven a la cama. La piel se les cae a tiras. Se han comido todo lo de los pisos, y al perro del 2ºC. De la escolta solo queda uno.\n\nNoche 13. El del 3ºB me ha mordido. Salas los llama «durmientes». Tengo mucho sueño.",   # [traducir]
				"nota": ""},
			{"id": "vd7_correo", "planta": 3, "cuerpo": "Andrés Peña, técnico de muestras",   # [traducir]
				"look": {"skin": Color("#ffd2a8"), "hair": Color("#8a5a2b")},
				"tipo": "CORREO INTERNO IMPRESO", "titulo": "Asunto: RE: ¿virus?",   # [traducir]
				"texto": "De: Dirección de Velaria Corp.\nPara: Equipo de campo\n\nNo hay ningún virus, lo sabemos. Pero «virus» lo entiende todo el mundo y nadie pregunta por las pastillas.\n\nEsta noche nuestra seguridad precinta el edificio: nadie entra ni sale, tampoco vosotros ni la escolta. El edificio es nuestro y la policía de fuera no puede pasar.\n\nEl mordisco cambia el ADN del mordido: un durmiente más. No estaba previsto. Ahora forma parte del estudio.\n\nBorrad este correo.",   # [traducir]
				"nota": "No pienso borrarlo. Que lo lea alguien."},   # [traducir]
			{"id": "vd7_anexo", "planta": 4, "cuerpo": "Dr. Ramón Gil, investigador de Velaria",   # [traducir]
				"look": {"skin": Color("#e0ac69"), "hair": Color("#9b93a0")},
				"tipo": "INFORME · DOSIS ALTA", "titulo": "Los sonámbulos",   # [traducir]
				"texto": "Cuatro sujetos con dosis alta no se han quedado en durmientes. Han mutado más: cazan, piensan un poco y dicen frases. Salas los llama «sonámbulos».\n\nS-1. La portera. Dosis triple. Sigue fregando.\nS-2. Sin casa, Bajo C. Come sin parar. Grita «¡Tengo hambre!».\nS-3. Deudas, 1ºD. Lo mezcló con sus batidos. Ya no le cabe la ropa.\nS-4. Bombero jubilado, 2ºA. El fuego no le quema.\n\nSalas les saca sangre cada noche y se la sube a la azotea.",   # [traducir]
				"nota": "S-1 me ha llamado por mi nombre. Sacad al personal de las plantas de arriba. YA."},   # [traducir]
			# La última no la lleva un muerto: la suelta el científico jefe (el director del estudio) al caer en la
			# azotea (del_jefe)
			{"id": "vd7_sujeto_cero", "planta": 5, "jefe": true, "donde": "azotea",
				"falta": "Esta página falta. La lleva el director del estudio, arriba del todo, en la azotea.\n\nTendrás que quitársela.",   # [traducir]
				"cuerpo": "Dr. Héctor Salas, director del estudio",   # [traducir]
				"look": {"skin": Color("#f1c27d"), "hair": Color("#d9d1bd")},
				"tipo": "LISTA DE SUJETOS · SOLO DIRECCIÓN", "titulo": "Sujeto 0",   # [traducir]
				"texto": "Durmientes: 131, contando al personal. Sonámbulos: 4.\n\nSujeto 0: el conserje. Se quedó en el edificio porque yo lo pedí. Le han mordido más de 30 veces y no se convierte. Cuando acaba con un sonámbulo, el VD-7 le cambia el cuerpo unas horas, pero no la cabeza. Su sangre lo deshace.\n\nEs la cura. O el arma. Que el helicóptero lo lleve vivo a la sede.\n\nYo no espero. Los sonámbulos son el camino: VD-7 puro, todo de golpe, y estaré por encima del ser humano.",   # [traducir]
				"nota": "Si lees esto, conserje: no te fíes de la gente con bata. Tampoco de los que vengan a rescatarte."},   # [traducir]
		],
	},
	# «Turno infinito»: el gerente del centro pone VD-7 en el café de sus empleados para que trabajen sin parar, y
	# quiere entregarle a Johnny a Velaria a cambio de «la dosis buena» (docs/historial/CENTRO_COMERCIAL.md, Historia)
	"centro": {
		"titulo": "Dosier VD-7 · Centro comercial",   # [traducir]
		"nota": "En cada planta hay un cuerpo con una página, y la última la lleva el gerente. Lo que encuentres queda aquí para siempre.",   # [traducir]
		"falta": "Esta página falta. Está junto a un cuerpo, en la %s.\n\nBúscalo en una partida.",   # [traducir]
		"paginas": [
			{"id": "cc_albaran", "planta": 1, "cuerpo": "Julián Mora, farmacéutico de Velaria",   # [traducir]
				"look": {"skin": Color("#e0ac69"), "hair": Color("#4a3426")},
				"tipo": "ALBARÁN DE ENTREGA", "titulo": "Pedido para la farmacia",   # [traducir]
				"texto": "Producto: «Velaria Noche», contra el insomnio. 10.000 cajas de 20 pastillas.\n\nCada pastilla: un cuarto de dosis de VD-7. Venta libre, sin receta. Precio: $3,99.\n\nColocar junto a las cajas, a la altura de los ojos. Cartel: «Duerme como un bebé».\n\nSi un cliente pregunta por el edificio 14, se le atiende fuera de la tienda y se avisa a la seguridad de Velaria Corp.",   # [traducir]
				"nota": "¿Sin receta? Yo esto no lo vendo. La chica de la rebotica, tampoco."},   # [traducir]
			{"id": "cc_turno", "planta": 2, "cuerpo": "Dra. Elena Ruiz, técnica de Velaria",   # [traducir]
				"look": {"skin": Color("#ffd2a8"), "hair": Color("#b5651d")},
				"tipo": "CONTRATO · CONFIDENCIAL", "titulo": "Programa «Turno infinito»",   # [traducir]
				"texto": "Entre Velaria Corp. y la gerencia del centro comercial.\n\nVelaria entrega el VD-7 gratis. El centro lo echa en la cafetera de la sala de descanso de los empleados, a dosis completa. Ellos no lo saben.\n\nObjetivo: turnos de 20 horas, sin cansancio y sin quejas. Velaria se queda con los datos de 312 empleados.\n\nSi sale bien, Velaria Corp. lo venderá a fábricas, almacenes y hospitales: un turno infinito para todo el país.",   # [traducir]
				"nota": "Marta, si te llega esto: no vengas al centro. Por favor."},   # [traducir]
			{"id": "cc_incidencias", "planta": 3, "cuerpo": "Manuel Ortega, jefe de seguridad del centro",   # [traducir]
				"look": {"skin": Color("#c68642"), "hair": Color("#2b2b2b"), "ropa": Color("#2f3b5c"),
					"pantalon": Color("#23283a"), "tarjeta": Color("#d9b44a")},
				"tipo": "PARTE DE INCIDENCIAS", "titulo": "Turno de noche",   # [traducir]
				"texto": "02:10. Cerrado desde las 22:00. Los cajeros siguen cobrando a nadie.\n\n03:40. El cocinero fríe sin aceite. La del taller de costura viste maniquíes. El del oso de la juguetería saluda al pasillo vacío.\n\n04:15. Tienen los ojos cerrados. Siguen trabajando. Si te acercas, muerden.\n\n05:00. El gerente dice que no es una incidencia: «Rinden más que nunca».\n\n05:30. Pido ayuda. Velaria Corp. manda un antidisturbios. Entra en la oficina de seguridad. No sale.",   # [traducir]
				"nota": "Esta noche no me tomo el café."},   # [traducir]
			{"id": "cc_correo", "planta": 4, "cuerpo": "Lucía Benet, secretaria del gerente",   # [traducir]
				"look": {"skin": Color("#f1c27d"), "hair": Color("#1d1b2c"), "ropa": Color("#a34a6a"),
					"pantalon": Color("#3a3a46"), "tarjeta": Color("#e8e8e0")},
				"tipo": "CORREO IMPRESO · GERENCIA", "titulo": "Asunto: El conserje",   # [traducir]
				"texto": "De: Gerencia del centro comercial\nPara: Velaria Corp., Dirección\n\nEl conserje del 14 está en el centro. Lo veo en las cámaras: sube planta por planta, como si buscara algo.\n\nNo voy a llamar a la policía. Lo retengo hasta que llegue vuestro helicóptero. He cerrado las salidas, y mis empleados no se cansan.\n\nA cambio, quiero la dosis buena. La de verdad.",   # [traducir]
				"nota": "Lleva cuatro días sin dormir. Dice que ya no le hace falta."},   # [traducir]
			# La última no la lleva un muerto: la suelta el gerente al caer en la azotea (del_jefe). La azotea y el
			# gerente llegan en el trozo 6 de la parte 4
			{"id": "cc_recogida", "planta": 5, "jefe": true, "donde": "azotea",
				"falta": "Esta página falta. La lleva el gerente del centro, arriba del todo, en la azotea.\n\nTendrás que quitársela.",   # [traducir]
				"cuerpo": "Arturo Salcedo, gerente del centro",   # [traducir]
				"look": {"skin": Color("#f1c27d"), "hair": Color("#6e6a64")},
				"tipo": "ORDEN DE RECOGIDA · URGENTE", "titulo": "Recogida del Sujeto 0",   # [traducir]
				"texto": "Lugar: helipuerto de la azotea del centro comercial. Hora: en cuanto avise el gerente.\n\nCarga: el Sujeto 0, el conserje del 14. Vivo. No gastéis VD-7 con él: no le hace nada.\n\nDestino: Torre Velaria, nuestra sede. Directo al laboratorio de la planta 40. Él ya lo conoce, aunque no se acuerde.\n\nEl gerente no viaja. Lo que pidió no se le entrega. Mandadle una jeringa para que aguante hasta que lleguemos.",   # [traducir]
				"nota": "Me prometieron la dosis buena. Me mandaron una jeringa y esta hoja."},   # [traducir]
		],
	},
}


# ── Las noticias ──
const CANAL := "Canal 8"   # [traducir]
const REPORTERA := "Marta Ruiz"   # no-tr

# Cada emisión:
#   id        no cambiar una vez publicada (el guardado apunta las vistas por su id)
#   pagina    sale al encontrar esa página del dosier ("" = no depende de ninguna)
#   victoria  sale al completar ese edificio ("" = no depende)
#   (si no depende de nada, sale desde la primera partida)
#   titular   el rótulo de abajo de la pantalla (corto: unas 30 letras)
#   texto     lo que cuenta la reportera
#   sitio     dónde está la reportera (la calle de detrás, ui/tele.gd): "centro" en las del centro comercial; si no
#             está, delante del número 14
# Los textos, en español; para enseñarlos, titular_de() y texto_de() los dan ya traducidos
# [traducir]
const NOTICIAS := [
	{"id": "n_cierre", "pagina": "", "victoria": "",
		"titular": "Cierran un edificio por un virus",
		"texto": "Buenas noches. Les hablo desde la puerta del número 14. Desde esta mañana, la seguridad privada de Velaria Corp., la dueña del edificio, no deja entrar ni salir a nadie. Según la empresa, dentro hay un virus muy contagioso. «La situación está controlada», nos dicen. Y piden que nadie se acerque."},
	{"id": "n_estudio", "pagina": "vd7_protocolo", "victoria": "",
		"titular": "Camiones de noche en el 14",
		"texto": "Alguien desde dentro del 14 nos ha mandado un documento. Según él, Velaria compró el edificio y lo llenó de gente sin casa, con deudas o enferma, traída de noche en camiones, para probar unas pastillas para dormir. Velaria lo niega: «Era un programa social de vivienda»."},
	{"id": "n_correo", "pagina": "vd7_correo", "victoria": "",
		"titular": "Un correo dice: no hay virus",
		"texto": "Nuestra fuente del 14 nos manda un correo interno de Velaria: «No hay ningún virus, lo sabemos». La empresa dice que es falso. Y añade que, si alguien está enfermo, será por «unas pastillas para dormir en mal estado, de otra marca». Sigue sin decir qué marca."},
	{"id": "n_portera", "pagina": "vd7_anexo", "victoria": "",
		"titular": "¿Dónde está la portera?",
		"texto": "La fuente habla ahora de cuatro «sonámbulos»: residentes que tomaron más dosis y que todavía hablan. Una sería la portera del 14, a la que nadie ha visto desde el cierre. Velaria dice que era «una señora con problemas que nunca trabajó para nosotros». De noche se oyen gritos arriba."},
	{"id": "n_buscado", "pagina": "", "victoria": "apartamentos",
		"titular": "Velaria busca a un conserje",
		"texto": "Última hora: anoche, un helicóptero de Velaria se posó en la azotea del 14. Al despegar, alguien colgaba de su escalera... y se soltó sobre los árboles de la avenida. Hoy Velaria busca a un empleado de mantenimiento «que se ha llevado documentos de la empresa». ¿Es nuestra fuente?"},
	# El centro comercial: «Turno infinito»
	{"id": "n_reformas", "sitio": "centro", "pagina": "", "victoria": "apartamentos",
		"titular": "El centro cierra «por reformas»",
		"texto": "Buenas noches. El centro comercial de la avenida cierra de noche «por reformas». Pero las luces siguen encendidas hasta el amanecer, la alarma de incendios suena de madrugada y dentro se ve gente moviéndose. Velaria, que tiene allí una farmacia, dice: «Nosotros solo alquilamos un local»."},
	{"id": "n_velaria_noche", "sitio": "centro", "pagina": "cc_albaran", "victoria": "",
		"titular": "Velaria vende su somnífero",
		"texto": "Ya está a la venta «Velaria Noche», contra el insomnio. Sin receta y a $3,99. Las cajas se agotan en horas. Nuestra fuente dice que es lo mismo que se probó en el 14, rebajado. Velaria lo niega: «Es una fórmula nueva, natural y segura. La tomamos nosotros todas las noches»."},
	{"id": "n_turnos", "sitio": "centro", "pagina": "cc_turno", "victoria": "",
		"titular": "Empleados que no vuelven a casa",
		"texto": "Decenas de familias denuncian que sus parientes, empleados del centro comercial, no vuelven a casa. El centro dice que hacen horas extra, «voluntarias y bien pagadas». Y les cuento algo mío: mi hermana Elena trabaja allí para Velaria. Desde el lunes no me coge el teléfono."},
	{"id": "n_audio", "sitio": "centro", "pagina": "cc_correo", "victoria": "",
		"titular": "Se filtra un audio del gerente",
		"texto": "Nos llega un audio del gerente del centro comercial, al teléfono: «Sí, el conserje está aquí. No se irá. Mis empleados no duermen, y él tendrá que dormir alguna vez». Velaria dice que no conoce a ese señor y que, si ha tomado algo suyo, «no habrá leído el prospecto»."},
	{"id": "n_helicoptero", "sitio": "centro", "pagina": "", "victoria": "centro",
		"titular": "Un helicóptero en la azotea",
		"texto": "Última hora: el helicóptero de Velaria ha vuelto, esta vez a la azotea del centro comercial. Ha despegado con alguien dentro, rumbo a Torre Velaria. Velaria ya no busca a su conserje: «Está con nosotros, a salvo». Mañana presenta en su torre «el futuro del trabajo». De mi hermana, nada."},
]
# [/traducir]


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


# El rótulo de una noticia y lo que cuenta la reportera, en el idioma del jugador
static func titular_de(n: Dictionary) -> String:
	return Idioma.t(n.titular)


static func texto_de(n: Dictionary) -> String:
	return Idioma.t(n.texto)


# El nombre del canal de la tele, en el idioma del jugador ("Channel 8")
static func canal() -> String:
	return Idioma.t(CANAL)


static func dosier(edificio: String) -> Dictionary:
	return DOSIERES.get(edificio, {"titulo": "", "nota": "", "falta": "Esta página falta (%s).", "paginas": []})   # [traducir]


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


# El título de una página y quién la llevaba, en el idioma del jugador
static func titulo_de(p: Dictionary) -> String:
	return Idioma.t(p.titulo)


static func cuerpo_de(p: Dictionary) -> String:
	return Idioma.t(p.cuerpo)


# Dónde está una página, en el idioma del jugador: su planta o, si la suelta el jefe, su sitio (hoy solo "azotea"; un
# sitio nuevo necesita aquí su propio Idioma.t, porque la herramienta no recoge de la tabla las palabras en minúscula)
static func donde(p: Dictionary) -> String:
	if p.get("donde", "") == "azotea":
		return Idioma.t("azotea")
	return p.get("donde", Idioma.minusculas(Planta.nombre_planta(p.planta)))


# Lo que dice el ordenador en el sitio de una página aún sin encontrar, en el idioma del jugador
static func falta(edificio: String, p: Dictionary) -> String:
	if p.has("falta"):
		return Idioma.t(p.falta)
	return Idioma.t(dosier(edificio).falta) % donde(p)


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


# La hoja de una página encontrada, en el idioma del jugador
static func hoja(p: Dictionary, ancho := 560.0) -> PanelContainer:
	return dibujar_hoja(Idioma.t(p.tipo), titulo_de(p), Idioma.t(p.texto), Idioma.t(p.nota), ancho)


# La hoja de una página aún sin encontrar (el ordenador): arrancada, con lo que dice falta() en vez del texto
static func hoja_arrancada(edificio: String, p: Dictionary, ancho := 560.0) -> PanelContainer:
	return dibujar_hoja("???", Idioma.t("Página arrancada"), falta(edificio, p), "", ancho)


# El papel, con los textos ya en el idioma del jugador (a_mano = "": sin nota a mano al pie)
static func dibujar_hoja(tipo_doc: String, titulo: String, escrito: String, a_mano: String, ancho: float) -> PanelContainer:
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
	var tipo := texto(tipo_doc, ROJO, 16)
	tipo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arriba.add_child(tipo)
	arriba.add_child(texto(EMPRESA.to_upper(), Color(TINTA, 0.55), 16))
	columna.add_child(texto(titulo, TINTA, 32))
	var raya := ColorRect.new()
	raya.color = Color(TINTA, 0.4)
	raya.custom_minimum_size.y = 2
	columna.add_child(raya)
	var cuerpo := texto(escrito, TINTA, 16)
	cuerpo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(cuerpo)
	if a_mano != "":
		var nota := texto("— " + a_mano, BOLI, 16)
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
