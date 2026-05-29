package com.example.checkmate.domain.settlement;

import com.example.checkmate.domain.notification.entity.NotificationType;
import com.example.checkmate.domain.notification.repository.NotificationRepository;
import com.example.checkmate.domain.point.entity.LedgerType;
import com.example.checkmate.domain.point.entity.PointLedger;
import com.example.checkmate.domain.point.entity.PointWallet;
import com.example.checkmate.domain.point.repository.PointLedgerRepository;
import com.example.checkmate.domain.point.repository.PointWalletRepository;
import com.example.checkmate.domain.proof.entity.Proof;
import com.example.checkmate.domain.proof.repository.ProofRepository;
import com.example.checkmate.domain.room.entity.ProofFrequencyType;
import com.example.checkmate.domain.room.entity.Room;
import com.example.checkmate.domain.room.entity.RoomMember;
import com.example.checkmate.domain.room.entity.RoomMemberStatus;
import com.example.checkmate.domain.room.entity.RoomStatus;
import com.example.checkmate.domain.room.repository.RoomMemberRepository;
import com.example.checkmate.domain.room.repository.RoomRepository;
import com.example.checkmate.domain.settlement.entity.Settlement;
import com.example.checkmate.domain.settlement.entity.SettlementMember;
import com.example.checkmate.domain.settlement.entity.SettlementMemberResult;
import com.example.checkmate.domain.settlement.repository.SettlementMemberRepository;
import com.example.checkmate.domain.settlement.repository.SettlementRepository;
import com.example.checkmate.domain.settlement.service.SettlementService;
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

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Settlement 정산 DB 통합 테스트.
 * 선택 이유: 포인트·원장·방상태·멤버상태·알림이 동시에 바뀌는 고위험 도메인.
 * Mockito verify()만으로는 금액 정합성 보장 불가 → MySQL 실제 DB 상태 검증 필수.
 * FCM 실제 발송은 firebase.enabled=false + @Transactional 롤백으로 자동 제외.
 */
@SpringBootTest
@Transactional
class SettlementIntegrationTest {

    @Autowired private SettlementService settlementService;
    @Autowired private UserRepository userRepository;
    @Autowired private RoomRepository roomRepository;
    @Autowired private RoomMemberRepository roomMemberRepository;
    @Autowired private ProofRepository proofRepository;
    @Autowired private SettlementRepository settlementRepository;
    @Autowired private SettlementMemberRepository settlementMemberRepository;
    @Autowired private PointWalletRepository pointWalletRepository;
    @Autowired private PointLedgerRepository pointLedgerRepository;
    @Autowired private NotificationRepository notificationRepository;

    // 테스트 파라미터
    // durationDays=28, requiredProofCount=1, targetRate=1
    // totalRequired = 28*1 = 28
    // requiredSuccess = ceil(28*1/100.0) = 1 → 1건 CONFIRMED이면 성공
    private static final long STAKE_POINT = 10_000L;
    private static final int DURATION_DAYS = 28;

    private UserEntity userA;
    private UserEntity userB;
    private Room room;

    @BeforeEach
    void setUp() {
        userA = userRepository.save(UserEntity.createUser("a@test.com", "pass", "A유저", "닉A"));
        userB = userRepository.save(UserEntity.createUser("b@test.com", "pass", "B유저", "닉B"));

        room = Room.create(
                userA, "테스트방", null,
                "TST001", "testtoken1234567890testtoken12",
                DURATION_DAYS, LocalTime.of(23, 59),
                1, STAKE_POINT, 2,
                ProofFrequencyType.DAILY, 1
        );
        // missionEndDate = 어제 → 정산 가능 조건 충족
        room.start(LocalDate.now().minusDays(DURATION_DAYS + 1), LocalDate.now().minusDays(1));
        room.addPotPoint(STAKE_POINT * 2); // 2명 예치
        roomRepository.save(room);

        RoomMember memberA = RoomMember.createOwner(room, userA);
        RoomMember memberB = RoomMember.createMember(room, userB);
        roomMemberRepository.save(memberA);
        roomMemberRepository.save(memberB);

        pointWalletRepository.save(PointWallet.create(userA));
        pointWalletRepository.save(PointWallet.create(userB));
    }

    // 성공 인증 1건 저장 헬퍼
    private void saveConfirmedProof(UserEntity user) {
        Proof proof = Proof.create(
                room, user, room.getMissionStartDate(),
                "test content", null, null, null, null, null
        );
        proof.confirm(LocalDateTime.now());
        proofRepository.save(proof);
    }

