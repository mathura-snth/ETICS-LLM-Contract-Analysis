CREATE TABLE Organisation (
    id_org SERIAL PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    secteur VARCHAR(100),
    pays VARCHAR(100)
);

CREATE TABLE Document (
    id_doc SERIAL PRIMARY KEY,
    id_org INT REFERENCES Organisation(id_org),
    type_contrat VARCHAR(100),
    titre VARCHAR(255),
    version VARCHAR(50),
    date_effet DATE,
    format VARCHAR(10),
    nb_pages INT,
    langue VARCHAR(10),
    date_import TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Clause (
    id_clause SERIAL PRIMARY KEY,
    id_doc INT REFERENCES Document(id_doc),
    article VARCHAR(50),
    page INT,
    texte TEXT NOT NULL,
    categorie_theme VARCHAR(100)
);

CREATE TABLE Categorie_Toxicite (
    id_cat SERIAL PRIMARY KEY,
    libelle VARCHAR(100) NOT NULL,
    type VARCHAR(50),
    raison TEXT
);

CREATE TABLE Evaluation (
    id_eval SERIAL PRIMARY KEY,
    id_clause INT REFERENCES Clause(id_clause),
    id_cat INT REFERENCES Categorie_Toxicite(id_cat),
    niveau INT CHECK (niveau >= 0 AND niveau <= 3),
    score FLOAT,
    justification TEXT,
    modele VARCHAR(100),
    date_eval TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

