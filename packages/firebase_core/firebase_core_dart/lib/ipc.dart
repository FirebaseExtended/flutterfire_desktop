// ignore_for_file: close_sinks

import 'dart:async';

import 'firebase_core_dart.dart';

final _topics = <String, StreamController<dynamic>>{};
final _messageBuffers = <String, List>{};

/// Publishes a value to a topic.
void firebasePluginPublish(String topic, dynamic value) {
  _topics[topic] ??= StreamController.broadcast();
  _messageBuffers[topic] ??= [];
  _messageBuffers[topic]!.add(value);
  _topics[topic]!.add(value);
}

/// Subscribes to a topic and returns a [Stream] of values published to that
/// topic.
StreamSubscription firebasePluginSubscribe(
  String topic,
  void Function(dynamic) onMessage,
) {
  final ctrl = _topics[topic] ??= StreamController.broadcast();
  _messageBuffers[topic]?.forEach(onMessage);

  return ctrl.stream.listen(onMessage);
}

// ignore: avoid_classes_with_only_static_members

// ignore: avoid_classes_with_only_static_members
/// Creates topic names.
class Topics {
  /// topic name for auth events
  static String currentUser(FirebaseApp app) {
    return 'auth/${app.options.appId}/${app.name}/currentUser';
  }
}
