package com.bank.ebanking.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class AccountDTO {
    private Long id;
    private String accountNumber;
    private String accountType;
    private BigDecimal balance = BigDecimal.ZERO;  // Initialisé à 0
    private String currency;
    private String status;
    private LocalDateTime createdAt;
    private Long userId;
    private String nickname; // Surnom du compte (optionnel)
    
    // Constructeurs
    public AccountDTO() {}
    
    // Getters et Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getNickname() { return nickname; }
    public void setNickname(String nickname) { this.nickname = nickname; }
    
    public String getAccountNumber() { return accountNumber; }
    public void setAccountNumber(String accountNumber) { this.accountNumber = accountNumber; }
    
    public String getAccountType() { return accountType; }
    public void setAccountType(String accountType) { this.accountType = accountType; }
    
    public BigDecimal getBalance() { return balance; }
    public void setBalance(BigDecimal balance) { this.balance = balance; }
    
    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }
    
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
}