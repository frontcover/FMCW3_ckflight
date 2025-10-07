import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

# -------------------------------
# Paths
# -------------------------------
project_dir = Path(__file__).parent
sim_dir = project_dir / "FMCW3.sim" / "sim_1" / "behav" / "xsim"
file_path = sim_dir / "adc_output.txt"

# -------------------------------
# Load data
# -------------------------------
adc_input, data_a, data_b = np.loadtxt(file_path, unpack=True)
adc_input = adc_input.astype(int)
data_a = data_a.astype(int)
data_b = data_b.astype(int)

# -------------------------------
# FFT
# -------------------------------
N = len(adc_input)
fs = 40e6  # Sampling rate
f = np.fft.fftfreq(N, 1/fs)

fft_input = np.abs(np.fft.fft(adc_input))
fft_a = np.abs(np.fft.fft(data_a))
fft_b = np.abs(np.fft.fft(data_b))

idx = np.arange(N//2)
f = f[idx]
fft_input = fft_input[idx]
fft_a = fft_a[idx]
fft_b = fft_b[idx]

# Normalize FFT for dB plot
fft_input_db = 20*np.log10(fft_input/np.max(fft_input))
fft_a_db = 20*np.log10(fft_a/np.max(fft_a))
fft_b_db = 20*np.log10(fft_b/np.max(fft_b))

# -------------------------------
# Plot in one figure with two subplots
# -------------------------------
fig, axes = plt.subplots(2, 1, figsize=(12, 10))

# Time-domain
axes[0].plot(adc_input, label='ADC Input')
axes[0].plot(data_a, label='FIR Output A')
axes[0].plot(data_b, label='FIR Output B')
axes[0].set_title('Time Domain')
axes[0].set_xlabel('Sample Index')
axes[0].set_ylabel('Value')
axes[0].legend()
axes[0].grid(True)

# Frequency-domain
axes[1].plot(f, fft_input_db, label='ADC Input')
axes[1].plot(f, fft_a_db, label='FIR Output A')
axes[1].plot(f, fft_b_db, label='FIR Output B')
axes[1].set_title('Frequency Domain (Normalized dB)')
axes[1].set_xlabel('Frequency [Hz]')
axes[1].set_ylabel('Amplitude [dB]')
axes[1].legend()
axes[1].grid(True)

plt.tight_layout()
plt.show()
