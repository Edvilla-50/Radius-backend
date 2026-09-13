package com.Radius.backend.Music;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.StringReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyFactory;
import java.security.PrivateKey;
import java.security.spec.PKCS8EncodedKeySpec;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.Date;

/**
 * Signs the Apple MusicKit developer token (JWT).
 * This token identifies the Radius app to Apple's catalog API and is safe
 * to hand to the client — it never contains the private key itself.
 *
 * The .p8 private key file NEVER leaves the backend. Store its path (or raw
 * contents) in an environment variable / secret manager — never commit it.
 */
@Service
public class MusicKitTokenService {

    @Value("${musickit.team-id}")       // Radius Team ID: Y8J539SFWX
    private String teamId;

    @Value("${musickit.key-id}")        // 10-char Key ID from the Keys page
    private String keyId;

    @Value("${musickit.private-key-path}") // e.g. /etc/secrets/AuthKey_XXXXXXXXXX.p8
    private String privateKeyPath;

    private String cachedToken;
    private Instant cachedTokenExpiry;

    /**
     * Returns a cached developer token if still valid, otherwise signs a new one.
     * Apple allows tokens to live up to 6 months — we use ~5.5 months here to be safe.
     */
    public synchronized String getDeveloperToken() throws Exception {
        if (cachedToken != null && cachedTokenExpiry != null
                && Instant.now().isBefore(cachedTokenExpiry)) {
            return cachedToken;
        }

        PrivateKey privateKey = loadPrivateKey(privateKeyPath);

        Instant now = Instant.now();
        Instant expiry = now.plus(Duration.ofDays(165)); // ~5.5 months

        String token = Jwts.builder()
                .setHeaderParam("alg", "ES256")
                .setHeaderParam("kid", keyId)
                .setIssuer(teamId)
                .setIssuedAt(Date.from(now))
                .setExpiration(Date.from(expiry))
                .signWith(privateKey, SignatureAlgorithm.ES256)
                .compact();

        this.cachedToken = token;
        this.cachedTokenExpiry = expiry;
        return token;
    }

    private PrivateKey loadPrivateKey(String path) throws IOException, Exception {
        String pem = Files.readString(Path.of(path));
        String cleaned = pem
                .replace("-----BEGIN PRIVATE KEY-----", "")
                .replace("-----END PRIVATE KEY-----", "")
                .replaceAll("\\s", "");

        byte[] decoded = Base64.getDecoder().decode(cleaned);
        PKCS8EncodedKeySpec keySpec = new PKCS8EncodedKeySpec(decoded);
        KeyFactory keyFactory = KeyFactory.getInstance("EC");
        return keyFactory.generatePrivate(keySpec);
    }
}