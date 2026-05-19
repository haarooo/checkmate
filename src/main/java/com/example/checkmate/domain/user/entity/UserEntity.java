package com.example.checkmate.domain.user.entity;

import com.example.checkmate.global.basetime.BaseTime;
import jakarta.persistence.*;
import lombok.*;

@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Getter
@Builder
@Entity
@Table(name = "users")
public class UserEntity extends BaseTime {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 100)
    private String email;

    @Column(nullable = false)
    private String password;

    @Column(nullable = false, length = 30)
    private String name;

    @Column(nullable = false , length = 30)
    private String nickname;

    // 권한
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;

    private UserEntity(
            String email,
            String password,
            String name,
            String nickname,
            Role role
    ) {
        this.email = email;
        this.password = password;
        this.name = name;
        this.nickname = nickname;
        this.role = role;
    }

    public static UserEntity createUser(
            String email,
            String encodedPassword,
            String name,
            String nickname
    ) {
        return new UserEntity(
                email,
                encodedPassword,
                name,
                nickname,
                Role.ROLE_USER
        );
    }

}
