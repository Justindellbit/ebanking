package com.bank.ebanking.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public class RegisterRequest {

    // ── Credentials ──────────────────────────────────────
    @NotBlank(message = "Username is required")
    @Size(min = 3, max = 50, message = "Username must be between 3 and 50 characters")
    private String username;

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    private String email;

    @NotBlank(message = "Password is required")
    @Size(min = 8, message = "Password must be at least 8 characters")
    private String password;

    // ── Personal Info ────────────────────────────────────
    @NotBlank(message = "First name is required")
    private String firstName;

    @NotBlank(message = "Last name is required")
    private String lastName;

    @Pattern(regexp = "^\\+?[0-9]{8,15}$", message = "Invalid phone number")
    private String phone;

    private Boolean fa2Enabled = false;

    // ── Account Info ─────────────────────────────────────
    @NotBlank(message = "Account type is required")
    private String accountType; // CHECKING | SAVINGS

    @NotBlank(message = "Currency is required")
    private String currency;   // USD | EUR | MAD | GBP...

    // ── Getters & Setters ────────────────────────────────
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }

    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public Boolean getFa2Enabled() { return fa2Enabled != null && fa2Enabled; }
    public void setFa2Enabled(Boolean fa2Enabled) { this.fa2Enabled = fa2Enabled; }

    public String getAccountType() { return accountType; }
    public void setAccountType(String accountType) { this.accountType = accountType; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }
}