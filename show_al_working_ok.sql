-- 1. Mostrar las bases de datos (Ya lo tienes)
SHOW DATABASES;

-- 2. Mostrar que hay un flujo de datos seudonimizado
USE clinical_trials_db;
SELECT * FROM ResumenPacientes;

-- 3. Mostrar que solo tú puedes recuperar la identidad (El cruce final)
SELECT ID.real_name, RES.Parámetro, RES.Resultado
FROM hospital_identity_db.PatientMapping ID
JOIN clinical_trials_db.ResumenPacientes RES ON ID.pseudo_id = RES.`ID Paciente`;
