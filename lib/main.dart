import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show CircularProgressIndicator, FloatingActionButton, Icons;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:network_info_plus/network_info_plus.dart';

abstract class Theme {
  Iterable<int> newGame({Set<int> exclude});

  Widget buildCard(int value);

  int get length;
}

class RandomizedIterable extends Object with Iterable<int> {
  RandomizedIterable(this.length);

  @override
  final int length;

  @override
  Iterator<int> get iterator => RandomizedIterator(length);
}

class RandomizedIterator implements Iterator<int> {
  RandomizedIterator(this.length);

  final int length;
  final Set<int> _usedIndexes = <int>{};
  final Random _random = Random(DateTime.now().microsecondsSinceEpoch);

  bool _currentNeedsCalculating = false;
  int _current = -1;

  @override
  int get current {
    if (_currentNeedsCalculating) {
      do {
        _current = _random.nextInt(length);
      } while (_usedIndexes.contains(_current));
      _usedIndexes.add(_current);
      _currentNeedsCalculating = false;
    } else if (_current == -1) {
      throw StateError('moveNext() has not yet been called');
    }
    return _current;
  }

  @override
  bool moveNext() {
    _currentNeedsCalculating = true;
    return _usedIndexes.length < length;
  }
}

class ClassicTheme implements Theme {
  const ClassicTheme();

