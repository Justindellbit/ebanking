package com.bank.ebanking.service;

import com.bank.ebanking.dto.AccountDTO;
import com.bank.ebanking.dto.AuditLogDTO;
import com.bank.ebanking.dto.UserAdminDTO;
import com.bank.ebanking.entity.Account;
import com.bank.ebanking.entity.AuditLog;
import com.bank.ebanking.entity.User;
import com.bank.ebanking.repository.AccountRepository;
import com.bank.ebanking.repository.AuditLogRepository;
import com.bank.ebanking.repository.UserRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class AdminService {

    private final UserRepository     userRepository;
    private final AccountRepository  accountRepository;
    private final AuditLogRepository auditLogRepository;
    private final AuditLogService    auditLogService;

    public AdminService(UserRepository userRepository,
                        AccountRepository accountRepository,
                        AuditLogRepository auditLogRepository,
                        AuditLogService auditLogService) {
        this.userRepository     = userRepository;
        this.accountRepository  = accountRepository;
        this.auditLogRepository = auditLogRepository;
        this.auditLogService    = auditLogService;
    }

    // ─── Tous les utilisateurs avec leurs rôles ───────────
    public List<UserAdminDTO> getAllUsers() {
        return userRepository.findAll().stream()
                .map(this::toUserDTO)
                .collect(Collectors.toList());
    }

    // ─── Tous les comptes ─────────────────────────────────
    public List<AccountDTO> getAllAccounts() {
        return accountRepository.findAll().stream()
                .map(this::toAccountDTO)
                .collect(Collectors.toList());
    }

    // ─── Bloquer un compte ────────────────────────────────
    @Transactional
    public AccountDTO blockAccount(Long accountId, String adminUsername) {
        @SuppressWarnings("null")
        Account account = accountRepository.findById(accountId)
                .orElseThrow(() -> new RuntimeException("Account not found"));

        account.setStatus("BLOCKED");
        accountRepository.save(account);

        auditLogService.log(adminUsername, "ACCOUNT_BLOCKED",
                "Admin blocked account " + account.getAccountNumber());

        return toAccountDTO(account);
    }

    // ─── Débloquer un compte ──────────────────────────────
    @Transactional
    public AccountDTO unblockAccount(Long accountId, String adminUsername) {
        @SuppressWarnings("null")
        Account account = accountRepository.findById(accountId)
                .orElseThrow(() -> new RuntimeException("Account not found"));

        account.setStatus("ACTIVE");
        accountRepository.save(account);

        auditLogService.log(adminUsername, "ACCOUNT_UNBLOCKED",
                "Admin unblocked account " + account.getAccountNumber());

        return toAccountDTO(account);
    }

    // ─── Logs d'audit (100 derniers) ──────────────────────
    public List<AuditLogDTO> getAuditLogs() {
        return auditLogRepository
                .findAllByOrderByCreatedAtDesc(PageRequest.of(0, 100))
                .stream()
                .map(this::toAuditDTO)
                .collect(Collectors.toList());
    }

    // ─── Helpers ──────────────────────────────────────────
    private UserAdminDTO toUserDTO(User user) {
        UserAdminDTO dto = new UserAdminDTO();
        dto.setId(user.getId());
        dto.setUsername(user.getUsername());
        dto.setEmail(user.getEmail());
        dto.setFirstName(user.getFirstName());
        dto.setLastName(user.getLastName());
        dto.setPhone(user.getPhone());
        dto.setFa2Enabled(user.getFa2Enabled());
        dto.setCreatedAt(user.getCreatedAt() != null
                ? user.getCreatedAt().toString() : "");

        // Rôles
        if (user.getRoles() != null) {
            dto.setRoles(user.getRoles().stream()
                    .map(r -> r.getName())
                    .collect(Collectors.toList()));
        }

        // Nombre de comptes
        if (user.getAccounts() != null) {
            dto.setAccountCount(user.getAccounts().size());
        }

        return dto;
    }

    private AccountDTO toAccountDTO(Account account) {
        AccountDTO dto = new AccountDTO();
        dto.setId(account.getId());
        dto.setAccountNumber(account.getAccountNumber());
        dto.setAccountType(account.getAccountType());
        dto.setBalance(account.getBalance());
        dto.setCurrency(account.getCurrency());
        dto.setStatus(account.getStatus());
        dto.setCreatedAt(account.getCreatedAt());
        if (account.getUser() != null) {
            dto.setUserId(account.getUser().getId());
        }
        return dto;
    }

    private AuditLogDTO toAuditDTO(AuditLog log) {
        AuditLogDTO dto = new AuditLogDTO();
        dto.setId(log.getId());
        dto.setUsername(log.getUser() != null
                ? log.getUser().getUsername() : "system");
        dto.setAction(log.getAction());
        dto.setDescription(log.getDescription());
        dto.setIpAddress(log.getIpAddress());
        dto.setDeviceInfo(log.getDeviceInfo());
        dto.setCreatedAt(log.getCreatedAt() != null
                ? log.getCreatedAt().toString() : "");
        return dto;
    }
}