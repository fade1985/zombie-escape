// El golpe del chorro (chorro-golpe.js) del lanza hielo en un zombi: niebla helada que se abre y cae, esquirlas que saltan
// y se quedan un momento en el suelo, y cristalitos; con los azules del chorro (chorro_hielo.gdshader).
import * as base from "./chorro-golpe.js";

export const meta = {
  ...base.meta,
  name: "Golpe del chorro de hielo",
  desc: "A freezing jet hitting a body, seen from above: icy mist billows out and sinks, ice shards spray and frost the floor, crystals glint.",
  options: { ...base.meta.options, tipo: "hielo", palette: ["#0e1a33", "#223e70", "#3a76b6", "#66b2e4", "#9edef8", "#cdeffc", "#ffffff"], seed: 5 },
};
export const create = base.create;