  static const List<String> _population = <String>[
    'Africa', 'Agent', 'Air', 'Alien', 'Alps', 'Amazon', 'Ambulance', 'America',
    'Angel', 'Antarctica', 'Apple', 'Arm', 'Atlantis', 'Australia', 'Aztec', 'Back',
    'Ball', 'Band', 'Bank', 'Bar', 'Bark', 'Bat', 'Battery', 'Beach', 'Bear',
    'Beat', 'Bed', 'Beijing', 'Bell', 'Belt', 'Berlin', 'Bermuda', 'Berry', 'Bill',
    'Block', 'Board', 'Bolt', 'Bomb', 'Bond', 'Boom', 'Boot', 'Bottle', 'Bow',
    'Box', 'Bridge', 'Brush', 'Buck', 'Buffalo', 'Bug', 'Bugle', 'Button', 'Calf',
    'Canada', 'Cap', 'Capital', 'Car', 'Card', 'Carrot', 'Casino', 'Cast', 'Cat',
    'Cell', 'Centaur', 'Center', 'Chair', 'Change', 'Charge', 'Check', 'Chest',
    'Chick', 'China', 'Chocolate', 'Church', 'Circle', 'Cliff', 'Cloak', 'Club',
    'Code', 'Cold', 'Comic', 'Compound', 'Concert', 'Conductor', 'Contract', 'Cook',
    'Copper', 'Cotton', 'Court', 'Cover', 'Crane', 'Crash', 'Cricket', 'Cross',
    'Crown', 'Cycle', 'Czech', 'Dance', 'Date', 'Day', 'Death', 'Deck', 'Degree',
    'Diamond', 'Dice', 'Dinosaur', 'Disease', 'Doctor', 'Dog', 'Draft', 'Dragon',
    'Dress', 'Drill', 'Drop', 'Duck', 'Dwarf', 'Eagle', 'Egypt', 'Embassy',
    'Engine', 'England', 'Europe', 'Eye', 'Face', 'Fair', 'Fall', 'Fan', 'Fence',
    'Field', 'Fighter', 'Figure', 'File', 'Film', 'Fire', 'Fish', 'Flute', 'Fly',
    'Foot', 'Force', 'Forest', 'Fork', 'France', 'Game', 'Gas', 'Genius', 'Germany',
    'Ghost', 'Giant', 'Glass', 'Glove', 'Gold', 'Grace', 'Grass', 'Greece', 'Green',
    'Ground', 'Ham', 'Hand', 'Hawk', 'Head', 'Heart', 'Helicopter', 'Himalayas',
    'Hole', 'Hollywood', 'Honey', 'Hood', 'Hook', 'Horn', 'Horse', 'Horseshoe',
    'Hospital', 'Hotel', 'Ice', 'Ice cream', 'India', 'Iron', 'Ivory', 'Jack',
    'Jam', 'Jet', 'Jupiter', 'Kangaroo', 'Ketchup', 'Key', 'Kid', 'King', 'Kiwi',
    'Knife', 'Knight', 'Lab', 'Lap', 'Laser', 'Lawyer', 'Lead', 'Lemon',
    'Leprechaun', 'Life', 'Light', 'Limousine', 'Line', 'Link', 'Lion', 'Litter',
    'Loch ness', 'Lock', 'Log', 'London', 'Luck', 'Mail', 'Mammoth', 'Maple',
    'Marble', 'March', 'Mass', 'Match', 'Mercury', 'Mexico', 'Microscope',
    'Millionaire', 'Mine', 'Mint', 'Missile', 'Model', 'Mole', 'Moon', 'Moscow',
    'Mount', 'Mouse', 'Mouth', 'Mug', 'Nail', 'Needle', 'Net', 'New york', 'Night',
    'Ninja', 'Note', 'Novel', 'Nurse', 'Nut', 'Octopus', 'Oil', 'Olive', 'Olympus',
    'Opera', 'Orange', 'Organ', 'Palm', 'Pan', 'Pants', 'Paper', 'Parachute',
    'Park', 'Part', 'Pass', 'Paste', 'Penguin', 'Phoenix', 'Piano', 'Pie', 'Pilot',
    'Pin', 'Pipe', 'Pirate', 'Pistol', 'Pit', 'Pitch', 'Plane', 'Plastic', 'Plate',
    'Platypus', 'Play', 'Plot', 'Point', 'Poison', 'Pole', 'Police', 'Pool', 'Port',
    'Post', 'Pound', 'Press', 'Princess', 'Pumpkin', 'Pupil', 'Pyramid', 'Queen',
    'Rabbit', 'Racket', 'Ray', 'Revolution', 'Ring', 'Robin', 'Robot', 'Rock',
    'Rome', 'Root', 'Rose', 'Roulette', 'Round', 'Row', 'Ruler', 'Satellite',
    'Saturn', 'Scale', 'School', 'Scientist', 'Scorpion', 'Screen', 'Scuba diver',
    'Seal', 'Server', 'Shadow', 'Shakespeare', 'Shark', 'Ship', 'Shoe', 'Shop',
    'Shot', 'Sink', 'Skyscraper', 'Slip', 'Slug', 'Smuggler', 'Snow', 'Snowman',
    'Sock', 'Soldier', 'Soul', 'Sound', 'Space', 'Spell', 'Spider', 'Spike',
    'Spine', 'Spot', 'Spring', 'Spy', 'Square', 'Stadium', 'Staff', 'Star', 'State',
    'Stick', 'Stock', 'Straw', 'Stream', 'Strike', 'String', 'Sub', 'Suit',
    'Superhero', 'Swing', 'Switch', 'Table', 'Tablet', 'Tag', 'Tail', 'Tap',
    'Teacher', 'Telescope', 'Temple', 'Theater', 'Thief', 'Thumb', 'Tick', 'Tie',
    'Time', 'Tokyo', 'Tooth', 'Torch', 'Tower', 'Track', 'Train', 'Triangle',
    'Trip', 'Trunk', 'Tube', 'Turkey', 'Undertaker', 'Unicorn', 'Vacuum', 'Van',
    'Vet', 'Wake', 'Wall', 'War', 'Washer', 'Washington', 'Watch', 'Water', 'Wave',
    'Web', 'Well', 'Whale', 'Whip', 'Wind', 'Witch', 'Worm', 'Yard',
  ];

  @override
  Iterable<int> newGame({Set<int> exclude = const <int>{}}) {
    final Set<int> excludeCopy = Set<int>.from(exclude);
    return RandomizedIterable(_population.length).where((int value) {
      return !excludeCopy.contains(value);
    }).take(Board.size);
  }

  @override
  Widget buildCard(int value) {
    return ColoredBox(
      color: const Color(0xfffff8ef),
      child: Center(
        child: Text(_population[value]),
      ),
    );
  }

  @override
  int get length => _population.length;
}

enum MessageType {
  newAppInstance,
  syncAppState,
}

sealed class Message {
  const Message(this.messageType);

  final MessageType messageType;

  static const String _keyMessageType = 'type';
  static const String _keyPayload = 'payload';

  Object? toJson();
  void receive();

  @nonVirtual
  List<int> serialize() {
    final Map<String, dynamic> envelope = <String, dynamic>{
      _keyMessageType: messageType.index,
      _keyPayload: toJson(),
    };
    return utf8.encode(json.encode(envelope));
  }

