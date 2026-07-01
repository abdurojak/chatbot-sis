part of 'home_screen.dart';

class CurvedDiscussionBottomBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final midX = size.width / 2;
    final path = Path()
      ..moveTo(0, 16)
      ..lineTo(midX - 58, 16)
      ..cubicTo(midX - 42, 16, midX - 40, 34, midX - 24, 39)
      ..cubicTo(midX - 10, 44, midX + 10, 44, midX + 24, 39)
      ..cubicTo(midX + 40, 34, midX + 42, 16, midX + 58, 16)
      ..lineTo(size.width, 16)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class BottomBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const double radius = 40; // ⬅️ BESARIN INI untuk lebih lebar

    final path = Path();

    path.lineTo(size.width / 2 - radius, 0);

    // setengah lingkaran sempurna
    path.arcTo(
      Rect.fromCircle(center: Offset(size.width / 2, 0), radius: radius),
      math.pi,
      -math.pi,
      false,
    );

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class NotificationBadge extends StatelessWidget {
  final int count;
  final Widget child;

  const NotificationBadge({
    super.key,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 1) {
      return child;
    }

    final label = count > 99 ? '99+' : '$count';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -8,
          top: -8,
          child: Container(
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: AppThemePalette.negative(),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
