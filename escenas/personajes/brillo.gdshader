// La copia del dibujo que brilla a oscuras (scripts/brillo.gd): de quemaduras.gdshaderinc solo pinta lo que luce
// (las llamas, las chispas y, más flojo, el ácido), y "unshaded" hace que no le afecte la penumbra
shader_type canvas_item;
render_mode unshaded;

#define SOLO_BRILLO
#include "res://escenas/personajes/quemaduras.gdshaderinc"
