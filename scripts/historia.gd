# La historia del juego: el "Proyecto VD-7". En cada planta hay un muerto (casi siempre, un científico de Velaria)
# con una página del dosier de ese edificio; al cogerla se lee y queda guardada para siempre (Guardado: "paginas").
# Todo lo encontrado se puede releer en el ordenador de la sala de mantenimiento (programa "Dosier").
# Un muerto solo aparece mientras queden páginas sin encontrar: así la historia no se repite. Cada uno lleva la primera
# que te falte (si no la coges, pasa al de la planta siguiente); con cuatro plantas y cinco páginas, dos partidas. Ningún
# jefe suelta páginas. Con cada página se hace una noticia de la tele de un salón (la número N con la página N).
#
# PARA CAMBIAR LA HISTORIA: todo el texto está aquí. Se puede reescribir cualquier página, cambiar nombres o
# añadir edificios nuevos (una entrada más en DOSIERES). Lo único que no hay que tocar es el "id" de una página
# ya publicada: el guardado de los jugadores apunta las encontradas por su id.
#
# Las NOTICIAS: emisiones de Canal 8 que se ven en la tele de un salón (mapa/tele_salon.gd): cada planta tiene una tele
# que, al limpiar su apartamento, se enciende y enseña la primera noticia de ese edificio que aún no has visto. Las
# páginas que encuentra Johnny le llegan a la reportera como de «una fuente de dentro», y en cada una Velaria cambia un
# poco su versión para tapar el experimento. Las vistas quedan en el guardado ("videos_vistos") y se repiten en el
# programa VIDEOS.EXE del ordenador.
#
# Los RELATOS: los textos que salen una sola vez sobre negro (ui/relato.gd): la introducción y un final por edificio.
# Los ya salidos quedan en el guardado ("relatos").
#
# La historia, en corto (la decidió el dueño el 28 oct): el VD-7 de Velaria Corp. se vende para dormir, pero deja
# a la gente dormida y moviéndose, con el cuerpo pudriéndose y un hambre que muerde; el mordisco cambia el ADN del
# mordido. Los científicos llaman «durmientes» a los zombis y «noctámbulos» a los jefes de planta (sujetos con más
# dosis, que mutan más y dicen frases). El 14 es de Velaria: lo llenó de sujetos traídos en camiones y su propia
# seguridad lo precintó. Los tres supervivientes de los Apartamentos vinieron con los científicos (la médica, el
# policía y lo que queda de la escolta militar). Johnny es el Sujeto 0: no se convierte. Salas se pincha VD-7 puro
# para estar «por encima del ser humano». Marta Ruiz, la reportera, es hermana de Elena Ruiz (cc_turno).
#
# IDIOMAS: los textos están aquí en español (en los dosieres, cada línea con texto lleva al final la marca de traducir;
# las noticias y los relatos van entre las dos marcas) y el inglés, en locale/en.po (docs/IDIOMAS.md). Para enseñarlos,
# titulo_de(), cuerpo_de(), titular_de(), texto_de(), canal(), donde(), falta(), lineas_de() y hoja() los dan ya
# traducidos. En los dosieres no se marca el bloque entero porque las líneas de los colores (look) no son texto.
class_name Historia
extends RefCounted

const EMPRESA := "Velaria Corp."   # no-tr

