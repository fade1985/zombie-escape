// El reventón de sangre (reventon-sangre.js) con la sangre morada del de tentáculos (partida.gd, MANCHAS).
import * as base from "./reventon-sangre.js";

export const meta = { ...base.meta, options: { ...base.meta.options, palette: ["#1c0f28", "#38204f", "#5a3480", "#7b4fa0", "#ab84cc"] } };
export const create = base.create;
