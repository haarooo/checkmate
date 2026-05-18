package com.example.checkmate.domain.user.service;

import com.example.checkmate.domain.user.entity.UserEntity;
import com.example.checkmate.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;


@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    /*
     * Spring Security가 로그인 인증 과정에서 호출하는 메서드
     * email로 회원을 조회한 뒤, Security가 이해할 수 있는 UserDetails로 변환한다.
     */
    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {

        // 1. 이메일로 회원 조회
        UserEntity user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("회원을 찾을 수 없습니다."));

        // 2. UserEntity → Spring Security UserDetails 변환
        return User.builder()
                .username(user.getEmail())
                .password(user.getPassword())
                .authorities(user.getRole().name())
                .build();
    }
}
