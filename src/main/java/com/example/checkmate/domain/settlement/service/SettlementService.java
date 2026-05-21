package com.example.checkmate.domain.settlement.service;

import com.example.checkmate.domain.point.entity.LedgerType;
import com.example.checkmate.domain.point.service.PointService;
import com.example.checkmate.domain.proof.entity.ProofStatus;
import com.example.checkmate.domain.proof.repository.ProofRepository;
import com.example.checkmate.domain.room.entity.ProofFrequencyType;
import com.example.checkmate.domain.room.entity.Room;
import com.example.checkmate.domain.room.entity.RoomMember;
import com.example.checkmate.domain.room.entity.RoomStatus;
import com.example.checkmate.domain.room.repository.RoomMemberRepository;
import com.example.checkmate.domain.room.repository.RoomRepository;
import com.example.checkmate.domain.settlement.dto.SettlementMemberResponse;
import com.example.checkmate.domain.settlement.dto.SettlementResponse;
import com.example.checkmate.domain.settlement.entity.Settlement;
import com.example.checkmate.domain.settlement.entity.SettlementMember;
import com.example.checkmate.domain.settlement.entity.SettlementMemberResult;
import com.example.checkmate.domain.settlement.repository.SettlementMemberRepository;
import com.example.checkmate.domain.settlement.repository.SettlementRepository;
import com.example.checkmate.domain.user.entity.UserEntity;
import com.example.checkmate.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class SettlementService {

    private final RoomRepository roomRepository;
    private final RoomMemberRepository roomMemberRepository;
    private final UserRepository userRepository;
    private final ProofRepository proofRepository;
    private final SettlementRepository settlementRepository;
    private final SettlementMemberRepository settlementMemberRepository;
    private final PointService pointService;

    @Transactional
    public SettlementResponse settle(String email, Long roomId) {
        Room room = roomRepository.findByIdForUpdate(roomId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "방을 찾을 수 없습니다."));

        UserEntity user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다."));

        roomMemberRepository.findByRoomAndUser(room, user)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "방 멤버가 아닙니다."));

        if (room.getStatus() != RoomStatus.IN_PROGRESS) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "진행 중인 방만 정산할 수 있습니다.");
        }

        LocalDate today = LocalDate.now(ZoneId.of("Asia/Seoul"));
        if (!today.isAfter(room.getMissionEndDate())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "미션 종료일 이후에만 정산할 수 있습니다.");
        }

        if (settlementRepository.findByRoom(room).isPresent()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "이미 정산된 방입니다.");
        }

        List<RoomMember> members = roomMemberRepository.findAllByRoomOrderByJoinedAtAsc(room);

        int totalRequired = (room.getProofFrequencyType() == ProofFrequencyType.WEEKLY)
                ? (room.getDurationDays() / 7) * room.getRequiredProofCount()
                : room.getDurationDays() * room.getRequiredProofCount();
        int requiredSuccess = (int) Math.ceil(totalRequired * room.getTargetRate() / 100.0);

        record MemberStats(RoomMember member, long submitted, long confirmed) {}
        List<MemberStats> statsList = new ArrayList<>();
        List<RoomMember> successMembers = new ArrayList<>();
        List<RoomMember> failedMembers = new ArrayList<>();

        for (RoomMember m : members) {
            long submitted = proofRepository.countByRoomAndUserAndProofDateBetween(
                    room, m.getUser(), room.getMissionStartDate(), room.getMissionEndDate());
            long confirmed = proofRepository.countByRoomAndUserAndProofDateBetweenAndStatus(
                    room, m.getUser(), room.getMissionStartDate(), room.getMissionEndDate(), ProofStatus.CONFIRMED);
            statsList.add(new MemberStats(m, submitted, confirmed));
            if (confirmed >= requiredSuccess) {
                successMembers.add(m);
            } else {
                failedMembers.add(m);
            }
        }

        int successCount = successMembers.size();
        int failedCount = failedMembers.size();
        long systemFeePoint = 0L;
        long systemBonusPoint = 0L;

        long[] rewardPoints = new long[members.size()];

        if (failedCount == 0) {
            // 케이스 A: 전원 성공
            long bonus = Math.min(room.getStakePoint() * 10 / 100, 5000L);
            systemBonusPoint = bonus * members.size();
            for (int i = 0; i < members.size(); i++) {
                rewardPoints[i] = room.getStakePoint() + bonus;
            }
        } else if (successCount == 0) {
            // 케이스 C: 전원 실패
            systemFeePoint = room.getPotPoint() * 30 / 100;
            long refundPool = room.getPotPoint() - systemFeePoint;
            long base = refundPool / members.size();
            long remainder = refundPool % members.size();
            for (int i = 0; i < members.size(); i++) {
                rewardPoints[i] = base + (i < remainder ? 1 : 0);
            }
        } else {
            // 케이스 B: 일부 성공
            long failedPot = (long) failedCount * room.getStakePoint();
            long bonusPerWinner = failedPot / successCount;
            long remainder = failedPot % successCount;
            int successIdx = 0;
            for (int i = 0; i < members.size(); i++) {
                RoomMember m = members.get(i);
                if (successMembers.contains(m)) {
                    rewardPoints[i] = room.getStakePoint() + bonusPerWinner + (successIdx < remainder ? 1 : 0);
                    successIdx++;
                } else {
                    rewardPoints[i] = 0L;
                }
            }
        }

        Settlement settlement = Settlement.create(
                room, room.getPotPoint(), members.size(),
                successCount, failedCount,
                totalRequired, requiredSuccess,
                systemFeePoint, systemBonusPoint
        );
        settlementRepository.save(settlement);

        List<SettlementMemberResponse> memberResponses = new ArrayList<>();
        for (int i = 0; i < members.size(); i++) {
            RoomMember m = members.get(i);
            MemberStats stats = statsList.get(i);
            boolean isSuccess = successMembers.contains(m);
            double proofRate = totalRequired == 0 ? 0.0
                    : (double) stats.confirmed() / totalRequired * 100.0;

            SettlementMember sm = SettlementMember.create(
                    settlement, room, m.getUser(),
                    isSuccess ? SettlementMemberResult.SUCCESS : SettlementMemberResult.FAILED,
                    stats.submitted(), stats.confirmed(),
                    requiredSuccess, rewardPoints[i], proofRate
            );
            settlementMemberRepository.save(sm);

            if (rewardPoints[i] > 0) {
                if (failedCount == 0) {
                    // 전원 성공: stakePoint 반환 + bonus 분리 저장
                    long bonus = Math.min(room.getStakePoint() * 10 / 100, 5000L);
                    pointService.addForSettlement(m.getUser(), room.getStakePoint(), roomId,
                            LedgerType.ROOM_SETTLEMENT_REFUND, "정산 예치금 반환");
                    pointService.addForSettlement(m.getUser(), bonus, roomId,
                            LedgerType.ROOM_SETTLEMENT_SUCCESS_BONUS, "전원 성공 보너스");
                } else if (isSuccess) {
                    // 일부 성공: stakePoint 반환 + 분배 보상 분리 저장
                    long bonusPart = rewardPoints[i] - room.getStakePoint();
                    pointService.addForSettlement(m.getUser(), room.getStakePoint(), roomId,
                            LedgerType.ROOM_SETTLEMENT_REFUND, "정산 예치금 반환");
                    if (bonusPart > 0) {
                        pointService.addForSettlement(m.getUser(), bonusPart, roomId,
                                LedgerType.ROOM_SETTLEMENT_REWARD, "정산 보상");
                    }
                } else {
                    // 전원 실패: refund 저장
                    pointService.addForSettlement(m.getUser(), rewardPoints[i], roomId,
                            LedgerType.ROOM_SETTLEMENT_REFUND, "정산 환불");
                }
            }
            if (isSuccess) {m.markSuccess();}
            else {m.markFailed();}
            memberResponses.add(new SettlementMemberResponse(sm));
        }
        room.settle();
        return new SettlementResponse(settlement, memberResponses);
    }
}
