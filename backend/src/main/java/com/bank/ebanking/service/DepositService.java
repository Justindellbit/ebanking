package com.bank.ebanking.service;

import com.bank.ebanking.dto.DepositRequestDTO;
import com.bank.ebanking.entity.Account;
import com.bank.ebanking.entity.DepositRequest;
import com.bank.ebanking.entity.Transaction;
import com.bank.ebanking.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class DepositService {

    private final DepositRequestRepository depositRequestRepository;
    private final AccountRepository        accountRepository;
    private final TransactionRepository    transactionRepository;
    private final UserRepository           userRepository;
    private final AuditLogService          auditLogService;

    public DepositService(DepositRequestRepository depositRequestRepository,
                          AccountRepository accountRepository,
                          TransactionRepository transactionRepository,
                          UserRepository userRepository,
                          AuditLogService auditLogService) {
        this.depositRequestRepository = depositRequestRepository;
        this.accountRepository        = accountRepository;
        this.transactionRepository    = transactionRepository;
        this.userRepository           = userRepository;
        this.auditLogService          = auditLogService;
    }

    // ─── CLIENT soumet une demande de dépôt ──────────────
    @Transactional
    public DepositRequestDTO createRequest(Long accountId,
                                           java.math.BigDecimal amount,
                                           String description,
                                           String clientUsername) {
        @SuppressWarnings("null")
        Account account = accountRepository.findById(accountId)
                .orElseThrow(() -> new RuntimeException("Account not found"));

        if (!"ACTIVE".equals(account.getStatus())) {
            throw new RuntimeException("Account is not active");
        }
        if (amount == null || amount.compareTo(java.math.BigDecimal.ZERO) <= 0) {
            throw new RuntimeException("Amount must be greater than zero");
        }

        DepositRequest request = new DepositRequest();
        request.setAccount(account);
        request.setAmount(amount);
        request.setDescription(description);
        request.setStatus("PENDING");

        depositRequestRepository.save(request);

        auditLogService.log(clientUsername, "DEPOSIT_REQUEST",
                "Client requested deposit of " + amount +
                " for account " + account.getAccountNumber());

        return toDTO(request);
    }

    // ─── TELLER approuve une demande ─────────────────────
    @SuppressWarnings("null")
    @Transactional
    public DepositRequestDTO approveRequest(Long requestId,
                                             String tellerUsername) {
        DepositRequest request = depositRequestRepository.findById(requestId)
                .orElseThrow(() -> new RuntimeException("Request not found"));

        if (!"PENDING".equals(request.getStatus())) {
            throw new RuntimeException("Request already processed");
        }

        Account account = request.getAccount();

        // Créditer le compte
        account.setBalance(account.getBalance().add(request.getAmount()));
        accountRepository.save(account);

        // Créer la transaction
        Transaction tx = new Transaction();
        tx.setTransId(UUID.randomUUID().toString());
        tx.setAccount(account);
        tx.setAmount(request.getAmount());
        tx.setType("DEPOSIT");
        tx.setDescription(request.getDescription() != null
                ? request.getDescription()
                : "Deposit approved by teller");
        tx.setStatus("COMPLETED");
        transactionRepository.save(tx);

        // Mettre à jour la demande
        request.setStatus("APPROVED");
        request.setProcessedAt(LocalDateTime.now());
        userRepository.findByUsername(tellerUsername)
                .ifPresent(request::setProcessedBy);
        depositRequestRepository.save(request);

        auditLogService.log(tellerUsername, "DEPOSIT_APPROVED",
                "Teller approved deposit of " + request.getAmount() +
                " for account " + account.getAccountNumber());

        return toDTO(request);
    }

    // ─── TELLER rejette une demande ───────────────────────
    @SuppressWarnings("null")
    @Transactional
    public DepositRequestDTO rejectRequest(Long requestId,
                                            String tellerUsername) {
        DepositRequest request = depositRequestRepository.findById(requestId)
                .orElseThrow(() -> new RuntimeException("Request not found"));

        if (!"PENDING".equals(request.getStatus())) {
            throw new RuntimeException("Request already processed");
        }

        request.setStatus("REJECTED");
        request.setProcessedAt(LocalDateTime.now());
        userRepository.findByUsername(tellerUsername)
                .ifPresent(request::setProcessedBy);
        depositRequestRepository.save(request);

        auditLogService.log(tellerUsername, "DEPOSIT_REJECTED",
                "Teller rejected deposit of " + request.getAmount() +
                " for account " + request.getAccount().getAccountNumber());

        return toDTO(request);
    }

    // ─── Liste toutes les demandes PENDING (pour TELLER) ──
    public List<DepositRequestDTO> getPendingRequests() {
        return depositRequestRepository
                .findByStatusOrderByCreatedAtAsc("PENDING")
                .stream().map(this::toDTO).collect(Collectors.toList());
    }

    // ─── Historique des demandes d'un compte (CLIENT) ─────
    public List<DepositRequestDTO> getRequestsByAccount(Long accountId) {
        return depositRequestRepository
                .findByAccountIdOrderByCreatedAtDesc(accountId)
                .stream().map(this::toDTO).collect(Collectors.toList());
    }

    // ─── Helper ───────────────────────────────────────────
    private DepositRequestDTO toDTO(DepositRequest r) {
        DepositRequestDTO dto = new DepositRequestDTO();
        dto.setId(r.getId());
        dto.setAccountId(r.getAccount().getId());
        dto.setAccountNumber(r.getAccount().getAccountNumber());
        dto.setAmount(r.getAmount());
        dto.setDescription(r.getDescription());
        dto.setStatus(r.getStatus());
        dto.setCreatedAt(r.getCreatedAt());
        dto.setProcessedAt(r.getProcessedAt());

        // Nom du client
        if (r.getAccount().getUser() != null) {
            dto.setClientName(
                r.getAccount().getUser().getFirstName() + " " +
                r.getAccount().getUser().getLastName()
            );
        }

        if (r.getProcessedBy() != null) {
            dto.setProcessedBy(r.getProcessedBy().getUsername());
        }

        return dto;
    }
}