// El golpe de una carga que se estrella contra la pared (M58; minijefe.gd, estrellarse): el pisotón (golpe-suelo.js) sin
// onda ni grietas, a la altura del cuerpo: una nube de yeso y cascotes que caen al suelo y rebotan.
import * as base from "./golpe-suelo.js";

export const meta = {
  ...base.meta,
  name: "Golpe contra la pared",
  desc: "A heavy body slams into a wall, seen from above: a burst of plaster dust at body height and rubble that falls to the floor, bounces and settles.",
  size: [120, 110],
  origin: [60, 74],
  duration: 1.0,
  options: { ...base.meta.options, palette: ["#2a2622", "#4a4540", "#77706a", "#a39c92", "#c9c2b6", "#e4ded2", "#f6f2ea"], reach: 30, height: 26, ring: false, chunks: 14, seed: 8 },
};
export const create = base.create;