  static Message deserialize(List<int> serialized) {
    final Map<String, dynamic> envelope = json.decode(utf8.decode(serialized));
    final MessageType type = MessageType.values[envelope[_keyMessageType]];
    switch (type) {
      case MessageType.newAppInstance:
        return NewAppInstanceMessage(envelope[_keyPayload]);
      case MessageType.syncAppState:
        return SyncAppStateMessage.fromJson(envelope[_keyPayload]);
    }
  }
}

class NewAppInstanceMessage extends Message {
  const NewAppInstanceMessage(this.ip) : super(MessageType.newAppInstance);

  final String ip;

  @override
  Object? toJson() => ip;

  @override
  Future<void> receive() async {
    final LocalClient localClient = NetworkBinding.instance.localClient;
    debugPrint('New app instance spawned at $ip; connecting to remote server');
    await localClient.connectToServer(ip);
    await GameBinding.instance.boardController?.sync(ip);
  }
}

class SyncAppStateMessage extends Message {
  const SyncAppStateMessage(this.results, this.values, this.usedValues) : super(MessageType.syncAppState);

  final Map<Coordinates, Result> results;
  final Map<Coordinates, int> values;
  final Set<int> usedValues;

  static const String _keyResults = 'result';
  static const String _keyValues = 'values';
  static const String _keyUsed = 'used';

  factory SyncAppStateMessage.fromJson(Map<String, dynamic> payload) {
    final Map<Coordinates, Result> results = payload[_keyResults]!.map<Coordinates, Result>((String key, dynamic value) {
      final List<String> parts = key.split(',');
      final Coordinates coordinates = (int.parse(parts[0]), int.parse(parts[1]));
      final Result result;
      switch (value) {
        case 'unknown':
          result = const Unknown();
          break;
        case 'neutral':
          result = const Neutral();
          break;
        case 'death':
          result = const Death();
          break;
        case 'red':
          result = const Red();
          break;
        case 'blue':
          result = const Blue();
          break;
        default:
          throw ArgumentError();
      }
      return MapEntry<Coordinates, Result>(coordinates, result);
    });
    final Map<Coordinates, int> values = payload[_keyValues]!.map<Coordinates, int>((String key, dynamic value) {
      final List<String> parts = key.split(',');
      final Coordinates coordinates = (int.parse(parts[0]), int.parse(parts[1]));
      return MapEntry<Coordinates, int>(coordinates, value);
    });
    final Set<int> usedValues = Set<int>.from(payload[_keyUsed]);
    return SyncAppStateMessage(results, values, usedValues);
  }

  @override
  Object toJson() {
    Map<String, dynamic> data = <String, dynamic>{
      _keyResults: results.map<String, String>((Coordinates key, Result value) {
        return MapEntry<String, String>('${key.$1},${key.$2}', value.toJson());
      }),
      _keyValues: values.map<String, int>((Coordinates key, int value) {
        return MapEntry<String, int>('${key.$1},${key.$2}', value);
      }),
      _keyUsed: usedValues.toList(),
    };
    return data;
  }
  
  @override
  void receive() {
    NetworkBinding.instance.onRemoteSync?.call(this);
  }
}

class Server {
  Server({
    required this.ip,
  });

  final String ip;
  final Map<String, RemoteClient> _remoteClients = <String, RemoteClient>{};
  ServerSocket? _socket;
  StreamSubscription<Socket>? _remoteClientListener;

  static const port = 26952;

  AppDataCallback? onRemoteSync;

  Future<void> start() async {
    if (_socket == null) {
      assert(_remoteClientListener == null);
      final ServerSocket socket = await ServerSocket.bind(ip, port);
      _socket = socket;
      _remoteClientListener = socket.listen(_handleNewRemoteClient, onError: _handleError);
      debugPrint('Server listening on $ip:$port');
    }
  }

  Future<void> stop() async {
    if (_socket != null) {
      assert(_remoteClientListener != null);
      await _remoteClientListener!.cancel();
      _remoteClientListener = null;
      await _socket!.close();
      _socket = null;
      for (final RemoteClient client in _remoteClients.values) {
        await client.dispose();
      }
      _remoteClients.clear();
    }
  }

