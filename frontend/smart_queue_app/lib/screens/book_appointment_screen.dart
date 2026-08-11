import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import 'queue_tracker_screen.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String patientName;
  final String phone;
  final String hospitalId;
  final String hospitalName;

  BookAppointmentScreen({
    required this.patientName,
    required this.phone,
    required this.hospitalId,
    required this.hospitalName,
  });

  @override
  _BookAppointmentScreenState createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  bool _loading = false;
  Map<String, dynamic>? _bookingResult;

  Future<void> _bookAppointment() async {
    setState(() => _loading = true);
    final res = await http.post(
      Uri.parse('$BASE_URL/appointment/book'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'hospital_id': widget.hospitalId,
        'patient_name': widget.patientName,
        'phone': widget.phone,
      }),
    );
    final data = jsonDecode(res.body);
    setState(() {
      _loading = false;
      _bookingResult = data;
    });
  }

  @override
  void initState() {
    super.initState();
    _bookAppointment();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Appointment Booked'), backgroundColor: Colors.teal),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _bookingResult == null
              ? Center(child: Text('Booking failed'))
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 80),
                      SizedBox(height: 16),
                      Text('Appointment Confirmed!',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 24),
                      // Token Card
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text('Your Token', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            Text(_bookingResult!['token'],
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 4)),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(_bookingResult!['hospital_name'],
                          style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                      Text('Queue Position: ${_bookingResult!['position']}',
                          style: TextStyle(fontSize: 16)),
                      Text('Est. Wait: ${_bookingResult!['wait_time']}',
                          style: TextStyle(fontSize: 16, color: Colors.orange)),
                      SizedBox(height: 32),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QueueTrackerScreen(
                              hospitalId: widget.hospitalId,
                              patientId: _bookingResult!['token'],
                              hospitalName: _bookingResult!['hospital_name'],
                              initialPosition: _bookingResult!['position'],
                              initialWait: _bookingResult!['wait_time'],
                            ),
                          ),
                        ),
                        child: Text('Track My Queue', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
    );
  }
}