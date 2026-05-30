import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CMColors {
  static const bg = Color(0xFFF6F8FC);
  static const card = Color(0xFFFFFFFF);
  static const text = Color(0xFF111827);
  static const sub = Color(0xFF6B7280);
  static const muted = Color(0xFF94A3B8);
  static const line = Color(0xFFE5EAF2);

  static const blue = Color(0xFF2563EB);
  static const blue2 = Color(0xFF1D4ED8);
  static const blue3 = Color(0xFF3B82F6);

  static const green = Color(0xFF16A34A);
  static const greenBg = Color(0xFFEAF8EF);
  static const orange = Color(0xFFF97316);
  static const orangeBg = Color(0xFFFFF3E7);
  static const red = Color(0xFFEF4444);
  static const redBg = Color(0xFFFEECEC);
  static const purple = Color(0xFF7C3AED);
  static const purpleBg = Color(0xFFF2EAFE);
  static const gray = Color(0xFFF1F5F9);
  static const dark = Color(0xFF334155);
}

String formatPoint(num value) {
  return '${NumberFormat('#,###').format(value)}P';
}

String formatDate(DateTime? date) {
  if (date == null || date.year == 0) return '-';
  return DateFormat('yyyy.MM.dd').format(date);
}

String formatDateTime(DateTime date) {
  return DateFormat('yyyy.MM.dd  HH:mm').format(date);
}

String proofFrequencyText(String type, int count) {
  final upper = type.toUpperCase();
  if (upper == 'DAILY') return '하루 $count회 인증';
  if (upper == 'WEEKLY') return '매주 $count회 인증';
  return '$count회 인증';
}

String roomStatusText(String status) {
  switch (status.toUpperCase()) {
    case 'IN_PROGRESS':
      return '진행중';
    case 'SETTLED':
      return '정산완료';
    case 'READY':
      return '시작대기';
    case 'RECRUITING':
      return '모집중';
    default:
      return status;
  }
}

String memberExpectedText(String status) {
  switch (status.toUpperCase()) {
    case 'SUCCESS':
      return '충족';
    case 'WAITING_CONFIRM':
      return '확인 대기';
    case 'NEED_MORE':
      return '부족';
    case 'FAILED':
      return '실패';
    default:
      return status;
  }
}

Color statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'SUCCESS':
    case 'CONFIRMED':
    case 'IN_PROGRESS':
      return CMColors.green;
    case 'WAITING_CONFIRM':
    case 'PENDING':
      return CMColors.orange;
    case 'FAILED':
    case 'NEED_MORE':
      return CMColors.red;
    default:
      return CMColors.sub;
  }
}

Color statusBgColor(String status) {
  switch (status.toUpperCase()) {
    case 'SUCCESS':
    case 'CONFIRMED':
    case 'IN_PROGRESS':
      return CMColors.greenBg;
    case 'WAITING_CONFIRM':
    case 'PENDING':
      return CMColors.orangeBg;
    case 'FAILED':
    case 'NEED_MORE':
      return CMColors.redBg;
    default:
      return CMColors.gray;
  }
}

String initials(String value) {
  final t = value.trim();
  if (t.isEmpty) return '?';
  return t.characters.first;
}

String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return '방금 전';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  if (diff.inDays < 7) return '${diff.inDays}일 전';
  return DateFormat('M월 d일 HH:mm').format(date);
}

int readInt(dynamic v, {int fallback = 0}) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

double readDouble(dynamic v, {double fallback = 0}) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

String readString(dynamic v, {String fallback = ''}) {
  if (v == null) return fallback;
  return v.toString();
}

DateTime? readDate(dynamic v) {
  if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
  return null;
}

class CMPage extends StatelessWidget {
  const CMPage({
    super.key,
    required this.child,
    this.bottom,
    this.padding = const EdgeInsets.fromLTRB(24, 20, 24, 24),
  });

  final Widget child;
  final Widget? bottom;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CMColors.bg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ),
          if (bottom != null)
            Positioned(left: 0, right: 0, bottom: 0, child: bottom!),
        ],
      ),
    );
  }
}

