package com.Radius.backend.Music;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * Serves the MusicKit developer token to the browser so MusicKit JS can
 * initialize. This token only identifies the Radius app to Apple's catalog —
 * it contains no secret key material, so it's safe to expose publicly.
 */
@RestController
public class MusicKitDevTokenController {

    @Autowired
    private MusicKitTokenService tokenService;

    @GetMapping("/api/music/dev-token")
    public Map<String, String> getDevToken() throws Exception {
        return Map.of("token", tokenService.getDeveloperToken());
    }
}