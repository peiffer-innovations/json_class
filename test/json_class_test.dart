import 'package:json_class/json_class.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  test('JsonClass.parseBool', () {
    expect(JsonClass.parseBool('false'), false);
    expect(JsonClass.parseBool('FALSE'), false);
    expect(JsonClass.parseBool('NO'), false);
    expect(JsonClass.parseBool('no'), false);
    expect(JsonClass.parseBool(0), false);
    expect(JsonClass.parseBool(false), false);
    expect(JsonClass.parseBool(null), false);

    expect(JsonClass.parseBool('true'), true);
    expect(JsonClass.parseBool('TRUE'), true);
    expect(JsonClass.parseBool('YES'), true);
    expect(JsonClass.parseBool('yes'), true);
    expect(JsonClass.parseBool(1), true);
    expect(JsonClass.parseBool(true), true);

    expect(JsonClass.parseBool(null, whenNull: false), false);
    expect(JsonClass.parseBool(null, whenNull: true), true);
  });

  test('JsonClass.parseDateTime', () {
    expect(
      JsonClass.parseDateTime(null),
      null,
    );

    expect(
      JsonClass.parseDateTime(DateTime(2019, 01, 01)),
      DateTime(2019, 01, 01),
    );

    expect(
      JsonClass.parseDateTime('01/02/2020'),
      DateTime(2020, 01, 02),
    );
    expect(
      JsonClass.parseDateTime('01/02/2020')!.isUtc,
      false,
    );

    expect(
      JsonClass.parseDateTime('2020-02-01'),
      DateTime(2020, 02, 01),
    );
    expect(
      JsonClass.parseDateTime('2020-02-01')!.isUtc,
      false,
    );

    expect(
      JsonClass.parseDateTime('2020-02-01T12:30'),
      DateTime(2020, 02, 01, 12, 30),
    );
    expect(
      JsonClass.parseDateTime('2020-02-01T12:30')!.isUtc,
      false,
    );

    expect(
      JsonClass.parseDateTime('2020-02-01T12:30:45'),
      DateTime(2020, 02, 01, 12, 30, 45),
    );
    expect(
      JsonClass.parseDateTime('2020-02-01T12:30:45')!.isUtc,
      false,
    );

    expect(
      JsonClass.parseDateTime('2020-02-01T12:30:45.123'),
      DateTime(2020, 02, 01, 12, 30, 45, 123),
    );
    expect(
      JsonClass.parseDateTime('2020-02-01T12:30:45.123')!.isUtc,
      false,
    );

    expect(
      JsonClass.parseDateTime('2020-02-01T12:30Z')!.isUtc,
      true,
    );
    expect(
      JsonClass.parseDateTime('2020-02-01T12:30:45Z')!.isUtc,
      true,
    );
    expect(
      JsonClass.parseDateTime('2020-02-01T12:30:45.123Z')!.isUtc,
      true,
    );

    const millis = 1586717564014;
    expect(
      JsonClass.parseDateTime(millis)?.millisecondsSinceEpoch,
      millis,
    );
    expect(
      JsonClass.parseDateTime('$millis')?.millisecondsSinceEpoch,
      millis,
    );
    expect(JsonClass.parseDateTime(millis)!.isUtc, true);
  });

  test('JsonClass.parseDouble', () {
    expect(JsonClass.parseDouble(null), null);
    expect(
      JsonClass.parseDouble('infinity'),
      double.infinity,
    );
    expect(
      JsonClass.parseDouble('INFINITY'),
      double.infinity,
    );
    expect(JsonClass.parseDouble(1.23), 1.23);
    expect(JsonClass.parseDouble('1.23'), 1.23);
    expect(JsonClass.parseDouble('1.0'), 1.0);
    expect(JsonClass.parseDouble(1.0), 1.0);
    expect(JsonClass.parseDouble(1), 1.0);

    expect(JsonClass.parseDouble('0xff'), 0xff);
  });

  test('JsonClass.parseDoubleList', () {
    expect(JsonClass.parseDoubleList(null), null);
    expect(
      JsonClass.parseDoubleList(
        [
          1.23,
          '1.23',
          '1.0',
          1,
          '0xff',
        ],
      ),
      [
        1.23,
        1.23,
        1.0,
        1.0,
        0xff.toDouble(),
      ],
    );
  });

  test('JsonClass.parseDurationFromMillis', () {
    expect(JsonClass.parseDurationFromMillis(null), null);
    expect(JsonClass.parseDurationFromMillis(123),
        const Duration(milliseconds: 123));
    expect(
      JsonClass.parseDurationFromMillis(123.5),
      const Duration(milliseconds: 123),
    );
    expect(
      JsonClass.parseDurationFromMillis('123'),
      const Duration(milliseconds: 123),
    );
    expect(
      JsonClass.parseDurationFromMillis('123.5'),
      const Duration(milliseconds: 123),
    );
  });

  test('JsonClass.parseDurationFromSeconds', () {
    expect(JsonClass.parseDurationFromSeconds(null), null);
    expect(
        JsonClass.parseDurationFromSeconds(123), const Duration(seconds: 123));
    expect(JsonClass.parseDurationFromSeconds(123.5),
        const Duration(seconds: 123));
    expect(JsonClass.parseDurationFromSeconds('123'),
        const Duration(seconds: 123));
    expect(JsonClass.parseDurationFromSeconds('123.5'),
        const Duration(seconds: 123));
  });

  test('JsonClass.parseInt', () {
    expect(JsonClass.parseInt(null), null);
    expect(JsonClass.parseInt(1.23), 1);
    expect(JsonClass.parseInt('1.23'), 1);
    expect(JsonClass.parseInt('1.0'), 1);
    expect(JsonClass.parseInt(1.0), 1);
    expect(JsonClass.parseInt(1), 1);
    expect(JsonClass.parseInt('0xff'), 0xff);
  });

  test('JsonClass.parseIntList', () {
    expect(JsonClass.parseIntList(null), null);

    expect(
      JsonClass.parseIntList(
        [
          1.23,
          '1.23',
          '1.0',
          1,
          0xff,
        ],
      ),
      [
        1,
        1,
        1,
        1,
        0xff,
      ],
    );
  });

  test('JsonClass.parseLevel', () {
    final levels = {
      'all': Level.ALL,
      'config': Level.CONFIG,
      'fine': Level.FINE,
      'finer': Level.FINER,
      'finest': Level.FINEST,
      'off': Level.OFF,
      'severe': Level.SEVERE,
      'shout': Level.SHOUT,
      'warning': Level.WARNING,
    };

    expect(JsonClass.parseLevel('default', Level.OFF), Level.OFF);

    for (var entry in levels.entries) {
      expect(JsonClass.parseLevel(entry.key), entry.value);
    }
  });

  test('JsonClass.parseUtcMillis', () {
    const millis = 1586717564014;

    expect(JsonClass.parseUtcMillis(null), null);
    expect(
        JsonClass.parseUtcMillis(null, millis)?.millisecondsSinceEpoch, millis);
    expect(JsonClass.parseUtcMillis(millis)?.millisecondsSinceEpoch, millis);
    expect(JsonClass.parseUtcMillis('$millis')?.millisecondsSinceEpoch, millis);
    expect(JsonClass.parseUtcMillis(millis)?.isUtc, true);
  });

  test('JsonClass.parseValue', () {
    expect(
      JsonClass.parseValue<DateTime>(null),
      null,
    );

    expect(
      JsonClass.parseValue<DateTime>(DateTime(2019, 01, 01)),
      DateTime(2019, 01, 01),
    );

    expect(
      JsonClass.parseValue<DateTime>('01/02/2020'),
      DateTime(2020, 01, 02),
    );
    expect(
      JsonClass.parseValue<DateTime>('01/02/2020')!.isUtc,
      false,
    );

    expect(
      JsonClass.parseValue<DateTime>('2020-02-01'),
      DateTime(2020, 02, 01),
    );
    expect(
      JsonClass.parseValue<DateTime>('2020-02-01')!.isUtc,
      false,
    );

    expect(
      JsonClass.parseValue<DateTime>('2020-02-01T12:30'),
      DateTime(2020, 02, 01, 12, 30),
    );
    expect(
      JsonClass.parseValue<DateTime>('2020-02-01T12:30')!.isUtc,
      false,
    );

    expect(
      JsonClass.parseValue<DateTime>('2020-02-01T12:30:45'),
      DateTime(2020, 02, 01, 12, 30, 45),
    );
    expect(
      JsonClass.parseValue<DateTime>('2020-02-01T12:30:45')!.isUtc,
      false,
    );

    expect(
      JsonClass.parseValue<DateTime>('2020-02-01T12:30:45.123'),
      DateTime(2020, 02, 01, 12, 30, 45, 123),
    );
    expect(
      JsonClass.parseValue<DateTime>('2020-02-01T12:30:45.123')!.isUtc,
      false,
    );

    expect(
      JsonClass.parseValue<DateTime>('2020-02-01T12:30Z')!.isUtc,
      true,
    );
    expect(
      JsonClass.parseValue<DateTime>('2020-02-01T12:30:45Z')!.isUtc,
      true,
    );
    expect(
      JsonClass.parseValue<DateTime>('2020-02-01T12:30:45.123Z')!.isUtc,
      true,
    );

    const millis = 1586717564014;
    expect(
      JsonClass.parseValue<DateTime>(millis)?.millisecondsSinceEpoch,
      millis,
    );
    expect(
      JsonClass.parseValue<DateTime>('$millis')?.millisecondsSinceEpoch,
      millis,
    );
    expect(JsonClass.parseValue<DateTime>(millis)!.isUtc, true);

    expect(JsonClass.parseValue<double>(null), null);
    expect(JsonClass.parseValue<double>(123), 123.0);
    expect(JsonClass.parseValue<double>(123.45), 123.45);
    expect(JsonClass.parseValue<double>('123'), 123.0);
    expect(JsonClass.parseValue<double>('123.45'), 123.45);
    expect(JsonClass.parseValue<double>('foo'), null);

    expect(JsonClass.parseValue<Duration>(null), null);
    expect(
        JsonClass.parseValue<Duration>(123), const Duration(milliseconds: 123));
    expect(JsonClass.parseValue<Duration>(123.45),
        const Duration(milliseconds: 123));
    expect(
      JsonClass.parseValue<Duration>('123'),
      const Duration(milliseconds: 123),
    );
    expect(
      JsonClass.parseValue<Duration>('123.45'),
      const Duration(milliseconds: 123),
    );
    expect(JsonClass.parseValue<Duration>('foo'), null);

    expect(JsonClass.parseValue<int>(null), null);
    expect(JsonClass.parseValue<int>(123), 123);
    expect(JsonClass.parseValue<int>(123.45), 123);
    expect(JsonClass.parseValue<int>('123'), 123);
    expect(JsonClass.parseValue<int>('123.45'), 123);
    expect(JsonClass.parseValue<int>('foo'), null);

    expect(JsonClass.parseValue<String>(null), null);
    expect(JsonClass.parseValue<String>('foo'), 'foo');
    expect(JsonClass.parseValue<String>(123.45), '123.45');
  });

  test('JsonClass.removeNull', () {
    final data = {
      'foo': 'bar',
      'other': null,
      'list': [],
      'map': {'value': null},
    };

    expect(
      JsonClass.removeNull(data),
      {'foo': 'bar'},
    );
    expect(
      JsonClass.removeNull(data, false),
      {'foo': 'bar', 'list': [], 'map': {}},
    );
  });
}
