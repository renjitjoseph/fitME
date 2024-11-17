import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarPopup extends StatefulWidget {
  @override
  _CalendarPopupState createState() => _CalendarPopupState();
}

class _CalendarPopupState extends State<CalendarPopup> {
  DateTime _focusedDate = DateTime(2024, 8, 15); // Set a mid-month date to ensure the month is centered
  DateTime? _selectedDate; // No date is selected initially
  Map<DateTime, List<dynamic>> _events = {};

  @override
  void initState() {
    super.initState();
    _fetchFavoritedDates();
  }

  Future<void> _fetchFavoritedDates() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await userDoc.collection('favorites').get();

    Map<DateTime, List<dynamic>> events = {};
    for (var doc in snapshot.docs) {
      try {
        if (doc.data().containsKey('dateSaved')) {
          DateTime favoritedDate = (doc['dateSaved'] as Timestamp).toDate();
          DateTime normalizedDate = DateTime(favoritedDate.year, favoritedDate.month, favoritedDate.day);

          if (events.containsKey(normalizedDate)) {
            events[normalizedDate]!.add(doc.data());
          } else {
            events[normalizedDate] = [doc.data()];
          }
        }
      } catch (e) {
        print('Error processing document ${doc.id}: $e');
        // Handle any specific logging or error handling as needed
      }
    }

    setState(() {
      _events = events;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TableCalendar(
              focusedDay: _focusedDate,
              firstDay: DateTime(2000),
              lastDay: DateTime(2050),
              calendarFormat: CalendarFormat.month,  // Set default format to month
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',  // Only allow month view
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: false, // Hide the format button
                titleCentered: true, // Center the title
              ),
              selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
              eventLoader: (day) {
                DateTime normalizedDay = DateTime(day.year, day.month, day.day);
                return _events[normalizedDay] ?? [];
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDate = selectedDay;
                  _focusedDate = focusedDay; // Update focused day when a new day is selected
                });
                Navigator.of(context).pop(_selectedDate);
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      bottom: 1, // Move the dot to the middle bottom
                      child: _buildMarker(date, events),
                    );
                  }
                  return Container();
                },
              ),
            ),
            SizedBox(height: 8.0),
            ElevatedButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarker(DateTime date, List<dynamic> events) {
    return Container(
      width: 7.0,
      height: 7.0,
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        shape: BoxShape.circle,
      ),
    );
  }
}
