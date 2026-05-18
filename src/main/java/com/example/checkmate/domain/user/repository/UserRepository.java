package com.example.checkmate.domain.user.repository;

import com.example.checkmate.domain.user.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import org.springframework.web.bind.annotation.ResponseBody;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<UserEntity , Long> {

    Optional<UserEntity> findByEmail(String email);
    boolean existsByEmail(String email);
}
