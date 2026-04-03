package com.bank.ebanking.controller;

import com.bank.ebanking.dto.DepositRequestDTO;
import com.bank.ebanking.service.DepositService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;

@RestController
@RequestMapping("/api/deposits")
@CrossOrigin(origins = "*")
public class DepositController {

    private final DepositService depositService;

    public DepositController(DepositService depositService) {
        this.depositService = depositService;
    }

    // ── CLIENT soumet une demande de dépôt ───────────────
    @PostMapping("/request/{accountId}")
    @PreAuthorize("hasAnyRole('CLIENT', 'ADMIN')")
    public ResponseEntity<DepositRequestDTO> requestDeposit(
            @PathVariable Long accountId,
            @RequestParam BigDecimal amount,
            @RequestParam(required = false) String description) {

        String username = getCurrentUsername();
        DepositRequestDTO dto = depositService.createRequest(
                accountId, amount, description, username);
        return ResponseEntity.ok(dto);
    }

    // ── TELLER : liste toutes les demandes PENDING ───────
    @GetMapping("/pending")
    @PreAuthorize("hasAnyRole('TELLER', 'ADMIN')")
    public ResponseEntity<List<DepositRequestDTO>> getPending() {
        return ResponseEntity.ok(depositService.getPendingRequests());
    }

    // ── TELLER : approuver une demande ───────────────────
    @PostMapping("/approve/{requestId}")
    @PreAuthorize("hasAnyRole('TELLER', 'ADMIN')")
    public ResponseEntity<DepositRequestDTO> approve(
            @PathVariable Long requestId) {

        String username = getCurrentUsername();
        return ResponseEntity.ok(
                depositService.approveRequest(requestId, username));
    }

    // ── TELLER : rejeter une demande ─────────────────────
    @PostMapping("/reject/{requestId}")
    @PreAuthorize("hasAnyRole('TELLER', 'ADMIN')")
    public ResponseEntity<DepositRequestDTO> reject(
            @PathVariable Long requestId) {

        String username = getCurrentUsername();
        return ResponseEntity.ok(
                depositService.rejectRequest(requestId, username));
    }

    // ── CLIENT : historique des demandes d'un compte ─────
    @GetMapping("/history/{accountId}")
    @PreAuthorize("hasAnyRole('CLIENT', 'TELLER', 'ADMIN')")
    public ResponseEntity<List<DepositRequestDTO>> getHistory(
            @PathVariable Long accountId) {
        return ResponseEntity.ok(
                depositService.getRequestsByAccount(accountId));
    }

    private String getCurrentUsername() {
        return (String) SecurityContextHolder
                .getContext().getAuthentication().getPrincipal();
    }
}