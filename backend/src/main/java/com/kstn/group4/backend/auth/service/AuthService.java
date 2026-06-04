package com.kstn.group4.backend.auth.service;

import com.kstn.group4.backend.auth.dto.*;
import com.kstn.group4.backend.auth.entity.PasswordResetToken;
import com.kstn.group4.backend.auth.repository.PasswordResetTokenRepository;
import com.kstn.group4.backend.config.security.jwt.JwtTokenProvider;
import com.kstn.group4.backend.config.security.services.UserPrincipal;
import com.kstn.group4.backend.user.entity.Role;
import com.kstn.group4.backend.user.entity.User;
import com.kstn.group4.backend.exception.ResourceConflictException;
import com.kstn.group4.backend.exception.ForbiddenException;
import com.kstn.group4.backend.exception.ResourceNotFoundException;
import com.kstn.group4.backend.exception.BusinessException;
import com.kstn.group4.backend.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final AuthenticationManager authenticationManager;
    private final JwtTokenProvider jwtTokenProvider;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final PasswordResetTokenRepository passwordResetTokenRepository;
    private final EmailService emailService;

    @Value("${application.security.password-reset.expiration-minutes:15}")
    private int expirationMinutes;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByUsername(request.username())) {
            throw new ResourceConflictException("Username đã tồn tại");
        }

        if (userRepository.existsByEmail(request.email())) {
            throw new ResourceConflictException("Email đã được sử dụng");
        }

        User user = new User();
        user.setUsername(request.username());
        user.setEmail(request.email());
        user.setPassword(passwordEncoder.encode(request.password()));

        String normalizedRole = request.role() == null || request.role().isBlank()
                ? Role.PLAYER.name()
                : Role.fromValue(request.role()).name();
        user.setRole(normalizedRole);

        userRepository.save(user);
        return new AuthResponse(true, "Người dùng đã đăng ký thành công");
    }

    @Transactional(readOnly = true)
    public JwtResponse login(LoginRequest request) {
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.email(), request.password())
        );

        SecurityContextHolder.getContext().setAuthentication(authentication);
        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();

        if (request.role() != null && !request.role().isBlank()) {
            String requestedRole = Role.fromValue(request.role()).name();
            if (!requestedRole.equals(userPrincipal.getRole())) {
                throw new ForbiddenException(
                        "Tài khoản không có quyền đăng nhập với vai trò " + requestedRole
                );
            }
        }

        String token = jwtTokenProvider.generateToken(authentication);
        return new JwtResponse(
                token,
                userPrincipal.getAppUsername(),
                userPrincipal.getEmail(),
                userPrincipal.getRole()
        );
    }

    @Transactional
    public AuthResponse forgotPassword(ForgotPasswordRequest request) {
        User user = userRepository.findByEmail(request.email())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người dùng với email: " + request.email()));

        // Xóa token cũ nếu có
        passwordResetTokenRepository.findByUser(user).ifPresent(passwordResetTokenRepository::delete);

        // Tạo token mới
        String token = UUID.randomUUID().toString();
        PasswordResetToken resetToken = new PasswordResetToken(token, user, expirationMinutes);
        passwordResetTokenRepository.save(resetToken);

        // Gửi email khôi phục
        String resetUrl = "http://localhost:5173/reset-password?token=" + token;
        emailService.sendPasswordResetEmail(user.getEmail(), user.getUsername(), resetUrl);

        return new AuthResponse(true, "Yêu cầu khôi phục mật khẩu đã được gửi tới email của bạn");
    }

    @Transactional
    public AuthResponse resetPassword(ResetPasswordRequest request) {
        PasswordResetToken resetToken = passwordResetTokenRepository.findByToken(request.token())
                .orElseThrow(() -> new BusinessException("Token không hợp lệ hoặc đã được sử dụng", "INVALID_TOKEN"));

        if (resetToken.isExpired()) {
            passwordResetTokenRepository.delete(resetToken);
            throw new BusinessException("Liên kết khôi phục mật khẩu đã hết hạn", "EXPIRED_TOKEN");
        }

        User user = resetToken.getUser();
        user.setPassword(passwordEncoder.encode(request.newPassword()));
        userRepository.save(user);

        // Xóa token sau khi dùng thành công
        passwordResetTokenRepository.delete(resetToken);

        return new AuthResponse(true, "Cập nhật mật khẩu mới thành công");
    }
}