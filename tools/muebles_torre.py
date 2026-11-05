"""Pone los muebles propios de los seis departamentos de Torre Velaria en scripts/mapa/catalogo.gd (SALAS).

Cada departamento usa el plano de una tienda del centro (Tienda.TIPOS, "presta"), así que sus muebles se colocan en
los mismos sitios que los de esa tienda, pero con los de oficina (cubículos, escritorios, racks, archivadores...). Este
script copia los "colocados" de la tienda y cambia el tipo de cada mueble; el resultado se pega en catalogo.gd, donde
ya se puede retocar a mano (el script solo sirve la primera vez: si el bloque ya está, no hace nada).

  py tools/muebles_torre.py
"""
import re, sys

RUTA = 'scripts/mapa/catalogo.gd'
FIN = '\t# la tienda destrozada del jefe de la planta'

# paredes de cada mueble nuevo (para no poner de lado lo que no tiene dibujo de lado)
LADOS = {'cubicle', 'officedesk', 'lobbysofa', 'execdesk', 'interviewtable', 'checkout', 'workbench', 'bench', 'clothesrack'}
TODAS = {'watercooler', 'plant', 'pallet', 'mannequin'}


def alterna(tipo):
    """Uno sí y uno no (para filas de muebles estrechas que se cambian por otros más anchos)"""
    return ('alterna', tipo)


def ciclo(*tipos):
    """Cada vez que sale el mueble, el siguiente de la lista"""
    return ('ciclo', tipos)


# (sala de la tienda de la que se copia) -> (sala nueva, {tipo viejo: tipo nuevo | ciclo | None para quitarlo})
# El tipo nuevo se cambia por uno que sí valga si cae en una pared lateral o de abajo y no tiene dibujo allí
ATENCION = {'drinkfridge': ciclo('printer', 'watercooler', 'copier'), 'gondola': 'cubicle', 'checkout': 'officedesk',
            'pallet': 'filecabinet', 'metalshelf': 'filecabinet'}
IMPRESORAS = {'freezershelf': ciclo('copier', 'printer', 'copier'), 'pallet': 'plant'}
OFFICE = {'metalshelf': ciclo('officekitchen', 'filecabinet'), 'lockers': 'drinkfridge', 'pallet': 'watercooler'}
INFORMATICA = {'tvshelf': 'serverrack', 'metalshelf': 'filecabinet', 'checkout': 'officedesk', 'pallet': 'watercooler'}
SERVIDORES = {'lockers': 'serverrack', 'bench': 'watercooler'}
RRHH = {'mannequin': ciclo('plant', 'watercooler', 'plant'), 'clothesrack': 'cubicle', 'bench': 'lobbysofa', 'checkout': 'officedesk'}
ARCHIVO = {'metalshelf': 'filecabinet', 'clothesrack': 'bookcase', 'pallet': 'filecabinet'}
ENTREVISTAS = {'bench': 'interviewtable', 'mannequin': 'watercooler', 'clothesrack': 'lobbysofa'}
MARKETING = {'metalshelf': alterna('cubicle'), 'workbench': 'officedesk', 'checkout': 'officedesk', 'pallet': 'plant'}
ESTUDIO = {'workbench': ciclo('mixerdesk', 'officedesk'), 'metalshelf': 'lobbysofa', 'pallet': 'plant'}
SEGURIDAD = {'drinkfridge': 'filecabinet', 'checkout': 'officedesk', 'bench': 'lobbysofa', 'diningtable': 'officedesk'}
CAMARAS = {'industrialstove': ciclo('monitorwall', 'officedesk'), 'fryer': 'serverrack', 'steeltable': 'officedesk'}
ARMERO = {'freezershelf': 'armory'}
DIRECCION = {'mannequin': 'plant', 'clothesrack': 'execdesk', 'bench': 'lobbysofa', 'checkout': 'execdesk'}
DESPACHO = {'metalshelf': 'bookcase', 'clothesrack': 'execdesk', 'pallet': 'filecabinet'}
JUNTAS = {'bench': 'bookcase', 'mannequin': 'boardtable', 'clothesrack': 'watercooler'}

