package com.bank.ebanking.controller;

import com.bank.ebanking.dto.TransactionDTO;
import com.bank.ebanking.dto.WithdrawalOtpDTO;
import com.bank.ebanking.service.TransactionService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;

@RestController
@RequestMapping("/api/transactions")
@CrossOrigin(origins = "*")
public class TransactionController {

    private final TransactionService transactionService;

    public TransactionController(TransactionService transactionService) {
        this.transactionService = transactionService;
    }

    // ── DÉPÔT — TELLER ou ADMIN seulement ────────────────
    @PostMapping("/deposit/{accountId}")
    @PreAuthorize("hasAnyRole('TELLER', 'ADMIN')")
    public ResponseEntity<TransactionDTO> deposit(
            @PathVariable Long accountId,
            @RequestParam BigDecimal amount,
            @RequestParam(required = false) String description) {

        String tellerUsername = getCurrentUsername();
        TransactionDTO tx = transactionService.deposit(
                accountId, amount, description, tellerUsername);
        return ResponseEntity.ok(tx);
    }

    // ── RETRAIT ÉTAPE 1 : CLIENT génère un OTP ────────────
    @PostMapping("/withdrawal/request/{accountId}")
    @PreAuthorize("hasAnyRole('CLIENT', 'ADMIN')")
    public ResponseEntity<WithdrawalOtpDTO> requestWithdrawal(
            @PathVariable Long accountId,
            @RequestParam BigDecimal amount) {

        String clientUsername = getCurrentUsername();
        WithdrawalOtpDTO otp = transactionService.generateWithdrawalOtp(
                accountId, amount, clientUsername);
        return ResponseEntity.ok(otp);
    }

    // ── RETRAIT ÉTAPE 2 : valider l'OTP ──────────────────
    // CLIENT peut valider lui-même (retrait DAB) ou TELLER valide en agence
    @PostMapping("/withdrawal/validate")
    @PreAuthorize("hasAnyRole('CLIENT', 'TELLER', 'ADMIN')")
    public ResponseEntity<TransactionDTO> validateWithdrawal(
            @RequestParam String otpCode) {

        String username = getCurrentUsername();
        TransactionDTO tx = transactionService.validateWithdrawalOtp(
                otpCode, username);
        return ResponseEntity.ok(tx);
    }

    // ── VIREMENT — CLIENT ou ADMIN ────────────────────────
    @PostMapping("/transfer/{fromAccountId}")
    @PreAuthorize("hasAnyRole('CLIENT', 'ADMIN')")
    public ResponseEntity<TransactionDTO> transfer(
            @PathVariable Long fromAccountId,
            @RequestParam String toAccountNumber,
            @RequestParam BigDecimal amount,
            @RequestParam(required = false) String description) {

        String clientUsername = getCurrentUsername();
        TransactionDTO tx = transactionService.transfer(
                fromAccountId, toAccountNumber, amount, description, clientUsername);
        return ResponseEntity.ok(tx);
    }

    // ── HISTORIQUE — tous les rôles ───────────────────────
    @GetMapping("/history/{accountId}")
    @PreAuthorize("hasAnyRole('CLIENT', 'TELLER', 'ADMIN')")
    public ResponseEntity<List<TransactionDTO>> getHistory(
            @PathVariable Long accountId) {
        return ResponseEntity.ok(
                transactionService.getTransactionsByAccountId(accountId));
    }

    // ─────────────────────────────────────────────────────
    private String getCurrentUsername() {
        return (String) SecurityContextHolder
                .getContext().getAuthentication().getPrincipal();
    }
}