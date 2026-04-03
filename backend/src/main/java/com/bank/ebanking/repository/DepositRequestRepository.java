// ─── DepositRequestRepository.java ───────────────────────
package com.bank.ebanking.repository;

import com.bank.ebanking.entity.DepositRequest;
import org.springframework.data.jpa.repository.JpaRepository;
//import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface DepositRequestRepository extends JpaRepository<DepositRequest, Long> {

    // Toutes les demandes PENDING — pour le dashboard TELLER
    List<DepositRequest> findByStatusOrderByCreatedAtAsc(String status);

    // Demandes d'un compte spécifique
    List<DepositRequest> findByAccountIdOrderByCreatedAtDesc(Long accountId);
}