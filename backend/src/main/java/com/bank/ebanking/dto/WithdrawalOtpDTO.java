package com.bank.ebanking.dto;

import java.math.BigDecimal;

public class WithdrawalOtpDTO {

    private String     otpCode;
    private int        expiresInMinutes;
    private String     accountNumber;
    private BigDecimal amount;

    public WithdrawalOtpDTO(String otpCode, int expiresInMinutes,
                             String accountNumber, BigDecimal amount) {
        this.otpCode          = otpCode;
        this.expiresInMinutes = expiresInMinutes;
        this.accountNumber    = accountNumber;
        this.amount           = amount;
    }

    public String     getOtpCode()          { return otpCode;          }
    public int        getExpiresInMinutes()  { return expiresInMinutes; }
    public String     getAccountNumber()     { return accountNumber;    }
    public BigDecimal getAmount()            { return amount;           }
}