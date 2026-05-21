package com.example.checkmate.domain.proof.service;

import com.example.checkmate.domain.proof.dto.ProofConfirmResponse;
import com.example.checkmate.domain.proof.dto.ProofFeedItemResponse;
import com.example.checkmate.domain.proof.dto.ProofSubmitResponse;
import com.example.checkmate.domain.proof.entity.Proof;
import com.example.checkmate.domain.proof.entity.ProofConfirmation;
import com.example.checkmate.domain.proof.entity.ProofStatus;
import com.example.checkmate.domain.proof.repository.ProofConfirmationRepository;
import com.example.checkmate.domain.proof.repository.ProofRepository;
import com.example.checkmate.domain.room.entity.ProofFrequencyType;
import com.example.checkmate.domain.room.entity.Room;
import com.example.checkmate.domain.room.entity.RoomMember;
import com.example.checkmate.domain.room.entity.RoomStatus;
import com.example.checkmate.domain.room.repository.RoomMemberRepository;
import com.example.checkmate.domain.room.repository.RoomRepository;
import com.example.checkmate.domain.user.entity.UserEntity;
import com.example.checkmate.domain.user.repository.UserRepository;
import com.example.checkmate.global.storage.FileUploadResult;
import com.example.checkmate.global.storage.LocalFileStorageService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ProofService {

    private final ProofRepository proofRepository;
    private final ProofConfirmationRepository proofConfirmationRepository;
    private final RoomRepository roomRepository;
    private final RoomMemberRepository roomMemberRepository;
    private final UserRepository userRepository;
    private final LocalFileStorageService fileStorageService;

    @Transactional
    public ProofSubmitResponse submitProof(String email, Long roomId, String content, MultipartFile file) {
        Room room = roomRepository.findByIdForUpdate(roomId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "방을 찾을 수 없습니다."));

        UserEntity user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다."));

        roomMemberRepository.findByRoomAndUser(room, user)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "방 멤버가 아닙니다."));

        if (room.getStatus() != RoomStatus.IN_PROGRESS) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "진행 중인 방이 아닙니다.");
        }

        LocalDate proofDate = LocalDate.now(ZoneId.of("Asia/Seoul"));
        if (proofDate.isBefore(room.getMissionStartDate()) || proofDate.isAfter(room.getMissionEndDate())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "미션 기간이 아닙니다.");
        }

        LocalTime nowTime = LocalTime.now(ZoneId.of("Asia/Seoul"));
        if (nowTime.isAfter(room.getDeadlineTime())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "오늘 인증 마감 시간이 지났습니다.");
        }

        if (file != null && file.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "파일이 비어 있습니다.");
        }

        boolean hasContent = content != null && !content.isBlank();
        boolean hasFile = file != null;
        if (!hasContent && !hasFile) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "content 또는 file 중 하나는 필수입니다.");
        }

        long submitCount;
        if (room.getProofFrequencyType() == ProofFrequencyType.DAILY) {
            submitCount = proofRepository.countByRoomAndUserAndProofDate(room, user, proofDate);
        } else {
            LocalDate weekStart = proofDate.with(DayOfWeek.MONDAY);
            LocalDate weekEnd = proofDate.with(DayOfWeek.SUNDAY);
            submitCount = proofRepository.countByRoomAndUserAndProofDateBetween(room, user, weekStart, weekEnd);
        }

        if (submitCount >= room.getRequiredProofCount()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "제출 가능한 횟수를 초과했습니다.");
        }

        String fileUrl = null;
        String fileOriginalName = null;
        String fileStoredName = null;
        Long fileSize = null;
        String fileContentType = null;

        if (hasFile) {
            FileUploadResult result = fileStorageService.store(file);
            fileUrl = result.getFileUrl();
            fileOriginalName = result.getOriginalName();
            fileStoredName = result.getStoredName();
            fileSize = result.getSize();
            fileContentType = result.getContentType();
        }

        Proof proof = Proof.create(
                room, user, proofDate,
                hasContent ? content : null,
                fileUrl, fileOriginalName, fileStoredName, fileSize, fileContentType
        );
        proofRepository.save(proof);

        return new ProofSubmitResponse(
                proof.getId(),
                room.getId(),
                user.getId(),
                proof.getProofDate(),
                proof.getContent(),
                proof.getStatus().name(),
                proof.getCreatedAt(),
                proof.getFileUrl(),
                proof.getFileOriginalName(),
                proof.getFileStoredName(),
                proof.getFileSize(),
                proof.getFileContentType()
        );
    }

    @Transactional(readOnly = true)
    public List<ProofFeedItemResponse> getProofFeed(String email, Long roomId) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "방을 찾을 수 없습니다."));

        UserEntity currentUser = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다."));

        roomMemberRepository.findByRoomAndUser(room, currentUser)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "방 멤버가 아닙니다."));

        return proofRepository.findByRoomOrderByCreatedAtDesc(room).stream()
                .map(proof -> {
                    long confirmationCount = proofConfirmationRepository.countByProof(proof);
                    boolean isMine = proof.getUser().getId().equals(currentUser.getId());
                    boolean alreadyConfirmedByMe = !isMine &&
                            proofConfirmationRepository.existsByProofAndConfirmer(proof, currentUser);
                    boolean canConfirm = !isMine && !alreadyConfirmedByMe;
                    return new ProofFeedItemResponse(
                            proof.getId(),
                            room.getId(),
                            proof.getUser().getId(),
                            proof.getUser().getNickname(),
                            proof.getContent(),
                            proof.getFileUrl(),
                            proof.getFileOriginalName(),
                            proof.getFileContentType(),
                            proof.getStatus().name(),
                            proof.getProofDate(),
                            proof.getCreatedAt(),
                            proof.getConfirmedAt(),
                            confirmationCount,
                            1L,
                            canConfirm,
                            isMine,
                            alreadyConfirmedByMe
                    );
                }).toList();
    }

    @Transactional
    public ProofConfirmResponse confirmProof(String email, Long proofId) {
        Proof proof = proofRepository.findByIdForUpdate(proofId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "인증을 찾을 수 없습니다."));

        UserEntity user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다."));

        roomMemberRepository.findByRoomAndUser(proof.getRoom(), user)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "방 멤버가 아닙니다."));

        if (proof.getUser().getId().equals(user.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "본인의 인증은 확인할 수 없습니다.");
        }

        if (proofConfirmationRepository.existsByProofAndConfirmer(proof, user)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "이미 확인한 인증입니다.");
        }

        if (proof.getStatus() != ProofStatus.CONFIRMED) {
            proof.confirm(LocalDateTime.now(ZoneId.of("Asia/Seoul")));
        }

        proofConfirmationRepository.save(ProofConfirmation.create(proof, proof.getRoom(), user));

        return new ProofConfirmResponse(
                proof.getId(),
                user.getId(),
                proof.getConfirmedAt(),
                proof.getStatus().name()
        );
    }
}
