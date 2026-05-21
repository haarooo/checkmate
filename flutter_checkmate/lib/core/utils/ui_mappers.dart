
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UiMappers {
  static final NumberFormat _numberFormat = NumberFormat('#,###');

  static String point(int value) => '${_numberFormat.format(value)}P';

  static String statusLabel(String status) {
    switch (status) {
      case 'RECRUITING':
        return '모집중';
      case 'READY':
        return '대기중';
      case 'IN_PROGRESS':
        return '진행중';
      case 'SETTLED':
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
        return '확인완료';
      case 'WAITING_CONFIRM':
        return '확인대기';
      case 'NEED_SUBMIT':
      case 'NEED_MORE':
        return '제출필요';
      case 'MISSED':
      case 'FAILED':
        return '미달성';
      default:
        return status;
    }
  }

  static Color proofProgressColor(String status) {
    switch (status) {
      case 'SUCCESS':
        return const Color(0xFF22C55E);
      case 'WAITING_CONFIRM':
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
}
