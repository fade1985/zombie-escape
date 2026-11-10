# «Contáctanos» (Opciones → General → Contáctanos, desde el 10 nov 2026, en lugar del botón del registro de errores): el
# jugador escribe con sus palabras qué falla, qué no le gusta o qué mejoraría, y se nos manda. Va al programita de Vercel
# api/contacto.js (con la web), que abre un aviso en el repositorio privado fade1985/zombie-escape-mensajes; ahí lo leemos
# los dos y Claude lo analiza (docs/MENSAJES.md). La página, en opciones.gd (contacto()).
#
# Solo va el texto que escribe el jugador: nada suyo (ni correo ni nombre) y, desde el 10 nov, tampoco datos técnicos
# (versión, sistema ni registro: lo quiso así el dueño).
# Se prueba con -- --captura --contacto (prueba_varias.gd); las pruebas no mandan nada de verdad.
class_name Contacto

const URL := "https://zombie-escape-two.vercel.app/api/contacto"   # no-tr
const MAX_LETRAS := 1000      # lo que se deja escribir (api/contacto.js tampoco acepta más)
const ESPERA := 15.0          # segundos, antes de dar el envío por perdido


# Lo que se manda: solo el mensaje
static func datos(mensaje: String) -> Dictionary:
	return {"mensaje": mensaje.strip_edges().left(MAX_LETRAS)}   # no-tr


# Manda el mensaje y avisa con hecho(si_ha_llegado). En las pruebas (--captura) no sale nada
# del ordenador, salvo que se le diga adónde con --contacto-url (para probar el envío de verdad contra un servidor de prueba)
static func enviar(dueno: Node, mensaje: String, hecho: Callable) -> void:
	var cuerpo := JSON.stringify(datos(mensaje))
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
		if hecho.is_valid():
			hecho.call(resultado == HTTPRequest.RESULT_SUCCESS and codigo >= 200 and codigo < 300))
	var error := peticion.request(url, ["Content-Type: application/json", "X-Juego: johnny-rush"], HTTPClient.METHOD_POST, cuerpo)   # no-tr
	if error != OK:
		peticion.queue_free()
		hecho.call(false)
