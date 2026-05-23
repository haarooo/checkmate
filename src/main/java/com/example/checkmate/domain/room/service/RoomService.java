package com.example.checkmate.domain.room.service;

import com.example.checkmate.domain.activity.entity.ActivityType;
import com.example.checkmate.domain.activity.service.RoomActivityService;
import com.example.checkmate.domain.notification.entity.NotificationType;
import com.example.checkmate.domain.notification.service.NotificationService;
import com.example.checkmate.domain.point.service.PointService;
import com.example.checkmate.domain.room.dto.JoinRoomRequest;
import com.example.checkmate.domain.room.entity.ProofFrequencyType;
import com.example.checkmate.domain.room.dto.RoomCreateRequest;
import com.example.checkmate.domain.room.dto.RoomDetailEnrichedResponse;
import com.example.checkmate.domain.room.dto.RoomDetailResponse;
import com.example.checkmate.domain.room.dto.RoomInviteResponse;
import com.example.checkmate.domain.room.dto.RoomMemberResponse;
import com.example.checkmate.domain.room.dto.RoomSummaryResponse;
import com.example.checkmate.domain.room.entity.Room;
import com.example.checkmate.domain.room.entity.RoomMember;
import com.example.checkmate.domain.room.entity.RoomMemberRole;
import com.example.checkmate.domain.room.entity.RoomMemberStatus;
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

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class RoomService {

    private final RoomRepository roomRepository;
    private final RoomMemberRepository roomMemberRepository;
    private final UserRepository userRepository;
    private final PointService pointService;
    private final RoomActivityService roomActivityService;
    private final NotificationService notificationService;

    @Transactional
    public RoomDetailResponse createRoom(String email, RoomCreateRequest request) {
        if (request.getDurationDays() < 28) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "미션 기간은 최소 28일 이상이어야 합니다.");
        }
        if (request.getStakePoint() < 1000 || request.getStakePoint() > 50000) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "예치금은 1,000P 이상 50,000P 이하여야 합니다.");
        }
        if (request.getProofFrequencyType() == ProofFrequencyType.WEEKLY) {
            if (request.getDurationDays() % 7 != 0) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "주 단위 방은 진행 기간이 7의 배수여야 합니다.");
            }
            if (request.getRequiredProofCount() > 7) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "주 단위 인증 횟수는 7 이하여야 합니다.");
            }
        }
        UserEntity user = findUserByEmail(email);
        String inviteCode = generateInviteCode();
        String inviteLinkToken = generateInviteLinkToken();

        Room room = Room.create(
                user,
                request.getTitle(),
                request.getDescription(),
                inviteCode,
                inviteLinkToken,
                request.getDurationDays(),
                request.getDeadlineTime(),
                request.getTargetRate(),
                request.getStakePoint(),
                request.getMaxMembers(),
                request.getProofFrequencyType(),
                request.getRequiredProofCount()
        );
        roomRepository.save(room);

        RoomMember owner = RoomMember.createOwner(room, user);
        roomMemberRepository.save(owner);

        return toDetailResponse(room, 1L, owner.getRole().name());
    }

    @Transactional(readOnly = true)
    public List<RoomSummaryResponse> getMyRooms(String email) {
        UserEntity user = findUserByEmail(email);
        return roomMemberRepository.findAllByUser(user).stream()
                .map(member -> new RoomSummaryResponse(
                        member.getRoom().getId(),
                        member.getRoom().getTitle(),
                        member.getRoom().getStatus().name(),
                        member.getRoom().getMaxMembers(),
                        member.getRoom().getStakePoint(),
                        member.getRoom().getInviteCode(),
                        member.getRoom().getInviteLinkToken(),
                        roomMemberRepository.countByRoom(member.getRoom()),
                        member.getRole().name(),
                        member.getRoom().getProofFrequencyType().name(),
                        member.getRoom().getRequiredProofCount()
                ))
                .toList();
    }

    @Transactional(readOnly = true)
    public RoomDetailResponse getRoomDetail(String email, Long roomId) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "방을 찾을 수 없습니다."));

        UserEntity user = findUserByEmail(email);
        RoomMember member = roomMemberRepository.findByRoomAndUser(room, user)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "방 멤버가 아닙니다."));

        return toDetailResponse(room, roomMemberRepository.countByRoom(room), member.getRole().name());
    }

    private RoomDetailResponse toDetailResponse(Room room, long memberCount, String myRole) {
        return new RoomDetailResponse(
                room.getId(),
                room.getTitle(),
                room.getDescription(),
                room.getStatus().name(),
                room.getInviteCode(),
                room.getInviteLinkToken(),
                room.getDurationDays(),
                room.getDeadlineTime(),
                room.getTargetRate(),
                room.getStakePoint(),
                room.getMaxMembers(),
                room.getPotPoint(),
                room.getMissionStartDate(),
                room.getMissionEndDate(),
                memberCount,
                myRole,
                room.getProofFrequencyType().name(),
                room.getRequiredProofCount()
        );
    }

    @Transactional(readOnly = true)
    public RoomInviteResponse getRoomByInviteLinkToken(String inviteLinkToken) {
        Room room = roomRepository.findByInviteLinkToken(inviteLinkToken)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "유효하지 않은 초대 링크입니다."));
        long count = roomMemberRepository.countByRoom(room);
        boolean joinable = room.getStatus() == RoomStatus.RECRUITING && count < room.getMaxMembers();
        return new RoomInviteResponse(
                room.getId(),
                room.getTitle(),
                room.getDescription(),
                room.getStatus().name(),
                room.getDurationDays(),
                room.getDeadlineTime(),
                room.getTargetRate(),
                room.getStakePoint(),
                room.getMaxMembers(),
                count,
                joinable,
                room.getProofFrequencyType().name(),
                room.getRequiredProofCount()
        );
    }

    @Transactional
    public RoomDetailResponse joinRoom(String email, Long roomId, JoinRoomRequest request) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "방을 찾을 수 없습니다."));
        if (!room.getInviteCode().equals(request.getInviteCode())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "초대 코드가 올바르지 않습니다.");
        }
        if (room.getStatus() != RoomStatus.RECRUITING) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "참여 가능한 상태가 아닙니다.");
        }
        UserEntity user = findUserByEmail(email);
        if (roomMemberRepository.findByRoomAndUser(room, user).isPresent()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "이미 참여한 방입니다.");
        }
        long count = roomMemberRepository.countByRoom(room);
        if (count >= room.getMaxMembers()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "최대 인원을 초과했습니다.");
        }
        RoomMember member = RoomMember.createMember(room, user);
        roomMemberRepository.save(member);
        roomActivityService.record(room, user, ActivityType.MEMBER_JOINED);
        return toDetailResponse(room, count + 1, member.getRole().name());
    }

    @Transactional(readOnly = true)
    public List<RoomMemberResponse> getRoomMembers(String email, Long roomId) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "방을 찾을 수 없습니다."));
        UserEntity user = findUserByEmail(email);
        roomMemberRepository.findByRoomAndUser(room, user)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "방 멤버가 아닙니다."));
        return roomMemberRepository.findAllByRoomOrderByJoinedAtAsc(room).stream()
                .map(m -> new RoomMemberResponse(
                        m.getUser().getId(),
                        m.getUser().getNickname(),
                        m.getRole().name(),
                        m.getStatus().name(),
                        m.getStakedPoint(),
                        m.getJoinedAt(),
                        m.getStakedAt()
                ))
                .toList();
    }

    @Transactional
    public RoomDetailResponse stakeRoom(String email, Long roomId) {
        Room room = roomRepository.findByIdForUpdate(roomId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "방을 찾을 수 없습니다."));

        UserEntity user = findUserByEmail(email);
        RoomMember member = roomMemberRepository.findByRoomAndUser(room, user)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "방 멤버가 아닙니다."));

        if (room.getStatus() != RoomStatus.RECRUITING) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "모집 중인 방이 아닙니다.");
        }
        if (member.getStatus() != RoomMemberStatus.JOINED) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "이미 예치금을 납부한 상태입니다.");
        }

        pointService.deductForRoomStake(user, room.getStakePoint(), room.getId());
        member.stake(room.getStakePoint());
        room.addPotPoint(room.getStakePoint());
        roomActivityService.record(room, user, ActivityType.MEMBER_STAKED);

        long totalCount = roomMemberRepository.countByRoom(room);
        long stakedCount = roomMemberRepository.countByRoomAndStatus(room, RoomMemberStatus.STAKED);
        if (totalCount == room.getMaxMembers() && stakedCount == room.getMaxMembers()) {
            room.markReady();
            roomActivityService.record(room, null, ActivityType.ROOM_READY);
        }

        return toDetailResponse(room, totalCount, member.getRole().name());
    }

    @Transactional
    public RoomDetailResponse startRoom(String email, Long roomId) {
        Room room = roomRepository.findByIdForUpdate(roomId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "방을 찾을 수 없습니다."));

        UserEntity user = findUserByEmail(email);
        RoomMember member = roomMemberRepository.findByRoomAndUser(room, user)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "방 멤버가 아닙니다."));

        if (member.getRole() != RoomMemberRole.OWNER) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "방장만 시작할 수 있습니다.");
        }
        if (room.getStatus() != RoomStatus.READY) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "READY 상태의 방만 시작할 수 있습니다.");
        }

        long currentCount = roomMemberRepository.countByRoom(room);
        if (currentCount != room.getMaxMembers()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "전원이 참여해야 시작할 수 있습니다.");
        }

        long stakedCount = roomMemberRepository.countByRoomAndStatus(room, RoomMemberStatus.STAKED);
        if (stakedCount != room.getMaxMembers()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "전원이 예치금을 납부해야 시작할 수 있습니다.");
        }

        LocalDate missionStartDate = LocalDate.now(ZoneId.of("Asia/Seoul")).plusDays(1);
        LocalDate missionEndDate = missionStartDate.plusDays(room.getDurationDays() - 1);
        room.start(missionStartDate, missionEndDate);
        roomActivityService.record(room, user, ActivityType.ROOM_STARTED);
        List<RoomMember> allMembers = roomMemberRepository.findAllByRoomOrderByJoinedAtAsc(room);
        for (RoomMember m : allMembers) {
            notificationService.notify(room, m.getUser(), NotificationType.ROOM_STARTED, null);
        }

        return toDetailResponse(room, currentCount, member.getRole().name());
    }

    @Transactional(readOnly = true)
    public RoomDetailEnrichedResponse getRoomDetailEnriched(String email, Long roomId) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "방을 찾을 수 없습니다."));

        UserEntity user = findUserByEmail(email);
        RoomMember myMember = roomMemberRepository.findByRoomAndUser(room, user)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "방 멤버가 아닙니다."));

        List<RoomMember> roomMembers = roomMemberRepository.findAllByRoomOrderByJoinedAtAsc(room);

        List<RoomMemberResponse> memberResponses = roomMembers.stream()
                .map(m -> new RoomMemberResponse(
                        m.getUser().getId(),
                        m.getUser().getNickname(),
                        m.getRole().name(),
                        m.getStatus().name(),
                        m.getStakedPoint(),
                        m.getJoinedAt(),
                        m.getStakedAt()))
                .toList();

        return new RoomDetailEnrichedResponse(
                room.getId(), room.getTitle(), room.getDescription(),
                room.getStatus().name(), room.getInviteCode(), room.getInviteLinkToken(),
                room.getOwner().getId(), room.getOwner().getNickname(),
                myMember.getRole().name(), myMember.getStatus().name(),
                room.getProofFrequencyType().name(), room.getRequiredProofCount(),
                room.getDurationDays(), room.getDeadlineTime(),
                room.getTargetRate(), room.getStakePoint(), room.getMaxMembers(),
                roomMembers.size(), room.getPotPoint(),
                room.getMissionStartDate(), room.getMissionEndDate(),
                room.getCreatedAt(), memberResponses
        );
    }

    private String generateInviteCode() {
        String code;
        do {
            code = UUID.randomUUID().toString().replace("-", "").substring(0, 6);
        } while (roomRepository.existsByInviteCode(code));
        return code;
    }

    private String generateInviteLinkToken() {
        String token;
        do {
            token = UUID.randomUUID().toString().replace("-", "");
        } while (roomRepository.existsByInviteLinkToken(token));
        return token;
    }

    private UserEntity findUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다."));
    }
}