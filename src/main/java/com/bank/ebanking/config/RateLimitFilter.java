package com.bank.ebanking.config;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Filtre de rate limiting sur /auth/login.
 * Bloque une IP après 5 tentatives échouées en 60 secondes.
 *
 * Note: Pour une prod robuste, utiliser Redis à la place de ConcurrentHashMap
 * (pas persistant au redémarrage, pas distribué multi-instance).
 */
@Component
public class RateLimitFilter extends OncePerRequestFilter {

    private static final int    MAX_ATTEMPTS  = 5;
    private static final long   WINDOW_MS     = 60_000L; // 60 secondes

    // IP → [nb tentatives, timestamp première tentative]
    private final Map<String, long[]> attempts = new ConcurrentHashMap<>();

    @SuppressWarnings("null")
    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain)
            throws ServletException, IOException {

        // Appliquer uniquement sur POST /auth/login
        if (!request.getMethod().equals("POST") ||
            !request.getRequestURI().contains("/auth/login")) {
            chain.doFilter(request, response);
            return;
        }

        String ip = getClientIp(request);
        long now  = Instant.now().toEpochMilli();

        attempts.compute(ip, (key, val) -> {
            if (val == null || (now - val[1]) > WINDOW_MS) {
                // Première tentative ou fenêtre expirée → reset
                return new long[]{1, now};
            }
            val[0]++; // incrémenter le compteur
            return val;
        });

        long[] data = attempts.get(ip);
        if (data[0] > MAX_ATTEMPTS) {
            long retryAfter = (WINDOW_MS - (now - data[1])) / 1000;
            response.setContentType("application/json");
            response.setStatus(429); // Too Many Requests
            response.setHeader("Retry-After", String.valueOf(retryAfter));
            response.getWriter().write(String.format(
                "{\"error\":\"Too many login attempts\",\"retryAfterSeconds\":%d}",
                retryAfter
            ));
            return;
        }

        chain.doFilter(request, response);
    }

    private String getClientIp(HttpServletRequest request) {
        // Respecter les headers proxy
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isEmpty()) {
            return forwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}