# Un dosier por edificio (la clave es el id del edificio, el EDIFICIO de partida.gd). Del dosier:
#   titulo
#   nota     lo que explica el ordenador debajo del título
#   falta    lo que dice el ordenador en el sitio de una página aún sin encontrar
# Cada página:
#   id       no cambiar una vez publicada
#   cuerpo   quién es el muerto (sale al encontrarlo)
#   look     los colores de su dibujo (cientifico.gd): piel y pelo (todos llevan la bata de Velaria)
#   tipo     qué clase de papel es (sale arriba de la hoja)
#   titulo, texto, nota (lo escrito a mano al pie, o "")
# El orden de la lista es el orden en que salen (y el de las noticias de ese edificio).
const DOSIERES := {
	"apartamentos": {
		"titulo": "Dosier VD-7 · Apartamentos",   # [traducir]
		"nota": "Cada planta tiene un muerto de Velaria con una página. Si no la coges, pasa a la planta siguiente. Lo que encuentres queda aquí para siempre.",   # [traducir]
		"falta": "Esta página falta. La lleva un muerto de Velaria, en alguna planta: siempre sale la primera que te falte.\n\nBúscalo en una partida.",   # [traducir]
		"paginas": [
			{"id": "vd7_protocolo", "cuerpo": "Dra. Inés Lozano, coordinadora del estudio",   # [traducir]
				"look": {"skin": Color("#f1c27d"), "hair": Color("#2b2b2b")},
				"tipo": "PLAN DE CAMPO · CONFIDENCIAL", "titulo": "Estudio de descanso",   # [traducir]
				"texto": "Edificio: el número 14. Velaria Corp. lo ha comprado entero: nadie puede husmear.\n\nSujetos: 120, traídos de noche en camiones por el garaje de atrás, donde no los ve nadie. Gente sin casa, con deudas o enferma. Les damos piso y $300 al mes.\n\nDosis: una pastilla de VD-7 cada noche, a las 23:00.\n\nPersonal: una médica, para vigilar a los sujetos; un policía de uniforme, para que se fíen; y una escolta militar, por si algo sale mal. La portera trabaja para nosotros.",   # [traducir]
				"nota": "Salas dice que nadie los echará de menos."},   # [traducir]
			{"id": "vd7_diario", "cuerpo": "Tomás Vidal, enfermero de noche",   # [traducir]
				"look": {"skin": Color("#c68642"), "hair": Color("#1d1b2c")},
				"tipo": "DIARIO DE TURNO", "titulo": "Noches 6 a 13",   # [traducir]
				"texto": "Noche 6. Funciona. El del 1ºA, que no pegaba ojo desde hacía años, ronca a las 23:10.\n\nNoche 9. Siguen dormidos, pero se levantan. Andan, abren la nevera, vuelven a la cama. Con los ojos cerrados.\n\nNoche 12. Ya no vuelven a la cama. La piel se les cae a tiras. Se han comido todo lo de los pisos, y al perro del 2ºC. De la escolta solo queda uno.\n\nNoche 13. El del 3ºB me ha mordido. Salas los llama «durmientes». Tengo mucho sueño.",   # [traducir]
				"nota": ""},
			{"id": "vd7_correo", "cuerpo": "Andrés Peña, técnico de muestras",   # [traducir]
				"look": {"skin": Color("#ffd2a8"), "hair": Color("#8a5a2b")},
				"tipo": "CORREO INTERNO IMPRESO", "titulo": "Asunto: RE: ¿virus?",   # [traducir]
				"texto": "De: Dirección de Velaria Corp.\nPara: Equipo de campo\n\nNo hay ningún virus, lo sabemos. Pero «virus» lo entiende todo el mundo y nadie pregunta por las pastillas.\n\nEsta noche nuestra seguridad precinta el edificio: nadie entra ni sale, tampoco vosotros ni la escolta. El edificio es nuestro y la policía de fuera no puede pasar.\n\nEl mordisco cambia el ADN del mordido: un durmiente más. No estaba previsto. Ahora forma parte del estudio.\n\nBorrad este correo.",   # [traducir]
				"nota": "No lo borro. Que alguien lo lea."},   # [traducir]
			{"id": "vd7_anexo", "cuerpo": "Dr. Ramón Gil, investigador de Velaria",   # [traducir]
				"look": {"skin": Color("#e0ac69"), "hair": Color("#9b93a0")},
				"tipo": "INFORME · DOSIS ALTA", "titulo": "Los noctámbulos",   # [traducir]
				"texto": "Cuatro sujetos con dosis alta no se han quedado en durmientes. Han mutado más: cazan, piensan un poco y dicen frases. Salas los llama «noctámbulos».\n\nS-1. La portera. Dosis triple. Sigue fregando.\nS-2. Sin casa, Bajo C. Come sin parar. Grita «¡Tengo hambre!».\nS-3. Deudas, 1ºD. Lo mezcló con sus batidos. Ya no le cabe la ropa.\nS-4. Bombero jubilado, 2ºA. El fuego no le quema.\n\nSalas les saca sangre cada noche y se la sube a la azotea.",   # [traducir]
				"nota": "S-1 sabe mi nombre. ¡Evacuad arriba YA!"},   # [traducir]
			{"id": "vd7_sujeto_cero", "cuerpo": "Ayudante del director del estudio",   # [traducir]
				"look": {"skin": Color("#f1c27d"), "hair": Color("#d9d1bd")},
				"tipo": "LISTA DE SUJETOS · SOLO DIRECCIÓN", "titulo": "Sujeto 0",   # [traducir]
				"texto": "Durmientes: 131, contando al personal. Noctámbulos: 4.\n\nSujeto 0: el conserje. Se quedó en el edificio porque yo lo pedí. Le han mordido más de 30 veces y no se convierte. Cuando acaba con un noctámbulo, el VD-7 le cambia el cuerpo unas horas, pero no la cabeza. Su sangre lo deshace.\n\nEs la cura. O el arma. Que el helicóptero lo lleve vivo a la sede.\n\nYo no espero. Los noctámbulos son el camino: VD-7 puro, todo de golpe, y estaré por encima del ser humano.",   # [traducir]
				"nota": "Conserje: no te fíes de las batas. Ni de quien te rescate."},   # [traducir]
		],
	},
	# «Turno infinito»: el gerente del centro pone VD-7 en el café de sus empleados para que trabajen sin parar, y
	# quiere entregarle a Johnny a Velaria a cambio de «la dosis buena» (docs/historial/CENTRO_COMERCIAL.md, Historia)
	"centro": {
		"titulo": "Dosier VD-7 · Centro comercial",   # [traducir]
		"nota": "Cada planta tiene un muerto de Velaria con una página. Si no la coges, pasa a la planta siguiente. Lo que encuentres queda aquí para siempre.",   # [traducir]
		"falta": "Esta página falta. La lleva un muerto de Velaria, en alguna planta: siempre sale la primera que te falte.\n\nBúscalo en una partida.",   # [traducir]
		"paginas": [
			{"id": "cc_albaran", "cuerpo": "Julián Mora, farmacéutico de Velaria",   # [traducir]
				"look": {"skin": Color("#e0ac69"), "hair": Color("#4a3426")},
				"tipo": "ALBARÁN DE ENTREGA", "titulo": "Pedido para la farmacia",   # [traducir]
				"texto": "Producto: «Velaria Noche», contra el insomnio. 10.000 cajas de 20 pastillas.\n\nCada pastilla: un cuarto de dosis de VD-7. Venta libre, sin receta. Precio: $3,99.\n\nColocar junto a las cajas, a la altura de los ojos. Cartel: «Duerme como un bebé».\n\nSi un cliente pregunta por el edificio 14, se le atiende fuera de la tienda y se avisa a la seguridad de Velaria Corp.",   # [traducir]
				"nota": "¿Sin receta? Esto no lo vendo."},   # [traducir]
			{"id": "cc_turno", "cuerpo": "Dra. Elena Ruiz, técnica de Velaria",   # [traducir]
				"look": {"skin": Color("#ffd2a8"), "hair": Color("#b5651d")},
				"tipo": "CONTRATO · CONFIDENCIAL", "titulo": "Programa «Turno infinito»",   # [traducir]
				"texto": "Entre Velaria Corp. y la gerencia del centro comercial.\n\nVelaria entrega el VD-7 gratis. El centro lo echa en la cafetera de la sala de descanso de los empleados, a dosis completa. Ellos no lo saben.\n\nObjetivo: turnos de 20 horas, sin cansancio y sin quejas. Velaria se queda con los datos de 312 empleados.\n\nSi sale bien, Velaria Corp. lo venderá a fábricas, almacenes y hospitales: un turno infinito para todo el país.",   # [traducir]
				"nota": "Marta: no vengas al centro. Por favor."},   # [traducir]
			{"id": "cc_incidencias", "cuerpo": "Dr. Tomás Vidal, químico de Velaria",   # [traducir]
				"look": {"skin": Color("#c68642"), "hair": Color("#2b2b2b")},   # M86: un científico, con su bata
				"tipo": "PARTE DE INCIDENCIAS", "titulo": "Turno de noche",   # [traducir]
				"texto": "02:10. Cerrado desde las 22:00. Los cajeros siguen cobrando a nadie.\n\n03:40. El cocinero fríe sin aceite. La del taller de costura viste maniquíes. El del oso de la juguetería saluda al pasillo vacío.\n\n04:15. Tienen los ojos cerrados. Siguen trabajando. Si te acercas, muerden.\n\n05:00. El gerente dice que no es una incidencia: «Rinden más que nunca».\n\n05:30. Pido ayuda. Velaria Corp. manda un antidisturbios. Entra en la oficina de seguridad. No sale.",   # [traducir]
				"nota": "Era del vigilante. No llegó a la mañana."},   # [traducir]
			{"id": "cc_correo", "cuerpo": "Dra. Irene Soler, enlace de Velaria con la gerencia",   # [traducir]
				"look": {"skin": Color("#f1c27d"), "hair": Color("#1d1b2c")},   # M86: una científica, con su bata
				"tipo": "CORREO IMPRESO · GERENCIA", "titulo": "Asunto: El conserje",   # [traducir]
				"texto": "De: Gerencia del centro comercial\nPara: Velaria Corp., Dirección\n\nEl conserje del 14 está en el centro. Lo veo en las cámaras: sube planta por planta, como si buscara algo.\n\nNo voy a llamar a la policía. Lo retengo hasta que llegue vuestro helicóptero. He cerrado las salidas, y mis empleados no se cansan.\n\nA cambio, quiero la dosis buena. La de verdad.",   # [traducir]
				"nota": "El gerente ya no duerme. Dice que no le hace falta."},   # [traducir]
			{"id": "cc_recogida", "cuerpo": "Auxiliar de la gerencia del centro",   # [traducir]
				"look": {"skin": Color("#f1c27d"), "hair": Color("#6e6a64")},
				"tipo": "ORDEN DE RECOGIDA · URGENTE", "titulo": "Recogida del Sujeto 0",   # [traducir]
				"texto": "Lugar: helipuerto de la azotea del centro comercial. Hora: en cuanto avise el gerente.\n\nCarga: el Sujeto 0, el conserje del 14. Vivo. No gastéis VD-7 con él: no le hace nada.\n\nDestino: Torre Velaria, nuestra sede. Directo al laboratorio de la planta 40. Él ya lo conoce, aunque no se acuerde.\n\nEl gerente no viaja. Lo que pidió no se le entrega. Mandadle una jeringa para que aguante hasta que lleguemos.",   # [traducir]
				"nota": "Me prometieron la dosis buena. Solo vino esto."},   # [traducir]
		],
	},
	# Torre Velaria: por qué Johnny «ya conoce» la planta 40. Hace once años fue el voluntario del primer ensayo del
	# VD-7; no se convirtió, le borraron la memoria y lo pusieron de conserje en el 14 para tenerlo cerca. Con su
	# sangre han hecho el Sujeto 1. La presidenta (Clara Velar) quiere presentarlo como «el empleado perfecto» y
	# llevar el VD-7 del aire de la torre a todo el país. Las plantas son el vestíbulo y la 10, 20, 30 y 40
	"torre": {
		"titulo": "Dosier VD-7 · Torre Velaria",   # [traducir]
		"nota": "Cada planta tiene un muerto de Velaria con una página. Si no la coges, pasa a la planta siguiente. Lo que encuentres queda aquí para siempre.",   # [traducir]
		"falta": "Esta página falta. La lleva un muerto de Velaria, en alguna planta: siempre sale la primera que te falte.\n\nBúscalo en una partida.",   # [traducir]
		"paginas": [
			{"id": "tv_visitas", "cuerpo": "Dra. Nuria Castell, médica de guardia de Velaria",   # [traducir]
				"look": {"skin": Color("#e0ac69"), "hair": Color("#1d1b2c")},
				"tipo": "LIBRO DE VISITAS · HACE 11 AÑOS", "titulo": "Visitas del turno de noche",   # [traducir]
				"texto": "14 de marzo. 23:40. Dr. H. Salas. Planta 40.\n\n14 de marzo. 23:52. J. Rush, voluntario. Planta 40. Le acompaña seguridad. Firma con buena letra.\n\n15 de marzo. J. Rush no firma la salida.\n\n(Las tres semanas siguientes, arrancadas.)\n\n4 de abril. 06:10. J. Rush sale. Firma con una X. Le acompaña seguridad. Destino: «número 14, conserje».",   # [traducir]
				"nota": "Es el conserje de las noticias. Ya estuvo aquí."},   # [traducir]
			{"id": "tv_bienestar", "cuerpo": "Dra. Marina Ortega, médica de empresa",   # [traducir]
				"look": {"skin": Color("#ffd2a8"), "hair": Color("#8a5a2b")},
				"tipo": "CIRCULAR DE RECURSOS HUMANOS", "titulo": "Programa Bienestar",   # [traducir]
				"texto": "Para toda la plantilla de Torre Velaria: desde el lunes, la torre estrena aire acondicionado. Más fresco, más descanso, mejor ambiente. Gracias por vuestro esfuerzo.\n\nANEXO, SOLO PARA DIRECCIÓN: el aire lleva VD-7 en dosis muy baja, en las cuarenta plantas. Empleados más tranquilos, más horas, ninguna queja.\n\nSi alguien se duerme en su mesa, no se le despierta. Recursos Humanos lo recoge por la noche y lo sube a la planta 40.",   # [traducir]
				"nota": "40 bajas «por cansancio». Me pongo mascarilla."},   # [traducir]
			{"id": "tv_guion", "cuerpo": "Dr. Pablo Ferrer, asesor científico de la presentación",   # [traducir]
				"look": {"skin": Color("#c68642"), "hair": Color("#2b2b2b")},
				"tipo": "GUION · NO DIFUNDIR", "titulo": "El futuro del trabajo",   # [traducir]
				"texto": "LUZ. MÚSICA. Sale el presentador.\n\nPRESENTADOR: ¿Cansados? ¿Otra vez lunes? Eso se acabó.\n\nPRESENTADOR: Velaria presenta el Turno Infinito: el VD-7 en el aire de cada oficina, cada fábrica y cada hospital del país.\n\nSe abre el telón. Sale el Sujeto 1.\n\nPRESENTADOR: Les presento al empleado perfecto. No duerme. No se cansa. No pide vacaciones.\n\nAPLAUSOS (grabados: el público ya no aplaude).",   # [traducir]
				"nota": "Quieren que escriba que es seguro. Yo lo he visto."},   # [traducir]
			{"id": "tv_sujeto_1", "cuerpo": "Dr. Andrés Lin, investigador del laboratorio",   # [traducir]
				"look": {"skin": Color("#f1c27d"), "hair": Color("#9b93a0")},
				"tipo": "INFORME · LABORATORIO 40", "titulo": "Sujeto 1",   # [traducir]
				"texto": "Origen: la sangre del Sujeto 0, sacada una vez al mes durante once años, en sus «revisiones médicas de empresa».\n\nResultado: dos metros y medio. No duerme. No se cansa. No se convierte.\n\nImita lo que ve. Le pusimos vídeos del Sujeto 0 trabajando y ahora friega el suelo del laboratorio.\n\nProblema: no obedece. Ha roto dos cápsulas y a tres técnicos.\n\nLa presidenta dice que da igual: se presenta el viernes.",   # [traducir]
				"nota": "Ayer me dijo «turno de noche». Como el conserje."},   # [traducir]
			{"id": "tv_sujeto_cero", "cuerpo": "Asistente de la presidencia de Velaria",   # [traducir]
				"look": {"skin": Color("#c9b8d6"), "hair": Color("#3b2a4a")},
				"tipo": "FICHA DE SUJETO · SOLO PRESIDENCIA", "titulo": "Sujeto 0",   # [traducir]
				"texto": "Nombre: Johnny Rush. Repartidor de noche, sin familia y con deudas. Se presentó voluntario al primer ensayo del VD-7 por $500.\n\nDosis: cuarenta veces la normal. No se durmió. No se convirtió. Su sangre deshace el VD-7.\n\nDespués: tres semanas de borrado de memoria. Nuevo trabajo: conserje del número 14, un edificio nuestro, para tenerlo cerca. Revisión médica cada mes.\n\nSi recuerda, avisar a Presidencia. Si escapa, recuperarlo vivo. Es lo único que tenemos que funciona.",   # [traducir]
				"nota": "En la foto, con letra torpe: «PAPÁ»."},   # [traducir]
		],
	},
}


