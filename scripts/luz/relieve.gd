# El relieve con la luz: a una hoja de animaciones (SpriteFrames) le pone su mapa de normales, si lo tiene. El mapa
# es otra imagen al lado de la hoja, con el mismo nombre y "_n" al final (conserje-48-guardia_n.png), sacada con
# Sprite Fusion (create_normal_map). No se ve: le dice a Godot hacia dónde mira cada píxel, y así las luces
# (lámparas, linterna, fogonazos) alumbran el lado que les toca y dejan el otro en sombra.
# De momento es una PRUEBA (--relieve, prueba_varias.gd): solo Johnny con la fregona y el zombi normal tienen mapa.
class_name Relieve

static var hechas := {}   # la ruta de la hoja → la misma hoja, con relieve (se hace una vez)


# La hoja con relieve; si no tiene mapa de normales, la misma de siempre
static func poner(hoja: SpriteFrames) -> SpriteFrames:
	if hoja == null or hoja.get_animation_names().is_empty():
		return hoja
	if hechas.has(hoja.resource_path):
		return hechas[hoja.resource_path]
	var primera := hoja.get_frame_texture(hoja.get_animation_names()[0], 0)
	if not primera is AtlasTexture:
		return hoja
	var dibujo: Texture2D = primera.atlas
	var ruta := dibujo.resource_path.get_basename() + "_n.png"
	if not ResourceLoader.exists(ruta):
		return hoja
	# El dibujo y su mapa juntos, en una sola textura; cada fotograma recorta su trozo, como antes
	var lienzo := CanvasTexture.new()
	lienzo.diffuse_texture = dibujo
	lienzo.normal_texture = load(ruta)
	var nueva := SpriteFrames.new()
	nueva.remove_animation("default")
	for anim in hoja.get_animation_names():
		nueva.add_animation(anim)
		nueva.set_animation_speed(anim, hoja.get_animation_speed(anim))
		nueva.set_animation_loop(anim, hoja.get_animation_loop(anim))
		for i in hoja.get_frame_count(anim):
			var vieja: AtlasTexture = hoja.get_frame_texture(anim, i)
			var t := AtlasTexture.new()
			t.atlas = lienzo
			t.region = vieja.region
			t.margin = vieja.margin
			t.filter_clip = vieja.filter_clip
			nueva.add_frame(anim, t, hoja.get_frame_duration(anim, i))
	for m in hoja.get_meta_list():   # (las "puntas" del arma y lo demás que lleve la hoja)
		nueva.set_meta(m, hoja.get_meta(m))
	hechas[hoja.resource_path] = nueva
	return nueva
