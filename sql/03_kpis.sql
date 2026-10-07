-- =====================================================================
-- Requêtes KPI (SQLite) - s'appuient sur la vue v_ventes (02_vues.sql)
-- =====================================================================
-- Chaque requête est précédée d'une ligne « -- name: <nom> » utilisée par
-- le notebook pour l'exécuter. Montants en dollars US au prix catalogue.
-- « unites » = quantités vendues ; « commandes » = numéros de commande distincts.


-- name: vue_ensemble
-- Chiffres clés sur toute la période
SELECT
    MIN(order_date)                                           AS debut,
    MAX(order_date)                                           AS fin,
    COUNT(DISTINCT order_number)                              AS commandes,
    COUNT(DISTINCT customer_id)                               AS clients,
    SUM(quantity)                                             AS unites,
    ROUND(SUM(chiffre_affaires))                              AS chiffre_affaires,
    ROUND(SUM(marge))                                         AS marge,
    ROUND(100.0 * SUM(marge) / SUM(chiffre_affaires), 1)      AS taux_marge_pct,
    ROUND(SUM(chiffre_affaires) / COUNT(DISTINCT order_number)) AS panier_moyen
FROM v_ventes;


-- name: evolution_annuelle
-- Chiffre d'affaires par année et croissance sur un an (années complètes uniquement)
WITH annuel AS (
    SELECT
        annee,
        COUNT(DISTINCT strftime('%m', order_date)) AS mois_couverts,
        COUNT(DISTINCT order_number)               AS commandes,
        SUM(chiffre_affaires)                      AS ca,
        SUM(marge)                                 AS marge
    FROM v_ventes
    GROUP BY annee
)
SELECT
    annee,
    mois_couverts,
    commandes,
    ROUND(ca)    AS chiffre_affaires,
    ROUND(marge) AS marge,
    CASE WHEN mois_couverts = 12 AND LAG(mois_couverts) OVER (ORDER BY annee) = 12
         THEN ROUND(100.0 * (ca / LAG(ca) OVER (ORDER BY annee) - 1), 1)
    END          AS croissance_pct
FROM annuel
ORDER BY annee;


-- name: ventes_trimestrielles
-- Chiffre d'affaires par trimestre, avec le rang du trimestre au sein de son année
SELECT
    annee,
    trimestre,
    SUM(quantity)                                                       AS unites,
    ROUND(SUM(chiffre_affaires))                                        AS chiffre_affaires,
    RANK() OVER (PARTITION BY annee ORDER BY SUM(chiffre_affaires) DESC) AS rang_dans_annee
FROM v_ventes
GROUP BY annee, trimestre
ORDER BY annee, trimestre;


-- name: canaux
-- Magasins physiques ou boutique en ligne
SELECT
    canal,
    COUNT(DISTINCT order_number)                                               AS commandes,
    ROUND(SUM(chiffre_affaires))                                               AS chiffre_affaires,
    ROUND(100.0 * SUM(chiffre_affaires) / SUM(SUM(chiffre_affaires)) OVER (), 1) AS part_ca_pct,
    ROUND(SUM(chiffre_affaires) / COUNT(DISTINCT order_number))                AS panier_moyen,
    ROUND(100.0 * SUM(marge) / SUM(chiffre_affaires), 1)                       AS taux_marge_pct
FROM v_ventes
GROUP BY canal
ORDER BY chiffre_affaires DESC;


-- name: part_en_ligne_par_annee
-- Poids de la boutique en ligne dans le chiffre d'affaires de chaque année
SELECT
    annee,
    ROUND(SUM(CASE WHEN canal = 'En ligne' THEN chiffre_affaires ELSE 0 END)) AS ca_en_ligne,
    ROUND(SUM(chiffre_affaires))                                              AS ca_total,
    ROUND(100.0 * SUM(CASE WHEN canal = 'En ligne' THEN chiffre_affaires ELSE 0 END)
          / SUM(chiffre_affaires), 1)                                         AS part_en_ligne_pct
FROM v_ventes
GROUP BY annee
ORDER BY annee;


-- name: delai_livraison
-- Délai moyen entre commande et livraison (commandes en ligne livrées)
SELECT
    CAST(strftime('%Y', order_date) AS INTEGER)                    AS annee,
    COUNT(*)                                                       AS commandes_livrees,
    ROUND(AVG(julianday(delivery_date) - julianday(order_date)), 1) AS delai_moyen_jours
FROM orders
WHERE delivery_date IS NOT NULL
GROUP BY annee
ORDER BY annee;


