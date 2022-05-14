// ignore_for_file: require_trailing_commas
/// Defines the options for the corresponding Remote Config instance.
class RemoteConfigSettings {
  /// Constructs an instance of [RemoteConfigSettings] with given [fetchTimeout]
  /// and [minimumFetchInterval].
  RemoteConfigSettings({
    this.fetchTimeout = const Duration(minutes: 10),
    this.minimumFetchInterval = const Duration(hours: 12),
  });

  /// Maximum Duration to wait for a response when fetching configuration from
  /// the Remote Config server. Defaults to one minute.
  Duration fetchTimeout;

  /// Maximum age of a cached config before it is considered stale. Defaults
  /// to twelve hours.
  Duration minimumFetchInterval;

  @override
  String toString() =>
      'RemoteConfigSettings(fetchTimeout: $fetchTimeout, minimumFetchInterval: $minimumFetchInterval)';
}
