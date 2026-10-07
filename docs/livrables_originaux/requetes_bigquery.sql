
-- 1. TOP 10 clients par volume et valeur
SELECT 
    Transaction.CustomerID, 
    SUM(Transaction.Quantity) AS TotalVolume, 
    SUM(Transaction.Quantity * Products.ProductPrice) AS TotalValue
FROM 
    `vivid-osprey-447816-p4.sqlprojet.Transaction` AS Transaction
JOIN 
    `vivid-osprey-447816-p4.sqlprojet.Products` AS Products 
ON 
    Transaction.ProductID = Products.ProductID
GROUP BY 
    Transaction.CustomerID
ORDER BY 
    TotalValue DESC
LIMIT 10;

-- 2. TOP 10 produits par volume et valeur
SELECT 
    Products.ProductID, 
    Products.ProductName, 
    SUM(Transaction.Quantity) AS TotalVolume, 
    SUM(Transaction.Quantity * Products.ProductPrice) AS TotalValue
FROM 
    `vivid-osprey-447816-p4.sqlprojet.Transaction` AS Transaction
JOIN 
    `vivid-osprey-447816-p4.sqlprojet.Products` AS Products 
ON 
    Transaction.ProductID = Products.ProductID
GROUP BY 
    Products.ProductID, Products.ProductName
ORDER BY 
    TotalValue DESC
LIMIT 10;

-- 3. TOP 10 villes par volume et valeur
SELECT 
    Clients.CustomerCity, 
    SUM(Transaction.Quantity) AS TotalVolume, 
    SUM(Transaction.Quantity * Products.ProductPrice) AS TotalValue
FROM 
    `vivid-osprey-447816-p4.sqlprojet.Transaction` AS Transaction
JOIN 
    `vivid-osprey-447816-p4.sqlprojet.Products` AS Products 
ON 
    Transaction.ProductID = Products.ProductID
JOIN 
    `vivid-osprey-447816-p4.sqlprojet.Clients` AS Clients 
ON 
    Transaction.CustomerID = Clients.CustomerID
GROUP BY 
    Clients.CustomerCity
ORDER BY 
    TotalValue DESC
LIMIT 10;

-- 4. Synthèse des ventes par zone géographique
SELECT 
    Clients.CustomerContinent, 
    SUM(Transaction.Quantity) AS TotalVolume, 
    SUM(Transaction.Quantity * Products.ProductPrice) AS TotalValue
FROM 
    `vivid-osprey-447816-p4.sqlprojet.Transaction` AS Transaction
JOIN 
    `vivid-osprey-447816-p4.sqlprojet.Products` AS Products 
ON 
    Transaction.ProductID = Products.ProductID
JOIN 
    `vivid-osprey-447816-p4.sqlprojet.Clients` AS Clients 
ON 
    Transaction.CustomerID = Clients.CustomerID
GROUP BY 
    Clients.CustomerContinent;

-- 7. Synthèse des ventes par pays
SELECT 
    Clients.CustomerCountry AS Country, 
    SUM(Transaction.Quantity) AS TotalVolume, 
    SUM(Transaction.Quantity * Products.ProductPrice) AS TotalValue
FROM 
    `vivid-osprey-447816-p4.sqlprojet.Transaction` AS Transaction
JOIN 
    `vivid-osprey-447816-p4.sqlprojet.Products` AS Products 
ON 
    Transaction.ProductID = Products.ProductID
JOIN 
    `vivid-osprey-447816-p4.sqlprojet.Clients` AS Clients 
ON 
    Transaction.CustomerID = Clients.CustomerID
GROUP BY 
    Clients.CustomerCountry
ORDER BY 
    TotalValue DESC;

-- 5. Synthèse des ventes par catégorie de produits
SELECT 
    ProductCategories.ProductCategory, 
    SUM(Transaction.Quantity) AS TotalVolume, 
    SUM(Transaction.Quantity * Products.ProductPrice) AS TotalValue
FROM 
    `vivid-osprey-447816-p4.sqlprojet.Transaction` AS Transaction
JOIN 
    `vivid-osprey-447816-p4.sqlprojet.Products` AS Products 
ON 
    Transaction.ProductID = Products.ProductID
JOIN 
    `vivid-osprey-447816-p4.sqlprojet.Product_categories` AS ProductCategories 
ON 
    Products.ProductSubcategoryID = ProductCategories.ProductSubcategoryID
GROUP BY 
    ProductCategories.ProductCategory;

-- 6. Suivi des ventes par année et trimestre
SELECT 
    EXTRACT(YEAR FROM Transaction.OrderDate) AS Year, 
    EXTRACT(QUARTER FROM Transaction.OrderDate) AS Quarter, 
    SUM(Transaction.Quantity) AS TotalVolume, 
    SUM(Transaction.Quantity * Products.ProductPrice) AS TotalValue
FROM 
    `vivid-osprey-447816-p4.sqlprojet.Transaction` AS Transaction
JOIN 
    `vivid-osprey-447816-p4.sqlprojet.Products` AS Products 
ON 
    Transaction.ProductID = Products.ProductID
GROUP BY 
    Year, Quarter
ORDER BY 
    Year, Quarter;

