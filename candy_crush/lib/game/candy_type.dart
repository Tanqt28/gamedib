enum CandyType {
  blue,
  green,
  orange,
  red,
  yellow,
  purple;

  String get asset {
    return switch (this) {
      CandyType.blue => 'ball.png',
      CandyType.green => 'pill.png',
      CandyType.orange => 'egg.png',
      CandyType.red => 'cherry.png',
      CandyType.yellow => 'sun.png',
      CandyType.purple => 'star.png',
    };
  }
}
