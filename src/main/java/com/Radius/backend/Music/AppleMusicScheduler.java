package com.Radius.backend.Music;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class AppleMusicScheduler {

    private final MusicSnippetRepository repository;
    private final MusicSnippetController controller;

    public AppleMusicScheduler(
            MusicSnippetRepository repository,
            MusicSnippetController controller
    ) {
        this.repository = repository;
        this.controller = controller;
    }

    @Scheduled(fixedRate = 30000)
    public void refreshAppleMusic() {

        List<MusicSnippet> snippets = repository.findAll();

        for (MusicSnippet snippet : snippets) {

            if (snippet.getAppleMusicUserToken() == null
                    || snippet.getAppleMusicUserToken().isBlank()) {
                continue;
            }

            try {
                controller.refreshFromApple(snippet);
                repository.save(snippet);

                System.out.println(
                        "Apple Music refreshed for user "
                                + snippet.getUserId()
                                + ": "
                                + snippet.getTrackName()
                );

            } catch (Exception e) {
                System.err.println(
                        "Apple Music refresh failed for user "
                                + snippet.getUserId()
                                + ": "
                                + e.getMessage()
                );
            }
        }
    }
}
