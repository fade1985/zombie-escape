// Común a los borradores del aviso del giro del jefe de bomberos (Johnny Rush), vistos desde arriba: el jefe en el
// centro, sus dos conos de fuego (enfadado) hasta la pared y, arriba a la izquierda, la marca de un molotov, todo con el
// mismo estilo, más sutil que el A: la zona apenas oscurecida, un borde fino oscuro y otro del color, relleno flojo con
// su frente claro. Gira como las agujas del reloj (SENTIDO 1). Cada borrador cambia lo que dice hacia dónde gira.
import { hex, WHITE, clamp } from "../../core/index.js";

export const D = 1.5, TW = 1.0, SENTIDO = 1;
export const L = 120, AB = 0.35;                         // lo largo de los conos (hasta la pared) y su medio ángulo
export const CONOS = [-0.5, -0.5 + Math.PI];             // hacia dónde mira cada uno
export const MOL = { x: -95, y: -55, r: 27, ap: 0.6 };   // la marca del molotov (aplastada)
export const META = { size: [300, 190], origin: [150, 95], duration: D, loop: true, fps: 30, bg: "dark" };
export const ROJO = hex("#ff3d59"), OSC = hex("#3a0a14"), MED = hex("#b0182f"), BRI = hex("#ffd1d9");
export { WHITE, clamp };

export const fase = (t) => [clamp(t / TW), t - TW];
const dang = (a, b) => Math.atan2(Math.sin(a - b), Math.cos(a - b));

/** El estilo común: "d" lo que se ha avanzado (px), "hasta" donde acaba, "borde" px al borde, "k" lo que lleva. */
export function sutil(p, x, y, d, hasta, borde, k, t) {
  const fog = t > TW - 0.06 && t < TW;
  if (borde < 1) return p.blend(x, y, OSC, fog ? 0.9 : 0.6);
  if (borde < 2) return p.blend(x, y, fog ? WHITE : ROJO, 0.75);
  if (fog) return p.blend(x, y, WHITE, 0.45);
  const lleno = hasta * k;
  if (d < lleno - 1.5) return p.blend(x, y, ROJO, 0.28 + 0.12 * k);
  if (d < lleno + 0.5) return p.blend(x, y, BRI, 0.7);
  p.blend(x, y, OSC, 0.18);
}

/** Los conos y la marca del molotov, con el estilo común. */
export function zonas(p, t) {
  const [k] = fase(t);
  if (k >= 1 && t > TW) return;
  for (let y = -95; y < 95; y++)
    for (let x = -150; x < 150; x++) {
      const px = x + 0.5, py = y + 0.5, r = Math.hypot(px, py), a = Math.atan2(py, px);
      for (const c of CONOS) {
        const g = Math.abs(dang(a, c));
        if (g <= AB && r <= L && r > 6) sutil(p, px, py, r, L, Math.min(L - r, (AB - g) * r), k, t);
      }
      const mx = px - MOL.x, my = (py - MOL.y) / MOL.ap, mr = Math.hypot(mx, my);
      if (mr <= MOL.r) sutil(p, px, py, mr, MOL.r, (MOL.r - mr) * MOL.ap, k, t);
    }
}

/** Un píxel con contorno: el color en el sitio y la base oscura alrededor (para las flechas). */
export function punto(p, x, y, c, a = 1) {
  p.blend(x, y, c, a);
}
