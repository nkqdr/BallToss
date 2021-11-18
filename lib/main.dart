import 'dart:async';
import 'package:esense_flutter/esense.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const BallToss());
}

class BallToss extends StatelessWidget {
  const BallToss({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ball Toss',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          color: Colors.grey[900],
        ), //Colors.blue[900]),
        canvasColor: Colors.grey[900],
        fontFamily: 'Roboto',
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final double _ballSize = 40;
  final Color _ballColor = Colors.blue;
  final double _sensitivity = 5.0;
  final double _movementThreshhold = 150.0;
  int _currentScore = 0;
  List<int> _startGyro = [];
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
  String eSenseName = 'eSense-0151';

  @override
  void initState() {
    super.initState();
    _setUpESense();
  }

  Future _setUpESense() async {
    await _listenToESense();
    await _connectToESense();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fieldSize = MediaQuery.of(context).size.width - 30;
    _centerX = (_fieldSize / 2);
    _centerY = (_fieldSize / 2);
    print(_centerX);
    print(_centerY);
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
            print('Here');
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
        print("Setting");
        _startGyro = event.gyro!;
      }
      setNewPosition(event, event.gyro!);
    });
    setState(() {
      sampling = true;
    });
  }

  void setNewPosition(SensorEvent event, List<int> newData) {
    if (abs(newData[0] - _startGyro[0]) < _movementThreshhold) {
      print("no Change");
      return;
    }
    if (newData[0] > _startGyro[0]) {
      print("Right");
    } else if (newData[0] < _startGyro[0]) {
      print("Left");
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
    if (0 <= _ballX + _ballY && _ballX + _ballY <= 150) {
      print("Hit blue!");
    } else if (0 <= _ballX + (300 - _ballY) && _ballX + (300 - _ballY) <= 150) {
      print("Hit yellow!");
    } else if (0 <= (300 - _ballX) + _ballY && (300 - _ballX) + _ballY <= 150) {
      print("Hit green!");
    } else if (0 <= (300 - _ballX) + (300 - _ballY) &&
        (300 - _ballX) + (300 - _ballY) <= 150) {
      print("Hit red!");
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
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
          child: ListView(
            children: [
              Text(
                'eSense Device Status: \t$_deviceStatus',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                'eSense Device Name: \t$_deviceName',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                'eSense Battery Level: \t$_voltage',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                'eSense Button Event: \t$_button',
                style: const TextStyle(color: Colors.white),
              ),
              const Text(''),
              Text(
                _event,
                style: const TextStyle(color: Colors.white),
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
                color: Colors.white,
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

  int abs(int value) {
    return value < 0 ? -value : value;
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
