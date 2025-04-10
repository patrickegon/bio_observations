-- Criação do Banco de Dados
CREATE DATABASE bio_observations;
\c bio_observations;

-- Criação e Importação de Dados Brutos
CREATE TABLE raw_data (
    id SERIAL PRIMARY KEY,
    observation_date DATE,
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    species_name VARCHAR(255),
    duration_minutes INT,
    comments TEXT
);

COPY raw_data FROM 'data/sample_observations.csv' CSV HEADER;

-- Normalização com Transação Única
BEGIN;

CREATE TABLE locations (
    id SERIAL PRIMARY KEY,
    latitude DECIMAL(9,6) UNIQUE,
    longitude DECIMAL(9,6) UNIQUE
);

CREATE TABLE species (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE,
    conservation_status VARCHAR(50) DEFAULT 'Não avaliada'
);

CREATE TABLE durations (
    id SERIAL PRIMARY KEY,
    minutes INT UNIQUE
);

INSERT INTO locations (latitude, longitude)
SELECT DISTINCT latitude, longitude FROM raw_data
ON CONFLICT (latitude, longitude) DO NOTHING;

INSERT INTO species (name)
SELECT DISTINCT species_name FROM raw_data
ON CONFLICT (name) DO NOTHING;

INSERT INTO durations (minutes)
SELECT DISTINCT duration_minutes FROM raw_data
ON CONFLICT (minutes) DO NOTHING;

-- Criação da Tabela Fato com Verificação
CREATE TABLE sightings AS
SELECT
    r.observation_date,
    loc.id AS location_id,
    sp.id AS species_id,
    dur.id AS duration_id,
    r.comments
FROM raw_data r
JOIN locations loc ON r.latitude = loc.latitude AND r.longitude = loc.longitude
JOIN species sp ON r.species_name = sp.name
JOIN durations dur ON r.duration_minutes = dur.minutes;

-- Análise Imediata (Mostra Impacto Visual)
SELECT 
    'Dados Processados' AS metric,
    COUNT(*) AS total_observations,
    COUNT(DISTINCT species_id) AS unique_species,
    COUNT(DISTINCT location_id) AS unique_locations
FROM sightings;

COMMIT;

-- Índices e Limpeza
CREATE INDEX idx_sightings_date ON sightings(observation_date);
ALTER TABLE raw_data
    DROP COLUMN latitude,
    DROP COLUMN longitude,
    DROP COLUMN species_name,
    DROP COLUMN duration_minutes;
