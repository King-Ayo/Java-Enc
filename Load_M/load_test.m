data = load('encryptedDataset.mat');

n = length(data.original);

for i = 1:n
    orig = data.original{i};

    aes = data.aes{i};
    aes_mode = strtrim(data.aes_mode(i, :));  % FIXED LINE

    if strcmp(aes_mode, 'ECB')
        aes_iv = [];
    else
        aes_iv = data.aes_input_iv{i};
    end

    aes_key = data.aes_input_key(i,:);

    tdes = data.triple_des{i};
    tdes_iv = data.triple_des_input_iv(i, :);
    tdes_key = data.triple_des_input_key(i, :);

    blowfish = data.blowfish{i};
    blowfish_iv = data.blowfish_input_iv(i,:);
    blowfish_key = data.blowfish_input_key(i,:);

    chacha = data.chacha20{i};
    chacha_nonce = data.chacha_input_nonce(i,:);
    chacha_key = data.chacha_input_key(i,:);

    fernet = data.fernet{i};
    fernet_key = data.fernet_key(i,:);

    fprintf('Row %d: AES mode = %s | AES IV bytes: %d | AES Key: %s\n', ...
        i, aes_mode, length(aes_iv), aes_key);

end