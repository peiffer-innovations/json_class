# json_class

Singular class that when extended can encode itself to a JSON compatible map or list.  This also provides convenience functions to decode from a JSON compatible map or list to the actual data model.

## Using the library

Add the repo to your Flutter `pubspec.yaml` file.

```
dependencies:
  json_class: <<version>> 
```

Then run...
```
flutter packages get
```


## Example

```dart
import 'package:json_class/json_class.dart';
import 'package:meta/meta.dart';

@immutable
class Person extends JsonClass {
  Person({
    this.age,
    this.minor,
    this.firstName,
    this.lastName,
  });

  final int age;
  final bool minor;
  final String firstName;
  final String lastName;

  static Person fromDynamic(dynamic map) {
    // It's recommended to use dynamic over Map<String, dynamic> because it's
    // compatible with other types of map-like results such as Firebase Realtime
    // Database's values or the ones returned from sqlflite.
    Person result;

    if (map != null) {
      result = Person(
        age: JsonClass.parseInt(map['age']),
        minor: JsonClass.parseBool(map['minor']),
        firstName: map['firstName'],
        lastName: map['lastName'],
      );
    }

    return result;
  }

  static List<Person> fromDynamicList(Iterable<dynamic> list) {
    List<Person> results;

    if (list != null) {
      results = [];
      for (dynamic map in list) {
        results.add(fromDynamic(map));
      }
    }

    return results;
  }

  @override
  Map<String, dynamic> toJson() => JsonClass.removeNull({
    age: age,
    minor: minor,
    firstName: firstName,
    lastName: lastName,
  });
}


class SomeoneElseWhoUsesMyUiFramework extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MyUiFramework(
      childWidgetBuilder: (BuildContext context, Widget child) {
        return Container(
          // This would allow you to find by key this specific widget
          key: ValueKey('MySpiffyUiWidgetKey'),
          child: child,
        );
      }
    );
  }
}
```