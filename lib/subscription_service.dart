import 'package:supabase_flutter/supabase_flutter.dart';

enum SubscriptionGateStatus { expired, warning, valid, error }

class SubscriptionGateResult {
  final SubscriptionGateStatus status;
  final int daysRemaining;
  final String? errorMessage;

  const SubscriptionGateResult({
    required this.status,
    required this.daysRemaining,
    this.errorMessage,
  });
}

class SubscriptionService {
  final SupabaseClient _supabase;

  const SubscriptionService(this._supabase);

  Future<SubscriptionGateResult> checkSubscriptionGate({
    required String pharmacyId,
    int warningDays = 5,
  }) async {
    try {
      final row = await _supabase
          .from('pharmacies')
          .select('subscription_status, subscription_end_date')
          .eq('id', pharmacyId)
          .maybeSingle();

      if (row == null) {
        return const SubscriptionGateResult(
          status: SubscriptionGateStatus.error,
          daysRemaining: 0,
          errorMessage:
              'Unable to read subscription record. Check pharmacy mapping or RLS policy.',
        );
      }

      final statusRaw = (row['subscription_status'] ?? '').toString().trim();
      final normalizedStatus = statusRaw.toLowerCase();

      if (normalizedStatus == 'expired') {
        return const SubscriptionGateResult(
          status: SubscriptionGateStatus.expired,
          daysRemaining: 0,
        );
      }

      final endDateRaw = row['subscription_end_date'];
      if (endDateRaw == null) {
        return const SubscriptionGateResult(
          status: SubscriptionGateStatus.error,
          daysRemaining: 0,
          errorMessage:
              'subscription_end_date is missing for this pharmacy. Please contact admin.',
        );
      }

      final endDate = DateTime.parse(endDateRaw.toString()).toLocal();
      final now = DateTime.now();

      final endDay = DateTime(endDate.year, endDate.month, endDate.day);
      final nowDay = DateTime(now.year, now.month, now.day);
      final daysRemaining = endDay.difference(nowDay).inDays;

      if (daysRemaining <= 0) {
        return SubscriptionGateResult(
          status: SubscriptionGateStatus.expired,
          daysRemaining: daysRemaining,
        );
      }

      if (daysRemaining <= warningDays) {
        return SubscriptionGateResult(
          status: SubscriptionGateStatus.warning,
          daysRemaining: daysRemaining,
        );
      }

      return SubscriptionGateResult(
        status: SubscriptionGateStatus.valid,
        daysRemaining: daysRemaining,
      );
    } catch (e) {
      return SubscriptionGateResult(
        status: SubscriptionGateStatus.error,
        daysRemaining: 0,
        errorMessage: 'Subscription check failed: $e',
      );
    }
  }
}
