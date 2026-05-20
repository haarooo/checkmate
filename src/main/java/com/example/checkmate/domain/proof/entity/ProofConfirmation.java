package com.example.checkmate.domain.proof.entity;

import com.example.checkmate.domain.room.entity.Room;
import com.example.checkmate.domain.user.entity.UserEntity;
import com.example.checkmate.global.basetime.BaseTime;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Getter
@Entity
@Table(
        name = "proof_confirmations",
        uniqueConstraints = @UniqueConstraint(columnNames = {"proof_id", "confirmer_id"})
)
public class
ProofConfirmation extends BaseTime {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "proof_id", nullable = false)
    private Proof proof;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_id", nullable = false)
    private Room room;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "confirmer_id", nullable = false)
    private UserEntity confirmer;

    public static ProofConfirmation create(Proof proof, Room room, UserEntity confirmer) {
        ProofConfirmation pc = new ProofConfirmation();
        pc.proof = proof;
        pc.room = room;
        pc.confirmer = confirmer;
        return pc;
    }
}
