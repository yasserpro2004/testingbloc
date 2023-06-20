import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dart:developer' as devtools show log;

extension Log on Object {
  void log() => devtools.log(toString());
}

void main() {
  runApp(
    MaterialApp(
      title: 'demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: BlocProvider(
        create: (_) => PersonBloc(),
        child: const HomePage(),
      ),
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Home Page'),
        ),
        body: Column(
          children: [
            Row(
              children: [
                TextButton(
                    onPressed: () {
                      context
                          .read<PersonBloc>()
                          .add(const LoadPersonAction(url: PersonURL.person1));
                    },
                    child: const Text('Load Persons 1')),
                TextButton(
                    onPressed: () {
                      context
                          .read<PersonBloc>()
                          .add(const LoadPersonAction(url: PersonURL.person2));
                    },
                    child: const Text('Load Persons 2')),
              ],
            ),
            BlocBuilder<PersonBloc, FetchResult?>(
              builder: (context, state) {
                if (state == null) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else {
                  return Expanded(
                    child: ListView.builder(
                      itemCount: state.persons.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(state.persons[index]!.name),
                        );
                      },
                    ),
                  );
                }
              },
            )
          ],
        ));
  }
}

/////////////////////////////////////////////////////////
////////// person model
class Person {
  final String name;
  final int age;

  const Person({required this.name, required this.age});

  Person.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        age = json['age'] as int;
}

//////////////////////////////////////////////////////////
///return data from server   / api

Future<Iterable<Person>> getPersons(String url) {
  return HttpClient()
      .getUrl(Uri.parse(url))
      .then((request) => request.close())
      .then((respons) => respons.transform(utf8.decoder).join())
      .then((str) => json.decode(str) as List<dynamic>)
      .then((list) => list.map((e) => Person.fromJson(e)));
}

//////////////////////////////////////////////////////////
/// Event classes
@immutable
abstract class LoadAction {
  const LoadAction();
}

@immutable
class LoadPersonAction extends LoadAction {
  final PersonURL url;
  const LoadPersonAction({required this.url}) : super();
}

///////////////////////////////////////////////////////////
/// state class
@immutable
class FetchResult {
  final Iterable<Person> persons;
  final bool isRetrivedFromCach;
  const FetchResult({required this.persons, required this.isRetrivedFromCach});

  @override
  String toString() {
    return 'isRetrivedFromCach : $isRetrivedFromCach  , persons = $persons';
  }
}
///////////////////////////////////////////////////////////
///// bloc class

class PersonBloc extends Bloc<LoadAction, FetchResult?> {
  final Map<PersonURL, Iterable<Person>> _cash = {};
  PersonBloc() : super(null) {
    on<LoadPersonAction>(
      (event, emit) async {
        final url = event.url;
        if (_cash.containsKey(url)) {
          final result = FetchResult(
            persons: _cash[url]!,
            isRetrivedFromCach: true,
          );
          if (kDebugMode) {
            print(result.toString());
          }
          emit(result);
        } else {
          final persons = await getPersons(url.urlString);
          final result = FetchResult(
            persons: persons,
            isRetrivedFromCach: false,
          );
          _cash[url] = persons;
          if (kDebugMode) {
            print(result.toString());
          }
          emit(result);
        }
      },
    );
  }
}

///////////////////////////////////////////////////////////
enum PersonURL {
  person1,
  person2,
}

extension URLString on PersonURL {
  String get urlString {
    switch (this) {
      case PersonURL.person1:
        return "http://127.0.0.1:5500/api/person1.json";
      case PersonURL.person2:
        return "http://127.0.0.1:5500/api/person2.json";
    }
  }
}

extension SubScrip<T> on Iterable<T?> {
  T? operator [](int index) => length > index ? elementAt(index) : null;
}
