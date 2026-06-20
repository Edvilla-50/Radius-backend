package com.Radius.backend.controllers;

import com.Radius.backend.Entity.Report;
import com.Radius.backend.Services.ReportService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/reports")
public class ReportController {

    @Autowired
    private ReportService reportService;

    @PostMapping("/submit")
    public ResponseEntity<?> submitReport(@RequestBody Map<String, Object> body) {
        try {
            int reporterId = ((Number) body.get("reporterId")).intValue();
            int reportedUserId = ((Number) body.get("reportedUserId")).intValue();
            String reason = (String) body.get("reason");
            String details = (String) body.getOrDefault("details", "");

            Report saved = reportService.createReport(reporterId, reportedUserId, reason, details);
            return ResponseEntity.ok(saved);

        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("error", "Failed to submit report"));
        }
    }
}