SALAS = [
    ('tienda-atencion', 'tienda-supermercado', ATENCION), ('impresoras-atencion', 'camara-supermercado', IMPRESORAS),
    ('office-atencion', 'almacen-supermercado', OFFICE), ('bano-atencion', 'bano-supermercado', {}),
    ('tienda-informatica', 'tienda-electronica', INFORMATICA), ('servidores-informatica', 'taquillas-electronica', SERVIDORES),
    ('almacen-informatica', 'almacen-electronica', {}), ('bano-informatica', 'bano-electronica', {}),
    ('tienda-rrhh', 'tienda-ropa', RRHH), ('archivo-rrhh', 'almacen-ropa', ARCHIVO),
    ('entrevistas-rrhh', 'probadores-ropa', ENTREVISTAS), ('bano-rrhh', 'bano-ropa', {}),
    ('tienda-marketing', 'tienda-ferreteria', MARKETING), ('estudio-marketing', 'taller-ferreteria', ESTUDIO),
    ('almacen-marketing', 'almacen-ferreteria', {}), ('bano-marketing', 'bano-ferreteria', {}),
    ('tienda-seguridad', 'tienda-restaurante', SEGURIDAD), ('camaras-seguridad', 'cocina-restaurante', CAMARAS),
    ('armero-seguridad', 'camara-restaurante', ARMERO), ('bano-seguridad', 'bano-restaurante', {}),
    ('tienda-direccion', 'tienda-ropa', DIRECCION), ('despacho-direccion', 'almacen-ropa', DESPACHO),
    ('juntas-direccion', 'probadores-ropa', JUNTAS), ('bano-direccion', 'bano-ropa', {}),
]

NOTAS = {
    'tienda-atencion': 'Atención al cliente (plano del supermercado): impresoras, fotocopiadoras y fuentes de agua al fondo, filas de cubículos',
    'tienda-informatica': 'Informática (plano de la electrónica): racks de servidores en la pared y filas de escritorios',
    'tienda-rrhh': 'Recursos Humanos (plano de la tienda de ropa): cubículos, sofás de espera y plantas',
    'tienda-marketing': 'Marketing (plano de la ferretería): cubículos creativos en filas y escritorios',
    'tienda-seguridad': 'Seguridad corporativa (plano del restaurante): filas de escritorios, archivadores y sofás',
    'tienda-direccion': 'Dirección (plano de la tienda de ropa): mesas de dirección, sofás y plantas',
}


def bloque(texto, clave):
    """El texto de la entrada de SALAS con esa clave (desde su línea hasta la llave que la cierra)"""
    ini = texto.index('\t"%s": {' % clave)
    nivel, i = 0, texto.index('{', ini)
    while True:
        nivel += {'{': 1, '}': -1}.get(texto[i], 0)
        if nivel == 0:
            break
        i += 1
    return texto[ini:i + 1] + ','


def cambiar(txt, mapa):
    cuenta = {}
    txt = re.sub(r'\["([a-z]+)", ([0-9.]+)(?:, "(izquierda|derecha|abajo|libre)")?', lambda m: _sub(m, mapa, cuenta), txt)
    return re.sub(r'\["__quitar"[^\]]*\],? ?', '', txt)   # los que se quitan (ver alterna)


def _sub(m, mapa, cuenta):
    tipo, centro, pared = m.group(1), m.group(2), m.group(3) or 'arriba'
    nuevo = mapa.get(tipo, tipo)
    if isinstance(nuevo, tuple):
        k = cuenta.get(tipo, 0)
        cuenta[tipo] = k + 1
        nuevo = nuevo[1][k % len(nuevo[1])] if nuevo[0] == 'ciclo' else (nuevo[1] if k % 2 == 0 else '__quitar')
    if mapa and nuevo != '__quitar':
        if pared in ('izquierda', 'derecha') and nuevo not in LADOS | TODAS:
            nuevo = 'watercooler'
        if pared == 'abajo' and nuevo not in TODAS:
            nuevo = 'plant'
    return m.group(0).replace('["%s"' % tipo, '["%s"' % nuevo, 1)


def main():
    texto = open(RUTA, encoding='utf-8').read()
    if '"tienda-atencion"' in texto:
        print('ya están')
        return
    salida = []
    for nueva, vieja, mapa in SALAS:
        b = bloque(texto, vieja)
        b = b.replace('"%s": {' % vieja, '"%s": {' % nueva, 1)
        b = '\n'.join(l for l in b.split('\n') if not l.strip().startswith('#'))   # sin los comentarios de la tienda
        b = cambiar(b, mapa)
        if nueva in NOTAS:
            salida.append('\t# ' + NOTAS[nueva] + '; el resto, como esa tienda (mismas casillas)')
        salida.append(b)
    marca = texto.index(FIN)
    nuevo = ('\t# Los departamentos de Torre Velaria (parte 2 del tercer edificio): los muebles de oficina, en las casillas del\n'
             '\t# plano que les presta una tienda del centro (Tienda.TIPOS, "presta"). "<uso>-<tipo>", como las tiendas\n'
             + '\n'.join(salida) + '\n')
    open(RUTA, 'w', encoding='utf-8').write(texto[:marca] + nuevo + texto[marca:])
    print('hecho')


main()
