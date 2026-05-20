package com.example.checkmate.domain.proof.entity;

import com.example.checkmate.domain.room.entity.Room;
import com.example.checkmate.domain.user.entity.UserEntity;
import com.example.checkmate.global.basetime.BaseTime;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Getter
@Entity
@Table(name = "proofs")
public class Proof extends BaseTime {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_id", nullable = false)
    private Room room;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private UserEntity user;

    @Column(nullable = false)
    private LocalDate proofDate;

    @Column(columnDefinition = "TEXT")
    private String content;

    private String fileUrl;
    private String fileOriginalName;
    private String fileStoredName;
    private Long fileSize;
    private String fileContentType;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ProofStatus status;

    private LocalDateTime confirmedAt;

    public static Proof create(
            Room room,
            UserEntity user,
            LocalDate proofDate,
            String content,
            String fileUrl,
            String fileOriginalName,
            String fileStoredName,
            Long fileSize,
            String fileContentType
    ) {
        Proof proof = new Proof();
        proof.room = room;
        proof.user = user;
        proof.proofDate = proofDate;
        proof.content = content;
        proof.fileUrl = fileUrl;
        proof.fileOriginalName = fileOriginalName;
        proof.fileStoredName = fileStoredName;
        proof.fileSize = fileSize;
        proof.fileContentType = fileContentType;
        proof.status = ProofStatus.SUBMITTED;
        proof.confirmedAt = null;
        return proof;
    }
}
