import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'login_screen.dart';

class StaffScreen extends StatefulWidget {
  @override
  _StaffScreenState createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  List hospitals = [];
  String selectedHospitalId = 'H001';
  String resultMessage = '';
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchHospitals(isInitial: true); // ✅ FIX: Pass true on initial load
  }

  // ✅ FIX: Added isInitial parameter to prevent resetting selection
  Future<void> fetchHospitals({bool isInitial = false}) async {
    final res = await http.get(Uri.parse('$BASE_URL/hospitals'));
    setState(() {
      hospitals = jsonDecode(res.body);
      // ✅ FIX: Only reset hospital on initial load, not after every call
      if (isInitial && hospitals.isNotEmpty) {
        selectedHospitalId = hospitals[0]['id'];
      }
    });
  }

  Future<void> callNext() async {
    setState(() => loading = true);
    try {
      final res = await http.post(
        Uri.parse('$BASE_URL/queue/next/$selectedHospitalId'),
      );
      final data = jsonDecode(res.body);
      
      setState(() {
        resultMessage = data['called'] != null
            ? 'Called: ${data['called']} | Remaining: ${data['remaining']}'
            : 'Queue is empty!';
        loading = false;
      });
      
      // ✅ FIX: Small delay to ensure backend has updated, then refresh
      await Future.delayed(Duration(milliseconds: 300));
      
      // ✅ FIX: Pass false - don't reset selection when refreshing
      await fetchHospitals(isInitial: false);
      
    } catch (e) {
      setState(() {
        resultMessage = 'Error connecting to server';
        loading = false;
      });
    }
  }

  // After calling next patient, show this dialog:
  void _showPrescriptionDialog(String token, String hospitalId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Prescription for $token'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
              hintText: 'e.g. Paracetamol 500mg, rest...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            child: Text('Skip'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('Mark Complete'),
            onPressed: () async {
              await http.post(
                Uri.parse('$BASE_URL/doctor/complete'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'hospital_id': hospitalId,
                  'token': token,
                  'prescription': controller.text,
                }),
              );
              Navigator.pop(context);
              
              // ✅ FIX: Refresh after marking complete
              await Future.delayed(Duration(milliseconds: 300));
              await fetchHospitals(isInitial: false);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doctor Panel'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
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
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Hospital',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 10),
            DropdownButtonFormField(
              value: selectedHospitalId,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.teal, width: 2),
                ),
              ),
              items: hospitals.map((h) {
                return DropdownMenuItem(
                  value: h['id'] as String,
                  child: Text('${h['name']} (${h['queue_count']} in queue)'),
                );
              }).toList(),
              onChanged: (val) =>
                  setState(() => selectedHospitalId = val as String),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: loading ? null : callNext,
                icon: loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Icon(Icons.arrow_forward),
                label: Text('Start Consultation',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            SizedBox(height: 24),
            if (resultMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.teal),
                ),
                child: Text(
                  resultMessage,
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.teal[800],
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(height: 32),
            Text('Live Queue Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: hospitals.length,
                itemBuilder: (context, index) {
                  final h = hospitals[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Text('${h['queue_count']}',
                          style: TextStyle(color: Colors.white)),
                    ),
                    title: Text(h['name']),
                    subtitle: Text('Wait: ${h['wait_time']} mins'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}