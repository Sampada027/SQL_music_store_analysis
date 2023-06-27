-- (1)  Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent 
/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist.*/


WITH best_selling_artist AS (
	SELECT Music_Analysis.dbo.artist.artist_id AS artist_id, artist.name AS artist_name, SUM(Music_Analysis.dbo.invoice_line.unit_price*Music_Analysis.dbo.invoice_line.quantity) AS total_sales
	FROM Music_Analysis.dbo.invoice_line
	JOIN Music_Analysis.dbo.track ON track.track_id = Music_Analysis.dbo.invoice_line.track_id
	JOIN Music_Analysis.dbo.album ON album.album_id = Music_Analysis.dbo.track.album_id
	JOIN Music_Analysis.dbo.artist ON artist.artist_id = Music_Analysis.dbo.album.artist_id
	GROUP BY 1
	ORDER BY artist_id, artist_name, total_sales DESC
	
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

WITH popular_genre AS 
(
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id, 
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1


/* Method 2: : Using Recursive */

WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2
	),
	max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2)

SELECT sales_per_country.* 
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;


/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Method 1: using CTE */

WITH Customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT * FROM Customter_with_country WHERE RowNo <= 1


/* Method 2: Using Recursive */

WITH RECURSIVE 
	customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),

	country_max_spending AS(
		SELECT billing_country,MAX(total_spending) AS max_spending
		FROM customter_with_country
		GROUP BY billing_country)

SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customter_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;


--Q4: Write query to return the email, first name, last name, and genre of all rock music listeners. return your list in alphabetically order starting with 'a'.

SELECT DISTINCT customer.email, customer.first_name, customer.last_name from Music_Analysis.dbo.customer
JOIN Music_Analysis.dbo.invoice ON customer.customer_id = invoice.customer_id
JOIN Music_Analysis.dbo.invoice_line on invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN (
                   SELECT track_id from Music_Analysis.dbo.track
				   JOIN Music_Analysis.dbo.genre ON Music_Analysis.dbo.track.genre_id = genre.genre_id
				   WHERE genre.name LIKE 'Rock'
				   )
ORDER BY email;


-- Q5: 


SELECT TOP 10 artist.artist_id, artist.name,COUNT(artist.artist_id) AS number_of_songs
FROM Music_Analysis.dbo.track
JOIN Music_Analysis.dbo.album ON album.album_id = track.album_id
JOIN Music_Analysis.dbo.artist ON artist.artist_id = album.artist_id
JOIN Music_Analysis.dbo.genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id, artist.name
ORDER BY number_of_songs DESC


-- Q6: Return all the track names that have a song length longer than the average song length.Return the Name and Milliseconds for each track. 
-- Order by the song length with the longest songs listed first.
 

SELECT name,miliseconds FROM Music_Analysis.dbo.track
WHERE miliseconds > (
	SELECT AVG(travk.miliseconds) AS avg_track_length
	FROM track )
ORDER BY miliseconds DESC;




-- Q7: Who is the senior most employee based on the job title?

SELECT	top	1 levels, first_name, last_name from employee 
ORDER BY levels desc


-- Q8: have the most invoices?

SELECT TOP 5 billing_country, total from invoice
GROUP BY billing_country, total
ORDER BY total desc


--Q9: What are top 3 values of total invoice?

SELECT TOP 3 total from invoice
ORDER BY total desc

--Q10: Which city has the best customers? CLient would like to throw the promotional musical festive in the city we make the most money. (Write query for obtaining the city name and invoice)

SELECT TOP 1 SUM(total) as invoice_total, billing_city from [Music_Analysis].[dbo].[invoice]
GROUP BY billing_city
ORDER BY invoice_total desc


--Q11:  Who is the best customers? CLient want to give reward to the person whi has purchased the product most.

SELECT TOP 1 customer.customer_id , customer.first_name, customer.last_name, SUM(invoice.total) as TOTAL from Music_Analysis.dbo.customer
JOIN Music_Analysis.dbo.invoice on customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id, customer.first_name, customer.last_name
ORDER BY TOTAL desc
