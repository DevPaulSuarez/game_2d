"""Crea los efectos de sonido y la música del juego (estilo 8 bits).

Todo se genera con ondas sencillas (cuadrada, triangular y ruido), como en
las consolas antiguas. No hace falta descargar nada.

Resultado:
    lib/sonido/efectos/*.wav   (efectos cortos: salto, flecha, cristal...)
    lib/sonido/musica/*.m4a    (música en bucle de cada pantalla)

Uso (desde la carpeta mario_pixel):
    .venv/bin/python tools/crear_sonidos.py

Para cambiar una melodía, edita las listas de notas de más abajo: cada
compás tiene 8 corcheas; '-' alarga la nota anterior y '.' es silencio.
"""
import os
import subprocess
import wave

import numpy as np

SR = 22050          # muestras por segundo
EFECTOS = 'lib/sonido/efectos'
MUSICA = 'lib/sonido/musica'

NOTAS = {'C': 0, 'C#': 1, 'D': 2, 'D#': 3, 'E': 4, 'F': 5, 'F#': 6,
         'G': 7, 'G#': 8, 'A': 9, 'A#': 10, 'B': 11}


def hz(nota):
    """'A4' -> 440.0"""
    nombre, octava = nota[:-1], int(nota[-1])
    n = NOTAS[nombre] + (octava + 1) * 12
    return 440.0 * 2 ** ((n - 69) / 12)


# ---- Ondas -------------------------------------------------------------------

def _fase(frec, dur):
    """frec puede ser un número o un array (para deslizar el tono)."""
    n = int(SR * dur)
    f = np.full(n, frec, float) if np.isscalar(frec) else np.asarray(frec)
    return np.cumsum(f) / SR


def cuadrada(frec, dur, ciclo=0.5):
    return np.where(_fase(frec, dur) % 1 < ciclo, 1.0, -1.0)


def triangular(frec, dur):
    p = _fase(frec, dur) % 1
    return 4 * np.abs(p - 0.5) - 1


def seno(frec, dur):
    return np.sin(2 * np.pi * _fase(frec, dur))


def ruido(dur, suave=1):
    r = np.random.default_rng(7).uniform(-1, 1, int(SR * dur))
    if suave > 1:
        r = np.convolve(r, np.ones(suave) / suave, 'same')
    return r


def desliza(a, b, dur, curva=1.0):
    """Tono que va de a Hz a b Hz."""
    t = np.linspace(0, 1, int(SR * dur)) ** curva
    return a + (b - a) * t


def envolvente(n, ataque=0.005):
    """Volumen: sube en [ataque] segundos y se va apagando hasta el final."""
    t = np.arange(n) / SR
    dur = max(n / SR, 1e-9)
    return np.minimum(1, t / ataque) * np.clip(1 - t / dur, 0, 1) ** 1.5


def env(x, **kw):
    return x * envolvente(len(x), **kw)


def junta(*partes):
    return np.concatenate(partes)


def mezcla(*partes):
    n = max(len(p) for p in partes)
    out = np.zeros(n)
    for p in partes:
        out[:len(p)] += p
    return out


