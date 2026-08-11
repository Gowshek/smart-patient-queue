from flask import Flask, request, jsonify
from fake_data import hospitals, preload_patients
import time, uuid
from flask import Flask
from flask_cors import CORS

import sqlite3, os

app = Flask(__name__)
CORS(app)  

DB_PATH = 'queue.db'

def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS appointments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_name TEXT,
        phone TEXT,
        hospital_id TEXT,
        token TEXT,
        status TEXT DEFAULT 'waiting',
        prescription TEXT DEFAULT '',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )''')
    conn.commit()
    conn.close()

init_db()

# ✅ FIX: Helper function to ensure queue_count is accurate
def get_hospital_queue_count(hospital_id):
    """Get the accurate queue count from in-memory queue"""
    if hospital_id not in hospitals:
        return 0
    return len(hospitals[hospital_id]['queue'])

# ✅ FIX: Helper function to calculate position
def get_patient_position(hospital_id, patient_id):
    """Get accurate position of a specific patient in queue"""
    if hospital_id not in hospitals:
        return None
    
    queue = hospitals[hospital_id]['queue']
    for i, p in enumerate(queue):
        if p['patient_id'] == patient_id:
            return i + 1  # Position is 1-indexed
    return None

# Route 5: Book Appointment (generates token)
@app.route('/appointment/book', methods=['POST'])
def book_appointment():
    data = request.json
    hospital_id = data.get('hospital_id')
    patient_name = data.get('patient_name', 'Patient')
    phone = data.get('phone', '')

    if hospital_id not in hospitals:
        return jsonify({'error': 'Hospital not found'}), 404

    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("INSERT INTO appointments (patient_name, phone, hospital_id, token, status) VALUES (?,?,?,?,?)",
              (patient_name, phone, hospital_id, '', 'waiting'))
    appt_id = c.lastrowid
    token = f"TKN-{appt_id:03d}"
    c.execute("UPDATE appointments SET token=? WHERE id=?", (token, appt_id))
    conn.commit()
    conn.close()

    # ✅ FIX: Add to in-memory queue with proper structure
    hospitals[hospital_id]['queue'].append({
        'patient_id': token, 
        'checkin_time': time.time()
    })
    
    position = get_patient_position(hospital_id, token)
    queue_count = get_hospital_queue_count(hospital_id)

    return jsonify({
        'token': token,
        'patient_name': patient_name,
        'hospital_name': hospitals[hospital_id]['name'],
        'position': position,
        'wait_time': f'{position * 5} minutes',
        'total_in_queue': queue_count
    })

# Route 6: Doctor marks consultation done + optional prescription
@app.route('/doctor/complete', methods=['POST'])
def complete_consultation():
    data = request.json
    hospital_id = data.get('hospital_id')
    token = data.get('token')
    prescription = data.get('prescription', '')

    if hospital_id not in hospitals:
        return jsonify({'error': 'Hospital not found'}), 404

    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("UPDATE appointments SET status='completed', prescription=? WHERE token=? AND hospital_id=?",
              (prescription, token, hospital_id))
    conn.commit()
    conn.close()

    # ✅ FIX: Properly remove from in-memory queue
    queue = hospitals[hospital_id]['queue']
    original_length = len(queue)
    hospitals[hospital_id]['queue'] = [p for p in queue if p['patient_id'] != token]
    
    removed = original_length > len(hospitals[hospital_id]['queue'])

    return jsonify({
        'message': f'{token} consultation marked complete', 
        'prescription': prescription,
        'removed': removed,
        'remaining': len(hospitals[hospital_id]['queue'])
    })

# Route 7: View appointment history for a patient
@app.route('/appointments/history/<phone>', methods=['GET'])
def appointment_history(phone):
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("SELECT token, hospital_id, status, prescription, created_at FROM appointments WHERE phone=? ORDER BY created_at DESC", (phone,))
    rows = c.fetchall()
    conn.close()
    result = [{'token': r[0], 'hospital_id': r[1], 'hospital_name': hospitals.get(r[1], {}).get('name', r[1]),
               'status': r[2], 'prescription': r[3], 'date': r[4]} for r in rows]
    return jsonify(result)

# Allow all connections

preload_patients()

# Route 1: List all hospitals
@app.route('/hospitals', methods=['GET'])
def get_hospitals():                  
    result = []
    for hid, h in hospitals.items():
        # ✅ FIX: Use helper function for accurate count
        queue_count = get_hospital_queue_count(hid)
        result.append({
            'id': hid,
            'name': h['name'],
            'queue_count': queue_count,
            'wait_time': queue_count * 5
        })
    return jsonify(result)

# Route 2: Patient checks in via QR scan
@app.route('/checkin', methods=['POST'])
def checkin():
    data = request.json
    hospital_id = data.get('hospital_id')
    patient_id = data.get('patient_id', str(uuid.uuid4())[:8])

    if hospital_id not in hospitals:
        return jsonify({'error': 'Hospital not found'}), 404

    queue = hospitals[hospital_id]['queue']
    queue.append({'patient_id': patient_id, 'checkin_time': time.time()})

    position = get_patient_position(hospital_id, patient_id)
    queue_count = get_hospital_queue_count(hospital_id)
    
    return jsonify({
        'patient_id': patient_id,
        'hospital_name': hospitals[hospital_id]['name'],
        'position': position,
        'wait_time': f'{position * 5} minutes',
        'total_in_queue': queue_count
    })

# Route 3: Patient polls for their current position
@app.route('/queue/status/<hospital_id>/<patient_id>', methods=['GET'])
def queue_status(hospital_id, patient_id):
    if hospital_id not in hospitals:
        return jsonify({'error': 'Hospital not found'}), 404

    # ✅ FIX: Use helper function for accurate position
    position = get_patient_position(hospital_id, patient_id)
    queue_count = get_hospital_queue_count(hospital_id)

    if position is None:
        return jsonify({
            'status': 'done', 
            'message': 'You have been served!',
            'total_in_queue': queue_count
        })

    return jsonify({
        'position': position,
        'wait_time': f'{position * 5} minutes',
        'total_in_queue': queue_count
    })

# Route 4: Staff clicks "Next" to move queue
@app.route('/queue/next/<hospital_id>', methods=['POST'])
def next_patient(hospital_id):
    if hospital_id not in hospitals:
        return jsonify({'error': 'Hospital not found'}), 404

    queue = hospitals[hospital_id]['queue']
    if queue:
        called = queue.pop(0)  # ✅ FIX: Removes from actual queue
        remaining = len(queue)
        return jsonify({
            'called': called['patient_id'],
            'remaining': remaining
        })
    return jsonify({
        'message': 'Queue is empty',
        'called': None,
        'remaining': 0
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)