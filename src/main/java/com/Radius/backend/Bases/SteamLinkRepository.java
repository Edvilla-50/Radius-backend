package com.Radius.backend.Bases;   // match your other repositories

import com.Radius.backend.Entity.SteamLink;   // adjust to where SteamLink lives
import org.springframework.data.jpa.repository.JpaRepository;

public interface SteamLinkRepository extends JpaRepository<SteamLink, Long> {}