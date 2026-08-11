import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class QueueTrackerScreen extends StatefulWidget {
  final String hospitalId;
  final String hospitalName;
  final String patientId;
  final int initialPosition;
  final String initialWait;

  QueueTrackerScreen({
    required this.hospitalId,
    required this.hospitalName,
    required this.patientId,
    required this.initialPosition,
    required this.initialWait,
  });

  @override
  _QueueTrackerScreenState createState() => _QueueTrackerScreenState();
}

class _QueueTrackerScreenState extends State<QueueTrackerScreen> {
  int position = 0;
  String waitTime = '';
  int totalInQueue = 0;
  bool served = false;
  Timer? pollingTimer;

  @override
  void initState() {
    super.initState();
    position = widget.initialPosition;
    waitTime = widget.initialWait;

    pollingTimer = Timer.periodic(Duration(seconds: 5), (_) {
      _checkPosition();
    });
  }

  Future<void> _checkPosition() async {
    try {
      final res = await http.get(
        Uri.parse('$BASE_URL/queue/status/${widget.hospitalId}/${widget.patientId}'),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data['status'] == 'done') {
          pollingTimer?.cancel();
          setState(() => served = true);
          _showCalledAlert();
          return;
        }

        setState(() {
          position = data['position'];
          waitTime = data['wait_time'];
          totalInQueue = data['total_in_queue'];
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  void _showCalledAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('Your Turn!', style: TextStyle(color: Colors.teal)),
        content: Text('Please proceed to the counter now.'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text('Done', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    pollingTimer?.cancel();
    super.dispose();
  }

  Color get _positionColor {
    if (position <= 2) return Colors.green;
    if (position <= 5) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hospitalName),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: served
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 80),
                  SizedBox(height: 16),
                  Text('You have been served!',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Your Queue Position',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  SizedBox(height: 16),
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _positionColor, width: 6),
                    ),
                    child: Center(
                      child: Text(
                        '$position',
                        style: TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: _positionColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Estimated Wait:', style: TextStyle(fontSize: 16)),
                              Text(waitTime,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal)),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Patient ID:', style: TextStyle(fontSize: 16)),
                              Text(widget.patientId,
                                  style: TextStyle(fontSize: 14, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 12, height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.teal),
                      ),
                      SizedBox(width: 8),
                      Text('Updating every 5 seconds...',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}