  void _handleNewRemoteClient(Socket socket) async {
    final String ip = socket.remoteAddress.address;
    debugPrint('Received remote client at $ip:${socket.remotePort}');

    RemoteClient? remoteClient = _remoteClients[ip];
    if (remoteClient != null) {
      debugPrint('Remote client already existed at $ip; disposing...');
      await remoteClient.dispose();
    }
    remoteClient = _remoteClients[ip] = RemoteClient(socket);
    debugPrint('Accepted remote client at $ip:${socket.remotePort}');
  }

  void _handleError(Object error, StackTrace stack) {
    debugPrint('$error\n$stack');
    if (error is SocketException) {
      debugPrint('error is SocketException - message is ${error.osError?.message}');
      String? message = error.osError?.message;
      if (message != null && message.contains('reset by peer')) {
        final RegExp regexp = RegExp(r'address = ([0-9].)+');
        if (regexp.hasMatch(message)) {
          final String remoteAddress = regexp.firstMatch(message)!.group(1)!;
          assert(_remoteClients.containsKey(remoteAddress));
          debugPrint('Remote client $remoteAddress closed by remote');
          final RemoteClient remoteClient = _remoteClients[remoteAddress]!;
          remoteClient.dispose();
          _remoteClients.remove(remoteAddress);
        }
      }
    }
  }
}

class RemoteClient {
  RemoteClient(this._socket) {
    _subscription = _socket.cast<List<int>>().listen(_handleData);
  }

  final Socket _socket;
  late final StreamSubscription<Object?> _subscription;

  void _handleData(List<int> data) {
    final Message message = Message.deserialize(data);
    message.receive();
  }

  InternetAddress get address => _socket.remoteAddress;

  Future<void> dispose() async {
    await _subscription.cancel();
    await _socket.close();
    _socket.destroy();
  }
}

class LocalClient {
  LocalClient();

  final Map<String, Socket> _remoteServers = <String, Socket>{};

  static const Duration connectionTimeout = Duration(seconds: 3);

  bool isConnectedToServer(String ip) => _remoteServers.containsKey(ip);

  Future<bool> connectToServer(String ip) async {
    if (isConnectedToServer(ip)) {
      final Socket socket = _remoteServers[ip]!;
      socket.destroy();
      _remoteServers.remove(ip);
    }

    final ConnectionTask<Socket> task = await Socket.startConnect(ip, Server.port);
    try {
      final Socket socket = await task.socket.timeout(connectionTimeout);
      debugPrint('Local client connected to ${socket.remoteAddress.address}:${socket.remotePort}');
      _remoteServers[ip] = socket;
      return true;
    } on TimeoutException {
      // There's likely no device at this address.
      task.cancel();
      return false;
    } on SocketException {
      // There's likely a device at this address, but it's not listening.
      return false;
    } catch (error) {
      debugPrint('Error while trying to connect to $ip: $error');
      return false;
    }
  }

  Future<void> sendMessage(String ip, Message message) async {
    final List<int> bytes = message.serialize();
    _remoteServers[ip]?.add(bytes);
  }

  Future<void> broadcastMessage(Message message) async {
    final List<int> bytes = message.serialize();
    for (final Socket server in _remoteServers.values) {
      server.add(bytes);
    }
  }
}

typedef AppDataCallback = void Function(SyncAppStateMessage message);

mixin GameBinding on AppBindingBase {
  /// The singleton instance of this object.
  static late GameBinding _instance;
  static GameBinding get instance => _instance;

  BoardController? boardController;

  @override
  @protected
  @mustCallSuper
  Future<void> initInstances() async {
    await super.initInstances();
    _instance = this;
  }
}

