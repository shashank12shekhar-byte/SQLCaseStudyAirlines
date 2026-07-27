
--1. Find the busiest Airport by number of Flights take off
SELECT a.name, COUNT(*) AS TotalFlights
FROM Flights f
JOIN Airports a
ON f.origin = a.airportid
GROUP BY a.name
ORDER BY TotalFlights DESC
LIMIT 1;

--2. Total no of tickets sold per Airline
SELECT a.name, COUNT(t.ticketid) AS No_of_tickets_sold
FROM tickets t
JOIN flights f
ON t.flightid= f.flightid
JOIN airlines a
ON f.airlineid = a.airlineid
GROUP BY a.name;

--3. List all flights operated by 'Indigo' with airport names(origin and deprture)
SELECT f.flightid, ap.name AS OriginAirport, ap1.name AS DestinationAirport, a.name AS FlightName
FROM flights f
JOIN airlines a
ON a.airlineid = f.airlineid
JOIN airports ap
ON ap.airportid = f.origin 
JOIN airports ap1
ON ap1.airportid = f.destination
WHERE a.name = 'IndiGo';

--4. For each airline Rank top airports by number of flights departing from there

SELECT a.name AS AirlineName, ap.name AS airportname, 
	(DENSE_RANK() OVER (PARTITION BY a.name ORDER BY MAX(f.destination) DESC )) 
FROM airports ap
JOIN flights f
ON ap.airportid = f.destination
JOIN airlines a
ON a.airlineid = f.airlineid
GROUP by ap.name, a.name;

--5. For each flight, show time taken in hours and categorize it as short(<2hrs), Medium(2-5h), Long(>5h)

SELECT f.flightid, a.name,
CASE
	WHEN EXTRACT(EPOCH FROM (arrivaltime- departuretime))/3600 < 2 THEN 'Short'
	WHEN EXTRACT(EPOCH FROM (arrivaltime- departuretime))/3600 BETWEEN 2 AND 5 THEN 'Medium'
	WHEN EXTRACT(EPOCH FROM (arrivaltime- departuretime))/3600 > 5 THEN 'Long'
	END AS Time_taken

FROM flights f
JOIN airlines a
ON f.airlineid = a.airlineid;

--6. Show each passenger's first and last flight dates and number of flights

WITH CTE_FlightNo AS(
SELECT passengerid, MIN(f.departuretime) AS FirstFlight, MAX(f.departuretime) AS LastFlight,
COUNT(*) AS TotalFlights
FROM tickets t
JOIn flights f
ON t.flightid = f.flightid
GROUP BY passengerid
)
SELECT p.name, fn.FirstFlight, fn.LastFlight, fn.TotalFlights
FROM CTE_FlightNo fn
JOIN passengers p ON fn.passengerid = p.passengerid;

--7. Find flights with highest price tickets sold for each route (origin & destination)

WITH CTE_routetickets AS(
SELECT f.flightid, f.origin, f.destination, t.ticketid, t.price,
	RANK() OVER (PARTITION BY f.origin, f.destination ORDER BY t.price DESC) AS Rnk
FROM tickets t
JOIN flights f
ON f.flightid = t.flightid
)
SELECT ap.name AS origin, ap1.name AS destination, rt.price, rt.ticketid
FROM CTE_routetickets rt
JOIN airports ap
ON rt.origin = ap.airportid
JOIN airports ap1
ON rt.destination = ap1.airportid
WHERE Rnk = 1;

--8. Find the highest spending passenger in each frequent flyer status group

WITH CTE_spending AS(
SELECT *,
	RANK() OVER(PARTITION BY frequentflyerstatus ORDER BY totalspent DESC) AS rn
	FROM(
		SELECT  p.passengerid, p.name, p.frequentflyerstatus, SUM(price) AS totalspent
		FROM passengers p
		JOIN tickets t
		ON p.passengerid = t.passengerid
		GROUP BY p.passengerid, p.name, p.frequentflyerstatus
	)
)
SELECT name, frequentflyerstatus, totalspent
FROM CTE_spending 
WHERE rn =1;

--9.Find the total revenue and number of tickets sold for each airline and rank airlines based on total revenue.

WITH CTE_airlinerevenue AS(
SELECT a.name AS airlinename, ROUND(SUM(t.price)) AS totalrevenue, COUNT(t.ticketid) AS numberofticketsold FROM tickets t
JOIN flights f
ON t.flightid = f.flightid
JOIN airlines a
ON f.airlineid = a.airlineid
GROUP BY a.name
ORDER BY SUM(t.price) DESC
)
SELECT airlinename, numberofticketsold, totalrevenue,
	RANK() OVER (ORDER BY totalrevenue DESC)
FROM CTE_airlinerevenue

--10. For each passenger, identify most frequently used airline. If a passenger has multiple airines with the same highest usage, show all such airlines.

SELECT *,
	RANK() OVER(PARTITION BY passengerid ORDER BY ticketswithairline DESC) AS AirlineRank
FROM
(SELECT p.passengerid , p.name AS passengername, a.name AS airlineaname, COUNT(*) AS ticketswithairline FROM passengers p
JOIN tickets t
ON p.passengerid = t.passengerid
JOIN flights f
ON t.flightid = f.flightid
JOIN airlines a
ON f.airlineid = a.airlineid
GROUP BY p.passengerid ,p.name, a.name)
