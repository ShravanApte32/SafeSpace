import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class BreathMeditationPage extends StatefulWidget {
  final Color accent;

  const BreathMeditationPage({Key? key, required this.accent}) : super(key: key);

  @override
  _BreathMeditationPageState createState() => _BreathMeditationPageState();
}

class _BreathMeditationPageState extends State<BreathMeditationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  
  // Meditation state
  bool _isBreathingActive = false;
  bool _isPaused = false; // NEW: Track pause state
  int _breathCount = 0;
  int _sessionDuration = 0;
  String _currentPhase = "Ready";
  Timer? _sessionTimer;
  Timer? _breathTimer;
  bool _voiceGuideEnabled = true;
  bool _ambientSoundsEnabled = false;
  int _selectedDuration = 300; // 5 minutes in seconds

  // Phase durations for 4-7-8 breathing (in milliseconds)
  final int _inhaleDuration = 4000; // 4 seconds
  final int _holdDuration = 7000;   // 7 seconds  
  final int _exhaleDuration = 8000; // 8 seconds

  // Audio players
  final AudioPlayer _ambientPlayer = AudioPlayer();
  final AudioPlayer _bellPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  
  // Sound states
  bool _isAmbientPlaying = false;
  double _ambientVolume = 0.5;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
    _initializeAudio();
    _initializeTTS();
  }

  void _initializeAudio() async {
    await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
    await _bellPlayer.setReleaseMode(ReleaseMode.release);
  }

  void _initializeTTS() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  void _playAmbientSounds() async {
    if (_ambientSoundsEnabled && !_isAmbientPlaying) {
      try {
        // Add your ambient sound file to assets/sounds/ and uncomment:
        await _ambientPlayer.play(AssetSource('sounds/ambient_sound.mp3'));
        setState(() {
          _isAmbientPlaying = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ambient sounds started'),
            duration: Duration(seconds: 2),
            backgroundColor: widget.accent,
          ),
        );
      } catch (e) {
        print('Error playing ambient sounds: $e');
      }
    }
  }

  void _stopAmbientSounds() async {
    if (_isAmbientPlaying) {
      await _ambientPlayer.stop();
      setState(() {
        _isAmbientPlaying = false;
      });
    }
  }

  void _playBellSound() async {
    if (_voiceGuideEnabled) {
      try {
        // Add your bell sound file to assets/sounds/ and uncomment:
        await _bellPlayer.play(AssetSource('sounds/bell_sound.mp3'));
      } catch (e) {
        print('Error playing bell sound: $e');
      }
    }
  }

  void _speakPhaseGuidance(String phase) async {
    // Allow voice guidance even when ambient sounds are playing
    // But make sure TTS volume is appropriate
    if (_voiceGuideEnabled && _isBreathingActive) {
      // Adjust TTS volume based on ambient sounds
      double ttsVolume = _ambientSoundsEnabled ? 1.0 : 1.0; // You can adjust this
      await _flutterTts.setVolume(ttsVolume);
      
      String text = _getVoiceGuidanceText(phase);
      await _flutterTts.speak(text);
    }
  }

  String _getVoiceGuidanceText(String phase) {
    switch (phase) {
      case "Inhale":
        return "Breathe in slowly through your nose. Count to four.";
      case "Hold":
        return "Hold your breath. Count to seven.";
      case "Exhale":
        return "Breathe out slowly through your mouth. Count to eight.";
      case "Complete":
        return "Session complete. Take a moment to notice how you feel.";
      default:
        return "Begin your breathing exercise.";
    }
  }

  void _startBreathingSession() {
    setState(() {
      _isBreathingActive = true;
      _isPaused = false; // NEW: Reset pause state
      _breathCount = 0;
      _sessionDuration = 0;
      _currentPhase = "Inhale";
    });

    // Start ambient sounds if enabled (but don't stop them when session pauses)
    if (_ambientSoundsEnabled && !_isAmbientPlaying) {
      _playAmbientSounds();
    }

    // Speak initial guidance
    _speakPhaseGuidance("Inhale");
    _playBellSound();

    // Start session timer - UPDATED: Only increment when not paused
    _sessionTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted && _isBreathingActive && !_isPaused) { // NEW: Added !_isPaused check
        setState(() {
          _sessionDuration++;
        });
        
        // Auto-stop after selected duration
        if (_sessionDuration >= _selectedDuration) {
          _stopBreathingSession();
        }
      }
    });

    // Start the breathing cycle
    _startBreathCycle();
  }

  void _startBreathCycle() {
    if (!_isBreathingActive) return;

    // Inhale phase
    setState(() {
      _currentPhase = "Inhale";
    });
    _speakPhaseGuidance("Inhale");
    _playBellSound();

    // Schedule Hold phase
    _breathTimer = Timer(Duration(milliseconds: _inhaleDuration), () {
      if (!_isBreathingActive) return;
      
      setState(() {
        _currentPhase = "Hold";
      });
      _speakPhaseGuidance("Hold");
      _playBellSound();

      // Schedule Exhale phase
      _breathTimer = Timer(Duration(milliseconds: _holdDuration), () {
        if (!_isBreathingActive) return;
        
        setState(() {
          _currentPhase = "Exhale";
        });
        _speakPhaseGuidance("Exhale");
        _playBellSound();

        // Schedule next breath cycle
        _breathTimer = Timer(Duration(milliseconds: _exhaleDuration), () {
          if (!_isBreathingActive) return;
          
          setState(() {
            _breathCount++;
          });
          
          // Continue to next breath cycle
          _startBreathCycle();
        });
      });
    });
  }

  void _stopBreathingSession() {
    setState(() {
      _isBreathingActive = false;
      _isPaused = false; // NEW: Reset pause state
      _currentPhase = "Complete";
    });
    
    // Stop all timers
    _sessionTimer?.cancel();
    _breathTimer?.cancel();
    
    // Stop TTS if speaking
    _flutterTts.stop();
    
    // DON'T stop ambient sounds here - they should continue
    // _stopAmbientSounds(); // REMOVED THIS LINE
    
    // Play completion sound
    _playBellSound();
    
    // Speak completion message
    _speakPhaseGuidance("Complete");
  }

  void _pauseBreathingSession() {
    setState(() {
      _isBreathingActive = false;
      _isPaused = true; // NEW: Set pause state
      _currentPhase = "Paused";
    });
    
    // Stop breathing cycle timer but keep session timer running
    _breathTimer?.cancel();
    
    // Stop TTS if speaking
    _flutterTts.stop();
    
    // DON'T stop ambient sounds - they should continue
    // _stopAmbientSounds(); // REMOVED THIS LINE
    
    // Play pause sound
    _playBellSound();
  }

  void _resumeBreathingSession() {
    setState(() {
      _isBreathingActive = true;
      _isPaused = false; // NEW: Reset pause state
      _currentPhase = "Inhale";
    });

    // Speak guidance for current phase
    _speakPhaseGuidance("Inhale");
    _playBellSound();

    // Resume breathing cycle
    _startBreathCycle();
  }

  void _toggleAmbientSounds() {
    setState(() {
      _ambientSoundsEnabled = !_ambientSoundsEnabled;
      
      // If turning on ambient sounds, turn off voice guide
      if (_ambientSoundsEnabled && _voiceGuideEnabled) {
        _voiceGuideEnabled = false;
        _flutterTts.stop(); // Stop any ongoing TTS
      }
    });
    
    if (_ambientSoundsEnabled) {
      _playAmbientSounds();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ambient sounds enabled - Voice guide disabled'),
          duration: Duration(seconds: 2),
          backgroundColor: widget.accent,
        ),
      );
    } else {
      _stopAmbientSounds();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ambient sounds disabled'),
          duration: Duration(seconds: 1),
          backgroundColor: widget.accent,
        ),
      );
    }
  }

  void _toggleVoiceGuidance() {
    setState(() {
      _voiceGuideEnabled = !_voiceGuideEnabled;
      
      // If turning on voice guide, turn off ambient sounds
      if (_voiceGuideEnabled && _ambientSoundsEnabled) {
        _ambientSoundsEnabled = false;
        _stopAmbientSounds();
      }
    });
    
    if (!_voiceGuideEnabled && _isBreathingActive) {
      // Stop any ongoing speech if voice guidance is disabled
      _flutterTts.stop();
    }
    
    String message = 'Voice guidance ${_voiceGuideEnabled ? 'enabled' : 'disabled'}';
    if (_voiceGuideEnabled && _ambientSoundsEnabled) {
      message += ' - Ambient sounds disabled';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
        backgroundColor: widget.accent,
      ),
    );
  }

  // Enhanced controls with volume slider
  Widget _buildSoundControls() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.white.withOpacity(0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Sound Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          
          // Ambient Sounds Toggle with Volume
          _buildSoundControlItem(
            'Ambient Sounds',
            Icons.music_note,
            _ambientSoundsEnabled,
            _toggleAmbientSounds,
            showVolume: true,
            volume: _ambientVolume,
            onVolumeChanged: (value) {
              setState(() {
                _ambientVolume = value;
              });
              _ambientPlayer.setVolume(value);
            },
            isDisabledByOther: _voiceGuideEnabled, // Mutual exclusion
          ),
          
          const SizedBox(height: 16),
          
          // Voice Guidance Toggle
          _buildSoundControlItem(
            'Voice Guide',
            Icons.record_voice_over,
            _voiceGuideEnabled,
            _toggleVoiceGuidance,
            isDisabledByOther: _ambientSoundsEnabled, // Mutual exclusion
          ),
          
          const SizedBox(height: 16),
          
          // Timer Control
          _buildSoundControlItem(
          'Session Timer',
          Icons.alarm_add,
          true, // Always show as "active" since it's always available
          () => _showDurationSelector(context),
          showTimer: true, // New parameter
          timerValue: '${_selectedDuration ~/ 60} min', // New parameter
          ),
        ],
      ),
    );
  }

  // Update the _buildSoundControlItem method to handle timer display:
