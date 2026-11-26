import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/network/api_exception.dart';
import '../models/event.dart';
import '../models/event_status.dart';
import '../services/event_service_contract.dart';

class EventController extends ChangeNotifier {
  EventController(this._service);

  final EventServiceContract _service;

  List<Event> _events = const [];
  Event? _selectedEvent;
  AppError? _error;

  bool _isLoading = false;
  bool _isMutating = false;

  List<Event> get events => List.unmodifiable(_events);
  Event? get selectedEvent => _selectedEvent;
  AppError? get error => _error;
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _events = await _service.getEvents();
    } on ApiException catch (exception) {
      _error = ErrorHandler.fromApiException(exception);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  Future<void> selectEvent(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedEvent = await _service.getEvent(id);
    } on ApiException catch (exception) {
      _error = ErrorHandler.fromApiException(exception);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createEvent({
    required String title,
    required String eventDate,
    required String venue,
    required int guestCount,
  }) async {
    return _runMutation(() async {
      final event = await _service.createEvent(
        title: title,
        eventDate: eventDate,
        venue: venue,
        guestCount: guestCount,
      );

      _events = [..._events, event];
      _selectedEvent = event;
    });
  }

  Future<bool> updateStatus(int id, EventStatus status) async {
    return _runMutation(() async {
      final event = await _service.updateStatus(id, status);

      _events = _events
          .map((item) => item.id == event.id ? event : item)
          .toList();

      if (_selectedEvent?.id == event.id) {
        _selectedEvent = event;
      }
    });
  }

  Future<bool> deleteEvent(int id) async {
    return _runMutation(() async {
      await _service.deleteEvent(id);

      _events = _events.where((event) => event.id != id).toList();

      if (_selectedEvent?.id == id) {
        _selectedEvent = null;
      }
    });
  }

  Future<void> retry() => load();

  Future<bool> _runMutation(Future<void> Function() mutation) async {
    _isMutating = true;
    _error = null;
    notifyListeners();

    try {
      await mutation();
      return true;
    } on ApiException catch (exception) {
      _error = ErrorHandler.fromApiException(exception);
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) {
      return;
    }

    _error = null;
    notifyListeners();
  }

  void clearSelectedEvent() {
    if (_selectedEvent == null) {
      return;
    }

    _selectedEvent = null;
    notifyListeners();
  }
}
