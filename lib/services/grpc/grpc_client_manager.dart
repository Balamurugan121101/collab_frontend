import 'package:grpc/grpc.dart';
import 'package:flutter/foundation.dart';
import '../../config/environment_config.dart';
import '../storage/secure_storage_service.dart';
import 'token_interceptor.dart';

enum ServiceType {
  auth,
  chat,
  workspace,
  notification,
}

class GrpcClientManager {
  static final GrpcClientManager _instance = GrpcClientManager._internal();
  factory GrpcClientManager() => _instance;
  GrpcClientManager._internal();

  final Map<ServiceType, ClientChannel> _channels = {};
  final Map<ServiceType, TokenInterceptor> _interceptors = {};
  final SecureStorageService _storageService = SecureStorageService();

  // Get service configuration from environment
  ServiceConfig _getServiceConfig(ServiceType service) {
    switch (service) {
      case ServiceType.auth:
        return ServiceConfig(
          name: 'auth',
          host: EnvironmentConfig.authHost,
          port: EnvironmentConfig.authPort,
        );
      case ServiceType.chat:
        return ServiceConfig(
          name: 'chat',
          host: EnvironmentConfig.chatHost,
          port: EnvironmentConfig.chatPort,
        );
      case ServiceType.workspace:
        return ServiceConfig(
          name: 'file',
          host: EnvironmentConfig.fileHost,
          port: EnvironmentConfig.filePort,
        );
      case ServiceType.notification:
        return ServiceConfig(
          name: 'notification',
          host: EnvironmentConfig.notificationHost,
          port: EnvironmentConfig.notificationPort,
        );
    }
  }

  // Get or create channel for a service
  ClientChannel getChannel(ServiceType service) {
    if (_channels.containsKey(service)) {
      return _channels[service]!;
    }

    final config = _getServiceConfig(service);

    final channel = ClientChannel(
      config.host,
      port: config.port,
      options: ChannelOptions(
        credentials: EnvironmentConfig.useSSL
            ? const ChannelCredentials.secure()
            : const ChannelCredentials.insecure(),
        codecRegistry: CodecRegistry(
          codecs: const [GzipCodec(), IdentityCodec()],
        ),
        connectionTimeout: Duration(
          seconds: EnvironmentConfig.connectionTimeout,
        ),
        idleTimeout: const Duration(minutes: 10),
      ),
    );

    _channels[service] = channel;

    return channel;
  }

  // Get interceptors for a service
  List<ClientInterceptor> getInterceptors(ServiceType service) {
    if (!_interceptors.containsKey(service)) {
      _interceptors[service] = TokenInterceptor(_storageService);
    }
    return [_interceptors[service]!];
  }

  // Get call options
  CallOptions getCallOptions({Duration? timeout}) {
    return CallOptions(
      timeout: timeout ?? Duration(
        seconds: EnvironmentConfig.apiTimeout,
      ),
    );
  }

  // Update token for a specific service
  Future<void> updateToken(ServiceType service) async {
    if (_interceptors.containsKey(service)) {
      await _interceptors[service]!.updateToken();
    }
  }

  // Update token for all services
  Future<void> updateAllTokens() async {
    final token = await _storageService.getAccessToken();
    if (token != null) {
      for (final interceptor in _interceptors.values) {
        await interceptor.updateToken();
      }
    }
  }

  // Clear token for a specific service
  void clearToken(ServiceType service) {
    if (_interceptors.containsKey(service)) {
      _interceptors[service]!.clearToken();
    }
  }

  // Clear all tokens
  void clearAllTokens() {
    for (final interceptor in _interceptors.values) {
      interceptor.clearToken();
    }
  }

  // Close channel for a service
  Future<void> closeChannel(ServiceType service) async {
    if (_channels.containsKey(service)) {
      await _channels[service]!.shutdown();
      _channels.remove(service);
      _interceptors.remove(service);
    }
  }

  // Close all channels
  Future<void> closeAllChannels() async {
    for (final channel in _channels.values) {
      await channel.shutdown();
    }
    _channels.clear();
    _interceptors.clear();
  }
}

class ServiceConfig {
  final String name;
  final String host;
  final int port;

  ServiceConfig({
    required this.name,
    required this.host,
    required this.port,
  });
}
