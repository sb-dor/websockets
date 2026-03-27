import 'dart:async';
import 'package:dio/dio.dart';
import 'package:websockets/src/features/chat/models/message.dart';

abstract interface class IChatRepository {
  Future<List<Message>> getHistory({required String roomCode});

  Future<void> sendMessage({required String roomCode, required String content});
}

class ChatRepositoryImpl implements IChatRepository {
  ChatRepositoryImpl({required final Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<List<Message>> getHistory({required String roomCode}) async {
    final response = await _dio.get<List<Object?>>('/api/rooms/$roomCode/messages');
    return (response.data ?? [])
        .whereType<Map<String, Object?>>()
        .map(Message.fromMap)
        .toList(growable: false);
  }

  @override
  Future<void> sendMessage({required String roomCode, required String content}) async {
    await _dio.post<void>('/api/rooms/$roomCode/messages', data: {'content': content});
  }
}
