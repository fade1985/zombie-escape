// El recorte de los efectos en las paredes (recorte.gd): un píxel del efecto solo se pinta si desde su centro (el pie
// del nodo, en el suelo) hasta él no hay ninguna pared. La máscara tiene un texel por casilla del mapa (blanco: suelo o
// hueco de puerta; negro: muro). Modos:
//   0 suelo  lo que está tendido en el suelo (charcos, quemaduras): se mira hasta el mismo píxel
//   1 aire   lo que sube (explosiones, llamas, escarcha): lo de encima de su pie se mira a la altura del pie, así que
//            por un lado o por abajo se corta en la pared, pero por encima de la pared de arriba se sigue viendo
//            (como un personaje delante de ella)
//   2 punto  lo que no tiene un centro (las partículas, todas en un nodo): solo que el píxel no caiga en un muro
uniform sampler2D mascara : filter_nearest, repeat_disable, hint_default_white;
uniform vec2 origen = vec2(0.0);   // dónde empieza el mapa
uniform vec2 medida = vec2(0.0);   // lo que mide el mapa (0: no hay mapa y no se recorta nada)
uniform int modo = 0;

varying vec2 mundo;   // el píxel, en el mundo
varying vec2 pie;     // el centro del efecto (la posición de su nodo)

float libre(vec2 q) {
	vec2 uv = (q - origen) / medida;
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x >= 1.0 || uv.y >= 1.0) {
		return 0.0;   // fuera del mapa, como un muro
	}
	return step(0.5, textureLod(mascara, uv, 0.0).r);
}

float visible() {
	if (medida.x <= 0.0) {
		return 1.0;
	}
	if (modo == 2 || libre(pie) < 0.5) {
		return libre(mundo);   // (si el centro cae en un muro, como mucho se quita lo que pisa muro)
	}
	vec2 hasta = mundo;
	if (modo == 1) {
		hasta.y = max(hasta.y, pie.y);
	}
	// de su centro al píxel, a pasos de menos de media casilla (32 en el mundo): ningún muro se cuela entre dos
	int pasos = int(clamp(ceil(distance(pie, hasta) / 12.0), 1.0, 40.0));
	for (int i = 1; i <= 40; i++) {
		if (i > pasos) {
			break;
		}
		if (libre(mix(pie, hasta, float(i) / float(pasos))) < 0.5) {
			return 0.0;
		}
	}
	return 1.0;
}