mixin NetworkBinding on AppBindingBase {
  /// The singleton instance of this object.
  static late NetworkBinding _instance;
  static NetworkBinding get instance => _instance;

  late String _ip;
  String get ip => _ip;

  late String _subnetMask;
  String get subnetMask => _subnetMask;

  late Server _localServer;
  Server get localServer => _localServer;

  late LocalClient _localClient;
  LocalClient get localClient => _localClient;

  late LocalNetwork _localNetwork;
  LocalNetwork get localNetwork => _localNetwork;

  AppDataCallback? get onRemoteSync => localServer.onRemoteSync;
  set onRemoteSync(AppDataCallback? callback) {
    localServer.onRemoteSync = callback;
  }

  @override
  @protected
  @mustCallSuper
  Future<void> initInstances() async {
    await super.initInstances();
    _instance = this;

    final NetworkInfo net = NetworkInfo();
    _ip = (await net.getWifiIP()) ?? '192.168.86.34';
    _subnetMask = (await net.getWifiSubmask()) ?? '255.255.255.0';
    if (_subnetMask.isEmpty) _subnetMask = '255.255.255.0'; // TODO: this is a hack

    _localServer = Server(ip: ip);
    _localClient = LocalClient();
    await localServer.start();

    _localNetwork = LocalNetwork(ip, subnetMask);
    debugPrint('Local network is deviceIp="$ip", subnetMask="$subnetMask"');
    final Iterable<Ip> networkIps = localNetwork.getPossibleDeviceAddresses();
    final Iterable<Future<void>> connectionFutures = networkIps.map<Future<void>>((Ip networkIp) {
      if (networkIp == _localNetwork.deviceIp) {
        // Don't connect back to localhost.
        return Future<void>.value();
      }
      return localClient.connectToServer(networkIp.displayValue).then<void>((bool isConnected) {
        if (isConnected) {
          debugPrint('connected to remote server at ${networkIp.displayValue}');
        }
      });
    });
    await Future.wait(connectionFutures);

    await localClient.broadcastMessage(NewAppInstanceMessage(ip));
  }
}

class AppBinding extends AppBindingBase with NetworkBinding, GameBinding {
  /// Creates and initializes the application binding if necessary.
  ///
  /// Applications should call this method before calling [runApp].
  static Future<void> ensureInitialized() async {
    await AppBinding().initialized;
  }
}

abstract class AppBindingBase {
  /// Default abstract constructor for application bindings.
  ///
  /// First calls [initInstances] to have bindings initialize their
  /// instance pointers and other state.
  AppBindingBase() {
    developer.Timeline.startSync('App initialization');

    assert(!_debugInitialized);
    _initialized = initInstances();
    assert(_debugInitialized);

    developer.postEvent('Photos.AppInitialization', <String, String>{});
    developer.Timeline.finishSync();
  }

  static bool _debugInitialized = false;

  /// A future that completes once this app binding has been fully initialized.
  late Future<void> _initialized;
  Future<void> get initialized => _initialized;

  /// The initialization method. Subclasses override this method to hook into
  /// the app. Subclasses must call `super.initInstances()`.
  ///
  /// By convention, if the service is to be provided as a singleton, it should
  /// be exposed as `MixinClassName.instance`, a static getter that returns
  /// `MixinClassName._instance`, a static field that is set by
  /// `initInstances()`.
  @protected
  @mustCallSuper
  Future<void> initInstances() async {
    assert(!_debugInitialized);
    assert(() {
      _debugInitialized = true;
      return true;
    }());
    // This lives here instead of in `AppBinding.ensureInitialized()` to ensure
    // that the widgets binding is initialized before subclass implementations
    // of `initInstances()` (which may rely on things like `ServicesBinding`).
    WidgetsFlutterBinding.ensureInitialized();
  }

  @override
  String toString() => '<${objectRuntimeType(this, 'AppBindingBase')}>';
}

