import 'package:flutter/material.dart';

import '../design/app_dimensions.dart';
import '../design/app_spacing.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({
    super.key,
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: AppDimensions.iconMedium,
              height: AppDimensions.iconMedium,
              child: CircularProgressIndicator(),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.medium),
              Text(
                message!,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}