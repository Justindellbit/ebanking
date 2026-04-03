package com.bank.ebanking.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class TestController {

    @GetMapping("/test/public")
    public String publicEndpoint() {
        return "Public endpoint";
    }

    @GetMapping("/test/private")
    public String privateEndpoint() {
        return "Private endpoint - authenticated";
    }
}