import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../config/theme.dart';
import '../services/meal_ai_service.dart';
import '../utils/haptics.dart';
import '../managers/meal_history_provider.dart';

class CalorieCounterScreen extends ConsumerStatefulWidget {
  const CalorieCounterScreen({super.key});

  @override
  ConsumerState<CalorieCounterScreen> createState() => _CalorieCounterScreenState();
}

class _CalorieCounterScreenState extends ConsumerState<CalorieCounterScreen> {
  File? _image;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResults;
  
  // Daily Stats removed together with Remaining/Consumed tracker

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final XFile? image = await showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.luxeDarkGrey : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text("ADD MEAL", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionIcon(isDark ? Icons.camera_alt : Icons.camera_alt_outlined, "Camera", isDark ? Colors.white : Colors.black, () async => Navigator.pop(context, await picker.pickImage(source: ImageSource.camera, imageQuality: 50, maxWidth: 1024))),
                _actionIcon(isDark ? Icons.photo_library : Icons.photo_library_outlined, "Gallery", isDark ? Colors.white70 : Colors.black87, () async => Navigator.pop(context, await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 1024))),
                _actionIcon(Icons.edit_note_rounded, "Manual", isDark ? Colors.white54 : Colors.black45, () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (image != null) {
      setState(() {
        _image = File(image.path);
        _isAnalyzing = true;
        _analysisResults = null;
      });

      try {
        final result = await ref.read(mealAiServiceProvider).analyzeImage(_image!);
        setState(() {
          _isAnalyzing = false;
          _analysisResults = result;
        });
        
        // ✨ NEW: Store in history (only on success)
        if (result['is_food'] == true && result['item'] != 'Detection Failed' && !result['item'].toString().contains('ERROR')) {
          ref.read(mealHistoryProvider.notifier).addRecord(result, _image);
        }
        
        AppHaptics.medium();
      } catch (e) {
        setState(() {
          _isAnalyzing = false;
          _analysisResults = {
            'item': 'Error', 
            'calories': 0, 
            'protein': '-',
            'carbs': '-',
            'fats': '-',
            'confidence': 0.0,
            'description': 'Check your internet connection or API key.',
            'portion_estimate': 'N/A'
          };
        });
      }
    }
  }

