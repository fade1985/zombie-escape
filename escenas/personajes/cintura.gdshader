// Johnny partido por la cintura (johnny.gd): al golpear andando, el dibujo del golpe pone el cuerpo y otro
// dibujo debajo, el de andar, pone las piernas. Así no se le quedan los pies quietos mientras avanza.
// "parte": 0 = entero (lo normal), 1 = el golpe (todo menos sus piernas), 2 = solo las piernas de andar.
// Por debajo de la cintura se mira el color: las piernas son los vaqueros (azules) y lo oscuro (botas y bordes),
// y solo cerca de los pies. Lo demás (el barrido, el agua, la fregona, el palo) es del golpe y no se corta.
// Además arde como los zombis ("fuego", y lo demás de quemaduras.gdshaderinc, que se incluye al final y pone el
// dibujo): aquí solo se dice qué píxeles se quitan (RECORTE).
shader_type canvas_item;

uniform int parte = 0;
uniform float cintura = 17.0;   // píxeles del dibujo por encima de los pies
uniform float ancho = 14.5;     // hasta dónde llegan las piernas a cada lado de los pies

float luz(vec4 c) {
	return dot(c.rgb, vec3(0.299, 0.587, 0.114));
}

bool vaquero(vec4 c) {
	return c.b > c.r + 0.05 && luz(c) < 0.45;
}

bool pierna(vec4 c) {
	return c.a > 0.0 && (vaquero(c) || luz(c) < 0.33);
}

// El palo de la fregona, la mano...: se ve, pero no es pierna
bool otra_cosa(vec4 c) {
	return c.a > 0.0 && !pierna(c);
}

// Si ese píxel no va en esta parte. "sitio": los pies están en el 0 (el offset del dibujo los pone ahí) y hacia
// arriba es positivo
bool fuera(sampler2D tex, vec2 uv, vec2 p, vec2 sitio) {
	vec4 c = texture(tex, uv);
	bool abajo = sitio.y < cintura;
	bool cerca = abs(sitio.x) < ancho;
	if (parte == 1 && abajo && pierna(c)) {
		return true;
	}
	if (parte == 1 && abajo && cerca && luz(c) <= 0.45) {
		return true;   // los brillos de sus botas
	}
	if (parte == 2) {
		if (!abajo || !cerca || !pierna(c)) {
			return true;
		}
		// Un borde oscuro pegado al palo es del palo, no de la pierna
		if (!vaquero(c)) {
			if (otra_cosa(texture(tex, uv + vec2(p.x, 0.0))) || otra_cosa(texture(tex, uv - vec2(p.x, 0.0)))
					|| otra_cosa(texture(tex, uv + vec2(0.0, p.y))) || otra_cosa(texture(tex, uv - vec2(0.0, p.y)))) {
				return true;
			}
		}
	}
	return false;
}

#define RECORTE if (parte != 0 && fuera(TEXTURE, UV, TEXTURE_PIXEL_SIZE, vec2(lugar.x, -lugar.y))) { discard; }
#include "res://escenas/personajes/quemaduras.gdshaderinc"
