
package com.bank.ebanking.repository;

import com.bank.ebanking.entity.AuditLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface AuditLogRepository extends JpaRepository<AuditLog, Long> {

    // Les 100 derniers logs — pour éviter de tout charger
    List<AuditLog> findAllByOrderByCreatedAtDesc(Pageable pageable);
}