    @Test
    @DisplayName("TC-S-001: 전원 성공 — rewardPoint, 원장, 방/멤버 상태, 알림 DB 검증")
    void 전원성공_정산() {
        saveConfirmedProof(userA);
        saveConfirmedProof(userB);

        settlementService.settle("a@test.com", room.getId());

        // 방 상태
        assertThat(roomRepository.findById(room.getId()).orElseThrow().getStatus())
                .isEqualTo(RoomStatus.SETTLED);

        // Settlement
        Settlement settlement = settlementRepository.findByRoom(room).orElseThrow();
        assertThat(settlement.getSuccessCount()).isEqualTo(2);
        assertThat(settlement.getFailedCount()).isEqualTo(0);
        long expectedBonus = STAKE_POINT * 30 / 100; // 3000
        assertThat(settlement.getSystemBonusPoint()).isEqualTo(expectedBonus * 2); // 6000

        // SettlementMember
        List<SettlementMember> sms = settlementMemberRepository.findAllBySettlementOrderByIdAsc(settlement);
        assertThat(sms).hasSize(2);
        assertThat(sms).allMatch(sm -> sm.getResultStatus() == SettlementMemberResult.SUCCESS);
        assertThat(sms).allMatch(sm -> sm.getRewardPoint() == STAKE_POINT + expectedBonus); // 13000

        // RoomMember 상태
        assertThat(roomMemberRepository.findAllByRoomOrderByJoinedAtAsc(room))
                .allMatch(m -> m.getStatus() == RoomMemberStatus.SUCCESS);

        // PointWallet 잔액
        long expectedBalance = STAKE_POINT + expectedBonus; // 13000
        assertThat(pointWalletRepository.findByUser(userA).orElseThrow().getBalance())
                .isEqualTo(expectedBalance);
        assertThat(pointWalletRepository.findByUser(userB).orElseThrow().getBalance())
                .isEqualTo(expectedBalance);

        // PointLedger: 멤버별 REFUND + SUCCESS_BONUS 각 1건
        List<PointLedger> ledgersA = pointLedgerRepository.findByUserOrderByCreatedAtDesc(userA);
        assertThat(ledgersA).hasSize(2);
        assertThat(ledgersA).anyMatch(l -> l.getType() == LedgerType.ROOM_SETTLEMENT_REFUND);
        assertThat(ledgersA).anyMatch(l -> l.getType() == LedgerType.ROOM_SETTLEMENT_SUCCESS_BONUS);

        // Notification: 멤버 2명 ROOM_SETTLED
        List<com.example.checkmate.domain.notification.entity.Notification> notifications =
                notificationRepository.findAll();
        assertThat(notifications).hasSize(2);
        assertThat(notifications).allMatch(n -> n.getType() == NotificationType.ROOM_SETTLED);
    }

    @Test
    @DisplayName("TC-S-002: 일부 성공 — 성공자 보상, 실패자 0P, 원장 분리 검증")
    void 일부성공_정산() {
        saveConfirmedProof(userA); // A만 성공
        // B는 인증 없음 → 실패

        settlementService.settle("a@test.com", room.getId());

        Settlement settlement = settlementRepository.findByRoom(room).orElseThrow();
        assertThat(settlement.getSuccessCount()).isEqualTo(1);
        assertThat(settlement.getFailedCount()).isEqualTo(1);

        List<SettlementMember> sms = settlementMemberRepository.findAllBySettlementOrderByIdAsc(settlement);
        SettlementMember smA = sms.stream()
                .filter(sm -> sm.getUser().getId().equals(userA.getId())).findFirst().orElseThrow();
        SettlementMember smB = sms.stream()
                .filter(sm -> sm.getUser().getId().equals(userB.getId())).findFirst().orElseThrow();

        // 성공자: stakePoint + failedPot = 10000 + 10000 = 20000
        assertThat(smA.getResultStatus()).isEqualTo(SettlementMemberResult.SUCCESS);
        assertThat(smA.getRewardPoint()).isEqualTo(STAKE_POINT * 2);

        // 실패자: 0P
        assertThat(smB.getResultStatus()).isEqualTo(SettlementMemberResult.FAILED);
        assertThat(smB.getRewardPoint()).isEqualTo(0L);

        // 성공자 원장: REFUND + REWARD
        List<PointLedger> ledgersA = pointLedgerRepository.findByUserOrderByCreatedAtDesc(userA);
        assertThat(ledgersA).hasSize(2);
        assertThat(ledgersA).anyMatch(l -> l.getType() == LedgerType.ROOM_SETTLEMENT_REFUND);
        assertThat(ledgersA).anyMatch(l -> l.getType() == LedgerType.ROOM_SETTLEMENT_REWARD);

        // 실패자 원장: 없음
        assertThat(pointLedgerRepository.findByUserOrderByCreatedAtDesc(userB)).isEmpty();

        // 성공자 잔액: 20000
        assertThat(pointWalletRepository.findByUser(userA).orElseThrow().getBalance())
                .isEqualTo(STAKE_POINT * 2);

        // 실패자 잔액: 0 (변동 없음)
        assertThat(pointWalletRepository.findByUser(userB).orElseThrow().getBalance())
                .isEqualTo(0L);
    }

