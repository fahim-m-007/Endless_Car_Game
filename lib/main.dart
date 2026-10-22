import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  double playerX = 0;
  double speed = 0.01;
  double maxSpeed = 0.03; // 🔥 NEW: difficulty cap
  double roadOffset = 0;

  List<EnemyCar> enemies = [];

  int score = 0;
  int highScore = 0;

  bool isGameStarted = false;
  bool isGameOver = false;
  bool isPaused = false;

  Timer? gameTimer;
  Timer? holdTimer;

  final Random random = Random();
  int spawnCooldown = 0;

  @override
  void dispose() {
    gameTimer?.cancel();
    holdTimer?.cancel();
    super.dispose();
  }

  void startGame() {
    gameTimer?.cancel();
    holdTimer?.cancel();

    score = 0;
    speed = 0.01;            // ✅ reset speed
    enemies.clear();
    playerX = 0;
    roadOffset = 0;
    spawnCooldown = 60;
    isGameOver = false;
    isPaused = false;
    isGameStarted = true;

    startLoop();
  }

  void startLoop() {
    gameTimer =
        Timer.periodic(const Duration(milliseconds: 16), (_) {
          if (isPaused || isGameOver) return;

          setState(() {
            roadOffset += speed;

            for (var e in enemies) {
              e.y += speed;
            }

            enemies.removeWhere((e) => e.y > 1.3);

            spawnCooldown--;

            if (spawnCooldown <= 0) {
              spawnEnemy();
              spawnCooldown = max(40, 90 - (speed * 2000).toInt());
            }

            checkCollision();

            score++;

            // 🔥 Gradual difficulty increase
            if (speed < maxSpeed) {
              speed += 0.00002;
            }
          });
        });
  }

  void spawnEnemy() {
    List<double> lanes = [-0.6, 0.0, 0.6];
    double lane = lanes[random.nextInt(3)];

    bool tooClose =
    enemies.any((e) => e.x == lane && e.y < -0.6);

    if (!tooClose) {
      enemies.add(EnemyCar(x: lane, y: -1.2));
    }
  }

  void checkCollision() {
    const double collisionX = 0.32;
    const double collisionTop = 0.70;
    const double collisionBottom = 1.0;

    for (var e in enemies) {
      bool xHit = (e.x - playerX).abs() < collisionX;
      bool yHit = (e.y > collisionTop && e.y < collisionBottom);

      if (xHit && yHit) {
        gameOver();
        break;
      }
    }
  }

  void gameOver() {
    isGameOver = true;

    if (score > highScore) {
      highScore = score;
    }
  }

  void pauseGame() {
    setState(() {
      isPaused = !isPaused;
    });
  }

  void moveLeft() {
    if (!isGameOver && !isPaused) {
      setState(() {
        playerX -= 0.03;
        if (playerX < -0.9) playerX = -0.9;
      });
    }
  }

  void moveRight() {
    if (!isGameOver && !isPaused) {
      setState(() {
        playerX += 0.03;
        if (playerX > 0.9) playerX = 0.9;
      });
    }
  }

  void startHolding(VoidCallback action) {
    action();
    holdTimer =
        Timer.periodic(const Duration(milliseconds: 16), (_) => action());
  }

  void stopHolding() {
    holdTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: !isGameStarted
          ? buildStartScreen()
          : Stack(
        children: [
          buildRoad(),
          buildEnemies(),
          buildPlayer(),
          buildScore(),
          buildPauseButton(),
          buildControls(),
          if (isPaused) buildPauseOverlay(),
          if (isGameOver) buildGameOver(),
        ],
      ),
    );
  }

  Widget buildStartScreen() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: startGame,
              child: const Text("START GAME",
                  style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("High Score"),
                    content: Text("Your High Score: $highScore"),
                  ),
                );
              },
              child: const Text("HIGH SCORE"),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRoad() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double height = constraints.maxHeight;

        double dashHeight = 40;
        double gapHeight = 40;
        double totalSegment = dashHeight + gapHeight;

        int dashCount = (height / totalSegment).ceil() + 2;

        return Stack(
          children: [
            Container(color: Colors.grey[900]),
            ...List.generate(dashCount, (i) {
              double yPos =
                  (i * totalSegment) - (roadOffset * 300 % totalSegment);

              return Positioned(
                top: yPos,
                left: constraints.maxWidth / 2 - 3,
                child: Container(
                  width: 6,
                  height: dashHeight,
                  color: Colors.white,
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget buildPlayer() {
    return Align(
      alignment: Alignment(playerX, 0.85),
      child: buildCar(Colors.blueAccent),
    );
  }

  Widget buildEnemies() {
    return Stack(
      children: enemies.map((e) {
        return Align(
          alignment: Alignment(e.x, e.y),
          child: buildCar(Colors.redAccent),
        );
      }).toList(),
    );
  }

  Widget buildCar(Color color) {
    return Container(
      width: 60,
      height: 100,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 15,
          ),
          const BoxShadow(
            color: Colors.black54,
            offset: Offset(0, 10),
            blurRadius: 15,
          ),
        ],
      ),
    );
  }

  Widget buildScore() {
    return Positioned(
      top: 60,
      left: 20,
      child: Text(
        "SCORE $score",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget buildPauseButton() {
    return Positioned(
      top: 60,
      right: 20,
      child: IconButton(
        onPressed: pauseGame,
        icon: Icon(
          isPaused ? Icons.play_arrow : Icons.pause,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget buildControls() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          holdButton(Icons.arrow_left, moveLeft),
          holdButton(Icons.arrow_right, moveRight),
        ],
      ),
    );
  }

  Widget holdButton(IconData icon, VoidCallback action) {
    return GestureDetector(
      onTapDown: (_) => startHolding(action),
      onTapUp: (_) => stopHolding(),
      onTapCancel: stopHolding,
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30),
        ),
        child: Icon(icon, color: Colors.white, size: 38),
      ),
    );
  }

  Widget buildPauseOverlay() {
    return const Center(
      child: Text(
        "PAUSED",
        style: TextStyle(
          fontSize: 30,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget buildGameOver() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "GAME OVER",
              style: TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Text("Score: $score",
                style: const TextStyle(
                    color: Colors.white, fontSize: 20)),
            Text("High Score: $highScore",
                style: const TextStyle(
                    color: Colors.white, fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: startGame,
              child: const Text("RESTART"),
            )
          ],
        ),
      ),
    );
  }
}

class EnemyCar {
  double x;
  double y;

  EnemyCar({required this.x, required this.y});
}