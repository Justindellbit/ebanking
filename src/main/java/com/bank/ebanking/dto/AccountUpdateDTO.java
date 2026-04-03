package com.bank.ebanking.dto;


/**
 * DTO pour la modification partielle d'un compte (PATCH).
 * Seuls les champs non-null seront mis à jour.
 */
public class AccountUpdateDTO {

    private String nickname;   // surnom du compte
    private String currency;   // devise ex: USD, EUR, MAD
    private String status;     // ACTIVE | BLOCKED

    public AccountUpdateDTO() {}

    public String getNickname() { return nickname; }
    public void setNickname(String nickname) { this.nickname = nickname; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}