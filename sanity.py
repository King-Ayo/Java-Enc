import numpy as np
import matplotlib.pyplot as plt

def analyze_waveform_pair(modulated, demodulated, sample_rate, recording_id="recording"):
    
    def print_stats(label, data):
        print(f"\n=== {label} ===")
        print(f"Mean: {np.mean(data):.5f}")
        print(f"DC Offset (Real): {np.mean(np.real(data)):.5f}")
        print(f"DC Offset (Imag): {np.mean(np.imag(data)):.5f}" if np.iscomplexobj(data) else "")
        print(f"Average Power: {np.mean(np.abs(data)**2):.5f}")
        print(f"Variance: {np.var(data):.5f}")
        print(f"Peak (max): {np.max(data):.5f}")
        print(f"Peak (min): {np.min(data):.5f}")

    print_stats("Modulated Signal", modulated)
    print_stats("Demodulated Signal", demodulated)

    # Time-domain visualization
    time = np.arange(len(modulated)) / sample_rate
    N_plot = min(5000, len(modulated))
  
    plt.figure(figsize=(12, 6))
    plt.subplot(2, 1, 1)
    plt.plot(time[:N_plot], np.abs(modulated[:N_plot]))
    plt.title(f"{recording_id} - Modulated (Magnitude Envelope)")
    plt.xlabel("Time [s]")
    plt.ylabel("Amplitude")

    plt.subplot(2, 1, 2)
    plt.plot(time[:N_plot], demodulated[:N_plot].real)
    plt.title(f"{recording_id} - Demodulated (Real Part)")
    plt.xlabel("Time [s]")
    plt.ylabel("Amplitude")
    plt.tight_layout()
    plt.show()

    # Frequency-domain visualization
    def plot_fft(signal, sr, label):
        N = 4096
        freq = np.fft.fftfreq(N, d=1/sr)
        fft_vals = np.fft.fft(signal[:N])
        plt.figure(figsize=(10, 4))
        plt.plot(freq[:N//2], 20*np.log10(np.abs(fft_vals[:N//2]) + 1e-12))
        plt.title(f"{recording_id} - {label} Spectrum")
        plt.xlabel("Frequency [Hz]")
        plt.ylabel("Magnitude [dB]")
        plt.grid()
        plt.tight_layout()
        plt.show()

    plot_fft(modulated, sample_rate, "Modulated")
    plot_fft(demodulated, sample_rate, "Demodulated")

    # Optional correlation
    if len(modulated) == len(demodulated):
        corr = np.correlate(np.abs(modulated), np.abs(demodulated), mode='valid')
        plt.figure(figsize=(6, 3))
        plt.plot(corr)
        plt.title(f"{recording_id} - Correlation between |Modulated| and |Demodulated|")
        plt.xlabel("Lag")
        plt.ylabel("Correlation")
        plt.tight_layout()
        plt.show()
