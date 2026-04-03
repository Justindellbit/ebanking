package com.bank.ebanking.controller;

import com.bank.ebanking.dto.JwtResponse;
import com.bank.ebanking.dto.LoginRequest;
import com.bank.ebanking.dto.RegisterRequest;
import com.bank.ebanking.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest request) {
        String message = authService.register(request);
        return ResponseEntity.ok().body(message);
    }

    @PostMapping("/login")
    public ResponseEntity<JwtResponse> login(@Valid @RequestBody LoginRequest request) {
        JwtResponse response = authService.login(request);
        return ResponseEntity.ok(response);
    }

    // ── Vérification code SMS 2FA ─────────────────────────
    @PostMapping("/verify-sms")
    public ResponseEntity<?> verifySms(@RequestBody Map<String, String> body) {
        String username = body.get("username");
        String code     = body.get("code");

        if (username == null || code == null) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "username and code are required"));
        }

        try {
            JwtResponse response = authService.verifySmsCode(username, code);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.status(401)
                    .body(Map.of("error", e.getMessage()));
        }
    }
}