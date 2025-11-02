import 'dart:async';
import 'package:flutter/material.dart';

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
  int _breathCount = 0;
  int _sessionDuration = 0;
  String _currentPhase = "Ready";
  Timer? _sessionTimer;
  bool _voiceGuideEnabled = true;
  bool _ambientSoundsEnabled = false;
  int _selectedDuration = 300; // 5 minutes in seconds

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
  }

  @override
  void dispose() {
    _controller.dispose();
    _sessionTimer?.cancel();
    super.dispose();
  }

  void _startBreathingSession() {
    setState(() {
      _isBreathingActive = true;
      _breathCount = 0;
      _sessionDuration = 0;
      _currentPhase = "Inhale";
    });

    // Start session timer
    _sessionTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _sessionDuration++;
        });
        
        // Auto-stop after selected duration
        if (_sessionDuration >= _selectedDuration) {
          _stopBreathingSession();
        }
      }
    });

    // Simulate breath phases
    _simulateBreathing();
  }

  void _stopBreathingSession() {
    setState(() {
      _isBreathingActive = false;
      _currentPhase = "Complete";
    });
    _sessionTimer?.cancel();
  }

  void _simulateBreathing() {
    Future.delayed(Duration(milliseconds: 4000), () {
      if (_isBreathingActive && mounted) {
        setState(() {
          _currentPhase = "Hold";
        });
      }
    });
    
    Future.delayed(Duration(milliseconds: 7000), () {
      if (_isBreathingActive && mounted) {
        setState(() {
          _currentPhase = "Exhale";
        });
      }
    });
    
    Future.delayed(Duration(milliseconds: 10000), () {
      if (_isBreathingActive && mounted) {
        setState(() {
          _breathCount++;
          _currentPhase = "Inhale";
          _simulateBreathing(); // Continue cycle
        });
      }
    });
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
                  
                  // Meditation controls
                  _buildMeditationControls(),
                  const SizedBox(height: 20),
                  
                  // Additional breathing techniques
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
            'Ready to Begin?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _isBreathingActive ? _stopBreathingSession : _startBreathingSession,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 400),
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isBreathingActive 
                    ? [Colors.redAccent, Colors.orangeAccent]
                    : [widget.accent, widget.accent.withOpacity(0.8)],
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
                    _isBreathingActive ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text(
                    _isBreathingActive ? 'Pause Session' : 'Begin Breathing',
                    style: TextStyle(
                      fontSize: 20,
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

  Widget _buildMeditationControls() {
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
            'Meditation Settings',
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
              _buildToggleControl(
                'Sounds',
                Icons.music_note,
                _ambientSoundsEnabled,
                onTap: _toggleAmbientSounds,
              ),
              _buildToggleControl(
                'Guide',
                Icons.record_voice_over,
                _voiceGuideEnabled,
                onTap: _toggleVoiceGuidance,
              ),
              _buildActionControl(
                'Timer',
                Icons.alarm_add,
                onTap: () => _showDurationSelector(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleControl(String label, IconData icon, bool isActive, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive ? widget.accent.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? widget.accent : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? widget.accent : Colors.grey,
              size: 28,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isActive ? widget.accent : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionControl(String label, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.grey,
              size: 28,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
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

  void _toggleAmbientSounds() {
    setState(() {
      _ambientSoundsEnabled = !_ambientSoundsEnabled;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ambient sounds ${_ambientSoundsEnabled ? 'enabled' : 'disabled'}'),
        duration: Duration(seconds: 1),
        backgroundColor: widget.accent,
      ),
    );
  }

  void _toggleVoiceGuidance() {
    setState(() {
      _voiceGuideEnabled = !_voiceGuideEnabled;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voice guidance ${_voiceGuideEnabled ? 'enabled' : 'disabled'}'),
        duration: Duration(seconds: 1),
        backgroundColor: widget.accent,
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
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: _getPhaseDuration(),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.4,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine,
    ));
  }

  Duration _getPhaseDuration() {
    switch (widget.currentPhase) {
      case "Inhale":
        return Duration(milliseconds: 4000);
      case "Hold":
        return Duration(milliseconds: 3000);
      case "Exhale":
        return Duration(milliseconds: 3000);
      default:
        return Duration(milliseconds: 3000);
    }
  }

  @override
  void didUpdateWidget(BreathPulseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPhase != oldWidget.currentPhase) {
      _pulseController.duration = _getPhaseDuration();
    }
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isActive ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}