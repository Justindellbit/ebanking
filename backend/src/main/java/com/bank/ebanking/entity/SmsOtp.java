// ─── SmsOtp.java (entity) ─────────────────────────────────
package com.bank.ebanking.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "sms_otp")
public class SmsOtp {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, length = 6)
    private String code;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    @Column(nullable = false)
    private Boolean used = false;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    // Getters & Setters
    public Long          getId()        { return id; }

    public User          getUser()              { return user; }
    public void          setUser(User user)      { this.user = user; }

    public String        getCode()              { return code; }
    public void          setCode(String code)   { this.code = code; }

    public LocalDateTime getExpiresAt()                        { return expiresAt; }
    public void          setExpiresAt(LocalDateTime expiresAt) { this.expiresAt = expiresAt; }

    public Boolean       getUsed()               { return used; }
    public void          setUsed(Boolean used)   { this.used = used; }

    public LocalDateTime getCreatedAt() { return createdAt; }
}

