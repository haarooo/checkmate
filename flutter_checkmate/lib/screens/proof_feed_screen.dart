import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/providers/app_providers.dart';
import '../models/proof_model.dart';
import '../ui/checkmate_ui.dart';

class ProofFeedScreen extends ConsumerStatefulWidget {
  const ProofFeedScreen({super.key, required this.roomId});

  final int roomId;

  @override
  ConsumerState<ProofFeedScreen> createState() => _ProofFeedScreenState();
}

class _ProofFeedScreenState extends ConsumerState<ProofFeedScreen> {
  late Future<List<ProofFeedItemModel>> future;
  int tab = 0;
  final Set<int> confirmingIds = {};

  @override
  void initState() {
    super.initState();
    future = ref.read(proofServiceProvider).getProofFeed(widget.roomId);
  }

  void _refresh() {
    setState(() => future = ref.read(proofServiceProvider).getProofFeed(widget.roomId));
  }

  Future<void> _confirm(ProofFeedItemModel item) async {
    setState(() => confirmingIds.add(item.proofId));
    try {
      await ref.read(proofServiceProvider).confirmProof(item.proofId);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.messageFromError(e))));
    } finally {
      if (mounted) setState(() => confirmingIds.remove(item.proofId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CMPage(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 102),
      bottom: _BottomActions(roomId: widget.roomId),
      child: FutureBuilder<List<ProofFeedItemModel>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: CMColors.blue));
          }
          if (snapshot.hasError) {
            return CMErrorView(message: '인증 피드를 불러오지 못했어요.', onRetry: _refresh);
          }

          final items = snapshot.data ?? [];
          final filtered = _filter(items);

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            color: CMColors.blue,
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                CMTopBar(
                  title: '인증 피드',
                  subtitle: '인증을 확인하고 친구의 성공을 도와주세요',
                  onBack: () => context.canPop() ? context.pop() : context.go('/rooms/${widget.roomId}'),
                  actions: [
                    IconButton(
                      onPressed: () => context.push('/rooms/${widget.roomId}/chat'),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: CMColors.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _FilterChips(current: tab, onChanged: (v) => setState(() => tab = v)),
                const SizedBox(height: 18),
                if (filtered.isEmpty)
                  const CMEmptyState(title: '표시할 인증이 없어요', message: '조건에 맞는 인증 내역이 없습니다.', icon: Icons.check_circle_outline_rounded)
                else
                  ...filtered.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _ProofCard(
                          item: item,
                          loading: confirmingIds.contains(item.proofId),
                          onConfirm: () => _confirm(item),
                        ),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  List<ProofFeedItemModel> _filter(List<ProofFeedItemModel> items) {
    if (tab == 1) return items.where((e) => e.canConfirm).toList();
    if (tab == 2) return items.where((e) => e.status == 'CONFIRMED').toList();
    if (tab == 3) return items.where((e) => e.alreadyConfirmedByMe).toList();
    return items;
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.current, required this.onChanged});
  final int current;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = ['전체', '확인 필요', '확인 완료', '내가 확인'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = current == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? CMColors.blue : CMColors.gray,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    color: selected ? Colors.white : CMColors.sub,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ProofCard extends StatelessWidget {
  const _ProofCard({
    required this.item,
    required this.loading,
    required this.onConfirm,
  });

  final ProofFeedItemModel item;
  final bool loading;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final needsConfirm = item.canConfirm;
    final already = item.alreadyConfirmedByMe;
    final color = needsConfirm ? CMColors.orange : CMColors.green;
    final bg = needsConfirm ? CMColors.orangeBg : CMColors.greenBg;
    final status = needsConfirm ? '확인 필요' : (already ? '내가 확인했어요' : '확인 완료');

    return CMCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CMAvatar(label: item.nickname, color: needsConfirm ? CMColors.orange : CMColors.blue, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.nickname, style: const TextStyle(fontSize: 14, color: CMColors.text, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(timeAgo(item.createdAt), style: const TextStyle(fontSize: 10, color: CMColors.sub)),
                  ],
                ),
              ),
              CMPill(label: status, color: color, background: bg),
            ],
          ),
          const SizedBox(height: 16),
          Text(item.content?.isNotEmpty == true ? item.content! : '인증을 제출했어요.', style: const TextStyle(fontSize: 13, color: CMColors.text, height: 1.45)),
          if (item.fileUrl != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.network(
                _resolveUrl(item.fileUrl!),
                height: 76,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 76,
                  color: const Color(0xFFE5EAF2),
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported_outlined, color: CMColors.muted),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            '확인 현황 ${item.confirmationCount}/${item.requiredConfirmationCount}',
            style: const TextStyle(fontSize: 10, color: CMColors.sub, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 9),
          if (needsConfirm)
            CMPrimaryButton(
              label: '확인하기',
              onPressed: onConfirm,
              loading: loading,
              height: 42,
              icon: Icons.check_rounded,
            )
          else
            Container(
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: CMColors.greenBg, borderRadius: BorderRadius.circular(12)),
              child: Text(
                already ? '✓ 내가 확인했어요' : '확인 완료',
                style: const TextStyle(color: CMColors.green, fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ),
        ],
      ),
    );
  }

  String _resolveUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '${ApiConstants.baseUrl}$url';
    return '${ApiConstants.baseUrl}/$url';
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.roomId});
  final int roomId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: CMColors.line))),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: CMPrimaryButton(
                label: '인증 올리기',
                icon: Icons.upload_rounded,
                onPressed: () => context.push('/rooms/$roomId/submit-proof'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CMOutlineButton(
                label: '방 홈으로',
                icon: Icons.home_rounded,
                onPressed: () => context.go('/rooms/$roomId'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
