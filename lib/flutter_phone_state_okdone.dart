import 'dart:async';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

class PhoneStateCallEvent {
  final String stateC;
  PhoneStateCallEvent(this.stateC);

  @override
  String toString() => '$stateC';
}

class FlutterPhoneState {
  final EventChannel _phoneStateCallEventChannel =
      EventChannel('co.sunnyapp/phone_events');

  final Logger _log = Logger("flutterPhoneState");

  Stream<RawPhoneEvent?>? _phoneStateCallEvent;

  PhoneStateCallEvent _listphoneStateCallEvent(String stateD) {
    return PhoneStateCallEvent(stateD);
  }

  /// A broadcast stream of events from the phone state.
  Stream<RawPhoneEvent?>? get phoneStateCallEvent {
    _phoneStateCallEvent ??=
        _phoneStateCallEventChannel.receiveBroadcastStream().map((dynamic dyn) {
      try {
        _log.info('callEvent: $dyn');
        if (dyn == null) return null;
        if (dyn is! Map) {
          _log.warning("Unexpected result type for phone event.  "
              "Expected Map<String, dynamic> but got ${dyn?.runtimeType ?? 'null'} ");
        }
        final Map<String, dynamic> event = (dyn as Map).cast();
        final eventType = _parseEventType(event["type"] as String);
        return RawPhoneEvent(
            event["id"] as String, event["phoneNumber"] as String, eventType);
      } catch (e, stack) {
        _log.severe("Error handling native event $e", e, stack);
        return null;
      }
      //return _listphoneStateCallEvent(event as String);
    });
    _log.severe('phoneStateCallEvent ${_phoneStateCallEvent != null}');
    return _phoneStateCallEvent;
  }

  RawEventType _parseEventType(String dyn) {
    switch (dyn) {
      case "inbound":
        return RawEventType.inbound;
      case "connected":
        return RawEventType.connected;
      case "outbound":
        return RawEventType.outbound;
      case "disconnected":
        return RawEventType.disconnected;
      default:
        throw "Illegal raw event type: $dyn";
    }
  }
}

class RawPhoneEvent {
  /// Underlying call ID assigned by the device.
  /// android: always null
  /// ios: a uuid
  /// others: ??
  final String id;

  /// If available, the phone number being dialed.
  final String phoneNumber;

  /// The type of call event.
  final RawEventType type;

  RawPhoneEvent(this.id, this.phoneNumber, this.type);

  /// Whether this event represents a new call
  bool get isNewCall =>
      type == RawEventType.inbound || type == RawEventType.outbound;

  @override
  String toString() {
    return 'RawPhoneEvent{type: $type, id: $id, phoneNumber: $phoneNumber}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RawPhoneEvent &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          phoneNumber == other.phoneNumber &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ phoneNumber.hashCode ^ type.hashCode;
}

enum RawEventType { inbound, outbound, connected, disconnected }
