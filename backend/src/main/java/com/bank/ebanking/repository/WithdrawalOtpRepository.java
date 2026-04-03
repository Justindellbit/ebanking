// ─── WithdrawalOtpRepository.java ────────────────────────
package com.bank.ebanking.repository;

import com.bank.ebanking.entity.WithdrawalOtp;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface WithdrawalOtpRepository extends JpaRepository<WithdrawalOtp, Long> {

    // Trouver un OTP valide (non utilisé, non expiré)
    @Query("SELECT o FROM WithdrawalOtp o WHERE o.otpCode = :code " +
           "AND o.used = false AND o.expiresAt > :now")
    Optional<WithdrawalOtp> findValidOtp(String code, LocalDateTime now);

    // Invalider les anciens OTPs d'un compte avant d'en générer un nouveau
    @Query("SELECT o FROM WithdrawalOtp o WHERE o.account.id = :accountId " +
           "AND o.used = false AND o.expiresAt > :now")
    List<WithdrawalOtp> findActiveOtpForAccount(Long accountId, LocalDateTime now);
}