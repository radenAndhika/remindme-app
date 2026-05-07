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
  static const int _sessionSeconds = 30;

  int _score = 0;
  int _highScore = 0;
  int _missedItems = 0;
  int _combo = 0;
  int _bestCombo = 0;
  int _timeLeft = _sessionSeconds;
  int _tick = 0;
  double _playerX = 0;
  double _fallSpeed = 0.018;
  double _spawnChance = 0.045;
  bool _isPlaying = false;
  bool _showGlow = false;
  String? _feedbackText;
  List<GameItem> _items = [];
  Timer? _timer;

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
      _combo = 0;
      _bestCombo = 0;
      _timeLeft = _sessionSeconds;
      _tick = 0;
      _playerX = 0;
      _fallSpeed = 0.018;
      _spawnChance = 0.045;
      _isPlaying = true;
      _showGlow = false;
      _feedbackText = null;
      _items = [];
    });
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _updateGame();
    });
  }

  void _updateGame() {
    if (!_isPlaying) return;

    _tick++;
    var missedThisTick = 0;
    var shouldEndGame = false;

    setState(() {
      if (_tick % 20 == 0 && _timeLeft > 0) {
        _timeLeft--;
      }

      if (_tick % 80 == 0) {
        _fallSpeed = min(_fallSpeed + 0.003, 0.05);
        _spawnChance = min(_spawnChance + 0.005, 0.12);
      }

      for (final item in _items) {
        item.y += _fallSpeed * item.speedFactor;
      }

      _items.removeWhere((item) {
        if (item.y > 0.8 && (item.x - _playerX).abs() < 0.2) {
          _handleCaughtItem(item);
          return true;
        }

        if (item.y > 1.0) {
          if (item.kind != ItemKind.distraksi) {
            missedThisTick++;
            _combo = 0;
          }
          return true;
        }

        return false;
      });

      _missedItems += missedThisTick;

      if (Random().nextDouble() < _spawnChance) {
        _items.add(GameItem.spawn());
      }

      if (_missedItems >= _maxMissedItems || _timeLeft <= 0) {
        shouldEndGame = true;
      }
    });

    if (shouldEndGame) {
      _endGame();
    }
  }

  void _handleCaughtItem(GameItem item) {
    switch (item.kind) {
      case ItemKind.focus:
        _combo++;
        _bestCombo = max(_bestCombo, _combo);
        final points = _combo >= 6 ? 3 : _combo >= 3 ? 2 : 1;
        _score += points;
        _flashFeedback(_combo >= 3 ? 'Combo x$points!' : 'Nice!', glow: true);
        break;
      case ItemKind.boost:
        _combo++;
        _bestCombo = max(_bestCombo, _combo);
        _score += 5;
        _flashFeedback('Task Boost +5', glow: true);
        break;
      case ItemKind.distraksi:
        _combo = 0;
        _missedItems = min(_missedItems + 1, _maxMissedItems);
        _flashFeedback('Distraksi!', glow: false);
        break;
    }
  }

  void _flashFeedback(String text, {required bool glow}) {
    _feedbackText = text;
    _showGlow = glow;

    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted || !_isPlaying) return;
      setState(() {
        if (_feedbackText == text) {
          _feedbackText = null;
          _showGlow = false;
        }
      });
    });
  }

  void _endGame() {
    _timer?.cancel();
    _saveHighScoreIfNeeded();
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
      _showGlow = false;
      _feedbackText = _timeLeft <= 0 ? 'Waktu habis!' : 'Fokus pecah!';
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
        title: Text(
          'Focus Collector',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
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
              colors: [
                AppTheme.background,
                const Color(0xFFFFF1D6),
                AppTheme.secondary.withOpacity(0.08),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              if (!_isPlaying)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orangeAccent.withOpacity(0.2),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.psychology_alt_outlined,
                            size: 72,
                            color: Colors.orangeAccent,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Tangkap Fokus, Hindari Distraksi',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _score > 0 || _missedItems > 0
                              ? 'Sesi selesai. Skor kamu $_score.'
                              : 'Kumpulkan Focus Point dan Task Boost. Jangan sentuh Distraksi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.onSurface.withOpacity(0.55),
                            height: 1.4,
                          ),
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
                          'Durasi $_sessionSeconds detik • Maksimal lolos: $_maxMissedItems',
                          style: TextStyle(color: AppTheme.onSurface.withOpacity(0.5)),
                        ),
                        if (_score > 0 || _missedItems > 0) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Best Combo: $_bestCombo',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Column(
                            children: [
                              _LegendRow(
                                icon: Icons.bolt_rounded,
                                label: 'Focus Point',
                                color: Colors.orangeAccent,
                              ),
                              SizedBox(height: 8),
                              _LegendRow(
                                icon: Icons.star_rounded,
                                label: 'Task Boost +5',
                                color: Colors.amber,
                              ),
                              SizedBox(height: 8),
                              _LegendRow(
                                icon: Icons.notifications_active_rounded,
                                label: 'Distraksi',
                                color: Colors.redAccent,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _startGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondary,
                          ),
                          child: Text(
                            _score > 0 || _missedItems > 0
                                ? 'Main Lagi'
                                : 'Mulai Focus Session',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_isPlaying)
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'Score: $_score',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 54,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary.withOpacity(0.12),
                          ),
                        ),
                        if (_feedbackText != null)
                          AnimatedOpacity(
                            opacity: _feedbackText == null ? 0 : 1,
                            duration: const Duration(milliseconds: 180),
                            child: Text(
                              _feedbackText!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _showGlow ? Colors.orangeAccent : Colors.redAccent,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              if (_isPlaying)
                Positioned(
                  top: 110,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatPill(
                          text: 'Waktu: $_timeLeft s',
                          color: AppTheme.primary,
                          icon: Icons.timer_outlined,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatPill(
                          text: 'Combo: x$_combo',
                          color: Colors.orangeAccent,
                          icon: Icons.local_fire_department_outlined,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatPill(
                          text: 'Miss: $_missedItems/$_maxMissedItems',
                          color: AppTheme.secondary,
                          icon: Icons.flash_off_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
              ..._items.map(
                (item) => Align(
                  alignment: Alignment(item.x, item.y),
                  child: Icon(
                    item.icon,
                    color: item.color,
                    size: item.size,
                  ),
                ),
              ),
              Align(
                alignment: Alignment(_playerX, 0.9),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 92,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _showGlow ? Colors.orangeAccent : AppTheme.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (_showGlow ? Colors.orangeAccent : AppTheme.primary)
                            .withOpacity(0.38),
                        blurRadius: _showGlow ? 18 : 10,
                        offset: const Offset(0, 4),
                      ),
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

class _StatPill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _StatPill({
    required this.text,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _LegendRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

enum ItemKind { focus, boost, distraksi }

class GameItem {
  double x;
  double y;
  final ItemKind kind;
  final IconData icon;
  final Color color;
  final double size;
  final double speedFactor;

  GameItem({
    required this.x,
    required this.y,
    required this.kind,
    required this.icon,
    required this.color,
    required this.size,
    required this.speedFactor,
  });

  factory GameItem.spawn() {
    final rng = Random();
    final roll = rng.nextDouble();

    if (roll < 0.12) {
      return GameItem(
        x: rng.nextDouble() * 2 - 1,
        y: -1.0,
        kind: ItemKind.boost,
        icon: Icons.star_rounded,
        color: Colors.amber,
        size: 34,
        speedFactor: 0.95,
      );
    }

    if (roll < 0.28) {
      return GameItem(
        x: rng.nextDouble() * 2 - 1,
        y: -1.0,
        kind: ItemKind.distraksi,
        icon: Icons.notifications_active_rounded,
        color: Colors.redAccent,
        size: 30,
        speedFactor: 1.15,
      );
    }

    return GameItem(
      x: rng.nextDouble() * 2 - 1,
      y: -1.0,
      kind: ItemKind.focus,
      icon: Icons.bolt_rounded,
      color: Colors.orangeAccent,
      size: 30,
      speedFactor: 1.0,
    );
  }
}
