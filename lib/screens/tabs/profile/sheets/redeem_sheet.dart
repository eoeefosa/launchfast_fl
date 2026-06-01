import 'package:flutter/material.dart';
import 'package:campuschow/repositories/wallet_repository.dart';
import 'package:campuschow/screens/auth/widgets/apptextfield.dart';
import 'package:campuschow/screens/auth/widgets/custom_button.dart';
import 'package:campuschow/services/api_service.dart';
import 'package:campuschow/store/lib/core/services/notification_service.dart';
import 'package:campuschow/utils/ui_utils.dart';
import 'package:campuschow/widgets/pin_entry_sheet.dart';
import 'package:campuschow/widgets/set_pin_sheet.dart';
import 'package:provider/provider.dart';
import 'package:campuschow/providers/auth_provider.dart';

class RedeemSheet extends StatefulWidget {
  const RedeemSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const RedeemSheet(),
    );
  }

  @override
  State<RedeemSheet> createState() => _RedeemSheetState();
}

class _RedeemSheetState extends State<RedeemSheet> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  // Notification settings
  bool _dailyEnabled = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 12, minute: 0);
  int _windowMinutes = 30;
  static const int _kDailyReminderId = 9001;
  int _streak = 0;
  bool _adaptiveEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final enabled = await notificationService.isDailyReminderEnabled();
      final cfg = await notificationService.getDailyReminderConfig();
      final streak = await notificationService.getReminderStreak();
      final adaptive = await notificationService.isAdaptiveEnabled();
      setState(() {
        _dailyEnabled = enabled;
        _selectedTime = TimeOfDay(hour: cfg['hour']!, minute: cfg['minute']!);
        _windowMinutes = cfg['window']!;
        _streak = streak;
        _adaptiveEnabled = adaptive;
      });
    } catch (_) {}
  }

  Future<void> _onRedeemPressed() async {
    if (_codeController.text.isEmpty) return;

    final auth = context.read<AuthProvider>();

    if (!(auth.user?.hasTransactionPin ?? false)) {
      final pinSet = await SetPinSheet.show(context);
      if (!mounted || !pinSet) return;
    }

    final confirmed = await PinEntrySheet.show(
      context,
      title: 'Enter Transaction PIN',
      onSubmit: (pin) => WalletRepository().verifyTransactionPin(pin),
    );
    if (!mounted || !confirmed) return;

    _redeem(auth);
  }

  Future<void> _redeem(AuthProvider auth) async {
    setState(() => _isLoading = true);
    try {
      final newBalance = await WalletRepository().redeemGiftCard(_codeController.text.trim());
      if (!mounted) return;

      if (newBalance != null) {
        auth.updateWalletBalance(newBalance);
      } else {
        auth.refreshUser();
      }

      notificationService.showNotification(
        title: 'Gift Card Redeemed',
        body: 'Your gift card has been redeemed and your wallet has been credited.',
        payload: 'gift_card_redeem',
      );

      Navigator.pop(context);
      UIUtils.showSuccessDialog(context, 'Success', 'Gift card redeemed successfully');
    } catch (e) {
      if (mounted) UIUtils.showErrorDialog(context, 'Redemption Failed', ApiService.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20, left: 20, right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Redeem Gift Card', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          AppTextField(controller: _codeController, hint: 'Gift Card Code', icon: Icons.card_giftcard),
          const SizedBox(height: 20),
          CustomButton(
            label: 'Redeem',
            isLoading: _isLoading,
            onPressed: _onRedeemPressed,
            primaryColor: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          // Daily gentle reminders UI
          SwitchListTile(
            title: const Text('Daily gentle reminders'),
            subtitle: const Text('Quiet daily nudge with deals and fresh picks'),
            value: _dailyEnabled,
            onChanged: (v) async {
              setState(() => _dailyEnabled = v);
              if (v) {
                await notificationService.scheduleDailyReminder(
                  id: _kDailyReminderId,
                  hour: _selectedTime.hour,
                  minute: _selectedTime.minute,
                  windowMinutes: _windowMinutes,
                  title: 'Today on CampusChow',
                  body: 'Tap to see fresh picks and limited-time deals.',
                  payload: 'reminders_daily',
                );
              } else {
                await notificationService.cancelReminder(_kDailyReminderId);
              }
            },
          ),
          if (_dailyEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Time: ${_selectedTime.format(context)}'),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime,
                          );
                          if (t != null) {
                            setState(() => _selectedTime = t);
                            // reschedule
                            await notificationService.scheduleDailyReminder(
                              id: _kDailyReminderId,
                              hour: _selectedTime.hour,
                              minute: _selectedTime.minute,
                              windowMinutes: _windowMinutes,
                              title: 'Today on CampusChow',
                              body: 'Tap to see fresh picks and limited-time deals.',
                              payload: 'reminders_daily',
                            );
                          }
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Randomize within $_windowMinutes minutes to stay gentle'),
                  Slider(
                    min: 0,
                    max: 60,
                    divisions: 12,
                    value: _windowMinutes.toDouble(),
                    label: '$_windowMinutes',
                    onChanged: (v) async {
                      setState(() => _windowMinutes = v.toInt());
                    },
                    onChangeEnd: (v) async {
                      if (_dailyEnabled) {
                        await notificationService.scheduleDailyReminder(
                          id: _kDailyReminderId,
                          hour: _selectedTime.hour,
                          minute: _selectedTime.minute,
                          windowMinutes: _windowMinutes,
                          title: 'Today on CampusChow',
                          body: 'Tap to see fresh picks and limited-time deals.',
                          payload: 'reminders_daily',
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Streak:'),
                      const SizedBox(width: 8),
                      Chip(label: Text('$_streak days')),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () async {
                          final impressions = await notificationService.getAnalyticsImpressions();
                          final opens = await notificationService.getAnalyticsOpens();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Analytics — impressions: $impressions, opens: $opens')),
                          );
                        },
                        child: const Text('View stats'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Adaptive timing'),
                    subtitle: const Text('Automatically shift reminders to when you usually open them'),
                    value: _adaptiveEnabled,
                    onChanged: (v) async {
                      setState(() => _adaptiveEnabled = v);
                      await notificationService.setAdaptiveEnabled(v);
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
