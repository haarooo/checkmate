# 11_member_stats_research.md

## 분석 대상
GET /api/rooms/{roomId}/members/stats — 미션 전체 기간 누적 통계 조회 (읽기 전용)

## 기존 코드 재사용
- TodayStatusService 구조 동일 (검증 → 멤버 순회 → DTO 조립)
- ProofRepository 신규 메서드 없음:
  - countByRoomAndUserAndProofDateBetween → submittedCount
  - countByRoomAndUserAndProofDateBetweenAndStatus(CONFIRMED) → confirmedCount
- RoomMemberRepository.findAllByRoomOrderByJoinedAtAsc, findByRoomAndUser 재사용

## 조회 허용 정책
- IN_PROGRESS / SETTLED: 허용
- RECRUITING / READY: 409 (missionStartDate 미설정)

## 신규 파일 (domain/proof/)
- MemberExpectedResult.java (enum, dto/) — 응답 계산용, DB 저장 아님
- MemberStatsMemberResponse.java (dto/)
- MemberStatsResponse.java (dto/)
- MemberStatsService.java (service/)

## 핵심 계산
- DAILY: totalRequiredProofCount = durationDays * requiredProofCount
- WEEKLY: totalRequiredProofCount = (durationDays / 7) * requiredProofCount
- requiredSuccessCount = (int) Math.ceil(total * targetRate / 100.0)
- proofRate = confirmedCount / totalRequiredProofCount * 100.0
- remainingRequiredCount = max(requiredSuccessCount - confirmedCount, 0)

## MemberExpectedResult 판단 순서
1. SUCCESS: confirmedCount >= requiredSuccessCount
2. WAITING_CONFIRM: IN_PROGRESS + confirmedCount < requiredSuccessCount + submittedCount >= requiredSuccessCount
   (제출은 충분하지만 확인이 부족한 상태)
3. NEED_MORE: IN_PROGRESS + confirmedCount < requiredSuccessCount + submittedCount < requiredSuccessCount
   (제출/확인 모두 더 필요한 상태)
4. FAILED: SETTLED + confirmedCount < requiredSuccessCount
   (응답용 표시값, DB 상태 아님)

## 금지 확인
- ProofStatus / RoomMemberStatus 변경 없음
- DB 상태 변경 없음, Settlement 구현 없음
