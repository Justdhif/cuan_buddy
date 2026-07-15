import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/widgets/avatar_border_helper.dart';

/// Horizontal scrollable row of selected-user chips.
class SelectedUsersChipRow extends StatefulWidget {
  const SelectedUsersChipRow({
    super.key,
    required this.selectedIds,
    required this.friendMap,
    required this.isDark,
    this.onRemove,
    this.isReadonly = false,
    this.contentPadding = const EdgeInsets.only(
      left: 16,
      right: 16,
      top: 10,
      bottom: 4,
    ),
    this.accentColor,
  });

  final List<String> selectedIds;
  final Map<String, dynamic> friendMap;
  final bool isDark;
  final void Function(String id)? onRemove;
  final bool isReadonly;
  final EdgeInsetsGeometry contentPadding;
  final Color? accentColor;

  @override
  State<SelectedUsersChipRow> createState() => _SelectedUsersChipRowState();
}

class _SelectedUsersChipRowState extends State<SelectedUsersChipRow> with TickerProviderStateMixin {
  // Per-chip animation controllers (also tracks chips animating out)
  final Map<String, AnimationController> _ctrls = {};
  // Render list: includes chips currently animating out
  final List<String> _renderIds = [];

  @override
  void initState() {
    super.initState();
    // Pre-populate without animation (screen opens with 0 selected usually)
    for (final id in widget.selectedIds) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 320),
        value: 1.0, // already visible
      );
      _ctrls[id] = ctrl;
      _renderIds.add(id);
    }
  }

  @override
  void didUpdateWidget(SelectedUsersChipRow old) {
    super.didUpdateWidget(old);

    final oldSet = old.selectedIds.toSet();
    final newSet = widget.selectedIds.toSet();

    // ── Added chips ──────────────────────────────────────────────────────────
    for (final id in widget.selectedIds) {
      if (!oldSet.contains(id)) {
        final ctrl = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 320),
        );
        _ctrls[id] = ctrl;
        // Insert at front to match parent ordering
        setState(() => _renderIds.insert(0, id));
        ctrl.forward();
      }
    }

    // ── Removed chips ────────────────────────────────────────────────────────
    for (final id in old.selectedIds) {
      if (!newSet.contains(id)) {
        _ctrls[id]?.reverse().then((_) {
          if (mounted) {
            setState(() {
              _renderIds.remove(id);
              _ctrls.remove(id)?.dispose();
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: widget.contentPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _renderIds.map((id) {
            final ctrl = _ctrls[id]!;
            final friend =
                widget.friendMap[id] as Map<String, dynamic>? ?? {};
            final fallbackName = (friend['fullName'] ??
                    friend['email'] ??
                    '') as String;
            final username = friend['username'] as String?;
            final displayName = username != null ? '@$username' : fallbackName;
            final avatarUrl = friend['avatar'] as String?;
            final avatarBorderId = friend['avatarBorder'] as String?;
            final borderAsset = borderAssetFromId(avatarBorderId);

            // SizeTransition grows width 0→full (pushes siblings right)
            // FadeTransition fades the content in/out simultaneously
            return SizeTransition(
              sizeFactor: CurvedAnimation(
                parent: ctrl,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              ),
              axis: Axis.horizontal,
              alignment: Alignment.centerLeft, // anchor to the left edge
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: ctrl,
                  curve: Curves.easeOut,
                  reverseCurve: Curves.easeIn,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 80,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 76,
                          height: 64, // Reduced from 76
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Align(
                                alignment: Alignment.topCenter,
                                child: AvatarWithBorder(
                                  size: 64,
                                  borderAsset: borderAsset,
                                  avatarUrl: avatarUrl,
                                  fallbackName: fallbackName,
                                ),
                              ),
                              // X badge
                              if (!widget.isReadonly)
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      if (widget.onRemove != null) {
                                        widget.onRemove!(id);
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 2, left: 2, bottom: 8, right: 8),
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: widget.isDark
                                              ? Colors.grey[700]
                                              : Colors.grey[500],
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: widget.isDark
                                                ? AppColors.backgroundDark
                                                : Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: widget.accentColor ?? (widget.isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
