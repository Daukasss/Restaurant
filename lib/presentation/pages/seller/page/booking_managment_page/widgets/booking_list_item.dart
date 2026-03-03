import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BookingListItem extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onTap;

  const BookingListItem({
    super.key,
    required this.booking,
    required this.onTap,
  });

  String _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return '00:00';
    return timeString;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  DateTime _parseBookingDate(dynamic rawDate) {
    if (rawDate is Timestamp) {
      return rawDate.toDate();
    } else if (rawDate is String) {
      try {
        return DateTime.parse(rawDate);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime bookingDate = _parseBookingDate(booking['booking_date']);
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime bookingDay =
        DateTime(bookingDate.year, bookingDate.month, bookingDate.day);

    final bool isToday = bookingDay.isAtSameMomentAs(today);
    final bool isPast = bookingDay.isBefore(today);

    final startTime = _formatTime(booking['start_time']);
    final endTime = _formatTime(booking['end_time']);

    String dateDisplay;
    Color dateColor = Colors.grey[700]!;
    FontWeight dateWeight = FontWeight.normal;

    if (isToday) {
      dateDisplay = 'Сегодня';
      dateColor = Colors.green[800]!;
      dateWeight = FontWeight.w600;
    } else if (isPast) {
      dateDisplay = _formatDate(bookingDate);
      dateColor = Colors.grey[500]!;
    } else {
      dateDisplay = _formatDate(bookingDate);
    }

    final String displayStatus =
        isToday ? 'today' : (booking['status']?.toString() ?? 'pending');

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      booking['name']?.toString() ?? 'Без имени',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getStatusColor(displayStatus),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _getStatusText(displayStatus),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Дата + время
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 17,
                    color: dateColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateDisplay,
                    style: TextStyle(
                      color: dateColor,
                      fontWeight: dateWeight,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Icon(
                    Icons.access_time_rounded,
                    size: 17,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$startTime – $endTime',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                      fontSize: 14.5,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Icon(
                    Icons.people_rounded,
                    size: 17,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${booking['guests'] ?? '?'} гость',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Icon(
                    Icons.phone_rounded,
                    size: 17,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      booking['phone']?.toString() ?? '—',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'today':
        return Colors.green[800]!;
      case 'completed':
        return Colors.green[700]!;
      case 'pending':
        return Colors.orange[800]!;
      case 'cancelled':
        return Colors.red[700]!;
      default:
        return Colors.grey[500]!;
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'today':
        return 'Сегодня';
      case 'completed':
        return 'Прошедший';
      case 'pending':
        return 'Ожидается';
      case 'cancelled':
        return 'Отменён';
      default:
        return status ?? '—';
    }
  }
}
