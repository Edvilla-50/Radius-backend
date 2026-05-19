package com.Radius.backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@EnableScheduling
@SpringBootApplication
public class RadiusApplication {

    public static void main(String[] args) {
        SpringApplication.run(RadiusApplication.class, args);
    }
}
