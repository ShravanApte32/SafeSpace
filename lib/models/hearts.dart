class FloatHeart {
  final double startX; // 0..1 (percent of width)
  final double size;
  final double speed;
  final double phase;
  final int hue; // 0..2 small palette switch

  FloatHeart({
    required this.startX,
    required this.size,
    required this.speed,
    required this.phase,
    required this.hue,
  });
}
