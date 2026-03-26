import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:websockets/src/common/constant/config.dart';

class PusherClient {
  late final PusherChannelsClient _pusherChannelsClient;

  PusherChannelsClient get client => _pusherChannelsClient;

  Future<void> initilize() async {
    const options = PusherChannelsOptions.fromHost(
      scheme: Config.wsTls ? 'wss' : 'ws',
      host: Config.wsHost,
      key: Config.wsKey,
      port: Config.wsPort,
    );

    _pusherChannelsClient = PusherChannelsClient.websocket(
      options: options,
      connectionErrorHandler: (exception, trace, refresh) async {
        Error.throwWithStackTrace(Exception('Pusher channel client exception: $exception'), trace);
      },
    );

    await _pusherChannelsClient.connect();
  }
}
