// Los líquidos del suelo (charco.gd, pintar_liquido): la tarjeta gráfica pinta cada cuadradito (un píxel del dibujo),
// con lo mismo que hacía antes el código. La textura tiene un texel por cuadradito, calculado una vez al hacer el charco:
//   r  su color de base (lo cerca del borde, más la luz de arriba a la izquierda); 10 si es del contorno; +20 si está
//      tan cerca del borde que no lleva vetas de brillo
//   g  su fase (un ruido suave: las bandas de color se mecen como olas)
//   b  cuándo aparece (1e9: ahí no hay líquido)
//   a  cuándo se seca
// Todo en precisión alta (highp): hay móviles que, si no, calculan con pocos decimales y el balanceo iría a saltos.
shader_type canvas_item;

#include "res://escenas/armas/recorte.gdshaderinc"

uniform highp float t = 0.0;       // el tiempo del charco (lo que se mece)
uniform highp float e = 0.0;       // lo que lleva hecho (los cuadraditos que aún no han llegado o ya se han secado, no)
uniform highp vec2 esquina = vec2(0.0);   // dónde está el primer cuadradito, en el nodo (para las vetas)
uniform vec4 borde : source_color;
uniform vec4 oscuro : source_color;
uniform vec4 medio : source_color;
uniform vec4 centro : source_color;
uniform vec4 brillo : source_color;

varying vec4 tinte;   // el modulate del nodo (el destello del agua con corriente)

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	pie = MODEL_MATRIX[3].xy;
	tinte = COLOR;
}

void fragment() {
	ivec2 s = ivec2(floor(UV * vec2(textureSize(TEXTURE, 0))));
	highp vec4 c = texelFetch(TEXTURE, s, 0);
	if (e < c.b || e >= c.a + 0.2) {
		discard;
	}
	vec4 color;
	if (e >= c.a) {
		color = vec4(borde.rgb, 0.6);   // recién secado: un momento más oscuro
	} else if (c.r > 5.0 && c.r < 15.0) {
		color = borde;   // el contorno
	} else {
		bool vetas = c.r < 5.0;
		highp float d = (vetas ? c.r : c.r - 20.0) + 0.05 * sin(t * 2.2 + c.g);
		color = d < 0.35 ? centro : d < 0.62 ? medio : d < 0.86 ? oscuro : borde;
		if (vetas) {
			// el brillo en vetas: líneas casi horizontales que ondulan y se desplazan
			highp vec2 p = esquina + vec2(s) * 2.0;
			highp float v = sin(p.y * 0.35 + sin(p.x * 0.06 + t * 0.7) * 2.2 + c.g * 0.25) * sin(p.x * 0.045 - t * 0.5 + c.g * 0.1);
			if (v > 0.86) {
				color = brillo;
			} else if (v > 0.74 && d >= 0.35) {
				color = centro;
			}
		}
	}
	COLOR = color * tinte;
	COLOR.a *= visible();
}
