-- Creamos la tabla de identidades
CREATE TABLE PatientMapping (
    pseudo_id INT PRIMARY KEY, 
    real_name VARCHAR(255),
    national_id VARCHAR(50)
);
