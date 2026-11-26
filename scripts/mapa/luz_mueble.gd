# Lo que luce de un mueble (27 nov, el dueño: las torres de luces y las pantallas encendidas de los puestos de la sala de juegos de la
# electrónica, que den luz como los neones): su capa de luz (mueble-<tipo>-luz.png, de tools/muebles_electronica_gpt.py: solo lo que
# luce, con su resplandor), pintada encima del dibujo del mueble sin que le afecte la oscuridad. La pone mueble.gd. Tiembla un poco y,
# de vez en cuando, parpadea un momento, como una pantalla que falla
extends Sprite2D

var tiempo := 0.0
var fallo := 0.0
var proximo_fallo := 0.0


func _ready() -> void:
	var propio := CanvasItemMaterial.new()
	propio.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = propio
	var semilla := fposmod(global_position.x * 0.0173 + global_position.y * 0.0091, 1.0)
	tiempo = semilla * 30.0
	proximo_fallo = 2.0 + semilla * 10.0


func _process(delta: float) -> void:
	tiempo += delta
	proximo_fallo -= delta
	if proximo_fallo <= 0.0:
		fallo = randf_range(0.05, 0.18)
		proximo_fallo = randf_range(5.0, 16.0)
	fallo = maxf(fallo - delta, 0.0)
	modulate.a = 0.35 if fallo > 0.0 else 0.92 + 0.08 * sin(tiempo * 23.0) * sin(tiempo * 3.1)
