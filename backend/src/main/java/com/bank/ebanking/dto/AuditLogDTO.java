// ─── AuditLogDTO.java ─────────────────────────────────────
package com.bank.ebanking.dto;

public class AuditLogDTO {
    private Long   id;
    private String username;
    private String action;
    private String description;
    private String ipAddress;
    private String deviceInfo;
    private String createdAt;

    public AuditLogDTO() {}

    public Long   getId()              { return id; }
    public void   setId(Long id)       { this.id = id; }

    public String getUsername()                  { return username; }
    public void   setUsername(String username)   { this.username = username; }

    public String getAction()                { return action; }
    public void   setAction(String action)   { this.action = action; }

    public String getDescription()                     { return description; }
    public void   setDescription(String description)   { this.description = description; }

    public String getIpAddress()                   { return ipAddress; }
    public void   setIpAddress(String ipAddress)   { this.ipAddress = ipAddress; }

    public String getDeviceInfo()                    { return deviceInfo; }
    public void   setDeviceInfo(String deviceInfo)   { this.deviceInfo = deviceInfo; }

    public String getCreatedAt()                   { return createdAt; }
    public void   setCreatedAt(String createdAt)   { this.createdAt = createdAt; }
}