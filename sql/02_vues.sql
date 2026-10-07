-- =====================================================================
-- Vue analytique : une ligne par ligne de commande, enrichie
-- =====================================================================
-- Centralise les jointures et le calcul du chiffre d'affaires et de la
-- marge, pour que les requêtes KPI restent courtes et cohérentes.
-- Montants en dollars US, calculés au prix catalogue.

DROP VIEW IF EXISTS v_ventes;

CREATE VIEW v_ventes AS
SELECT
    ol.order_number,
    ol.line_item,
    o.order_date,
    CAST(strftime('%Y', o.order_date) AS INTEGER)                      AS annee,
    (CAST(strftime('%m', o.order_date) AS INTEGER) + 2) / 3            AS trimestre,
    o.delivery_date,
    o.customer_id,
    c.city                                                             AS ville_client,
    c.state                                                            AS etat_client,
    c.country                                                          AS pays_client,
    co.continent                                                       AS continent_client,
    o.store_id,
    CASE WHEN s.is_online = 1 THEN 'En ligne' ELSE 'Magasin' END       AS canal,
    p.product_id,
    p.name                                                             AS produit,
    p.brand                                                            AS marque,
    sc.name                                                            AS sous_categorie,
    cat.name                                                           AS categorie,
    ol.quantity,
    ol.quantity * p.unit_price                                         AS chiffre_affaires,
    ol.quantity * (p.unit_price - p.unit_cost)                         AS marge
FROM order_lines   AS ol
JOIN orders        AS o   ON o.order_number   = ol.order_number
JOIN customers     AS c   ON c.customer_id    = o.customer_id
JOIN countries     AS co  ON co.country       = c.country
JOIN stores        AS s   ON s.store_id       = o.store_id
JOIN products      AS p   ON p.product_id     = ol.product_id
JOIN subcategories AS sc  ON sc.subcategory_id = p.subcategory_id
JOIN categories    AS cat ON cat.category_id  = sc.category_id;
