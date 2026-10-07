"""Construit la base SQLite `ventes.db` à partir des CSV de `data/`.

Usage : python build_database.py

Étapes : création du schéma (sql/01_schema.sql), nettoyage et répartition des
données dans les tables normalisées, création des vues (sql/02_vues.sql), puis
contrôles d'intégrité.
"""
import sqlite3
from pathlib import Path

import pandas as pd

RACINE = Path(__file__).parent
DATA = RACINE / 'data'
SQL = RACINE / 'sql'
DB_PATH = RACINE / 'ventes.db'


def date_excel_vers_iso(serie):
    """Convertit un numéro de série Excel (jours depuis 1899-12-30) en date ISO."""
    return (pd.Timestamp('1899-12-30') + pd.to_timedelta(serie, unit='D')).dt.strftime('%Y-%m-%d')


def corriger_encodage(texte):
    """Répare le texte UTF-8 relu en Windows-1252, éventuellement deux fois ('ThÃƒÂ¼ringen')."""
    while isinstance(texte, str) and 'Ã' in texte:
        try:
            texte = texte.encode('cp1252').decode('utf-8')
        except (UnicodeEncodeError, UnicodeDecodeError):
            break
    return texte


def preparer_tables():
    clients = pd.read_csv(DATA / 'Clients.csv', dtype={'CustomerZip': str})
    produits = pd.read_csv(DATA / 'Products.csv')
    categories_brutes = pd.read_csv(DATA / 'Product_Categories.csv')
    magasins = pd.read_csv(DATA / 'Stores.csv')
    transactions = pd.read_csv(DATA / 'Transactions.csv')

    countries = (clients[['CustomerCountry', 'CustomerContinent']].drop_duplicates()
                 .rename(columns={'CustomerCountry': 'country', 'CustomerContinent': 'continent'}))

    # Les codes postaux américains ont perdu leurs zéros initiaux (05301 -> 5301)
    us = clients['CustomerCountry'] == 'United States'
    clients.loc[us, 'CustomerZip'] = clients.loc[us, 'CustomerZip'].str.zfill(5)
    customers = pd.DataFrame({
        'customer_id': clients['CustomerID'],
        'name': clients['CustomerName'].map(corriger_encodage),
        'gender': clients['CustomerGender'],
        'birth_date': date_excel_vers_iso(clients['CustomerDOB']),
        'city': clients['CustomerCity'].map(corriger_encodage),
        'state_code': clients['CustomerStateCode'],
        'state': clients['CustomerState'].map(corriger_encodage),
        'zip_code': clients['CustomerZip'],
        'country': clients['CustomerCountry'],
    })

    en_ligne = magasins['StoreCountry'] == 'Online'
    stores = pd.DataFrame({
        'store_id': magasins['StoreID'],
        'country': magasins['StoreCountry'].mask(en_ligne),
        'state': magasins['StoreState'].mask(en_ligne).map(corriger_encodage),
        'square_meters': magasins['StoreSqMeters'].mask(en_ligne),
        'open_date': date_excel_vers_iso(magasins['StoreOpenDate']),
        'is_online': en_ligne.astype(int),
    })

    categories = (categories_brutes[['ProductCategoryID', 'ProductCategory']].drop_duplicates()
                  .rename(columns={'ProductCategoryID': 'category_id', 'ProductCategory': 'name'}))
    subcategories = categories_brutes.rename(columns={
        'ProductSubcategoryID': 'subcategory_id', 'ProductSubcategory': 'name',
        'ProductCategoryID': 'category_id'})[['subcategory_id', 'name', 'category_id']]

    products = produits.rename(columns={
        'ProductID': 'product_id', 'ProductName': 'name', 'ProductBrand': 'brand',
        'ProductColor': 'color', 'ProductCost': 'unit_cost', 'ProductPrice': 'unit_price',
        'ProductSubcategoryID': 'subcategory_id'})

    # Date, livraison, client et magasin dépendent du numéro de commande, pas de la ligne
    orders = (transactions[['OrderNumber', 'OrderDate', 'DeliveryDate', 'CustomerID', 'StoreID']]
              .drop_duplicates()
              .rename(columns={'OrderNumber': 'order_number', 'OrderDate': 'order_date',
                               'DeliveryDate': 'delivery_date', 'CustomerID': 'customer_id',
                               'StoreID': 'store_id'}))
    assert orders['order_number'].is_unique, "Attributs de commande incohérents entre les lignes"
    order_lines = transactions.rename(columns={
        'OrderNumber': 'order_number', 'LineItem': 'line_item',
        'ProductID': 'product_id', 'Quantity': 'quantity'})[
        ['order_number', 'line_item', 'product_id', 'quantity']]

    # Ordre d'insertion compatible avec les clés étrangères
    return {
        'countries': countries, 'customers': customers, 'stores': stores,
        'categories': categories, 'subcategories': subcategories, 'products': products,
        'orders': orders, 'order_lines': order_lines,
    }


def construire(db_path=DB_PATH, verbose=True):
    db_path.unlink(missing_ok=True)
    con = sqlite3.connect(db_path)
    con.executescript((SQL / '01_schema.sql').read_text(encoding='utf-8'))

    tables = preparer_tables()
    for nom, df in tables.items():
        # if_exists='append' : on remplit les tables créées par le schéma, sans les recréer
        df.to_sql(nom, con, if_exists='append', index=False)
    con.executescript((SQL / '02_vues.sql').read_text(encoding='utf-8'))
    con.commit()

    erreurs_fk = con.execute('PRAGMA foreign_key_check').fetchall()
    integrite = con.execute('PRAGMA integrity_check').fetchone()[0]
    if erreurs_fk or integrite != 'ok':
        raise RuntimeError(f"Contrôle d'intégrité en échec : {erreurs_fk[:5]} / {integrite}")

    if verbose:
        print(f"Base créée : {db_path.name}")
        for nom in tables:
            n = con.execute(f'SELECT COUNT(*) FROM {nom}').fetchone()[0]
            print(f"  {nom:<14} {n:>7} lignes")
        print("  Clés étrangères et intégrité : OK")
    return con


if __name__ == '__main__':
    construire().close()
