part of '../view/booking_page.dart';

// ─────────────────────────────────────────────
//  DATE MANAGEMENT PAGE (Seller Tab 2)
// ─────────────────────────────────────────────
class DateManagementPage extends StatelessWidget {
  final String restaurantId;

  const DateManagementPage({required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    // Делегируем весь UI в отдельный виджет SellerDateManagementPage
    return SellerDateManagementPage(restaurantId: restaurantId);
  }
}
