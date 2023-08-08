============================================================================
============================================================================
CREATE TABLE barang (
	kode_barang CHAR VARYING(10),
	sektor CHAR VARYING(10),
	nama_barang CHAR VARYING(50),
	tipe CHAR VARYING(10),
	nama_tipe CHAR VARYING(30),
	kode_lini INTEGER,
	lini CHAR VARYING(10),
	kemasan CHAR VARYING(10)
);

COPY barang
FROM 'D:\Data\!!S DoC\Database\rakamin academy\Data_sales_kimiaFarma_pelanggan.csv'
DELIMITER ','
CSV HEADER;

============================================================================
============================================================================
CREATE TABLE pelanggan (
	id_customer CHAR VARYING(10),
	level CHAR VARYING(10),
	nama CHAR VARYING(50),
	id_cabang_sales CHAR VARYING(10),
	cabang_sales CHAR VARYING(50),
	id_group CHAR VARYING(10),
	tipe_group CHAR VARYING(10)
);

COPY pelanggan
FROM 'D:\Data\!!S DoC\Database\rakamin academy\Data_sales_kimiaFarma_pelanggan.csv'
DELIMITER ','
CSV HEADER;

============================================================================
============================================================================
CREATE TABLE penjualan_1 (
	id_distributor CHAR VARYING(10),
	id_cabang CHAR VARYING(10),
	id_invoice CHAR VARYING(50),
	tanggal DATE,
	id_customer CHAR VARYING(50),
	id_barang CHAR VARYING(10),
	jumlah_barang INTEGER,
	unit CHAR VARYING(10),
	harga NUMERIC,
	brand_id CHAR VARYING(10),
	lini CHAR VARYING(30)
);

COPY penjualan_1
FROM 'C:\Users\User\Downloads\Data_penjualan - penjualan (1).csv'‬
DELIMITER ',' CSV HEADER;

============================================================================
============================================================================
'TABLE BASE'
CREATE TABLE table_base AS (SELECT 
	s.id_distributor, s.id_cabang, s.id_invoice, s.tanggal,
	s.id_customer, s.id_barang, s.jumlah_barang, s.unit, s.harga,
	c.level, c.nama, c.id_cabang_sales, c.cabang_sales, c.tipe_group, 
	p.kode_barang, p.nama_tipe, p.kode_lini, p.lini
FROM penjualan_1 AS s
	LEFT JOIN pelanggan AS c ON c.id_customer = s.id_customer
	LEFT JOIN barang AS p ON p.kode_barang = s.id_barang)

============================================================================
============================================================================
'1. Data Cleaning'
PRIMARY KEY = id_invoice (UID)//
-- table base terdapat total rows 350 
-- coba melakukan distinct untuk memastikan tidak ada 
-- duplikat pada kode unik table base
SELECT DISTINCT id_invoice FROM table_base
-- memunculkan total rows 350 
-- mengartikan bahwa tidak terdapat duplikat 

============================================================================
============================================================================
'2. menambahkan column aggregate'
ALTER TABLE table_base ADD COLUMN revenue INTEGER 

UPDATE table_base
SET revenue = (jumlah_barang * harga * 100)

SELECT * FROM table_base ORDER BY tanggal

============================================================================
============================================================================
'3. Aggregate'
'a) Revenue Growth jan - jun 2022'
SELECT to_char(tanggal, 'Month') AS MONTH, sum(revenue) AS profit
FROM table_base
GROUP BY month
ORDER BY min (tanggal);
-- mencari bulan dengan profit tertinggi  
SELECT to_char(tanggal, 'Month') AS MONTH, sum(revenue) AS profit
FROM table_base
GROUP BY month
ORDER BY profit DESC;
-- Januari menjadi bulan dengan profit tertinggi 

'b) Average Product sold'
SELECT to_char(tanggal, 'Month') AS MONTH, 
	ROUND(AVG(jumlah_barang),0) AS AVG_PRODUCT
FROM table_base
GROUP BY month
ORDER BY min(tanggal);
--AVG produk banyak terjual pada bulang april yakni 32

'c) total profit sales berdasarkan segmen'
SELECT nama AS seller, sum(revenue) AS profit
FROM table_base
GROUP BY nama
ORDER BY profit DESC;

'd) rata-rata profit sales berdasarkan nama cabang'
SELECT nama AS seller, ROUND(AVG(revenue),0) AS profit
FROM table_base
GROUP BY nama
ORDER BY profit DESC;
	
'e)profit berdasarkan wilayah'
SELECT cabang_sales AS region, SUM(revenue) AS revenue, round(avg(jumlah_barang),0) AS AVG_product
FROM table_base
GROUP BY region
ORDER BY revenue DESC;

'OR
WITH revenue AS
      (SELECT cabang_sales AS region, sum(revenue) AS revenue
       FROM table_base
       GROUP BY cabang_sales),
     seller AS
      (SELECT cabang_sales AS region, round(avg(jumlah_barang),0) AS AVG_product
       FROM table_base
       GROUP BY cabang_sales)
SELECT r.region, r.revenue, s.avg_product
FROM revenue r 
JOIN seller s ON r.region = s.region
ORDER BY revenue DESC;'


'f)profit berdasarkan tipe_group'
SELECT tipe_group, COUNT(id_invoice) AS total_transactions, 
		SUM(jumlah_barang) AS product_sold, SUM(revenue) AS profit 
FROM table_base
GROUP BY tipe_group
ORDER BY profit DESC;

'g)Best Product Sold'
SELECT lini, SUM(jumlah_barang) AS sold, round(AVG(jumlah_barang), 0) AS AVG_sold 
FROM table_base
GROUP BY lini
ORDER BY sold DESC;

============================================================================
============================================================================
'Table Aggregate'
DROP TABLE IF EXISTS table_store

CREATE TABLE table_store AS 
(SELECT 
	to_char(tanggal, 'Month') AS MONTH,	
 	nama AS store,
 	SUM(jumlah_barang) AS product_sold, 
 	SUM(revenue) AS profit,
	COUNT(id_invoice) AS total_transactions,
 	cabang_sales AS region
FROM table_base
GROUP BY month, store, lini, region
ORDER BY min (tanggal))

SELECT store, SUM(product_sold), SUM(profit), SUM(total_transactions) 
FROM table_store 
GROUP BY store

============================================================================
============================================================================
'search missing values' 
SELECT * FROM table_base
        WHERE id_customer IS NULL
		OR revenue <= 0;