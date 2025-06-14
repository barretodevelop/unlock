// 1. connection_service.dart
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectionService {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>?
  _connectivitySubscription;
  static bool _isConnected = true;
  static final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  // ✅ Stream para ouvir mudanças de conectividade
  static Stream<bool> get connectionStream => _connectionController.stream;
  static bool get isConnected => _isConnected;

  // ✅ Inicializar monitoramento de conectividade
  static Future<void> initialize() async {
    try {
      // Verificar conectividade inicial
      final List<ConnectivityResult> results = await _connectivity
          .checkConnectivity(); // ✅ CORRIGIDO: List<ConnectivityResult>
      _updateConnectionStatus(results);

      // Ouvir mudanças de conectividade
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        // ✅ CORRIGIDO: Agora retorna List<ConnectivityResult>
        _updateConnectionStatus,
        onError: (error) {
          if (kDebugMode) {
            print(
              '❌ ConnectionService: Erro no listener de conectividade: $error',
            );
          }
        },
      );

      if (kDebugMode) {
        print(
          '✅ ConnectionService: Inicializado. Status: ${_isConnected ? 'Conectado' : 'Desconectado'}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ConnectionService: Erro na inicialização: $e');
      }
    }
  }

  // ✅ Atualizar status de conectividade
  static void _updateConnectionStatus(List<ConnectivityResult> results) {
    // ✅ CORRIGIDO: List<ConnectivityResult>
    try {
      // ✅ Considera conectado se há pelo menos uma conexão ativa
      final bool hasConnection = results.any(
        (result) => result != ConnectivityResult.none,
      );

      if (_isConnected != hasConnection) {
        _isConnected = hasConnection;
        _connectionController.add(_isConnected);

        if (kDebugMode) {
          print(
            '🔄 ConnectionService: Status alterado para: ${_isConnected ? 'Conectado' : 'Desconectado'}',
          );
          print(
            '📡 Tipos de conexão: ${results.map((r) => r.name).join(', ')}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ConnectionService: Erro ao atualizar status: $e');
      }
    }
  }

  // ✅ Verificar conectividade manualmente
  static Future<bool> checkConnection() async {
    try {
      final List<ConnectivityResult> results = await _connectivity
          .checkConnectivity(); // ✅ CORRIGIDO
      _updateConnectionStatus(results);
      return _isConnected;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ConnectionService: Erro na verificação manual: $e');
      }
      return false;
    }
  }

  // ✅ Obter tipos de conexão detalhados
  static Future<Map<String, dynamic>> getConnectionDetails() async {
    try {
      final List<ConnectivityResult> results = await _connectivity
          .checkConnectivity();

      return {
        'isConnected': results.any((r) => r != ConnectivityResult.none),
        'connectionTypes': results.map((r) => r.name).toList(),
        'hasWifi': results.contains(ConnectivityResult.wifi),
        'hasMobile': results.contains(ConnectivityResult.mobile),
        'hasEthernet': results.contains(ConnectivityResult.ethernet),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ ConnectionService: Erro ao obter detalhes: $e');
      }
      return {
        'isConnected': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // ✅ Aguardar por conectividade
  static Future<bool> waitForConnection({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_isConnected) return true;

    final completer = Completer<bool>();
    late StreamSubscription<bool> subscription;

    subscription = connectionStream.listen((isConnected) {
      if (isConnected) {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    });

    // Timeout
    Timer(timeout, () {
      subscription.cancel();
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    return completer.future;
  }

  // ✅ Limpar recursos
  static Future<void> dispose() async {
    try {
      await _connectivitySubscription?.cancel();
      _connectivitySubscription = null;
      await _connectionController.close();

      if (kDebugMode) {
        print('✅ ConnectionService: Recursos limpos');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ConnectionService: Erro ao limpar recursos: $e');
      }
    }
  }
}
