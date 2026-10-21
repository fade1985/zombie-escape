// El destello blanco de los zombis al recibir un golpe (zombi.gd): mezcla el dibujo con blanco.
// Y "hielo": congelado en la cámara frigorífica, lo mezcla con azul hielo
shader_type canvas_item;

uniform float destello = 0.0;
uniform float hielo = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	vec3 r = mix(c.rgb, vec3(0.72, 0.9, 1.0), hielo);
	COLOR = vec4(mix(r, vec3(1.0), destello), c.a);
}
