# 10_today_status_research.md

## 분석 대상
GET /api/rooms/{roomId}/today-status — 현재 기간 인증 현황 조회 (읽기 전용)

## 기존 코드 참조
- RoomController @RequestMapping("/api/rooms") — /{roomId}/today-status 추가 위치
- RoomMemberRepository.findAllByRoomOrderByJoinedAtAsc() — 멤버 목록 재사용
- ProofRepository.countByRoomAndUserAndProofDate() — DAILY submittedCount 재사용
- ProofRepository.countByRoomAndUserAndProofDateBetween() — WEEKLY submittedCount 재사용

## Room status / 미션 기간 정책
- IN_PROGRESS 아니면 409
- IN_PROGRESS이어도 today < missionStartDate 또는 today > missionEndDate이면 409
- 이유: start 당일은 IN_PROGRESS이지만 missionStartDate는 다음 날

## 신규 파일
- service: TodayStatusService (domain/proof/service/)
- dto: TodayStatusResponse, ProofMemberStatusResponse, ProofProgressStatus
- ProofProgressStatus는 응답 계산용 상태이므로 entity가 아닌 dto 패키지에 위치

## ProofRepository 추가 메서드
- countByRoomAndUserAndProofDateAndStatus — DAILY confirmedCount
- countByRoomAndUserAndProofDateBetweenAndStatus — WEEKLY confirmedCount
- submittedCount는 기존 status 무관 메서드 재사용

## 검증 순서
1. room 조회 → 404
2. 멤버 여부 → 403
3. room.status != IN_PROGRESS → 409
4. today < missionStartDate 또는 today > missionEndDate → 409
5. 기간/deadlinePassed 계산 및 멤버별 count 조회

## 기간 계산
- today = LocalDate.now(ZoneId.of("Asia/Seoul"))
- DAILY: periodStart = periodEnd = today
- WEEKLY: periodStart = today.with(DayOfWeek.MONDAY), periodEnd = today.with(DayOfWeek.SUNDAY)

## 마감 판단 (deadlinePassed)
- DAILY: LocalTime.now(Asia/Seoul).isAfter(room.getDeadlineTime())
- WEEKLY: today.isEqual(periodEnd) && LocalTime.now(Asia/Seoul).isAfter(room.getDeadlineTime())
  → 월~토는 deadlineTime 지나도 그 주가 끝나지 않았으므로 MISSED 확정 안 함

## ProofProgressStatus 계산 순서
1. confirmedCount >= requiredProofCount → SUCCESS
2. submittedCount >= requiredProofCount → WAITING_CONFIRM
3. deadlinePassed → MISSED
4. else → NEED_SUBMIT

## myStatus 계산 기준
- members 중 member.getUser().getId().equals(user.getId())인 항목
- Entity 객체 비교 아님, id 비교

## 응답 구조
- TodayStatusResponse: roomId, proofFrequencyType, requiredProofCount, periodStart, periodEnd,
  deadlineTime, deadlinePassed, myStatus, members
- ProofMemberStatusResponse: userId, nickname, role, submittedCount, confirmedCount,
  requiredProofCount, remainingSubmitCount, remainingConfirmCount, status

## 제외
- DB 상태 변경 금지, RoomMemberStatus 변경 금지
- Settlement / Stats / ShareCard 구현 금지
