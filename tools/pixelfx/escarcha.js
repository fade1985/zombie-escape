// El estallido de escarcha (M51), visto desde arriba: el de la congeladora al explotar (granada.gd, en vez de la bola de
// fuego) y, pequeño (escarcha-zombi.js), el de cada zombi que se congela (zombi.gd, congelar). Hecho para el juego con las
// piezas del "frost-nova" de pixelfx (sus cristales, la banda del anillo y los copos):
//  - un destello blanco y un copo de seis brazos en el centro;
//  - un anillo de frío que se abre por el suelo (en elipse: VISTA, lo de arriba abajo más corto) y deja detrás una costra
//    de escarcha;
//  - cristales de hielo que brotan del suelo cuando el anillo pasa por su sitio (más y más grandes hacia fuera), brillan
//    y luego se funden y se hunden;
//  - trozos de hielo que saltan y caen cada uno en su sitio (con su altura, z), vaho frío y copos.
// "reach": hasta dónde llega, en píxeles del dibujo · "height": a qué altura está el centro (el copo) · "crystals": cuántos
// cristales · "tall": lo alto de los cristales. El origen es el suelo, en el centro. Lo exporta exportar.mjs.
import { Particles, Lights, P, Rng, fit, crystal, band, flare, clamp, smooth, ease, TAU, WHITE, hex } from "../../core/index.js";

export const meta = {
  name: "Escarcha",
  desc: "A frost burst from above: a white pop, a ring of cold opening over the floor leaving frost, ice crystals punching up as it passes, then melting away.",
  tags: ["ice", "frost", "nova", "aoe", "one-shot"],
  size: [176, 136],
  origin: [88, 80],
  duration: 1.6,
  loop: false,
  fps: 30,
  bg: "ground",
  options: { palette: ["#151a3d", "#212f6b", "#2c58aa", "#3a8bd8", "#62c8f4", "#a6ecff", "#dcfbff", "#ffffff"], reach: 60, height: 10, crystals: 34, tall: 1, seed: 4 },
};

const VISTA = 0.6, ABRE = 0.3, FUNDE = [1.0, 1.4];

