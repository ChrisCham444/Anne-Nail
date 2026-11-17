CREATE TABLE IF NOT EXISTS services (
  service_id VARCHAR(64) PRIMARY KEY,
  name VARCHAR(160) NOT NULL,
  duration_minutes SMALLINT UNSIGNED NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE
);

INSERT INTO services (service_id, name, duration_minutes, price, active)
VALUES (
  'signature-manicura-rusa',
  'Manicura Rusa & Esmaltado',
  60,
  45.00,
  TRUE
)
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  duration_minutes = VALUES(duration_minutes),
  price = VALUES(price),
  active = TRUE;

ALTER TABLE appointments
  ADD COLUMN service_id VARCHAR(64) NULL AFTER event_id,
  ADD COLUMN reservation_code VARCHAR(32) NULL AFTER service_id,
  ADD UNIQUE KEY uq_appointments_reservation_code (reservation_code),
  ADD INDEX idx_appointments_schedule (start_at, end_at),
  ADD CONSTRAINT fk_appointments_service
    FOREIGN KEY (service_id) REFERENCES services (service_id);

UPDATE appointments
SET reservation_code = UPPER(REPLACE(UUID(), '-', ''))
WHERE reservation_code IS NULL;

ALTER TABLE appointments
  MODIFY COLUMN reservation_code VARCHAR(32) NOT NULL;
