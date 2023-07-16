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
  static List<T> fromDynamicList<T>(
    Iterable<dynamic> list,
    JsonClassBuilder<T> builder,
  ) {
    final result = maybeFromDynamicList(list, builder);

    if (result == null) {
      throw Exception('Attempted to parse dynamic list but received null');
    }

    return result;
  }

  /// Helper function to create a [map] of string keys to dynamic objects given
  /// a [builder] that can build a single object.
  static Map<String, T> fromDynamicMap<T>(
    dynamic map,
    JsonClassBuilder<T> builder,
  ) {
    final result = maybeFromDynamicMap(map, builder);

    if (result == null) {
      throw Exception(
        'Requested non-nullable fromDynamicMap but null was encountered.',
      );
    }

    return result;
  }

  /// Helper function to create a [map] of string keys to dynamic objects given
  /// a [builder] that can build a single object with the key from the incoming
  /// map being passed to the builder.
  static Map<String, T> fromDynamicMapWithKey<T>(
    dynamic map,
    JsonClassWithKeyBuilder<T> builder,
  ) {
    final result = maybeFromDynamicMapWithKey(map, builder);

    if (result == null) {
      throw Exception(
        'Requested non-nullable fromDynamicMapWithKey but null was encountered.',
      );
    }

    return result;
  }

  /// Helper function to create a [list] of dynamic objects given a [builder]
  /// that can build a single object.
  static List<T>? maybeFromDynamicList<T>(
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

  /// Helper function to create a [map] of string keys to dynamic objects given
  /// a [builder] that can build a single object.
  static Map<String, T>? maybeFromDynamicMap<T>(
    dynamic map,
    JsonClassBuilder<T> builder,
  ) {
    Map<String, T>? result;

    if (map != null) {
      result = {};
      for (var entry in map.entries) {
        result[entry.key] = builder(entry.value);
      }
    }

    return result;
  }

  /// Helper function to create a [map] of string keys to dynamic objects given
  /// a [builder] that can build a single object with the key from the incoming
  /// map being passed to the builder.
  static Map<String, T>? maybeFromDynamicMapWithKey<T>(
    dynamic map,
    JsonClassWithKeyBuilder<T> builder,
  ) {
    Map<String, T>? result;

    if (map != null) {
      result = {};
      for (var entry in map.entries) {
        result[entry.key] = builder(
          entry.value,
          key: entry.key,
        );
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
  /// When [value] is null, this will return null.
  static bool? maybeParseBool(dynamic value) {
    bool? result;

    if (value != null) {
      if (value is bool) {
        result = value;
      } else if (value is String) {
        final lower = value.toLowerCase();
        result = lower == 'true' || lower == 'yes';
      } else {
        result = maybeParseInt(value) == 1;
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
  static DateTime? maybeParseDateTime(dynamic value) {
    DateTime? result;

    if (value is DateTime) {
      result = value;
    } else {
      result = maybeParseUtcMillis(value);
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
  static double? maybeParseDouble(
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

  /// Parses the dynamic [value] into a [List] of double values.  The value may
  /// be null, in which case null will be returned, or it may be an array of any
  /// type, but each element in the array must be parsable into a valid double
  /// or an error will be thrown.
  static List<double>? maybeParseDoubleList(dynamic value) {
    List<double>? result;

    if (value is Iterable) {
      result = [];
      for (var v in value) {
        result.add(parseDouble(v));
      }
    }

    return result;
  }

  /// Parses a duration from milliseconds.  The [value] may be an [int],
  /// [double], or number encoded [String].
  static Duration? maybeParseDurationFromMillis(dynamic value) {
    final millis =
        value is Duration ? value.inMilliseconds : maybeParseInt(value);

    return millis == null ? null : Duration(milliseconds: millis);
  }

  /// Parses a duration from seconds.  The [value] may be an [int], [double], or
  /// number encoded [String].
  static Duration? maybeParseDurationFromSeconds(dynamic value) {
    final seconds = value is Duration ? value.inSeconds : maybeParseInt(value);

    return seconds == null ? null : Duration(seconds: seconds);
  }

  /// Parses the dynamic [value] into a int.  The value may be a [String], [int],
  /// [double].  If the [value] cannot be successfully parsed into an [int] then
  /// [the [defaultValue] will be returned.
  static int? maybeParseInt(dynamic value) => maybeParseDouble(value)?.toInt();

  /// Parses the dynamic [value] into a [List] of int values.  The value may be
  /// null, in which case null will be returned, or it may be an array of any
  /// type, but each element in the array must be parsable into a valid int or
  /// an error will be thrown.
  static List<int>? maybeParseIntList(dynamic value) {
    List<int>? result;

    if (value is List) {
      result = [];
      for (var v in value) {
        result.add(parseInt(v));
      }
    }

    return result;
  }

  /// Parses the dynamic [value] in to it's JSON decoded form.  If the [value]
  /// cannot be decoded this will either return null.
  static dynamic maybeParseJson(dynamic value) {
    var result = value;

    try {
      if (value is Map) {
        result = Map<String, dynamic>.from(value);
      } else if (value is String) {
        result = json.decode(value);
      }
    } catch (e, stack) {
      _logger.severe(
        'Error parsing value: [$value]',
        e,
        stack,
      );
    }

    return result;
  }

  /// Parses the given UTC Millis into a proper [DateTime] class.  If the
  /// [value] cannot be processed then this will return null.
  static DateTime? maybeParseUtcMillis(dynamic value) {
    DateTime? result;
    int? input;

    if (value is DateTime) {
      result = value;
    } else if (value is int) {
      input = value;
    } else if (value is String || value is double) {
      input = JsonClass.maybeParseInt(value);
    }

    if (input != null) {
      result = DateTime.fromMillisecondsSinceEpoch(
        input,
        isUtc: true,
      );
    }

    return result;
  }

  /// Converts the given [list] of [JsonClass] objects into JSON.  If the given
  /// list is null` then null will be returned.
  static List<dynamic>? maybeToJsonList(List<JsonClass>? list) {
    List<dynamic>? result;

    if (list != null) {
      result = [];
      for (var j in list) {
        result.add(j.toJson());
      }
    }

    return result;
  }

  /// Attempts to parse the given [input] into the type [T].  This currently
  /// supports the following types:
  ///
  /// * `bool`
  /// * `String`
  /// * `double`
  /// * `int`
  /// * `num`
  /// * `DateTime`
  /// * `Duration`
  ///
  /// Any other type will result in an exception.
  static T? maybeParseValue<T>(dynamic input) {
    dynamic result;

    if (T == bool) {
      result = maybeParseBool(input);
    } else if (T == String) {
      result = input?.toString();
    } else if (T == double) {
      result = maybeParseDouble(input);
    } else if (T == int) {
      result = maybeParseInt(input);
    } else if (T == num) {
      result = maybeParseDouble(input);
    } else if (T == DateTime) {
      result = maybeParseDateTime(input);
    } else if (T == Duration) {
      result = maybeParseDurationFromMillis(input);
    } else {
      throw Exception('Unknown value type: [${T.runtimeType}]');
    }

    return result as T?;
  }

  /// Parses the dynamic [value] into a [bool].  This will return [true] if and
  /// only if the value is...
  /// * [true]
  /// * `"true"` (case insensitive)
  /// * `"yes"` (case insensitive)
  /// * `1`
  ///
  /// When [value] is null, this will return [whenNull].
  static bool parseBool(dynamic value, {bool whenNull = false}) {
    final result = maybeParseBool(value) ?? whenNull;

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
  static DateTime parseDateTime(dynamic value) {
    DateTime? result;

    if (value is DateTime) {
      result = value;
    } else {
      result = maybeParseUtcMillis(value);
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

    if (result == null) {
      throw Exception(
        'Non-nullable parseDateTime was called but null was encountered',
      );
    }

    return result;
  }

  /// Parses the dynamic [value] into a double.  The [value] may be a [String],
  /// [int], or [double].  If the [value] cannot be successfully parsed into a
  /// [double] then null will be returned.
  ///
  /// A value of the string "infinity" will result in [double.infinity].
  static double parseDouble(dynamic value) {
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

    if (result == null) {
      throw Exception(
        'Non-nullable parseDouble was called but null was encountered',
      );
    }

    return result;
  }

  /// Parses the dynamic [value] into a [List] of double values.  The value may
  /// be null, in which case null will be returned, or it may be an array of any
  /// type, but each element in the array must be parsable into a valid double
  /// or an error will be thrown.
  static List<double> parseDoubleList(dynamic value) {
    List<double>? result;

    if (value is Iterable) {
      result = [];
      for (var v in value) {
        result.add(parseDouble(v));
      }
    }

    if (result == null) {
      throw Exception(
        'Non-nullable parseDoubleList was called but null was encountered',
      );
    }

    return result;
  }

  /// Parses a duration from milliseconds.  The [value] may be an [int],
  /// [double], or number encoded [String].
  static Duration? parseDurationFromMillis(dynamic value) {
    final result = value is Duration ? value.inMilliseconds : parseInt(value);

    return Duration(milliseconds: result);
  }

  /// Parses a duration from seconds.  The [value] may be an [int], [double], or
  /// number encoded [String].
  static Duration parseDurationFromSeconds(dynamic value) {
    final result = value is Duration ? value.inSeconds : parseInt(value);

    return Duration(seconds: result);
  }

  /// Parses the dynamic [value] into a int.  The value may be a [String], [int],
  /// [double].
  static int parseInt(dynamic value) => parseDouble(value).toInt();

  /// Parses the dynamic [value] into a [List] of int values.  The value may be
  /// null, in which case null will be returned, or it may be an array of any
  /// type, but each element in the array must be parsable into a valid int or
  /// an error will be thrown.
  static List<int> parseIntList(dynamic value) {
    final result = maybeParseIntList(value);

    if (result == null) {
      throw Exception(
        'Non-nullable parseIntList was called but null was encountered',
      );
    }

    return result;
  }

  /// Parses the dynamic [value] in to it's JSON decoded form.
  static dynamic parseJson(dynamic value) {
    var result = value;

    try {
      if (value is Map) {
        result = Map<String, dynamic>.from(value);
      } else if (value is String) {
        result = json.decode(value);
      }
    } catch (e, stack) {
      _logger.severe(
        'Error parsing value: [$value]',
        e,
        stack,
      );
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

  /// Parses the given UTC Millis into a proper [DateTime] class.
  static DateTime parseUtcMillis(dynamic value) {
    final result = maybeParseUtcMillis(value);

    if (result == null) {
      throw Exception(
        'Non-nullable parseUtcMillis was called but null was encountered',
      );
    }

    return result;
  }

  /// Converts the given [list] of [JsonClass] objects into JSON.  If the given
  /// list is null` then null will be returned.
  static List<dynamic> toJsonList(List<JsonClass> list) {
    final result = maybeToJsonList(list);

    if (result == null) {
      throw Exception(
        'Non-nullable toJsonList was called but null was encountered',
      );
    }

    return result;
  }

  /// Attempts to parse the given [input] into the type [T].  This currently
  /// supports the following types:
  ///
  /// * `bool`
  /// * `String`
  /// * `double`
  /// * `int`
  /// * `num`
  /// * `DateTime`
  /// * `Duration`
  ///
  /// Any other type will result in an exception.
  static T parseValue<T>(dynamic input) {
    final result = maybeParseValue<T>(input);

    if (result == null) {
      throw Exception(
        'Non-nullable parseValue was called but null was encountered',
      );
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
