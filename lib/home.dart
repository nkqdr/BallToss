import 'package:ball_toss/config.dart';
import 'package:flutter/material.dart';
import 'package:ball_toss/settings_page.dart';
import 'package:esense_flutter/esense.dart';
import 'dart:async';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  final double sensitivity;
  final double ballSize;
  const HomePage({
    Key? key,
    required this.sensitivity,
    required this.ballSize,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

final List<Color> colors = [
  Colors.blue,
  Colors.green,
  Colors.yellow,
  Colors.red
];

class _HomePageState extends State<HomePage> {
  final Duration _immutableDuration = const Duration(milliseconds: 500);
  final double _movementThreshhold = 150.0;
  late double _ballSize;
  late double _sensitivity;
  late int _highScore;
  Color _ballColor = Colors.blue;
  int _currentScore = 0;
  List<int> _startGyro = [];
  bool _isImmutable = false;
  //bool _isGameOver = false;
  late double _centerX;
  late double _centerY;
  late double _ballX;
  late double _ballY;
  late double _fieldSize;

  String _deviceName = 'Unknown';
  double _voltage = -1;
  String _deviceStatus = '';
  bool sampling = false;
  String _event = '';
  String _button = 'not pressed';
  bool connected = false;
  String eSenseName = 'eSense-0569';

  @override
  void initState() {
    super.initState();
    _sensitivity = widget.sensitivity;
    _ballSize = widget.ballSize;
    _setUpESense();
  }

  Future _setUpESense() async {
    await _listenToESense();
    await _connectToESense();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var highScore = prefs.getInt(Config.highScoreKey);
    setState(() => _highScore = highScore ?? 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fieldSize = MediaQuery.of(context).size.width - 30;
    _centerX = (_fieldSize / 2);
    _centerY = (_fieldSize / 2);
    _ballX = _centerX;
    _ballY = _centerY;
  }

  Future _listenToESense() async {
    // if you want to get the connection events when connecting,
    // set up the listener BEFORE connecting...
    ESenseManager().connectionEvents.listen((event) {
      print('CONNECTION event: $event');

      // when we're connected to the eSense device, we can start listening to events from it
      if (event.type == ConnectionType.connected) _listenToESenseEvents();

      setState(() {
        connected = false;
        switch (event.type) {
          case ConnectionType.connected:
            _deviceStatus = 'connected';
            connected = true;
            break;
          case ConnectionType.unknown:
            _deviceStatus = 'unknown';
            break;
          case ConnectionType.disconnected:
            _deviceStatus = 'disconnected';
            break;
          case ConnectionType.device_found:
            _deviceStatus = 'device_found';
            break;
          case ConnectionType.device_not_found:
            _deviceStatus = 'device_not_found';
            break;
        }
      });
    });
  }

  Future _connectToESense() async {
    print('connecting... connected: $connected');
    if (!connected) connected = await ESenseManager().connect(eSenseName);

    setState(() {
      _deviceStatus = connected ? 'connecting' : 'connection failed';
    });
  }

  void _listenToESenseEvents() async {
    ESenseManager().eSenseEvents.listen((event) {
      print('ESENSE event: $event');

      setState(() {
        switch (event.runtimeType) {
          case DeviceNameRead:
            _deviceName = (event as DeviceNameRead).deviceName ?? 'Unknown';
            break;
          case BatteryRead:
            _voltage = (event as BatteryRead).voltage ?? -1;
            break;
          case ButtonEventChanged:
            _button = (event as ButtonEventChanged).pressed
                ? 'pressed'
                : 'not pressed';
            break;
          case AccelerometerOffsetRead:
            break;
          case AdvertisementAndConnectionIntervalRead:
            // TODO
            break;
          case SensorConfigRead:
            // TODO
            break;
        }
      });
    });

    _getESenseProperties();
  }

  void _getESenseProperties() async {
    // get the battery level every 10 secs
    Timer.periodic(
      const Duration(seconds: 10),
      (timer) async =>
          (connected) ? await ESenseManager().getBatteryVoltage() : null,
    );

    // wait 2, 3, 4, 5, ... secs before getting the name, offset, etc.
    // it seems like the eSense BTLE interface does NOT like to get called
    // several times in a row -- hence, delays are added in the following calls
    Timer(const Duration(seconds: 2),
        () async => await ESenseManager().getDeviceName());
    Timer(const Duration(seconds: 3),
        () async => await ESenseManager().getAccelerometerOffset());
    Timer(
        const Duration(seconds: 4),
        () async =>
            await ESenseManager().getAdvertisementAndConnectionInterval());
    Timer(const Duration(seconds: 5),
        () async => await ESenseManager().getSensorConfig());
  }

  StreamSubscription? subscription;
  void _startListenToSensorEvents() async {
    bool set = false;
    // subscribe to sensor event from the eSense device
    subscription = ESenseManager().sensorEvents.listen((event) {
      if (!set) {
        set = true;
        _startGyro = event.gyro!;
      }
      setNewPosition(event, event.gyro!);
    });
    setState(() {
      sampling = true;
    });
  }

  Future _setImmutable(Duration duration) async {
    setState(() => _isImmutable = true);
    await Future.delayed(duration);
    setState(() => _isImmutable = false);
  }

  void setNewPosition(SensorEvent event, List<int> newData) {
    if (abs(newData[0] - _startGyro[0]) < _movementThreshhold) {
      return;
    }
    setState(() {
      _event = event.toString();
      _ballX = _centerX +
          (newData[0] - _startGyro[0]).toDouble() / (100 / _sensitivity);
      _ballY = _centerY +
          (newData[2] - _startGyro[2]).toDouble() / (100 / _sensitivity);
    });
    _checkHit();
  }

  void _checkHit() {
    if (_isImmutable) {
      return;
    }
    if (0 <= _ballX + _ballY && _ballX + _ballY <= _centerX) {
      _handleHit(Colors.blue);
    } else if (0 <= _ballX + (_fieldSize - _ballY) &&
        _ballX + (_fieldSize - _ballY) <= _centerX) {
      _handleHit(Colors.yellow);
    } else if (0 <= (_fieldSize - _ballX) + _ballY &&
        (_fieldSize - _ballX) + _ballY <= _centerX) {
      _handleHit(Colors.green);
    } else if (0 <= (_fieldSize - _ballX) + (_fieldSize - _ballY) &&
        (_fieldSize - _ballX) + (_fieldSize - _ballY) <= _centerX) {
      _handleHit(Colors.red);
    }
  }

  void _handleHit(Color color) {
    if (_ballColor == color) {
      setState(() => _currentScore++);
      _setImmutable(_immutableDuration);
      setState(() => _ballColor = _getRandomColor());
    } else {
      _pauseListenToSensorEvents();
      _showGameOverDialog();
    }
  }

  void _pauseListenToSensorEvents() async {
    subscription?.cancel();
    setState(() {
      sampling = false;
    });
  }

  @override
  void dispose() {
    _pauseListenToSensorEvents();
    ESenseManager().disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ball Toss'),
      ),
      drawer: Drawer(
        child: Padding(
          padding: EdgeInsets.only(
            left: 15.0,
            right: 15.0,
            top: MediaQuery.of(context).viewPadding.top + 10,
            bottom: MediaQuery.of(context).viewPadding.bottom + 10,
          ),
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.black26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'eSense data:',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text('eSense Device Status: \t$_deviceStatus'),
                    Text('eSense Device Name: \t$_deviceName'),
                    Text('eSense Battery Level: \t$_voltage'),
                    Text('eSense Button Event: \t$_button'),
                  ],
                ),
              ),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                tileColor: Colors.black26,
                title: const Text("Settings"),
                onTap: () async {
                  Navigator.of(context).pop();
                  await Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => const SettingsPage()));
                  var prefs = await SharedPreferences.getInstance();
                  setState(() {
                    _sensitivity = prefs.getDouble(Config.sensitivityKey) ?? 5;
                    _ballSize = prefs.getDouble(Config.ballSizeKey) ?? 40;
                    _highScore = prefs.getInt(Config.highScoreKey) ?? 0;
                  });
                },
              ),
              Expanded(
                child: Align(
                  alignment: FractionalOffset.bottomCenter,
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: const Text("Made by Niklas Kuder"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              'Score: $_currentScore',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Stack(
              children: [
                CustomPaint(
                  size: Size(_fieldSize, _fieldSize),
                  painter: FieldPainter(),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 100),
                  left: _ballX - (_ballSize / 2),
                  top: _ballY - (_ballSize / 2),
                  child: Container(
                    width: _ballSize,
                    height: _ballSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _ballColor,
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        // a floating button that starts/stops listening to sensor events.
        // is disabled until we're connected to the device.
        onPressed: (!ESenseManager().connected)
            ? null
            : (!sampling)
                ? _startListenToSensorEvents
                : _pauseListenToSensorEvents,
        tooltip: 'Listen to eSense sensors',
        backgroundColor: Colors.blue[900],
        child: (!sampling)
            ? const Icon(Icons.play_arrow)
            : const Icon(Icons.pause),
      ),
    );
  }

  Future _showGameOverDialog() async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Center(child: Text('Game Over')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Score: $_currentScore'),
                Text('High-Score: $_highScore'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Try again!'),
              )
            ],
          );
        });
    if (_currentScore > _highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(Config.highScoreKey, _currentScore);
      setState(() => _highScore = _currentScore);
    }
    _resetGame();
  }

  int abs(int value) {
    return value < 0 ? -value : value;
  }

  Color _getRandomColor() {
    var rng = Random();
    Color color;
    do {
      color = colors[rng.nextInt(4)];
    } while (color == _ballColor);
    return color;
  }

  void _resetGame() {
    print("Reset");
    setState(() {
      _ballX = _centerX;
      _ballY = _centerY;
      _currentScore = 0;
    });
  }
}

class FieldPainter extends CustomPainter {
  final double _lineWidth = 10;

  @override
  void paint(Canvas canvas, Size size) {
    Offset centerLeft = Offset(0, size.height / 2);
    Offset centerTop = Offset(size.width / 2, 0);
    Offset centerRight = Offset(size.width, size.height / 2);
    Offset centerBottom = Offset(size.width / 2, size.height);
    var customPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = _lineWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(centerLeft, centerTop, customPaint);
    canvas.drawLine(centerTop, centerRight, customPaint..color = Colors.green);
    canvas.drawLine(centerRight, centerBottom, customPaint..color = Colors.red);
    canvas.drawLine(
        centerBottom, centerLeft, customPaint..color = Colors.yellow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
