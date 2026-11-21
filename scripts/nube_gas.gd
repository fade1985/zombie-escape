# La nube de gas lacrimógeno del antidisturbios (antidisturbios.gd: sale de sus botes, proyectil.gd "gas"). Hasta el 21
# nov era un charco (charco.gd) y parecía líquido. Lo que se ve es un efecto de pixelfx (efecto_suelo.gd, "gas";
# tools/pixelfx/gas-lacrimogeno.js): el bote revienta y salen bolas de humo blanco amarillento que llenan la elipse que
# pica, se hinchan y al final se deshacen. Crece al caer, dura VIDA s (lo mismo que el efecto) y se va deshaciendo.
# A quien esté dentro (Johnny y los zombis, menos a quien la tiró: "dueno") le pone el estado "toxico", como la
# lejía (estados.gd). Las paredes la cortan como a los charcos (ArmasCreadas.tapado).
class_name NubeGas
extends Node2D

const RADIO := 72.0        # el de su huella en el suelo (una elipse, como los charcos)
const VIDA := 7.0
const CRECE := 0.5         # lo que tarda en hincharse al caer
const SE_VA := 1.2         # lo que tarda en deshacerse al final
const ESTADOS := {"toxico": {"dps": 7.0}}

var dueno: Node2D = null
var t := 0.0


func _ready() -> void:
	add_to_group("nubes_gas")
	EfectoSuelo.soltar(get_parent(), "gas", global_position)
	Sonido.tocar("siseo")


func _physics_process(delta: float) -> void:
	t += delta
	if t >= VIDA:
		queue_free()
		return
	# a quien esté dentro, el picor (cada paso: los estados ya cuentan su tiempo)
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny and johnny.vivo and dentro(johnny.global_position) \
			and not ArmasCreadas.tapado(self, global_position, johnny.global_position):
		johnny.pisar(ESTADOS)
	for zombi in get_tree().get_nodes_in_group("zombis"):
		if zombi != dueno and zombi.has_method("pisar") and dentro(zombi.global_position) \
				and not ArmasCreadas.tapado(self, global_position, zombi.global_position):
			zombi.pisar(ESTADOS)


# Lo grande que está (0 a 1): crece al caer y se deshace al final
func tamano() -> float:
	return minf(1.0, t / CRECE) * clampf((VIDA - t) / SE_VA, 0.0, 1.0)


func dentro(p: Vector2) -> bool:
	var d := p - global_position
	var r := RADIO * maxf(tamano(), 0.3)
	return (d.x / r) ** 2 + (d.y / (r * 0.6)) ** 2 <= 1.0
