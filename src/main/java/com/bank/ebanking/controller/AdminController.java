package com.bank.ebanking.controller;

import com.bank.ebanking.dto.AccountDTO;
import com.bank.ebanking.dto.AuditLogDTO;
import com.bank.ebanking.dto.UserAdminDTO;
import com.bank.ebanking.service.AdminService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin")
@CrossOrigin(origins = "*")
@PreAuthorize("hasRole('ADMIN')") // ← Tout le controller réservé ADMIN
public class AdminController {

    private final AdminService adminService;

    public AdminController(AdminService adminService) {
        this.adminService = adminService;
    }

    // ── Tous les utilisateurs ─────────────────────────────
    @GetMapping("/users")
    public ResponseEntity<List<UserAdminDTO>> getAllUsers() {
        return ResponseEntity.ok(adminService.getAllUsers());
    }

    // ── Tous les comptes ──────────────────────────────────
    @GetMapping("/accounts")
    public ResponseEntity<List<AccountDTO>> getAllAccounts() {
        return ResponseEntity.ok(adminService.getAllAccounts());
    }

    // ── Bloquer un compte ─────────────────────────────────
    @PostMapping("/accounts/{accountId}/block")
    public ResponseEntity<AccountDTO> blockAccount(
            @PathVariable Long accountId) {
        String admin = getCurrentUsername();
        return ResponseEntity.ok(adminService.blockAccount(accountId, admin));
    }

    // ── Débloquer un compte ───────────────────────────────
    @PostMapping("/accounts/{accountId}/unblock")
    public ResponseEntity<AccountDTO> unblockAccount(
            @PathVariable Long accountId) {
        String admin = getCurrentUsername();
        return ResponseEntity.ok(
                adminService.unblockAccount(accountId, admin));
    }

    // ── Logs d'audit ──────────────────────────────────────
    @GetMapping("/audit-logs")
    public ResponseEntity<List<AuditLogDTO>> getAuditLogs() {
        return ResponseEntity.ok(adminService.getAuditLogs());
    }

    private String getCurrentUsername() {
        return (String) SecurityContextHolder
                .getContext().getAuthentication().getPrincipal();
    }
}