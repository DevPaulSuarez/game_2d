"""Recorta la hoja de cada personaje en un PNG por cuadro.

Hojas de entrada (una en la carpeta de cada personaje):
    lib/personajes/arquero/hoja.png
    lib/personajes/villano/hoja.png
    lib/personajes/princesa/hoja.png

Resultado (lo que carga el juego):
    lib/personajes/arquero/imagenes/quieto_derecha.png, caminar_1.png ...
    lib/personajes/villano/imagenes/quieto_frente.png, caminar_1.png ...
    lib/personajes/princesa/imagenes/quieto_frente.png, fantasma_verde_1.png ...

Solo necesitas este script si quieres volver a recortar desde las hojas
grandes. Para retocar un cuadro basta con editar su PNG directamente.

Uso (desde la carpeta mario_pixel):
    python3 -m venv .venv && .venv/bin/pip install pillow numpy scipy
    .venv/bin/python tools/build_sprites.py            # exporta los PNG
    .venv/bin/python tools/build_sprites.py --debug    # además tools/out/*_boxes.png

Con --debug se guarda una imagen de cada hoja con los cuadros detectados
numerados: esos números son los que se usan en las listas de más abajo.
"""
import os
import shutil
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

OUT = 'lib/personajes'
DEBUG = '--debug' in sys.argv


