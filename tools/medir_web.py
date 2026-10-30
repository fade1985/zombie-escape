# Mide una prueba en la web de verdad (docs/WEB.md): abre Edge sin ventana, con la tarjeta gráfica, contra la exportación de
# web/ y saca por la terminal lo que dice la consola del juego, más un espía de WebGL que avisa de cada fotograma de más de
# 40 ms (qué llamadas se comieron el tiempo) y de cada shader que tarda más de 40 ms en montarse (con sus uniforms, para
# saber cuál es). Cada vez con un perfil nuevo, como un jugador que entra por primera vez.
#
# No se mide en el panel del navegador de la app: a ratos va a un fotograma por segundo aunque diga que está visible.
#
# Antes: exportar a web/ y arrancar su servidor (el "web" de .claude/launch.json, en el puerto 8060). Desde la carpeta del juego:
#   py tools/medir_web.py 45 --captura --molotov-carga --zombis 12
# El primer número son los segundos que espera; lo demás, los argumentos de la prueba. Al acabar deja web/index.html como estaba.
import os
import re
import subprocess
import sys
import tempfile
import threading
import time

PAGINA = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "web", "index.html")
EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

ESPIA = r"""<script>(() => {
 const P = WebGL2RenderingContext.prototype;
 let cur = {};
 for (const k of Object.getOwnPropertyNames(P)) {
   const d = Object.getOwnPropertyDescriptor(P, k);
   if (!d || typeof d.value !== 'function') continue;
   const f = d.value;
   P[k] = function(...a) { const t = performance.now(); const r = f.apply(this, a); const c = cur[k] || (cur[k] = [0, 0]); c[0]++; c[1] += performance.now() - t; return r; };
 }
 const fuentes = new WeakMap(), partes = new WeakMap(), nombres = new WeakMap();
 const ss = P.shaderSource; P.shaderSource = function(s, t) { fuentes.set(s, t); return ss.call(this, s, t); };
 const at = P.attachShader; P.attachShader = function(p, s) { partes.set(p, (partes.get(p) || []).concat([s])); return at.call(this, p, s); };
 const lk = P.linkProgram; P.linkProgram = function(p) {
   const t = (partes.get(p) || []).map(x => fuentes.get(x) || '').join(' ');
   const defs = [...new Set(t.match(/#define (USE_|DISABLE_)\w+/g) || [])].map(x => x.slice(8));
   const uniforms = (t.match(/uniform MaterialUniforms\s*\{([^}]*)\}/) || [0, '-'])[1].replace(/\s+/g, ' ').slice(0, 70);
   nombres.set(p, '[' + uniforms + '] ' + defs.join(','));
   return lk.call(this, p);
 };
 const gp = P.getProgramParameter; P.getProgramParameter = function(p, q) {
   const t = performance.now(); const r = gp.call(this, p, q); const d = performance.now() - t;
   if (d >= 40) console.log('Espía · shader ' + (d | 0) + ' ms a los ' + (t | 0) + ' ms ' + (nombres.get(p) || '?'));
   return r;
 };
 let antes = performance.now();
 function paso() {
   const a = performance.now(); const dt = a - antes; antes = a;
   if (dt > 40) {
     const top = Object.entries(cur).sort((x, y) => y[1][1] - x[1][1]).slice(0, 5).map(([k, v]) => k + ':' + v[0] + '/' + v[1].toFixed(0));
     console.log('Espía · fotograma de ' + (dt | 0) + ' ms a los ' + (a | 0) + ' ms: ' + top.join(' '));
   }
   cur = {}; requestAnimationFrame(paso);
 }
 requestAnimationFrame(paso);
 const c = document.createElement('canvas').getContext('webgl2'); const e = c && c.getExtension('WEBGL_debug_renderer_info');
 console.log('Espía · tarjeta: ' + (e ? c.getParameter(e.UNMASKED_RENDERER_WEBGL) : '?'));
})();</script>
"""


def main() -> None:
	segundos = int(sys.argv[1])
	argumentos = '"args":["--",' + ",".join('"%s"' % a for a in sys.argv[2:]) + "]"
	original = open(PAGINA, encoding="utf-8").read()
	pagina = re.sub(r'"args":\[.*?\]', argumentos, original, count=1).replace("</head>", ESPIA + "</head>", 1)
	open(PAGINA, "w", encoding="utf-8").write(pagina)
	edge = subprocess.Popen([EDGE, "--headless=new", "--use-angle=d3d11", "--ignore-gpu-blocklist", "--no-first-run",
		"--no-default-browser-check", "--mute-audio", "--autoplay-policy=no-user-gesture-required",
		"--disable-background-timer-throttling", "--disable-renderer-backgrounding", "--disable-backgrounding-occluded-windows",
		"--window-size=1024,768", "--enable-logging=stderr", "--user-data-dir=" + tempfile.mkdtemp(prefix="medir-web-"),
		"http://localhost:8060/"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, encoding="utf-8", errors="replace")

	def leer() -> None:
		for linea in edge.stdout:
			m = re.search(r'CONSOLE[:(]\d+\)?\] "(.*)", source', linea)
			if m and not m.group(1).startswith("[.WebGL") and "res://capturas" not in m.group(1) and "at: " not in m.group(1):
				print(m.group(1)[:420], flush=True)

	threading.Thread(target=leer, daemon=True).start()
	try:
		time.sleep(segundos)
	finally:
		subprocess.run(["taskkill", "/F", "/T", "/PID", str(edge.pid)], capture_output=True)
		open(PAGINA, "w", encoding="utf-8").write(original)


main()