# ── Las noticias ──
const CANAL := "Canal 8"   # [traducir]
const REPORTERA := "Marta Ruiz"   # no-tr

# Cada emisión:
#   id        no cambiar una vez publicada (el guardado apunta las vistas por su id)
#   titular   el rótulo de abajo de la pantalla (corto: unas 30 letras)
#   texto     lo que cuenta la reportera
#   sitio     dónde está la reportera (la calle de detrás, ui/tele.gd): "centro" en las del centro comercial; si no
#             está, delante del número 14
# Los textos, en español; para enseñarlos, titular_de() y texto_de() los dan ya traducidos
# [traducir]
const NOTICIAS := [
	{"id": "n_cierre",
		"titular": "Cierran un edificio por un virus",
		"texto": "Buenas noches. Les hablo desde la puerta del número 14. Desde esta mañana, la seguridad privada de Velaria Corp., la dueña del edificio, no deja entrar ni salir a nadie. Según la empresa, dentro hay un virus muy contagioso. «La situación está controlada», nos dicen. Y piden que nadie se acerque."},
	{"id": "n_estudio",
		"titular": "Camiones de noche en el 14",
		"texto": "Alguien desde dentro del 14 nos ha mandado un documento. Según él, Velaria compró el edificio y lo llenó de gente sin casa, con deudas o enferma, traída de noche en camiones, para probar unas pastillas para dormir. Velaria lo niega: «Era un programa social de vivienda»."},
	{"id": "n_correo",
		"titular": "Un correo dice: no hay virus",
		"texto": "Nuestra fuente del 14 nos manda un correo interno de Velaria: «No hay ningún virus, lo sabemos». La empresa dice que es falso. Y añade que, si alguien está enfermo, será por «unas pastillas para dormir en mal estado, de otra marca». Sigue sin decir qué marca."},
	{"id": "n_portera",
		"titular": "¿Dónde está la portera?",
		"texto": "La fuente habla ahora de cuatro «noctámbulos»: residentes que tomaron más dosis y que todavía hablan. Una sería la portera del 14, a la que nadie ha visto desde el cierre. Velaria dice que era «una señora con problemas que nunca trabajó para nosotros». De noche se oyen gritos arriba."},
	{"id": "n_buscado",
		"titular": "Velaria busca a un conserje",
		"texto": "Última hora: anoche, un helicóptero de Velaria se posó en la azotea del 14. Al despegar, alguien colgaba de su escalera... y se soltó sobre los árboles de la avenida. Hoy Velaria busca a un empleado de mantenimiento «que se ha llevado documentos de la empresa». ¿Es nuestra fuente?"},
	# El centro comercial: «Turno infinito»
	{"id": "n_reformas", "sitio": "centro",
		"titular": "El centro cierra «por reformas»",
		"texto": "Buenas noches. El centro comercial de la avenida cierra de noche «por reformas». Pero las luces siguen encendidas hasta el amanecer, la alarma de incendios suena de madrugada y dentro se ve gente moviéndose. Velaria, que tiene allí una farmacia, dice: «Nosotros solo alquilamos un local»."},
	{"id": "n_velaria_noche", "sitio": "centro",
		"titular": "Velaria vende su somnífero",
		"texto": "Ya está a la venta «Velaria Noche», contra el insomnio. Sin receta y a $3,99. Las cajas se agotan en horas. Nuestra fuente dice que es lo mismo que se probó en el 14, rebajado. Velaria lo niega: «Es una fórmula nueva, natural y segura. La tomamos nosotros todas las noches»."},
	{"id": "n_turnos", "sitio": "centro",
		"titular": "Empleados que no vuelven a casa",
		"texto": "Decenas de familias denuncian que sus parientes, empleados del centro comercial, no vuelven a casa. El centro dice que hacen horas extra, «voluntarias y bien pagadas». Y les cuento algo mío: mi hermana Elena trabaja allí para Velaria. Desde el lunes no me coge el teléfono."},
	{"id": "n_audio", "sitio": "centro",
		"titular": "Se filtra un audio del gerente",
		"texto": "Nos llega un audio del gerente del centro comercial, al teléfono: «Sí, el conserje está aquí. No se irá. Mis empleados no duermen, y él tendrá que dormir alguna vez». Velaria dice que no conoce a ese señor y que, si ha tomado algo suyo, «no habrá leído el prospecto»."},
	{"id": "n_helicoptero", "sitio": "centro",
		"titular": "Un helicóptero en la azotea",
		"texto": "Última hora: el helicóptero de Velaria ha vuelto, esta vez a la azotea del centro comercial. Ha despegado con alguien dentro, rumbo a Torre Velaria. Velaria ya no busca a su conserje: «Está con nosotros, a salvo». Mañana presenta en su torre «el futuro del trabajo». De mi hermana, nada."},
	# Torre Velaria: la presentación que no llega a hacerse
	{"id": "n_presentacion", "sitio": "torre",
		"titular": "Esta noche, el futuro del trabajo",
		"texto": "Buenas noches. Les hablo desde la puerta de Torre Velaria. Esta noche, Velaria presenta aquí «el futuro del trabajo», en directo para todo el país. Hay focos, alfombra roja y colas de invitados. La presidenta, Clara Velar, promete «una sorpresa que cambiará los lunes para siempre». Del conserje, ni una palabra."},
	{"id": "n_simulacro", "sitio": "torre",
		"titular": "La torre cierra «por un simulacro»",
		"texto": "La presentación se ha cancelado a última hora. Torre Velaria ha cerrado sus puertas «por un simulacro de incendio», y desde entonces no ha salido nadie. Nuestra fuente nos manda la foto de un libro de visitas de hace once años. Hay un nombre: «J. Rush, voluntario. Planta 40»."},
	{"id": "n_dormidos", "sitio": "torre",
		"titular": "Dormidos en la puerta giratoria",
		"texto": "Esta madrugada, varios empleados de la torre han salido por la puerta giratoria... con los ojos cerrados. Dan vueltas y vueltas y vuelven a entrar. Velaria dice que es su nuevo programa de bienestar: «Descansar sin dejar de trabajar». Nuestra fuente dice que el VD-7 va en el aire acondicionado."},
	{"id": "n_audio_presidenta", "sitio": "torre",
		"titular": "Se filtra un audio de la presidenta",
		"texto": "Nos llega un audio de la presidenta de Velaria: «¿Que el Sujeto 1 no obedece? Los empleados tampoco, y los tenemos. Presentadlo igual. Y traedme al conserje: lo necesito entero». Velaria dice que el audio es falso, hecho con un ordenador. No dice quién es el Sujeto 1."},
	{"id": "n_torre_a_oscuras", "sitio": "torre",
		"titular": "La torre, a oscuras",
		"texto": "Última hora: Torre Velaria se ha quedado a oscuras, planta a planta, de abajo arriba. Hace unos minutos ha despegado un helicóptero desde el helipuerto, rumbo al norte. Velaria no contesta al teléfono. Y a mí me acaba de llegar un mensaje sin firma: «Soy el conserje. Tengo algo para ti»."},
]
# [/traducir]


