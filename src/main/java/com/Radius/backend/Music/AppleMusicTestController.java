
package com.Radius.backend.Music;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

@RestController
public class AppleMusicTestController {

    @Autowired
    private MusicKitTokenService tokenService;

    @GetMapping("/api/music/test-token")
    public ResponseEntity<String> testToken() {

        try {
            String developerToken =
                    tokenService.getDeveloperToken();

            HttpHeaders headers = new HttpHeaders();

            headers.set(
                    "Authorization",
                    "Bearer " + developerToken
            );

            HttpEntity<Void> entity =
                    new HttpEntity<>(headers);

            RestTemplate restTemplate =
                    new RestTemplate();

            String url =
                    "https://api.music.apple.com/v1/catalog/us/search" +
                    "?term=Taylor%20Swift&types=songs&limit=1";

            ResponseEntity<String> response =
                    restTemplate.exchange(
                            url,
                            HttpMethod.GET,
                            entity,
                            String.class
                    );

            return ResponseEntity
                    .status(response.getStatusCode())
                    .body(response.getBody());

        } catch (Exception e) {

            return ResponseEntity
                    .status(500)
                    .body(
                            "ERROR: " +
                            e.getClass().getName() +
                            " - " +
                            e.getMessage()
                    );
        }
    }
}
