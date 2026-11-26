"""Render the original score, shoreline, foley and Bernard's French dialogue.

Dependencies for rebuilding the checked-in Oggs: NumPy, ffmpeg and espeak-ng.
"""
import json
import math
from pathlib import Path
import shutil
import subprocess
import tempfile
import wave

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "Game/audio/generated"
RATE = 24000
RNG = np.random.default_rng(713346)
TAU = 2 * math.pi


def time(duration):
    return np.arange(round(duration * RATE), dtype=float) / RATE


def noise(t, high=6000, low=0):
    spectrum = np.fft.rfft(RNG.standard_normal(t.size))
    hz = np.fft.rfftfreq(t.size, 1 / RATE)
    spectrum *= np.exp(-((hz / high) ** 2))
    if low:
        spectrum *= 1 - np.exp(-((hz / low) ** 2))
    samples = np.fft.irfft(spectrum, n=t.size)
    return samples / max(.01, np.std(samples))


def encode(name, samples, peak=.76):
    samples = samples * (peak / max(.02, np.abs(samples).max()))
    channels = 1 if samples.ndim == 1 else samples.shape[1]
    raw = np.round(np.clip(samples, -1, 1) * 32767).astype('<i2').tobytes()
    subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y',
                    '-f', 's16le', '-ar', str(RATE), '-ac', str(channels),
                    '-i', 'pipe:0', '-c:a', 'libvorbis', '-q:a', '4',
                    '-metadata', 'artist=SPOONFUL', str(DEST / (name+'.ogg'))],
                   input=raw, check=True)


def hz(midi):
    return 440 * 2 ** ((midi-69) / 12)


def pluck(midi, duration, timbre=1):
    t = time(duration)
    phase = TAU * hz(midi) * t
    envelope = (1 - np.exp(-t * 85)) * np.exp(-t * (2.2 if timbre else 1.3))
    sound = np.sin(phase + .0025*np.sin(4.1*t))
    sound += .33*np.sin(phase*2.001)*np.exp(-3.8*t)
    sound += (.18 if timbre else .06)*np.sin(phase*3.002)*np.exp(-4.2*t)
    return envelope*sound


def lullaby():
    beat = .72
    bars = [[50,57,62,66], [47,54,59,62], [43,55,59,62], [45,57,61,64],
            [50,54,57,62], [43,55,59,64], [45,52,57,62], [45,52,61,64]]
    melody = [[69,71,69,66], [66,64,62], [67,69,71], [69,64,61],
              [66,69,74], [71,69,67,64], [66,64,62], [61,64,69]]
    count = round(16*6*beat*RATE)
    music = np.zeros((count, 2))

    def put(at, samples, gain, pan):
        # Fold reverberation into the start so the sea tune can loop cleanly.
        idx = (round(at * RATE) + np.arange(len(samples))) % count
        music[idx, 0] += samples * gain * math.sqrt(1-pan)
        music[idx, 1] += samples * gain * math.sqrt(pan)

    for bar in range(16):
        chord = bars[bar % 8]
        start = bar*6*beat
        put(start, pluck(chord[0]-12, 3.1, 0), .32, .41)
        for slot, degree in enumerate([0, 2, 1, 3, 2, 1]):
            delay = ([0,.024,.012,.008,.027,.014][slot])
            tone = pluck(chord[degree]+(12 if slot in [2,5] else 0), 1.9)
            put(start + slot*beat + delay, tone, .19 if slot in [0,3] else .13, .31)
            put(start + slot*beat + delay + .135, tone, .032, .74)
        for n, note in enumerate(melody[bar % 8]):
            onset = start+([.45,2.05,3.35,4.8][n]+(.12 if bar>=8 else 0))*beat
            tone = pluck(note+(12 if 11<=bar<14 else 0), 2.6, 0)
            put(onset, tone, .23, .63)
            put(onset+.24, tone, .045, .27)
    encode('theme', music, .72)


