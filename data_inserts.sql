-- 1. Usuarios (Solo si no existen para evitar errores)
INSERT IGNORE INTO Users (username, password_hash, id_role) 
VALUES ('marina_supervisor', 'hash_seguro_123', 2); 

-- 2. Configurar Estudio y Variables
INSERT INTO ClinicalStudy (name, description, lab_in_charge) 
VALUES ('Estudio Genómica BCN', 'Análisis longitudinal de marcadores', 'Lab Genética Avanzada');

INSERT INTO VariableDictionary (label, data_type) 
VALUES ('Nivel Glucosa', 'Value'), ('Secuencia Genómica', 'File');

-- 3. Paciente Seudonimizado
-- Esto crea un nuevo paciente cada vez que corres el script
INSERT INTO Participants (id_study) VALUES (1);

-- 4. Registro de Visita y Datos
-- Usamos LAST_INSERT_ID() para que el script sepa cuál es el paciente que acabamos de crear
SET @last_participant = LAST_INSERT_ID();

INSERT INTO Visits (pseudo_id, visit_date) 
VALUES (@last_participant, CURDATE());

SET @last_visit = LAST_INSERT_ID();

-- Insertamos el dato de glucosa (asumiendo que id_variable es 1)
INSERT INTO ClinicalData (id_visit, id_variable, data_value) 
VALUES (@last_visit, 1, '95 mg/dL');