void main() {
  runZonedGuarded<void>(
    () async {
      runApp(const LoadingScreen());
      await AppBinding.ensureInitialized();
      runApp(const CodeWordApp());
    },
    (Object error, StackTrace stack) {
      debugPrint('Caught unhandled error by zone error handler.');
      debugPrint('$error\n$stack');
    },
  );
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: ColoredBox(
        color: Color(0xffffffff),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class LocalNetwork {
  LocalNetwork(String deviceIp, String subnetMask) :
      deviceIp = Ip.fromDisplayValue(deviceIp),
      subnetMask = Ip.fromDisplayValue(subnetMask);

  final Ip deviceIp;
  final Ip subnetMask;

  Iterable<Ip> getPossibleDeviceAddresses() {
    final int subnetValue = subnetMask.value ^ 0xffffffff;
    final int pos = subnetValue.toRadixString(2).length;
    final Iterable<int> subnetValues = _getPossibleSubnetValuesRecur(subnetValue, pos);
    final int commonValue = deviceIp.value & subnetMask.value;
    return subnetValues.map<Ip>((int subnetValue) {
      return Ip.fromValue(commonValue | subnetValue);
    });
  }

  Iterable<int> _getPossibleSubnetValuesRecur(int subnetValue, int pos) {
    assert(pos >= 0);
    if (pos == 0) {
      return const <int>[0];
    }
    final Iterable<int> baseValues = _getPossibleSubnetValuesRecur(subnetValue, pos - 1);
    final int mask = (subnetValue >> (pos - 1)) & 0x1;
    if (mask > 0) {
      return baseValues.followedBy(baseValues.map<int>((int baseValue) {
        return (mask << (pos - 1)) | baseValue;
      }));
    } else {
      return baseValues;
    }
  }
}

class Ip {
  Ip.fromDisplayValue(this._displayValue);

  Ip.fromValue(this._value);

  String? _displayValue;
  String get displayValue {
    if (_displayValue == null) {
      assert(_value != null);
      List<int> parts = <int>[
        (_value! >> 24) & 0x000000ff,
        (_value! >> 16) & 0x000000ff,
        (_value! >> 8) & 0x000000ff,
        _value! & 0x000000ff,
      ];
      _debugAssertParts(parts);
      _displayValue = parts.map<String>((int part) => '$part').join('.');
    }
    return _displayValue!;
  }

  int? _value;
  int get value {
    if (_value == null) {
      assert(_displayValue != null);
      List<int> parts = _displayValue!
          .split('.')
          .map<int>((String chunk) => int.parse(chunk)).toList();
      _debugAssertParts(parts);
      _value = (parts[3] & 0x000000ff)
          | ((parts[2] << 8) & 0x0000ff00)
          | ((parts[1] << 16) & 0x00ff0000)
          | ((parts[0] << 24) & 0xff000000);
    }
    return _value!;
  }

  void _debugAssertParts(List<int> parts) {
    assert(parts.every((int part) => part >= 0 && part <= 255));
  }

  @override
  bool operator ==(Object other) {
    return other is Ip && value == other.value;
  }
  
  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Ip($displayValue)';
}

class CodeWordApp extends StatelessWidget {
  const CodeWordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'Codeword',
      color: const Color(0xffd25f4b),
      textStyle: DefaultTextStyle.of(context).style.copyWith(
        color: const Color(0xff000000),
        fontSize: 24,
      ),
      builder: (BuildContext context, Widget? widget) {
        return const SafeArea(
          child: Game(),
        );
      },
    );
  }
}

class Game extends StatefulWidget {
  const Game({super.key});

  @override
  State<Game> createState() => _GameState();

  static GameController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_GameScope>()!.state;
  }
}

abstract class GameController {
  Result getResult(Coordinates coordinates);
}

class _GameState extends State<Game> implements GameController {
  late final ResultMap _map;

  @override
  Result getResult(Coordinates coordinates) => _map[coordinates];

  @override
  void initState() {
    super.initState();
    _map = ResultMap();
  }

  @override
  Widget build(BuildContext context) {
    return _GameScope(
      state: this,
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: ColoredBox(
              color: Color(0xffffffff),
              child: Padding(
                padding: EdgeInsets.all(5),
                child: Board(),
              ),
            ),
          ),
          SizedBox(
            width: 75,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(width: 2)),
                color: Color(0xffffeedd),
              ),
              child: ActionBar(),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameScope extends InheritedWidget {
  const _GameScope({
    required super.child,
    required this.state,
  });

  final _GameState state;

  @override
  bool updateShouldNotify(_GameScope oldWidget) => false;
}

class ActionBar extends StatelessWidget {
  const ActionBar({super.key});

  void _handleNewGame() {
    final BoardController controller = GameBinding.instance.boardController!;
    controller.reset();
    controller.sync();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Focus(
            onFocusChange: (bool hasFocus) {debugPrint('button : $hasFocus');},
            child: FloatingActionButton(
              onPressed: _handleNewGame,
              child: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
    );
  }
}

class Board extends StatefulWidget {
  const Board({super.key, this.theme = const ClassicTheme()});

  final Theme theme;

  static const int xSize = 5;
  static const int ySize = 5;
  static const int size = xSize * ySize;

  @override
  State<Board> createState() => _BoardState();

  static BoardController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_BoardScope>()!.state;
  }
}

class _BoardState extends State<Board> implements BoardController {
  Coordinates? _coloring;
  final Map<Coordinates, GlobalKey<TileState>> _tiles = <Coordinates, GlobalKey<TileState>>{};
  final Map<Coordinates, Result> _results = <Coordinates, Result>{};
  final Map<Coordinates, int> _values = <Coordinates, int>{};
  final Set<int> _usedValues = <int>{};

