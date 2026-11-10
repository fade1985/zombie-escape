// Los efectos no se pintan encima de las paredes ni al otro lado (recorte.gd, recorte.gdshaderinc)
shader_type canvas_item;

#include "res://escenas/armas/recorte.gdshaderinc"

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	pie = MODEL_MATRIX[3].xy;
}

void fragment() {
	COLOR.a *= visible();
}
