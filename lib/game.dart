// ignore_for_file: unnecessary_type_check, use_key_in_widget_constructors, library_private_types_in_public_api, unnecessary_nullable_for_final_variable_declarations, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:confetti/confetti.dart';

import 'color.dart'; // provides `colors` list
import 'confetti.dart'; // provides `AppConfetti`

import 'dart:async';
import 'dart:math';

class ColorGameScreen extends StatefulWidget {
  @override
  _ColorGameScreenState createState() => _ColorGameScreenState();
}

class _ColorGameScreenState extends State<ColorGameScreen>
    with TickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  Timer? audioTimer;

  late ConfettiController confettiController;
  late AnimationController popupController;
  late AnimationController buttonController;
  late Animation<double> scaleAnimation;
  late Animation<double> buttonAnimation;

  int currentRound = 1;
  String targetColor = ''; // name
  String? lastTarget;
  bool gameStarted = false;
  bool showPopup = false;
  bool isSuccess = false;
  bool isPlaying = false;

  // Display "Round 0 of 10" initially, without changing logic.
  int get displayRound => (currentRound - 1).clamp(0, 10);

  // Helper: lookup Color by name from colors list.
  Color? get targetColorValue {
    if (targetColor.isEmpty) return null;
    final match = colors.firstWhere(
      (c) => c['name'] == targetColor,
      orElse: () => {},
    );
    if (match is Map && match.containsKey('color')) {
      return match['color'] as Color;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    initTTS();
    confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    popupController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: popupController, curve: Curves.elasticOut),
    );
    buttonAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: buttonController, curve: Curves.easeInOut),
    );
  }

  void initTTS() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.6);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.2);
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> speakColor() async {
    await flutterTts.stop();
    await flutterTts.speak("Find $targetColor");
  }

  void startNewRound() {
    // Use the full list from color.dart; do not force a fixed count.
    if (currentRound <= 10) {
      String next;
      final rnd = Random();
      do {
        next = colors[rnd.nextInt(colors.length)]['name'];
      } while (next == lastTarget && colors.length > 1);
      final newColor = next;

      if (!mounted) return;
      setState(() {
        targetColor = newColor; // update name
        lastTarget = newColor;
        gameStarted = true;
        isPlaying = true;
      });

      startColorAudio();
    } else {
      showGameComplete();
    }
  }

  void startColorAudio() {
    audioTimer?.cancel();
    speakColor();
    audioTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (gameStarted && isPlaying) {
        speakColor();
      } else {
        timer.cancel();
      }
    });
  }

  void stopAudio() {
    audioTimer?.cancel();
    flutterTts.stop();
    if (!mounted) return;
    setState(() {
      isPlaying = false;
    });
  }

  void onColorTapped(String colorName) {
    if (!gameStarted || showPopup) return;

    HapticFeedback.lightImpact();
    buttonController.forward().then((_) => buttonController.reverse());

    stopAudio();

    if (colorName == targetColor) {
      isSuccess = true;
      confettiController.play();
      showSuccessPopup();
    } else {
      isSuccess = false;
      showTryAgainPopup();
    }
  }

  void showSuccessPopup() {
    setState(() => showPopup = true);
    popupController.forward();

    Future.delayed(const Duration(seconds: 2), () async {
      await popupController.reverse();
      if (!mounted) return;
      setState(() {
        showPopup = false;
        currentRound++;
        gameStarted = false;
      });
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      startNewRound();
    });
  }

  void showTryAgainPopup() {
    setState(() => showPopup = true);
    popupController.forward();

    Future.delayed(const Duration(seconds: 1), () async {
      await popupController.reverse();
      if (!mounted) return;
      setState(() => showPopup = false);
      if (!mounted) return;
      isPlaying = true;
      startColorAudio();
    });
  }

  void showGameComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            Text('Congratulations!', style: TextStyle(color: Colors.green)),
          ],
        ),
        content: const Text('You completed all 10 rounds! Great job!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              resetGame();
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text('Play Again'),
            ),
          ),
        ],
      ),
    );
  }

  void resetGame() {
    audioTimer?.cancel();
    flutterTts.stop();
    if (!mounted) return;
    setState(() {
      currentRound = 1;
      gameStarted = false;
      isPlaying = false;
      showPopup = false;
      isSuccess = false;
      targetColor = '';
      lastTarget = null;
    });
  }

  Widget buildPaletteIcon() {
    // Use up to six colors for the gradient ring (or fallback to defaults if fewer exist).
    final gradientColors = <Color>[];
    for (var i = 0; i < colors.length && gradientColors.length < 6; i++) {
      final c = colors[i]['color'];
      if (c is Color) gradientColors.add(c);
    }
    if (gradientColors.isEmpty) {
      gradientColors.addAll(const [
        Colors.red,
        Colors.orange,
        Colors.yellow,
        Colors.green,
        Colors.blue,
        Colors.purple,
      ]);
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.palette, color: Colors.white, size: 16),
    );
  }

  Widget buildProgressBar() {
    final width = MediaQuery.of(context).size.width * 0.78;
    final progress = ((currentRound - 1) / 10).clamp(0.0, 1.0);
    return Container(
      width: width,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: width * progress,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
          ),
        ),
      ),
    );
  }

  // Rectangular label showing the current target color and its name.
  Widget buildTargetColorLabel() {
    if (!gameStarted || targetColor.isEmpty) {
      return const SizedBox.shrink();
    }

    final Color? swatch = targetColorValue ?? Colors.transparent;
    final brightness = swatch == null
        ? Brightness.light
        : ThemeData.estimateBrightnessForColor(swatch);
    final textColor = brightness == Brightness.light
        ? Colors.black
        : Colors.white;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: swatch,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (swatch ?? Colors.black).withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
      ),
      child: Text(
        'Find: $targetColor',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textColor,
          fontFamily: 'Comic Neue',
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Adaptive grid: uses all colors from color.dart and adjusts columns by width.
  Widget buildColorGrid(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    const spacing = 10.0;
    const horizontalPadding = 16.0;

    int crossAxisCount;
    if (width >= 700) {
      crossAxisCount = 7;
    } else if (width >= 600) {
      crossAxisCount = 6;
    } else if (width >= 500) {
      crossAxisCount = 5;
    } else if (width >= 380) {
      crossAxisCount = 4;
    } else {
      crossAxisCount = 3;
    }

    final usableWidth =
        width - (horizontalPadding * 2) - (spacing * (crossAxisCount - 1));
    final tileWidth = usableWidth / crossAxisCount;
    final tileHeight = tileWidth.clamp(64.0, 100.0);

    return IgnorePointer(
      ignoring: showPopup,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          mainAxisExtent: tileHeight,
        ),
        itemCount: colors.length,
        itemBuilder: (context, index) {
          final colorData = colors[index];
          final Color bg = colorData['color'] as Color;
          final brightness = ThemeData.estimateBrightnessForColor(bg);
          final textColor = brightness == Brightness.light
              ? Colors.black
              : Colors.white;

          return ScaleTransition(
            scale: buttonAnimation,
            child: GestureDetector(
              onTap: () => onColorTapped(colorData['name']),
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: bg.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    colorData['name'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: 'Comic Neue',
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 2,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final height = media.size.height;

    const headerVPad = 12.0;
    const sectionGap = 14.0;

    final header = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: headerVPad),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildPaletteIcon(),
          const SizedBox(width: 10),
          const Text(
            'Color Learning Game!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
              fontFamily: 'Comic Neue',
            ),
          ),
          const SizedBox(width: 10),
          buildPaletteIcon(),
        ],
      ),
    );

    final subtitle = Text(
      'Listen and click the right color!',
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey,
        fontFamily: 'Comic Neue',
      ),
    );

    final roundChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildPaletteIcon(),
          const SizedBox(width: 8),
          Text(
            'Round $displayRound of 10',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );

    final playButton = ElevatedButton(
      onPressed: (!gameStarted)
          ? startNewRound
          : (!isPlaying ? startColorAudio : null),
      style: ElevatedButton.styleFrom(
        backgroundColor: gameStarted && !isPlaying
            ? const Color(0xFF4FC3F7)
            : const Color(0xFF667eea),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            gameStarted && !isPlaying ? Icons.replay : Icons.play_arrow,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            gameStarted && !isPlaying
                ? 'Repeat'
                : (isPlaying ? 'Playing...' : 'Start'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    final hint = Text(
      'It repeats every 5 seconds.',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey,
        fontFamily: 'Comic Neue',
      ),
      textAlign: TextAlign.center,
    );

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final body = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            header,
            subtitle,
            const SizedBox(height: sectionGap),
            roundChip,
            // New: Target color label rect above the Start/Repeat button
            buildTargetColorLabel(),
            const SizedBox(height: 6),
            playButton,
            const SizedBox(height: 6),
            hint,
            const SizedBox(height: 12),
            // Grid area (scrollable as colors grow)
            SizedBox(height: height * 0.55, child: buildColorGrid(constraints)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton(
                onPressed: resetGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.refresh, size: 16),
                    SizedBox(width: 6),
                    Text('Start Over', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
          ],
        );

        return body;
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 8),
                child: content,
              ),
            ),
            AppConfetti(
              controller: confettiController,
              alignment: Alignment.topCenter,
            ),
            if (showPopup)
              Container(
                color: Colors.black54,
                child: Center(
                  child: ScaleTransition(
                    scale: scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      margin: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isSuccess ? '🎉' : '😅',
                            style: const TextStyle(fontSize: 46),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isSuccess ? 'Great Job!' : 'Try Again!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isSuccess ? Colors.green : Colors.orange,
                              fontFamily: 'Comic Neue',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isSuccess
                                ? 'You found the right color!'
                                : 'Keep looking for $targetColor',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontFamily: 'Comic Neue',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    audioTimer?.cancel();
    flutterTts.stop();
    confettiController.dispose();
    popupController.dispose();
    buttonController.dispose();
    super.dispose();
  }
}
