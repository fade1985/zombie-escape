// Johnny partido por la cintura (johnny.gd): al golpear andando, el dibujo del golpe pone el cuerpo y otro
// dibujo debajo, el de andar, pone las piernas. Así no se le quedan los pies quietos mientras avanza.
// "parte": 0 = entero (lo normal), 1 = el golpe (todo menos sus piernas), 2 = solo las piernas de andar.
// Por debajo de la cintura se mira el color: las piernas son los vaqueros (azules) y lo oscuro (botas y bordes),
// y solo cerca de los pies. Lo demás (el barrido, el agua, la fregona, el palo) es del golpe y no se corta.
shader_type canvas_item;

uniform int parte = 0;
uniform float cintura = 17.0;   // píxeles del dibujo por encima de los pies
uniform float ancho = 14.5;     // hasta dónde llegan las piernas a cada lado de los pies

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
	COLOR = c * COLOR;
}
