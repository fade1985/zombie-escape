// Johnny partido por la cintura (johnny.gd): al golpear andando, el dibujo del golpe pone el cuerpo y otro
// dibujo debajo, el de andar, pone las piernas. Así no se le quedan los pies quietos mientras avanza.
// "parte": 0 = entero (lo normal), 1 = el golpe (todo menos sus piernas), 2 = solo las piernas de andar.
// Por debajo de la cintura se mira el color: las piernas son los vaqueros (azules) y lo oscuro (botas y bordes),
// y solo cerca de los pies. Lo demás (el barrido, el agua, la fregona, el palo) es del golpe y no se corta.
//
// Y los trajes (trajes.gd): la ropa también se reconoce por su color, en las siete hojas de Johnny y en todas
// sus animaciones: el peto (los vaqueros azules), la camisa (crema) y el pañuelo (rojo). A cada zona se le
// cambia el tono y se le multiplican la saturación y la luz, así el sombreado y los bordes se quedan como
// estaban. Cada zona es un vec3(tono en grados, × saturación, × luz); con el tono negativo no se toca.
shader_type canvas_item;

uniform int parte = 0;
uniform float cintura = 17.0;   // píxeles del dibujo por encima de los pies
uniform float ancho = 14.5;     // hasta dónde llegan las piernas a cada lado de los pies
uniform vec3 peto = vec3(-1.0, 1.0, 1.0);
uniform vec3 camisa = vec3(-1.0, 1.0, 1.0);
uniform vec3 panuelo = vec3(-1.0, 1.0, 1.0);

varying vec2 sitio;

void vertex() {
	// Los pies están en el 0 (el offset del dibujo los pone ahí): hacia arriba es negativo
	sitio = vec2(VERTEX.x, -VERTEX.y);
}

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

// ── Los trajes ──

// De rojo-verde-azul a tono-saturación-luz, y vuelta (las fórmulas de siempre; el tono va de 0 a 1)
vec3 a_tsl(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 a_rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// La ropa con el traje puesto. Cada zona se reconoce por su color en el dibujo original:
//   el peto, los azules (tono de 195 a 245) no muy claros: el arco de aire de la fregona es cian y casi blanco;
//   la camisa, los cremas (tono de 30 a 55, poca saturación y claros): el pelo es más naranja y más saturado,
//   la piel más rosada, y el bate y la culata de la escopeta, más saturados;
//   el pañuelo, los rojos muy saturados.
vec3 vestir(vec3 rgb) {
	vec3 tsl = a_tsl(rgb);
	float tono = tsl.x * 360.0;
	vec3 cambio = vec3(-1.0, 1.0, 1.0);
	if (tono >= 195.0 && tono <= 245.0 && tsl.y >= 0.22 && tsl.z <= 0.8) {
		cambio = peto;
	} else if (tono >= 30.0 && tono <= 55.0 && tsl.y >= 0.12 && tsl.y <= 0.5 && tsl.z >= 0.5) {
		cambio = camisa;
	} else if ((tono <= 12.0 || tono >= 345.0) && tsl.y >= 0.6 && tsl.z >= 0.3) {
		cambio = panuelo;
	}
	if (cambio.x < 0.0) {
		return rgb;
	}
	return a_rgb(vec3(cambio.x / 360.0, min(tsl.y * cambio.y, 1.0), min(tsl.z * cambio.z, 1.0)));
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	bool abajo = sitio.y < cintura;
	bool cerca = abs(sitio.x) < ancho;
	if (parte == 1 && abajo && pierna(c)) {
		discard;
	}
	if (parte == 1 && abajo && cerca && luz(c) <= 0.45) {
		discard;   // los brillos de sus botas
	}
	if (parte == 2) {
		if (!abajo || !cerca || !pierna(c)) {
			discard;
		}
		// Un borde oscuro pegado al palo es del palo, no de la pierna
		if (!vaquero(c)) {
			vec2 p = TEXTURE_PIXEL_SIZE;
			if (otra_cosa(texture(TEXTURE, UV + vec2(p.x, 0.0))) || otra_cosa(texture(TEXTURE, UV - vec2(p.x, 0.0)))
					|| otra_cosa(texture(TEXTURE, UV + vec2(0.0, p.y))) || otra_cosa(texture(TEXTURE, UV - vec2(0.0, p.y)))) {
				discard;
			}
		}
	}
	// Lo que se ve, ya con los colores del traje (las pruebas de arriba se hacen sobre los de siempre)
	COLOR = vec4(vestir(c.rgb), c.a) * COLOR;
}
