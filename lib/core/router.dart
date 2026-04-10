import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/home/screens/home_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/profile_editor_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/products/screens/categories_screen.dart';
import '../features/products/screens/product_detail_screen.dart';
import '../features/products/screens/wishlist_screen.dart';
import '../models/product_model.dart';
import '../features/vendor/screens/vendor_dashboard_screen.dart';
import '../features/vendor/screens/vendor_product_editor_screen.dart';
import '../features/auth/screens/profile_screen.dart';
import '../features/vendor/screens/vendor_products_screen.dart';
import '../features/vendor/screens/vendor_orders_screen.dart';
import '../features/vendor/screens/vendor_list_screen.dart';
import '../features/vendor/screens/vendor_register_screen.dart';
import '../features/vendor/screens/vendor_storefront_screen.dart';
import '../features/vendor/screens/vendor_profile_editor_screen.dart';
import '../features/chat/screens/chat_list_screen.dart';
import '../features/chat/screens/chat_thread_screen.dart';
import '../models/vendor_model.dart';
import '../features/cart/screens/cart_screen.dart';
import '../features/cart/screens/checkout_screen.dart';
import '../features/cart/screens/my_orders_screen.dart';
import '../features/cart/screens/order_detail_screen.dart';
import '../models/order_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/categories',
        name: 'categories',
        builder: (context, state) => CategoriesScreen(
          selectedCategory: state.uri.queryParameters['name'] ?? 'All',
        ),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/product',
        name: 'product_detail',
        builder: (context, state) => ProductDetailScreen(product: state.extra as Product),
      ),
      GoRoute(
        path: '/vendor',
        name: 'vendor_dashboard',
        builder: (context, state) => const VendorDashboardScreen(),
      ),
      GoRoute(
        path: '/vendor/dashboard',
        name: 'vendor_dashboard_main',
        builder: (context, state) => const VendorDashboardScreen(),
      ),
      GoRoute(
        path: '/vendor/register',
        name: 'vendor_register',
        builder: (context, state) => const VendorRegisterScreen(),
      ),
      GoRoute(
        path: '/vendor/products',
        name: 'vendor_products',
        builder: (context, state) => const VendorProductsScreen(),
      ),
      GoRoute(
        path: '/vendor/products/new',
        name: 'vendor_products_new',
        builder: (context, state) => const VendorProductEditorScreen(),
      ),
      GoRoute(
        path: '/vendor/products/:id/edit',
        name: 'vendor_products_edit',
        builder: (context, state) =>
            VendorProductEditorScreen(product: state.extra as Product?),
      ),
      GoRoute(
        path: '/vendor/orders',
        name: 'vendor_orders',
        builder: (context, state) => const VendorOrdersScreen(),
      ),
      GoRoute(
        path: '/vendor/list',
        name: 'vendor_list',
        builder: (context, state) => const VendorListScreen(),
      ),
      GoRoute(
        path: '/vendor/store/:slug',
        name: 'vendor_storefront',
        builder: (context, state) {
          final vendorModel = state.extra as VendorModel?;
          return VendorStorefrontScreen(
            slug: state.pathParameters['slug']!,
            vendor: vendorModel,
          );
        },
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        name: 'profile_edit',
        builder: (context, state) => const ProfileEditorScreen(),
      ),
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/orders',
        name: 'my_orders',
        builder: (context, state) => const MyOrdersScreen(),
      ),
      GoRoute(
        path: '/orders/:id',
        name: 'order_detail',
        builder: (context, state) =>
            OrderDetailScreen(order: state.extra as OrderModel),
      ),
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/wishlist',
        name: 'wishlist',
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: '/vendor/profile',
        name: 'vendor_profile',
        builder: (context, state) => const VendorProfileEditorScreen(),
      ),
      GoRoute(
        path: '/chat',
        name: 'chat_list',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:id',
        name: 'chat_thread',
        builder: (context, state) => ChatThreadScreen(threadId: int.parse(state.pathParameters['id']!)),
      ),
    ],
  );
});
