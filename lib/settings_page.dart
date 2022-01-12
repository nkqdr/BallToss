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
  late String _esenseName;
  late TextEditingController _controller;
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
    _esenseName = prefs.getString(Config.eSenseKey) ?? "eSense-0569";
    _currentBallSize = prefs.getDouble(Config.ballSizeKey) ?? 40;
    _controller = TextEditingController(text: _esenseName);
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
                      Center(
                        child: TextButton(
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
                        ),
                      ),
                      const Text(
                        "Name of the eSense device:",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TextField(
                            autocorrect: false,
                            controller: _controller,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[900], //.withOpacity(0.2),
                              hintText: 'Enter the name of your eSense device.',
                              border: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _handleSaveEsenseName,
                            child: const Text(
                              "Save",
                              style: TextStyle(
                                color: Colors.blue,
                              ),
                            ),
                            style: ButtonStyle(
                                overlayColor: MaterialStateProperty.all(
                              Colors.blue.withOpacity(0.1),
                            )),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
      ),
    );
  }

  Future _handleSaveEsenseName() async {
    var prefs = await SharedPreferences.getInstance();
    prefs.setString(Config.eSenseKey, _controller.text);
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Center(child: Text("Success")),
            titleTextStyle: Theme.of(context)
                .dialogTheme
                .titleTextStyle
                ?.copyWith(color: Colors.white),
            content: const Text("The new name has been saved successfully."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Ok!'),
              )
            ],
          );
        });
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
