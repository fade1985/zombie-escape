# El cuerpo de un enemigo que acaba de morir. Tumbado mide mucho más que su choque (el zombi normal, unas 100 unidades de
# ancho contra 32), así que si moría pegado a una pared se metía en ella: se pintaba encima de lo alto del muro o, en la
# pared de arriba, se le iba detrás de la cara del muro (F12). Ahora, mientras cae, resbala lo justo para acabar sobre el
# suelo, y no baja a la capa del suelo (z -1) hasta tocarlo. Sin pared cerca, no se hace nada: cae donde estaba.
# Lo que ocupa cada dibujo sale de sus píxeles de verdad, pero leer una hoja es lento (get_image, docs/WEB.md): solo se lee
# si hay una pared cerca, una vez, y de paso se miden todas sus caídas. La imagen no se guarda, que ocupa mucho.
class_name Cuerpo
extends RefCounted

static var cajas := {}   # lo que ocupa cada dibujo sin el aire de alrededor, en píxeles del dibujo


# Lo llama el enemigo al morir, con su animación de caer ya puesta
static func caer(cuerpo: Node2D, s: AnimatedSprite2D) -> void:
	var mapa := cuerpo.get_tree().get_first_node_in_group("mapa")
	var hoja := s.sprite_frames
	var ultimo := hoja.get_frame_count(s.animation) - 1
	if mapa == null or ultimo == 0 or not s.animation.begins_with("muerte_"):   # (sin animación de caer, se gira de lado)
		return
	var de_pie := hoja.get_frame_texture(s.animation, 0)
	var tendido := hoja.get_frame_texture(s.animation, ultimo)
	var pies := cuerpo.global_position + s.position
	# lo que no cuesta nada: si ni el dibujo entero, con su aire, toca una pared, no hay más que mirar
	if not mapa.pisa_muro(Rect2(pies + s.offset * s.scale, de_pie.get_size() * s.scale)):
		return
	if not cajas.has(tendido):
		medir(hoja)
	var caja_pie: Rect2 = cajas[de_pie]
	var caja: Rect2 = cajas[tendido]
	resbalar(cuerpo, Rect2(pies + (s.offset + caja.position) * s.scale, caja.size * s.scale),
		(ultimo + 1) / hoja.get_animation_speed(s.animation),
		mapa.pisa_muro(Rect2(pies + (s.offset + caja_pie.position) * s.scale, caja_pie.size * s.scale)))


# Mide lo que ocupa cada enemigo de pie y tendido, en todas sus direcciones
static func medir(hoja: SpriteFrames) -> void:
	var leidas := {}
	for anim in hoja.get_animation_names():
		if not anim.begins_with("muerte_"):
			continue
		for i in [0, hoja.get_frame_count(anim) - 1]:
			var dibujo: AtlasTexture = hoja.get_frame_texture(anim, i)
			if not leidas.has(dibujo.atlas):
				# (si ya la tiene quemado.gd, no se vuelve a leer)
				leidas[dibujo.atlas] = Quemado.hojas[dibujo.atlas] if Quemado.hojas.has(dibujo.atlas) else dibujo.atlas.get_image()
			cajas[dibujo] = Rect2(leidas[dibujo.atlas].get_region(Rect2i(dibujo.region)).get_used_rect())


# Lleva el cuerpo, en lo que tarda en caer, hasta que "caja" (lo que ocupará tendido, en unidades del mapa) quede sobre el
# suelo. "tapado": al caer, una pared le taparía si bajase ya a la capa del suelo, aunque luego no haya que moverlo
static func resbalar(cuerpo: Node2D, caja: Rect2, tiempo: float, tapado := false) -> void:
	var desde := cuerpo.global_position
	var mover: Vector2 = cuerpo.get_tree().get_first_node_in_group("mapa").fuera_de_muros(caja, desde)
	if mover == Vector2.ZERO and not tapado:
		return
	cuerpo.z_index = 0
	var tween := cuerpo.create_tween()
	tween.tween_property(cuerpo, "global_position", desde + mover, tiempo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): cuerpo.z_index = -1)
