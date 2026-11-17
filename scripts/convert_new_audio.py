import soundfile as sf
import numpy as np
from scipy import signal
import os

os.makedirs('assets/audio', exist_ok=True)

# 1. Process string1.mp3 and string2.mp3
# USER EXPLICIT RULE: "lưu ý tiếng tôi đã cắt cho phù hợp thời lượng, đừng có tự ý cắt ngắn hơn vì âm string rất thanh nên sóng âm không to đâu. Thay âm string cũ bằng 2 âm string trên và phát random mỗi lần đánh có dùng string."
# Keep exact duration! Do not trim! Just peak normalize to -1.5 dBFS (0.84) and convert to 16-bit 48kHz WAV.

for name, out_name in [('string1.mp3', 'string1.wav'), ('string2.mp3', 'string2.wav')]:
    in_path = f'C:/Users/sieut/Downloads/{name}'
    data, sr = sf.read(in_path)
    if len(data.shape) == 1:
        data = np.column_stack([data, data])
    
    # Resample to 48000 if not already
    if sr != 48000:
        num_samples = int(len(data) * 48000 / sr)
        data = signal.resample(data, num_samples, axis=0)
        sr = 48000
        
    # Micro anti-click fade at very last 3ms without cutting any length
    fade_len = int(0.003 * sr)
    data[-fade_len:] *= np.linspace(1.0, 0.0, fade_len)[:, np.newaxis]
    
    # Peak normalize
    peak = np.max(np.abs(data))
    if peak > 0:
        data = (data / peak) * 0.84
        
    out_path = f'assets/audio/{out_name}'
    sf.write(out_path, data, sr, subtype='PCM_16')
    print(f"Created {out_path}: Dur {len(data)/sr:.3f}s, Peak {np.max(np.abs(data)):.3f}")

# Also overwrite legacy string.wav with string1.wav for safety
sf.write('assets/audio/string.wav', data, sr, subtype='PCM_16')

# 2. Process the 6 sneaker squeak files
squeak_src = [
    'freesound_community-sneaker-squeak-rubber-91711 (mp3cut.net).mp3',
    'freesound_community-sneaker-squeak-rubber-91711 (mp3cut.net) (1).mp3',
    'freesound_community-sneaker-squeak-rubber-91711 (mp3cut.net) (2).mp3',
    'freesound_community-sneaker-squeak-rubber-91711 (mp3cut.net) (3).mp3',
    'freesound_community-sneaker-squeak-rubber-91711 (mp3cut.net) (4).mp3',
    'freesound_community-sneaker-squeak-rubber-91711 (mp3cut.net) (5).mp3',
]

for idx, fname in enumerate(squeak_src):
    in_path = f'C:/Users/sieut/Downloads/{fname}'
    data, sr = sf.read(in_path)
    if len(data.shape) == 1:
        data = np.column_stack([data, data])
        
    # Resample from 24000 to 48000
    if sr != 48000:
        num_samples = int(len(data) * 48000 / sr)
        data = signal.resample(data, num_samples, axis=0)
        sr = 48000
        
    # Micro fade on edges
    fade_len = int(0.005 * sr)
    data[:fade_len] *= np.linspace(0.0, 1.0, fade_len)[:, np.newaxis]
    data[-fade_len:] *= np.linspace(1.0, 0.0, fade_len)[:, np.newaxis]
    
    # Peak normalize to 0.84 (-1.5 dBFS)
    peak = np.max(np.abs(data))
    if peak > 0:
        data = (data / peak) * 0.84
        
    out_path = f'assets/audio/squeak_{idx+1}.wav'
    sf.write(out_path, data, sr, subtype='PCM_16')
    print(f"Created {out_path}: Dur {len(data)/sr:.3f}s, Peak {np.max(np.abs(data)):.3f}")

# Overwrite legacy squeak.wav with squeak_1.wav for fallback
data_sq1, sr_sq1 = sf.read('assets/audio/squeak_1.wav')
sf.write('assets/audio/squeak.wav', data_sq1, sr_sq1, subtype='PCM_16')
print("All audio files converted successfully!")
