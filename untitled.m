% Design and plot analog Butterworth filters: lowpass, highpass, bandpass, bandstop
Rp = 0.5;    % passband ripple in dB
Rs = 30;     % stopband attenuation in dB
n_points = 512;

figure;

%% LOWPASS
Fp = 3500; Fs = 4500;               % Hz: passband edge, stopband edge
Wp = 2*pi*Fp; Ws = 2*pi*Fs;         % rad/s
[N, Wn] = buttord(Wp, Ws, Rp, Rs, 's');
[b,a] = butter(N, Wn, 's');         % analog lowpass
wa = linspace(0, 3*Ws, n_points);   % rad/s
H = freqs(b,a,wa);
subplot(2,2,1)
plot(wa/(2*pi), 20*log10(abs(H))); grid on
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
title(sprintf('LOWPASS (N=%d) - Gain response', N));
axis([0 3*Fs -60 5]);

%% HIGHPASS
Fp = 3500; Fs = 4500;               % Hz
Wp = 2*pi*Fp; Ws = 2*pi*Fs;         % rad/s
[N, Wn] = buttord(Wp, Ws, Rp, Rs, 's');   % for highpass these are scalars
[b,a] = butter(N, Wn, 'high', 's'); % analog highpass
wa = linspace(0, 3*Ws, n_points);
H = freqs(b,a,wa);
subplot(2,2,2)
plot(wa/(2*pi), 20*log10(abs(H))); grid on
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
title(sprintf('HIGHPASS (N=%d) - Gain response', N));
axis([0 3*Fs -60 5]);

%% BANDPASS
% Define lower and upper edges (Hz)
Fp = [2000 4000];    % passband edges in Hz (example)
Fs = [1500 4500];    % stopband edges in Hz (example)
Wp = 2*pi*Fp; Ws = 2*pi*Fs;   % rad/s vectors
[N, Wn] = buttord(Wp, Ws, Rp, Rs, 's');   % Wn will be [Wn1 Wn2] for bandpass
[b,a] = butter(N, Wn, 'bandpass', 's');
wa = linspace(0, 3*max(Ws), n_points);
H = freqs(b,a,wa);
subplot(2,2,3)
plot(wa/(2*pi), 20*log10(abs(H))); grid on
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
title(sprintf('BANDPASS (N=%d) - Gain response', N));
axis([0 3*max(Fs) -60 5]);

%% BANDSTOP
% Use same edges as bandpass but swapped stop/pass roles, or define new ones
Fp = [2000 4000];    % passband (Hz)
Fs = [1500 4500];    % stopband (Hz)
Wp = 2*pi*Fp; Ws = 2*pi*Fs;
[N, Wn] = buttord(Wp, Ws, Rp, Rs, 's');
[b,a] = butter(N, Wn, 'stop', 's');  % bandstop
wa = linspace(0, 3*max(Ws), n_points);
H = freqs(b,a,wa);
subplot(2,2,4)
plot(wa/(2*pi), 20*log10(abs(H))); grid on
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
title(sprintf('BANDSTOP (N=%d) - Gain response', N));
axis([0 3*max(Fs) -60 5]);
