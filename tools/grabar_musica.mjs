// ─────────────────────────────────────────────
//  Graba la música de fondo del juego JS (src/musica.js, que se inventa sobre la marcha) en tramos .ogg
//  para Godot: varios de cada momento (menú, explorar, jefe), cada uno distinto. En el juego,
//  scripts/sonido.gd los encadena al azar con fundidos, así que nunca suena igual dos veces seguidas.
//
//  node tools/grabar_musica.mjs        → assets/musica/<momento>-<n>.ogg
//  Necesita el juego JS en D:\Personal\Proyectos\game (con Playwright en su node_modules) y ffmpeg.
//  Graba igual que tools/grabar-musica.mjs del JS: volumen de la música (0,55) y el compresor general.
// ─────────────────────────────────────────────
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const AQUI = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const JS = 'D:/Personal/Proyectos/game';
const SALIDA = path.join(AQUI, 'assets', 'musica');
const TEMP = path.join(AQUI, 'tools', 'efectos');   // ya está en .gitignore y Godot no lo mira
// [momento en el JS, nombre en Godot, cuántos tramos, segundos de cada uno]
const TRAMOS = [['menu', 'menu', 2, 60], ['explore', 'explorar', 5, 72], ['boss', 'jefe', 3, 48]];
const ARRANQUE = 4;   // segundos del principio que se tiran (la música entra despacio)
const SR = 32000;

const { chromium } = createRequire(path.join(JS, 'package.json'))('playwright');
const server = http.createServer((req, res) => {
  const file = path.join(JS, decodeURIComponent(new URL(req.url, 'http://x').pathname));
  if (!file.startsWith(path.resolve(JS)) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    return res.end('<!doctype html><title>musica</title>');
  }
  res.writeHead(200, { 'Content-Type': 'text/javascript' });
  fs.createReadStream(file).pipe(res);
});
await new Promise((ok) => server.listen(0, ok));
const browser = await chromium.launch();
const page = await browser.newPage();
await page.goto(`http://localhost:${server.address().port}/`);
fs.mkdirSync(SALIDA, { recursive: true });
fs.mkdirSync(TEMP, { recursive: true });

for (const [modo, nombre, cuantos, dur] of TRAMOS) {
  for (let n = 1; n <= cuantos; n++) {
    const { wav, pico } = await page.evaluate(async ({ modo, dur, sr }) => {
      const { crearMusica } = await import('/src/musica.js');
      const ac = new OfflineAudioContext(2, sr * dur, sr);
      const comp = ac.createDynamicsCompressor();
      comp.threshold.value = -14;
      comp.ratio.value = 6;
      comp.connect(ac.destination);
      const vol = ac.createGain();
      vol.gain.value = 0.55;
      vol.connect(comp);
      const m = crearMusica(ac, vol);
      m.play(modo);
      m.programar(dur);
      const buf = await ac.startRendering();
      const L = buf.getChannelData(0), R = buf.getChannelData(1);
      const k = L.length;
      let pico = 0;
      const datos = new DataView(new ArrayBuffer(44 + k * 4));
      const txt = (o, s) => [...s].forEach((c, i) => datos.setUint8(o + i, c.charCodeAt(0)));
      txt(0, 'RIFF'); datos.setUint32(4, 36 + k * 4, true); txt(8, 'WAVEfmt ');
      datos.setUint32(16, 16, true); datos.setUint16(20, 1, true); datos.setUint16(22, 2, true);
      datos.setUint32(24, sr, true); datos.setUint32(28, sr * 4, true); datos.setUint16(32, 4, true);
      datos.setUint16(34, 16, true); txt(36, 'data'); datos.setUint32(40, k * 4, true);
      for (let i = 0; i < k; i++) {
        pico = Math.max(pico, Math.abs(L[i]), Math.abs(R[i]));
        datos.setInt16(44 + i * 4, Math.max(-1, Math.min(1, L[i])) * 32767, true);
        datos.setInt16(46 + i * 4, Math.max(-1, Math.min(1, R[i])) * 32767, true);
      }
      const bytes = new Uint8Array(datos.buffer);
      let bin = '';
      for (let i = 0; i < bytes.length; i += 0x8000) bin += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
      return { wav: btoa(bin), pico: (20 * Math.log10(pico)).toFixed(1) };
    }, { modo, dur: dur + ARRANQUE, sr: SR });
    const crudo = path.join(TEMP, `${nombre}-${n}.wav`);
    const ogg = path.join(SALIDA, `${nombre}-${n}.ogg`);
    fs.writeFileSync(crudo, Buffer.from(wav, 'base64'));
    execFileSync('ffmpeg', ['-y', '-loglevel', 'error', '-ss', String(ARRANQUE), '-i', crudo,
      '-c:a', 'libvorbis', '-q:a', '1', ogg]);
    fs.unlinkSync(crudo);
    console.log(`${path.relative(AQUI, ogg)}  ${dur} s, pico ${pico} dB, ${Math.round(fs.statSync(ogg).size / 1024)} KB`);
  }
}
await browser.close();
server.close();
