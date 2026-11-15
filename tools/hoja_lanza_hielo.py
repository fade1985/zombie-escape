# La hoja de Johnny con el lanza hielo: la del lanzallamas, con las dos bombonas de la espalda en blanco y azul hielo en
# vez de rojo y sin la llamita del piloto en la punta del tubo (el vaho frío que cae de la punta lo pinta el juego).
# Sin PixelLab, como el lanza ácido: hace lo mismo que tools/hoja_lanza_acido.py (cambiar los rojos, borrar la llamita y
# apuntar en el .tres la punta del tubo de cada dibujo de reposo, "puntas"), con otros colores.
# Saca assets/sprites/conserje-48-lanza-hielo.png, su .json y su .tres. Las skins, después, con tools/cara.py:
#   py tools/hoja_lanza_hielo.py            → la hoja (y luego, para cada skin, py tools/cara.py <skin> lanza-hielo)
#   py tools/hoja_lanza_hielo.py muestra    → además, capturas/captura-lanza-hielo.png (la punta del tubo, antes y después)
import hoja_lanza_acido as base

# Cada rojo de las bombonas por su azul: brillo (casi blanco), medio, medio tostado, sombra tostada y sombra (el azul del
# medio es el del chorro de hielo, llamarada.gd, HIELO)
HIELO = {
    (238, 96, 74): (236, 250, 255),
    (200, 58, 40): (158, 222, 248),
    (166, 50, 36): (102, 178, 228),
    (122, 40, 30): (58, 118, 182),
    (78, 36, 34): (34, 62, 112),
}

if __name__ == "__main__":
    base.A = "conserje-48-lanza-hielo"
    base.SCRIPT = "hoja_lanza_hielo.py"
    base.MUESTRA = "captura-lanza-hielo.png"
    base.VERDES = HIELO
    base.main()
