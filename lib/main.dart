import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show CircularProgressIndicator, FloatingActionButton, Icons;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:network_info_plus/network_info_plus.dart' as nip;

typedef Coordinates = (int, int);
typedef CardValue = int;

extension ToInt on bool {
  int toInt() => this ? 1 : 0;
}

extension ToBool on int {
  bool toBool() => this == 0 ? false : true;
}

extension GetCoordinates on int {
  Coordinates get coordinates {
    assert(this >= 0 && this < Board.size);
    final int i = this ~/ Board.xSize;
    final int j = this % Board.xSize;
    return (i, j);
  }
}

extension GetIndex on Coordinates {
  int get index {
    assert($1 >= 0 && $1 < Board.ySize);
    assert($2 >= 0 && $2 < Board.xSize);
    return $1 * Board.xSize + $2;
  }
}

extension AsCoordinatesMap<T> on Iterable<T> {
  Map<Coordinates, T> asCoordinatesMap() {
    assert(length == Board.size);
    final Map<Coordinates, T> result = <Coordinates, T>{};
    int i = 0;
    for (final T item in this) {
      result[i.coordinates] = item;
      i++;
    }
    return result;
  }
}

extension AsIndexedList<T> on Map<Coordinates, T> {
  List<T> asIndexedList() {
    assert(length == Board.size);
    final List<T?> result = List<T?>.filled(length, null);
    forEach((Coordinates coordinates, T value) {
      result[coordinates.index] = value;
    });
    assert(result.every((T? element) => element != null));
    return result.cast<T>();
  }
}

abstract class Theme {
  Iterable<CardValue> newGame({Set<CardValue> exclude});

  Widget buildCard(CardValue value);

  int get length;
}

class RandomizedIterable extends Object with Iterable<CardValue> {
  RandomizedIterable(this.length);

  @override
  final int length;

  @override
  Iterator<CardValue> get iterator => RandomizedIterator(length);
}

class RandomizedIterator implements Iterator<CardValue> {
  RandomizedIterator(this.length);

  final int length;
  final Set<CardValue> _usedValues = <CardValue>{};
  final Random _random = Random(DateTime.now().microsecondsSinceEpoch);

  bool _currentNeedsCalculating = false;
  CardValue _current = -1;

  @override
  CardValue get current {
    if (_currentNeedsCalculating) {
      do {
        _current = _random.nextInt(length);
      } while (_usedValues.contains(_current));
      _usedValues.add(_current);
      _currentNeedsCalculating = false;
    } else if (_current == -1) {
      throw StateError('moveNext() has not yet been called');
    }
    return _current;
  }

