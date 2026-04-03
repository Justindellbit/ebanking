package com.bank.ebanking.service;

import com.bank.ebanking.dto.AccountDTO;
import com.bank.ebanking.dto.AccountUpdateDTO;

import java.util.List;

public interface AccountService {
    AccountDTO createAccount(String username, AccountDTO accountDTO);
    List<AccountDTO> getAccountsByUsername(String username);
    AccountDTO getAccountByIdAndUsername(Long accountId, String username);
    public AccountDTO updateAccount(Long accountId, String username, AccountUpdateDTO dto);
    

}