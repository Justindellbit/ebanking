package com.bank.ebanking.dto;

import java.util.List;

public class JwtResponse {

    private String       token;
    private String       type     = "Bearer";
    private Long         id;
    private String       username;
    private String       email;
    private boolean      needs2FA;
    private List<String> roles;   // ← ROLE_CLIENT / ROLE_TELLER / ROLE_ADMIN

    public JwtResponse(String token, Long id, String username,
                       String email, boolean needs2FA, List<String> roles) {
        this.token    = token;
        this.id       = id;
        this.username = username;
        this.email    = email;
        this.needs2FA = needs2FA;
        this.roles    = roles;
    }

    public String       getToken()    { return token;    }
    public String       getType()     { return type;     }
    public Long         getId()       { return id;       }
    public String       getUsername() { return username; }
    public String       getEmail()    { return email;    }
    public boolean      isNeeds2FA()  { return needs2FA; }
    public List<String> getRoles()    { return roles;    }
}