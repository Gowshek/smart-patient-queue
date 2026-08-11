import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'queue_tracker_screen.dart';

class QRScannerScreen extends StatefulWidget {
  final String hospitalId;
  final String hospitalName;

  QRScannerScreen({required this.hospitalId, required this.hospitalName});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool scanned = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR — ${widget.hospitalName}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) async {
          if (scanned) return;
          scanned = true;

          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final qrText = barcode.rawValue ?? '';
            final parts = qrText.split('|');
            
            if (parts.length != 2) {
              _showError('Invalid QR code. Please scan a hospital QR.');
              return;
            }

            final hospitalId = parts[1];
            await _checkIn(hospitalId);
            break;
          }
        },
      ),
    );
  }

  Future<void> _checkIn(String hospitalId) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/checkin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'hospital_id': hospitalId,
          'patient_id': 'P_${DateTime.now().millisecondsSinceEpoch}',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QueueTrackerScreen(
              hospitalId: hospitalId,
              hospitalName: data['hospital_name'],
              patientId: data['patient_id'],
              initialPosition: data['position'],
              initialWait: data['wait_time'],
            ),
          ),
        );
      } else {
        _showError('Check-in failed. Try again.');
      }
    } catch (e) {
      _showError('Cannot connect to server. Check WiFi.');
    }
  }

  void _showError(String msg) {
    setState(() => scanned = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }
}