# ── Los relatos ──
# Cada línea, una línea en pantalla. La clave es "intro" (al empezar la primera partida) o el id del edificio (al
# completarlo por primera vez). Los tres acaban en el mismo estribillo a propósito: al traducirlos, que suene igual en
# los tres. No cambiar una clave ya publicada: el guardado apunta los salidos por ella
# [traducir]
const RELATOS := {
	"intro": [
		"Número 14. Turno de noche.",
		"Johnny es el conserje. Lleva aquí más años de los que recuerda.",
		"Los vecinos nuevos llegaron en camiones, de noche. No daban ningún problema.",
		"Anoche precintaron el edificio desde fuera. Los vecinos siguen durmiendo. Andan. Y muerden.",
		"Nada de esto viene en su contrato.",
		"Pero alguien tendrá que limpiarlo.",
	],
	"apartamentos": [
		"Johnny se agarra a la escalera. El helicóptero despega.",
		"«No te fíes de los que vengan a rescatarte», decía la hoja.",
		"Johnny se suelta.",
		"Los árboles de la avenida amortiguan la caída. Más o menos.",
		"Al otro lado, el centro comercial sigue con las luces encendidas.",
		"Alguien tendrá que limpiarlo.",
	],
	"centro": [
		"Esta vez Johnny no se suelta.",
		"Sube, se sienta y se pone la fregona entre las rodillas. El piloto le ofrece un café. Dice que no.",
		"Abajo, los cajeros siguen cobrando a nadie.",
		"Delante se acerca Torre Velaria. «Planta 40», dice la radio. «Ya conoce el camino.»",
		"Johnny no recuerda haber estado allí.",
		"Cuarenta plantas de moqueta. Alguien tendrá que limpiarlas.",
	],
	# Con gancho (lo eligió el dueño el 5 nov): la presidenta escapa; Johnny ya sabe quién es y se lo cuenta a Marta
	"torre": [
		"El helipuerto está vacío. El helicóptero de Velaria ya es una luz pequeña, rumbo al norte.",
		"En la mano, su ficha. Johnny Rush. Voluntario.",
		"Ahora se acuerda: la luz blanca, el olor del laboratorio, la firma con una X.",
		"Abajo, la ciudad duerme. En cada farmacia, una caja de «Velaria Noche».",
		"Johnny le manda una foto de la hoja a Marta Ruiz.",
		"Alguien tendrá que limpiarlo todo.",
	],
}
# [/traducir]


