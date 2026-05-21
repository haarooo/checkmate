# 11_member_stats_plan.md

## 목표
GET /api/rooms/{roomId}/members/stats — 미션 전체 누적 통계 조회

## 신규 파일

### 1. MemberExpectedResult.java (enum, domain/proof/dto/)
SUCCESS, WAITING_CONFIRM, NEED_MORE, FAILED — 응답 계산용, DB 저장 아님

### 2. MemberStatsMemberResponse.java
userId, nickname, role, joinedAt, submittedCount, confirmedCount,
totalRequiredProofCount, requiredSuccessCount, remainingRequiredCount,
proofRate(double), expectedResult(String)

### 3. MemberStatsResponse.java
roomId, roomTitle, proofFrequencyType, requiredProofCount, targetRate,
missionStartDate, missionEndDate, totalRequiredProofCount, requiredSuccessCount,
members(List<MemberStatsMemberResponse>)

### 4. MemberStatsService.java (domain/proof/service/)
- getMemberStats(String email, Long roomId) @Transactional(readOnly=true)
- 검증: room 404 → 멤버 403 → RECRUITING/READY 409
- totalRequired: DAILY=durationDays*required / WEEKLY=(durationDays/7)*required
- requiredSuccess: (int) Math.ceil(total * targetRate / 100.0)
- 멤버별: missionStartDate~missionEndDate + 기존 Between 메서드로 count 조회
- expectedResult 판단:
  1. SUCCESS: confirmedCount >= requiredSuccessCount
  2. WAITING_CONFIRM: IN_PROGRESS + confirmedCount < requiredSuccessCount + submittedCount >= requiredSuccessCount
  3. NEED_MORE: IN_PROGRESS + confirmedCount < requiredSuccessCount + submittedCount < requiredSuccessCount
  4. FAILED: SETTLED + confirmedCount < requiredSuccessCount (응답용 표시값)

## 기존 파일 수정
RoomController.java: @GetMapping("/{roomId}/members/stats"), MemberStatsService 주입

## ProofRepository 수정 없음

## 검증
- ./gradlew.bat clean build
- Swagger: 비멤버 403 / RECRUITING 409 / 정상 200
- submittedCount / confirmedCount / proofRate / expectedResult 값 확인
