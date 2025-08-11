import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:confetti/confetti.dart';
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
  String targetColor = '';
  String? lastTarget;
  bool gameStarted = false;
  bool showPopup = false;
  bool isSuccess = false;
  bool isPlaying = false;

  // Display "Round 0 of 10" initially, without changing logic.
  int get displayRound => (currentRound - 1).clamp(0, 10);

  final List<Map<String, dynamic>> colors = const [
    {'name': 'Red', 'color': Color(0xFFFF0000)}, // Pure red
    {'name': 'Orange', 'color': Color(0xFFFFA500)}, // Pure orange
    {'name': 'Yellow', 'color': Color(0xFFFFFF00)}, // Pure yellow
    {'name': 'Green', 'color': Color(0xFF008000)}, // Pure green
    {'name': 'Blue', 'color': Color(0xFF0000FF)}, // Pure blue
    {'name': 'Purple', 'color': Color(0xFF800080)}, // Pure purple
    {'name': 'Pink', 'color': Color(0xFFFFC0CB)}, // Standard pink
    {'name': 'Brown', 'color': Color(0xFFA52A2A)}, // Standard brown
    {'name': 'Black', 'color': Color(0xFF000000)}, // Black
    {'name': 'White', 'color': Color(0xFFFFFFFF)}, // White
    {'name': 'Gray', 'color': Color(0xFF808080)}, // Middle gray
  ];

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
    if (currentRound <= 10) {
      String next;
      do {
        next = colors[Random().nextInt(colors.length)]['name'];
      } while (next == lastTarget && colors.length > 1);
      targetColor = next;
      lastTarget = next;

      if (!mounted) return;
      setState(() {
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
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.red,
            Colors.orange,
            Colors.yellow,
            Colors.green,
            Colors.blue,
            Colors.purple,
          ],
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

  // Responsive grid to fit all tiles on one screen using fixed tile height.
  Widget buildColorGrid(BoxConstraints constraints) {
    const tileHeight = 72.0;
    const tileSpacing = 10.0;
    const crossAxisCount = 5;

    return IgnorePointer(
      ignoring: showPopup,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: tileSpacing,
          mainAxisSpacing: tileSpacing,
          mainAxisExtent: tileHeight,
        ),
        itemCount: colors.length,
        itemBuilder: (context, index) {
          final colorData = colors[index];
          return ScaleTransition(
            scale: buttonAnimation,
            child: GestureDetector(
              onTap: () => onColorTapped(colorData['name']),
              child: Container(
                decoration: BoxDecoration(
                  color: colorData['color'],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (colorData['color'] as Color).withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    colorData['name'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Comic Neue',
                      shadows: [
                        Shadow(
                          color: Colors.black38,
                          blurRadius: 2,
                          offset: Offset(1, 1),
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

    final startOverButton = ElevatedButton(
      onPressed: resetGame,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.refresh, size: 16),
          SizedBox(width: 6),
          Text('Start Over', style: TextStyle(fontSize: 14)),
        ],
      ),
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
            const SizedBox(height: 10),
            buildProgressBar(),
            const SizedBox(height: sectionGap),
            playButton,
            const SizedBox(height: 6),
            hint,
            const SizedBox(height: 12),
            buildColorGrid(constraints),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: startOverButton,
            ),
          ],
        );

        final likelyTooSmall = height < 640;
        if (likelyTooSmall) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: body,
            ),
          );
        }
        return body;
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      body: SafeArea(
        child: Stack(
          children: [
            Align(alignment: Alignment.topCenter, child: content),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: confettiController,
                blastDirection: pi / 2,
                particleDrag: 0.05,
                emissionFrequency: 0.05,
                numberOfParticles: 50,
                gravity: 0.05,
                shouldLoop: false,
                colors: const [
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.yellow,
                  Colors.purple,
                  Colors.orange,
                ],
              ),
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