def guardar_wav(ruta, x, volumen=0.8):
    x = x / max(1e-9, np.max(np.abs(x))) * volumen
    datos = (x * 32767).astype(np.int16)
    with wave.open(ruta, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(datos.tobytes())


def arpegio(notas, paso, onda=triangular, ciclo=None):
    trozos = []
    for n in notas:
        s = onda(hz(n), paso) if ciclo is None else onda(hz(n), paso, ciclo)
        trozos.append(env(s))
    return junta(*trozos)


# ---- Efectos -----------------------------------------------------------------

def efectos():
    os.makedirs(EFECTOS, exist_ok=True)
    e = {}
    e['salto'] = env(cuadrada(desliza(280, 720, 0.16, 0.6), 0.16, 0.25))
    e['flecha'] = mezcla(env(ruido(0.2, 3)) * 0.6,
                         env(cuadrada(desliza(1400, 380, 0.16), 0.16, 0.125)) * 0.3)
    e['espada'] = mezcla(env(ruido(0.14, 2)) * 0.8,
                         env(triangular(desliza(1100, 260, 0.18), 0.18)) * 0.7)
    e['golpe'] = mezcla(env(cuadrada(desliza(200, 80, 0.1), 0.1, 0.5)),
                        env(ruido(0.05, 4)) * 0.5)
    e['enemigo_muere'] = junta(env(cuadrada(desliza(700, 120, 0.22), 0.22, 0.25)),
                               env(ruido(0.08, 6)) * 0.6)
    e['pisoton'] = junta(env(cuadrada(desliza(180, 520, 0.06), 0.06, 0.5)),
                         env(cuadrada(desliza(520, 260, 0.1), 0.1, 0.5)))
    e['cristal'] = junta(env(cuadrada(hz('E6'), 0.06, 0.125)),
                         env(cuadrada(hz('B6'), 0.2, 0.125)))
    crujido = env(cuadrada(90 + 15 * seno(9, 0.18), 0.18, 0.3)) * 0.5
    e['cofre'] = junta(crujido, arpegio(['C6', 'E6', 'G6', 'C7'], 0.06,
                                        cuadrada, 0.25))
    e['curar'] = arpegio(['C5', 'E5', 'G5', 'C6', 'E6', 'G6'], 0.07)
    brillo = [env(triangular(f, 0.07)) for f in (1760, 2350, 1980, 2640, 2090, 3140)]
    e['hada'] = mezcla(junta(*brillo), env(seno(2640, 0.42)) * 0.2)
    e['dano'] = mezcla(env(cuadrada(desliza(520, 110, 0.32) +
                                    40 * seno(30, 0.32), 0.32, 0.5)),
                       env(ruido(0.12, 3)) * 0.4)
    e['magia'] = env(cuadrada(520 + 220 * seno(18, 0.35), 0.35, 0.5))
    muerte = arpegio(['G4', 'F#4', 'F4', 'E4', 'D#4', 'D4'], 0.12, cuadrada, 0.5)
    e['muerte'] = junta(muerte, env(triangular(hz('C3'), 0.5)))
    fanfarria = arpegio(['C5', 'E5', 'G5', 'C6'], 0.1, cuadrada, 0.25)
    final = mezcla(env(cuadrada(hz('G5'), 0.6, 0.25)),
                   env(cuadrada(hz('C6'), 0.6, 0.25)) * 0.7,
                   env(triangular(hz('C4'), 0.6)))
    e['victoria'] = junta(fanfarria, final)
    e['inicio'] = junta(env(cuadrada(hz('A5'), 0.06, 0.25)),
                        env(cuadrada(hz('E6'), 0.14, 0.25)))
    for nombre, x in e.items():
        guardar_wav(f'{EFECTOS}/{nombre}.wav', x)
    print(f'{EFECTOS}: {len(e)} efectos')


# ---- Música ------------------------------------------------------------------

def pista(melodia, acordes, bpm, arpegiar=False, bateria=True, lead_ciclo=0.25):
    """melodia: lista de compases (8 corcheas cada uno).
    acordes: un acorde por compás, p. ej. 'C', 'Am', 'G', 'E'."""
    corchea = 60 / bpm / 2
    n_total = int(SR * corchea * 8 * len(melodia))
    out = np.zeros(n_total + SR)

    def pon(x, i):
        a = int(SR * corchea * i)
        out[a:a + len(x)] += x

    # Melodía
    fichas = [f for compas in melodia for f in compas.split()]
    i = 0
    while i < len(fichas):
        f = fichas[i]
        largo = 1
        while i + largo < len(fichas) and fichas[i + largo] == '-':
            largo += 1
        if f not in '-.':
            dur = corchea * largo * 0.95
            x = cuadrada(hz(f) * (1 + 0.004 * seno(6, dur)), dur, lead_ciclo)
            pon(env(x, ataque=0.01) * 0.30, i)
        i += largo

    # Bajo y arpegios
    tonos = {'C': ['C', 'E', 'G'], 'Am': ['A', 'C', 'E'], 'F': ['F', 'A', 'C'],
             'G': ['G', 'B', 'D'], 'Em': ['E', 'G', 'B'], 'E': ['E', 'G#', 'B'],
             'Dm': ['D', 'F', 'A']}
    for c, acorde in enumerate(acordes):
        raiz, tercera, quinta = tonos[acorde]
        base = c * 8
        for k, nota in enumerate([raiz + '2', raiz + '3', quinta + '2', raiz + '3'] * 2):
            pon(env(triangular(hz(nota), corchea * 0.9)) * 0.45, base + k)
        if arpegiar:
            semis = [raiz + '4', tercera + '4', quinta + '4', raiz + '5']
            for k in range(16):
                n = semis[(k if (k // 4) % 2 == 0 else 3 - k % 4) % 4]
                x = env(triangular(hz(n), corchea / 2 * 0.9)) * 0.14
                pon(x, base + k / 2)

    # Batería suave
    if bateria:
        for b in range(len(melodia) * 4):
            pon(env(seno(desliza(150, 50, 0.1), 0.1)) * 0.5, b * 2)
            if b % 2 == 1:
                pon(env(ruido(0.08, 2)) * 0.18, b * 2)
            pon(env(ruido(0.02)) * 0.05, b * 2 + 1)

    return out[:n_total]


def guardar_musica(nombre, x):
    os.makedirs(MUSICA, exist_ok=True)
    wav = f'{MUSICA}/{nombre}.wav'
    guardar_wav(wav, x, volumen=0.7)
    m4a = f'{MUSICA}/{nombre}.m4a'
    # afconvert viene con macOS; el AAC ocupa ~10 veces menos que el WAV.
    subprocess.run(['afconvert', '-f', 'm4af', '-d', 'aac', '-b', '48000',
                    wav, m4a], check=True)
    os.remove(wav)


def musica():
    titulo = pista(
        ['G5 - E5 - C5 - E5 -', 'D5 - G5 - B5 - - -',
         'C6 - B5 - A5 - E5 -', 'F5 - A5 - C6 - - -',
         'E6 - D6 - C6 - G5 -', 'B5 - A5 - G5 - D5 -',
         'C6 - A5 - F5 - A5 -', 'G5 - - - - - . .'],
        ['C', 'G', 'Am', 'F', 'C', 'G', 'F', 'G'],
        bpm=90, arpegiar=True, bateria=False, lead_ciclo=0.5)
    bosque = pista(
        ['E5 - G5 - C6 - B5 A5', 'A5 - E5 - C5 - E5 G5',
         'F5 - A5 - C6 - A5 F5', 'G5 - - - D5 - . .',
         'E5 - G5 - C6 - D6 E6', 'D6 - C6 - A5 - G5 A5',
         'F5 - E5 - D5 - C5 D5', 'G5 - - - - - . .',
         'A5 - C6 - F6 - E6 D6', 'D6 - B5 - G5 - A5 B5',
         'G5 - B5 - E6 - D6 C6', 'C6 - A5 - E5 - G5 A5',
         'F5 - A5 - C6 - A5 C6', 'D6 - C6 - B5 - A5 B5',
         'C6 - G5 - E5 - G5 -', 'C6 - - - - - . .'],
        ['C', 'Am', 'F', 'G', 'C', 'Am', 'F', 'G',
         'F', 'G', 'Em', 'Am', 'F', 'G', 'C', 'C'],
        bpm=132)
    hadas = pista(
        ['E5 - - - C5 - - -', 'A5 - - - G5 - F5 -',
         'E5 - - - G5 - - -', 'D5 - - - - - . .',
         'E5 - A5 - B5 - C6 -', 'B5 - A5 - F5 - A5 -',
         'G#5 - - - B5 - - -', 'E5 - - - - - . .'],
        ['Am', 'F', 'C', 'G', 'Am', 'F', 'E', 'E'],
        bpm=100, arpegiar=True, bateria=False, lead_ciclo=0.5)
    for nombre, x in (('titulo', titulo), ('bosque', bosque), ('hadas', hadas)):
        guardar_musica(nombre, x)
    print(f'{MUSICA}: 3 pistas')


if __name__ == '__main__':
    efectos()
    musica()