# Las líneas de un relato, en el idioma del jugador
static func lineas_de(id: String) -> Array:
	return RELATOS[id].map(func(l): return Idioma.t(l))


# Apunta un relato como salido
static func apuntar_relato(id: String) -> void:
	Guardado.cambiar(func(g):
		if not id in g.relatos:
			g.relatos.append(id))


# El edificio al que pertenece una noticia ("sitio": "centro", "torre"; sin él, la calle del número 14: los apartamentos)
static func edificio_de(n: Dictionary) -> String:
	return {"": "apartamentos", "14": "apartamentos"}.get(n.get("sitio", ""), n.get("sitio", ""))


# Las noticias de un edificio, en su orden (el de las plantas: la baja enseña la primera, la siguiente la segunda...)
static func noticias_de(edificio: String) -> Array:
	return NOTICIAS.filter(func(n): return edificio_de(n) == edificio)


# La primera noticia de ese edificio que aún no se ha visto en la tele de un salón (para esta ranura de guardado), o {} si no
# hay o si todavía no se ha encontrado la página del dosier de la que sale: la noticia número N se hace con la página N, la
# documentación que Johnny le pasa a la periodista
static func siguiente_noticia(edificio: String, s: Dictionary) -> Dictionary:
	var noticias := noticias_de(edificio)
	var paginas: Array = dosier(edificio).paginas
	for i in noticias.size():
		if not noticias[i].id in s.videos_vistos:
			return noticias[i] if i < paginas.size() and encontrada(s, paginas[i].id) else {}
	return {}


