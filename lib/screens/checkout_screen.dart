import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../models/order.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isPriority = false;
  bool _isSuccess = false;
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user.name;
      _addressController.text = user.address ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final authProvider = context.read<AuthProvider>();

    const double priorityFee = 1000.0;
    final double finalTotal =
        cartProvider.cartTotal + (_isPriority ? priorityFee : 0);
    final bool hasQueuedItems = cartProvider.items.any(
      (i) => !i.menuItem.isReady,
    );

    if (_isSuccess) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    hasQueuedItems ? Icons.access_time : Icons.check,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  hasQueuedItems ? "Joined Queue!" : "Order Placed!",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  hasQueuedItems
                      ? "Your queued items will be prepared soon. You will be notified to pay when they are ready."
                      : "Your food is being prepared and will be delivered soon.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    context.go('/orders');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Track Order',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close),
        ),
        elevation: 0,
        shadowColor: Colors.white,
        surfaceTintColor: Colors.white,
        // scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.green),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInputField(
              controller: _nameController,
              hint: 'Your Name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
            _buildInputField(
              controller: _addressController,
              hint: 'Select Location',
              icon: Icons.location_on_outlined,
              readOnly: true,
              onTap: () => _showLocationPicker(context),
            ),
            const Text(
              'Delivery Options',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildOptionCard(
                    icon: Icons.bolt_rounded,
                    title: 'Instant',
                    subtitle: '25-35 mins',
                    isActive: !_isPriority,
                    onTap: () => setState(() => _isPriority = false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOptionCard(
                    icon: Icons.calendar_today_rounded,
                    title: 'Schedule',
                    subtitle: 'Later today',
                    isActive: _isPriority, // Using priority as a proxy for scheduled for now
                    onTap: () => setState(() => _isPriority = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 16),
            _buildPaymentCard(
              icon: Icons.account_balance_wallet_rounded,
              title: 'LanchFast Wallet',
              subtitle: 'Balance: ₦12,500',
              isActive: true,
            ),
            const SizedBox(height: 12),
            _buildPaymentCard(
              icon: Icons.credit_card_rounded,
              title: 'Mastercard',
              subtitle: '**** 4432',
              isActive: false,
            ),
            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Subtotal', cartProvider.subTotal),
                  _buildSummaryRow('Delivery Fees', cartProvider.deliveryFees),
                  _buildSummaryRow('Service Charges', cartProvider.serviceFees),
                  if (_isPriority)
                    _buildSummaryRow('Priority Fee', priorityFee),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        hasQueuedItems ? "Amount to Pay Later" : "Total to Pay",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₦${finalTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).padding.bottom + 20,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        child: ElevatedButton(
          onPressed: orderProvider.isLoading
              ? null
              : () async {
                  if (!authProvider.isAuthenticated) {
                    _showLoginRequiredDialog(context);
                    return;
                  }

                  final orderData = {
                    'items': cartProvider.items.map((i) => i.toJson()).toList(),
                    'total': finalTotal,
                    'stores': cartProvider.items
                        .map((i) => i.menuItem.storeId)
                        .toSet()
                        .toList(),
                    'isPriority': _isPriority,
                    'userId': authProvider.user!.id,
                    'date': DateTime.now().toIso8601String(),
                    'status': 'Queued',
                  };

                  final Order? success;
                  if (cartProvider.editingOrderId != null) {
                    success = await orderProvider.updateOrder(
                      cartProvider.editingOrderId!,
                      orderData,
                    );
                  } else {
                    success = await orderProvider.placeOrder(orderData);
                  }

                  if (success != null) {
                    setState(() => _isSuccess = true);
                    cartProvider.clearCart();
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: orderProvider.isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  cartProvider.editingOrderId != null
                      ? "Update Order"
                      : (hasQueuedItems ? "Join Queue" : "Place Order"),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  void _showLocationPicker(BuildContext context) {
    final locations = [
      'Hall 1',
      'Hall 2',
      'Hall 3',
      'Hall 4',
      'Hall 5',
      'Hall 6',
      'Hall 7',
      'Hall 8',
      'Faculty',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Delivery Location',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: locations.length,
                itemBuilder: (context, index) {
                  final loc = locations[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(loc, style: const TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      _addressController.text = loc;
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              onTap: onTap,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.black : Colors.grey[200]!,
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.black,
              size: 24,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: isActive ? Colors.white70 : Colors.grey[500],
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? Colors.black : Colors.grey[100]!,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.black, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            const Icon(Icons.check_circle_rounded, color: Colors.black)
          else
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[200]!, width: 2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Text(
            '₦${value.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Required'),
        content: const Text(
          'Please log in or create an account to place your order.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/login');
            },
            child: const Text('Login / Sign Up'),
          ),
        ],
      ),
    );
  }
}
