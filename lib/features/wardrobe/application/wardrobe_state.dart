import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/wardrobe_repository.dart';
import '../domain/wardrobe_item.dart';

class WardrobeState {
  const WardrobeState({
    required this.items,
    required this.isLoading,
    required this.hasMore,
    required this.errorMessage,
    required this.page,
    required this.searchQuery,
  });

  final List<WardrobeItem> items;
  final bool isLoading;
  final bool hasMore;
  final String? errorMessage;
  final int page;
  final String searchQuery;

  WardrobeState copyWith({
    List<WardrobeItem>? items,
    bool? isLoading,
    bool? hasMore,
    String? errorMessage,
    int? page,
    String? searchQuery,
  }) {
    return WardrobeState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
      page: page ?? this.page,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class WardrobeMarkWornResult {
  const WardrobeMarkWornResult({required this.item, required this.wearHistory});

  final WardrobeItem item;
  final Map<String, dynamic> wearHistory;
}

class WardrobeController extends StateNotifier<WardrobeState> {
  WardrobeController(this._repository)
    : super(
        const WardrobeState(
          items: [],
          isLoading: false,
          hasMore: true,
          errorMessage: null,
          page: 1,
          searchQuery: '',
        ),
      );

  final WardrobeRepository _repository;

  String _userMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('socketexception') ||
        message.contains('dioexception') ||
        message.contains('handshake') ||
        message.contains('os error')) {
      return 'You appear to be offline. Check your connection and try again.';
    }
    if (message.contains('404')) {
      return 'That wardrobe item could not be found. Please refresh and try again.';
    }
    if (message.contains('401') || message.contains('authentication')) {
      return 'Please sign in again to continue.';
    }
    if (message.contains('500') || message.contains('internal')) {
      return 'The wardrobe service is having trouble. Please try again soon.';
    }
    return 'We could not complete that request. Please try again.';
  }

  Future<void> loadItems({
    bool refresh = false,
    bool force = false,
    String? search,
    String? category,
    String? color,
    String? brand,
    String? season,
    String? occasion,
    String? laundryStatus,
    bool? favorite,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    if (state.isLoading && !force) return;
    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        page: 1,
        items: [],
      );
    } else {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final response = await _repository.fetchItems(
        page: refresh ? 1 : state.page + 1,
        search:
            search ?? (state.searchQuery.isEmpty ? null : state.searchQuery),
        category: category,
        color: color,
        brand: brand,
        season: season,
        occasion: occasion,
        laundryStatus: laundryStatus,
        favorite: favorite,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
      final payload = response['data'] as List<dynamic>? ?? [];
      final pagination = response['pagination'] as Map<String, dynamic>? ?? {};
      final items = payload
          .map(
            (item) =>
                WardrobeItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      state = state.copyWith(
        items: refresh ? items : [...state.items, ...items],
        isLoading: false,
        hasMore: pagination['hasMore'] == true,
        page: refresh ? 1 : state.page + 1,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _userMessage(error),
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _userMessage(error),
      );
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query, page: 1, items: []);
    await loadItems(refresh: true, search: query);
  }

  Future<void> createItem(
    Map<String, dynamic> payload, {
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.createItem(
        payload: payload,
        imageFile: imageFile,
        imageBytes: imageBytes,
      );
      await loadItems(refresh: true, force: true);
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _userMessage(error),
      );
      rethrow;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _userMessage(error),
      );
      rethrow;
    }
  }

  Future<void> updateItem(
    String id,
    Map<String, dynamic> payload, {
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.updateItem(
        id: id,
        payload: payload,
        imageFile: imageFile,
        imageBytes: imageBytes,
      );
      await loadItems(refresh: true, force: true);
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _userMessage(error),
      );
      rethrow;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _userMessage(error),
      );
      rethrow;
    }
  }

  bool _isMarkingWorn = false;

  Future<WardrobeMarkWornResult> markAsWorn({
    required String id,
    required String occasion,
    int? rating,
    String? notes,
  }) async {
    if (_isMarkingWorn) {
      throw StateError('A wear request is already in progress.');
    }
    _isMarkingWorn = true;
    try {
      final response = await _repository.markAsWorn(
        id: id,
        occasion: occasion,
        rating: rating,
        notes: notes,
      );
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final clothingJson = data['clothing'] as Map<String, dynamic>? ?? {};
      final wearHistoryJson = data['wearHistory'] as Map<String, dynamic>? ?? {};
      final updatedItem = WardrobeItem.fromJson(clothingJson);

      state = state.copyWith(
        items: [
          for (final existing in state.items)
            if (existing.id == updatedItem.id) updatedItem else existing,
        ],
      );

      return WardrobeMarkWornResult(item: updatedItem, wearHistory: wearHistoryJson);
    } finally {
      _isMarkingWorn = false;
    }
  }

  Future<void> deleteItem(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.deleteItem(id);
      state = state.copyWith(
        items: state.items.where((item) => item.id != id).toList(),
        isLoading: false,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _userMessage(error),
      );
      rethrow;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _userMessage(error),
      );
      rethrow;
    }
  }
}

final wardrobeControllerProvider =
    StateNotifierProvider<WardrobeController, WardrobeState>((ref) {
      return WardrobeController(WardrobeRepository());
    });

final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());
