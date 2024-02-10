/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */

SELECT *
FROM `Facilities`
WHERE `membercost` !=0

/* Q2: How many facilities do not charge a fee to members? */

SELECT COUNT( `facid` )
FROM `Facilities`
WHERE `membercost` !=0


/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT facid, name, membercost, monthlymaintenance
FROM `Facilities`
WHERE `membercost` < ( 0.2 * monthlymaintenance )
AND (
`membercost` !=0
)

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

SELECT *
FROM Facilities
WHERE facid
IN ( 1, 5 )

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

select 
	case when monthlymaintenance < 100 then "Cheap" 
		 else "Expensive" end as type,
name, monthlymaintenance from Facilities 

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

SELECT *
FROM `Members`
WHERE memid
IN (

SELECT COUNT( * ) -1
FROM Members
)

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

select distinct concat(`firstname`,' ' ,`surname`) as member_name, name as facility_name
from Members 
inner join Bookings 
on Bookings.memid = Bookings.memid
inner join 
Facilities 
on Facilities.facid = Bookings.facid
where Facilities.facid in (0,1)
order by member_name

/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

WITH datecast AS 
(SELECT memid, facid, slots, bookid, CAST(starttime AS date) as truedate from Bookings),

allcosts as 
(select 
 case when datecast.memid = 0 then Facilities.guestcost 
 else Facilities.membercost end as rental_cost, 
 datecast.memid, datecast.facid, datecast.slots, datecast.bookid 
 from Facilities 
 inner join datecast on Facilities.facid = datecast.facid 
 where datecast.truedate = '2012-09-14'),

totalcosts as (select allcosts.memid, allcosts.facid, allcosts.bookid, allcosts.slots, allcosts.rental_cost, (allcosts.slots * allcosts.rental_cost) as total_cost from allcosts where allcosts.rental_cost > 0 order by allcosts.memid)

select distinct concat(`firstname`,' ' ,`surname`) as member_name, name as facility_name, totalcosts.total_cost as cost 
from totalcosts 
inner join Members 
on totalcosts.memid = Members.memid 
inner join Facilities 
on totalcosts.facid = Facilities.facid 
where totalcosts.total_cost > 30 
order by totalcosts.total_cost DESC


/* Q9: This time, produce the same result as in Q8, but using a subquery. */


select distinct concat(`firstname`,' ' ,`surname`) as member_name, name as facility_name, totalcosts.total_cost as cost 
from 
(
select allcosts.memid, allcosts.facid, allcosts.bookid, allcosts.slots, allcosts.rental_cost, (allcosts.slots * allcosts.rental_cost) as total_cost 

from 
(select 
 case when memid = 0 then Facilities.guestcost 
 else Facilities.membercost end as rental_cost, 
 Bookings.memid, Bookings.facid, Bookings.slots, Bookings.bookid 
 from Facilities 
 inner join Bookings on Facilities.facid = Bookings.facid 
 where CAST(Bookings.starttime AS date) = '2012-09-14') as allcosts
               
where allcosts.rental_cost > 0 order by allcosts.memid
)
as totalcosts 
inner join Members 
on totalcosts.memid = Members.memid 
inner join Facilities 
on totalcosts.facid = Facilities.facid 
where totalcosts.total_cost > 30 
order by totalcosts.total_cost DESC


/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

    query1 = """
select distinct name as facility_name, totalcosts.total_cost as cost 
from 
(
select allcosts.memid, allcosts.facid, allcosts.bookid, allcosts.slots, allcosts.rental_cost, (allcosts.slots * allcosts.rental_cost) as total_cost 

from 
(select 
 case when memid = 0 then Facilities.guestcost 
 else Facilities.membercost end as rental_cost, 
 Bookings.memid, Bookings.facid, Bookings.slots, Bookings.bookid 
 from Facilities 
 inner join Bookings on Facilities.facid = Bookings.facid) as allcosts
               
where allcosts.rental_cost > 0 order by allcosts.memid
)
as totalcosts 
inner join Members 
on totalcosts.memid = Members.memid 
inner join Facilities 
on totalcosts.facid = Facilities.facid 
order by totalcosts.total_cost DESC
            """
    cur.execute(query1)
 
    rows = cur.fetchall()
 

    rs = cur.execute(query1)
    df = pd.DataFrame(rs.fetchall())
    df.columns = [description[0] for description in cur.description]

    #print(df.info())

    #print(df.head())
    facility_revenue = df.groupby(by=["facility_name"])["cost"].sum()#([min, max, np.mean, np.median])
    facility_revenue_df = pd.DataFrame({'facility_name':facility_revenue.index, 'revenue':facility_revenue.values})
    facility_revenue_df = facility_revenue_df.sort_values('revenue')
    #facility_revenue.columns = ['facility_name','cost']
    facility_revenue_new = facility_revenue_df[facility_revenue_df['revenue'] < 1000]
    print(facility_revenue_new)


/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

select distinct concat(M1.surname,' ' ,M1.firstname) as Member_name, concat(M2.surname,' ' ,M2.firstname) as Recommenders_name from Members M1 inner join Members M2 on M1.recommendedby = M2.memid order by Member_name


/* Q12: Find the facilities with their usage by member, but not guests */

    query1 = """
            SELECT * FROM Bookings WHERE memid != 0 ORDER by facid        
            """
    cur.execute(query1)
 
    rows = cur.fetchall()
 

    rs = cur.execute(query1)
    df = pd.DataFrame(rs.fetchall())
    df.columns = [description[0] for description in cur.description]


    mem_usage_stats = df.groupby(by="facid")["memid"].agg([min, max, np.mean, np.median])

    print(mem_usage_stats)


/* Q13: Find the facilities usage by month, but not guests */

    query1 = """
            SELECT * from Bookings where memid != 0          
            """
    cur.execute(query1)
 
    rows = cur.fetchall()
 

    rs = cur.execute(query1)
    df = pd.DataFrame(rs.fetchall())
    df.columns = [description[0] for description in cur.description]

    df["starttime"] = df["starttime"].apply(pd.to_datetime)

    #print(df.info())

    df['starttime'] = df['starttime'].dt.month
    #print(df.head())
    month_usage_stats = df.groupby(by=["facid","starttime"])["memid"].agg([min, max, np.mean, np.median])

    print(month_usage_stats)
