import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared/env.dart';

import 'demo.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  static String _pkg = "parallax_travel_cards_list";
  static String get pkg => Env.getPackage(_pkg);

  @override
  Widget build(BuildContext context) {
    //스크린 세로로 고정
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);

    /* 스크린 가로로 고정
      SystemChrome.setPreferredOrientations([

      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);*/

    return MaterialApp(
      home: TravelCardDemo(),
    );
  }
}
