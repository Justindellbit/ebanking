package com.bank.ebanking.service;

import com.bank.ebanking.dto.JwtResponse;
import com.bank.ebanking.dto.LoginRequest;
import com.bank.ebanking.dto.RegisterRequest;
import com.bank.ebanking.entity.Account;
import com.bank.ebanking.entity.Role;
import com.bank.ebanking.entity.User;
import com.bank.ebanking.repository.AccountRepository;
import com.bank.ebanking.repository.RoleRepository;
import com.bank.ebanking.repository.UserRepository;
import com.bank.ebanking.util.JwtUtil;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class AuthService {

    private final UserRepository    userRepository;
    private final AccountRepository accountRepository;
    private final RoleRepository    roleRepository;
    private final PasswordEncoder   passwordEncoder;
    private final JwtUtil           jwtUtil;
    private final SmsService        smsService;

    public AuthService(UserRepository userRepository,
                       AccountRepository accountRepository,
                       RoleRepository roleRepository,
                       PasswordEncoder passwordEncoder,
                       JwtUtil jwtUtil,
                       SmsService smsService) {
        this.userRepository    = userRepository;
        this.accountRepository = accountRepository;
        this.roleRepository    = roleRepository;
        this.passwordEncoder   = passwordEncoder;
        this.jwtUtil           = jwtUtil;
        this.smsService        = smsService;
    }

    // ─────────────────────────────────────────────────────
    // REGISTER
    // ─────────────────────────────────────────────────────
    @Transactional
    public String register(RegisterRequest request) {
        if (request == null)
            throw new IllegalArgumentException("Invalid registration request");

        String username = request.getUsername().trim();
        String email    = request.getEmail().trim().toLowerCase();

        if (userRepository.existsByUsername(username))
            throw new RuntimeException("Username already taken");
        if (userRepository.existsByEmail(email))
            throw new RuntimeException("Email already registered");

        // ── Créer l'utilisateur ──────────────────────────
        User user = new User();
        user.setUsername(username);
        user.setEmail(email);
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setFirstName(request.getFirstName() != null
                ? request.getFirstName().trim() : "");
        user.setLastName(request.getLastName() != null
                ? request.getLastName().trim() : "");
        user.setPhone(request.getPhone() != null
                ? request.getPhone().trim() : "");
        user.setFa2Enabled(request.getFa2Enabled() != null
                && request.getFa2Enabled());

        // ── Assigner ROLE_CLIENT automatiquement ─────────
        Role clientRole = roleRepository.findByName("ROLE_CLIENT")
                .orElseThrow(() -> new RuntimeException(
                        "ROLE_CLIENT not found. Run migration SQL first."));
        Set<Role> roles = new HashSet<>();
        roles.add(clientRole);
        user.setRoles(roles);

        User savedUser = userRepository.save(user);

        // ── Créer le compte bancaire initial ─────────────
        Account account = new Account();
        account.setAccountNumber(generateAccountNumber());
        account.setAccountType(request.getAccountType() != null
                ? request.getAccountType() : "CHECKING");
        account.setCurrency(request.getCurrency() != null
                ? request.getCurrency() : "USD");
        account.setBalance(BigDecimal.ZERO);
        account.setStatus("ACTIVE");
        account.setUser(savedUser);
        accountRepository.save(account);

        return "Registration successful";
    }

    // ─────────────────────────────────────────────────────
    // LOGIN
    // ─────────────────────────────────────────────────────
    public JwtResponse login(LoginRequest request) {
        if (request == null)
            throw new IllegalArgumentException("Invalid login request");

        String username = request.getUsername().trim();
        String password = request.getPassword();

        User user = userRepository.findByUsername(username)
                .orElseThrow(() ->
                        new RuntimeException("Invalid username or password"));

        if (!passwordEncoder.matches(password, user.getPassword()))
            throw new RuntimeException("Invalid username or password");

        // ── Charger les rôles ────────────────────────────
        List<String> roles = userRepository
                .findByUsernameWithRoles(username)
                .map(u -> u.getRoles() != null
                        ? u.getRoles().stream()
                                .map(r -> r.getName())
                                .collect(Collectors.toList())
                        : List.<String>of())
                .orElse(List.of());

        // ── 2FA par SMS ──────────────────────────────────
        if (Boolean.TRUE.equals(user.getFa2Enabled())) {
            if (user.getPhone() == null || user.getPhone().isBlank()) {
                throw new RuntimeException(
                        "2FA enabled but no phone number registered.");
            }
            smsService.sendSmsCode(user);
            String tempToken = jwtUtil.generateToken(username);
            return new JwtResponse(tempToken, user.getId(),
                    username, user.getEmail(), true, roles);
        }

        // ── Login normal ─────────────────────────────────
        String token = jwtUtil.generateToken(username);
        return new JwtResponse(token, user.getId(),
                username, user.getEmail(), false, roles);
    }

    // ─────────────────────────────────────────────────────
    // VERIFY SMS
    // ─────────────────────────────────────────────────────
    public JwtResponse verifySmsCode(String username, String code) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!smsService.verifyCode(user, code))
            throw new RuntimeException("Invalid or expired SMS code");

        List<String> roles = userRepository
                .findByUsernameWithRoles(username)
                .map(u -> u.getRoles() != null
                        ? u.getRoles().stream()
                                .map(r -> r.getName())
                                .collect(Collectors.toList())
                        : List.<String>of())
                .orElse(List.of());

        String token = jwtUtil.generateToken(username);
        return new JwtResponse(token, user.getId(),
                username, user.getEmail(), false, roles);
    }

    // ─────────────────────────────────────────────────────
    // HELPERS
    // ─────────────────────────────────────────────────────
    private String generateAccountNumber() {
        String number;
        do {
            long r = (long)(Math.random() * 9_000_000_000L) + 1_000_000_000L;
            number = "ACC" + String.format("%010d", r);
        } while (accountRepository.existsByAccountNumber(number));
        return number;
    }
}