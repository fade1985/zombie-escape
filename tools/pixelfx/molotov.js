// El molotov al romperse (proyectil.gd, llamarada): la botella revienta contra el suelo, visto desde arriba. Un chasquido
// blanco, la gasolina que sale en corro y prende con un golpe de llamas que suben y se vuelven humo, chispas y brasas, y los
// cristales verdes que saltan, rebotan en el suelo y resbalan. Sin humo: luego el charco de fuego del juego (charco.gd) sigue
// ardiendo, con el suyo.
// Visto desde arriba: lo que se reparte por el suelo va en elipse (VISTA: lo de arriba abajo, más corto), y los cristales
// llevan su propia altura (z) y caen cada uno en su sitio del suelo, no en una raya (como el suelo de pixelfx, y = 0).
// Lo exporta exportar_molotov.mjs.
import { Particles, Lights, P, Rng, fit, sparkle, ease, TAU, WHITE, hex, rgb } from "../../core/index.js";

export const meta = {
  name: "Molotov",
  desc: "A bottle smashes on the floor, seen from above: a white snap, fuel thrown out in a ring that catches in a whoosh of flame, sparks, and green glass shards that hop and skid away.",
  tags: ["fire", "impact", "glass", "one-shot"],
  size: [252, 202],   // (+16 por lado: que la luz no se salga del lienzo, 9 nov)
  origin: [126, 136],
  duration: 1.3,
  loop: false,
  fps: 30,
  bg: "ground",
  options: {
    palette: ["#1f0b10", "#4a1118", "#8c1d1c", "#cc3a1a", "#f2701f", "#ffae35", "#ffe27a", "#fff8d6"],
    glass: ["#1f3d34", "#3f7a68", "#7fc4a8", "#c8f2de"],
    size: 1,
    seed: 3,
  },
};

const VISTA = 0.6;                  // lo de arriba abajo, más corto: el suelo visto desde arriba
const WARM = rgb(255, 160, 80);

export function create(o) {
  const F = fit(o.palette, 8), G = fit(o.glass, 4).map(hex), S = o.size, R = new Rng(o.seed);
  const ps = new Particles({ rng: R, ground: () => 999, sparks: [F[6], F[5], F[3], F[2]] });
  const lights = new Lights();
  const vidrios = [];
  let t = 0;

  lights.add(0, -6, 70 * S, WARM, 0.8, 0.7);
  lights.add(0, -4, 30 * S, WHITE, 0.7, 0.07);
  // los cristales: saltan desde la botella, cada uno hacia su lado, con su saltito
  for (let i = 0; i < 18; i++) {
    const a = R.range(0, TAU), sp = R.range(70, 190) * S;
    vidrios.push({ x: Math.cos(a) * 2, y: Math.sin(a) * 2 * VISTA, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp * VISTA,
      z: 3, vz: R.range(60, 150), a: R.range(0, TAU), va: R.range(-22, 22), s: R.range(2.5, 4.5), c: R.pick([G[1], G[2], G[2], G[3]]),
      life: R.range(0.7, 1.15) });
  }
  // la gasolina, que sale en corro por el suelo
  for (let i = 0; i < 30; i++) {
    const a = R.range(0, TAU), d = R.range(1, 5) * S, sp = R.range(90, 210) * S;
    ps.spawn(P.FIRE, Math.cos(a) * d, Math.sin(a) * d * VISTA - 2, Math.cos(a) * sp, Math.sin(a) * sp * VISTA - 10,
      R.range(0.22, 0.4), 0, R.range(3, 5.5) * S, R.range(0, 0.05));
  }
  // y prende por donde ha caído: llamitas en un anillo, una detrás de otra
  for (let i = 0; i < 22; i++) {
    const a = R.range(0, TAU), r = R.range(12, 30) * S;
    ps.spawn(P.FIRE, Math.cos(a) * r, Math.sin(a) * r * VISTA, Math.cos(a) * 15, Math.sin(a) * 8 - 30, R.range(0.25, 0.5), 0,
      R.range(3, 5.5) * S, 0.05 + (r / (30 * S)) * 0.12);
  }
  // el golpe de llamas que sube en medio
  for (let i = 0; i < 8; i++)
    ps.spawn(P.FIRE, R.range(-7, 7) * S, -R.range(1, 5), R.range(-18, 18), -R.range(50, 110) * S, R.range(0.4, 0.7), 0,
      R.range(6, 10) * S, R.range(0.04, 0.14));
  // chispas y brasas
  for (let i = 0; i < 34; i++) {
    const a = R.range(0, TAU), sp = R.range(110, 280) * S;
    ps.spawn(P.SPARK, 0, -4, Math.cos(a) * sp, Math.sin(a) * sp * VISTA - 60, R.range(0.15, 0.4));
  }
  for (let i = 0; i < 12; i++) {
    const a = R.range(0, TAU), sp = R.range(20, 70);
    ps.spawn(P.EMBER, Math.cos(a) * 6, Math.sin(a) * 4 - 4, Math.cos(a) * sp, Math.sin(a) * sp * VISTA - 50, R.range(0.6, 1.1), F[3]);
  }

  return {
    update(dt) {
      t += dt;
      for (let i = vidrios.length - 1; i >= 0; i--) {
        const v = vidrios[i];
        if ((v.life -= dt) <= 0) {
          vidrios.splice(i, 1);
          continue;
        }
        v.vz -= 700 * dt;
        v.z += v.vz * dt;
        if (v.z <= 0) {
          // da en el suelo: rebota un poco y resbala, frenando
          v.z = 0;
          v.vz = v.vz < -80 ? -v.vz * 0.3 : 0;
          v.vx *= 0.75; v.vy *= 0.75; v.va *= 0.6;
        }
        const roce = v.z > 0 ? 0.6 : 5;
        v.vx -= v.vx * roce * dt; v.vy -= v.vy * roce * dt;
        v.x += v.vx * dt; v.y += v.vy * dt; v.a += v.va * dt;
      }
      ps.update(dt);
      lights.update(dt);
    },
    drawBack(p) {
      ps.draw(p, "back");
    },
    draw(p) {
      // el chasquido de la botella al romperse
      if (t < 0.07) sparkle(p, 0, -4, 11 * S * (1 - ease.outCubic(t / 0.07)), F[7], F[5]);
      // los cristales, con su sombra en el suelo mientras van por el aire
      for (const v of vidrios) {
        const al = Math.min(1, v.life / 0.3), ca = Math.cos(v.a), sa = Math.sin(v.a);
        if (v.z > 1) p.dot(v.x, v.y, G[0], 0.5 * al);
        for (let d = -v.s / 2; d <= v.s / 2; d += 0.5)
          p.dot(v.x + ca * d, v.y - v.z + sa * d, d > v.s / 2 - 0.6 ? WHITE : v.c, al);
      }
      ps.draw(p, "front");
      lights.draw(p);
    },
  };
}
