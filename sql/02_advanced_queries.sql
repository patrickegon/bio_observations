-- Análise 1: Eficiência de Observação por Espécie
WITH species_stats AS (
    SELECT
        s.name,
        s.conservation_status,
        COUNT(*) AS total_sightings,
        AVG(d.minutes) AS avg_duration,
        SUM(d.minutes) AS total_time
    FROM sightings sg
    JOIN species s ON sg.species_id = s.id
    JOIN durations d ON sg.duration_id = d.id
    GROUP BY s.name, s.conservation_status
)
SELECT 
    name AS "Espécie",
    conservation_status AS "Status",
    total_sightings AS "Avistamentos",
    ROUND(avg_duration) AS "Duração Média (min)",
    total_time AS "Tempo Total (h)",
    RANK() OVER (ORDER BY total_sightings DESC) AS ranking
FROM species_stats
WHERE conservation_status = 'Ameaçada'
ORDER BY total_time DESC;

-- Análise 2: Padrões Temporais (Sazonalidade)
SELECT
    EXTRACT(YEAR FROM observation_date) AS ano,
    EXTRACT(MONTH FROM observation_date) AS mes,
    loc.latitude,
    loc.longitude,
    COUNT(*) FILTER (WHERE s.conservation_status = 'Ameaçada') AS ameacadas,
    COUNT(*) AS total_observacoes
FROM sightings sg
JOIN species s ON sg.species_id = s.id
JOIN locations loc ON sg.location_id = loc.id
WHERE observation_date BETWEEN '2020-01-01' AND '2023-12-31'
GROUP BY ano, mes, loc.latitude, loc.longitude
HAVING COUNT(*) > 5
ORDER BY ano, mes, ameacadas DESC;

-- Análise 3: Hotspots de Conservação (JOIN Complexo)
SELECT 
    loc.latitude,
    loc.longitude,
    COUNT(*) AS total_obs,
    STRING_AGG(DISTINCT s.name, ', ') AS especies_detectadas,
    ROUND(AVG(d.minutes)) AS tempo_medio
FROM sightings sg
JOIN locations loc ON sg.location_id = loc.id
JOIN species s ON sg.species_id = s.id
JOIN durations d ON sg.duration_id = d.id
WHERE s.conservation_status IN ('Ameaçada', 'Vulnerável')
GROUP BY loc.latitude, loc.longitude
HAVING COUNT(*) > 3
ORDER BY total_obs DESC
LIMIT 10;