Widget _buildSoundControlItem(
  String label, 
  IconData icon, 
  bool isActive, 
  VoidCallback onTap, {
  bool showVolume = false,
  bool showTimer = false, // NEW: For timer display
  String timerValue = '', // NEW: Timer value to display
  double volume = 0.5,
  ValueChanged<double>? onVolumeChanged,
  bool isDisabledByOther = false,
}) {
  bool isActuallyActive = isActive && !isDisabledByOther;
  
  return Column(
    children: [
      GestureDetector(
        onTap: isDisabledByOther ? null : onTap,
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isActuallyActive ? widget.accent.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
            border: Border.all(
              color: isActuallyActive ? widget.accent.withOpacity(0.3) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActuallyActive ? widget.accent.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isActuallyActive ? widget.accent : Colors.grey,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isActuallyActive ? widget.accent : Colors.grey[700],
                      ),
                    ),
                    if (showVolume)
                      Text(
                        'Volume: ${(volume * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    if (showTimer) // NEW: Show timer value
                      Text(
                        'Duration: $timerValue',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    if (isDisabledByOther)
                      Text(
                        'Disabled - other audio active',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActuallyActive ? widget.accent : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  showTimer ? 'SET' : (isActuallyActive ? 'ON' : 'OFF'), // NEW: Show SET for timer
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      
      // Volume slider (keep existing)
      if (showVolume && isActuallyActive)
        Padding(
          padding: EdgeInsets.only(top: 12, left: 60, right: 16),
          child: Column(
            children: [
              Slider(
                value: volume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                activeColor: widget.accent,
                inactiveColor: widget.accent.withOpacity(0.3),
                onChanged: onVolumeChanged,
              ),
            ],
          ),
        ),
    ],
  );
}

  @override
  void dispose() {
    _controller.dispose();
    _sessionTimer?.cancel();
    _breathTimer?.cancel();
    _ambientPlayer.dispose();
    _bellPlayer.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  widget.accent.withOpacity(0.03),
                ],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Header with back button
                  _buildHeader(context),
                  const SizedBox(height: 40),
                  
                  // Breathing visualization section
                  _buildBreathingVisualizationSection(),
                  const SizedBox(height: 40),
                  
                  // Main breathing coach
                  _buildEnhancedBreathCoach(),
                  const SizedBox(height: 32),
                  
                  // Interactive stats
                  _buildInteractiveStats(),
                  const SizedBox(height: 32),
                  
                  // Enhanced sound controls
                  _buildSoundControls(),
                  const SizedBox(height: 32),
                  
                  // Breathing techniques
                  _buildBreathingTechniques(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.grey[700]),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Breathing Exercise',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Find your calm through mindful breathing',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        _BreathingIcon(accent: widget.accent),
      ],
    );
  }

  Widget _buildBreathingVisualizationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            widget.accent.withOpacity(0.08),
            widget.accent.withOpacity(0.03),
          ],
        ),
        border: Border.all(
          color: widget.accent.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Main animated circle
          _buildAnimatedBreathCircle(),
          const SizedBox(height: 30),
          
          // Phase indicator dots
          _buildPhaseIndicators(),
        ],
      ),
    );
  }

  Widget _buildAnimatedBreathCircle() {
    return Column(
      children: [
        BreathPulseAnimation(
          isActive: _isBreathingActive,
          currentPhase: _currentPhase,
          accent: widget.accent,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.accent.withOpacity(0.9),
                  widget.accent.withOpacity(0.4),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accent.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 15,
                ),
              ],
            ),
            child: Icon(
              Icons.self_improvement,
              color: Colors.white,
              size: 52,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _currentPhase,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: widget.accent,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _getPhaseInstruction(_currentPhase),
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getPhaseInstruction(String phase) {
    switch (phase) {
      case "Inhale":
        return "Breathe in slowly through your nose\nCount silently to 4";
      case "Hold":
        return "Hold your breath gently\nCount silently to 7";
      case "Exhale":
        return "Breathe out slowly through your mouth\nCount silently to 8";
      case "Complete":
        return "Session complete!\nTake a moment to notice how you feel";
      default:
        return "Press begin to start your\n4-7-8 breathing exercise";
    }
  }

  Widget _buildPhaseIndicators() {
    final phases = ["Inhale", "Hold", "Exhale"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: phases.map((phase) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 8),
          width: _currentPhase == phase ? 12 : 8,
          height: _currentPhase == phase ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPhase == phase 
              ? widget.accent 
              : widget.accent.withOpacity(0.3),
          ),
        );
      }).toList(),
    );
  }

  // Update the button tap handler to use pause/resume
  Widget _buildEnhancedBreathCoach() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.white.withOpacity(0.9),
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _getSessionTitle(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              if (_isBreathingActive) {
                _pauseBreathingSession();
              } else if (_isPaused) {
                _resumeBreathingSession();
              } else {
                _startBreathingSession();
              }
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 400),
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getButtonGradient(),
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: widget.accent.withOpacity(0.4),
                    blurRadius: 25,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getButtonIcon(),
                    color: Colors.white,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    _getButtonText(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for button states
  String _getSessionTitle() {
    if (_isBreathingActive) return 'Breathing Session';
    if (_isPaused) return 'Session Paused';
    if (_currentPhase == "Complete") return 'Session Complete';
    return 'Ready to Begin?';
  }

  List<Color> _getButtonGradient() {
    if (_isBreathingActive) {
      return [Colors.orangeAccent, Colors.orange];
    } else if (_isPaused) {
      return [Colors.green, Colors.greenAccent];
    } else {
      return [widget.accent, widget.accent.withOpacity(0.8)];
    }
  }

  IconData _getButtonIcon() {
    if (_isBreathingActive) {
      return Icons.pause;
    } else if (_isPaused) {
      return Icons.play_arrow;
    } else {
      return Icons.play_arrow;
    }
  }

  String _getButtonText() {
    if (_isBreathingActive) {
      return 'Pause Session';
    } else if (_isPaused) {
      return 'Resume Session';
    } else {
      return 'Begin Breathing';
    }
  }

  Widget _buildInteractiveStats() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.white.withOpacity(0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Session Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInteractiveStatItem(
                'Breaths',
                _breathCount.toString(),
                Icons.cyclone,
                _breathCount > 0 ? widget.accent : Colors.grey,
                onTap: () {
                  setState(() {
                    _breathCount = 0;
                  });
                },
              ),
              _buildInteractiveStatItem(
                'Time',
                _formatTime(_sessionDuration),
                Icons.timer,
                _sessionDuration > 0 ? widget.accent : Colors.grey,
                onTap: () {
                  _showDurationSelector(context);
                },
              ),
              _buildInteractiveStatItem(
                'Focus',
                '${((_breathCount / (_sessionDuration / 10 + 1)) * 100).clamp(0, 100).toInt()}%',
                Icons.psychology,
                _isBreathingActive ? Colors.green : Colors.grey,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Focus score based on breath consistency'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveStatItem(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreathingTechniques() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.white.withOpacity(0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Breathing Techniques',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildTechniqueItem(
            '4-7-8 Breathing',
            'Calms the nervous system',
            Icons.nightlight_round,
          ),
          const SizedBox(height: 12),
          _buildTechniqueItem(
            'Box Breathing',
            'Improves focus',
            Icons.check_box_outlined,
          ),
          const SizedBox(height: 12),
          _buildTechniqueItem(
            'Deep Breathing',
            'Reduces stress',
            Icons.waves,
          ),
        ],
      ),
    );
  }

  Widget _buildTechniqueItem(String title, String description, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: widget.accent.withOpacity(0.05),
        border: Border.all(
          color: widget.accent.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: widget.accent, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDurationSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Set Session Duration',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              ..._buildDurationOptions(),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text('Done', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildDurationOptions() {
    final options = [60, 300, 600, 900]; // 1, 5, 10, 15 minutes
    return options.map((duration) {
      return ListTile(
        leading: Radio(
          value: duration,
          groupValue: _selectedDuration,
          onChanged: (value) {
            setState(() {
              _selectedDuration = value as int;
            });
            Navigator.pop(context);
          },
        ),
        title: Text(
          '${duration ~/ 60} minutes',
          style: TextStyle(fontSize: 16),
        ),
        onTap: () {
          setState(() {
            _selectedDuration = duration;
          });
          Navigator.pop(context);
        },
      );
    }).toList();
  }
}