    @Test
    @DisplayName("TC-S-003: 전원 실패 — systemFee 30%, 균등 환불, REFUND 원장 검증")
    void 전원실패_정산() {
        // 인증 없음 → 전원 실패

        settlementService.settle("a@test.com", room.getId());

        Settlement settlement = settlementRepository.findByRoom(room).orElseThrow();
        assertThat(settlement.getSuccessCount()).isEqualTo(0);
        assertThat(settlement.getFailedCount()).isEqualTo(2);

        long potPoint = STAKE_POINT * 2; // 20000
        long expectedSystemFee = potPoint * 30 / 100; // 6000
        long expectedRefundPool = potPoint - expectedSystemFee; // 14000
        long expectedRefundPerMember = expectedRefundPool / 2; // 7000

        assertThat(settlement.getSystemFeePoint()).isEqualTo(expectedSystemFee);

        // 멤버 전원 FAILED, 환불금 7000
        List<SettlementMember> sms = settlementMemberRepository.findAllBySettlementOrderByIdAsc(settlement);
        assertThat(sms).hasSize(2);
        assertThat(sms).allMatch(sm -> sm.getResultStatus() == SettlementMemberResult.FAILED);
        assertThat(sms).allMatch(sm -> sm.getRewardPoint() == expectedRefundPerMember);

        // 원장: 각자 REFUND 1건
        assertThat(pointLedgerRepository.findByUserOrderByCreatedAtDesc(userA))
                .hasSize(1)
                .allMatch(l -> l.getType() == LedgerType.ROOM_SETTLEMENT_REFUND);
        assertThat(pointLedgerRepository.findByUserOrderByCreatedAtDesc(userB))
                .hasSize(1)
                .allMatch(l -> l.getType() == LedgerType.ROOM_SETTLEMENT_REFUND);

        // 잔액: 7000
        assertThat(pointWalletRepository.findByUser(userA).orElseThrow().getBalance())
                .isEqualTo(expectedRefundPerMember);
    }

    @Test
    @DisplayName("TC-F-001: 중복 정산 방지 — CONFLICT 예외, settlements 1건 유지")
    void 중복정산_방지() {
        saveConfirmedProof(userA);
        saveConfirmedProof(userB);

        // 첫 번째 정산
        settlementService.settle("a@test.com", room.getId());
        assertThat(settlementRepository.findByRoom(room)).isPresent();

        // 두 번째 정산 시도 → CONFLICT
        assertThatThrownBy(() -> settlementService.settle("a@test.com", room.getId()))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode())
                        .isEqualTo(HttpStatus.CONFLICT));
    }

    @Test
    @DisplayName("TC-F-002: 미션 종료 전 정산 불가 — CONFLICT 예외, settlements 0건")
    void 미션종료전_정산불가() {
        // missionEndDate = 내일인 방 생성
        Room futureRoom = Room.create(
                userA, "미래방", null,
                "FUT001", "futuretoken1234567890futuretoken",
                DURATION_DAYS, LocalTime.of(23, 59),
                1, STAKE_POINT, 2,
                ProofFrequencyType.DAILY, 1
        );
        futureRoom.start(LocalDate.now().minusDays(DURATION_DAYS - 1), LocalDate.now().plusDays(1));
        futureRoom.addPotPoint(STAKE_POINT * 2);
        roomRepository.save(futureRoom);

        RoomMember futureOwner = RoomMember.createOwner(futureRoom, userA);
        roomMemberRepository.save(futureOwner);

        assertThatThrownBy(() -> settlementService.settle("a@test.com", futureRoom.getId()))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode())
                        .isEqualTo(HttpStatus.CONFLICT));

        assertThat(settlementRepository.findByRoom(futureRoom)).isEmpty();
    }
}
