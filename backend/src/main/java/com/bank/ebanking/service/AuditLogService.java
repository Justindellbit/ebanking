package com.bank.ebanking.service;

import com.bank.ebanking.entity.AuditLog;
//import com.bank.ebanking.entity.User;
import com.bank.ebanking.repository.AuditLogRepository;
import com.bank.ebanking.repository.UserRepository;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Service;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

@Service
public class AuditLogService {

    private final AuditLogRepository auditLogRepository;
    private final UserRepository     userRepository;

    public AuditLogService(AuditLogRepository auditLogRepository,
                           UserRepository userRepository) {
        this.auditLogRepository = auditLogRepository;
        this.userRepository     = userRepository;
    }

    // ─── Logger une action ────────────────────────────────
    public void log(String username, String action, String description) {
        try {
            AuditLog log = new AuditLog();

            // Retrouver l'utilisateur
            userRepository.findByUsername(username).ifPresent(log::setUser);

            log.setAction(action);
            log.setDescription(description);

            // Extraire IP et device depuis la requête HTTP courante
            HttpServletRequest request = getCurrentRequest();
            if (request != null) {
                log.setIpAddress(getClientIp(request));
                log.setDeviceInfo(request.getHeader("User-Agent"));
            }

            auditLogRepository.save(log);
        } catch (Exception e) {
            // Ne jamais faire planter l'app à cause d'un log raté
            System.err.println("AuditLog failed: " + e.getMessage());
        }
    }

    // ─── Surcharge sans username (actions système) ────────
    public void log(String action, String description) {
        log("system", action, description);
    }

    // ─── Helpers ──────────────────────────────────────────
    private HttpServletRequest getCurrentRequest() {
        try {
            ServletRequestAttributes attrs =
                (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            return attrs != null ? attrs.getRequest() : null;
        } catch (Exception e) {
            return null;
        }
    }

    private String getClientIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isEmpty()) {
            return forwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}