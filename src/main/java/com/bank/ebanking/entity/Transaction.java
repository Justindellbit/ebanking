package com.bank.ebanking.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "transaction")
public class Transaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String transId;
    private BigDecimal amount;
    private String type;
    private String description;
    private LocalDateTime timestamp;
    private String status;

    @ManyToOne
    @JoinColumn(name = "account_id")
    private Account account;

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

    public Account getAccount() { return account; }
    public void setAccount(Account account) { this.account = account; }
}