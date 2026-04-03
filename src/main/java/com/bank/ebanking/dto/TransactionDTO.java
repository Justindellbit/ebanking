package com.bank.ebanking.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class TransactionDTO {

    private Long id;
    private String transId;
    private BigDecimal amount;
    private String type;
    private String description;
    private LocalDateTime timestamp;
    private String status;
    private Long accountId;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getTransId() { return transId; }
    public void setTransId(String transId) { this.transId = transId; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public LocalDateTime getTimestamp() { return timestamp; }
    public void setTimestamp(LocalDateTime timestamp) { this.timestamp = timestamp; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Long getAccountId() { return accountId; }
    public void setAccountId(Long accountId) { this.accountId = accountId; }
}