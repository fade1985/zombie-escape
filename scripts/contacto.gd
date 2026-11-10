# «Contáctanos» (Opciones → General → Contáctanos, desde el 10 nov 2026, en lugar del botón del registro de errores): el
# jugador escribe con sus palabras qué falla, qué no le gusta o qué mejoraría, y se nos manda. Va al programita de Vercel
# api/contacto.js (con la web), que abre un aviso en el repositorio privado fade1985/zombie-escape-mensajes; ahí lo leemos
# los dos y Claude lo analiza (docs/MENSAJES.md). La página, en opciones.gd (contacto()).
#
# No pedimos nada del jugador (ni correo ni nombre). Si deja marcada la casilla, van también los datos técnicos: la versión,
# el sistema y las últimas líneas del registro (registro.gd), sin las rutas de su carpeta (que llevan su nombre de usuario).
# Se prueba con -- --captura --contacto (prueba_varias.gd); las pruebas no mandan nada de verdad.
class_name Contacto

const URL := "https://zombie-escape-two.vercel.app/api/contacto"   # no-tr
const MAX_LETRAS := 1000      # lo que se deja escribir (api/contacto.js tampoco acepta más)
const LINEAS_REGISTRO := 150  # las últimas líneas del registro que van con el mensaje
const ESPERA := 15.0          # segundos, antes de dar el envío por perdido


# Lo que se manda: el mensaje y, con permiso, los datos técnicos
static func datos(mensaje: String, con_datos: bool) -> Dictionary:
	var d := {"mensaje": mensaje.strip_edges().left(MAX_LETRAS)}   # no-tr
	if con_datos:
		d.version = Registro.version()
		d.sistema = "%s %s" % [OS.get_name(), OS.get_version()]   # no-tr
		d.idioma = Idioma.actual
		d.plataforma = "web" if OS.has_feature("web") else OS.get_name()   # no-tr
		d.registro = limpiar(Registro.texto(LINEAS_REGISTRO))
	return d


# Sin el nombre del jugador: las rutas de su carpeta de usuario (C:\Users\Nombre, /home/nombre, /Users/nombre) se quedan
# en «~» (el nombre puede llevar espacios: se quita hasta la barra siguiente)
static func limpiar(texto: String) -> String:
	for carpeta in [OS.get_user_data_dir(), OS.get_environment("USERPROFILE"), OS.get_environment("HOME")]:
		if carpeta.length() > 3:
			texto = texto.replace(carpeta, "~").replace(carpeta.replace("\\", "/"), "~")
	var rutas := RegEx.create_from_string("(?i)([a-z]:[\\\\/]+(users|documents and settings)[\\\\/]+|/home/|/users/)[^\\\\/\"'\\r\\n]+")   # no-tr
	return rutas.sub(texto, "~", true)


# Manda el mensaje y avisa con hecho(si_ha_llegado). En las pruebas (--captura) no sale nada
# del ordenador, salvo que se le diga adónde con --contacto-url (para probar el envío de verdad contra un servidor de prueba)
static func enviar(dueno: Node, mensaje: String, con_datos: bool, hecho: Callable) -> void:
	var cuerpo := JSON.stringify(datos(mensaje, con_datos))
	var url := URL
	if Captura.activa():
		url = Captura.dato("--contacto-url")
		if url == "":
			print("Contacto · se mandaría a %s: %s" % [URL, cuerpo.left(300)])   # no-tr
			dueno.get_tree().create_timer(0.5, true).timeout.connect(func(): hecho.call(true))
			return
	var peticion := HTTPRequest.new()
	peticion.timeout = ESPERA
	peticion.process_mode = Node.PROCESS_MODE_ALWAYS   # (se manda también desde la pausa)
	dueno.get_tree().root.add_child(peticion)   # (en la raíz: si se cierra Opciones mientras se manda, llega igual)
	peticion.request_completed.connect(func(resultado: int, codigo: int, _cabeceras, _respuesta):
		peticion.queue_free()
		if resultado != HTTPRequest.RESULT_SUCCESS or codigo < 200 or codigo >= 300:
			Registro.apuntar("Contacto: no se ha podido mandar (resultado %d, código %d)" % [resultado, codigo])   # no-tr
		hecho.call(resultado == HTTPRequest.RESULT_SUCCESS and codigo >= 200 and codigo < 300))
	var error := peticion.request(url, ["Content-Type: application/json", "X-Juego: johnny-rush"], HTTPClient.METHOD_POST, cuerpo)   # no-tr
	if error != OK:
		peticion.queue_free()
		hecho.call(false)
