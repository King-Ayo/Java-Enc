# === STATS ===
power = np.mean(np.abs(iq_data)**2)
mean_i = np.mean(iq_data.real)
mean_q = np.mean(iq_data.imag)
var_i = np.var(iq_data.real)
var_q = np.var(iq_data.imag)

print(f"\nSignal Power: {power:.4f}")
print(f"Mean (I): {mean_i:.4f}, Mean (Q): {mean_q:.4f}")
print(f"Variance (I): {var_i:.4f}, Variance (Q): {var_q:.4f}")

# === TIME DOMAIN PLOT ===
time = np.arange(len(iq_data)) / sample_rate
plt.figure()
plt.plot(time[:1000], iq_data.real[:1000], label='I')
plt.plot(time[:1000], iq_data.imag[:1000], label='Q')
plt.title('Time-Domain IQ Signal (First 1000 samples)')
plt.xlabel('Time (s)')
plt.ylabel('Amplitude')
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.show()

# === CONSTELLATION DIAGRAM ===
plt.figure()
plt.plot(iq_data.real[::10], iq_data.imag[::10], '.', alpha=0.5)
plt.title('Constellation Diagram')
plt.xlabel('In-Phase (I)')
plt.ylabel('Quadrature (Q)')
plt.grid(True)
plt.axis('equal')
plt.tight_layout()
plt.show()

# === POWER SPECTRAL DENSITY ===
f, Pxx = signal.welch(iq_data, fs=sample_rate, nperseg=1024)
plt.figure()
plt.semilogy(f, Pxx)
plt.title('Power Spectral Density')
plt.xlabel('Frequency (Hz)')
plt.ylabel('Power/Frequency (dB/Hz)')
plt.grid(True)
plt.tight_layout()
plt.show()

# === BANDWIDTH ESTIMATION ===
thresh = np.max(Pxx) * 0.1
bw_indices = np.where(Pxx > thresh)[0]
bandwidth = f[bw_indices[-1]] - f[bw_indices[0]]
print(f"Estimated Bandwidth: {bandwidth:.2f} Hz")
