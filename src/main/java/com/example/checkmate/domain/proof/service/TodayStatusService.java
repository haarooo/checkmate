package com.example.checkmate.domain.proof.service;

import com.example.checkmate.domain.proof.dto.ProofMemberStatusResponse;
import com.example.checkmate.domain.proof.dto.ProofProgressStatus;
import com.example.checkmate.domain.proof.dto.TodayStatusResponse;
import com.example.checkmate.domain.proof.entity.ProofStatus;
import com.example.checkmate.domain.proof.repository.ProofRepository;
import com.example.checkmate.domain.room.entity.ProofFrequencyType;
import com.example.checkmate.domain.room.entity.Room;
import com.example.checkmate.domain.room.entity.RoomMember;
import com.example.checkmate.domain.room.entity.RoomStatus;
import com.example.checkmate.domain.room.repository.RoomMemberRepository;
import com.example.checkmate.domain.room.repository.RoomRepository;
import com.example.checkmate.domain.user.entity.UserEntity;
import com.example.checkmate.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.List;

@Service
@RequiredArgsConstructor
public class TodayStatusService {

    private final RoomRepository roomRepository;
    private final RoomMemberRepository roomMemberRepository;
    private final UserRepository userRepository;
    private final ProofRepository proofRepository;

    @Transactional(readOnly = true)
    public TodayStatusResponse getTodayStatus(String email, Long roomId) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "방을 찾을 수 없습니다."));

        UserEntity user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다."));

        roomMemberRepository.findByRoomAndUser(room, user)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "방 멤버가 아닙니다."));

        if (room.getStatus() != RoomStatus.IN_PROGRESS) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "진행 중인 방이 아닙니다.");
        }

        LocalDate today = LocalDate.now(ZoneId.of("Asia/Seoul"));
        if (today.isBefore(room.getMissionStartDate()) || today.isAfter(room.getMissionEndDate())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "미션 기간이 아닙니다.");
        }

        LocalDate periodStart;
        LocalDate periodEnd;
        if (room.getProofFrequencyType() == ProofFrequencyType.DAILY) {
            periodStart = today;
            periodEnd = today;
        } else {
            periodStart = today.with(DayOfWeek.MONDAY);
            periodEnd = today.with(DayOfWeek.SUNDAY);
        }

        LocalTime nowTime = LocalTime.now(ZoneId.of("Asia/Seoul"));
        boolean deadlinePassed;
        if (room.getProofFrequencyType() == ProofFrequencyType.DAILY) {
            deadlinePassed = nowTime.isAfter(room.getDeadlineTime());
        } else {
            deadlinePassed = today.isEqual(periodEnd) && nowTime.isAfter(room.getDeadlineTime());
        }

        List<RoomMember> roomMembers = roomMemberRepository.findAllByRoomOrderByJoinedAtAsc(room);

        List<ProofMemberStatusResponse> members = roomMembers.stream()
                .map(member -> buildMemberStatus(room, member, periodStart, periodEnd, deadlinePassed))
                .toList();

        ProofMemberStatusResponse myStatus = members.stream()
                .filter(m -> m.getUserId().equals(user.getId()))
                .findFirst()
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "본인 상태 조회 실패"));

        return new TodayStatusResponse(
                room.getId(),
                room.getProofFrequencyType().name(),
                room.getRequiredProofCount(),
                periodStart,
                periodEnd,
                room.getDeadlineTime(),
                deadlinePassed,
                myStatus,
                members
        );
    }

    private ProofMemberStatusResponse buildMemberStatus(Room room, RoomMember member,
                                                        LocalDate periodStart, LocalDate periodEnd,
                                                        boolean deadlinePassed) {
        UserEntity memberUser = member.getUser();
        int required = room.getRequiredProofCount();

        long submittedCount;
        long confirmedCount;
        if (room.getProofFrequencyType() == ProofFrequencyType.DAILY) {
            submittedCount = proofRepository.countByRoomAndUserAndProofDate(room, memberUser, periodStart);
            confirmedCount = proofRepository.countByRoomAndUserAndProofDateAndStatus(room, memberUser, periodStart, ProofStatus.CONFIRMED);
        } else {
            submittedCount = proofRepository.countByRoomAndUserAndProofDateBetween(room, memberUser, periodStart, periodEnd);
            confirmedCount = proofRepository.countByRoomAndUserAndProofDateBetweenAndStatus(room, memberUser, periodStart, periodEnd, ProofStatus.CONFIRMED);
        }

        ProofProgressStatus progressStatus;
        if (confirmedCount >= required) {
            progressStatus = ProofProgressStatus.SUCCESS;
        } else if (submittedCount >= required) {
            progressStatus = ProofProgressStatus.WAITING_CONFIRM;
        } else if (deadlinePassed) {
            progressStatus = ProofProgressStatus.MISSED;
        } else {
            progressStatus = ProofProgressStatus.NEED_SUBMIT;
        }

        long remainingSubmitCount = Math.max(required - submittedCount, 0);
        long remainingConfirmCount = Math.max(required - confirmedCount, 0);

        return new ProofMemberStatusResponse(
                memberUser.getId(),
                memberUser.getNickname(),
                member.getRole().name(),
                submittedCount,
                confirmedCount,
                required,
                remainingSubmitCount,
                remainingConfirmCount,
                progressStatus.name()
        );
    }
}