def surf():
    duration = 24
    t = time(duration)
    channels = []
    for phase in [0,.13]:
        swell = (.5+.5*np.sin(TAU*3*t/duration+phase+.5*np.sin(TAU*t/duration)))**2
        wash = noise(t, 1100, 85) * (.08+.18*swell)
        wash += noise(t, 4500, 1250)*(.022+.23*swell**2)
        channels.append(wash)
    encode('surf', np.array(channels).T, .62)


def liquid(duration, number, pitch):
    t=time(duration)
    sound=np.zeros_like(t)
    for i in range(number):
        onset = RNG.uniform(.005,duration*.6)
        k = np.maximum(0,t-onset)
        f = pitch*RNG.uniform(.75,1.38)
        phase = TAU*f*(k+.0017*(1-np.exp(-k*200)))
        sound += (t>=onset)*np.exp(-k*RNG.uniform(13,34))*np.sin(phase)
    return sound


def foley():
    for i in range(4):
        t=time(.44)
        encode('scoop'+str(i), liquid(.44,5,560+55*i) + .055*noise(t,3900,650)*np.sin(np.pi*t/.44)**2,.60)
    for i in range(2):
        t=time(.8)
        encode('pour'+str(i), liquid(.8,17,820+90*i) + .15*noise(t,2800,470)*np.sin(np.pi*t/.8)**2,.72)
        encode('wade'+str(i), liquid(.42,10,320+62*i),.58)
        t=time(.50)
        encode('coin'+str(i), (np.sin(TAU*(1165+i*75)*t)+.32*np.sin(TAU*1900*t))*np.exp(-t*11)*(1-np.exp(-t*125)),.57)
    for i in range(3):
        t=time(.34)
        thump=np.sin(TAU*(72+10*i)*t)*np.exp(-t*19)
        crunch=noise(t,2200+220*i,280)*np.exp(-t*16)
        encode('step'+str(i),(thump+.78*crunch)*(1-np.exp(-t*75)),.70)
    for key,notes,gap in [('buy0',[69,74,78],.11),('reveal0',[62,69,73,78,81],.21)]:
        t=time(2.8); y=np.zeros_like(t)
        for i,note in enumerate(notes):
            v=pluck(note,1.75,0); index=int(i*gap*RATE); y[index:index+len(v)]+=v
        encode(key,y)
    t=time(2.1); env=np.sin(np.pi*t/2.1)**1.4
    encode('creak0',env*(np.sin(TAU*(85*t+12*t*t)+.65*np.sin(TAU*2*t))+.43*noise(t,600,120))*(.60+.40*np.sin(TAU*5*t)**2))
    t=time(6); v=noise(t,1000,60)*(.25+.55*np.sin(TAU*(.5*t+.11*t*t))**2)
    encode('plug0', np.sin(np.pi*t/6)**.7*(v+.24*np.sin(TAU*(87*t-4.5*t*t))))
    t=time(.085); encode('click0',np.sin(TAU*780*t)*np.exp(-t*68)*(1-np.exp(-t*1200)),.29)


def voices():
    db=json.loads((ROOT/'Game/Data/basins.json').read_text(encoding='utf8'))
    with tempfile.TemporaryDirectory() as folder:
        wav=Path(folder)/'bernard.wav'
        for key, line in db['voices'].items():
            subprocess.run(['espeak-ng','-v','fr','-s','154','-p','42','-w',str(wav),'--',line],check=True)
            with wave.open(str(wav)) as source:
                recorded=np.frombuffer(source.readframes(source.getnframes()),dtype='<i2').astype(float)/32768
                native=source.getframerate()
            s=np.interp(np.arange(round(len(recorded)*RATE/native))*native/RATE,np.arange(len(recorded)),recorded)
            delay=int(.042*RATE)
            s[delay:]+=.11*s[:-delay].copy()
            encode('vo_'+key,s,.74)


if __name__=='__main__':
    if not all(shutil.which(x) for x in ('espeak-ng','ffmpeg')):
        raise SystemExit('Installer espeak-ng et ffmpeg pour reconstruire les pistes.')
    DEST.mkdir(parents=True,exist_ok=True)
    lullaby()
    surf()
    foley()
    voices()
    print(f'{len(list(DEST.glob("*.ogg")))} pistes rendues.')
