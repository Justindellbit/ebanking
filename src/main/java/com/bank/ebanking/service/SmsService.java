package com.bank.ebanking.service;

import com.bank.ebanking.entity.SmsOtp;
import com.bank.ebanking.entity.User;
import com.bank.ebanking.repository.SmsOtpRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Optional;

@Service
public class SmsService {

    private static final Logger log = LoggerFactory.getLogger(SmsService.class);
    private static final int CODE_EXPIRY_MINUTES = 5;

    private final SmsOtpRepository smsOtpRepository;

    public SmsService(SmsOtpRepository smsOtpRepository) {
        this.smsOtpRepository = smsOtpRepository;
    }

    // ─── Générer et "envoyer" le code SMS ────────────────
    @Transactional
    public void sendSmsCode(User user) {
        // Invalider les anciens codes
        smsOtpRepository.invalidateAllForUser(user.getId());

        // Générer un nouveau code 6 chiffres
        String code = generateCode();

        // Sauvegarder en DB
        SmsOtp otp = new SmsOtp();
        otp.setUser(user);
        otp.setCode(code);
        otp.setExpiresAt(LocalDateTime.now().plusMinutes(CODE_EXPIRY_MINUTES));
        smsOtpRepository.save(otp);

        // ── SIMULATION SMS ────────────────────────────────
        // En production → remplacer par appel API Twilio :
        // twilioClient.messages.create(user.getPhone(), FROM_NUMBER, "Your code: " + code);
        // ─────────────────────────────────────────────────
        log.info("╔══════════════════════════════════════╗");
        log.info("║  SMS CODE for @{}  ", user.getUsername());
        log.info("║  Code: {}  (valid {} min)            ", code, CODE_EXPIRY_MINUTES);
        log.info("║  Phone: {}  ", maskPhone(user.getPhone()));
        log.info("╚══════════════════════════════════════╝");
    }

    // ─── Vérifier le code soumis ─────────────────────────
    @Transactional
    public boolean verifyCode(User user, String code) {
        Optional<SmsOtp> otpOpt = smsOtpRepository.findValidCode(
                user.getId(), code, LocalDateTime.now());

        if (otpOpt.isEmpty()) return false;

        // Marquer comme utilisé
        SmsOtp otp = otpOpt.get();
        otp.setUsed(true);
        smsOtpRepository.save(otp);

        return true;
    }

    // ─── Helpers ─────────────────────────────────────────
    private String generateCode() {
        SecureRandom random = new SecureRandom();
        int code = 100000 + random.nextInt(900000);
        return String.valueOf(code);
    }

    private String maskPhone(String phone) {
        if (phone == null || phone.length() < 4) return "****";
        return "****" + phone.substring(phone.length() - 4);
    }
}