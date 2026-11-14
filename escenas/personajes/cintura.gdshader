// Johnny partido por la cintura (johnny.gd): al golpear andando, el dibujo del golpe pone el cuerpo y otro
// dibujo debajo, el de andar, pone las piernas. Así no se le quedan los pies quietos mientras avanza.
// "parte": 0 = entero (lo normal), 1 = el golpe (todo menos sus piernas), 2 = solo las piernas de andar.
// Qué píxeles son piernas lo dice la "mascara" de la hoja de esa arma (assets/sprites/<hoja>-piernas.png, del mismo
// tamaño que la hoja y solo con las piernas, en su sitio; la saca tools/piernas.py, que lo decide con calma dibujo a
// dibujo). Del golpe se quita lo que ahí es pierna; y las piernas de andar se pintan de esa imagen, no de la hoja,
// porque trae relleno lo que el arma tapa al andar (los muslos detrás de la motosierra).
// Si una hoja no tiene máscara ("con_mascara" apagado), se adivina por el color, como antes del 14 nov, y falla: lo
// claro del vaquero no cuenta como pierna (agujeros y trozos sueltos) y lo oscuro del arma sí (se cuela). Por el
// color: por debajo de la cintura, las piernas son los vaqueros (azules) y lo oscuro (botas y bordes), y solo cerca
// de los pies. Lo demás (el barrido, el agua, la fregona, el palo) es del golpe y no se corta.
// Además arde como los zombis ("fuego", y lo demás de quemaduras.gdshaderinc, que se incluye al final y pone el
// dibujo): aquí solo se dice qué píxeles se quitan (RECORTE).
shader_type canvas_item;

uniform int parte = 0;
uniform sampler2D mascara : filter_nearest;
uniform bool con_mascara = false;
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
	if (con_mascara) {
		bool es_pierna = texture(mascara, uv).a > 0.5;
		return parte == 1 ? es_pierna : !es_pierna;
	}
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

// De dónde sale el color: las piernas de andar, de la imagen de piernas; lo demás, de la hoja
vec4 dibujo(sampler2D tex, vec2 uv) {
	if (con_mascara && parte == 2) {
		return texture(mascara, uv);
	}
	return texture(tex, uv);
}

#define DIBUJO dibujo(TEXTURE, UV)
#define RECORTE if (parte != 0 && fuera(TEXTURE, UV, TEXTURE_PIXEL_SIZE, vec2(lugar.x, -lugar.y))) { discard; }
#include "res://escenas/personajes/quemaduras.gdshaderinc"
