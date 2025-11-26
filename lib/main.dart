import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for keyboard input
import 'data/words.dart';

void main() {
  runApp(const HangmanApp());
}

class HangmanApp extends StatelessWidget {
  const HangmanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hangman – Friend Edition',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const HangmanScreen(),
    );
  }
}

class HangmanScreen extends StatefulWidget {
  const HangmanScreen({super.key});

  @override
  State<HangmanScreen> createState() => _HangmanScreenState();
}

class _HangmanScreenState extends State<HangmanScreen>
    with TickerProviderStateMixin {
  static const int maxAttempts = 5;

  late String _word;
  final Set<String> _guessed = {};
  int _wrong = 0;

  bool _showIntro = true;

  late AnimationController _introController;
  late AnimationController _shakeController;
  late Animation<Offset> _cardSlideAnimation;
  late Animation<double> _cardFadeAnimation;
  late Animation<double> _shakeAnimation;

  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startNewGame();
  }

  void _setupAnimations() {
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.easeOutCubic,
      ),
    );

    _cardFadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOut,
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _introController.dispose();
    _shakeController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _startNewGame() {
    final r = Random();
    _word = words[r.nextInt(words.length)].toUpperCase();
    _guessed.clear();
    _wrong = 0;
    setState(() {});
  }

  void _beginGameFromIntro() {
    setState(() {
      _showIntro = false;
    });
    _introController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _keyboardFocusNode.requestFocus();
      }
    });
  }

  void _onLetterTap(String letter) {
    if (_isGameOver) return;
    if (_guessed.contains(letter)) return;

    bool wasWrong = false;

    setState(() {
      _guessed.add(letter);
      if (!_word.contains(letter)) {
        _wrong++;
        wasWrong = true;
      }
    });

    if (wasWrong) {
      _shakeController.forward(from: 0);
    }

    if (_isWin || _isLose) {
      _showResultDialog();
    }
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (_showIntro || _isGameOver) return;
    if (event is! RawKeyDownEvent) return;

    final keyLabel = event.logicalKey.keyLabel.toUpperCase();
    if (keyLabel.length == 1 &&
        keyLabel.codeUnitAt(0) >= 65 &&
        keyLabel.codeUnitAt(0) <= 90) {
      _onLetterTap(keyLabel);
    }
  }

  bool get _isWin =>
      _word.split('').every((ch) => _guessed.contains(ch.toUpperCase()));

  bool get _isLose => _wrong >= maxAttempts;

  bool get _isGameOver => _isWin || _isLose;

  String get _displayWord {
    return _word.split('').map((ch) {
      final up = ch.toUpperCase();
      return _guessed.contains(up) ? '$up ' : '_ ';
    }).join();
  }

  String get _friendStageAsset {
    final stage = _wrong.clamp(0, maxAttempts);
    return 'assets/friend_stage_$stage.png';
  }

  // Hint logic
  String? get _hintText {
    final attemptsLeft = maxAttempts - _wrong;
    if (attemptsLeft != 3 || _isGameOver) return null;

    final first = _word[0];
    final last = _word[_word.length - 1];

    return 'Hint: the word starts with "$first" and ends with "$last".\n';
  }

  BoxDecoration _backgroundDecoration() {
    if (_isWin) {
      return const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB3E5FC), Color(0xFF4FC3F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else if (_isLose) {
      return const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF8A80), Color(0xFFFF5252)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else if (_wrong >= 4) {
      return const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF59D), Color(0xFFFFE082)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else {
      return const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF5C6BC0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }
  }

  Future<void> _showResultDialog() async {
    final win = _isWin;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Icon(
                win ? Icons.celebration : Icons.sentiment_very_dissatisfied,
                color: win ? Colors.green : Colors.redAccent,
              ),
              const SizedBox(width: 8),
              Text(win ? 'You saved Jyro!' : 'Aray Coh!'),
            ],
          ),
          content: Text(
            win ? 'Nice! You guessed the word: $_word' : 'The word was: $_word',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startNewGame();
                _keyboardFocusNode.requestFocus();
              },
              child: const Text('Play Again'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showIntro) {
      return _buildIntroScreen();
    }
    return _buildGameScreen();
  }

  // Welcome screen
  Widget _buildIntroScreen() {
    return Container(
      decoration: _backgroundDecoration(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      offset: const Offset(0, 18),
                      blurRadius: 35,
                    ),
                  ],
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Welcome to Hangman – Nahuhulog na Bato Edition',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Jyro is in Danger! \nGuess the hidden word one letter at a time.\nEach wrong guess reveals more of their “hangman” stages.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.keyboard, color: Colors.white70, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Tip: You can use your keyboard to type!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _beginGameFromIntro,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start Game'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Main game screen
  Widget _buildGameScreen() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final wrongLetters = _guessed.where((l) => !_word.contains(l)).join(', ');
    final colorScheme = Theme.of(context).colorScheme;
    final hint = _hintText;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      decoration: _backgroundDecoration(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: const Text(
            'Hangman Game - Nahuhulog na Bato Edition',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: RawKeyboardListener(
          focusNode: _keyboardFocusNode,
          autofocus: true,
          onKey: _handleKeyEvent,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 780),
                child: SlideTransition(
                  position: _cardSlideAnimation,
                  child: FadeTransition(
                    opacity: _cardFadeAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            offset: const Offset(0, 18),
                            blurRadius: 35,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  child: const Icon(
                                    Icons.videogame_asset_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Save Jyro!',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Guess the hidden word!',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: Colors.white.withOpacity(0.14),
                                  ),
                                  child: const Text(
                                    'CSIT Project - AXALAN_NIDEA',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Image Section
                            AnimatedBuilder(
                              animation: _shakeAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(_shakeAnimation.value, 0),
                                  child: child,
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: AspectRatio(
                                  aspectRatio: 4 / 3,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.asset(
                                        _friendStageAsset,
                                        fit: BoxFit.cover,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.black.withOpacity(0.0),
                                              Colors.black.withOpacity(0.35),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 6,
                                          ),
                                          margin:
                                              const EdgeInsets.only(bottom: 10),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.6),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                'Lives',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Row(
                                                children: List.generate(
                                                  maxAttempts,
                                                  (i) => Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 2),
                                                    child: Icon(
                                                      Icons.favorite,
                                                      size: 18,
                                                      color: i <
                                                              (maxAttempts -
                                                                  _wrong)
                                                          ? Colors.pinkAccent
                                                          : Colors
                                                              .grey.shade500,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 22),

                            // Word + stats
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _displayWord,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      letterSpacing: 4,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Word length: ${_word.length}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      Text(
                                        'Attempts left: ${maxAttempts - _wrong} / $maxAttempts',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Wrong letters + Hint
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Wrong letters',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        wrongLetters.isEmpty
                                            ? '—'
                                            : wrongLetters,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 3,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: hint == null
                                        ? const SizedBox.shrink()
                                        : Container(
                                            key: const ValueKey('hint_box'),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade100
                                                  .withOpacity(0.9),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: Colors.amber.shade400,
                                              ),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Icon(
                                                  Icons.lightbulb,
                                                  color: Colors.amber,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    hint,
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      height: 1.3,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Keyboard
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                alignment: WrapAlignment.center,
                                children: letters.split('').map((ch) {
                                  final used = _guessed.contains(ch);
                                  final isCorrect = _word.contains(ch);
                                  final isWrong = used && !isCorrect;

                                  Color bg;
                                  Color fg;
                                  if (!used) {
                                    bg = colorScheme.primaryContainer
                                        .withOpacity(0.9);
                                    fg = colorScheme.onPrimaryContainer;
                                  } else if (isCorrect) {
                                    bg = Colors.greenAccent.shade400;
                                    fg = Colors.black;
                                  } else if (isWrong) {
                                    bg = Colors.redAccent.shade200;
                                    fg = Colors.white;
                                  } else {
                                    bg = Colors.grey.shade500;
                                    fg = Colors.white;
                                  }

                                  return SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        backgroundColor: bg,
                                        foregroundColor: fg,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                      ),
                                      onPressed: used || _isGameOver
                                          ? null
                                          : () => _onLetterTap(ch),
                                      child: Text(
                                        ch,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(height: 16),

                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _startNewGame();
                                  _keyboardFocusNode.requestFocus();
                                },
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Reset Game'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
