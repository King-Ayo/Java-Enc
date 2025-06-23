import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.security.SecureRandom;
import java.util.Base64;

public class AESModesFull {

    static final int IV_LENGTH = 16;
    static final int GCM_IV_LENGTH = 12;
    static final int GCM_TAG_LENGTH = 128;
    static final int CCM_TAG_LENGTH = 128;
    static final int CCM_IV_LENGTH = 12;

    public static void main(String[] args) throws Exception {
        String plaintext = "Hello from AES Full Example!";
        String mode = "GCM"; // ECB, CBC, CFB, OFB, CTR, GCM, CCM
        int keySizeBits = 256; // 128, 192, or 256

        System.out.println("Plaintext: " + plaintext);
        System.out.println("Mode: AES/" + mode);
        System.out.println("Key Size (bits): " + keySizeBits);

        AESResult result = aesEncrypt(plaintext.getBytes(), mode, keySizeBits);

        System.out.println("\n=== Encryption Result ===");
        System.out.println("Ciphertext (Base64): " + Base64.getEncoder().encodeToString(result.ciphertext));
        if (result.iv != null)
            System.out.println("IV (Base64): " + Base64.getEncoder().encodeToString(result.iv));
        if (result.tag != null)
            System.out.println("Auth Tag (Base64): " + Base64.getEncoder().encodeToString(result.tag));

        byte[] decrypted = aesDecrypt(result, mode, keySizeBits);
        System.out.println("\n=== Decryption Result ===");
        System.out.println("Decrypted Plaintext: " + new String(decrypted));
    }

    public static class AESResult {
        public byte[] ciphertext;
        public byte[] key;
        public byte[] iv;
        public byte[] tag;

        public AESResult(byte[] ciphertext, byte[] key, byte[] iv, byte[] tag) {
            this.ciphertext = ciphertext;
            this.key = key;
            this.iv = iv;
            this.tag = tag;
        }
    }

    public static AESResult aesEncrypt(byte[] plaintext, String mode, int keySizeBits) throws Exception {
        if (keySizeBits != 128 && keySizeBits != 192 && keySizeBits != 256) {
            throw new IllegalArgumentException("Invalid key size. Must be 128, 192, or 256 bits.");
        }

        KeyGenerator keyGen = KeyGenerator.getInstance("AES");
        keyGen.init(keySizeBits);
        SecretKey key = keyGen.generateKey();

        byte[] iv = null;
        byte[] tag = null;
        Cipher cipher;

        if (mode.equalsIgnoreCase("ECB")) {
            cipher = Cipher.getInstance("AES/ECB/PKCS5Padding");
            cipher.init(Cipher.ENCRYPT_MODE, key);

        } else if (mode.equalsIgnoreCase("CBC") || mode.equalsIgnoreCase("CFB") ||
                   mode.equalsIgnoreCase("OFB") || mode.equalsIgnoreCase("CTR")) {

            iv = new byte[IV_LENGTH];
            new SecureRandom().nextBytes(iv);

            cipher = Cipher.getInstance("AES/" + mode + "/PKCS5Padding");
            IvParameterSpec ivSpec = new IvParameterSpec(iv);
            cipher.init(Cipher.ENCRYPT_MODE, key, ivSpec);

        } else if (mode.equalsIgnoreCase("GCM")) {
            iv = new byte[GCM_IV_LENGTH];
            new SecureRandom().nextBytes(iv);

            GCMParameterSpec gcmSpec = new GCMParameterSpec(GCM_TAG_LENGTH, iv);
            cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, key, gcmSpec);

        } else if (mode.equalsIgnoreCase("CCM")) {
            iv = new byte[CCM_IV_LENGTH];
            new SecureRandom().nextBytes(iv);

            GCMParameterSpec ccmSpec = new GCMParameterSpec(CCM_TAG_LENGTH, iv);
            cipher = Cipher.getInstance("AES/CCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, key, ccmSpec);

        } else {
            throw new IllegalArgumentException("Unsupported AES mode: " + mode);
        }

        byte[] ciphertext = cipher.doFinal(plaintext);
        return new AESResult(ciphertext, key.getEncoded(), iv, tag);
    }

    public static byte[] aesDecrypt(AESResult result, String mode, int keySizeBits) throws Exception {
        SecretKeySpec keySpec = new SecretKeySpec(result.key, "AES");

        Cipher cipher;
        if (mode.equalsIgnoreCase("ECB")) {
            cipher = Cipher.getInstance("AES/ECB/PKCS5Padding");
            cipher.init(Cipher.DECRYPT_MODE, keySpec);

        } else if (mode.equalsIgnoreCase("CBC") || mode.equalsIgnoreCase("CFB") ||
                   mode.equalsIgnoreCase("OFB") || mode.equalsIgnoreCase("CTR")) {

            IvParameterSpec ivSpec = new IvParameterSpec(result.iv);
            cipher = Cipher.getInstance("AES/" + mode + "/PKCS5Padding");
            cipher.init(Cipher.DECRYPT_MODE, keySpec, ivSpec);

        } else if (mode.equalsIgnoreCase("GCM")) {
            GCMParameterSpec gcmSpec = new GCMParameterSpec(GCM_TAG_LENGTH, result.iv);
            cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE, keySpec, gcmSpec);

        } else if (mode.equalsIgnoreCase("CCM")) {
            GCMParameterSpec ccmSpec = new GCMParameterSpec(CCM_TAG_LENGTH, result.iv);
            cipher = Cipher.getInstance("AES/CCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE, keySpec, ccmSpec);

        } else {
            throw new IllegalArgumentException("Unsupported AES mode: " + mode);
        }

        byte[] decrypted = cipher.doFinal(result.ciphertext);
        return decrypted;
    }
}
