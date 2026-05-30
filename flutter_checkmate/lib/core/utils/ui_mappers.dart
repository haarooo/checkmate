
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UiMappers {
  static final NumberFormat _numberFormat = NumberFormat('#,###');

  // ─── 기존 유지 ───────────────────────────────────────────────

  static String point(int value) => '${_numberFormat.format(value)}P';

  static String statusLabel(String status) {
    switch (status) {
      case 'RECRUITING':
        return '모집중';
      case 'READY':
        return '시작대기';
      case 'IN_PROGRESS':
        return '진행중';
      case 'SETTLED':
        return '정산완료';
      case 'FINISHED':
        return '종료';
      default:
        return status;
    }
  }

  static Color statusColor(String status) {
    switch (status) {
      case 'RECRUITING':
        return const Color(0xFFF97316);
      case 'READY':
        return const Color(0xFF3B82F6);
      case 'IN_PROGRESS':
        return const Color(0xFF22C55E);
      case 'SETTLED':
        return const Color(0xFF6B7280);
      case 'FINISHED':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  static String frequencyGoal(String frequencyType, int requiredProofCount) {
    if (frequencyType == 'WEEKLY') return '주 $requiredProofCount회';
    return '하루 $requiredProofCount회';
  }

  static String roomDescriptionFallback(String title, String? description) {
    final value = description?.trim();
    if (value != null && value.isNotEmpty) return value;
    if (title.contains('러닝') || title.contains('달리')) return '매일 아침 5km 달리기';
    if (title.contains('식단')) return '건강한 식습관 만들기';
    if (title.contains('운동')) return '친구들과 함께 운동 습관 만들기';
    return '친구들과 함께 미션 완주하기';
  }

  static String initialFromName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1);
  }

  static String roleLabel(String role) {
    switch (role) {
      case 'OWNER':
        return '방장';
      case 'MEMBER':
        return '멤버';
      default:
        return role;
    }
  }

  static String memberStatusLabel(String status) {
    switch (status) {
      case 'JOINED':
        return '참여중';
      case 'STAKED':
        return '예치완료';
      case 'SUCCESS':
        return '성공';
      case 'FAILED':
        return '실패';
      case 'SETTLED':
        return '정산완료';
      default:
        return status;
    }
  }

  static String proofProgressLabel(String status) {
    switch (status) {
      case 'SUCCESS':
        return '목표 완료';
      case 'WAITING_CONFIRM':
        return '확인 대기';
      case 'NEED_SUBMIT':
        return '제출 필요';
      case 'MISSED':
        return '기간 마감';
      case 'NEED_MORE':
        return '추가 필요';
      case 'FAILED':
        return '실패';
      case 'CONFIRMED':
        return '확인 완료';
      case 'SUBMITTED':
        return '제출 완료';
      default:
        return status;
    }
  }

  static Color proofProgressColor(String status) {
    switch (status) {
      case 'SUCCESS':
      case 'CONFIRMED':
        return const Color(0xFF22C55E);
      case 'WAITING_CONFIRM':
      case 'SUBMITTED':
        return const Color(0xFF3B82F6);
      case 'NEED_SUBMIT':
      case 'NEED_MORE':
        return const Color(0xFFF97316);
      case 'MISSED':
      case 'FAILED':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  // ─── 신규 helper ──────────────────────────────────────────────

  static String frequencyTypeLabel(String type) {
    switch (type) {
      case 'DAILY':
        return '일 단위';
      case 'WEEKLY':
        return '주 단위';
      default:
        return '인증 방식 미정';
    }
  }

  static String frequencyGoalLabel(String type, int count) {
    if (type == 'DAILY') return count == 1 ? '하루 1회 인증' : '하루 $count회 인증';
    if (type == 'WEEKLY') return count == 1 ? '매주 1회 인증' : '매주 $count회 인증';
    return '인증 방식 미정';
  }

  static String currentPeriodGoalLabel(String type, int count) {
    if (type == 'DAILY') return '오늘 $count회 제출';
    if (type == 'WEEKLY') return '이번 주 $count회 제출';
    return '인증 방식 미정';
  }

  static String currentPeriodTitle(String type) {
    switch (type) {
      case 'DAILY':
        return '오늘 인증 현황';
      case 'WEEKLY':
        return '이번 주 인증 현황';
      default:
        return '인증 현황';
    }
  }

  static String remainingSubmitLabel(String type) {
    switch (type) {
      case 'DAILY':
        return '오늘 남은 제출';
      case 'WEEKLY':
        return '이번 주 남은 제출';
      default:
        return '남은 제출';
    }
  }

  static String deadlineLabel(String type, String deadlineTime) {
    switch (type) {
      case 'DAILY':
        return '매일 $deadlineTime까지';
      case 'WEEKLY':
        return '매주 $deadlineTime까지';
      default:
        return '$deadlineTime까지';
    }
  }

  static String stakePointLabel(num point) =>
      '내 예치금 ${_numberFormat.format(point)}P';

  static String potPointLabel(num point) =>
      '총 예치금 ${_numberFormat.format(point)}P';

  static String rewardPointLabel(num point) =>
      '정산 보상 ${_numberFormat.format(point)}P';

  static String bonusPointLabel(num point) =>
      '전원 성공 보너스 ${_numberFormat.format(point)}P';

  static String feePointLabel(num point) =>
      '실패 패널티 ${_numberFormat.format(point)}P';

  static String proofProgressDescription(String status) {
    switch (status) {
      case 'SUCCESS':
        return '목표를 완료했어요.';
      case 'WAITING_CONFIRM':
        return '제출은 완료했고, 멤버 확인을 기다리는 중이에요.';
      case 'NEED_SUBMIT':
        return '아직 제출이 더 필요해요.';
      case 'MISSED':
        return '이번 기간 제출 시간이 마감됐어요.';
      case 'NEED_MORE':
        return '목표까지 추가 인증이 필요해요.';
      case 'FAILED':
        return '성공 기준을 달성하지 못했어요.';
      default:
        return '';
    }
  }

  static String successRuleLabel(int targetRate) => '인증 $targetRate% 이상 확인받기';

  static const String confirmNoticeText = '확인받은 인증만 성공으로 인정돼요';

  static const String virtualPointNoticeText = '현재 포인트는 서비스 내 가상 포인트입니다.';

  static const String penaltyNoticeText = '인증 미달 시 예치금이 다른 멤버에게 분배돼요';

  static const String bonusNoticeText = '전원 성공 시 예치금 반환 + 30% 보너스';

  static const List<String> settlementPolicyTexts = [
    '전원 성공: 모두 예치금 반환 + 성공 보너스',
    '일부 성공: 성공자가 실패자의 예치금을 나눠 받음',
    '전원 실패: 30% 패널티 후 남은 포인트 환불',
  ];
}
