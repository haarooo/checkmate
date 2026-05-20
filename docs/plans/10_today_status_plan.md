# 10_today_status_plan.md

## 목표
GET /api/rooms/{roomId}/today-status — 현재 기간 인증 현황 조회

## 신규 파일

### 1. ProofProgressStatus.java (enum, domain/proof/dto/)
- SUCCESS, WAITING_CONFIRM, NEED_SUBMIT, MISSED
- DB 저장용 아님, 응답 계산용

### 2. ProofMemberStatusResponse.java (DTO)
- userId, nickname, role, submittedCount, confirmedCount, requiredProofCount
- remainingSubmitCount, remainingConfirmCount, status(String)

### 3. TodayStatusResponse.java (DTO)
- roomId, proofFrequencyType, requiredProofCount, periodStart, periodEnd
- deadlineTime, deadlinePassed, myStatus, members

### 4. TodayStatusService.java (domain/proof/service/)
- getTodayStatus(String email, Long roomId) @Transactional(readOnly=true)
- 검증 순서:
  1. room 404
  2. 멤버 403
  3. IN_PROGRESS 아님 409
  4. today < missionStartDate 또는 today > missionEndDate → 409
- 기간/deadlinePassed 계산 후 전체 멤버 순회하며 submittedCount/confirmedCount 조회
- ProofProgressStatus 판단 → ProofMemberStatusResponse 생성
- myStatus: members 중 member.getUser().getId().equals(user.getId())인 항목

## 기존 파일 수정

### ProofRepository.java
- countByRoomAndUserAndProofDateAndStatus 추가
- countByRoomAndUserAndProofDateBetweenAndStatus 추가

### RoomController.java
- @GetMapping("/{roomId}/today-status") 추가, TodayStatusService 주입

## 검증
- ./gradlew.bat clean build 성공
- Swagger: 비멤버 403 / IN_PROGRESS 아닌 방 409 / 미션 기간 외 409 / DAILY·WEEKLY 정상 200
- submittedCount / confirmedCount / status 값 확인
