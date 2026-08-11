# generate_qr.py

import qrcode
import os

YOUR_LAPTOP_IP = '10.206.79.18'

hospitals = {
    'H001': 'Apollo Hospital',
    'H002': 'Fortis Hospital',
    'H003': 'Medwin Hospital',
    'H004': 'KMCH Hospital',
    'H005': 'Vijaya Hospital',
}

os.makedirs('qr_codes', exist_ok=True)

for hid, name in hospitals.items():
    qr_data = f'http://10.206.79.18:5000/checkin|{hid}'
    img = qrcode.make(qr_data)
    img.save(f'qr_codes/{hid}_{name}.png')
    print(f'Generated QR for {name}')

print('\nAll 5 QR codes saved to qr_codes/ folder!')