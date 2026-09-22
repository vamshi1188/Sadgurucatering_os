import 'package:flutter/material.dart';

import '../../../core/design/app_spacing.dart';
import '../models/event.dart';
import 'event_card.dart';

class EventList extends StatelessWidget {
  const EventList({required this.events, required this.onEventTap, super.key});

  final List<Event> events;
  final ValueChanged<Event> onEventTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < events.length; index++) ...[
          EventCard(
            event: events[index],
            onTap: () => onEventTap(events[index]),
          ),
          if (index != events.length - 1)
            const SizedBox(height: AppSpacing.medium),
        ],
      ],
    );
  }
}
