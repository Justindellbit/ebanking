
// ─── SmsOtpRepository.java ────────────────────────────────
package com.bank.ebanking.repository;

import com.bank.ebanking.entity.SmsOtp;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

import java.time.LocalDateTime;
import java.util.Optional;

public interface SmsOtpRepository extends JpaRepository<SmsOtp, Long> {

    // Trouver le code valide pour un user
    @Query("SELECT o FROM SmsOtp o WHERE o.user.id = :userId " +
           "AND o.code = :code AND o.used = false AND o.expiresAt > :now")
    Optional<SmsOtp> findValidCode(Long userId, String code, LocalDateTime now);

    // Invalider tous les anciens codes d'un user avant d'en générer un nouveau
    @Modifying
    @Query("UPDATE SmsOtp o SET o.used = true WHERE o.user.id = :userId AND o.used = false")
    void invalidateAllForUser(Long userId);
}