import 'package:flutter/material.dart';
import 'package:hereforyou/widgets/glass_effect.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class InteractiveMoodSection extends StatelessWidget {
  final PageController controller;
  final int currentMood;
  final List<Map<String, dynamic>> moods;
  final ValueChanged<int> onMoodChanged;
  final Future<void> Function(int index) onMoodTap;

  const InteractiveMoodSection({
    super.key,
    required this.controller,
    required this.currentMood,
    required this.moods,
    required this.onMoodChanged,
    required this.onMoodTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final screenWidth = MediaQuery.of(context).size.width;
    final viewportFraction = isTablet ? 0.32 : 0.35;
    final itemWidth = screenWidth * viewportFraction;

    return Glass(
      blur: 20,
      opacity: 0.25,
      borderRadius: 24,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.pink[50]!.withOpacity(0.3),
              Colors.purple[50]!.withOpacity(0.3),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: isTablet ? 40 : 36,
                  height: isTablet ? 40 : 36,
                  decoration: BoxDecoration(
                    color: Colors.pink[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.psychology_rounded,
                    color: Colors.pink[400],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "How are you feeling today?",
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: isTablet ? 150 : 110,
              child: PageView.builder(
                controller: controller,
                itemCount: moods.length,
                physics: const BouncingScrollPhysics(),
                onPageChanged: onMoodChanged,
                itemBuilder: (context, index) {
                  final mood = moods[index];
                  final isSelected = index == currentMood;

                  return GestureDetector(
                    onTap: () => onMoodTap(index),
                    child: Container(
                      width: itemWidth - 12,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: EdgeInsets.all(isTablet ? 20 : 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isSelected
                                ? [
                                    mood['color'].withOpacity(0.4),
                                    mood['color'].withOpacity(0.2),
                                  ]
                                : [
                                    Colors.white.withOpacity(0.15),
                                    Colors.white.withOpacity(0.08),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? mood['color'].withOpacity(0.6)
                                : Colors.transparent,
                            width: isSelected ? 3 : 0,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              mood['emoji'],
                              style: TextStyle(fontSize: isTablet ? 36 : 28),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              mood['label'],
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isSelected
                                    ? mood['color']
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: SmoothPageIndicator(
                controller: controller,
                count: moods.length,
                effect: ExpandingDotsEffect(
                  activeDotColor: Colors.pink[400]!,
                  dotColor: Colors.pink[200]!.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