  Widget _actionIcon(IconData icon, String label, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1), 
              shape: BoxShape.circle, 
              border: Border.all(color: color.withOpacity(0.3))
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87, 
              fontSize: 12,
              fontWeight: FontWeight.w600
            )
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final secondaryTextColor = textColor.withOpacity(0.6);
    
    // Cleaner look: only use shadows in dark mode if needed, or keeping it very subtle
    final shadows = isDark ? [const Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 4)] : <Shadow>[];
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'AI MEAL SCANNER', 
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            letterSpacing: 2, 
            color: textColor, 
            fontSize: 18, 
            shadows: shadows
          )
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20), 
          onPressed: () => Navigator.pop(context)
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              if (_image == null) ...[
                _buildEmptyState(theme, textColor, secondaryTextColor, shadows),
              ] else ...[
                _buildAnalysisView(theme, textColor, secondaryTextColor, shadows),
              ],
              const SizedBox(height: 30),
              _buildRecentHistory(theme, textColor, secondaryTextColor, shadows),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: _image == null ? FloatingActionButton.extended(
        onPressed: _pickImage,
        backgroundColor: isDark ? AppTheme.cyanAccent : theme.colorScheme.primary,
        icon: Icon(Icons.add_a_photo, color: isDark ? Colors.black : Colors.white),
        label: Text("SCAN MEAL", style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildEmptyState(ThemeData theme, Color textColor, Color secondaryTextColor, List<Shadow> shadows) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("READY TO LOG?", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20, shadows: shadows)),
        const SizedBox(height: 8),
        Text("Take a photo and let AI do the rest.", style: TextStyle(color: secondaryTextColor, fontSize: 14, shadows: shadows)),
        const SizedBox(height: 20),
        InkWell(
          onTap: _pickImage,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
              boxShadow: isDark ? [] : [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.center_focus_weak_rounded, 
                  size: 48, 
                  color: isDark ? AppTheme.cyanAccent.withOpacity(0.8) : Colors.black.withOpacity(0.6)
                ),
                const SizedBox(height: 16),
                Text("OPEN CAMERA SCANNER", style: TextStyle(color: textColor, fontWeight: FontWeight.w900, letterSpacing: 1, shadows: shadows)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisView(ThemeData theme, Color textColor, Color secondaryTextColor, List<Shadow> shadows) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.file(_image!, height: 350, width: double.infinity, fit: BoxFit.cover),
              if (_isAnalyzing)
                Container(
                  height: 350,
                  width: double.infinity,
                  color: Colors.black54,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: AppTheme.cyanAccent),
                      const SizedBox(height: 20),
                      Text("ANALYZING PORTIONS...", style: TextStyle(color: AppTheme.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2, shadows: shadows)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (!_isAnalyzing && _analysisResults != null) ...[
          const SizedBox(height: 20),
          _buildResultDetails(theme, textColor, secondaryTextColor, shadows),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _largeButton(theme, "RE-SCAN", theme.colorScheme.surface, textColor, _pickImage),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _largeButton(theme, "LOG MEAL", AppTheme.cyanAccent, Colors.black, () => Navigator.pop(context)),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _largeButton(ThemeData theme, String text, Color bg, Color textCol, VoidCallback onTap) {
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: bg, 
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          boxShadow: isDark ? [] : [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        alignment: Alignment.center,
        child: Text(text, style: TextStyle(color: textCol, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildResultDetails(ThemeData theme, Color textColor, Color secondaryTextColor, List<Shadow> shadows) {
    final bool isFood = _analysisResults!['is_food'] ?? true;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isFood ? Icons.verified : Icons.info_outline, color: AppTheme.cyanAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                (_analysisResults!['item'] ?? 'Analyzing...').toString().toUpperCase(),
                style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1, shadows: shadows),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _analysisResults!['description'] ?? 'No description available',
            textAlign: TextAlign.center,
            style: TextStyle(color: secondaryTextColor, fontSize: 13, shadows: shadows),
          ),
          if (isFood) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.cyanAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(
                "Est. Weight: ${_analysisResults!['portion_estimate'] ?? '-'}",
                style: TextStyle(color: AppTheme.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold, shadows: shadows),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statCircle(textColor, secondaryTextColor, "CAL", (_analysisResults!['calories'] ?? 0).toString(), Colors.orangeAccent, shadows),
                _statCircle(textColor, secondaryTextColor, "PRO", (_analysisResults!['protein'] ?? '0g').toString(), Colors.blueAccent, shadows),
                _statCircle(textColor, secondaryTextColor, "CARB", (_analysisResults!['carbs'] ?? '0g').toString(), Colors.greenAccent, shadows),
                _statCircle(textColor, secondaryTextColor, "FAT", (_analysisResults!['fats'] ?? '0g').toString(), Colors.redAccent, shadows),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Divider(color: textColor.withOpacity(0.05)),
          const SizedBox(height: 16),
          _buildHealthInsight(textColor, secondaryTextColor, shadows, isFood: isFood),
        ],
      ),
    );
  }

  Widget _buildHealthInsight(Color textColor, Color secondaryTextColor, List<Shadow> shadows, {bool isFood = true}) {
    final int? score = _analysisResults!['health_score'];
    final String insight = _analysisResults!['ai_insight'] ?? (isFood ? "Keep track of your macros!" : "Interesting object!");
    
    Color insightColor = AppTheme.cyanAccent;
    if (isFood && score != null) {
      if (score >= 8) insightColor = Colors.greenAccent;
      else if (score <= 4) insightColor = Colors.redAccent;
      else insightColor = Colors.orangeAccent;
    }

    return Column(
      children: [
        if (isFood && score != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("HEALTH SCORE", style: TextStyle(color: secondaryTextColor, fontSize: 10, fontWeight: FontWeight.bold, shadows: shadows, letterSpacing: 1)),
              Row(
                children: List.generate(10, (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  width: 12,
                  height: 4,
                  decoration: BoxDecoration(
                    color: index < score ? insightColor : textColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
              ),
            ],
          )
        else
          Row(
            children: [
              Text("AI INSIGHT", style: TextStyle(color: secondaryTextColor, fontSize: 10, fontWeight: FontWeight.bold, shadows: shadows, letterSpacing: 1)),
              const Spacer(),
            ],
          ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: insightColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: insightColor.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(isFood ? Icons.lightbulb_outline : Icons.auto_awesome, color: insightColor, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  insight,
                  style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 11, fontStyle: FontStyle.italic, shadows: shadows),
                ),
              ),
            ],
          ),
        ),
        if (isFood && (_analysisResults?['proven_source'] != null || _analysisResults?['source'] != null)) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.03),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: textColor.withOpacity(0.05)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user_outlined, color: Colors.greenAccent, size: 10),
                const SizedBox(width: 6),
                Text(
                  "VERIFIED VIA: ${(_analysisResults!['proven_source'] ?? _analysisResults!['source']).toString().toUpperCase()}",
                  style: TextStyle(
                    color: secondaryTextColor, 
                    fontSize: 8, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    shadows: shadows
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _statCircle(Color textColor, Color secondaryTextColor, String label, String value, Color color, List<Shadow> shadows) {
    return Column(
      children: [
        Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.4), width: 2),
            color: color.withOpacity(0.1),
          ),
          alignment: Alignment.center,
          child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13, shadows: shadows)),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: secondaryTextColor, fontSize: 10, fontWeight: FontWeight.bold, shadows: shadows)),
      ],
    );
  }

  Widget _buildRecentHistory(ThemeData theme, Color textColor, Color secondaryTextColor, List<Shadow> shadows) {
    final isDark = theme.brightness == Brightness.dark;
    final history = ref.watch(mealHistoryProvider);

    if (history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("RECENT SCANS", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18, shadows: shadows)),
            TextButton(
              onPressed: () {}, 
              child: Text("View All", style: TextStyle(color: isDark ? AppTheme.cyanAccent : theme.colorScheme.primary))
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: history.length,
            itemBuilder: (context, index) {
              final record = history[index];
              return InkWell(
                onTap: () {
                  setState(() {
                    _analysisResults = record.fullResults;
                    _image = record.imageFile;
                  });
                },
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                    image: record.imageFile != null 
                      ? DecorationImage(
                          image: FileImage(record.imageFile!),
                          fit: BoxFit.cover,
                          opacity: isDark ? 0.3 : 0.8,
                        )
                      : null,
                  ),
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black54 : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "${record.calories} kcal", 
                      style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


