package com.example.checkmate.domain.room;

import com.example.checkmate.domain.activity.entity.ActivityType;
import com.example.checkmate.domain.activity.entity.RoomActivity;
import com.example.checkmate.domain.activity.repository.RoomActivityRepository;
import com.example.checkmate.domain.point.entity.LedgerType;
import com.example.checkmate.domain.point.entity.PointLedger;
import com.example.checkmate.domain.point.entity.PointWallet;
import com.example.checkmate.domain.point.repository.PointLedgerRepository;
import com.example.checkmate.domain.point.repository.PointWalletRepository;
import com.example.checkmate.domain.room.entity.ProofFrequencyType;
import com.example.checkmate.domain.room.entity.Room;
import com.example.checkmate.domain.room.entity.RoomMember;
import com.example.checkmate.domain.room.entity.RoomMemberStatus;
import com.example.checkmate.domain.room.entity.RoomStatus;
import com.example.checkmate.domain.room.repository.RoomMemberRepository;
import com.example.checkmate.domain.room.repository.RoomRepository;
import com.example.checkmate.domain.room.service.RoomService;
import com.example.checkmate.domain.user.entity.UserEntity;
import com.example.checkmate.domain.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpStatus;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@SpringBootTest
@Transactional
class StakeIntegrationTest {

    @Autowired private RoomService roomService;
    @Autowired private UserRepository userRepository;
    @Autowired private RoomRepository roomRepository;
    @Autowired private RoomMemberRepository roomMemberRepository;
    @Autowired private PointWalletRepository pointWalletRepository;
    @Autowired private PointLedgerRepository pointLedgerRepository;
    @Autowired private RoomActivityRepository roomActivityRepository;

    private static final long STAKE_POINT = 10_000L;

    private UserEntity userA;
    private UserEntity userB;
    private Room room;

    @BeforeEach
    void setUp() {
        userA = userRepository.save(UserEntity.createUser("a@stake.com", "pass", "A유저", "닉A"));
        userB = userRepository.save(UserEntity.createUser("b@stake.com", "pass", "B유저", "닉B"));

        room = Room.create(
                userA, "스테이크방", null,
                "STK001", "staketoken1234567890staketoken12",
                28, LocalTime.of(23, 59),
                1, STAKE_POINT, 2,
                ProofFrequencyType.DAILY, 1
        );
        roomRepository.save(room);

        roomMemberRepository.save(RoomMember.createOwner(room, userA));
        roomMemberRepository.save(RoomMember.createMember(room, userB));

        PointWallet walletA = PointWallet.create(userA);
        walletA.addBalance(STAKE_POINT);
        pointWalletRepository.save(walletA);

        PointWallet walletB = PointWallet.create(userB);
        walletB.addBalance(STAKE_POINT);
        pointWalletRepository.save(walletB);
    }

    @Test
    @DisplayName("TC-S-001: 정상 납부 — balance 차감, ROOM_STAKE 원장, STAKED 상태, potPoint 증가")
    void 정상납부() {
        roomService.stakeRoom("a@stake.com", room.getId());

        // 잔액 차감
        assertThat(pointWalletRepository.findByUser(userA).orElseThrow().getBalance()).isEqualTo(0L);

        // ROOM_STAKE 원장 (음수)
        List<PointLedger> ledgers = pointLedgerRepository.findByUserOrderByCreatedAtDesc(userA);
        assertThat(ledgers).hasSize(1);
        assertThat(ledgers.get(0).getType()).isEqualTo(LedgerType.ROOM_STAKE);
        assertThat(ledgers.get(0).getAmount()).isEqualTo(-STAKE_POINT);

        // 멤버 상태
        RoomMember member = roomMemberRepository.findByRoomAndUser(room, userA).orElseThrow();
        assertThat(member.getStatus()).isEqualTo(RoomMemberStatus.STAKED);
        assertThat(member.getStakedPoint()).isEqualTo(STAKE_POINT);
        assertThat(member.getStakedAt()).isNotNull();

        // potPoint 증가, 방 상태 유지 (B는 아직 미납)
        Room updated = roomRepository.findById(room.getId()).orElseThrow();
        assertThat(updated.getPotPoint()).isEqualTo(STAKE_POINT);
        assertThat(updated.getStatus()).isEqualTo(RoomStatus.RECRUITING);
    }

