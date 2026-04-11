import 'package:flutter/material.dart';

import '../../../../shared/shared.dart';
import '../providers/auth_provider.dart';

class ResendCooldownButton extends StatefulWidget {
  const ResendCooldownButton({
    super.key,
    required this.cooldown,
    required this.isLoading,
    required this.readyLabel,
    required this.lockedLabelBuilder,
    required this.onPressed,
    this.readyIcon = Icons.send,
  });

  final ResendCooldownState cooldown;
  final bool isLoading;
  final String readyLabel;
  final String Function(Duration remaining) lockedLabelBuilder;
  final VoidCallback? onPressed;
  final IconData readyIcon;

  @override
  State<ResendCooldownButton> createState() => _ResendCooldownButtonState();
}

class _ResendCooldownButtonState extends State<ResendCooldownButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final locked = widget.cooldown.isLocked;
    final progress = locked
        ? 1.0 -
            (widget.cooldown.remainingLock.inMilliseconds /
                widget.cooldown.lockDuration.inMilliseconds)
        : 0.0;
    final isActive = locked || widget.isLoading;

    return SizedBox(
      height: 52,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: isActive
                    ? (locked ? et.surface : et.ctaBackground)
                    : et.ctaBackground,
                borderRadius: AppRadius.smAll,
                border: locked
                    ? Border.all(color: et.surfaceBorder, width: 1.5)
                    : null,
              ),
            ),
          ),
          if (locked)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: AppRadius.smAll,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(color: et.ctaBackground),
                  ),
                ),
              ),
            ),
          Center(
            child: locked
                ? FadeTransition(
                    opacity: Tween<double>(begin: 0.5, end: 1.0).animate(_blink),
                    child: Text(
                      widget.lockedLabelBuilder(widget.cooldown.remainingLock),
                      style: AppTextStyles.labelLarge.copyWith(
                        color: et.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : widget.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: et.ctaForeground,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.readyLabel,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: et.ctaForeground,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            widget.readyIcon,
                            size: 14,
                            color: et.ctaForeground,
                          ),
                        ],
                      ),
          ),
          if (!locked && !widget.isLoading)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPressed,
                  borderRadius: AppRadius.smAll,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String formatCooldownMmSs(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
