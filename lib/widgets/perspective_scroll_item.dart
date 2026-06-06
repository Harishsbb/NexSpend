import 'package:flutter/material.dart';

class PerspectiveScrollItem extends StatefulWidget {
  final Widget child;

  const PerspectiveScrollItem({
    super.key,
    required this.child,
  });

  @override
  State<PerspectiveScrollItem> createState() => _PerspectiveScrollItemState();
}

class _PerspectiveScrollItemState extends State<PerspectiveScrollItem> {
  ScrollPosition? _scrollPosition;
  double _rotationX = 0.0;
  double _scale = 1.0;
  double _opacity = 1.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Remove listener from old position if any
    _scrollPosition?.removeListener(_updatePosition);
    
    // Retrieve parent Scrollable's position
    try {
      _scrollPosition = Scrollable.of(context).position;
      _scrollPosition?.addListener(_updatePosition);
    } catch (_) {
      // Handle cases where the widget is loaded outside a Scrollable
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePosition());
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_updatePosition);
    super.dispose();
  }

  void _updatePosition() {
    if (!mounted) return;
    
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    try {
      final position = renderBox.localToGlobal(Offset.zero);
      final viewportHeight = MediaQuery.of(context).size.height;
      
      // Calculate item's center position relative to viewport center
      final itemCenterY = position.dy + renderBox.size.height / 2;
      final screenCenterY = viewportHeight / 2;
      
      // Normalized distance from center (-1.0 to 1.0)
      final distanceFromCenter = (itemCenterY - screenCenterY) / (viewportHeight / 2);
      
      // Calculate 3D tilt, scale down, and fade near screen boundaries
      final clampedDistance = distanceFromCenter.clamp(-1.2, 1.2);
      
      if (mounted) {
        setState(() {
          _rotationX = -clampedDistance * 0.28; // Rotate on X-axis (Cylinder roll)
          _scale = (1.0 - clampedDistance.abs() * 0.08).clamp(0.9, 1.0);
          _opacity = (1.0 - clampedDistance.abs() * 0.25).clamp(0.65, 1.0);
        });
      }
    } catch (_) {
      // localToGlobal may fail if widget is currently being detached/unmounted
    }
  }

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0012) // Perspective depth mapping
        ..rotateX(_rotationX)
        ..setEntry(0, 0, _scale)
        ..setEntry(1, 1, _scale),
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: Duration.zero,
        child: widget.child,
      ),
    );
  }
}
