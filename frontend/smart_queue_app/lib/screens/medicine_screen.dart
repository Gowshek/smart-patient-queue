import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class MedicineScreen extends StatefulWidget {
  @override
  _MedicineScreenState createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  List<Map<String, dynamic>> medicines = [];
  int takenCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
    // Check for reminders every minute
    Timer.periodic(Duration(minutes: 1), (_) => _checkReminders());
  }

  Future<void> _loadMedicines() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('medicines') ?? [];
    setState(() {
      medicines = list.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
      takenCount = medicines.where((m) => m['taken'] == true).length;
    });
  }

  Future<void> _addMedicine(String name, String time, String notes) async {
    final prefs = await SharedPreferences.getInstance();
    final med = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'time': time,
      'notes': notes,
      'taken': false,
    };
    final list = prefs.getStringList('medicines') ?? [];
    list.add(jsonEncode(med));
    await prefs.setStringList('medicines', list);
    _loadMedicines();
  }

  Future<void> _toggleTaken(int index) async {
    final prefs = await SharedPreferences.getInstance();
    medicines[index]['taken'] = !medicines[index]['taken'];
    final updated = medicines.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList('medicines', updated);
    _loadMedicines();
  }

  Future<void> _deleteMedicine(int index) async {
    final prefs = await SharedPreferences.getInstance();
    medicines.removeAt(index);
    final updated = medicines.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList('medicines', updated);
    _loadMedicines();
  }

  void _checkReminders() {
    final now = TimeOfDay.now();
    for (int i = 0; i < medicines.length; i++) {
      if (medicines[i]['taken'] == true) continue;
      final parts = medicines[i]['time'].split(':');
      final medTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      if (medTime.hour == now.hour && medTime.minute == now.minute) {
        _showReminderDialog(i);
      }
    }
  }

  void _showReminderDialog(int index) {
    final med = medicines[index];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.local_pharmacy, color: Colors.teal, size: 28),
            SizedBox(width: 10),
            Text('Time to Take Medicine!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('💊 ${med['name']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('🕐 ${med['time']}', style: TextStyle(fontSize: 14, color: Colors.grey)),
            SizedBox(height: 8),
            if (med['notes'].isNotEmpty)
              Text('📝 ${med['notes']}', style: TextStyle(fontSize: 14, color: Colors.orange)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Snooze 30 min'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              _toggleTaken(index);
              Navigator.pop(context);
            },
            child: Text('Mark as Taken', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Medicines'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // Progress bar
          if (medicines.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.teal[50],
              child: Column(
                children: [
                  Text('$takenCount / ${medicines.length} taken today',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: medicines.isEmpty ? 0 : takenCount / medicines.length,
                    backgroundColor: Colors.grey[300],
                    color: Colors.teal,
                    minHeight: 8,
                  ),
                ],
              ),
            ),
          // Medicine list
          Expanded(
            child: medicines.isEmpty
                ? Center(
                    child: Text('No medicines added', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  )
                : ListView.builder(
                    itemCount: medicines.length,
                    itemBuilder: (_, i) {
                      final m = medicines[i];
                      final taken = m['taken'] == true;
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        color: taken ? Colors.green[50] : Colors.white,
                        child: ListTile(
                          leading: Icon(
                            taken ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: taken ? Colors.green : Colors.grey,
                            size: 28,
                          ),
                          title: Text(m['name'],
                              style: TextStyle(
                                decoration: taken ? TextDecoration.lineThrough : null,
                                fontWeight: FontWeight.bold,
                              )),
                          subtitle: Text('${m['time']} • ${m['notes']}'),
                          trailing: taken
                              ? Icon(Icons.done, color: Colors.green)
                              : PopupMenuButton(
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      child: Text('Mark Taken'),
                                      value: 'taken',
                                    ),
                                    PopupMenuItem(
                                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                                      value: 'delete',
                                    ),
                                  ],
                                  onSelected: (val) {
                                    if (val == 'taken') _toggleTaken(i);
                                    if (val == 'delete') _deleteMedicine(i);
                                  },
                                ),
                          onTap: () => _toggleTaken(i),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: Icon(Icons.add),
        onPressed: () => _showAddMedicineDialog(),
      ),
    );
  }

  void _showAddMedicineDialog() {
    final nameController = TextEditingController();
    final notesController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Medicine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Medicine Name', hintText: 'e.g. Paracetamol'),
            ),
            SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.access_time),
              title: Text('Time: ${selectedTime.format(context)}'),
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: selectedTime);
                if (picked != null) selectedTime = picked;
              },
            ),
            SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: InputDecoration(labelText: 'Notes (optional)', hintText: 'e.g. After food'),
            ),
          ],
        ),
        actions: [
          TextButton(child: Text('Cancel'), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                _addMedicine(
                  nameController.text,
                  '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}',
                  notesController.text,
                );
                Navigator.pop(context);
              }
            },
            child: Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}