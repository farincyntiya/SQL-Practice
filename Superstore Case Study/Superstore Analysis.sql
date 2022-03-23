-- RUN SCRIPT SHORTCUT: fn + F5


-- CASE 1
-- Layanan Ship Mode SAME DAY merupakan layanan di mana produk yang dipesan oleh pelanggan
-- dapat langsung dikirimkan pada hari yang sama dengan hari pemesanan. Namun pada kenyataannya,
-- tidak semua pelanggan yang memesan Ship Mode SAME DAY menerima benefit dari layanan ini
-- dengan baik. Dengan kata lain, ada juga beberapa pesanan SAME DAY yang tidak dikirimkan pada
-- hari yang sama dengan hari pemesanan. Tim Operasional ingin menganalisis lebih lanjut mengenai
-- hal ini untuk dapat ditindaklanjuti. Anda diminta untuk menampilkan jumlah order/pesanan SAME
-- DAY yang mengalami keterlambatan kirim.
select count (1) as count_late_shipped
from superstore_order
where ship_mode = 'Same Day' and order_date != ship_date

-- CASE 2
-- Tim Business ingin melakukan analisis lebih lanjut mengenai profitabilitas perusahaan. Kali ini, Tim
-- Business ingin melihat hubungan antara besaran nilai diskon yang diberikan dengan profitabilitas
-- yang diterima oleh perusahaan. Anda diminta untuk menampilkan hubungan ini dengan
-- menunjukkan rata-rata profit untuk masing-masing level diskon, di mana kriteria level diskon yang
-- diminta oleh Tim Business adalah sebagai berikut:
-- *** LOW apabila diskon berada di bawah 0.2 (tidak termasuk 0.2),
-- *** MODERATE apabila diskon mulai dari 0.2 hingga di bawah 0.4 (tidak termasuk 0.4)
-- *** HIGH apabila diskon mulai dari 0.4 ke atas.
select 
	avg(profit) as average_profit, 
	case when discount < 0.2 then 'low'
		 when discount >= 0.2 and discount < 0.4 then 'moderate'
		 else 'high' 
	end as discount_level
from superstore_order
group by discount_level
order by average_profit desc

-- CASE 3
-- Tim Sales meminta tolong kepada Business Intelligence Analyst untuk menganalisis performa dari
-- Category dan Subcategory dari produk-produk yang dimiliki oleh perusahaan. Anda diminta untuk
-- menampilkan metrik-metrik berikut untuk masing-masing pasangan Category-Subcategory yang ada:
-- *** Rata-rata diskon
-- *** Rata-rata profit
-- Jangan lupa untuk menampilkan nama Category dan Subcategory secara lengkap dan bukan hanya
-- menampilkan Product ID saja agar Tim Sales lebih mudah untuk memahami hasil analisis Anda!
select 
	p.category, p.subcategory,
	avg(o.discount) as average_discount,
	avg(o.profit) as average_profit
from superstore_order o 
left join superstore_product p
on o.product_id = p.product_id
group by 1,2
order by 1,2

-- CASE 4
-- Tim Business Development sedang mempertimbangkan untuk melakukan ekspansi yang lebih
-- mendalam di State California, Texas dan juga Georgia. Sebagai bahan untuk pertimbangan mereka,
-- Anda diminta untuk menampilkan performa dari masing-masing Customer Segment yang ada di
-- ketiga State tersebut untuk tahun 2016 saja. Adapun metrik-metrik performa yang diminta adalah
-- sebagai berikut:
-- *** Total sales
-- *** Rata-rata profit
select
	c.segment,
	sum(o.sales) as total_sales,
	avg(profit) as average_profit
from superstore_order o
left join superstore_customer c
on o.customer_id = c.customer_id
where 
	extract(year from o.order_date) = 2016 and
	c.state in ('California','Texas','Georgia')
group by 1

-- CASE 5
-- Tim Business tertarik untuk melihat region mana yang memiliki jumlah pelanggan/customer pecinta
-- diskon terbanyak. Oleh karena itu, Tim Business meminta Anda sebagai Business Intelligence Analyst
-- untuk menampilkan jumlah orang/customer yang memiliki rata-rata diskon di atas 0.4 untuk
-- masing-masing region yang ada.
with
subsq as (
	select
		customer_id,
		avg(discount) as average_discount
	from superstore_order
	group by 1
	having avg(discount) > 0.4
)
select c.region, count(1) as customer_disc_high_40
from subsq
join superstore_customer c
on subsq.customer_id = c.customer_id
group by 1
order by count(1) desc