class CMTopBar extends StatelessWidget {
  const CMTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions = const [],
    this.badge,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null) ...[
          GestureDetector(
            onTap: onBack,
            child: const Icon(Icons.arrow_back_rounded, size: 24, color: CMColors.text),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: CMColors.text,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    CMPill(label: badge!, color: CMColors.green, background: CMColors.greenBg),
                  ],
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle!, style: const TextStyle(fontSize: 12, color: CMColors.sub)),
              ],
            ],
          ),
        ),
        ...actions,
      ],
    );
  }
}

class CMCard extends StatelessWidget {
  const CMCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.radius = 24,
    this.background = CMColors.card,
    this.borderColor = const Color(0xFFE8EEF6),
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final double radius;
  final Color background;
  final Color borderColor;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}


class CMGradientCard extends StatelessWidget {
  const CMGradientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.radius = 24,
    this.colors = const [CMColors.blue3, CMColors.blue2],
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: CMColors.blue.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class CMPill extends StatelessWidget {
  const CMPill({
    super.key,
    required this.label,
    this.color = CMColors.blue,
    this.background = const Color(0xFFEFF6FF),
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    this.fontSize = 10,
  });

  final String label;
  final Color color;
  final Color background;
  final EdgeInsets padding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}


class CMPrimaryButton extends StatelessWidget {
  const CMPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 52,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: CMColors.blue,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      disabledBackgroundColor: CMColors.blue.withValues(alpha: 0.55),
    );

    final child = loading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900));

    return SizedBox(
      height: height,
      width: double.infinity,
      child: icon == null
          ? ElevatedButton(
              onPressed: loading ? null : onPressed,
              style: style,
              child: child,
            )
          : ElevatedButton.icon(
              onPressed: loading ? null : onPressed,
              icon: loading ? const SizedBox.shrink() : Icon(icon, size: 18),
              label: child,
              style: style,
            ),
    );
  }
}

class CMOutlineButton extends StatelessWidget {
  const CMOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.check_circle_outline_rounded, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
        style: OutlinedButton.styleFrom(
          foregroundColor: CMColors.blue,
          side: const BorderSide(color: CMColors.blue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}

class CMAvatar extends StatelessWidget {
  const CMAvatar({
    super.key,
    required this.label,
    this.color = CMColors.blue,
    this.size = 42,
  });

  final String label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Text(
        initials(label),
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: size * 0.34),
      ),
    );
  }
}

class CMInfoRow extends StatelessWidget {
  const CMInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 16, color: CMColors.muted),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 12, color: CMColors.sub)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12, color: CMColors.text, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class CMProgressBar extends StatelessWidget {
  const CMProgressBar({
    super.key,
    required this.value,
    this.color = CMColors.blue,
    this.background = const Color(0xFFE8EEF6),
    this.height = 7,
  });

  final double value;
  final Color color;
  final Color background;
  final double height;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: v,
        minHeight: height,
        backgroundColor: background,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class CMCircularProgress extends StatelessWidget {
  const CMCircularProgress({
    super.key,
    required this.percent,
    this.size = 72,
    this.color = Colors.white,
  });

  final double percent;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percent.clamp(0, 100) / 100,
            strokeWidth: 7,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text(
            '${percent.round()}%',
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: size * 0.24),
          ),
        ],
      ),
    );
  }
}

class CMBottomNav extends StatelessWidget {
  const CMBottomNav({super.key, required this.current, required this.onTap});

  final String current;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(Icons.home_rounded, '홈', 'home'),
      _NavItem(Icons.flag_rounded, '미션방', 'rooms'),
      _NavItem(Icons.check_circle_rounded, '인증', 'proof'),
      _NavItem(Icons.person_rounded, '마이', 'my'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 9, 18, 13),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: CMColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            final active = current == item.key;
            final color = active ? CMColors.blue : CMColors.muted;
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onTap(item.key),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, size: 23, color: color),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: color,
                        fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label, this.key);
  final IconData icon;
  final String label;
  final String key;
}

class CMEmptyState extends StatelessWidget {
  const CMEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CMCard(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: CMColors.muted),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(message, style: const TextStyle(color: CMColors.sub, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class CMErrorView extends StatelessWidget {
  const CMErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CMCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: CMColors.red, size: 36),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: CMColors.sub)),
            const SizedBox(height: 16),
            CMPrimaryButton(label: '다시 시도', onPressed: onRetry, height: 44, icon: Icons.refresh_rounded),
          ],
        ),
      ),
    );
  }
}
