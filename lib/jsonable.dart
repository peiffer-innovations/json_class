import 'dart:convert';

import 'package:logging/logging.dart';

/// Abstract class that other classes should extend to provide conversion to or
/// from JSON.
abstract class Jsonable {
  static final Logger _logger = Logger('Jsonable');

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
  static double parseDouble(
    dynamic value, [
    double defaultValue,
  ]) {
    double result;
    try {
      if (value is String) {
        result = double.tryParse(value);
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

  /// Converts the given list of [Jsonable] objects into JSON.  If the given
  /// list is [null] then [null] will be returned.
  static List<dynamic> toJsonList(List<Jsonable> list) {
    List<dynamic> result;

    if (list != null) {
      result = [];
      for (var j in list) {
        result.add(j.toJson());
      }
    }

    return result;
  }

  /// Abstract function that concrete classes must implement.  This effectively
  /// JSON encodes the class's internal data model.
  Map<String, dynamic> toJson();

  /// Returns the string encoded JSON representation for this class.
  @override
  String toString() => json.encode(toJson());
}
