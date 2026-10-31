// El reventón de sangre (reventon-sangre.js) con la sangre verde del venenoso (partida.gd, MANCHAS).
import * as base from "./reventon-sangre.js";

export const meta = { ...base.meta, options: { ...base.meta.options, palette: ["#16300c", "#2f5a14", "#5e9a26", "#8fd13f", "#c4f07a"] } };
export const create = base.create;
