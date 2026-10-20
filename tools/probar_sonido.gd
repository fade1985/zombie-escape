# Prueba los efectos sin jugar: los sintetiza todos, dice cuánto duran y lo fuerte que suenan, y los guarda
# en tools/efectos/*.wav para escucharlos.  "..._console.exe" --headless --path . --script tools/probar_sonido.gd
extends SceneTree


func _init() -> void:
	var s: Node = load("res://scripts/sonido.gd").new()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tools/efectos"))
	FileAccess.open("res://tools/efectos/.gdignore", FileAccess.WRITE).close()   # que Godot no los importe
	for nombre in s.EFECTOS:
		var wav: AudioStreamWAV = s.sintetizar(s.EFECTOS[nombre].notas)
		var pico := 0
		for i in range(0, wav.data.size(), 2):
			pico = maxi(pico, absi(wav.data.decode_s16(i)))
		print("%-15s %.2f s  pico %3d %%" % [nombre, wav.get_length(), pico * 100 / 32767])
		wav.save_to_wav("res://tools/efectos/%s.wav" % nombre)
	s.free()
	quit()
