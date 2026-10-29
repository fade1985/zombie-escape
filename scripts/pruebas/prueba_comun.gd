# Lo común de la partida de prueba: el guardado de prueba, la alerta, el evento y el jefe que se piden.
# Es el primer eslabón de la cadena de archivos de la partida de prueba (ver partida_prueba.gd).
extends "res://scripts/partida.gd"


func _ready() -> void:
	captura = true
	super()


func preparar_prueba() -> void:
	Guardado.archivo = "user://guardado-prueba.json"   # la prueba no toca el guardado de verdad
	SalaArmas.escondido = false   # la sala de pruebas, con sus líneas y su panel de daño a la vista (en el juego empieza sin ellos)
	# sin el repaso de los logros que salen del guardado (logros.gd, revisar): sus avisos saldrían en las fotos de
	# cualquier prueba; la de --logros lo hace a mano
	logros.repasar = false
	# con "--alerta 5", la prueba se juega con esa alerta (alerta.gd); sin él, sin alerta
	Alerta.nivel = int(Captura.dato("--alerta", "0"))
	# con "--evento apagon" (incendio, horda), la prueba de ese evento sorpresa (eventos.gd)
	eventos.forzado = Captura.dato("--evento")
	# con "--continuar", la partida a medias sí se guarda (partida_guardada.gd; prueba_varias.gd, probar_continuar)
	guarda_partida = "--continuar" in OS.get_cmdline_user_args()
		# con "--lentos", avisa de cada fotograma lento (pruebas/lentos.gd), con cualquier prueba
	if "--lentos" in OS.get_cmdline_user_args():
		var lentos := preload("res://scripts/pruebas/lentos.gd").new()
		lentos.partida = self
		add_child(lentos)
	# con "--guiado", la guía de la primera partida (guia.gd; prueba_varias.gd, probar_guiado): como si fuera la primera
	if "--guiado" in OS.get_cmdline_user_args():
		guiado_prueba = true
		tutoriales_prueba = true   # (con las ventanas encendidas: así se ve que no sale ninguna)
		Tutoriales.olvidar()
		Guardado.cambiar(func(g):
			g.partidas = 4   # (no es la primera: sale por «Que vuelvan a salir todos», guia_otra_vez)
			g.guia_otra_vez = true
			g.ajustes.tutoriales = true)


# En la prueba, el jefe que se ve es el de la 1ª planta (la segunda): que sea el antidisturbios, u otro con
# "--jefe cocinero", "--jefe modista" o "--jefe mascota"
func ordenar_jefes_prueba() -> void:
	var probar := Captura.dato("--jefe", "antidisturbios")
	if probar not in orden_jefes and "portera" in orden_jefes:
		# los Apartamentos sin --jefe: la portera en la planta baja, como siempre
		orden_jefes.erase("portera")
		orden_jefes.insert(0, "portera")
	if probar in orden_jefes:
		orden_jefes.erase(probar)
		orden_jefes.insert(1, probar)
	if "--joyeria" in OS.get_cmdline_user_args():
		Planta.joyeria_planta = 1   # la joyería en la planta baja, para ir derecho a su cámara acorazada