# Las noticias ya vistas en una tele, para VIDEOS.EXE del ordenador (en el orden de siempre)
static func videos_vistos(s: Dictionary) -> Array:
	return NOTICIAS.filter(func(n): return n.id in s.videos_vistos)


# Apunta una noticia como vista (al acabar de verla en la tele de un salón): ya sale en VIDEOS.EXE
static func ver_noticia(id: String) -> void:
	Guardado.cambiar(func(g):
		if not id in g.videos_vistos:
			g.videos_vistos.append(id))


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


# La página que lleva el científico muerto de una planta: la primera del dosier del edificio que aún no se ha encontrado
# ({} si ya están todas). Si no la coges, la lleva el de la planta siguiente; con cuatro plantas y cinco páginas hacen falta
# dos partidas. (Ya no suelta ninguna el jefe.)
static func pendiente(s: Dictionary, edificio: String) -> Dictionary:
	for p in dosier(edificio).paginas:
		if not encontrada(s, p.id):
			return p
	return {}


# El título de una página y quién la llevaba, en el idioma del jugador
static func titulo_de(p: Dictionary) -> String:
	return Idioma.t(p.titulo)


static func cuerpo_de(p: Dictionary) -> String:
	return Idioma.t(p.cuerpo)


# Dónde se encuentra una página, en el idioma del jugador (la hoja lo dice en «HALLADO EN»): siempre junto a un cuerpo
static func donde(_p: Dictionary, _edificio := "") -> String:
	return Idioma.t("junto a un cuerpo de Velaria")


