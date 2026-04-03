package com.bank.ebanking.controller;

import com.bank.ebanking.dto.AccountDTO;
import com.bank.ebanking.service.AccountService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/accounts")
@CrossOrigin(origins = "*")
public class AccountController {

    private final AccountService accountService;

    public AccountController(AccountService accountService) {
        this.accountService = accountService;
    }

    @PostMapping
    public ResponseEntity<AccountDTO> createAccount(@RequestBody AccountDTO accountDTO) {
        // Récupérer le username directement
        String username = (String) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        
        AccountDTO createdAccount = accountService.createAccount(username, accountDTO);
        return ResponseEntity.ok(createdAccount);
    }

    @GetMapping("/my-accounts")
    public ResponseEntity<List<AccountDTO>> getMyAccounts() {
        String username = (String) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        
        List<AccountDTO> accounts = accountService.getAccountsByUsername(username);
        return ResponseEntity.ok(accounts);
    }

    @GetMapping("/{accountId}")
    public ResponseEntity<AccountDTO> getAccountById(@PathVariable Long accountId) {
        String username = (String) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        
        AccountDTO account = accountService.getAccountByIdAndUsername(accountId, username);
        return ResponseEntity.ok(account);
    }
}