// Custom breathing icon with animation
class _BreathingIcon extends StatefulWidget {
  final Color accent;

  const _BreathingIcon({required this.accent});

  @override
  _BreathingIconState createState() => _BreathingIconState();
}

class _BreathingIconState extends State<_BreathingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_controller.value * 0.1),
          child: Icon(
            Icons.air,
            color: widget.accent,
            size: 40,
          ),
        );
      },
    );
  }
}

class BreathPulseAnimation extends StatefulWidget {
  final Widget child;
  final Color accent;
  final bool isActive;
  final String currentPhase;

  const BreathPulseAnimation({
    Key? key,
    required this.child,
    required this.accent,
    required this.isActive,
    required this.currentPhase,
  }) : super(key: key);

  @override
  _BreathPulseAnimationState createState() => _BreathPulseAnimationState();
}

class _BreathPulseAnimationState extends State<BreathPulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _scaleAnimation;
  String _lastPhase = "";

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      duration: _getPhaseDuration(),
      vsync: this,
    );
    
    _setupAnimationForPhase();
    _lastPhase = widget.currentPhase;
  }

  Duration _getPhaseDuration() {
    switch (widget.currentPhase) {
      case "Inhale":
        return Duration(milliseconds: 4000);
      case "Hold":
        return Duration(milliseconds: 7000);
      case "Exhale":
        return Duration(milliseconds: 8000);
      default:
        return Duration(milliseconds: 4000);
    }
  }

  void _setupAnimationForPhase() {
    // Always reset the controller when setting up a new animation
    _breathController.stop();
    _breathController.duration = _getPhaseDuration();
    
    switch (widget.currentPhase) {
      case "Inhale":
        // Grow from small to large during inhale
        _scaleAnimation = Tween<double>(
          begin: 0.8,
          end: 1.4,
        ).animate(CurvedAnimation(
          parent: _breathController,
          curve: Curves.easeInOut,
        ));
        if (widget.isActive) {
          _breathController.forward(from: 0.0); // Always start from beginning
        } else {
          _breathController.value = 0.0; // Reset to start
        }
        break;
        
      case "Hold":
        // Stay at the large size (no animation during hold)
        _scaleAnimation = Tween<double>(
          begin: 1.4,
          end: 1.4,
        ).animate(CurvedAnimation(
          parent: _breathController,
          curve: Curves.linear,
        ));
        if (widget.isActive) {
          _breathController.forward(from: 0.0); // Instantly complete to 1.4
        } else {
          _breathController.value = 0.0; // Reset to start (will show 1.4 immediately)
        }
        break;
        
      case "Exhale":
        // Shrink from large to small during exhale
        _scaleAnimation = Tween<double>(
          begin: 1.4,
          end: 0.8,
        ).animate(CurvedAnimation(
          parent: _breathController,
          curve: Curves.easeInOut,
        ));
        if (widget.isActive) {
          _breathController.forward(from: 0.0); // Always start from beginning
        } else {
          _breathController.value = 0.0; // Reset to start
        }
        break;
        
      default:
        // Default to normal size when not active
        _scaleAnimation = Tween<double>(
          begin: 1.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _breathController,
          curve: Curves.linear,
        ));
        _breathController.value = 0.0; // Reset to start
        break;
    }
  }

  @override
  void didUpdateWidget(BreathPulseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Only reset and restart animation if phase actually changed
    if (widget.currentPhase != _lastPhase || 
        widget.isActive != oldWidget.isActive) {
      
      _lastPhase = widget.currentPhase;
      _setupAnimationForPhase();
      
      // If we're active and in a breathing phase, start the animation
      if (widget.isActive && 
          ["Inhale", "Hold", "Exhale"].contains(widget.currentPhase)) {
        _breathController.forward(from: 0.0);
      } else if (!widget.isActive) {
        // If session stopped, reset to normal size
        _breathController.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}