# Lo que dice el ordenador en el sitio de una página aún sin encontrar, en el idioma del jugador
static func falta(edificio: String, _p: Dictionary) -> String:
	return Idioma.t(dosier(edificio).falta)


# Apunta una página como encontrada
static func apuntar(id: String) -> void:
	Guardado.cambiar(func(g):
		if not id in g.paginas:
			g.paginas.append(id))


# ── La hoja ──
# Una página del dosier dibujada como un expediente de Velaria Corp. (ui/hoja_dosier.gd): el papel viejo, el logo, la
# foto del sitio con el muerto, el texto, el sello y la nota en un pósit. La usan el aviso de la partida (menus.gd) y
# el Dosier del ordenador (ui/carpeta_dosier.gd). Los colores del papel también los usa la hojita del suelo (cientifico.gd)

const PAPEL := Color("#e9dfc4")
const PAPEL_BORDE := Color("#b8a983")
const TINTA := Color("#2a2520")
const ROJO := Color("#a3312b")
const BOLI := Color("#1f3c8a")
const HOJA := preload("res://scripts/ui/hoja_dosier.gd")


# De qué edificio es una página y qué número tiene: [edificio, número (desde 1), páginas del edificio]
static func sitio_de(p: Dictionary) -> Array:
	for e in DOSIERES:
		var paginas: Array = DOSIERES[e].paginas
		for i in paginas.size():
			if paginas[i].id == p.get("id", ""):
				return [e, i + 1, paginas.size()]
	return ["", 1, 1]


# La hoja de una página encontrada, en el idioma del jugador. Mide "ancho" y de alto lo que necesite; si pasa de
# "alto_max", con la letra algo más pequeña (sin cortar nunca el texto)
static func hoja(p: Dictionary, ancho := 720.0, alto_max := 440.0) -> Control:
	var sitio := sitio_de(p)
	var h: Control = HOJA.new()
	h.montar(p, sitio[0], sitio[1], sitio[2], false, ancho, alto_max)
	return h


# La hoja de una página aún sin encontrar (el ordenador): arrancada, con lo que dice falta() en vez del texto
static func hoja_arrancada(edificio: String, p: Dictionary, ancho := 720.0, alto_max := 440.0) -> Control:
	var sitio := sitio_de(p)
	var h: Control = HOJA.new()
	h.montar(p, edificio, sitio[1], sitio[2], true, ancho, alto_max)
	return h
