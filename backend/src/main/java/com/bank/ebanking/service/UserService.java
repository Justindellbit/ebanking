package com.bank.ebanking.service;

import com.bank.ebanking.dto.UserDTO;
import com.bank.ebanking.entity.User;
import com.bank.ebanking.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public List<UserDTO> getAllUsers() {
        return userRepository.findAll()
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    public UserDTO getUserById(Long id) {
        if (id == null) {
            throw new IllegalArgumentException("L'identifiant utilisateur ne doit pas être null");
        }

        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));

        return convertToDTO(user);
    }

    public UserDTO getUserByUsername(String username) {
        if (username == null || username.isBlank()) {
            throw new IllegalArgumentException("Le nom d'utilisateur est obligatoire");
        }

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));

        return convertToDTO(user);
    }

    public UserDTO createUser(UserDTO userDTO) {
        if (userDTO == null) {
            throw new IllegalArgumentException("Les données utilisateur sont obligatoires");
        }

        if (userDTO.getUsername() == null || userDTO.getUsername().isBlank()) {
            throw new IllegalArgumentException("Le nom d'utilisateur est obligatoire");
        }

        if (userDTO.getEmail() == null || userDTO.getEmail().isBlank()) {
            throw new IllegalArgumentException("L'email est obligatoire");
        }

        if (userRepository.existsByUsername(userDTO.getUsername())) {
            throw new RuntimeException("Nom d'utilisateur déjà pris");
        }

        User user = new User();
        user.setUsername(userDTO.getUsername().trim());
        user.setPassword(passwordEncoder.encode("password123")); // Temporaire, à remplacer plus tard par un vrai mot de passe
        user.setEmail(userDTO.getEmail().trim().toLowerCase());
        user.setFirstName(userDTO.getFirstName());
        user.setLastName(userDTO.getLastName());
        user.setPhone(userDTO.getPhone());
        user.setFa2Enabled(false);

        User savedUser = userRepository.save(user);
        return convertToDTO(savedUser);
    }

    public UserDTO updateUser(Long id, UserDTO userDTO) {
        if (id == null) {
            throw new IllegalArgumentException("L'identifiant utilisateur ne doit pas être null");
        }

        if (userDTO == null) {
            throw new IllegalArgumentException("Les données utilisateur sont obligatoires");
        }

        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));

        if (userDTO.getEmail() != null && !userDTO.getEmail().isBlank()) {
            user.setEmail(userDTO.getEmail().trim().toLowerCase());
        }

        user.setFirstName(userDTO.getFirstName());
        user.setLastName(userDTO.getLastName());
        user.setPhone(userDTO.getPhone());

        User updatedUser = userRepository.save(user);
        return convertToDTO(updatedUser);
    }

    public void deleteUser(Long id) {
        if (id == null) {
            throw new IllegalArgumentException("L'identifiant utilisateur ne doit pas être null");
        }

        if (!userRepository.existsById(id)) {
            throw new RuntimeException("Utilisateur non trouvé");
        }

        userRepository.deleteById(id);
    }

    private UserDTO convertToDTO(User user) {
        UserDTO dto = new UserDTO();
        dto.setId(user.getId());
        dto.setUsername(user.getUsername());
        dto.setEmail(user.getEmail());
        dto.setFirstName(user.getFirstName());
        dto.setLastName(user.getLastName());
        dto.setPhone(user.getPhone());
        dto.setFa2Enabled(user.getFa2Enabled());
        return dto;
    }
}