# Saca una foto (tools/dibujos.png, no se sube a git) con los dibujos hechos con código, para revisarlos sin
# jugar: los tres supervivientes mirando a varios lados, andando y con el arma, y el zombi de tentáculos
# (quieto y andando, en varios momentos).
#   "C:\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path . tools/ver_dibujos.tscn
extends Node

const SUPERVIVIENTES := preload("res://scripts/supervivientes.gd")


func _ready() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color("#6d6a64")
	fondo.size = Vector2(960, 640)
	add_child(fondo)
	var lienzo := Node2D.new()
	lienzo.scale = Vector2(2, 2)   # el doble, para verlos bien
	add_child(lienzo)
	var miradas := [Vector2.DOWN, Vector2(1, 0.4).normalized(), Vector2.UP, Vector2(-1, 0.2).normalized()]
	var fila := 0
	for id in SUPERVIVIENTES.DATOS:
		var def: Dictionary = SUPERVIVIENTES.DATOS[id]
		for i in miradas.size() + 1:
			var p := Persona.new()
			p.look = def.look
			p.arma = def.arma
			p.position = Vector2(40 + i * 80, 50 + fila * 100)
			if i < miradas.size():
				p.mira = miradas[i]
				p.apunte = miradas[i].angle()
			else:
				# andando hacia la derecha, en mitad del paso
				p.mira = Vector2.RIGHT
				p.apunte = 0.0
				p.mueve = Vector2.RIGHT
				p.andando = 1.0
				p.paso = 1.2
				p.fogonazo = true
				p.retroceso = 0.7
			lienzo.add_child(p)
		fila += 1
	for i in 4:
		var z: Node2D = preload("res://escenas/personajes/zombi_tentaculos.tscn").instantiate()
		z.position = Vector2(520 + i * 110, 600)
		add_child(z)
		z.set_physics_process(false)
		z.tiempo = i * 0.7
		z.velocity = Vector2(30, 0) if i >= 2 else Vector2.ZERO
		z.andar_t = i * 0.8
		z.mover_dibujo(0.0)
		z.queue_redraw()
	for i in 5:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://tools/dibujos.png")
	get_tree().quit()
