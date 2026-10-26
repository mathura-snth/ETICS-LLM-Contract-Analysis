CREATE TABLE organisation (
    id_org   SERIAL PRIMARY KEY,
    nom      VARCHAR(255) NOT NULL UNIQUE,
    secteur  VARCHAR(100),
    pays     VARCHAR(100)
);

CREATE TABLE document (
    id_doc       SERIAL PRIMARY KEY,
    id_org       INT NOT NULL REFERENCES organisation(id_org),
    type_contrat VARCHAR(100) NOT NULL
        CHECK (type_contrat IN ('convention_compte','contrat_carte','grille_tarifaire','banque_a_distance','autre')),
    titre        VARCHAR(255) NOT NULL,
    version      VARCHAR(50),
    date_effet   DATE,
    format       VARCHAR(10) NOT NULL DEFAULT 'pdf',
    nb_pages     INT,
    langue       VARCHAR(10) NOT NULL DEFAULT 'fr',
    nom_fichier  VARCHAR(255),
    hash_sha256  CHAR(64) UNIQUE,          -- évite de ré-importer deux fois le même PDF
    date_import  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE clause (
    id_clause       SERIAL PRIMARY KEY,
    id_doc          INT NOT NULL REFERENCES document(id_doc) ON DELETE CASCADE,
    ordre           INT NOT NULL,           -- position dans le document (utile si un article est sous-découpé)
    article         VARCHAR(50),            -- ex. '2.3.1'
    titre           VARCHAR(255),
    page_debut      INT,
    page_fin        INT,                    -- un article peut s'étendre sur plusieurs pages
    texte           TEXT NOT NULL,
    categorie_theme VARCHAR(100),
    UNIQUE (id_doc, ordre)
);

CREATE TABLE categorie_toxicite (
    id_cat  SERIAL PRIMARY KEY,
    libelle VARCHAR(100) NOT NULL UNIQUE,
    type    VARCHAR(50),
    raison  TEXT
);

-- Golden dataset : annotations humaines (base du calcul précision/rappel et du kappa de Cohen)
CREATE TABLE annotation (
    id_annot    SERIAL PRIMARY KEY,
    id_clause   INT NOT NULL REFERENCES clause(id_clause) ON DELETE CASCADE,
    id_cat      INT NOT NULL REFERENCES categorie_toxicite(id_cat),
    annotateur  VARCHAR(50) NOT NULL,
    niveau      INT NOT NULL CHECK (niveau BETWEEN 0 AND 3),
    commentaire TEXT,
    date_annot  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (id_clause, id_cat, annotateur)
);

-- Prédictions du LLM (partie 2)
CREATE TABLE evaluation (
    id_eval        SERIAL PRIMARY KEY,
    id_clause      INT NOT NULL REFERENCES clause(id_clause) ON DELETE CASCADE,
    id_cat         INT NOT NULL REFERENCES categorie_toxicite(id_cat),
    niveau         INT NOT NULL CHECK (niveau BETWEEN 0 AND 3),
    score          DOUBLE PRECISION,
    justification  TEXT,
    modele         VARCHAR(100),
    prompt_version VARCHAR(50),             -- pour comparer plusieurs versions de prompt
    date_eval      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Postgres n'indexe pas automatiquement les clés étrangères
CREATE INDEX idx_document_org   ON document(id_org);
CREATE INDEX idx_clause_doc     ON clause(id_doc);
CREATE INDEX idx_eval_clause    ON evaluation(id_clause);
CREATE INDEX idx_eval_cat       ON evaluation(id_cat);
CREATE INDEX idx_annot_clause   ON annotation(id_clause);

-- Les 6 critères éthiques du sujet
INSERT INTO categorie_toxicite (libelle, type, raison) VALUES
 ('equilibre_parties',   'ethique', 'Déséquilibre significatif entre les droits et obligations de la banque et du client'),
 ('transparence',        'ethique', 'Clause peu claire, technique, incohérente ou renvoyant à des informations non fournies'),
 ('justice_equite',      'ethique', 'Clause excessivement favorable au professionnel'),
 ('personnes_vulnerables','ethique','Clause pouvant désavantager une personne âgée, en difficulté financière ou peu instruite'),
 ('donnees_personnelles','ethique', 'Usage, partage ou transfert de données personnelles peu encadré'),
 ('discrimination',      'ethique', 'Traitement différencié sans justification suffisante (ex. décision automatisée)');