  static const double borderRadius = 10;
  static const double padding = 5;

  Iterable<Widget> _getResultPopup() {
    Iterable<Widget> result = const Iterable<Widget>.empty();
    if (_coloring != null) {
      final GlobalKey<TileState> tile = _tiles[_coloring!]!;
      final RenderBox tileRenderBox = tile.currentContext!.findRenderObject() as RenderBox;
      final Offset tileGlobalOffset = tileRenderBox.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
      result = <Widget>[
        Positioned(
          left: tileGlobalOffset.dx,
          top: tileGlobalOffset.dy,
          child: Padding(
            padding: const EdgeInsets.all(padding),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: SizedBox(
                  width: tileRenderBox.size.width - 2 * padding,
                  height: tileRenderBox.size.height - 2 * padding,
                  child: FocusScope(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ResultPicker(autofocus: true, coordinates: _coloring!, result: const Death()),
                              ResultPicker(coordinates: _coloring!, result: const Neutral()),
                            ],
                          ),
                        ),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ResultPicker(coordinates: _coloring!, result: const Blue()),
                              ResultPicker(coordinates: _coloring!, result: const Red()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ];
    }
    return result;
  }

  void _cancelResultsPopup() {
    coloring = null;
  }

  void _handleRemoteSync(SyncAppStateMessage message) {
    assert(mounted);
    setState(() {
      _results.clear();
      _results.addAll(message.results);
      _values.clear();
      _values.addAll(message.values);
    });
  }

  @override
  set coloring(Coordinates? coordinates) {
    setState(() {
      _coloring = coordinates;
    });
  }
  
  @override
  set result(Result result) {
    assert(_coloring != null);
    setState(() {
      _results[_coloring!] = result;
      _coloring = null;
    });
    sync();
  }

  @override
  Future<void> sync([String? ip]) async {
    final Message message = SyncAppStateMessage(_results, _values, _usedValues);
    if (ip == null) {
      await NetworkBinding.instance.localClient.broadcastMessage(message);
    } else {
      await NetworkBinding.instance.localClient.sendMessage(ip, message);
    }
  }

  @override
  void reset() {
    setState(() {
      _results.clear();
      _values.clear();
      final Iterator<int> randomValues = widget.theme.newGame(exclude: _usedValues).iterator;
      for (int i = 0; i < Board.ySize; i++) {
        for (int j = 0; j < Board.xSize; j++) {
          final Coordinates coordinates = (i, j);
          _tiles[coordinates] ??= GlobalKey<TileState>(debugLabel: 'Tile$coordinates');
          randomValues.moveNext();
          _values[coordinates] = randomValues.current;
        }
      }
      _usedValues.addAll(_values.values);
      if (_usedValues.length + Board.size > widget.theme.length) {
        // We've used up all the cards
        _usedValues.clear();
      }
    });
  }

  @override
  void didUpdateWidget(covariant Board oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.theme != oldWidget.theme) {
      _usedValues.clear();
    }
  }

  @override
  void initState() {
    reset();
    NetworkBinding.instance.onRemoteSync = _handleRemoteSync;
    GameBinding.instance.boardController = this;
    super.initState();
  }

  @override
  void dispose() {
    GameBinding.instance.boardController = null;
    NetworkBinding.instance.onRemoteSync = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BoardScope(
      state: this,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          FocusScope(
            autofocus: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List<Widget>.generate(Board.ySize, (int i) {
                return Flexible(
                  flex: 1,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List<Widget>.generate(Board.xSize, (int j) {
                      final Coordinates coordinates = (i, j);
                      return Tile(
                        key: _tiles[coordinates],
                        theme: widget.theme,
                        coordinates: coordinates,
                        value: _values[coordinates]!,
                        result: _results[coordinates] ?? const Unknown(),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
          GestureDetector(
            onTap: _coloring == null ? null : _cancelResultsPopup,
          ),
          ... _getResultPopup(),
        ],
      ),
    );
  }
}

class ResultPicker extends StatelessWidget {
  const ResultPicker({
    super.key,
    this.autofocus = false,
    required this.coordinates,
    required this.result,
  });

  final bool autofocus;
  final Coordinates coordinates;
  final Result result;

  void _handleSelect(BuildContext context) {
    Board.of(context).result = result;
  }

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Focus(
        autofocus: autofocus,
        child: SizedBox.expand(
          child: GestureDetector(
            onTap: () => _handleSelect(context),
            child: result.build(),
          ),
        ),
      ),
    );
  }
}

abstract class BoardController {
  set coloring(Coordinates? coordinates);
  set result(Result result);
  Future<void> sync([String? ip]);
  void reset();
}

class _BoardScope extends InheritedWidget {
  const _BoardScope({
    required super.child,
    required this.state,
  });

  final _BoardState state;

  @override
  bool updateShouldNotify(_BoardScope oldWidget) => false;
}

class Tile extends StatefulWidget {
  const Tile({
    super.key,
    required this.theme,
    required this.coordinates,
    required this.value,
    this.result = const Unknown(),
  });

  final Theme theme;
  final Coordinates coordinates;
  final int value;
  final Result result;

  @override
  State<Tile> createState() => TileState();
}

class TileState extends State<Tile> {
  bool _hasFocus = false;

  void _chooseColor() {
    Board.of(context).coloring = widget.coordinates;
  }

  void _handleTap() {
    _chooseColor();
  }

  void _handleFocusChanged(bool hasFocus) {
    setState(() {
      _hasFocus = hasFocus;
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode focusNode, KeyEvent event) {
    KeyEventResult result = KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _chooseColor();
      result = KeyEventResult.handled;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: 1,
      fit: FlexFit.tight,
      child: Focus(
        onFocusChange: _handleFocusChanged,
        onKeyEvent: _handleKeyEvent,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _hasFocus ? const Color(0xffaa9988) : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GestureDetector(
                      onTap: _handleTap,
                      child: Stack(
                        fit: StackFit.passthrough,
                        children: [
                          widget.theme.buildCard(widget.value),
                          widget.result.build(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

sealed class Result {
  const Result(this.color);

  final Color color;

  Widget build() => ColoredBox(color: color);

  String toJson() => runtimeType.toString().toLowerCase();
}

final class Unknown extends Result {
  const Unknown() : super(const Color(0x00000000));
}

final class Neutral extends Result {
  const Neutral() : super(const Color(0xffc8b4a0));

  @override
  Widget build() {
    return Image.asset('assets/tan.png', fit: BoxFit.cover);
  }
}

final class Death extends Result {
  const Death() : super(const Color(0xff000000));

  @override
  Widget build() {
    return Image.asset('assets/black.png', fit: BoxFit.cover);
  }
}

final class Red extends Result {
  const Red() : super(const Color(0xffd25f4b));

  @override
  Widget build() {
    return Image.asset('assets/red.png', fit: BoxFit.cover);
  }
}

final class Blue extends Result {
  const Blue() : super(const Color(0xff4e7ba6));

  @override
  Widget build() {
    return Image.asset('assets/blue.png', fit: BoxFit.cover);
  }
}

class ResultMap {
  ResultMap({Result? firstMove, Random? random}) {
    random ??= Random(DateTime.now().microsecondsSinceEpoch);
    firstMove ??= _chooseRandomFirstMove(random);
    final List<Result> values = List<Result>.from(_seedValues)
        ..add(firstMove)
        ..shuffle(random);
    for (int i = 0; i < values.length; i++) {
      final Coordinates coordinates = _getCoordinates(i);
      _results[coordinates] = values[i];
    }
  }

  final Map<Coordinates, Result> _results = <Coordinates, Result>{};

  static const List<Result> _seedValues = <Result>[
    Death(), Neutral(), Neutral(), Neutral(), Neutral(), Neutral(), Neutral(), Neutral(),
    Blue(), Blue(), Blue(), Blue(), Blue(), Blue(), Blue(), Blue(),
    Red(), Red(), Red(), Red(), Red(), Red(), Red(), Red(),
  ];

  static Result _chooseRandomFirstMove(Random random) {
    return random.nextBool() ? const Red() : const Blue();
  }

  static Coordinates _getCoordinates(int index) {
    final int i = index ~/ Board.xSize;
    final int j = index % Board.xSize;
    return (i, j);
  }

  Result operator[](Coordinates coordinates) => _results[coordinates]!;
}

typedef Coordinates = (int, int);
