import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:json_class/json_class.dart';
import 'package:logging/logging.dart';

/// Abstract class that other classes should extend to provide conversion to or
/// from JSON.
abstract class JsonClass {
  const JsonClass();

  static final Logger _logger = Logger('JsonClass');

  /// Helper function to create a [list] of dynamic objects given a [builder]
  /// that can build a single object.
  static List<T>? fromDynamicList<T>(
    Iterable<dynamic>? list,
    JsonClassBuilder<T> builder,
  ) {
    List<T>? result;

    if (list != null) {
      result = [];
      for (var map in list) {
        result.add(builder(map));
      }
    }

    return result;
  }

  /// Parses the dynamic [value] into a [bool].  This will return [true] if and
  /// only if the value is...
  /// * [true]
  /// * `"true"` (case insensitive)
  /// * `"yes"` (case insensitive)
  /// * `1`
  ///
  /// Any other value will result in [false].
  static bool parseBool(
    dynamic value, {
    bool whenNull = false,
  }) {
    var result = false;

    if (value == null) {
      result = whenNull;
    } else {
      result = result || value == true;
      result = result || parseInt(value) == 1;
      if (result != true && value is String) {
        final lower = value.toLowerCase();
        result = result || lower == 'true';
        result = result || lower == 'yes';
      }
    }

    return result;
  }

  /// Parses the given [value] into a [DateTime] object.  If the [value] cannot
  /// be parsed then null will be returned.
  ///
  /// The following formats will result in the [DateTime] object being returned
  /// as a UTC based [DateTime]:
  /// * `"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"`
  /// * `"yyyy-MM-dd'T'HH:mm:ss'Z'"`
  /// * `"yyyy-MM-dd'T'HH:mm'Z'"`
  ///
  /// The following formats will result in the [DateTime] object being returned
  /// as a local timezone based [DateTime]:
  /// * `"yyyy-MM-dd'T'HH:mm:ss"`
  /// * `"yyyy-MM-dd'T'HH:mm"`
  /// * `'yyyy-MM-dd'`
  /// * `'MM/dd/yyyy'`
  ///
  /// Alternatively, the value may be in UTC Millis and that will also properly
  /// decode to a DateTime.
  static DateTime? parseDateTime(dynamic value) {
    DateTime? result;

    if (value is DateTime) {
      result = value;
    } else {
      result = parseUtcMillis(value);
    }

    if (value != null) {
      const utcPatterns = [
        "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
        "yyyy-MM-dd'T'HH:mm:ss'Z'",
        "yyyy-MM-dd'T'HH:mm'Z'",
      ];

      const patterns = [
        "yyyy-MM-dd'T'HH:mm:ss.SSS",
        "yyyy-MM-dd'T'HH:mm:ss",
        "yyyy-MM-dd'T'HH:mm",
        'yyyy-MM-dd',
        'MM/dd/yyyy'
      ];

      for (var pattern in utcPatterns) {
        try {
          result = DateFormat(pattern).parse(
            value,
            true,
          );
          break;
        } catch (e) {
          // no-op
        }
      }
      if (result == null) {
        for (var pattern in patterns) {
          try {
            result = DateFormat(pattern).parse(value, false);
            break;
          } catch (e) {
            // no-op
          }
        }
      }
    }

    return result;
  }

