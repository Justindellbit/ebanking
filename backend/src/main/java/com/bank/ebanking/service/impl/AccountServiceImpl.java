package com.bank.ebanking.service.impl;

import com.bank.ebanking.dto.AccountDTO;
import com.bank.ebanking.dto.AccountUpdateDTO;
import com.bank.ebanking.entity.Account;
import com.bank.ebanking.entity.User;
import com.bank.ebanking.repository.AccountRepository;
import com.bank.ebanking.repository.UserRepository;
import com.bank.ebanking.service.AccountService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class AccountServiceImpl implements AccountService {

    private final AccountRepository accountRepository;
    private final UserRepository userRepository;

    public AccountServiceImpl(AccountRepository accountRepository, UserRepository userRepository) {
        this.accountRepository = accountRepository;
        this.userRepository = userRepository;
    }

    private String generateAccountNumber() {
        return "BNK" + UUID.randomUUID().toString().replace("-", "").substring(0, 12).toUpperCase();
    }

    private AccountDTO convertToDTO(Account account) {
        AccountDTO dto = new AccountDTO();
        dto.setId(account.getId());
        dto.setAccountNumber(account.getAccountNumber());
        dto.setAccountType(account.getAccountType());
        dto.setBalance(account.getBalance());
        dto.setCurrency(account.getCurrency());
        dto.setStatus(account.getStatus());
        dto.setCreatedAt(account.getCreatedAt());
        dto.setUserId(account.getUser().getId());
        return dto;
    }

        
    @SuppressWarnings("null")
    public AccountDTO updateAccount(Long accountId, String username, AccountUpdateDTO dto) {

        // Vérifier que le compte appartient bien à l'utilisateur connecté
        Account account = accountRepository.findById(accountId)
            .orElseThrow(() -> new RuntimeException("Account not found"));

        if (!account.getUser().getUsername().equals(username)) {
            throw new RuntimeException("Unauthorized");
        }

        // Mise à jour partielle — on ne touche qu'aux champs fournis
        if (dto.getNickname() != null) {
            account.setNickname(dto.getNickname());
        }
        if (dto.getCurrency() != null) {
            account.setCurrency(dto.getCurrency());
        }
        if (dto.getStatus() != null) {
            // Sécurité : on n'autorise que ACTIVE et BLOCKED
            if (dto.getStatus().equals("ACTIVE") || dto.getStatus().equals("BLOCKED")) {
                account.setStatus(dto.getStatus());
            }
        }

        Account updated = accountRepository.save(account);
        return convertToDTO(updated);
    }


    @Override
    @Transactional
    public AccountDTO createAccount(String username, AccountDTO accountDTO) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé : " + username));

        Account account = new Account();
        account.setAccountNumber(generateAccountNumber());
        account.setAccountType(accountDTO.getAccountType());
        account.setBalance(accountDTO.getBalance() != null ? accountDTO.getBalance() : BigDecimal.ZERO);
        account.setCurrency(accountDTO.getCurrency() != null ? accountDTO.getCurrency() : "XOF");
        account.setStatus("ACTIVE");
        account.setCreatedAt(LocalDateTime.now());
        account.setUser(user);

        Account savedAccount = accountRepository.save(account);
        return convertToDTO(savedAccount);
    }

    @Override
    public List<AccountDTO> getAccountsByUsername(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé : " + username));

        return accountRepository.findByUserId(user.getId())
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    @Override
    public AccountDTO getAccountByIdAndUsername(Long accountId, String username) {
        if (accountId == null) {
            throw new IllegalArgumentException("Account ID cannot be null");
        }

        Account account = accountRepository.findById(accountId)
                .orElseThrow(() -> new RuntimeException("Compte non trouvé : " + accountId));

        if (!account.getUser().getUsername().equals(username)) {
            throw new RuntimeException("Ce compte ne vous appartient pas");
        }

        return convertToDTO(account);
    }
}