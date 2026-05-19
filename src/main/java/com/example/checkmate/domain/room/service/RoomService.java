package com.example.checkmate.domain.room.service;

import com.example.checkmate.domain.room.dto.RoomCreateRequest;
import com.example.checkmate.domain.room.dto.RoomDetailResponse;
import com.example.checkmate.domain.room.dto.RoomInviteResponse;
import com.example.checkmate.domain.room.dto.RoomMemberResponse;
import com.example.checkmate.domain.room.dto.RoomSummaryResponse;
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
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class RoomService {

    private final RoomRepository roomRepository;
    private final RoomMemberRepository roomMemberRepository;
    private final UserRepository userRepository;

    @Transactional
    public RoomDetailResponse createRoom(String email, RoomCreateRequest request) {
        UserEntity user = findUserByEmail(email);
        String inviteCode = generateInviteCode();

        Room room = Room.create(
                user,
                request.getTitle(),
                request.getDescription(),
                inviteCode,
                request.getDurationDays(),
                request.getDeadlineTime(),
                request.getTargetRate(),
                request.getStakePoint(),
                request.getMaxMembers()
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
                        roomMemberRepository.countByRoom(member.getRoom()),
                        member.getRole().name()
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
                room.getDurationDays(),
                room.getDeadlineTime(),
                room.getTargetRate(),
                room.getStakePoint(),
                room.getMaxMembers(),
                room.getPotPoint(),
                room.getMissionStartDate(),
                room.getMissionEndDate(),
                memberCount,
                myRole
        );
    }

    @Transactional(readOnly = true)
    public RoomInviteResponse getRoomByInviteCode(String inviteCode) {
        Room room = roomRepository.findByInviteCode(inviteCode)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "유효하지 않은 초대 코드입니다."));
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
                joinable
        );
    }

    @Transactional
    public RoomDetailResponse joinRoom(String email, Long roomId) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "방을 찾을 수 없습니다."));
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
                        m.getJoinedAt()
                ))
                .toList();
    }

    private String generateInviteCode() {
        String code;
        do {
            code = UUID.randomUUID().toString().replace("-", "").substring(0, 8);
        } while (roomRepository.existsByInviteCode(code));
        return code;
    }

    private UserEntity findUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다."));
    }
}