  @override
  bool moveNext() {
    _currentNeedsCalculating = true;
    return _usedValues.length < length;
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
  Iterable<CardValue> newGame({Set<CardValue> exclude = const <CardValue>{}}) {
    // TODO: do we still need to do this copy?
    final Set<CardValue> excludeCopy = Set<CardValue>.from(exclude);
    return RandomizedIterable(_population.length).where((CardValue value) {
      return !excludeCopy.contains(value);
    }).take(Board.size);
  }

  @override
  Widget buildCard(CardValue value) {
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

class NoNetworkError extends Error {
  NoNetworkError(this.message);

  final String message;
}

class NetworkInfo {
  const NetworkInfo();

  static const MethodChannel _channel = MethodChannel('codeword.tvolkert.dev/network');

  Future<List<String>> getAddresses() async {
    List<String>? addresses;
    try {
      addresses = await _channel.invokeListMethod<String>('getAddresses');
      debugPrint('channel returned addresses: $addresses');
    } on PlatformException catch (error) {
      if (error.code == 'no_network') {
        throw NoNetworkError('Not connected to network');
      } else {
        rethrow;
      }
    } on MissingPluginException {
      debugPrint('No platform implementation for getAddresses(); falling back to network_info_plus');
      addresses = await _fallbackGetAddresses();
    }
    assert(addresses != null);
    assert(() {
      final RegExp pattern = RegExp(r'^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]+$');
      assert(addresses!.every(pattern.hasMatch));
      return true;
    }());
    return addresses!;
  }

  Future<List<String>> _fallbackGetAddresses() async {
    final nip.NetworkInfo net = nip.NetworkInfo();
    final String? ip = await net.getWifiIP();
    if (ip == null) {
      throw NoNetworkError('Not connected to wifi network');
    }
    final String? subnetMask = await net.getWifiSubmask();
    assert(subnetMask != null);
    final int subnetValue = Ip.fromDisplayValue(subnetMask!).value;
    final String subnetBinary = subnetValue.toRadixString(2);
    assert(() {
      final RegExp pattern = RegExp(r'^1*0*$');
      assert(pattern.hasMatch(subnetBinary));
      return true;
    }());
    final int prefixLength = subnetBinary.replaceAll('0', '').length;
    return <String>['$ip/$prefixLength'];
  }
}

enum MessageType {
  newAppInstance,
  syncAppState,
}

sealed class Message {
  const Message(this.messageType);

  final MessageType messageType;

  static const String _keyMessageType = 't';
  static const String _keyPayload = 'p';

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
    debugPrint('$envelope');
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
    await GameBinding.instance.controller?.sync(ip);
  }
}

class SyncAppStateMessage extends Message {
  const SyncAppStateMessage(this.results, this.values, this.usedValues, this.revealed) : super(MessageType.syncAppState);

  final List<int> results;
  final List<int> values;
  final List<int> usedValues;
  final List<bool> revealed;

  static const String _keyValues = 'v';
  static const String _keyUsedValues = 'u';
  static const String _keyRevealed = 'l';
  static const String _keyResults = 'r';

  factory SyncAppStateMessage.fromJson(Map<String, dynamic> payload) {
    return SyncAppStateMessage(
      payload[_keyResults].cast<int>(),
      payload[_keyValues].cast<int>(),
      payload[_keyUsedValues].cast<int>(),
      payload[_keyRevealed].cast<int>().map<bool>((int value) => value.toBool()).toList(),
    );
  }

  @override
  Object toJson() {
    return <String, dynamic>{
      _keyResults: results,
      _keyValues: values,
      _keyUsedValues: usedValues,
      _keyRevealed: revealed.map<int>((bool value) => value.toInt()).toList(),
    };
  }
  
  @override
  void receive() {
    NetworkBinding.instance.localServer?.onRemoteSync?.call(this);
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

  SyncAppStateCallback? onRemoteSync;

  Future<bool> start() async {
    if (isStopped) {
      assert(_remoteClientListener == null);
      try {
        _socket = await ServerSocket.bind(ip, port);
      } on SocketException catch (error) {
        if (error.toString().contains('already in use')) {
          return false;
        } else {
          rethrow;
        }
      }
      _remoteClientListener = _socket!.listen(_handleNewRemoteClient, onError: _handleError);
      debugPrint('Server listening on $ip:$port');
    }
    return true;
  }

  Future<void> stop() async {
    if (isStarted) {
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

  bool get isStarted => _socket != null;

  bool get isStopped => _socket == null;

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

typedef SyncAppStateCallback = void Function(SyncAppStateMessage message);

mixin GameBinding on AppBindingBase {
  /// The singleton instance of this object.
  static late GameBinding _instance;
  static GameBinding get instance => _instance;

  GameController? controller;

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

  Server? _localServer;
  Server? get localServer => _localServer;

  late LocalClient _localClient;
  LocalClient get localClient => _localClient;

  late LocalNetwork _localNetwork;
  LocalNetwork get localNetwork => _localNetwork;

  @override
  @protected
  @mustCallSuper
  Future<void> initInstances() async {
    await super.initInstances();
    _instance = this;

    try {
      List<String> addresses = await const NetworkInfo().getAddresses();
      if (addresses.isEmpty) {
        debugPrint('No address found for local network');
        return;
      }

      final String address = addresses.first;
      if (addresses.length > 1) {
        debugPrint('Found more than one IPv4 address; chose first one. The list was:');
        for (String value in addresses) {
          debugPrint(' - $value');
        }
      }
      _ip = address.split('/').first;
      _subnetMask = Ip.fromPrefixLength(int.parse(address.split('/').last)).displayValue;
    } on NoNetworkError {
      debugPrint('No network connection');
      return;
    }

    _localServer = Server(ip: ip);
    _localClient = LocalClient();
    await localServer!.start();

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
      if (NetworkBinding.instance.localServer == null) {
        runApp(const ErrorScreen(
          'This machine appears to be disconnected from the local network.'
        ));
      } else if (NetworkBinding.instance.localServer!.isStopped) {
        runApp(const ErrorScreen(
          'There appears to be another Codeword app already running on '
          'this machine. Only one Codeword app can be running at a time.'
        ));
      } else {
        runApp(const CodewordApp());
      }
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

class ErrorScreen extends StatelessWidget {
  const ErrorScreen(this.errorMessage, {super.key});

  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ColoredBox(
        color: const Color(0xffffffff),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Padding(
            padding: const EdgeInsets.all(100),
            child: Center(
              child: Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: DefaultTextStyle.of(context).style.copyWith(
                  color: const Color(0xff000000),
                  fontSize: 24,
                ),
              ),
            ),
          ),
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
    final int mask = (subnetValue >>> (pos - 1)) & 0x1;
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

  factory Ip.fromPrefixLength(int length) {
    assert(length >= 16 && length <= 32);
    int value = 0;
    int mask = 1 << 31;
    for (int i = 0; i < length; i++) {
      value |= mask;
      mask = mask >>> 1;
    }
    return Ip.fromValue(value);
  }

  String? _displayValue;
  String get displayValue {
    if (_displayValue == null) {
      assert(_value != null);
      List<int> parts = <int>[
        (_value! >>> 24) & 0x000000ff,
        (_value! >>> 16) & 0x000000ff,
        (_value! >>> 8) & 0x000000ff,
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

class CodewordApp extends StatelessWidget {
  const CodewordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'Codeword',
      color: const Color(0xffd25f4b),
      textStyle: DefaultTextStyle.of(context).style.copyWith(
        color: const Color(0xff000000),
        fontSize: 24,
      ),
      shortcuts: <ShortcutActivator, Intent>{
        ... WidgetsApp.defaultShortcuts,
        const SingleActivator(LogicalKeyboardKey.select): const ActivateIntent(),
      },
      builder: (BuildContext context, Widget? widget) {
        return const SafeArea(
          child: Game(),
        );
      },
    );
  }
}

class Game extends StatefulWidget {
  const Game({super.key, this.theme = const ClassicTheme()});

  final Theme theme;

  @override
  State<Game> createState() => _GameState();

  static GameController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_GameScope>()!.state;
  }
}

abstract class GameController {
  /// Reinitializes the game to contain a new set of values and results.
  void newGame();

  /// The theme of the game.
  Theme get theme;

  /// Gets the value of the card at the specified coordinates.
  CardValue getValue(Coordinates coordinates);

  /// Tells whether the card at the specified coordinates has been revealed.
  bool isRevealed(Coordinates coordinates);

  /// Gets the result of the card at the specified coordinates.
  ///
  /// The result is not necessarily shown to the user. Results are only shown
  /// either once a player chooses a card or if the game is in codegiver mode.
  Result getResult(Coordinates coordinates);

  void toggleRevealed(Coordinates coordinates);

  bool get codegiverMode;
  set codegiverMode(bool value);

  int get numRedCardsRemaining;
  int get numBlueCardsRemaining;

  /// Syncs the state of this game to remote clients.
  ///
  /// Once this future completes, the state of remote instances of this game
  /// will match this local game's state.
  ///
  /// If [ip] is specified, this game's state will only be synced to the
  /// specified remote instance. By default, this game's state is broadcast to
  /// all remote instances.
  Future<void> sync([String? ip]);
}

class _GameState extends State<Game> implements GameController {
  late List<CardValue> _values;
  late List<CardValue> _usedValues;
  late List<bool> _revealed;
  late ResultMap _results;
  bool _codegiverMode = false;

  void _handleRemoteSync(SyncAppStateMessage message) {
    assert(mounted);
    setState(() {
      _values = message.values;
      _usedValues = message.usedValues;
      _revealed = message.revealed;
      _results = ResultMap.fromValues(message.results);
    });
  }

  bool _notYetRevealed(MapEntry<Coordinates, Result> entry) {
    return !_revealed[entry.key.index];
  }

  bool Function(MapEntry<Coordinates, Result>) _isColor(ResultType type) {
    return (MapEntry<Coordinates, Result> entry) {
      return entry.value.type == type;
    };
  }

  @override
  void newGame() {
    setState(() {
      _values = widget.theme.newGame(exclude: Set<CardValue>.from(_usedValues)).toList();
      _usedValues.addAll(_values);
      _revealed = List<bool>.filled(Board.size, false);
      _results = ResultMap();
      _codegiverMode = false;
      if (_usedValues.length + Board.size > widget.theme.length) {
        // We've used up all the cards
        _usedValues.clear();
      }
    });
  }

  @override
  Theme get theme => widget.theme;

  @override
  CardValue getValue(Coordinates coordinates) => _values[coordinates.index];

  @override
  bool isRevealed(Coordinates coordinates) => _revealed[coordinates.index];

  @override
  Result getResult(Coordinates coordinates) => _results[coordinates];

  @override
  void toggleRevealed(Coordinates coordinates) {
    setState(() {
      _revealed[coordinates.index] = !_revealed[coordinates.index];
    });
  }

  @override
  bool get codegiverMode => _codegiverMode;

  @override
  set codegiverMode(bool value) {
    setState(() {
      _codegiverMode = value;
    });
  }

  @override
  int get numRedCardsRemaining {
    return _results.map.entries
        .where(_notYetRevealed)
        .where(_isColor(ResultType.red))
        .length;
  }

  @override
  int get numBlueCardsRemaining {
    return _results.map.entries
        .where(_notYetRevealed)
        .where(_isColor(ResultType.blue))
        .length;
  }

  @override
  Future<void> sync([String? ip]) async {
    final Message message = SyncAppStateMessage(
      _results.values,
      _values,
      _usedValues,
      _revealed,
    );
    if (ip == null) {
      await NetworkBinding.instance.localClient.broadcastMessage(message);
    } else {
      await NetworkBinding.instance.localClient.sendMessage(ip, message);
    }
  }

  @override
  void didUpdateWidget(covariant Game oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.theme != oldWidget.theme) {
      _usedValues.clear();
    }
  }

  @override
  void initState() {
    super.initState();
    _usedValues = <CardValue>[];
    newGame();
    NetworkBinding.instance.localServer?.onRemoteSync = _handleRemoteSync;
    GameBinding.instance.controller = this;
  }

  @override
  void dispose() {
    GameBinding.instance.controller = null;
    NetworkBinding.instance.localServer?.onRemoteSync = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _GameScope(
      state: this,
      valuesHash: Object.hashAll(_values),
      revealedHash: Object.hashAll(_revealed),
      resultsHash: Object.hashAll(_results.values),
      codegiverMode: _codegiverMode,
      child: const FocusScope(
        autofocus: true,
        child: Row(
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
      ),
    );
  }
}

class _GameScope extends InheritedWidget {
  const _GameScope({
    required super.child,
    required this.state,
    required this.valuesHash,
    required this.revealedHash,
    required this.resultsHash,
    required this.codegiverMode,
  });

  final _GameState state;
  final int valuesHash;
  final int revealedHash;
  final int resultsHash;
  final bool codegiverMode;

  @override
  bool updateShouldNotify(_GameScope oldWidget) {
    return valuesHash != oldWidget.valuesHash
        || revealedHash != oldWidget.revealedHash
        || resultsHash != oldWidget.resultsHash
        || codegiverMode != oldWidget.codegiverMode;
  }
}

class ActionBar extends StatelessWidget {
  const ActionBar({super.key});

  void _handleNewGame() {
    final GameController controller = GameBinding.instance.controller!;
    controller.newGame();
    controller.sync();
  }

  void _handleToggleCodegiverMode() {
    final GameController controller = GameBinding.instance.controller!;
    controller.codegiverMode = !controller.codegiverMode;
  }

  @override
  Widget build(BuildContext context) {
    final GameController gameController = Game.of(context);
    return DefaultTextStyle.merge(
      style: const TextStyle(
        color: Color(0xffffffff),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ActionButton(
              debugName: 'newGame',
              icon: Icons.refresh,
              onPressed: _handleNewGame,
            ),
            ActionButton(
              debugName: 'toggleCodegiver',
              icon: Icons.map,
              onPressed: _handleToggleCodegiverMode,
            ),
            Flexible(child: Container()),
            Scorecard(
              result: const Red(),
              score: gameController.numRedCardsRemaining,
            ),
            Scorecard(
              result: const Blue(),
              score: gameController.numBlueCardsRemaining,
            ),
          ],
        ),
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.debugName,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String? debugName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: FloatingActionButton(
        onPressed: onPressed,
        child: Icon(icon),
      ),
    );
  }

  @override
  String toStringShort() {
    return 'ActionButton-[$debugName]';
  }
}

class Scorecard extends StatelessWidget {
  const Scorecard({
    super.key,
    required this.result,
    required this.score,
  });

  final Result result;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: result.color,
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Center(
              child: Text(
                '$score',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Board extends StatefulWidget {
  const Board({super.key});

  static const int xSize = 5;
  static const int ySize = 5;
  static const int size = xSize * ySize;

  @override
  State<Board> createState() => _BoardState();
}

class _BoardState extends State<Board> {
  final Map<Coordinates, GlobalKey<TileState>> _tiles = <Coordinates, GlobalKey<TileState>>{};

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < Board.size; i++) {
      final Coordinates coordinates = i.coordinates;
      _tiles[coordinates] ??= GlobalKey<TileState>(debugLabel: 'Tile$coordinates');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                coordinates: coordinates,
              );
            }),
          ),
        );
      }),
    );
  }
}

class Tile extends StatefulWidget {
  const Tile({
    super.key,
    required this.coordinates,
  });

  final Coordinates coordinates;

  @override
  State<Tile> createState() => TileState();
}

class TileState extends State<Tile> {
  bool _hasFocus = false;
  late FocusNode _focusNode;

  void _handleTap() {
    _toggleRevealed();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _toggleRevealed() {
    GameController controller = Game.of(context);
    controller.toggleRevealed(widget.coordinates);
    controller.sync();
  }

  void _handleFocusChanged(bool hasFocus) {
    setState(() {
      _hasFocus = hasFocus;
      if (hasFocus) {
        SystemSound.play(SystemSoundType.click);
      }
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode focusNode, KeyEvent event) {
    KeyEventResult result = KeyEventResult.ignored;
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.select) {
        _toggleRevealed();
        result = KeyEventResult.handled;
      }
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GameController gameController = Game.of(context);
    final CardValue value = gameController.getValue(widget.coordinates);
    final bool isRevealed = gameController.isRevealed(widget.coordinates);
    final bool isCodegiverMode = gameController.codegiverMode;
    final Result result = gameController.getResult(widget.coordinates);

    return Flexible(
      flex: 1,
      fit: FlexFit.tight,
      child: Focus(
        focusNode: _focusNode,
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
                          gameController.theme.buildCard(value),
                          if (isRevealed) result.build()
                          else if (isCodegiverMode) ColoredBox(color: result.color.withAlpha(0x88)),
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

enum ResultType {
  neutral,
  assassin,
  red,
  blue,
}

sealed class Result {
  const Result(this.type, this.color);

  factory Result.fromValue(int value) {
    switch (ResultType.values[value]) {
      case ResultType.neutral: return const Neutral();
      case ResultType.assassin: return const Assassin();
      case ResultType.red: return const Red();
      case ResultType.blue: return const Blue();
    }
  }

  final ResultType type;
  final Color color;

  Widget build() => ColoredBox(color: color);
}

final class Neutral extends Result {
  const Neutral() : super(ResultType.neutral, const Color(0xffc8b4a0));

  @override
  Widget build() {
    return Image.asset('assets/tan.png', fit: BoxFit.cover);
  }
}

final class Assassin extends Result {
  const Assassin() : super(ResultType.assassin, const Color(0xff000000));

  @override
  Widget build() {
    return Image.asset('assets/black.png', fit: BoxFit.cover);
  }
}

final class Red extends Result {
  const Red() : super(ResultType.red, const Color(0xffd25f4b));

  @override
  Widget build() {
    return Image.asset('assets/red.png', fit: BoxFit.cover);
  }
}

final class Blue extends Result {
  const Blue() : super(ResultType.blue, const Color(0xff4e7ba6));

  @override
  Widget build() {
    return Image.asset('assets/blue.png', fit: BoxFit.cover);
  }
}

class ResultMap {
  ResultMap({Result? firstMove, Random? random}) {
    random ??= Random(DateTime.now().microsecondsSinceEpoch);
    this.firstMove = firstMove ?? _chooseRandomFirstMove(random);
    final List<Result> values = List<Result>.from(_seedValues)
        ..add(this.firstMove)
        ..shuffle(random);
    map = values.asCoordinatesMap();
  }

  ResultMap.fromValues(List<int> values) {
    assert(values.length == Board.size);
    assert(values.every((int value) => value >= 0 && value < ResultType.values.length));
    assert(values.where((int value) => value == ResultType.assassin.index).length == 1);
    assert(values.where((int value) => value == ResultType.neutral.index).length == 7);
    assert(values.where((int value) => value == ResultType.red.index).length >= 8);
    assert(values.where((int value) => value == ResultType.blue.index).length >= 8);
    map = values.map<Result>((int value) => Result.fromValue(value)).asCoordinatesMap();
    if (values.where((int value) => value == ResultType.red.index).length == 9) {
      firstMove = const Red();
    } else {
      firstMove = const Blue();
    }
  }

  late final Result firstMove;
  late final Map<Coordinates, Result> map;

  static const List<Result> _seedValues = <Result>[
    Assassin(), Neutral(), Neutral(), Neutral(), Neutral(), Neutral(), Neutral(), Neutral(),
    Blue(), Blue(), Blue(), Blue(), Blue(), Blue(), Blue(), Blue(),
    Red(), Red(), Red(), Red(), Red(), Red(), Red(), Red(),
  ];

  static Result _chooseRandomFirstMove(Random random) {
    return random.nextBool() ? const Red() : const Blue();
  }

  Result operator[](Coordinates coordinates) => map[coordinates]!;

  List<int> get values {
    return map.asIndexedList()
        .map<int>((Result result) => result.type.index)
        .toList();
  }
}