-- name: categories
-- Volume, chiffre d'affaires et rentabilité par catégorie de produits
SELECT
    categorie,
    SUM(quantity)                                                              AS unites,
    ROUND(SUM(chiffre_affaires))                                               AS chiffre_affaires,
    ROUND(100.0 * SUM(chiffre_affaires) / SUM(SUM(chiffre_affaires)) OVER (), 1) AS part_ca_pct,
    ROUND(SUM(chiffre_affaires) / SUM(quantity), 1)                            AS prix_moyen,
    ROUND(SUM(marge))                                                          AS marge,
    ROUND(100.0 * SUM(marge) / SUM(chiffre_affaires), 1)                       AS taux_marge_pct
FROM v_ventes
GROUP BY categorie
ORDER BY chiffre_affaires DESC;


-- name: continents
-- Ventes par continent du client
SELECT
    continent_client                                                           AS continent,
    SUM(quantity)                                                              AS unites,
    ROUND(SUM(chiffre_affaires))                                               AS chiffre_affaires,
    ROUND(100.0 * SUM(chiffre_affaires) / SUM(SUM(chiffre_affaires)) OVER (), 1) AS part_ca_pct
FROM v_ventes
GROUP BY continent_client
ORDER BY chiffre_affaires DESC;


-- name: pays
-- Ventes et panier moyen par pays du client
SELECT
    pays_client                                                                AS pays,
    COUNT(DISTINCT order_number)                                               AS commandes,
    SUM(quantity)                                                              AS unites,
    ROUND(SUM(chiffre_affaires))                                               AS chiffre_affaires,
    ROUND(100.0 * SUM(chiffre_affaires) / SUM(SUM(chiffre_affaires)) OVER (), 1) AS part_ca_pct,
    ROUND(SUM(chiffre_affaires) / COUNT(DISTINCT order_number))                AS panier_moyen
FROM v_ventes
GROUP BY pays_client
ORDER BY chiffre_affaires DESC;


-- name: top_villes
-- Top 10 des villes par chiffre d'affaires
-- Regroupement par ville ET pays : il existe un Toronto au Canada et un autre aux États-Unis
SELECT
    RANK() OVER (ORDER BY SUM(chiffre_affaires) DESC) AS rang,
    ville_client                                      AS ville,
    etat_client                                       AS etat,
    pays_client                                       AS pays,
    COUNT(DISTINCT customer_id)                       AS clients,
    SUM(quantity)                                     AS unites,
    ROUND(SUM(chiffre_affaires))                      AS chiffre_affaires
FROM v_ventes
GROUP BY ville_client, etat_client, pays_client
ORDER BY chiffre_affaires DESC
LIMIT 10;


-- name: top_produits
-- Top 10 des produits par chiffre d'affaires
SELECT
    RANK() OVER (ORDER BY SUM(chiffre_affaires) DESC) AS rang,
    produit,
    categorie,
    SUM(quantity)                                     AS unites,
    ROUND(SUM(chiffre_affaires))                      AS chiffre_affaires,
    ROUND(SUM(marge))                                 AS marge
FROM v_ventes
GROUP BY product_id, produit, categorie
ORDER BY chiffre_affaires DESC
LIMIT 10;


-- name: top_clients
-- Top 10 des clients par chiffre d'affaires
SELECT
    RANK() OVER (ORDER BY SUM(chiffre_affaires) DESC)          AS rang,
    customer_id,
    pays_client                                                AS pays,
    COUNT(DISTINCT order_number)                               AS commandes,
    SUM(quantity)                                              AS unites,
    ROUND(SUM(chiffre_affaires))                               AS chiffre_affaires,
    ROUND(SUM(chiffre_affaires) / COUNT(DISTINCT order_number)) AS panier_moyen
FROM v_ventes
GROUP BY customer_id, pays_client
ORDER BY chiffre_affaires DESC
LIMIT 10;


-- name: frequence_achat
-- Répartition des clients selon leur nombre de commandes
WITH par_client AS (
    SELECT customer_id, COUNT(*) AS nb_commandes
    FROM orders
    GROUP BY customer_id
)
SELECT
    CASE WHEN nb_commandes >= 5 THEN '5 et plus' ELSE CAST(nb_commandes AS TEXT) END AS commandes_par_client,
    COUNT(*)                                                                        AS clients,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)                              AS part_clients_pct
FROM par_client
GROUP BY commandes_par_client
ORDER BY MIN(nb_commandes);
