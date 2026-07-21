import 'package:flutter/material.dart';
import 'glass_card.dart';

class GlassButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color color;

  const GlassButton({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius = 20.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
    this.color = const Color(0x1AFFFFFF),
  });

  @override
  _GlassButtonState createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _btnController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _btnController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _btnController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _btnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _btnController.forward(),
      onTapUp: (_) {
        _btnController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _btnController.reverse(),
      child: AnimatedBuilder(
        animation: _btnController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GlassCard(
              borderRadius: widget.borderRadius,
              padding: widget.padding,
              color: widget.color,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}
