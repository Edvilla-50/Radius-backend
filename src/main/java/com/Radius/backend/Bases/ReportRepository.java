package com.Radius.backend.Bases;

import com.Radius.backend.Entity.Report;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ReportRepository extends JpaRepository<Report, Integer> {
    List<Report> findByReportedUserId(int reportedUserId);
    List<Report> findByReporterId(int reporterId);

    // Useful later if you ever want a "this user has X reports" check
    long countByReportedUserId(int reportedUserId);
}