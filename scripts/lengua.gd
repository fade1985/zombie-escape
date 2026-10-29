# Las lenguas que pegan, pintadas con código: las del latigazo del Glotón y las de la criatura del científico mutado.
# Hacen lo mismo que los tentáculos (tentaculo.gd): apuntan y se paran en las paredes y los muebles, avisan con lo
# mismo que las cargas de los jefes (Aviso.franja) y se pintan como las de su dibujo, por capas, pero sin ventosas.
# Lo que cambia es la forma: durante el aviso no se pintan (las enrosca su dibujo por encima de la cabeza) y con el
# golpe salen disparadas de la boca, caen al suelo sobre el aviso culebreando y se recogen por el mismo camino.
class_name Lengua
extends Tentaculo

const SALE := 0.08         # lo que tardan en llegar al final
const RECOGE := 0.2        # lo que tardan en recogerse (lo último antes de acabar)

var culebrea := 7.0        # lo que culebrea a cada lado


func _init(paleta: Dictionary) -> void:
	super(paleta)


# Disparada de la boca ("raiz") hasta donde llega (si da con una pared, hasta ella): sale hacia delante, baja hasta
# el suelo y se tiende sobre el aviso (que empieza en "suelo"), con una onda que la recorre. Va saliendo por ese
# camino y se recoge por él hacia la boca. "t", lo que lleva desde el golpe; "dura", cuándo acaba de recogerse
func lanzada(raiz: Vector2, suelo: Vector2, t: float, dura: float) -> PackedVector2Array:
	var hacia := Vector2.from_angle(angulo)
	var punta := suelo + Vector2(0, -4) + hacia * llega
	# donde toca el suelo: siempre más allá de la boca (si va hacia arriba, la boca queda muy alta y, si no, la
	# lengua bajaría y volvería a subir); y al salir de la boca va hacia delante hasta la mitad de ese camino
	var boca := (raiz - suelo).dot(hacia)
	var hasta_codo := minf(maxf(llega * 0.45, boca + 50.0), llega * 0.8)
	var codo := suelo + Vector2(0, -4) + hacia * hasta_codo
	var sale := raiz + hacia * maxf(0.0, hasta_codo - boca) * 0.5
	var lado := (punta - raiz).orthogonal().normalized()
	var fuera := ease(minf(1.0, t / SALE), 0.5) * (1.0 - smoothstep(dura - RECOGE, dura, t))   # lo que tiene fuera
	var puntos := PackedVector2Array()
	for i in PUNTOS + 1:
		var s := fuera * i / PUNTOS
		var u := 1.0 - s
		var p := raiz * u * u * u + sale * 3.0 * u * u * s + codo * 3.0 * u * s * s + punta * s * s * s
		puntos.append(p + lado * sin(s * 9.0 - (t + desfase) * 35.0) * culebrea * sin(s * PI))
	return puntos
