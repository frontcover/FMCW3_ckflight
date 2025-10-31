import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import freqz

# -----------------------------
# CONFIG: Change the filename and sampling rate
# -----------------------------
#coe_file = "C:/Users/CK/Desktop/coe_analyze/fir20.coe"
coe_file = "C:/Users/CK/Desktop/coe_analyze/fir_downsampler.coe"
Fs = 40e6  # ADC sampling rate in Hz

# -----------------------------
# STEP 1: Load coefficients
# -----------------------------
with open(coe_file, 'r') as f:
    lines = f.readlines()

# Find line with "CoefData="
coef_line = None
for line in lines:
    if "CoefData" in line:
        coef_line = line.split('=')[1].strip().rstrip(';')
        break

if coef_line is None:
    raise ValueError("No CoefData found in the COE file.")

# Convert to float array
coefs = np.array([float(x) for x in coef_line.split(',')])

print(f"Number of taps: {len(coefs)}")
print(f"First 10 coefficients: {coefs[:10]}")

# -----------------------------
# STEP 2: Plot impulse response
# -----------------------------
plt.figure(figsize=(10,4))
plt.stem(coefs)
plt.title("FIR Impulse Response")
plt.xlabel("Tap Index")
plt.ylabel("Coefficient")
plt.grid(True)
plt.show()

# -----------------------------
# STEP 3: Compute and plot frequency response
# -----------------------------
w, h = freqz(coefs, worN=2048)  # Frequency response
freq_hz = w * Fs / (2 * np.pi)  # Convert from rad/sample to Hz

plt.figure(figsize=(10,4))
plt.plot(freq_hz/1e6, 20*np.log10(np.abs(h)))  # Frequency in MHz
plt.title("FIR Magnitude Response")
plt.xlabel("Frequency (MHz)")
plt.ylabel("Magnitude (dB)")
plt.grid(True)
plt.show()

# -----------------------------
# Optional: Phase response
# -----------------------------
plt.figure(figsize=(10,4))
plt.plot(freq_hz/1e6, np.angle(h))
plt.title("FIR Phase Response")
plt.xlabel("Frequency (MHz)")
plt.ylabel("Phase (radians)")
plt.grid(True)
plt.show()
