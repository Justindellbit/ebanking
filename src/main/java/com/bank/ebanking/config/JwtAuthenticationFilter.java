package com.bank.ebanking.config;

import com.bank.ebanking.repository.UserRepository;
//import com.bank.ebanking.repository.RoleRepository;
import com.bank.ebanking.util.JwtUtil;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;
import java.util.stream.Collectors;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtUtil        jwtUtil;
    private final UserRepository userRepository;

    public JwtAuthenticationFilter(JwtUtil jwtUtil, UserRepository userRepository) {
        this.jwtUtil        = jwtUtil;
        this.userRepository = userRepository;
    }

    @SuppressWarnings("null")
    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain)
            throws ServletException, IOException {

        String header = request.getHeader("Authorization");

        if (header == null || !header.startsWith("Bearer ")) {
            chain.doFilter(request, response);
            return;
        }

        String token = header.substring(7);

        try {
            if (!jwtUtil.isTokenValid(token)) {
                chain.doFilter(request, response);
                return;
            }

            String username = jwtUtil.extractUsername(token);

            if (username != null &&
                SecurityContextHolder.getContext().getAuthentication() == null) {

                // ── Charger les rôles depuis la DB ────────────────
                // Charger les rôles via requête dédiée (évite LazyInitializationException)
                List<SimpleGrantedAuthority> authorities = userRepository
                        .findByUsernameWithRoles(username)
                        .map(user -> user.getRoles() != null
                                ? user.getRoles().stream()
                                        .map(role -> new SimpleGrantedAuthority(
                                                role.getName()))
                                        .collect(Collectors.toList())
                                : List.<SimpleGrantedAuthority>of())
                        .orElse(List.of());

                UsernamePasswordAuthenticationToken auth =
                        new UsernamePasswordAuthenticationToken(
                                username, null, authorities);

                SecurityContextHolder.getContext().setAuthentication(auth);
            }

        } catch (Exception e) {
            // Token invalide → laisser passer sans authentification
            SecurityContextHolder.clearContext();
        }

        chain.doFilter(request, response);
    }
}