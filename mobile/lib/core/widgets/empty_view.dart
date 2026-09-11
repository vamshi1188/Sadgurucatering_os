import 'package:flutter/material.dart';

import '../design/app_dimensions.dart';
import '../design/app_spacing.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: AppDimensions.iconLarge,
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}