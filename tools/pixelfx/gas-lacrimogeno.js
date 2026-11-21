// La nube de gas lacrimógeno del antidisturbios (nube_gas.gd): el humo del "smoke-bomb" de pixelfx (licencia MIT,
// © Patch, https://github.com/patch-gg/pixelfx) pasado a vista desde arriba y a los colores del gas, blanco
// amarillento. El bote ya ha caído (lo dibuja el juego, proyectil.gd): revienta con un fogonazo y salen bolas de humo
// con volumen (luz arriba a la izquierda, sombra abajo) que ruedan por el suelo hasta llenar la elipse que pica (los
// 72 del radio de nube_gas.gd = 36 píxeles del dibujo; lo alto es 0,6 de lo ancho, como los charcos), se hinchan y
// suben un poco, sueltan hilillos y al final se deshacen. Dura lo que la nube (7 s).
// Lo exporta tools/pixelfx/exportar.mjs a assets/sprites/gas-lacrimogeno-*.png.
import { Particles, P, Rng, fit, smooth, clamp, ease, TAU, WHITE } from "../../core/index.js";
import { lobe, haze } from "../explosions/_lib.js";

export const meta = {
  name: "Gas lacrimógeno",
  desc: "A tear gas cloud seen from above: a spent canister pops and pale yellow-white smoke balls roll out across the floor to fill an oval, billow, shed wisps, thin away.",
  tags: ["smoke", "gas", "cloud", "tear-gas", "ground", "one-shot"],
  size: [116, 92],
  origin: [58, 62],
  duration: 7,
  loop: false,
  fps: 30,
  bg: "ground",
  options: { palette: ["#1a1a10", "#34331f", "#55533a", "#7c7a58", "#a8a67c", "#d2d0a6", "#f2f0d2"], seed: 5 },
};

const D = meta.duration, F = 0.6, RAD = 36, N = 24;

export function create(o) {
  const C = fit(o.palette, 7), R = new Rng(o.seed);
  const SM = [C[6], C[5], C[4], C[3], C[2]];
  const ps = new Particles({ rng: R });
  // cada bola sale del bote y rueda hasta su sitio dentro de la elipse; las del borde, las últimas
  const bolas = Array.from({ length: N }, (_, i) => {
    const a = R.range(0, TAU), d = i < 3 ? R.range(0, 0.3) : Math.sqrt(R.range(0.05, 1)) * 0.82;
    return {
      tx: Math.cos(a) * d * RAD, ty: Math.sin(a) * d * RAD * F, t0: 0.04 + 0.4 * Math.pow(i / (N - 1), 1.3) + R.range(0, 0.04),
      r0: R.range(3, 5), r1: R.range(8.5, 12.5) * (1 - 0.25 * d), f: R.range(-0.6, 0), wob: R.range(0, TAU), sube: R.range(2, 6),
    };
  });
  let t = 0;
  const vida = (b) => t - b.t0;
  const radio = (b) => (b.r0 + (b.r1 - b.r0) * (1 - Math.exp(-vida(b) / 0.3))) * (1 + 0.06 * Math.sin(t * 2.2 + b.wob)) * (1 + 0.3 * deshecho(b));
  const deshecho = (b) => smooth(5.4 + b.f, 6.85 + b.f * 0.15, t);
  const sitio = (b) => {
    const u = ease.outCubic(clamp(vida(b) / 0.7));
    const x = b.tx * u + Math.sin(t * 0.8 + b.wob) * 1.5, y = b.ty * u + Math.cos(t * 0.6 + b.wob) * 1;
    const h = 1 + b.sube * smooth(0.3, 4, vida(b)) + 3 * deshecho(b);
    return [x, y, h];
  };

  return {
    update(dt) {
      t += dt;
      // el reventón: unas motas de polvo
      if (t - dt <= 0.02 && t > 0.02)
        for (let i = 0; i < 10; i++) {
          const a = R.range(0, TAU), sp = R.range(40, 110);
          ps.spawn(P.DUST, 0, -1, Math.cos(a) * sp, Math.sin(a) * sp * F - 10, R.range(0.3, 0.6), C[4], R.range(1.2, 2));
        }
      // los hilillos que se van del humo
      for (const b of bolas) {
        if (vida(b) < 0.6) continue;
        const k = deshecho(b);
        if (k < 0.85 && R.chance(0.35 * dt)) {
          const [x, y, h] = sitio(b), r = radio(b), life = Math.min(R.range(1, 1.6), D - 0.1 - t);
          if (life > 0.3) ps.spawn(P.VAPOUR, x + R.range(-r, r) * 0.4, y - h - r * 1.3, R.range(-5, 5), -R.range(8, 18), life, C[6], r * R.range(0.3, 0.45));
        }
      }
      ps.update(dt);
    },
    drawBack(p) {
      // la sombra flojita de la nube en el suelo
      const k = smooth(0, 0.6, t) * (1 - smooth(5.6, 6.9, t));
      if (k > 0) haze(p, 0, 0, RAD * (0.5 + 0.5 * k), RAD * F * (0.5 + 0.5 * k), C[1], (d) => 0.28 * k * (1 - d));
      ps.draw(p, "back");
    },
    draw(p) {
      // las bolas, las de atrás primero; translúcidas para que se vea a quien está dentro
      const on = bolas.filter((b) => vida(b) > 0).sort((a, b) => a.ty - b.ty);
      for (const b of on) {
        const [x, y, h] = sitio(b), r = radio(b), k = deshecho(b);
        const a = Math.min(1, vida(b) / 0.06) * Math.pow(1 - k, 1.2) * 0.62;
        const sombra = b.ty > RAD * F * 0.3 ? 1 : 0;   // las de delante, un poco más en la sombra de la nube
        lobe(p, x, y - h - r * 0.6, r, SM, SM, 0, 0, a, 0, sombra, 1);
      }
      ps.draw(p, "front");
      // el fogonazo del reventón
      if (t < 0.07) {
        p.circle(0, -3, 5.5, C[5]);
        p.circle(0, -3, 3.5, WHITE);
      }
      if (t < 0.3) p.glow(0, -3, 16, C[6], 0.6 * (1 - t / 0.3));
    },
  };
}
