import 'package:ball_toss/config.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late double _currentSensitivity;
  late double _currentBallSize;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _initSettings();
  }

  Future _initSettings() async {
    setState(() => isLoading = true);
    var prefs = await SharedPreferences.getInstance();
    _currentSensitivity = prefs.getDouble(Config.sensitivityKey) ?? 5;
    _currentBallSize = prefs.getDouble(Config.ballSizeKey) ?? 40;
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          splashRadius: 18,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: ListView(
        children: isLoading
            ? ([
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10),
                  child: CircularProgressIndicator.adaptive(),
                ),
              ])
            : [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Sensitivity",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Slider(
                        value: _currentSensitivity,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: _currentSensitivity.round().toString(),
                        onChanged: _handleChangeSensitivity,
                      ),
                      const Text(
                        "Ball Size",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Slider(
                        value: _currentBallSize,
                        min: 10,
                        max: 80,
                        divisions: 7,
                        label: (_currentBallSize / 10).round().toString(),
                        onChanged: _handleChangeBallSize,
                      ),
                      TextButton(
                        onPressed: _handleResetHighScore,
                        child: const Text(
                          "Reset High-Score",
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                        style: ButtonStyle(
                            overlayColor: MaterialStateProperty.all(
                          Colors.red.withOpacity(0.1),
                        )),
                      )
                    ],
                  ),
                ),
              ],
      ),
    );
  }

  Future _handleResetHighScore() async {
    var prefs = await SharedPreferences.getInstance();
    prefs.setInt(Config.highScoreKey, 0);
  }

  Future _handleChangeBallSize(double value) async {
    setState(() {
      _currentBallSize = value;
    });
    var prefs = await SharedPreferences.getInstance();
    prefs.setDouble(Config.ballSizeKey, value);
  }

  Future _handleChangeSensitivity(double value) async {
    setState(() {
      _currentSensitivity = value;
    });
    var prefs = await SharedPreferences.getInstance();
    prefs.setDouble(Config.sensitivityKey, value);
  }
}
