"""Generates the extra 3D sound effects (enemy bolts, the Curator boss).
Run from the project root:  python tools/make_sfx_3d.py
Only writes new files; it never touches the sounds made by make_assets.py."""
import os, wave
import numpy as np

SR = 22050
np.random.seed(7)


def write(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    pcm = (np.clip(data, -1, 1) * 32767).astype('<i2')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())


def t(sec): return np.linspace(0, sec, int(SR * sec), endpoint=False)


def env(n, a=0.01, r=0.2):
    e = np.ones(n); A = max(1, int(SR * a)); R = max(1, int(SR * r))
    e[:A] = np.linspace(0, 1, A); e[-R:] *= np.linspace(1, 0, R); return e


def sweep(f0, f1, sec, vol=0.4, square=False, r=None):
    x = t(sec); f = np.linspace(f0, f1, len(x)); ph = 2 * np.pi * np.cumsum(f) / SR
    s = np.sign(np.sin(ph)) if square else np.sin(ph)
    return s * env(len(x), 0.005, r if r else sec * 0.5) * vol


def noise(sec, vol=0.3, r=0.1):
    return np.random.uniform(-1, 1, int(SR * sec)) * env(int(SR * sec), 0.002, r) * vol


def tone(f, sec, vol=0.3, r=0.2):
    x = t(sec); return np.sin(2 * np.pi * f * x) * env(len(x), 0.005, r) * vol


d = 'assets/sounds/sfx/'
# A short rising zap: a bolt leaving a turret or the Curator.
write(d + 'bolt.wav', sweep(900, 300, 0.14, 0.35, True, 0.1))
# The Curator flipping worlds: a rising shimmer with a noisy tail.
write(d + 'boss_flip.wav', np.concatenate([sweep(150, 1800, 0.5, 0.35, False, 0.15), noise(0.15, 0.2, 0.15)]))
# Waking up: a low growl.
low = sweep(70, 45, 0.9, 0.5, True, 0.5) + 0.5 * sweep(105, 60, 0.9, 0.3, True, 0.5)
write(d + 'boss_wake.wav', low)
# A new phase: two hard hits then a falling sweep.
write(d + 'boss_phase.wav', np.concatenate([
    noise(0.08, 0.6, 0.06), sweep(220, 80, 0.12, 0.5, True), noise(0.08, 0.6, 0.06),
    sweep(900, 40, 0.5, 0.45, True, 0.3)]))
# Armour: a metallic clang.
write(d + 'clang.wav', (tone(520, 0.25, 0.3, 0.22) + tone(1330, 0.25, 0.2, 0.22) + tone(2210, 0.25, 0.12, 0.22)))
# Defeat: a falling arpeggio and a long noise wash.
arp = np.concatenate([tone(f, 0.14, 0.35, 0.1) for f in (1047, 784, 659, 523, 392, 262)])
write(d + 'boss_down.wav', np.concatenate([arp, noise(0.6, 0.35, 0.55)]))
print('3d sfx written')
