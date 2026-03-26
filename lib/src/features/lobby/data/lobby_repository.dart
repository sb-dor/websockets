import 'package:dio/dio.dart';
import 'package:websockets/src/features/lobby/models/room.dart';

abstract interface class ILobbyRepository {
  Future<List<Room>> getRooms();
  Future<Room> createRoom({required String name});
  Future<Room> joinRoom({required String code});
}

class LobbyRepositoryImpl implements ILobbyRepository {
  LobbyRepositoryImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<List<Room>> getRooms() async {
    final response = await _dio.get<List<Object?>>('/api/rooms');
    return (response.data ?? [])
        .whereType<Map<String, Object?>>()
        .map(Room.fromMap)
        .toList(growable: false);
  }

  @override
  Future<Room> createRoom({required String name}) async {
    final response = await _dio.post<Map<String, Object?>>('/api/rooms', data: {'name': name});
    return Room.fromMap(response.data!);
  }

  @override
  Future<Room> joinRoom({required String code}) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/api/rooms/join',
      data: {'code': code.toUpperCase()},
    );
    return Room.fromMap(response.data!);
  }
}
