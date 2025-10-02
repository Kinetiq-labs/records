import 'package:flutter/material.dart';

class SynchronizedScrollController {
  final ScrollController _primary = ScrollController();
  final ScrollController _secondary = ScrollController();

  bool _isUpdating = false;

  ScrollController get primary => _primary;
  ScrollController get secondary => _secondary;

  SynchronizedScrollController() {
    _primary.addListener(_onPrimaryScroll);
    _secondary.addListener(_onSecondaryScroll);
  }

  void _onPrimaryScroll() {
    if (!_isUpdating && _secondary.hasClients) {
      _updateSecondary();
    }
  }

  void _onSecondaryScroll() {
    if (!_isUpdating && _primary.hasClients) {
      _updatePrimary();
    }
  }

  void _updateSecondary() {
    _isUpdating = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_secondary.hasClients && _primary.hasClients) {
        final targetOffset = _primary.offset.clamp(
          _secondary.position.minScrollExtent,
          _secondary.position.maxScrollExtent,
        );
        _secondary.jumpTo(targetOffset);
      }
      _isUpdating = false;
    });
  }

  void _updatePrimary() {
    _isUpdating = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_primary.hasClients && _secondary.hasClients) {
        final targetOffset = _secondary.offset.clamp(
          _primary.position.minScrollExtent,
          _primary.position.maxScrollExtent,
        );
        _primary.jumpTo(targetOffset);
      }
      _isUpdating = false;
    });
  }

  void dispose() {
    _primary.removeListener(_onPrimaryScroll);
    _secondary.removeListener(_onSecondaryScroll);
    _primary.dispose();
    _secondary.dispose();
  }
}