// ignore_for_file: require_trailing_commas

import 'package:meta/meta.dart';

/// ValueSource defines the possible sources of a config parameter value.
enum ValueSource {
  /// The value was defined by a static constant.
  valueStatic,

  /// The value was defined by default config.
  valueDefault,

  /// The value was defined by fetched config.
  valueRemote,
}

/// RemoteConfigValue encapsulates the value and source of a Remote Config
/// parameter.
class RemoteConfigValue {
  /// Wraps a value with metadata and type-safe getters.
  @protected
  RemoteConfigValue(this._value, this.source);

  /// Creates a new RemoteConfigValue from json
  factory RemoteConfigValue.fromJson(Map<String, Object?> remoteConfigValue) {
    return RemoteConfigValue(
      remoteConfigValue['value']! as String,
      ValueSource.values.byName(remoteConfigValue['source']! as String),
    );
  }

  /// Converts the RemoteConfigValue to a json map
  Map<String, Object?> toJson() {
    return {'source': source.name, 'value': asString()};
  }

  /// Default value for String
  static const String defaultValueForString = '';

  /// Default value for Int
  static const int defaultValueForInt = 0;

  /// Default value for Double
  static const double defaultValueForDouble = 0;

  /// Default value for Bool
  static const bool defaultValueForBool = false;

  final String? _value;

  /// Indicates at which source this value came from.
  final ValueSource source;

  /// Decode value to string.
  String asString() {
    final value = _value;
    return value ?? defaultValueForString;
  }

  /// Decode value to int.
  int asInt() {
    final value = _value;
    if (value != null) {
      final intValue = int.tryParse(value) ?? defaultValueForInt;
      return intValue;
    } else {
      return defaultValueForInt;
    }
  }

  /// Decode value to double.
  double asDouble() {
    final value = _value;
    if (value != null) {
      final doubleValue = double.tryParse(value) ?? defaultValueForDouble;
      return doubleValue;
    } else {
      return defaultValueForDouble;
    }
  }

  /// Decode value to bool.
  bool asBool() {
    final value = _value;
    if (value != null) {
      final lowerCase = value.toLowerCase();
      return lowerCase == 'true' || lowerCase == '1';
    } else {
      return defaultValueForBool;
    }
  }

  @override
  String toString() {
    return 'RemoteConfigValue(value: $_value, source: $source)';
  }
}
