package com.kstn.group4.backend.config.security;

import com.kstn.group4.backend.config.security.jwt.AuthTokenFilter;
import com.kstn.group4.backend.config.security.jwt.JwtTokenProvider;
import com.kstn.group4.backend.config.security.services.UserDetailsServiceImplement;
import java.util.ArrayList;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.core.Ordered;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class WebSecurityConfig {

    @Bean
    public AuthTokenFilter authenticationJwtTokenFilter(
            JwtTokenProvider jwtTokenProvider,
            UserDetailsServiceImplement userDetailsService
    ) {
        return new AuthTokenFilter(jwtTokenProvider, userDetailsService);
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public UserDetailsService userDetailsService(UserDetailsServiceImplement userDetailsServiceImplement) {
        return userDetailsServiceImplement;
    }

    @Bean
    public DaoAuthenticationProvider authenticationProvider(
            UserDetailsService userDetailsService,
            PasswordEncoder passwordEncoder
    ) {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider(userDetailsService);
        authProvider.setPasswordEncoder(passwordEncoder);
        return authProvider;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration authConfig) throws Exception {
        return authConfig.getAuthenticationManager();
    }

    @Bean
    public SecurityFilterChain filterChain(
            HttpSecurity http,
            DaoAuthenticationProvider authenticationProvider,
            AuthTokenFilter authTokenFilter,
            CorsConfigurationSource corsConfigurationSource
    ) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .cors(cors -> cors.configurationSource(corsConfigurationSource))
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authenticationProvider(authenticationProvider)
                .authorizeHttpRequests(auth -> auth
                        // ĐÃ SỬA: Cho phép Preflight OPTIONS đi qua thoải mái
                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                        
                        // ĐÃ SỬA: Thêm /api/v1/ tiền tố để khớp tuyệt đối với context-path
                        .requestMatchers("/api/v1/auth/**", "/auth/**").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/v1/public/**", "/api/v1/pitches/**", "/pitches/**").permitAll()
                        .requestMatchers("/api/v1/player/venues/**", "/api/v1/player/venues").permitAll() // Cho phép xem sân công khai
                        
                        // Giữ nguyên các cấu hình phân quyền khác của nhóm bạn
                        .requestMatchers("/v3/api-docs/**", "/swagger-ui/**", "/swagger-ui.html").permitAll()
                        .requestMatchers("/error").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/v1/payment/vnpay/ipn").permitAll()
                        
                        .requestMatchers("/api/v1/teams", "/api/v1/teams/**").hasAnyRole("PLAYER", "ADMIN")
                        .requestMatchers("/api/v1/match/**", "/api/v1/matches", "/api/v1/matches/**").hasAnyRole("PLAYER", "ADMIN")
                        .requestMatchers("/api/v1/notifications", "/api/v1/notifications/**").hasAnyRole("PLAYER", "ADMIN")
                        .requestMatchers("/api/v1/player/**").hasRole("PLAYER")
                        .requestMatchers("/api/v1/admin/**").hasRole("ADMIN")
                        .anyRequest().authenticated()
                )
                .addFilterBefore(authTokenFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource(
            @Value("${application.cors.allowed-origins:http://localhost:5173}") List<String> allowedOrigins
    ) {
        CorsConfiguration configuration = new CorsConfiguration();
        
        // ĐÃ SỬA: Tạo danh sách nguồn động bảo đảm đọc tốt cả biến môi trường Render thô
        List<String> finalOrigins = new ArrayList<>(allowedOrigins);
        String envOrigin = System.getenv("FRONTEND_ORIGIN");
        if (envOrigin != null && !envOrigin.trim().isEmpty()) {
            finalOrigins.add(envOrigin.trim());
        }
        // Backup cứng thêm cái link Netlify của bạn để bảo đảm ăn chắc 100%
        finalOrigins.add("https://fanciful-monstera-4ef7d2.netlify.app");

        configuration.setAllowedOrigins(finalOrigins);
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"));
        configuration.setAllowedHeaders(List.of("Authorization", "Cache-Control", "Content-Type", "Origin", "Accept", "X-Requested-With"));
        configuration.setExposedHeaders(List.of("Authorization"));
        configuration.setAllowCredentials(true);
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

    @Bean
    public FilterRegistrationBean<CorsFilter> corsFilterRegistration(CorsConfigurationSource corsConfigurationSource) {
        CorsFilter corsFilter = new CorsFilter(corsConfigurationSource);
        FilterRegistrationBean<CorsFilter> registration = new FilterRegistrationBean<>(corsFilter);
        registration.setOrder(Ordered.HIGHEST_PRECEDENCE);
        return registration;
    }
}
