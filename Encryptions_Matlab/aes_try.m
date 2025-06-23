%% Add compiled JAR
javaaddpath('AESModesFull.class');

%% Example input
plaintext = 'Hello from MATLAB to Java AES';
mode = 'CCM'; % ECB, CBC, CFB, OFB, CTR, GCM, CCM
keySizeBits = 256; % 128, 192, 256

%% Call encrypt
result = AESModesFull.aesEncrypt(uint8(plaintext), mode, keySizeBits);

%% Display results
disp('=== Encrypted ===');
disp(['Ciphertext (Base64): ', char(java.util.Base64.getEncoder().encodeToString(result.ciphertext))]);
if ~isempty(result.iv)
    disp(['IV (Base64): ', char(java.util.Base64.getEncoder().encodeToString(result.iv))]);
end

%% Call decrypt
decryptedBytes = AESModesFull.aesDecrypt(result, mode, keySizeBits);
disp('=== Decrypted ===');
disp(char(decryptedBytes));
