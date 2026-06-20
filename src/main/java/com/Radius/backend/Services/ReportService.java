package com.Radius.backend.Services;

import com.Radius.backend.Bases.ReportRepository;
import com.Radius.backend.Entity.Report;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class ReportService {

    @Autowired
    private ReportRepository repo;

    public Report createReport(int reporterId, int reportedUserId, String reason, String details) {
        // Prevent users from reporting themselves
        if (reporterId == reportedUserId) {
            throw new IllegalArgumentException("Cannot report yourself");
        }

        Report report = new Report(reporterId, reportedUserId, reason, details);
        return repo.save(report);
    }
}