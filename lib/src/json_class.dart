import 'dart:convert';

import 'package:json_class/json_class.dart';
import 'package:logging/logging.dart';

/// Abstract class that other classes should extend to provide conversion to or
/// from JSON.
abstract class JsonClass {
  static final Logger _logger = Logger('JsonClass');

  /// Helper function to create a list of dynamic objects given a [builder] that
  /// can build a single object.
  static List<T> fromDynamicList<T>(
    Iterable<dynamic> list,
    JsonClassBuilder<T> builder,
  ) {
    List<T> result;

    if (list != null) {
      result = [];
      for (var map in list) {
        result.add(builder(map));
      }
    }

    return result;
  }

  /// Parses the dynamic value into a [bool].  This will return [true] if and
  /// only if the value is...
  /// * [true]
  /// * `"true"` (case insensitive)
  /// * `"yes"` (case insensitive)
  /// * `1`
  ///
  /// Any other value will result in [false].
  static bool parseBool(dynamic value) {
    var result = false;

    result = result || value == true;
    result = result || parseInt(value) == 1;
    if (result != true && value is String) {
      var lower = value.toLowerCase();
      result = result || lower == 'true';
      result = result || lower == 'yes';
    }

    return result;
  }

  /// Parses the dynamic value into a double.  The value may be a [String],
  /// [int], or [double].  If the value cannot be successfully parsed into a
  /// [double] then the [defaultValue] will be returned.
  ///
  /// A value of the string `infinity` will result in `double.infinity`.
  static double parseDouble(
    dynamic value, [
    double defaultValue,
  ]) {
    double result;
    try {
      if (value is String) {
        if (value.toLowerCase() == 'infinity') {
          result = double.infinity;
        } else {
          result = double.tryParse(value);
        }
      } else if (value is double) {
        result = value;
      } else if (value is int) {
        result = value.toDouble();
      }
    } catch (e, stack) {
      _logger.finest('Error parsing: $value', e, stack);
    }

    return result ?? defaultValue;
  }

  /// Parses a duration from milliseconds.  The value may be an [int], [double],
  /// or number encoded [String].  If the value cannot be processed into a
  /// duration then this will return the [defaultValue].
  static Duration parseDurationFromMillis(
    dynamic value, [
    Duration defaultValue,
  ]) {
    var millis = parseInt(value);

    return millis == null ? defaultValue : Duration(milliseconds: millis);
  }

  /// Parses a duration from seconds.  The value may be an [int], [double], or
  /// number encoded [String].  If the value cannot be processed into a duration
  /// then this will return the [defaultValue].
  static Duration parseDurationFromSeconds(
    dynamic value, [
    Duration defaultValue,
  ]) {
    var seconds = parseInt(value);

    return seconds == null ? defaultValue : Duration(seconds: seconds);
  }

  /// Parses the dynamic value into a int.  The value may be a [String], [int],
  /// [double].  If the value cannot be successfully parsed into an [int] then
  /// [the [defaultValue] will be returned.
  static int parseInt(
    dynamic value, [
    int defaultValue,
  ]) =>
      parseDouble(value)?.toInt() ?? defaultValue;

  /// Parses the given UTC Millis into a proper [DateTime] class.  If the value
  /// cannot be processed then this will return the [defaultValue].
  static DateTime parseUtcMillis(
    dynamic value, [
    int defaultValue,
  ]) =>
      value == null
          ? defaultValue
          : DateTime.fromMillisecondsSinceEpoch(
              parseInt(value, defaultValue),
              isUtc: true,
            );

  /// Converts the given list of [JsonClass] objects into JSON.  If the given
  /// list is [null] then [null] will be returned.
  static List<dynamic> toJsonList(List<JsonClass> list) {
    List<dynamic> result;

    if (list != null) {
      result = [];
      for (var j in list) {
        result.add(j.toJson());
      }
    }

    return result;
  }

  /// Removes [null] values from the given input.  This defaults to removing
  /// empty lists and maps.  To override this default, set the optional
  /// [removeEmptyCollections] to [false].
  ///
  /// For example, if the the starting input is:
  /// ```json
  /// {
  ///   "foo": "bar",
  ///   "other": null,
  ///   "map": {
  ///     "value": null
  ///   }
  /// }
  /// ```
  ///
  /// A call to [removeNull] will result in the final string:
  /// ```json
  /// {
  ///   "foo": "bar"
  /// }
  /// ```
  static Map<String, dynamic> removeNull(
    Map<String, dynamic> input, [
    bool removeEmptyCollections = true,
  ]) {
    Map<String, dynamic> result;

    if (input != null) {
      result ??= <String, dynamic>{};

      for (var entry in input.entries) {
        if (entry.value != null) {
          if (entry.value is Map) {
            var processed = removeNull(
              entry.value,
              removeEmptyCollections,
            );
            if (processed != null) {
              result[entry.key] = processed;
            }
          } else if (removeEmptyCollections != true ||
              entry.value is! List ||
              entry.value?.isNotEmpty == true) {
            result[entry.key] = entry.value;
          }
        }
      }
    }

    return result?.isNotEmpty == true || removeEmptyCollections == false
        ? result
        : null;
  }

  /// Abstract function that concrete classes must implement.  This must encode
  /// the internal data model to a JSON compatible representation.
  ///
  /// While not required, it is suggested to call [removeNull] before returning.
  Map<String, dynamic> toJson();

  /// Returns the string encoded JSON representation for this class.  This will
  /// remove all [null] values and empty collections from the returned string.
  @override
  String toString() => json.encode(removeNull(toJson()));
}
