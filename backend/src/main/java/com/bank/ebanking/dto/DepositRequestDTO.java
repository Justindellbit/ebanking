package com.bank.ebanking.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class DepositRequestDTO {

    private Long          id;
    private Long          accountId;
    private String        accountNumber;
    private String        clientName;      // prénom + nom du client
    private BigDecimal    amount;
    private String        description;
    private String        status;
    private LocalDateTime createdAt;
    private LocalDateTime processedAt;
    private String        processedBy;

    public DepositRequestDTO() {}

    // Getters & Setters
    public Long          getId()            { return id; }
    public void          setId(Long id)     { this.id = id; }

    public Long          getAccountId()                   { return accountId; }
    public void          setAccountId(Long accountId)     { this.accountId = accountId; }

    public String        getAccountNumber()                      { return accountNumber; }
    public void          setAccountNumber(String accountNumber)  { this.accountNumber = accountNumber; }

    public String        getClientName()                   { return clientName; }
    public void          setClientName(String clientName)  { this.clientName = clientName; }

    public BigDecimal    getAmount()                { return amount; }
    public void          setAmount(BigDecimal a)    { this.amount = a; }

    public String        getDescription()                     { return description; }
    public void          setDescription(String description)   { this.description = description; }

    public String        getStatus()                  { return status; }
    public void          setStatus(String status)     { this.status = status; }

    public LocalDateTime getCreatedAt()                       { return createdAt; }
    public void          setCreatedAt(LocalDateTime createdAt){ this.createdAt = createdAt; }

    public LocalDateTime getProcessedAt()                          { return processedAt; }
    public void          setProcessedAt(LocalDateTime processedAt) { this.processedAt = processedAt; }

    public String        getProcessedBy()                    { return processedBy; }
    public void          setProcessedBy(String processedBy)  { this.processedBy = processedBy; }
}