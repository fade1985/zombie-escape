// El fuego del suelo (charco.gd, el molotov y el aceite que arde): la tarjeta gráfica pinta cada cuadradito (un píxel
// del dibujo), con lo mismo que hacía antes el código. Las llamas y las ascuas de encima las sigue pintando el charco.
// La textura tiene un texel por cuadradito, calculado una vez al hacer el fuego:
//   r  lo lejos del centro (0-1)   g  un ruido suave (0-1)   b  cuándo prende (1e9: ahí no hay fuego)   a  cuándo se apaga
shader_type canvas_item;

#include "res://escenas/armas/recorte.gdshaderinc"

uniform highp float t = 0.0;   // el tiempo del fuego (lo que tiembla)
uniform highp float e = 0.0;   // lo que lleva ardiendo
uniform float brasa = 0.3;     // lo que dura la brasa de lo que se apaga, antes de quedar en ceniza (BRASA)
uniform float frente = 0.07;   // lo que dura el frente del fuego, recién prendido (FRENTE)
uniform vec4 fuego0 : source_color;   // los colores de Llamas.FUEGO, del más claro al más oscuro
uniform vec4 fuego1 : source_color;
uniform vec4 fuego2 : source_color;
uniform vec4 fuego3 : source_color;
uniform vec4 fuego4 : source_color;
uniform vec4 rojo_brasa : source_color = vec4(0.431, 0.114, 0.071, 1.0);
uniform vec4 ceniza1 : source_color = vec4(0.11, 0.071, 0.055, 0.7);
uniform vec4 ceniza2 : source_color = vec4(0.165, 0.102, 0.078, 0.6);

varying vec4 tinte;

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	pie = MODEL_MATRIX[3].xy;
	tinte = COLOR;
}

void fragment() {
	highp vec4 c = texelFetch(TEXTURE, ivec2(floor(UV * vec2(textureSize(TEXTURE, 0)))), 0);
	if (e < c.b) {
		discard;
	}
	vec4 color;
	if (e >= c.a) {
		// ya apagado: brasa un momento y luego ceniza
		color = e - c.a < brasa ? rojo_brasa : (c.g < 0.5 ? ceniza1 : ceniza2);
	} else if (e - c.b < frente) {
		color = fuego0;
	} else {
		highp float d = c.r + 0.12 * sin(t * 9.0 + c.g * 7.0);   // el color tiembla un poco, por trozos
		color = d < 0.3 ? fuego1 : d < 0.55 ? fuego2 : d < 0.8 ? fuego3 : fuego4;
		color.a = 0.9;
	}
	COLOR = color * tinte;
	COLOR.a *= visible();
}
