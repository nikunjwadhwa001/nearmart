import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/cart_item.dart';

enum AddToCartResultType {
  added,
  incremented,
  conflict,
}

class AddToCartResult {
  final AddToCartResultType type;
  final String? currentShopName;

  const AddToCartResult._(this.type, {this.currentShopName});

  const AddToCartResult.added() : this._(AddToCartResultType.added);
  const AddToCartResult.incremented() : this._(AddToCartResultType.incremented);
  const AddToCartResult.conflict({String? currentShopName})
      : this._(AddToCartResultType.conflict, currentShopName: currentShopName);

  bool get isConflict => type == AddToCartResultType.conflict;
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  AddToCartResult addItem(
    CartItem newItem, {
    bool replaceExistingShop = false,
  }) {
    if (state.isNotEmpty && state.first.shopId != newItem.shopId) {
      if (!replaceExistingShop) {
        return AddToCartResult.conflict(currentShopName: state.first.shopName);
      }
      state = [];
    }

    final existingIndex = state.indexWhere(
      (item) =>
          item.shopId == newItem.shopId && item.variantId == newItem.variantId,
    );

    if (existingIndex >= 0) {
      final updated = [...state];
      updated[existingIndex] = updated[existingIndex].copyWith(
        quantity: updated[existingIndex].quantity + newItem.quantity,
      );
      state = updated;
      return const AddToCartResult.incremented();
    } else {
      state = [...state, newItem];
      return const AddToCartResult.added();
    }
  }

  void removeItem(String shopId, String variantId) {
    state = state
        .where((item) => !(item.shopId == shopId && item.variantId == variantId))
        .toList();
  }

  void updateQuantity(String shopId, String variantId, int quantity) {
    if (quantity <= 0) {
      removeItem(shopId, variantId);
      return;
    }
    state = state.map((item) {
      if (item.shopId == shopId && item.variantId == variantId) {
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