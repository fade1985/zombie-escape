// El destello blanco de los zombis al recibir un golpe (zombi.gd): mezcla el dibujo con blanco
shader_type canvas_item;

uniform float destello = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	COLOR = vec4(mix(c.rgb, vec3(1.0), destello), c.a);
}
