package com.Radius.backend.Entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "user_blocks", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"blocker_id", "blocked_id"})
})
public class UserBlock {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "blocker_id", nullable = false)
    private Long blockerId;

    @Column(name = "blocked_id", nullable = false)
    private Long blockedId;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    public UserBlock() {}

    public UserBlock(Long blockerId, Long blockedId) {
        this.blockerId = blockerId;
        this.blockedId = blockedId;
        this.createdAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public Long getBlockerId() { return blockerId; }
    public Long getBlockedId() { return blockedId; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}