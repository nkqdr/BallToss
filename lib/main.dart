import 'package:ball_toss/config.dart';
import 'package:ball_toss/home.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var prefs = await SharedPreferences.getInstance();
  double? sensitivity = prefs.getDouble(Config.sensitivityKey);
  double? ballSize = prefs.getDouble(Config.ballSizeKey);
  runApp(BallToss(
    sensitivity: sensitivity ?? 5,
    ballSize: ballSize ?? 40,
  ));
}

class BallToss extends StatelessWidget {
  final double sensitivity;
  final double ballSize;
  const BallToss({
    Key? key,
    required this.sensitivity,
    required this.ballSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ball Toss',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
        appBarTheme: AppBarTheme(
          color: Colors.grey[900],
        ), //Colors.blue[900]),
        dialogTheme: const DialogTheme(
          backgroundColor: Color.fromRGBO(33, 33, 33, 1),
          titleTextStyle: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        canvasColor: Colors.grey[900],
        fontFamily: 'Roboto',
      ),
      home: HomePage(
        sensitivity: sensitivity,
        ballSize: ballSize,
      ),
    );
  }
}
