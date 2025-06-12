import 'package:flutter/material.dart';
import 'package:evolution_api/evolution_api.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Evolution API Test', theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true), home: const WebSocketTestPage());
  }
}

class WebSocketTestPage extends StatefulWidget {
  const WebSocketTestPage({super.key});

  @override
  State<WebSocketTestPage> createState() => _WebSocketTestPageState();
}

class _WebSocketTestPageState extends State<WebSocketTestPage> {
  final _hostController = TextEditingController(text: 'http://localhost:8080');
  final _tokenController = TextEditingController(text: '429683C4C977415CAAFCCE10F7D57E11');
  final _instanceController = TextEditingController(text: '7e92e0e7-4a09-43d1-90e6-4a1e98a1cc03');

  late EvolutionApi _api;
  bool _isConnected = false;
  final List<String> _events = [];

  @override
  void initState() {
    super.initState();
    _initializeApi();
  }

  void _initializeApi() {
    _api = EvolutionApi(host: _hostController.text, token: _tokenController.text, websocketEnabled: true);

    // _api.websocket.setEvents(instanceName: _instanceController.text, events: [EvoEvents.CONNECTION_UPDATE]);
  }

  Future<void> _connect() async {
    final stream = await _api.websocket.connect(instanceName: _instanceController.text);
    stream?.listen((event) {
      if (event.message != null) {
        print(event.message.toString());
      }
    });
  }

  void _disconnect() {
    _api.websocket.disconnect();
    setState(() {
      _isConnected = false;
      _events.add('🛑 Desconectando...');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evolution API WebSocket Test'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _hostController, decoration: const InputDecoration(labelText: 'Host', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _tokenController, decoration: const InputDecoration(labelText: 'Token', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _instanceController, decoration: const InputDecoration(labelText: 'Instance', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: _isConnected ? null : _connect, child: const Text('Conectar')),
                ElevatedButton(onPressed: _isConnected ? _disconnect : null, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('Desconectar')),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Eventos:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                child: ListView.builder(
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(_events[index]));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hostController.dispose();
    _tokenController.dispose();
    _instanceController.dispose();
    _api.websocket.disconnect();
    super.dispose();
  }
}
