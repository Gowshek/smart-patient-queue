import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'staff_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRole = 'patient';
  bool _loading = false;

  final Map<String, String> _staffCredentials = {
    'admin': '1234',
    'staff': '0000',
  };

  void _login() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _loading = true);

    Future.delayed(Duration(seconds: 1), () {
      setState(() => _loading = false);

      if (_selectedRole == 'staff') {
        if (_staffCredentials.containsKey(name) &&
            _staffCredentials[name] == phone) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => StaffScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid staff credentials'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(patientName: name, patientPhone: phone),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.local_hospital, size: 72, color: Colors.teal),
                    SizedBox(height: 12),
                    Text(
                      'Smart Queue',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    Text(
                      'Skip the wait, not the care',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 48),
              Text('Login as', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRole = 'patient'),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _selectedRole == 'patient'
                              ? Colors.teal
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.teal),
                        ),
                        child: Center(
                          child: Text(
                            'Patient',
                            style: TextStyle(
                              color: _selectedRole == 'patient'
                                  ? Colors.white
                                  : Colors.teal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRole = 'staff'),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _selectedRole == 'staff'
                              ? Colors.teal
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.teal),
                        ),
                        child: Center(
                          child: Text(
                            'Staff',
                            style: TextStyle(
                              color: _selectedRole == 'staff'
                                  ? Colors.white
                                  : Colors.teal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 28),
              Text(
                _selectedRole == 'patient' ? 'Full Name' : 'Staff Username',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: _selectedRole == 'patient'
                      ? 'Enter your name'
                      : 'Enter username',
                  prefixIcon: Icon(Icons.person, color: Colors.teal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.teal, width: 2),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                _selectedRole == 'patient' ? 'Phone Number' : 'Password',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                obscureText: _selectedRole == 'staff',
                keyboardType: _selectedRole == 'patient'
                    ? TextInputType.phone
                    : TextInputType.text,
                decoration: InputDecoration(
                  hintText: _selectedRole == 'patient'
                      ? 'Enter phone number'
                      : 'Enter password',
                  prefixIcon: Icon(
                    _selectedRole == 'patient' ? Icons.phone : Icons.lock,
                    color: Colors.teal,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.teal, width: 2),
                  ),
                ),
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _loading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: Text(
                  _selectedRole == 'staff'
                      ? 'Demo: username: admin  password: 1234'
                      : 'Demo: enter any name and phone number',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}