"""Original procedural card-game effects. Python 3 + NumPy, deterministic seed."""
from pathlib import Path
import wave
import numpy as np

SR = 48000
OUT = Path(__file__).parent
rng = np.random.default_rng(92)

def timeline(d): return np.arange(round(SR*d))/SR

def tone(t, freq, decay=5, start=0, gain=1):
    u=np.maximum(t-start,0)
    return np.sin(2*np.pi*freq*u)*np.exp(-decay*u)*np.minimum(u/.006,1)*(t>=start)*gain

def noise(t, decay=15, start=0, gain=1):
    u=np.maximum(t-start,0)
    n=rng.standard_normal(len(t))
    return n*np.exp(-decay*u)*np.minimum(u/.003,1)*(t>=start)*gain

def sweep(t, f0, f1, duration, start=0, gain=1):
    u=np.clip(t-start,0,duration)
    phase=2*np.pi*(f0*u+(f1-f0)*u*u/(2*duration))
    env=np.maximum(np.sin(np.pi*u/duration),0)**1.5
    return np.sin(phase)*env*(t>=start)*(t<start+duration)*gain

def filtered(n, width):
    return np.convolve(n, np.ones(width)/width, mode='same')

def finish(x):
    # A short, quiet room reflection; no DC or clipped sample peaks.
    x=x-x.mean()
    delay=round(.027*SR)
    reflected=np.zeros_like(x)
    reflected[delay:]=x[:-delay]*.1
    left=x+reflected
    right=x-reflected*.4
    y=np.stack([left,right],axis=1)
    edge=min(480,len(y)//5)
    y[:edge]*=np.linspace(0,1,edge)[:,None]
    y[-edge:]*=np.linspace(1,0,edge)[:,None]
    y*=.8/max(np.max(np.abs(y)),1e-8)
    return y

def save(name,x):
    y=finish(x)
    with wave.open(str(OUT/(name+'.wav')),'wb') as w:
        w.setparams((2,2,SR,0,'NONE','not compressed'))
        w.writeframes((y*32767).astype('<i2').tobytes())
    return y

sounds=[]
t=timeline(.32)
x=filtered(noise(t,18,gain=.9),7)+noise(t,90,start=.06,gain=.12)+sweep(t,1300,500,.16,gain=.11)
sounds.append(('card_draw',save('card_draw',x)))
t=timeline(.38)
x=filtered(noise(t,32,gain=.5),4)+tone(t,145,22,gain=.65)+tone(t,280,30,gain=.2)+noise(t,95,start=.035,gain=.12)
sounds.append(('card_play',save('card_play',x)))
t=timeline(.85)
x=sum(tone(t,f,6,start=i*.07,gain=.30/(1+i*.15)) for i,f in enumerate([660,880,1320,1760]))
x+=sweep(t,400,1800,.32,gain=.08)+filtered(noise(t,10,gain=.06),9)
sounds.append(('study',save('study',x)))
t=timeline(.48)
x=filtered(noise(t,10,gain=.3),5)*np.sin(np.pi*np.minimum(t/.25,1))**2
x+=sweep(t,380,95,.17,start=.18,gain=.6)+filtered(noise(t,35,start=.22,gain=.45),6)
sounds.append(('attack',save('attack',x)))
t=timeline(.55)
x=sweep(t,150,42,.25,gain=.55)+filtered(noise(t,20,gain=.5),10)
x+=tone(t,67,12,gain=.55)+tone(t,311,22,gain=.12)
sounds.append(('damage',save('damage',x)))
t=timeline(.65)
x=tone(t,587.33,9,gain=.4)+tone(t,880,9,start=.12,gain=.35)+tone(t,1174.66,10,start=.15,gain=.1)
sounds.append(('turn_end',save('turn_end',x)))
t=timeline(.18)
x=tone(t,900,55,gain=.28)+tone(t,1500,70,gain=.12)+noise(t,100,gain=.12)
sounds.append(('ui_confirm',save('ui_confirm',x)))
t=timeline(2.1)
x=np.zeros_like(t)
for i,(f,start) in enumerate([(523.25,0),(659.25,.14),(783.99,.28),(1046.5,.46)]):
    x+=tone(t,f,3.5,start=start,gain=.25)+tone(t,f*2,5,start=start,gain=.06)
for f in [523.25,659.25,783.99,1046.5]: x+=tone(t,f,3,start=.72,gain=.13)
x+=filtered(noise(t,8,start=.46,gain=.05),8)
sounds.append(('victory',save('victory',x)))
for name,y in sounds:
    assert np.isfinite(y).all() and np.max(np.abs(y))<1
    print(f'{name}: {len(y)/SR:.2f}s, peak {20*np.log10(np.max(np.abs(y))):.1f} dBFS')
