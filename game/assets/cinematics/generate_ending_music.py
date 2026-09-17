"""Original 30-second ending cue; NumPy is only needed for regeneration."""
from pathlib import Path
import wave
import numpy as np
RATE=22050
DURATION=30
mix=np.zeros(RATE*DURATION,dtype=np.float64)
def note(at,duration,midi,volume,soft=False):
    n=int(duration*RATE); t=np.arange(n)/RATE
    f=440*2**((midi-69)/12)
    tone=np.sin(2*np.pi*f*t)+.23*np.sin(2*np.pi*f*2*t)+.09*np.sin(2*np.pi*f*3*t)
    envelope=(1-np.exp(-t/(.28 if soft else .012)))*np.exp(-t/(duration*.55))
    envelope*=np.minimum((duration-t)/.15,1).clip(0,1)
    start=int(at*RATE); end=min(len(mix),start+n)
    mix[start:end]+=volume*tone[:end-start]*envelope[:end-start]
chords=[[50,57,60,65],[53,60,65,69],[48,55,60,64],[55,59,62,67],[53,60,65,69],[48,55,60,64]]
melodies=[[69,72,74,72,69],[72,76,79,76,74],[76,79,84,79,76],[74,77,79,83,79],[81,79,76,74,72],[76,79,84,88,84]]
for bar,(chord,melody) in enumerate(zip(chords,melodies)):
    for pitch in chord: note(bar*5,5,pitch,.058,True)
    for i,pitch in enumerate(melody): note(bar*5+.55+i*.8,1.7,pitch,.075)
    if bar>0:
        for i in range(10): note(bar*5+i*.45,1.1,chord[i%4]+12,.024)
fade=np.minimum(np.arange(len(mix))/RATE/1.0,1)*np.minimum((DURATION-np.arange(len(mix))/RATE)/1.8,1)
mix=np.tanh(mix*1.5)*fade
stereo=np.column_stack([mix,np.roll(mix,103)*.93])
path=Path(__file__).with_name('ending_music.wav')
with wave.open(str(path),'wb') as out:
    out.setnchannels(2); out.setsampwidth(2); out.setframerate(RATE)
    out.writeframes((stereo.clip(-1,1)*32767).astype('<i2').tobytes())
print(path)
