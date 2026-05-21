package com.example.checkmate.domain.proof.service;

import com.example.checkmate.domain.proof.dto.MemberExpectedResult;
import com.example.checkmate.domain.proof.dto.MemberStatsMemberResponse;
import com.example.checkmate.domain.proof.dto.MemberStatsResponse;
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

import java.util.List;

@Service
@RequiredArgsConstructor
public class MemberStatsService {

    private final RoomRepository roomRepository;
    private final RoomMemberRepository roomMemberRepository;
    private final UserRepository userRepository;
    private final ProofRepository proofRepository;

    @Transactional(readOnly = true)
    public MemberStatsResponse getMemberStats(String email, Long roomId) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "방을 찾을 수 없습니다."));

        UserEntity user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다."));

        roomMemberRepository.findByRoomAndUser(room, user)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "방 멤버가 아닙니다."));

        if (room.getStatus() == RoomStatus.RECRUITING || room.getStatus() == RoomStatus.READY) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "미션이 시작되지 않은 방입니다.");
        }

        int totalRequiredProofCount;
        if (room.getProofFrequencyType() == ProofFrequencyType.DAILY) {
            totalRequiredProofCount = room.getDurationDays() * room.getRequiredProofCount();
        } else {
            totalRequiredProofCount = (room.getDurationDays() / 7) * room.getRequiredProofCount();
        }

        int requiredSuccessCount = (int) Math.ceil(totalRequiredProofCount * room.getTargetRate() / 100.0);

        List<RoomMember> roomMembers = roomMemberRepository.findAllByRoomOrderByJoinedAtAsc(room);

        List<MemberStatsMemberResponse> members = roomMembers.stream()
                .map(member -> buildMemberStats(room, member, totalRequiredProofCount, requiredSuccessCount))
                .toList();

        return new MemberStatsResponse(
                room.getId(),
                room.getTitle(),
                room.getProofFrequencyType().name(),
                room.getRequiredProofCount(),
                room.getTargetRate(),
                room.getMissionStartDate(),
                room.getMissionEndDate(),
                totalRequiredProofCount,
                requiredSuccessCount,
                members
        );
    }

    private MemberStatsMemberResponse buildMemberStats(Room room, RoomMember member,
                                                        int totalRequiredProofCount, int requiredSuccessCount) {
        UserEntity memberUser = member.getUser();

        long submittedCount = proofRepository.countByRoomAndUserAndProofDateBetween(
                room, memberUser, room.getMissionStartDate(), room.getMissionEndDate());
        long confirmedCount = proofRepository.countByRoomAndUserAndProofDateBetweenAndStatus(
                room, memberUser, room.getMissionStartDate(), room.getMissionEndDate(), ProofStatus.CONFIRMED);

        long remainingRequiredCount = Math.max(requiredSuccessCount - confirmedCount, 0);
        double proofRate = totalRequiredProofCount == 0 ? 0.0
                : confirmedCount / (double) totalRequiredProofCount * 100.0;

        MemberExpectedResult expectedResult;
        if (confirmedCount >= requiredSuccessCount) {
            expectedResult = MemberExpectedResult.SUCCESS;
        } else if (room.getStatus() == RoomStatus.IN_PROGRESS && submittedCount >= requiredSuccessCount) {
            expectedResult = MemberExpectedResult.WAITING_CONFIRM;
        } else if (room.getStatus() == RoomStatus.IN_PROGRESS) {
            expectedResult = MemberExpectedResult.NEED_MORE;
        } else {
            expectedResult = MemberExpectedResult.FAILED;
        }

        return new MemberStatsMemberResponse(
                memberUser.getId(),
                memberUser.getNickname(),
                member.getRole().name(),
                member.getJoinedAt(),
                submittedCount,
                confirmedCount,
                totalRequiredProofCount,
                requiredSuccessCount,
                remainingRequiredCount,
                proofRate,
                expectedResult.name()
        );
    }
}
