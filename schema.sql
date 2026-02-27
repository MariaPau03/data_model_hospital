-- TABLAS DE ACCESO
CREATE TABLE Roles (
    id_role INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL -- Admin, Supervisor, DataEntry
);

CREATE TABLE Users (
    id_user INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    id_role INT,
    FOREIGN KEY (id_role) REFERENCES Roles(id_role)
);

-- TABLAS DE ESTUDIO Y PARTICIPANTES (Seudonimización)
CREATE TABLE ClinicalStudy (
    id_study INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    contact_info VARCHAR(255),
    lab_in_charge VARCHAR(255)
);

CREATE TABLE Participants (
    pseudo_id INT PRIMARY KEY AUTO_INCREMENT, -- Generado automáticamente
    id_study INT,
    FOREIGN KEY (id_study) REFERENCES ClinicalStudy(id_study)
);

-- TABLAS DE DATOS CLÍNICOS (Longitudinal y Flexible)
CREATE TABLE VariableDictionary (
    id_variable INT PRIMARY KEY AUTO_INCREMENT,
    label VARCHAR(100) NOT NULL, -- Ej: 'Presión Arterial', 'Imagen MRI'
    data_type ENUM('Value', 'File') NOT NULL
);

CREATE TABLE Visits (
    id_visit INT PRIMARY KEY AUTO_INCREMENT,
    pseudo_id INT,
    visit_date DATE NOT NULL,
    FOREIGN KEY (pseudo_id) REFERENCES Participants(pseudo_id)
);

CREATE TABLE ClinicalData (
    id_data INT PRIMARY KEY AUTO_INCREMENT,
    id_visit INT,
    id_variable INT,
    data_value TEXT, -- Para números o texto
    file_path VARCHAR(512), -- Para rutas de imágenes o secuencias
    FOREIGN KEY (id_visit) REFERENCES Visits(id_visit),
    FOREIGN KEY (id_variable) REFERENCES VariableDictionary(id_variable)
);

-- INSERTAR DATOS INICIALES
INSERT INTO Roles (name) VALUES ('Admin'), ('Supervisor'), ('Data Entry');
