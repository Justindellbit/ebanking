package com.bank.ebanking.repository;

import com.bank.ebanking.entity.Account;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface AccountRepository extends JpaRepository<Account, Long> {
    List<Account> findByUserUsername(String username);
    Optional<Account> findByIdAndUserUsername(Long id, String username);
    Optional<Account> findByAccountNumber(String accountNumber);
    List<Account> findByUserId(Long userId);
    boolean existsByAccountNumber(String accountNumber);
}