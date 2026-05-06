import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_theme.dart';

class MiniGameScreen extends StatefulWidget {
  const MiniGameScreen({super.key});

  @override
  State<MiniGameScreen> createState() => _MiniGameScreenState();
}

class _MiniGameScreenState extends State<MiniGameScreen> {
  static const int _maxMissedItems = 5;

  int _score = 0;
  int _highScore = 0;
  int _missedItems = 0;
  double _playerX = 0;
  List<Point> _items = [];
  Timer? _timer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _highScore = prefs.getInt('mini_game_high_score') ?? 0;
    });
  }

  Future<void> _saveHighScoreIfNeeded() async {
    if (_score <= _highScore) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('mini_game_high_score', _score);
    if (!mounted) return;
    setState(() {
      _highScore = _score;
    });
  }

  void _startGame() {
    _timer?.cancel();
    setState(() {
      _score = 0;
      _missedItems = 0;
      _playerX = 0;
      _items = [];
      _isPlaying = true;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _updateGame();
    });
  }

  void _updateGame() {
    if (!_isPlaying) return;

    var missedThisTick = 0;

    setState(() {
      for (var item in _items) {
        item.y += 0.02;
      }

      _items.removeWhere((item) {
        if (item.y > 0.8 && (item.x - _playerX).abs() < 0.2) {
          _score++;
          return true;
        }
        if (item.y > 1.0) {
          missedThisTick++;
          return true;
        }
        return false;
      });

      _missedItems += missedThisTick;

      if (Random().nextDouble() < 0.05) {
        _items.add(Point(Random().nextDouble() * 2 - 1, -1.0));
      }
    });

    if (_missedItems >= _maxMissedItems) {
      _endGame();
    }
  }

  void _endGame() {
    _timer?.cancel();
    _saveHighScoreIfNeeded();
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Focus Collector', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.background,
        elevation: 0,
      ),
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            _playerX += details.delta.dx / (MediaQuery.of(context).size.width / 2);
            _playerX = _playerX.clamp(-1.0, 1.0);
          });
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.background, AppTheme.secondary.withOpacity(0.05)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              if (!_isPlaying)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt, size: 80, color: Colors.orangeAccent),
                      const SizedBox(height: 20),
                      Text('Collect the Bolts!', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 10),
                      Text(
                        _score > 0 || _missedItems > 0
                            ? 'Game over. Skor kamu $_score.'
                            : 'Catch them to stay focused.',
                        style: TextStyle(color: AppTheme.onSurface.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'High Score: $_highScore',
                        style: const TextStyle(
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Maksimal petir lolos: $_maxMissedItems',
                        style: TextStyle(color: AppTheme.onSurface.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
                        child: Text(_score > 0 || _missedItems > 0 ? 'Main Lagi' : 'Start Focus Session'),
                      ),
                    ],
                  ),
                )
              else
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'Score: $_score',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 60,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ),
                ),
              if (_isPlaying)
                Positioned(
                  top: 92,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Terlewat: $_missedItems/$_maxMissedItems  •  High Score: $_highScore',
                        style: const TextStyle(
                          color: AppTheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ..._items.map((item) => Align(
                alignment: Alignment(item.x, item.y),
                child: const Icon(Icons.bolt, color: Colors.orangeAccent, size: 30),
              )),
              Align(
                alignment: Alignment(_playerX, 0.9),
                child: Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Point {
  double x;
  double y;
  Point(this.x, this.y);
}
