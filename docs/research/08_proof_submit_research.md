# 08_proof_submit_research.md

## 분석 대상
POST /api/rooms/{roomId}/proofs — 방 멤버가 IN_PROGRESS 방에 인증 제출

## 기존 코드 참조
- RoomRepository.findByIdForUpdate() — 비관적 락으로 동시 제출 직렬화 (기존 메서드 재사용)
- RoomMemberRepository.findByRoomAndUser() — 멤버 검증 패턴 재사용
- LocalFileStorageService.store(MultipartFile) → FileUploadResult — 파일 있을 때만 호출
- UserRepository.findByEmail() — 기존 패턴 동일
- BaseTime 상속 패턴, @Getter/@NoArgsConstructor(PROTECTED) Entity 규칙 준수

## 신규 패키지: domain/proof/
- entity: Proof, ProofStatus
- repository: ProofRepository
- service: ProofService
- controller: ProofController
- dto: ProofSubmitResponse

## Proof Entity 핵심 설계
- proofs 테이블 기반: room(FK), user(FK), proofDate, content(nullable),
  fileUrl/fileOriginalName/fileStoredName/fileSize/fileContentType (모두 nullable),
  status, confirmedAt(nullable)
- 정적 팩토리 메서드 create() 사용

## ProofRepository 필요 메서드
- `countByRoomAndUserAndProofDate` — DAILY 당일 제출 수
- `countByRoomAndUserAndProofDateBetween` — WEEKLY 주차 제출 수

## content/file 판단 기준
- content: null 또는 isBlank() → content 없음 (공백만 있는 문자열도 없음으로 처리)
- file: null → 파일 없음 / file != null && file.isEmpty() → 400 (빈 파일 업로드 시도)
- content 없음 + file 없음(null) → 400

## 미션 기간 검증
- proofDate = LocalDate.now(ZoneId.of("Asia/Seoul"))
- start 당일은 missionStartDate = 오늘+1일이므로 proofDate < missionStartDate → 인증 불가
- proofDate < missionStartDate 또는 proofDate > missionEndDate → 409
- room.status == IN_PROGRESS 확인 직후, 제출 수 계산 전에 수행

## 제출 제한 날짜 로직
- DAILY: proofDate 기준 당일 제출 수 조회
- WEEKLY: weekStart = proofDate.with(DayOfWeek.MONDAY)
          weekEnd   = proofDate.with(DayOfWeek.SUNDAY)
          → countByRoomAndUserAndProofDateBetween(room, user, weekStart, weekEnd)
- import java.time.DayOfWeek 필요

## 동시성 처리
- findByIdForUpdate(roomId)로 방 row 비관적 락 획득
- count 조회 → Proof 저장까지 같은 트랜잭션 내에서 직렬화
- 신규 Repository 메서드 추가 없음

## deadlineTime 검증
- LocalTime nowTime = LocalTime.now(ZoneId.of("Asia/Seoul"))
- nowTime.isAfter(room.getDeadlineTime()) → 409
- deadline 시각 자체(isEqual)는 통과, 이후(isAfter)만 차단
- import java.time.LocalTime 필요

## 검증 순서
1. 방 조회 (findByIdForUpdate) → 404
2. 사용자 조회
3. 멤버 여부 → 403
4. room.status != IN_PROGRESS → 409
5. proofDate가 missionStartDate~missionEndDate 범위 밖 → 409
6. nowTime.isAfter(room.getDeadlineTime()) → 409
7. file != null && file.isEmpty() → 400
8. content 없음 + file 없음(null) → 400
9. DAILY/WEEKLY 제출 수 >= requiredProofCount → 409
10. 파일 있으면 store() 호출
11. Proof 저장 (status = SUBMITTED)

## Controller 입력
- @RequestParam(required=false) String content
- @RequestPart(required=false) MultipartFile file
- consumes = MULTIPART_FORM_DATA_VALUE

## 제외
- Proof Confirm/Today Status/Stats/Settlement/ShareCard 구현 금지
