// Como recorte.gdshader, para las capas de brillo que se suman (el fuego de la explosión y de los efectos de pixelfx)
shader_type canvas_item;
render_mode blend_add;

#include "res://escenas/armas/recorte.gdshaderinc"

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	pie = MODEL_MATRIX[3].xy;
}

void fragment() {
	COLOR.a *= visible();
}
