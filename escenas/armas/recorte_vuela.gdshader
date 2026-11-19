// Como recorte.gdshader, para lo que vuela con su altura (los cachos de carne del zombi explosivo, cachos.gd; 20 nov,
// el dueño no quería que pasaran las paredes). Cada cosa se dibuja con su altura sobre el suelo en el rojo del color
// (en unidades / ALTURA), y cada píxel mira el suelo que tiene debajo (el píxel, bajado esa altura):
//   - si ese suelo cae en un muro, no se pinta (el que se arrima a una pared por un lado)
//   - si delante (más abajo) hay un muro con su cara (cara_pared.gd: sube CARA desde el pie del muro) y el píxel cae en
//     ella, la cara lo tapa (lo que vuela en las dos últimas filas de la habitación de detrás de un tabique)
//   - si detrás (más arriba) hay un muro, no se pinta por encima de lo alto de su cara (ahí ya es la habitación de al lado)
shader_type canvas_item;

#include "res://escenas/armas/recorte.gdshaderinc"

const float ALTURA = 256.0;   // la altura que vale 1 en el rojo (cachos.gd la pone así)
const float CARA = 96.0;      // lo que sube la cara de un muro desde su pie (cara_pared.gd, ALTO)

varying float alto;

// el y (en el mundo) del pie de la fila "f" de casillas (su borde de abajo)
float pie_de(float f, float casilla) {
	return origen.y + (f + 1.0) * casilla;
}

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	pie = MODEL_MATRIX[3].xy;
	alto = COLOR.r * ALTURA;
	COLOR = vec4(1.0);   // (el rojo solo lleva la altura: el dibujo va con sus colores)
}

float a_la_vista() {
	if (medida.x <= 0.0) {
		return 1.0;
	}
	vec2 suelo = mundo + vec2(0.0, alto);
	if (libre(suelo) < 0.5) {
		return 0.0;
	}
	float casilla = medida.x / float(textureSize(mascara, 0).x);
	float f = floor((suelo.y - origen.y) / casilla);
	// delante: el primer muro de debajo (hasta 3 casillas) y su pie (si es un tabique de varias, el de la última)
	for (int k = 1; k <= 3; k++) {
		vec2 q = vec2(suelo.x, origen.y + (f + float(k) + 0.5) * casilla);
		if (libre(q) < 0.5) {
			float ultima = f + float(k);
			for (int j = 1; j <= 3; j++) {
				if (libre(vec2(suelo.x, origen.y + (ultima + 1.5) * casilla)) > 0.5) {
					break;
				}
				ultima += 1.0;
			}
			float pie_muro = pie_de(ultima, casilla);
			bool con_cara = libre(vec2(suelo.x, pie_muro + casilla * 0.5)) > 0.5;
			if (con_cara && mundo.y >= pie_muro - CARA) {
				return 0.0;
			}
			break;
		}
	}
	// detrás: el primer muro de encima (hasta 4 casillas); lo alto de su cara, el techo
	for (int k = 1; k <= 4; k++) {
		vec2 q = vec2(suelo.x, origen.y + (f - float(k) + 0.5) * casilla);
		if (libre(q) < 0.5) {
			if (mundo.y < pie_de(f - float(k), casilla) - CARA) {
				return 0.0;
			}
			break;
		}
	}
	return 1.0;
}

void fragment() {
	COLOR = texture(TEXTURE, UV);
	COLOR.a *= a_la_vista();
}
