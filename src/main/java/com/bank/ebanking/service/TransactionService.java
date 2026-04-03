package com.bank.ebanking.service;

import com.bank.ebanking.dto.TransactionDTO;
import com.bank.ebanking.entity.Account;
import com.bank.ebanking.entity.Transaction;
import com.bank.ebanking.repository.AccountRepository;
import com.bank.ebanking.repository.TransactionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

import com.bank.ebanking.repository.WithdrawalOtpRepository;
import com.bank.ebanking.entity.WithdrawalOtp;
import com.bank.ebanking.dto.WithdrawalOtpDTO;
import java.util.Optional;
import java.util.Random;

@Service
public class TransactionService {

    private final TransactionRepository transactionRepository;
    private final AccountRepository accountRepository;
    private final WithdrawalOtpRepository withdrawalOtpRepository;

    public TransactionService(TransactionRepository transactionRepository,
                              AccountRepository accountRepository,
                              WithdrawalOtpRepository withdrawalOtpRepository) {
        this.transactionRepository = transactionRepository;
        this.accountRepository = accountRepository;
        this.withdrawalOtpRepository = withdrawalOtpRepository;
    }

    public List<TransactionDTO> getTransactionsByAccountId(Long accountId) {
        if (accountId == null) {
            throw new IllegalArgumentException("L'identifiant du compte ne doit pas être null");
        }

        return transactionRepository.findByAccountId(accountId)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    @Transactional
    public TransactionDTO deposit(Long accountId, BigDecimal amount, String description, String tellerUsername) {
        validateAmount(amount);

        if (accountId == null) {
            throw new IllegalArgumentException("L'identifiant du compte ne doit pas être null");
        }

        Account account = accountRepository.findById(accountId)
                .orElseThrow(() -> new RuntimeException("Compte non trouvé"));

        account.setBalance(account.getBalance().add(amount));
        accountRepository.save(account);

        Transaction transaction = new Transaction();
        transaction.setTransId(generateTransactionId());
        transaction.setAmount(amount);
        transaction.setType("DEPOSIT");
        transaction.setDescription(description);
        transaction.setTimestamp(LocalDateTime.now());
        transaction.setStatus("COMPLETED");
        transaction.setAccount(account);

        Transaction savedTransaction = transactionRepository.save(transaction);
        return convertToDTO(savedTransaction);
    }

    @Transactional
    public TransactionDTO withdraw(Long accountId, BigDecimal amount, String description) {
        validateAmount(amount);

        if (accountId == null) {
            throw new IllegalArgumentException("L'identifiant du compte ne doit pas être null");
        }

        Account account = accountRepository.findById(accountId)
                .orElseThrow(() -> new RuntimeException("Compte non trouvé"));

        if (account.getBalance().compareTo(amount) < 0) {
            throw new RuntimeException("Solde insuffisant");
        }

        account.setBalance(account.getBalance().subtract(amount));
        accountRepository.save(account);

        Transaction transaction = new Transaction();
        transaction.setTransId(generateTransactionId());
        transaction.setAmount(amount);
        transaction.setType("WITHDRAWAL");
        transaction.setDescription(description);
        transaction.setTimestamp(LocalDateTime.now());
        transaction.setStatus("COMPLETED");
        transaction.setAccount(account);

        Transaction savedTransaction = transactionRepository.save(transaction);
        return convertToDTO(savedTransaction);
    }

    @Transactional
    public TransactionDTO transfer(Long fromAccountId, String toAccountNumber, BigDecimal amount, String description, String clientUsername) {
        validateAmount(amount);

        if (fromAccountId == null) {
            throw new IllegalArgumentException("L'identifiant du compte source ne doit pas être null");
        }

        if (toAccountNumber == null || toAccountNumber.isBlank()) {
            throw new IllegalArgumentException("Le numéro du compte destinataire est obligatoire");
        }

        Account fromAccount = accountRepository.findById(fromAccountId)
                .orElseThrow(() -> new RuntimeException("Compte source non trouvé"));

        Account toAccount = accountRepository.findByAccountNumber(toAccountNumber)
                .orElseThrow(() -> new RuntimeException("Compte destinataire non trouvé"));

        if (fromAccount.getAccountNumber().equals(toAccount.getAccountNumber())) {
            throw new RuntimeException("Le compte source et le compte destinataire doivent être différents");
        }

        if (fromAccount.getBalance().compareTo(amount) < 0) {
            throw new RuntimeException("Solde insuffisant");
        }

        // Débit du compte source
        fromAccount.setBalance(fromAccount.getBalance().subtract(amount));
        accountRepository.save(fromAccount);

        // Crédit du compte destinataire
        toAccount.setBalance(toAccount.getBalance().add(amount));
        accountRepository.save(toAccount);

        // Transaction débit
        Transaction debitTransaction = new Transaction();
        debitTransaction.setTransId(generateTransactionId());
        debitTransaction.setAmount(amount);
        debitTransaction.setType("TRANSFER_OUT");
        debitTransaction.setDescription("Transfert vers " + toAccountNumber +
                (description != null && !description.isBlank() ? " : " + description : ""));
        debitTransaction.setTimestamp(LocalDateTime.now());
        debitTransaction.setStatus("COMPLETED");
        debitTransaction.setAccount(fromAccount);
        transactionRepository.save(debitTransaction);

        // Transaction crédit
        Transaction creditTransaction = new Transaction();
        creditTransaction.setTransId(generateTransactionId());
        creditTransaction.setAmount(amount);
        creditTransaction.setType("TRANSFER_IN");
        creditTransaction.setDescription("Transfert depuis " + fromAccount.getAccountNumber() +
                (description != null && !description.isBlank() ? " : " + description : ""));
        creditTransaction.setTimestamp(LocalDateTime.now());
        creditTransaction.setStatus("COMPLETED");
        creditTransaction.setAccount(toAccount);

        Transaction savedTransaction = transactionRepository.save(creditTransaction);
        return convertToDTO(savedTransaction);
    }

    @Transactional
    public WithdrawalOtpDTO generateWithdrawalOtp(Long accountId, BigDecimal amount, String clientUsername) {
        validateAmount(amount);

        if (accountId == null) {
            throw new IllegalArgumentException("L'identifiant du compte ne doit pas être null");
        }

        Account account = accountRepository.findById(accountId)
                .orElseThrow(() -> new RuntimeException("Compte non trouvé"));

        // Invalider les anciens OTPs
        LocalDateTime now = LocalDateTime.now();
        List<WithdrawalOtp> activeOtps = withdrawalOtpRepository.findActiveOtpForAccount(accountId, now);
        for (WithdrawalOtp otp : activeOtps) {
            otp.setUsed(true);
            withdrawalOtpRepository.save(otp);
        }

        // Générer un nouveau OTP
        String otpCode = String.format("%06d", new Random().nextInt(999999));
        LocalDateTime expiresAt = now.plusMinutes(5);

        WithdrawalOtp otp = new WithdrawalOtp();
        otp.setAccount(account);
        otp.setAmount(amount);
        otp.setOtpCode(otpCode);
        otp.setExpiresAt(expiresAt);

        withdrawalOtpRepository.save(otp);

        return new WithdrawalOtpDTO(otpCode, 5, account.getAccountNumber(), amount);
    }

    @Transactional
    public TransactionDTO validateWithdrawalOtp(String otpCode, String username) {
        LocalDateTime now = LocalDateTime.now();
        Optional<WithdrawalOtp> otpOpt = withdrawalOtpRepository.findValidOtp(otpCode, now);

        if (otpOpt.isEmpty()) {
            throw new RuntimeException("OTP invalide ou expiré");
        }

        WithdrawalOtp otp = otpOpt.get();
        Account account = otp.getAccount();
        BigDecimal amount = otp.getAmount();

        if (account.getBalance().compareTo(amount) < 0) {
            throw new RuntimeException("Solde insuffisant");
        }

        // Effectuer le retrait
        account.setBalance(account.getBalance().subtract(amount));
        accountRepository.save(account);

        Transaction transaction = new Transaction();
        transaction.setTransId(generateTransactionId());
        transaction.setAmount(amount);
        transaction.setType("WITHDRAWAL");
        transaction.setDescription("Retrait avec OTP");
        transaction.setTimestamp(now);
        transaction.setStatus("COMPLETED");
        transaction.setAccount(account);

        Transaction savedTransaction = transactionRepository.save(transaction);

        // Marquer l'OTP comme utilisé
        otp.setUsed(true);
        withdrawalOtpRepository.save(otp);

        return convertToDTO(savedTransaction);
    }

    private void validateAmount(BigDecimal amount) {
        if (amount == null) {
            throw new IllegalArgumentException("Le montant est obligatoire");
        }

        if (amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Le montant doit être supérieur à zéro");
        }
    }

    private String generateTransactionId() {
        return "TXN" + UUID.randomUUID()
                .toString()
                .replace("-", "")
                .substring(0, 16)
                .toUpperCase();
    }

    private TransactionDTO convertToDTO(Transaction transaction) {
        TransactionDTO dto = new TransactionDTO();
        dto.setId(transaction.getId());
        dto.setTransId(transaction.getTransId());
        dto.setAmount(transaction.getAmount());
        dto.setType(transaction.getType());
        dto.setDescription(transaction.getDescription());
        dto.setTimestamp(transaction.getTimestamp());
        dto.setStatus(transaction.getStatus());

        if (transaction.getAccount() != null) {
            dto.setAccountId(transaction.getAccount().getId());
        }

        return dto;
    }
}