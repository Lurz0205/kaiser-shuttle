import soundfile as sf
import numpy as np
from scipy import signal

def process_audio(input_path, output_path, hp_cutoff=320.0, tail_extension=0.35, wet_reverb=0.28):
    data, sr = sf.read(input_path)
    if len(data.shape) > 1:
        # Convert to stereo if not already, or preserve stereo
        channels = data.shape[1]
    else:
        data = np.column_stack([data, data])
        channels = 2

    # 1. High-pass filter (Butterworth 4th-order) to eliminate low-frequency footstep thud / rumble
    sos = signal.butter(4, hp_cutoff, btype='highpass', fs=sr, output='sos')
    filtered = np.zeros_like(data)
    for ch in range(channels):
        filtered[:, ch] = signal.sosfilt(sos, data[:, ch])

    # 2. Crisp Presence EQ (slight boost at 2.5kHz - 4.5kHz for racquet string ping clarity)
    sos_presence = signal.butter(2, [2200.0, 5000.0], btype='bandpass', fs=sr, output='sos')
    for ch in range(channels):
        presence = signal.sosfilt(sos_presence, filtered[:, ch])
        filtered[:, ch] += presence * 0.25

    # 3. Smooth fade-out on the tail of original sound (last 35ms) to eliminate the hard cutoff edge
    fade_len = int(0.035 * sr)
    fade_curve = 0.5 * (1.0 + np.cos(np.linspace(0, np.pi, fade_len)))
    for ch in range(channels):
        filtered[-fade_len:, ch] *= fade_curve

    # 4. Tail Extension with Badminton Hall Acoustic Decay (Exponential Reverb Tail)
    # Create pad for the decay tail
    tail_samples = int(tail_extension * sr)
    padded = np.pad(filtered, ((0, tail_samples), (0, 0)), mode='constant')

    # Multi-tap hall resonance / diffuser for smooth indoor hall ring
    # Delay lines (in samples) and feedback gains simulating indoor hall reflections
    delay_ms = [18.0, 27.0, 39.0, 53.0, 71.0, 89.0, 113.0]
    decay_factors = [0.45, 0.38, 0.30, 0.24, 0.18, 0.12, 0.08]

    reverb = np.zeros_like(padded)
    for d_ms, g in zip(delay_ms, decay_factors):
        d_samp = int((d_ms / 1000.0) * sr)
        # Lowpass each reflection slightly to simulate air & wooden court absorption
        sos_damp = signal.butter(1, 4000.0, btype='lowpass', fs=sr, output='sos')
        for ch in range(channels):
            delayed = np.zeros(len(padded))
            delayed[d_samp:] = padded[:-d_samp, ch] * g
            reverb[:, ch] += signal.sosfilt(sos_damp, delayed)

    # Blend dry + wet reverb
    out = padded + reverb * wet_reverb

    # Apply gentle fade-out over the final 80ms of the extended tail
    end_fade_len = int(0.08 * sr)
    end_fade = 0.5 * (1.0 + np.cos(np.linspace(0, np.pi, end_fade_len)))
    out[-end_fade_len:, :] *= end_fade[:, np.newaxis]

    # 5. Normalization: Peak at -1.5 dBFS (approx 0.84)
    peak = np.max(np.abs(out))
    if peak > 0:
        out = (out / peak) * 0.84

    # Save as 16-bit 48kHz WAV
    sf.write(output_path, out, sr, subtype='PCM_16')
    print(f"Processed {input_path} -> {output_path} (Dur: {len(out)/sr:.3f}s, Peak: {np.max(np.abs(out)):.3f})")

if __name__ == '__main__':
    # Process string.mp3 -> assets/audio/string.wav
    process_audio(
        'C:/Users/sieut/Downloads/string.mp3',
        'c:/Users/sieut/Downloads/GameCauLong/assets/audio/string.wav',
        hp_cutoff=300.0,
        tail_extension=0.28,
        wet_reverb=0.22
    )

    # Process chem cau.mp3 -> assets/audio/chem_cau.wav
    process_audio(
        'C:/Users/sieut/Downloads/chem cau.mp3',
        'c:/Users/sieut/Downloads/GameCauLong/assets/audio/chem_cau.wav',
        hp_cutoff=280.0,
        tail_extension=0.35,
        wet_reverb=0.25
    )
