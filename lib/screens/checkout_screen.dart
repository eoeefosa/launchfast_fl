import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../models/order.dart';
import '../widgets/home/location_selector.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isPriority = false;
  bool _isSuccess = false;

  String _deliveryTime = "Deliver now (25–35 mins)";
  String _paymentMethod = "Wallet";

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final auth = context.read<AuthProvider>();

    const double priorityFee = 1000;
    final total = cart.cartTotal + (_isPriority ? priorityFee : 0);
    final hasQueuedItems = cart.items.any((i) => !i.menuItem.isReady);

    if (_isSuccess) {
      return const Scaffold(
        body: Center(child: Text("✅ Order placed successfully")),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _appBar(),

              SliverToBoxAdapter(
                child: _sectionCard(
                  title: "Deliver to",
                  child: const LocationSelector(),
                ),
              ),

              SliverToBoxAdapter(
                child: _sectionCard(
                  title: "Delivery time",
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text(_deliveryTime),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showTimeSheet,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: _sectionCard(
                  title: "Payment",
                  child: ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: Text(_paymentMethod),
                    subtitle: const Text("Tap to change"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showPaymentSheet,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: _sectionCard(
                  title: "Order Summary",
                  child: ExpansionTile(
                    title: Text("${cart.totalQuantity} Items"),
                    children: [
                      ...cart.items.map((item) => ListTile(
                            title: Text(item.menuItem.name),
                            trailing: Text("₦${item.totalPrice}"),
                          )),
                      const Divider(),
                      _row("Subtotal", cart.subTotal),
                      _row("Delivery", cart.deliveryFees),
                      _row("Service", cart.serviceFees),
                      if (_isPriority) _row("Priority", priorityFee),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          _bottomBar(total, cart, orderProvider, auth, hasQueuedItems),
        ],
      ),
    );
  }

  SliverAppBar _appBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.black),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        "Review & Place Order",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black12)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  void _showTimeSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text("Deliver now"),
            onTap: () {
              setState(() {
                _deliveryTime = "Deliver now (25–35 mins)";
                _isPriority = false;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text("Schedule delivery"),
            onTap: () {
              setState(() {
                _deliveryTime = "Scheduled";
                _isPriority = true;
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showPaymentSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text("Wallet"),
            onTap: () {
              setState(() => _paymentMethod = "Wallet");
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text("Pay on Delivery"),
            onTap: () {
              setState(() => _paymentMethod = "Cash");
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _row(String label, double value) {
    return ListTile(
      title: Text(label),
      trailing: Text("₦${value.toStringAsFixed(0)}"),
    );
  }

  Widget _bottomBar(double total, CartProvider cart,
      OrderProvider orderProvider, AuthProvider auth, bool hasQueuedItems) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Total"),
                  Text("₦${total.toStringAsFixed(0)}",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: orderProvider.isLoading
                  ? null
                  : () async {
                      if (!auth.isAuthenticated) {
                        context.push('/login');
                        return;
                      }

                      final orderData = {
                        'items': cart.items.map((i) => i.toJson()).toList(),
                        'total': total,
                        'isPriority': _isPriority,
                        'userId': auth.user!.id,
                      };

                      final Order? success =
                          await orderProvider.placeOrder(orderData);

                      if (success != null) {
                        setState(() => _isSuccess = true);
                        cart.clearCart();
                      }
                    },
              child: orderProvider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(hasQueuedItems
                      ? "Join Queue & Pay Later"
                      : "Place Order & Pay Now"),
            )
          ],
        ),
      ),
    );
  }
}
