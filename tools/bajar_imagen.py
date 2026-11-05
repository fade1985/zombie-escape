"""Baja imágenes sueltas de PixelLab (create_image_pixflux...) por su job_id.
  py tools/bajar_imagen.py <carpeta> nombre=job_id [nombre=job_id ...]
Guarda <carpeta>/<nombre>.png (con curl: PixelLab rechaza las descargas de Python)."""
import os, subprocess, sys
carpeta = sys.argv[1]
os.makedirs(carpeta, exist_ok=True)
for par in sys.argv[2:]:
    nombre, job = par.split('=')
    ruta = f'{carpeta}/{nombre}.png'
    subprocess.run(['curl', '-sSf', '-o', ruta, f'https://api.pixellab.ai/mcp/images/{job}/download'], check=True)
    print(ruta)