export function create(o) {
  const C = fit(o.palette, 8), CH = C.map((c) => (typeof c === "string" ? hex(c) : c)), R = new Rng(o.seed);
  const REACH = o.reach, H = o.height, ps = new Particles({ rng: R, ground: () => 999 }), lights = new Lights();
  const frente = (t) => REACH * ease.outCubic(clamp(t / ABRE));
  const llega = (d) => ABRE * (1 - Math.cbrt(1 - Math.min(1, d / REACH)));
  // los cristales: repartidos por la elipse, más hacia fuera; cada uno se inclina hacia fuera
  const sitios = [];
  for (let i = 0; i < o.crystals; i++) {
    const a = R.range(0, TAU), q = Math.sqrt(R.range(0.08, 1)), d = q * REACH * 0.95;
    const h = (3 + q * R.range(5, 9)) * o.tall, w = h * R.range(0.45, 0.65);
    sitios.push({ x: Math.cos(a) * d, y: Math.sin(a) * d * VISTA, h, w, lean: Math.cos(a) * h * R.range(0.15, 0.4), t0: llega(d) + R.range(0, 0.03), arriba: false, fase: R.next() });
  }
  sitios.sort((a, b) => a.y - b.y);   // los de detrás, primero
  // la costra de escarcha: puntitos fijos por el suelo
  const costra = Array.from({ length: Math.round(REACH * REACH * 0.28) }, () => {
    const a = R.range(0, TAU), q = Math.sqrt(R.next());
    return { x: Math.round(Math.cos(a) * q * REACH), y: Math.round(Math.sin(a) * q * REACH * VISTA), q, c: R.chance(0.12) ? WHITE : R.chance(0.5) ? C[6] : C[5] };
  });
  // trozos de hielo: saltan desde el centro, cada uno con su altura
  const trozos = Array.from({ length: Math.round(REACH / 4) }, () => {
    const a = R.range(0, TAU), sp = R.range(60, 150) * (REACH / 60);
    return { x: 0, y: 0, z: H, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp * VISTA, vz: R.range(40, 110), giro: R.range(0, TAU), vgiro: R.range(-16, 16), s: R.range(1.5, 3), c: R.pick([C[7], C[6], C[5]]), vida: R.range(0.6, 1.0) };
  });
  lights.add(0, -H, REACH * 1.4, C[4], 0.8, 0.5);
  lights.add(0, -H, REACH * 0.6, WHITE, 0.7, 0.1);
  for (let i = 0; i < REACH / 5; i++) {
    const a = R.range(0, TAU), sp = R.range(20, 70);
    ps.spawn(P.FLAKE, 0, -H, Math.cos(a) * sp, Math.sin(a) * sp * VISTA - R.range(10, 40), R.range(0.9, 1.4), R.chance(0.6) ? WHITE : C[6], R.range(0.5, 1.4));
  }
  let t = 0;
  const funde = (tt) => smooth(FUNDE[0], FUNDE[1], tt);

  return {
    update(dt) {
      t += dt;
      const fr = frente(t);
      // el vaho que levanta el anillo al pasar
      if (t < ABRE)
        for (let i = 0; i < 3; i++) {
          const a = R.range(0, TAU);
          ps.spawn(P.VAPOUR, Math.cos(a) * fr, Math.sin(a) * fr * VISTA, Math.cos(a) * R.range(10, 40), Math.sin(a) * R.range(5, 20) - R.range(2, 10), R.range(0.4, 0.7), R.chance(0.7) ? C[6] : C[5], R.range(2, 4) * (REACH / 60 + 0.4));
        }
      for (const s of sitios)
        if (!s.arriba && t >= s.t0) {
          s.arriba = true;
          if (s.h > 7) ps.spawn(P.STAR, s.x, s.y - s.h * 0.7, 0, -3, R.range(0.25, 0.5), C[6], R.range(1, 2.2));
        }
      // mientras aguanta, brillitos por los cristales
      if (t > ABRE && t < FUNDE[0] && R.chance(0.4 * Math.min(1, o.crystals / 20))) {
        const s = R.pick(sitios);
        ps.spawn(P.STAR, s.x + R.range(-2, 2), s.y - R.range(1, s.h * 0.9), 0, -3, R.range(0.25, 0.45), R.chance(0.6) ? C[6] : WHITE, R.range(0.6, 1.8));
      }
      for (let i = trozos.length - 1; i >= 0; i--) {
        const g = trozos[i];
        if ((g.vida -= dt) <= 0) {
          trozos.splice(i, 1);
          continue;
        }
        g.vz -= 500 * dt;
        g.z += g.vz * dt;
        if (g.z <= 0) {
          g.z = 0;
          g.vz = g.vz < -60 ? -g.vz * 0.3 : 0;
          g.vx *= 0.6; g.vy *= 0.6; g.vgiro *= 0.5;
        }
        const roce = g.z > 0 ? 0.5 : 5;
        g.vx -= g.vx * roce * dt; g.vy -= g.vy * roce * dt;
        g.x += g.vx * dt; g.y += g.vy * dt; g.giro += g.vgiro * dt;
      }
      ps.update(dt);
      lights.update(dt);
    },
    drawBack(p) {
      // la costra de escarcha, por donde ya ha pasado el anillo; se va al fundirse
      const fr = frente(t), va = 1 - smooth(FUNDE[0], FUNDE[1] + 0.15, t);
      if (va > 0)
        for (const m of costra) {
          if (m.q * REACH > fr) continue;
          p.dot(m.x, m.y, m.c, va * (0.9 - m.q * 0.45));
        }
      // el anillo: la mitad de detrás
      if (t < ABRE + 0.12) {
        const u = clamp(t / (ABRE + 0.12));
        band(p, 0, 0, fr + 1, VISTA, Math.max(1.5, 6 * Math.pow(1 - u, 0.7) * (REACH / 60 + 0.3)), u < 0.7 ? 1 : (1 - u) / 0.3, C, (g) => Math.sin(g) < 0, t < 0.06);
      }
      // los cristales, que crecen de golpe, brillan y se hunden al fundirse
      const m = funde(t);
      for (const s of sitios) {
        if (!s.arriba || m >= 1) continue;
        const g = ease.outBack(clamp((t - s.t0) / 0.08), 2.4), brilla = (((t - s.t0) * 0.8 + s.fase * 3) % 1.6) / 0.5;
        crystal(p, s.x, s.y, s.h * g * (1 - m), s.w * (1 - m * 0.3), s.lean * g * (1 - m), C, { white: t < s.t0 + 0.03, glint: brilla <= 1 ? brilla : -1 });
      }
      ps.draw(p, "back");
    },
    draw(p) {
      // el anillo: la mitad de delante
      const fr = frente(t);
      if (t < ABRE + 0.12) {
        const u = clamp(t / (ABRE + 0.12));
        band(p, 0, 0, fr + 1, VISTA, Math.max(1.5, 6 * Math.pow(1 - u, 0.7) * (REACH / 60 + 0.3)), u < 0.7 ? 1 : (1 - u) / 0.3, C, (g) => Math.sin(g) >= 0, t < 0.06);
      }
      // el destello y el copo del centro
      if (t < 0.28) {
        const k = 1 - t / 0.28;
        flare(p, 0, -H, (4 + REACH * 0.12) * ease.outCubic(k), k, C);
        p.glow(0, -H, 10 + REACH * 0.4, C[5], 0.6 * k);
        if (t < 0.06) p.glow(0, -H, 8 + REACH * 0.15, WHITE, 0.5);
      }
      // los trozos de hielo, con su sombra mientras van por el aire
      for (const g of trozos) {
        const al = Math.min(1, g.vida / 0.25), ca = Math.cos(g.giro), sa = Math.sin(g.giro);
        if (g.z > 1) p.dot(g.x, g.y, CH[1], 0.4 * al);
        for (let d = -g.s / 2; d <= g.s / 2; d += 0.5) p.dot(g.x + ca * d, g.y - g.z + sa * d, d > g.s / 2 - 0.6 ? WHITE : g.c, al);
      }
      ps.draw(p, "front");
      lights.draw(p);
    },
  };
}
