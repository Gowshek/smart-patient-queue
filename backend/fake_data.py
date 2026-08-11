hospitals = {
    'H001': {'name': 'Apollo Hospital', 'queue': []},
    'H002': {'name': 'Fortis Hospital', 'queue': []},
    'H003': {'name': 'Medwin Hospital', 'queue': []},
    'H004': {'name': 'KMCH Hospital',   'queue': []},
    'H005': {'name': 'Vijaya Hospital', 'queue': []},
}

# Pre-load some fake patients to show queue is already busy
def preload_patients():
    import time
    hospitals['H001']['queue'] = [
        {'patient_id': 'P101', 'checkin_time': time.time()},
        {'patient_id': 'P102', 'checkin_time': time.time()},
        {'patient_id': 'P103', 'checkin_time': time.time()},
    ]
    hospitals['H002']['queue'] = [
        {'patient_id': 'P201', 'checkin_time': time.time()},
        {'patient_id': 'P202', 'checkin_time': time.time()},
    ]
    hospitals['H003']['queue'] = [
        {'patient_id': 'P301', 'checkin_time': time.time()},
        {'patient_id': 'P302', 'checkin_time': time.time()},
        {'patient_id': 'P303', 'checkin_time': time.time()},
        {'patient_id': 'P304', 'checkin_time': time.time()},
    ]
    hospitals['H004']['queue'] = [
        {'patient_id': 'P401', 'checkin_time': time.time()},
    ]
    hospitals['H005']['queue'] = [
        {'patient_id': 'P501', 'checkin_time': time.time()},
        {'patient_id': 'P502', 'checkin_time': time.time()},
    ]