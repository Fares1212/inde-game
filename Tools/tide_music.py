"""Original musical responses for the tide clock and the three endings."""
from pathlib import Path
import subprocess
import numpy as np

dest=Path(__file__).resolve().parents[1]/'Game/audio/generated'
for name,notes,space in [('tide',[50,57,62,66,69,74],.55),('home',[62,66,64,62,57,62],.80),('empty',[50,53,48],1.32),('bells',[74,81,78],.38)]:
    rate=24000
    snd=np.zeros(int(rate*(len(notes)*space+4)))
    for i,m in enumerate(notes):
        t=np.arange(rate*3)/rate
        a=2*np.pi*440*2**((m-69)/12)*t
        bell=(np.sin(a)+.27*np.sin(a*2.005)+.09*np.sin(a*3.01))*(1-np.exp(-t*32))*np.exp(-t*(1.15 if name!='empty' else 1.6))
        j=int(rate*i*space)
        snd[j:j+len(t)]+=bell*.26
    subprocess.run(['ffmpeg','-loglevel','error','-y','-f','s16le','-ar',str(rate),'-ac','1','-i','pipe:0','-c:a','libvorbis','-q:a','4',str(dest/(name+'.ogg'))],input=(snd*30000).astype('<i2').tobytes(),check=True)
