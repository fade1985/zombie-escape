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


# Lo que le da cuerpo al golpe (19 nov: se veía plano). Por debajo del que la lanza: su sombra en el suelo, cada punto
# llevado a la línea del aviso (donde acaba cayendo), oscura y translúcida; así se ve que va por el aire hasta que cae
func sombra(lienzo: CanvasItem, puntos: PackedVector2Array, suelo: Vector2) -> void:
	var hacia := Vector2.from_angle(angulo)
	var lado := hacia.orthogonal()
	var en_suelo := PackedVector2Array()
	for p in puntos:
		var d := p - suelo
		en_suelo.append(suelo + hacia * maxf(0.0, d.dot(hacia)) + lado * d.dot(lado) * 0.5)
	silueta(lienzo, en_suelo, Color(0.05, 0.02, 0.02, 0.3), 1.0)


# Por encima, antes de pintarla: la estela del latigazo mientras sale disparada, dos siluetas claras de por dónde
# acaba de pasar, cada vez más flojas
func estela(lienzo: CanvasItem, raiz: Vector2, suelo: Vector2, t: float, dura: float) -> void:
	if t > SALE + 0.06:
		return
	var apaga := 1.0 - t / (SALE + 0.06)
	for atras in [0.035, 0.018]:
		if t - atras <= 0.0:
			continue
		silueta(lienzo, lanzada(raiz, suelo, t - atras, dura), Color(1.0, 0.86, 0.8, (0.18 if atras > 0.02 else 0.32) * apaga), 1.5)


# El chasquido donde la punta da en el suelo (efecto_suelo.gd, "latigazo"); "cuerpo", el que la lanza
func chasquido(cuerpo: Node2D, suelo: Vector2) -> void:
	EfectoSuelo.soltar(cuerpo.get_parent(), "latigazo", cuerpo.global_position + suelo + Vector2.from_angle(angulo) * llega)
