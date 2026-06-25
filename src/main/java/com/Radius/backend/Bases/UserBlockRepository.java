package com.Radius.backend.Bases;

import com.Radius.backend.Entity.UserBlock;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface UserBlockRepository extends JpaRepository<UserBlock, Long> {
    boolean existsByBlockerIdAndBlockedId(Long blockerId, Long blockedId);
    List<UserBlock> findByBlockerId(Long blockerId);
    List<UserBlock> findByBlockedId(Long blockedId);
}