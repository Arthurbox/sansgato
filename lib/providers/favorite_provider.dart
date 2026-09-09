import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/favorite_service.dart';

class FavoriteNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() {
    _fetchFavorites();
    return {};
  }

  Future<void> _fetchFavorites() async {
    try {
      final favorites = await FavoriteService.fetchFavorites();
      state = favorites.toSet();
    } catch (e) {
      debugPrint('Erreur fetchFavorites: $e');
    }
  }

  Future<String?> toggleFavorite(int productId) async {
    final isFavorite = state.contains(productId);
    
    // Optimistic update
    if (isFavorite) {
      state = {...state}..remove(productId);
    } else {
      state = {...state, productId};
    }

    try {
      await FavoriteService.toggleFavorite(productId);
      return null;
    } catch (e) {
      // Revert if failed
      if (isFavorite) {
        state = {...state, productId};
      } else {
        state = {...state}..remove(productId);
      }
      debugPrint('Erreur toggleFavorite: $e');
      return e.toString();
    }
  }
}

final favoriteProvider = NotifierProvider<FavoriteNotifier, Set<int>>(FavoriteNotifier.new);
