import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import 'login_screen.dart';
import 'book_appointment_screen.dart';
import 'qr_scanner_screen.dart';
import 'medicine_screen.dart';

class HomeScreen extends StatefulWidget {
  final String patientName;
  final String patientPhone;

  HomeScreen({required this.patientName, required this.patientPhone});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List hospitals = [];

  @override
  void initState() {
    super.initState();
    fetchHospitals();
  }

  Future<void> fetchHospitals() async {
    try {
      final res = await http.get(Uri.parse('$BASE_URL/hospitals'));
      setState(() {
        hospitals = jsonDecode(res.body);
      });
    } catch (e) {
      print('Error fetching hospitals: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Hello, ${widget.patientName} 👋'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.local_hospital), text: 'Queue'),
              Tab(icon: Icon(Icons.local_pharmacy), text: 'Medicines'),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              ),
            )
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Hospital Queue List
            _buildQueueTab(),
            // Tab 2: Medicine Reminders
            MedicineScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueTab() {
    return hospitals.isEmpty
        ? Center(
            child: CircularProgressIndicator(),
          )
        : RefreshIndicator(
            onRefresh: fetchHospitals,
            child: ListView.builder(
              itemCount: hospitals.length,
              itemBuilder: (context, index) {
                final hospital = hospitals[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hospital Name
                        Text(
                          hospital['name'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[800],
                          ),
                        ),
                        SizedBox(height: 12),
                        // Queue Info
                        Row(
                          children: [
                            Icon(Icons.people, color: Colors.teal, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Queue: ${hospital['queue_count']} patients',
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.orange, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Est. Wait: ${hospital['wait_time']} mins',
                              style: TextStyle(fontSize: 14, color: Colors.orange),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookAppointmentScreen(
                                    patientName: widget.patientName,
                                    phone: widget.patientPhone,
                                    hospitalId: hospital['id'],
                                    hospitalName: hospital['name'],
                                  ),
                                ),
                              ),
                              child: Text('Book Appointment'),
                            ),
                            IconButton(
                              icon: Icon(Icons.qr_code_scanner, color: Colors.teal),
                              tooltip: 'QR Check-in',
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => QRScannerScreen(
  hospitalId: hospital['id'],
  hospitalName: hospital['name'],
)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
  }
}