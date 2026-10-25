import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/design_system/design_system.dart';
import '../../core/storage/user_data_store.dart';
import 'journey_screen.dart';

/// بطاقة مختصرة في الرئيسية: الأيام المتتالية وورد اليوم وتقدم الختمة.
class JourneySummaryCard extends StatelessWidget {
  /// ينشئ بطاقة ملخص رحلة القراءة.
  const JourneySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gold = AppColors.accentGold(context);

    return ListenableBuilder(
      listenable: UserDataStore.instance,
      builder: (context, _) {
        final journey = UserDataStore.instance.journey;
        final now = DateTime.now();
        final plan = journey.plan;
        final streak = journey.streak(now);

        return FuturisticCard(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JourneyScreen()),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Streak flame with its count.
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Color(0xFFE07A3F),
                    size: 28,
                  ),
                  Text(
                    l10n.digits(streak),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.myJourney,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan == null
                          ? l10n.startKhatmaTitle
                          : l10n.pagesOfTarget(
                              journey.pagesOn(now),
                              plan.pagesPerDay,
                            ),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    if (plan != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: plan.progress,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.chevron_right_rounded, color: gold),
            ],
          ),
        );
      },
    );
  }
}