    @Test
    @DisplayName("TC-S-002: 전원 납부 완료 — room.status READY 자동 전환, ROOM_READY 활동 기록")
    void 전원납부_READY전환() {
        roomService.stakeRoom("a@stake.com", room.getId());
        roomService.stakeRoom("b@stake.com", room.getId());

        assertThat(roomRepository.findById(room.getId()).orElseThrow().getStatus())
                .isEqualTo(RoomStatus.READY);

        List<RoomActivity> activities = roomActivityRepository.findTop50ByRoomOrderByCreatedAtDesc(room);
        assertThat(activities).anyMatch(a -> a.getType() == ActivityType.ROOM_READY);
        assertThat(activities.stream().filter(a -> a.getType() == ActivityType.MEMBER_STAKED).count()).isEqualTo(2);
    }

    @Test
    @DisplayName("TC-F-001: 잔액 부족 — 400, wallet/ledger/member 상태 변동 없음")
    void 잔액부족() {
        UserEntity poor = userRepository.save(UserEntity.createUser("poor@stake.com", "pass", "Poor유저", "닉P"));
        Room room2 = Room.create(
                poor, "빈지갑방", null,
                "STK002", "staketoken2234567890staketoken22",
                28, LocalTime.of(23, 59),
                1, STAKE_POINT, 2,
                ProofFrequencyType.DAILY, 1
        );
        roomRepository.save(room2);
        roomMemberRepository.save(RoomMember.createOwner(room2, poor));
        pointWalletRepository.save(PointWallet.create(poor)); // balance=0

        assertThatThrownBy(() -> roomService.stakeRoom("poor@stake.com", room2.getId()))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode())
                        .isEqualTo(HttpStatus.BAD_REQUEST));

        assertThat(pointWalletRepository.findByUser(poor).orElseThrow().getBalance()).isEqualTo(0L);
        assertThat(pointLedgerRepository.findByUserOrderByCreatedAtDesc(poor)).isEmpty();
        assertThat(roomMemberRepository.findByRoomAndUser(room2, poor).orElseThrow().getStatus())
                .isEqualTo(RoomMemberStatus.JOINED);
    }

    @Test
    @DisplayName("TC-F-002: 비멤버 납부 — 403")
    void 비멤버납부() {
        UserEntity stranger = userRepository.save(UserEntity.createUser("stranger@stake.com", "pass", "S유저", "닉S"));
        PointWallet wallet = PointWallet.create(stranger);
        wallet.addBalance(STAKE_POINT);
        pointWalletRepository.save(wallet);

        assertThatThrownBy(() -> roomService.stakeRoom("stranger@stake.com", room.getId()))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode())
                        .isEqualTo(HttpStatus.FORBIDDEN));
    }

    @Test
    @DisplayName("TC-F-003: 중복 납부 (이미 STAKED) — 409")
    void 중복납부() {
        roomService.stakeRoom("a@stake.com", room.getId());

        assertThatThrownBy(() -> roomService.stakeRoom("a@stake.com", room.getId()))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode())
                        .isEqualTo(HttpStatus.CONFLICT));
    }

    @Test
    @DisplayName("TC-F-004: RECRUITING 아닌 방 (READY) — 409")
    void 모집중아닌방_납부() {
        room.markReady(); // 더티 체킹으로 DB 반영

        assertThatThrownBy(() -> roomService.stakeRoom("a@stake.com", room.getId()))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode())
                        .isEqualTo(HttpStatus.CONFLICT));
    }
}
