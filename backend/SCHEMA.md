# Database Schema — Smart Patient Queue System

## Table: appointments
| Column       | Type      | Description                        |
|--------------|-----------|------------------------------------|
| id           | INTEGER   | Primary key, auto-increment        |
| patient_name | TEXT      | Patient's full name                |
| phone        | TEXT      | Patient phone (used for history)   |
| hospital_id  | TEXT      | e.g. H001, H002                    |
| token        | TEXT      | e.g. TKN-042                       |
| status       | TEXT      | 'waiting' or 'completed'           |
| prescription | TEXT      | Doctor's notes (optional)          |
| created_at   | TIMESTAMP | Auto-set on insert                  |