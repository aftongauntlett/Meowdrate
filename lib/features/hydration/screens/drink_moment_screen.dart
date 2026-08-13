import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../hydration_constants.dart';
import '../providers/hydration_providers.dart';

class DrinkMomentScreen extends ConsumerStatefulWidget {
  const DrinkMomentScreen({super.key});

  @override
  ConsumerState<DrinkMomentScreen> createState() => _DrinkMomentScreenState();
}

class _DrinkMomentScreenState extends ConsumerState<DrinkMomentScreen> {
  late int _remainingSeconds = kDrinkMomentSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _remainingSeconds = (_remainingSeconds - 1).clamp(0, kDrinkMomentSeconds);
      });
      if (_remainingSeconds == 0) {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _isComplete => _remainingSeconds == 0;

  Future<void> _handleDrank() async {
    if (!_isComplete) {
      return;
    }

    await ref.read(hydrationControllerProvider).logDrink();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  void _handleSkip() {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl).copyWith(
            top: AppSpacing.xxl,
            bottom: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your pet found water',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Take a few sips and come back when you’re done.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 16, height: 1.4),
              ),
              const Spacer(),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.xxl,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _formatSeconds(_remainingSeconds),
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _isComplete ? 'Your pet is waiting…' : 'Hold on until the timer ends.',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isComplete ? _handleDrank : null,
                      child: const Text('I drank'),
                    ),
                  ),
                  TextButton(
                    onPressed: _handleSkip,
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatSeconds(int totalSeconds) {
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