def bgmask(im):
    """Fondo azul oscuro de las hojas (conectado al borde o en huecos)."""
    r, g, b = [im[..., i].astype(int) for i in range(3)]
    cand = (np.maximum(np.maximum(r, g), b) < 50) & ((b - r) >= 5)
    lab, n = ndimage.label(cand)
    border = set(np.unique(np.concatenate(
        [lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    sizes = ndimage.sum(cand, lab, range(1, n + 1))
    # también huecos de fondo encerrados (p. ej. dentro del arco)
    inner = {i + 1 for i, sz in enumerate(sizes) if sz >= 25}
    return np.isin(lab, list(border | inner))


def boxes(fg, dilate=4, min_area=400):
    d = ndimage.binary_dilation(fg, iterations=dilate)
    lab, _ = ndimage.label(d, structure=np.ones((3, 3)))
    out = []
    for i, sl in enumerate(ndimage.find_objects(lab)):
        ys, xs = sl
        area = (fg[sl] & (lab[sl] == i + 1)).sum()
        if area < min_area:
            continue
        out.append([xs.start, ys.start, xs.stop, ys.stop, int(area)])
    out.sort(key=lambda b: (b[1] // 60, b[0]))
    return out


def process(name):
    """Quita el fondo de lib/personajes/<name>/hoja.png y detecta los cuadros."""
    hoja = f'{OUT}/{name}/hoja.png'
    im = np.array(Image.open(hoja).convert('RGBA'))
    bg = bgmask(im)
    bx = boxes(~bg)
    clean = im.copy()
    clean[bg, 3] = 0
    if DEBUG:
        os.makedirs('tools/out', exist_ok=True)
        vis = Image.open(hoja).convert('RGB')
        dr = ImageDraw.Draw(vis)
        for i, (x0, y0, x1, y1, _) in enumerate(bx):
            dr.rectangle([x0, y0, x1, y1], outline=(0, 255, 0))
            dr.text((x0 + 2, y0 + 2), str(i), fill=(255, 255, 0))
        vis.save(f'tools/out/{name}_boxes.png')
    return clean, [b[:4] for b in bx]


def cut(im, rect, keep_frac=0.06):
    """Recorta un rectángulo, quita restos sueltos y ajusta al contenido."""
    x0, y0, x1, y1 = rect
    c = im[y0:y1, x0:x1].copy()
    a = c[..., 3] > 0
    d = ndimage.binary_dilation(a, iterations=2)
    lab, n = ndimage.label(d, structure=np.ones((3, 3)))
    if n > 1:
        areas = ndimage.sum(a, lab, range(1, n + 1))
        keep = [i + 1 for i, ar in enumerate(areas) if ar >= areas.max() * keep_frac]
        c[~np.isin(lab, keep), 3] = 0
    ys, xs = np.nonzero(c[..., 3])
    return c[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def scaled(arr, factor):
    """Reescala un cuadro (para igualar filas dibujadas a otro tamaño)."""
    img = Image.fromarray(arr)
    w, h = img.size
    return np.array(img.resize((round(w * factor), round(h * factor)),
                               Image.LANCZOS))


def export(folder, frames):
    path = f'{OUT}/{folder}/imagenes'
    shutil.rmtree(path, ignore_errors=True)
    os.makedirs(path)
    for name, arr in frames:
        Image.fromarray(arr).save(f'{path}/{name}.png', optimize=True)
    print(f'{path}: {len(frames)} archivos')


def seq(name, im, rects):
    """caminar_1, caminar_2, ... a partir de una lista de rectángulos."""
    return [(f'{name}_{k + 1}', cut(im, r)) for k, r in enumerate(rects)]


def ciclo_piernas(base, cadera, corte, pivotes, n, amplitud, levantar,
                  inclinar=0.0):
    """Crea un ciclo de pasos animando las piernas de un solo dibujo.

    La hoja no trae un ciclo de caminar de verdad (en todos los cuadros los
    dos pies están en el suelo), así que se hace como animación de
    recortables: se separa el cuerpo (arriba de [cadera]) y las dos piernas
    (a cada lado de la columna [corte]); cada pierna gira sobre su cadera
    ([pivotes]) hacia delante y hacia atrás, y la que avanza se levanta
    [levantar] px para que el pie no arrastre. [inclinar] echa el cuerpo
    hacia delante (para correr).
    """
    import math
    h, w = base.shape[:2]
    pad = 40
    lienzo = np.zeros((h + pad * 2, w + pad * 2, 4), np.uint8)
    lienzo[pad:pad + h, pad:pad + w] = base
    img = Image.fromarray(lienzo)
    cuerpo = lienzo.copy()
    cuerpo[pad + cadera + 4:] = 0          # un poco de solape con las piernas
    piernas = []
    for lado in (0, 1):
        pierna = lienzo.copy()
        pierna[:pad + cadera] = 0
        if lado == 0:
            pierna[:, pad + corte:] = 0
        else:
            pierna[:, :pad + corte] = 0
        piernas.append(Image.fromarray(pierna))
    cuerpo = Image.fromarray(cuerpo)
    if inclinar:
        cuerpo = cuerpo.rotate(-inclinar, resample=Image.BICUBIC,
                               center=(pad + corte, pad + cadera))
    cuadros = []
    for k in range(n):
        fase = 2 * math.pi * k / n
        c = Image.new('RGBA', img.size)
        # Primero la pierna que va detrás (se ve un poco más oscura).
        orden = sorted((0, 1), key=lambda i: math.sin(fase + i * math.pi))
        for i in orden:
            f = fase + i * math.pi
            ang = amplitud * math.sin(f)
            subir = levantar * max(0.0, math.cos(f))
            px, py = pivotes[i]
            pie = piernas[i].rotate(ang, resample=Image.BICUBIC,
                                    center=(pad + px, pad + py),
                                    translate=(0, -subir))
            if i == orden[0]:
                a = np.array(pie).astype(float)
                a[..., :3] *= 0.82
                pie = Image.fromarray(a.astype(np.uint8))
            c.alpha_composite(pie)
        c.alpha_composite(cuerpo)
        a = np.array(c)
        a[..., 3] = np.where(a[..., 3] > 100, 255, 0)
        ys, xs = np.nonzero(a[..., 3])
        cuadros.append(a[ys.min():ys.max() + 1, xs.min():xs.max() + 1])
    return cuadros


# --- Arquero ----------------------------------------------------------------
# En la hoja, la fila IDLE está dibujada más grande que el resto (207 px de
# alto frente a 137 de CAMINAR): se reduce para que todo tenga la misma escala.
A, ab = process('arquero')
IDLE_A = 137 / 207
quieto_der = scaled(cut(A, ab[10]), IDLE_A)
arquero = [
    ('quieto_frente', scaled(cut(A, ab[1]), IDLE_A)),
    ('quieto_derecha', quieto_der),
    # La pose "IZQUIERDA" de la hoja en realidad mira a la derecha:
    # se usa la de la derecha volteada.
    ('quieto_izquierda', quieto_der[:, ::-1].copy()),
]
# Caminar y correr: se generan con ciclo_piernas() a partir del cuadro 1
# de CAMINAR (pies juntos), porque la hoja no trae pasos de verdad.
# Cadera en y=100; las piernas se separan por la columna 43.
paso = cut(A, ab[28])
PIERNAS = dict(cadera=100, corte=43, pivotes=[(30, 102), (56, 102)])
arquero += [(f'caminar_{k + 1}', f) for k, f in enumerate(
    ciclo_piernas(paso, n=8, amplitud=24, levantar=9, **PIERNAS))]
arquero += [(f'correr_{k + 1}', f) for k, f in enumerate(
    ciclo_piernas(paso, n=8, amplitud=38, levantar=16, inclinar=8,
                  **PIERNAS))]
arquero += seq('disparar', A, [ab[i] for i in [47, 48, 49, 50]])
# Salto: impulso (agachado), subida, en el aire, aterrizaje.
# El cuadro "en el aire" de la hoja (ab[54]) está dibujado con una sola
# pierna: se usa otra vez el de subida, que tiene las dos.
arquero += seq('saltar', A, [ab[i] for i in [57, 53, 53, 58]])
# Ataque cuerpo a cuerpo: el detector junta los cuadros 2 y 3 en ab[44];
# se separan a mano por la columna x=274.
x0, y0, x1, y1 = ab[44]
arquero += seq('atacar', A, [ab[43], (x0, y0, 274, y1), (274, y0, x1, y1),
                             ab[45], ab[46]])
arquero += seq('dano', A, [ab[i] for i in [59, 60, 61, 62]])
arquero += seq('muerte', A, [ab[i] for i in [64, 65, 66, 67]])
arquero += [('flecha', cut(A, ab[51]))]
arquero += [('retrato', cut(A, (95, 30, 295, 230)))]
export('arquero', arquero)

# --- Villano ----------------------------------------------------------------
M, mb = process('villano')
IDLE_M = 110 / 170
villano = [
    ('quieto_frente', scaled(cut(M, (369, 76, 496, 250)), IDLE_M)),
    ('quieto_derecha', scaled(cut(M, (539, 76, 689, 250)), IDLE_M)),
    ('quieto_izquierda', scaled(cut(M, (924, 74, 1059, 250)), IDLE_M)),
]
villano += seq('caminar', M, [mb[i] for i in [9, 10, 11, 12, 13, 14]])
villano += [('poder', cut(M, mb[24]))]
# ATAQUE (ROBA EL CORAZÓN): los 5 cuadros. El rayo del 3.º se corta en
# x=360 y el 5.º se corta antes del chico (el rayo lo dibuja el juego).
villano += seq('ataque', M, [(25, 528, 144, 647), (144, 527, 250, 647),
                             (250, 527, 360, 647), (365, 527, 460, 647),
                             (467, 527, 575, 655)])
# LANZAR MAGIA: 5 cuadros y la bola de magia suelta.
villano += seq('lanzar_magia', M, [(39, 700, 170, 822), (172, 707, 290, 828),
                                   (290, 707, 420, 828), (425, 707, 525, 828),
                                   (600, 707, 700, 828)])
villano += [('bola_magia', cut(M, (525, 735, 600, 795)))]
villano += [('con_corazon', cut(M, mb[29]))]
villano += seq('saltar', M, [mb[i] for i in [39, 37, 38]])
villano += seq('demonio', M, [(890, 880, 990, 1009), (990, 880, 1112, 1009),
                              (1112, 879, 1268, 1009), (1268, 828, 1519, 1009)])
villano += [('retrato', cut(M, (50, 12, 250, 212)))]
villano += [('retrato_demonio', cut(M, (1345, 845, 1455, 955)))]
export('villano', villano)

# --- Princesa ---------------------------------------------------------------
# En esta hoja varios cuadros salen pegados (espadas que se cruzan, textos),
# así que los rectángulos van a mano (x0, y0, x1, y1).
# Igual que en el arquero, la fila IDLE y los fantasmas están dibujados a
# otro tamaño que CAMINAR: se ajustan a la misma altura.
P, _ = process('princesa')
# Altura de juego = la de CAMINAR (cuadro 1).
ALTO_P = cut(P, (30, 362, 122, 500)).shape[0]


def quietos(prefijo, rects):
    """frente, derecha, espalda e izquierda, reducidos a la altura ALTO_P.

    La pose "IZQUIERDA" de la hoja también mira a la derecha: se usa la
    de la derecha volteada.
    """
    cuadros = [cut(P, r) for r in rects]
    factor = ALTO_P / cuadros[0].shape[0]
    frente, derecha, espalda, _ = [scaled(c, factor) for c in cuadros]
    return [(f'{prefijo}_frente', frente), (f'{prefijo}_derecha', derecha),
            (f'{prefijo}_espalda', espalda),
            (f'{prefijo}_izquierda', derecha[:, ::-1].copy())]


princesa = quietos('quieto', [(296, 98, 438, 274), (460, 101, 560, 274),
                              (588, 98, 714, 274), (744, 96, 848, 274)])
princesa += seq('caminar', P, [(30, 362, 122, 500), (122, 362, 215, 500),
                               (215, 362, 312, 500), (312, 362, 410, 500),
                               (410, 362, 516, 500)])
princesa += seq('atacar', P, [(16, 545, 125, 676), (130, 545, 225, 676),
                              (225, 545, 318, 676), (318, 545, 410, 676),
                              (410, 545, 516, 676)])
princesa += seq('saltar', P, [(28, 750, 107, 848), (136, 720, 216, 838),
                              (232, 688, 318, 814), (332, 744, 424, 846)])
princesa += seq('muerte', P, [(30, 894, 134, 990), (134, 880, 226, 992),
                              (244, 910, 329, 993), (348, 920, 453, 992)])
# Modos fantasmales: verde, azul y blanco, en las cuatro direcciones.
princesa += quietos('fantasma_verde', [(660, 390, 742, 520), (746, 390, 820, 520),
                                       (834, 388, 908, 518), (920, 390, 994, 520)])
princesa += quietos('fantasma_azul', [(656, 553, 738, 686), (745, 553, 820, 686),
                                      (831, 551, 916, 685), (920, 553, 994, 685)])
princesa += quietos('fantasma_blanco', [(656, 720, 740, 851), (745, 720, 830, 851),
                                        (833, 716, 912, 848), (920, 718, 997, 851)])
princesa += [('retrato', cut(P, (55, 16, 225, 186)))]
export('princesa', princesa)
