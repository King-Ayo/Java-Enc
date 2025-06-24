% Generate HE-SU waveform (MCS 0, CBW20, 100-byte payload)
cfgHESU = wlanHESUConfig('MCS',0, 'ChannelBandwidth','CBW20', 'NumTransmitAntennas',1);
cbw = cfgHESU.ChannelBandwidth;
% Create random 100-byte payload (random ASCII letters 'a'-'z')
payloadBytes = randi([97 122],100,1,'uint8');  
% Create MAC frame config for Data frame
cfgMAC = wlanMACFrameConfig(FrameType="Data");
% Convert payload to hexadecimal string for wlanMACFrame
hexString = lower(dec2hex(payloadBytes,2))'; 
payloadHex = lower(string(join(cellstr(hexString(:)),'')));
% Generate MPDU bits (frame) for the payload and PHY
[mpduBits, mpduLen] = wlanMACFrame(payloadHex, cfgMAC, cfgHESU); 
% Set PSDULength to match the MPDU bits (in octets)
cfgHESU.PSDULength = mpduLen;
% Generate the HE-SU waveform (baseband) with oversampling factor = 1
txWaveform = wlanWaveformGenerator(mpduBits, cfgHESU, ...
    NumPackets=1, IdleTime=0, ScramblerInitialization=1, ...
    OversamplingFactor=1);
% Add zero-padding to avoid TX underrun
padLen = round(0.001*cfgHESU.SampleRate);  % 1 ms padding
txWaveform = [txWaveform; zeros(padLen, size(txWaveform,2))];

% Configure ADALM-Pluto SDR for transmission
txPluto = sdrtx('Pluto','SerialNum','<TX_SERIAL>');         % TX Pluto (replace with serial)
txPluto.BasebandSampleRate = wlanSampleRate(cfgHESU);      % 20 MHz for CBW20
txPluto.CenterFrequency   = 2.412e9;                       % e.g., WLAN channel 1
txPluto.Gain              = 0;                             % TX gain (dB)
% Scale waveform to 80% of full-scale to prevent saturation
txWaveform = txWaveform * (0.8 / max(abs(txWaveform)));
% Transmit waveform repeatedly
transmitRepeat(txPluto, txWaveform);

% Configure ADALM-Pluto SDR for reception
rxPluto = sdrrx('Pluto','SerialNum','<RX_SERIAL>');         % RX Pluto (replace with serial)
rxPluto.BasebandSampleRate = txPluto.BasebandSampleRate;   % match TX rate
rxPluto.CenterFrequency   = txPluto.CenterFrequency;       % match TX freq
rxPluto.GainSource        = 'Manual';
rxPluto.Gain              = 20;                            % RX gain (dB)
rxPluto.OutputDataType    = 'double';
% Capture two frames worth of samples to cover the packet
rxPluto.SamplesPerFrame   = size(txWaveform,1);
rxData1 = rxPluto();   % receive first frame
rxData2 = rxPluto();   % receive second frame
rxFullWaveform = [rxData1; rxData2];  % concatenate received samples
% Stop transmission and release SDR objects
release(txPluto);
release(rxPluto);

% Time-domain scope for TX and RX signals
timeScope = dsp.TimeScope('SampleRate', txPluto.BasebandSampleRate, ...
    'TimeSpan','Full View','Title','Baseband Waveforms','YLimits',[-1.2 1.2]);
timeScope(rxFullWaveform);  % display received waveform over time

% Spectrum analyzer for received waveform
spectrumScope = spectrumAnalyzer( ...
    SpectrumType='power-density', ...
    Title='Received Baseband WLAN Signal Spectrum', ...
    YLabel='Power spectral density (dBW)', ...
    SampleRate=txPluto.BasebandSampleRate);
spectrumScope(rxFullWaveform);

% Constellation diagram (assumes equalized symbols available later)
refQAM = wlanReferenceSymbols('BPSK');  % MCS0 uses BPSK
constDiagram = comm.ConstellationDiagram(...
    Title='Equalized HE-Data Symbols',...
    ShowReferenceConstellation=true,...
    ReferenceConstellation=refQAM,...
    Position=[878 376 460 460]);

% Packet detection (coarse timing using L-STF) and fine timing using L-LTF
cbw = char(cbw);
startOffset = wlanPacketDetect(rxFullWaveform, cbw);  % coarse offset
% Extract fields from coarse offset for fine timing (L-STF to L-SIG)
ind = wlanFieldIndices(cfgHESU); 
preambleFields = rxFullWaveform(startOffset + (ind.LSTF(1):ind.LSIG(2)), :);
fineOffset = wlanSymbolTimingEstimate(preambleFields, cbw);  % refine offset
pktOffset = startOffset + fineOffset;
rxSync = rxFullWaveform(pktOffset+1:end);  % aligned waveform starting at L-STF

% Coarse CFO estimate/correction using L-STF
rxLSTF = rxSync(ind.LSTF(1):ind.LSTF(2), :);
coarseFreqOffset = wlanCoarseCFOEstimate(rxLSTF, cbw);
n = (0:length(rxSync)-1).';
rxSync = rxSync .* exp(-1j*2*pi*coarseFreqOffset*n/txPluto.BasebandSampleRate);

% Fine CFO estimate/correction using L-LTF
rxLLTF = rxSync(ind.LLTF(1):ind.LLTF(2), :);
fineFreqOffset = wlanFineCFOEstimate(rxLLTF, cbw);
rxSync = rxSync .* exp(-1j*2*pi*fineFreqOffset*n/txPluto.BasebandSampleRate);

% Demodulate and recover L-SIG (legacy signal field)
rxLSIG = rxSync(ind.LSIG(1):ind.RLSIG(2), :);  % L-SIG plus redundant field
lsigDemod = wlanHEDemodulate(rxLSIG, 'L-SIG', cbw);
lsigSymbols = mean(lsigDemod, 2);  % combine L-SIG and R-LSIG
lsigInfo = wlanHEOFDMInfo('L-SIG', cbw);
lsigData = lsigSymbols(lsigInfo.DataIndices);
[lsigBits, lsigFail, lsigInfo] = wlanLSIGBitRecover(lsigData, 0);  % assume no noise
% Demodulate and recover HE-SIG-A
rxSIGA = rxSync(ind.HESIGA(1):ind.HESIGA(2), :);
sigADemod = wlanHEDemodulate(rxSIGA, 'HE-SIG-A', cbw);
sigAInfo = wlanHEOFDMInfo('HE-SIG-A', cbw);
sigASymbols = sigADemod(sigAInfo.DataIndices,:);
[heSigBits, heSigCRC] = wlanHESIGABitRecover(sigASymbols, 0);  % assume no noise

% Demodulate and recover HE-Data field
rxDataField = rxSync(ind.HEData(1):ind.HEData(2), :);
dataDemod = wlanHEDemodulate(rxDataField, 'HE-Data', cfgHESU);
dataInfo = wlanHEOFDMInfo('HE-Data', cfgHESU);
rxDataSymbols = dataDemod(dataInfo.DataIndices, :);
recoveredBits = wlanHEDataBitRecover(rxDataSymbols, 0, cfgHESU);  % assume no noise

% Compare transmitted vs recovered bits
txBits = mpduBits;      % original MPDU bits from wlanMACFrame
numBits = length(txBits);
numErrors = sum(txBits ~= recoveredBits);
BER = numErrors/numBits;
fprintf('Bit errors: %d out of %d bits (BER = %.2g)\n', numErrors, numBits, BER);