  /// Parses the dynamic [value] into a double.  The [value] may be a [String],
  /// [int], or [double].  If the [value] cannot be successfully parsed into a
  /// [double] then the [defaultValue] will be returned.
  ///
  /// A value of the string "infinity" will result in [double.infinity].
  static double? parseDouble(
    dynamic value, [
    double? defaultValue,
  ]) {
    double? result;
    try {
      if (value is String) {
        if (value.toLowerCase() == 'infinity') {
          result = double.infinity;
        } else if (value.startsWith('0x') == true) {
          result = int.tryParse(value.substring(2), radix: 16)?.toDouble();
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

  /// Parses a duration from milliseconds.  The [value] may be an [int],
  /// [double], or number encoded [String].  If the [value] cannot be processed
  /// into a duration then this will return the [defaultValue].
  static Duration? parseDurationFromMillis(
    dynamic value, [
    Duration? defaultValue,
  ]) {
    final millis = parseInt(value);

    return millis == null ? defaultValue : Duration(milliseconds: millis);
  }

  /// Parses a duration from seconds.  The [value] may be an [int], [double], or
  /// number encoded [String].  If the [value] cannot be processed into a
  /// duration then this will return the [defaultValue].
  static Duration? parseDurationFromSeconds(
    dynamic value, [
    Duration? defaultValue,
  ]) {
    final seconds = parseInt(value);

    return seconds == null ? defaultValue : Duration(seconds: seconds);
  }

  /// Parses the dynamic [value] into a int.  The value may be a [String], [int],
  /// [double].  If the [value] cannot be successfully parsed into an [int] then
  /// [the [defaultValue] will be returned.
  static int? parseInt(
    dynamic value, [
    int? defaultValue,
  ]) =>
      parseDouble(value)?.toInt() ?? defaultValue;

  /// Parses the dynamic [value] in to it's JSON decoded form.  If the [value]
  /// cannot be decoded this will either return the [defaultValue], if not null,
  /// or return the [value] that was passed in if [defaultValue] is null.
  static dynamic parseJson(
    dynamic value, [
    dynamic defaultValue,
  ]) {
    final result = value;

    if (value is String) {
      try {
        value = json.decode(value);
      } catch (e) {
        value = defaultValue ?? value;
      }
    }

    return result;
  }

  /// Parses the dynamic [value] into a [Level] suitable for usage with the
  /// logging package.  The [value] is case-insensitive accepted values are:
  ///
  /// * `all`
  /// * `config`
  /// * `fine`
  /// * `finer`
  /// * `finest`
  /// * `off`
  /// * `severe`
  /// * `shout`
  /// * `warning`
  ///
  /// Any other value will result in the [defaultLevel] being returned
  static Level parseLevel(dynamic value, [Level defaultLevel = Level.INFO]) {
    final str = value?.toString().toLowerCase();
    var result = defaultLevel;

    switch (str) {
      case 'all':
        result = Level.ALL;
        break;

      case 'config':
        result = Level.CONFIG;
        break;

      case 'fine':
        result = Level.FINE;
        break;

      case 'finer':
        result = Level.FINER;
        break;

      case 'finest':
        result = Level.FINEST;
        break;

      case 'off':
        result = Level.OFF;
        break;

      case 'severe':
        result = Level.SEVERE;
        break;

      case 'shout':
        result = Level.SHOUT;
        break;

      case 'warning':
        result = Level.WARNING;
        break;
    }

    return result;
  }

  /// Parses the given UTC Millis into a proper [DateTime] class.  If the
  /// [value] cannot be processed then this will return the [defaultValue] or
  /// null if there is no provided [defaultValue].
  static DateTime? parseUtcMillis(
    dynamic value, [
    int? defaultValue,
  ]) {
    DateTime? result;
    int? input;

    if (value is int) {
      input = value;
    } else if (value is String || value is double) {
      input = JsonClass.parseInt(value);
    }

    if (input == null) {
      result = defaultValue == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              defaultValue,
              isUtc: true,
            );
    } else {
      result = DateTime.fromMillisecondsSinceEpoch(
        input,
        isUtc: true,
      );
    }

    return result;
  }

  /// Converts the given [list] of [JsonClass] objects into JSON.  If the given
  /// list is null` then null will be returned.
  static List<dynamic>? toJsonList(List<JsonClass>? list) {
    List<dynamic>? result;

    if (list != null) {
      result = [];
      for (var j in list) {
        result.add(j.toJson());
      }
    }

    return result;
  }

  static dynamic parseValue<T>(dynamic input) {
    dynamic result;

    if (T == bool) {
      result = parseBool(input);
    } else if (T == String) {
      result = input?.toString();
    } else if (T == double) {
      result = parseDouble(input);
    } else if (T == int) {
      result = parseInt(input);
    } else if (T == num) {
      result = parseDouble(input);
    } else if (T == DateTime) {
      result = parseDateTime(input);
    } else if (T == Duration) {
      result = parseDurationFromMillis(input);
    } else {
      throw Exception('Unknown value type: [${T.runtimeType}]');
    }

    return result;
  }

  /// Removes null values from the given input.  This defaults to removing
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
  static dynamic removeNull(
    dynamic input, [
    bool removeEmptyCollections = true,
  ]) {
    dynamic result;

    if (input != null) {
      result ??= <String, dynamic>{};

      for (var entry in input.entries) {
        if (entry.value != null) {
          if (entry.value is Map) {
            final processed = removeNull(
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
  /// remove all null values and empty collections from the returned string.
  @override
  String toString() => json.encode(removeNull(toJson()));
}
