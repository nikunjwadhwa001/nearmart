import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/cart_item.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(CartItem newItem) {
    final existingIndex = state.indexWhere(
      (item) => item.variantId == newItem.variantId,
    );

    if (existingIndex >= 0) {
      final updated = [...state];
      updated[existingIndex] = updated[existingIndex].copyWith(
        quantity: updated[existingIndex].quantity + newItem.quantity,
      );
      state = updated;
    } else {
      state = [...state, newItem];
    }
  }

  void removeItem(String variantId) {
    state = state.where((item) => item.variantId != variantId).toList();
  }

  void updateQuantity(String variantId, int quantity) {
    if (quantity <= 0) {
      removeItem(variantId);
      return;
    }
    state = state.map((item) {
      if (item.variantId == variantId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
  }

  void clearCart() {
    state = [];
  }

  int get totalItems => state.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice => state.fold(0.0, (sum, item) => sum + item.total);
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

final cartItemCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0, (sum, item) => sum + item.quantity);
});

final cartTotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0.0, (sum, item) => sum + item.total);
});

final cartShopNameProvider = Provider<String?>((ref) {
  final items = ref.watch(cartProvider);
  if (items.isEmpty) return null;
  return items.first.shopName;
});