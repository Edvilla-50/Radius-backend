package com.Radius.backend.Music;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.security.KeyFactory;
import java.security.PrivateKey;
import java.security.spec.PKCS8EncodedKeySpec;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.Date;

@Service
public class MusicKitTokenService {

    @Value("${musickit.team-id}")
    private String teamId;

    @Value("${musickit.key-id}")
    private String keyId;

    @Value("${musickit.private-key}")
    private String privateKeyContents;

    private String cachedToken;
    private Instant cachedTokenExpiry;

    public synchronized String getDeveloperToken() throws Exception {

        if (cachedToken != null
                && cachedTokenExpiry != null
                && Instant.now().isBefore(cachedTokenExpiry)) {
            return cachedToken;
        }

        PrivateKey privateKey = loadPrivateKey(privateKeyContents);

        Instant now = Instant.now();
        Instant expiry = now.plus(Duration.ofDays(165));

        String token = Jwts.builder()
                .setHeaderParam("alg", "ES256")
                .setHeaderParam("kid", keyId)
                .setIssuer(teamId)
                .setIssuedAt(Date.from(now))
                .setExpiration(Date.from(expiry))
                .claim("origin", new String[] {
                        "https://www.radius-create.com"
                })
                .signWith(privateKey, SignatureAlgorithm.ES256)
                .compact();

        cachedToken = token;
        cachedTokenExpiry = expiry;

        return token;
    }

    private PrivateKey loadPrivateKey(String pemContents) throws Exception {

        if (pemContents == null || pemContents.isBlank()) {
            throw new IllegalStateException(
                    "MUSICKIT_PRIVATE_KEY is missing or empty"
            );
        }

        String normalized = pemContents
                .replace("\\n", "\n")
                .replace("\r\n", "\n")
                .replace("\r", "\n")
                .trim();

        String cleaned = normalized
                .replace("-----BEGIN PRIVATE KEY-----", "")
                .replace("-----END PRIVATE KEY-----", "")
                .replaceAll("\\s", "");

        byte[] decoded = Base64.getDecoder().decode(cleaned);

        PKCS8EncodedKeySpec keySpec =
                new PKCS8EncodedKeySpec(decoded);

        KeyFactory keyFactory =
                KeyFactory.getInstance("EC");

        return keyFactory.generatePrivate(keySpec);
    }
}