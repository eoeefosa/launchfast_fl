import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../constants/app_colors.dart';

class OrderTimeline extends StatelessWidget {
  final OrderStatus status;

  const OrderTimeline({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {'title': 'Confirmed', 'icon': Icons.check_circle_outline_rounded},
      {'title': 'Cooking', 'icon': Icons.outdoor_grill_rounded},
      {'title': 'On Way', 'icon': Icons.moped_rounded},
      {'title': 'Arrived', 'icon': Icons.home_rounded},
    ];

    int currentStep = 0;
    if (status == OrderStatus.preparing) currentStep = 1;
    if (status == OrderStatus.outForDelivery) currentStep = 2;
    if (status == OrderStatus.delivered) currentStep = 3;

    return Row(
      children: List.generate(steps.length, (index) {
        final isCompleted = index <= currentStep;
        final isCurrent = index == currentStep;
        final isLast = index == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.black
                          : AppColors.lightSurface,
                      shape: BoxShape.circle,
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      steps[index]['icon'] as IconData,
                      color: isCompleted
                          ? Colors.white
                          : AppColors.lightMuted.withValues(alpha: 0.5),
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    steps[index]['title'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isCompleted
                          ? FontWeight.w900
                          : FontWeight.w600,
                      color: isCompleted ? Colors.black : AppColors.lightMuted,
                    ),
                  ),
                ],
              ),
              if (!isLast)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: index < currentStep
                            ? Colors.black
                            : AppColors.lightBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
