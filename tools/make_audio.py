"""Generates the placeholder sound effects and music for Chronicles of the Signal.
Run from the project root:  python tools/make_audio.py
Everything it writes is original and generated, so there is no licence issue.
Replace the outputs with real audio later using the same file names."""
import math, os, random, struct, wave
import numpy as np

# ---- audio ---------------------------------------------------------------
SR=22050
def write(path,data):
    os.makedirs(os.path.dirname(path),exist_ok=True)
    data=np.clip(data,-1,1); pcm=(data*32767).astype('<i2')
    with wave.open(path,'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
def t(sec): return np.linspace(0,sec,int(SR*sec),endpoint=False)
def env(n,a=0.01,r=0.2):
    e=np.ones(n); A=max(1,int(SR*a)); R=max(1,int(SR*r))
    e[:A]=np.linspace(0,1,A); e[-R:]*=np.linspace(1,0,R); return e
def sq(ph): return np.sign(np.sin(ph))
def tone(f,sec,wave_=np.sin,vol=0.4,r=0.2):
    x=t(sec); return wave_(2*np.pi*f*x)*env(len(x),0.005,r)*vol
def sweep(f0,f1,sec,vol=0.4,sqw=False):
    x=t(sec); f=np.linspace(f0,f1,len(x)); ph=2*np.pi*np.cumsum(f)/SR
    s=np.sign(np.sin(ph)) if sqw else np.sin(ph); return s*env(len(x),0.005,sec*0.5)*vol
def noise(sec,vol=0.3,r=0.1):
    return np.random.uniform(-1,1,int(SR*sec))*env(int(SR*sec),0.002,r)*vol

def sfx():
    d='assets/sounds/sfx/'
    write(d+'step.wav',noise(0.06,0.25,0.05)*np.sin(2*np.pi*140*t(0.06)))
    write(d+'swap.wav',np.concatenate([sweep(200,1400,0.18,0.35,True),noise(0.12,0.25,0.1)]))
    write(d+'hack_ok.wav',np.concatenate([tone(f,0.09,sq,0.3,0.05) for f in (523,659,784,1047)]))
    write(d+'hack_fail.wav',np.concatenate([tone(200,0.15,sq,0.35,0.05),tone(140,0.3,sq,0.35,0.25)]))
    write(d+'blip.wav',tone(660,0.03,sq,0.15,0.02))
    write(d+'click.wav',tone(900,0.04,np.sin,0.3,0.03))
    write(d+'hit.wav',np.concatenate([noise(0.1,0.5,0.08),sweep(300,60,0.25,0.5,True)]))
    write(d+'pickup.wav',np.concatenate([tone(880,0.06,np.sin,0.35,0.03),tone(1320,0.12,np.sin,0.35,0.1)]))
    write(d+'lever.wav',np.concatenate([tone(180,0.05,sq,0.4,0.03),tone(360,0.08,sq,0.3,0.06)]))
    write(d+'door.wav',sweep(120,60,0.4,0.4,True)+noise(0.4,0.15,0.3))
    write(d+'lost.wav',sweep(600,40,0.9,0.45,True))
    write(d+'timer.wav',tone(1000,0.05,np.sin,0.25,0.04))

def pad(freqs,sec,wave_=np.sin,vol=0.18):
    x=t(sec); out=np.zeros_like(x)
    for f in freqs: out+=wave_(2*np.pi*f*x)
    return out/len(freqs)*vol
def loop_fade(a,fade=0.05):
    n=int(SR*fade); a=a.copy(); a[:n]*=np.linspace(0,1,n); a[-n:]*=np.linspace(1,0,n); return a

def music():
    d='assets/sounds/music/'; sec=8.0; x=t(sec)
    def arp(notes,step,wave_,vol):
        out=np.zeros_like(x); n=int(SR*step)
        for i in range(int(sec/step)):
            f=notes[i%len(notes)]; seg=wave_(2*np.pi*f*t(step))*env(n,0.005,step*0.8)*vol
            out[i*n:i*n+n]+=seg[:len(out[i*n:i*n+n])]
        return out
    # Physical: slow minor pad + soft bass pulse
    phys=pad([110,130.8,164.8],sec,np.sin,0.25)+arp([55,55,65.4,55],0.5,np.sin,0.3)
    # Digital: brighter square arpeggio over a drone
    dig=pad([110,164.8,220],sec,np.sin,0.15)+arp([440,523,659,523,392,494,587,494],0.25,sq,0.07)
    # Title: slow arpeggio
    title=pad([98,146.8,196],sec,np.sin,0.2)+arp([392,494,587,784,587,494],0.5,np.sin,0.16)
    for n,a in (('physical',phys),('digital',dig),('title',title)):
        write(d+n+'.wav',loop_fade(a))

if __name__=='__main__':
    random.seed(1); np.random.seed(1)
    sfx(); music(); print('audio written')
