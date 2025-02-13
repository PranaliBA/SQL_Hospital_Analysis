create table hospital_data (
	visiting_date timestamp,
	patient_id  varchar(50),
	patient_gender varchar(3),
	patient_age int,
	patient_sat_score numeric(10),
	patient_first_inital varchar(3),
	patient_last_name varchar(50),
	patient_race varchar(50),
	patient_admin_flag varchar(50),
	patient_waittime int,
	department_referral varchar(50)
);

/*---------------------------------Hospital Data Anaysis------------------------------------------------*/

select count(*) from hospital_data;

/* What are the number of visiters*/

SELECT COUNT(*) AS total_visits FROM hospital_data;

/* What are the number of visiters per department*/

SELECT department_referral, COUNT(*) AS visit_count
FROM hospital_data
GROUP BY department_referral
ORDER BY visit_count DESC;

/* What is the Average Patient Wait Time*/

SELECT AVG(patient_waittime) AS avg_wait_time FROM hospital_data;

/* How many people visit per day*/

SELECT DATE(visiting_date) AS visit_date, COUNT(*) AS visit_count
FROM hospital_data
GROUP BY DATE(visiting_date)
ORDER BY visit_date;

/* Wait Time Analysis according to different Department*/

SELECT department_referral, AVG(patient_waittime) AS avg_wait_time, MAX(patient_waittime) AS max_wait_time, MIN(patient_waittime) AS min_wait_time
FROM hospital_data
GROUP BY department_referral;

/* Correlation Analysis between age and sat score*/

SELECT patient_age, patient_sat_score
FROM hospital_data
WHERE patient_sat_score IS NOT NULL;

/*Trend Analysis Overtime*/

SELECT DATE_TRUNC('month', visiting_date) AS month, COUNT(*) AS visit_count
FROM hospital_data
GROUP BY month
ORDER BY month;

/* Which is the most common patient race that visits the hospital frequently */

SELECT patient_race, COUNT(*) AS count
FROM hospital_data
GROUP BY patient_race
ORDER BY count DESC
LIMIT 1;

/* Which department is more effective in patient satisfaction*/

SELECT department_referral, AVG(patient_sat_score) AS avg_sat_score
FROM hospital_data
WHERE patient_sat_score IS NOT NULL
GROUP BY department_referral
ORDER BY avg_sat_score DESC;

/* Predictive Analysis of high waiting time*/

SELECT patient_age, patient_gender, department_referral, patient_waittime
FROM hospital_data
WHERE patient_waittime > (SELECT AVG(patient_waittime) FROM hospital_data);

/* Patient Segmentation for Cluster Analysis*/

SELECT patient_age, patient_gender, patient_race, department_referral
FROM hospital_data;

/*What is the average time patients spend in each department?*/

SELECT department_referral, AVG(patient_waittime) AS avg_wait_time
FROM hospital_data
GROUP BY department_referral
ORDER BY avg_wait_time DESC;

/*What is the age distribution of patients visiting different departments?*/

SELECT department_referral, patient_age, COUNT(*) AS count
FROM hospital_data
GROUP BY department_referral, patient_age
ORDER BY department_referral, patient_age;

/*What is the correlation between patient wait time and satisfaction score?*/

SELECT patient_waittime, AVG(patient_sat_score) AS avg_sat_score
FROM hospital_data
GROUP BY patient_waittime
ORDER BY patient_waittime;

/*Is there a difference in average wait time between male and female patients?*/

SELECT patient_gender, AVG(patient_waittime) AS avg_wait_time
FROM hospital_data
GROUP BY patient_gender;

/* Using Window Functions for Analysis*/
/* How many total visits have occurred over time*/

SELECT visiting_date,
       COUNT(*) OVER (ORDER BY visiting_date) AS running_total
FROM hospital_data
ORDER BY visiting_date;

/*What are the different percentiles of patient wait times?*/

SELECT patient_waittime,
       NTILE(100) OVER (ORDER BY patient_waittime) AS percentile
FROM hospital_data;

/*Use of Subqueries and CTE Function */
/* Who are the patients with the longest wait times? */

SELECT patient_id, patient_first_inital, patient_last_name, patient_waittime
FROM hospital_data
WHERE patient_waittime = (SELECT MAX(patient_waittime) FROM hospital_data);

/* What is the average wait time by different age groups?*/

WITH AgeGroups AS (
    SELECT
        CASE
            WHEN patient_age < 18 THEN '0-17'
            WHEN patient_age BETWEEN 18 AND 35 THEN '18-35'
            WHEN patient_age BETWEEN 36 AND 50 THEN '36-50'
            WHEN patient_age BETWEEN 51 AND 65 THEN '51-65'
            ELSE '66+'
        END AS age_group,
        patient_waittime
    FROM hospital_data
)
SELECT age_group, AVG(patient_waittime) AS avg_wait_time
FROM AgeGroups
GROUP BY age_group
ORDER BY avg_wait_time;

/* Which days of the week have the highest patient visits?*/

SELECT TO_CHAR(visiting_date, 'Day') AS day_of_week, COUNT(*) AS visit_count
FROM hospital_data
GROUP BY day_of_week
ORDER BY visit_count DESC;

/*What factors predict high patient satisfaction scores?*/

SELECT patient_age, patient_gender, patient_race, department_referral, patient_waittime, patient_sat_score
FROM hospital_data
WHERE patient_sat_score IS NOT NULL;

/*Find the average wait time for patients who visited each department and also had a satisfaction score recorded. Write a query to return department name, average wait time,
and the number of patients with recorded satisfaction scores.

Steps to Solve:
First, filter out the patients who have a recorded satisfaction score.
Then, calculate the average wait time for these patients per department.
Use joins to fetch necessary data from the tables.*/

WITH patients_with_scores AS (
    SELECT 
        department_referral, 
        patient_id, 
        patient_waittime, 
        patient_sat_score
    FROM hospital_data
    WHERE patient_sat_score IS NOT NULL
)
SELECT 
    pws.department_referral, 
    AVG(pws.patient_waittime) AS avg_wait_time, 
    COUNT(pws.patient_id) AS num_patients
FROM patients_with_scores pws
GROUP BY pws.department_referral
ORDER BY avg_wait_time DESC;

/*Write a query that determines the patient with the highest satisfaction score for each department. 
Return the department name, patient name, and satisfaction score. 
If the top satisfaction score is shared, provide all patients who have that score.

Steps to Solve:
First, find the highest satisfaction score for each department.
Then, filter the data to get the details of the patients with these top scores.*/

--Method 1: Using CTE--

WITH patient_with_department AS (
    SELECT 
        patient_id, 
        patient_first_inital, 
        patient_last_name, 
        department_referral, 
        patient_sat_score,
        ROW_NUMBER() OVER(PARTITION BY department_referral ORDER BY patient_sat_score DESC) AS RowNo
    FROM hospital_data
    WHERE patient_sat_score IS NOT NULL
)
SELECT 
    department_referral, 
    patient_first_inital, 
    patient_last_name, 
    patient_sat_score
FROM patient_with_department
WHERE RowNo = 1;

--Method 2: Recursive CTE--

WITH RECURSIVE patient_with_department AS (
    SELECT 
        patient_id, 
        patient_first_inital, 
        patient_last_name, 
        department_referral, 
        patient_sat_score
    FROM hospital_data
    WHERE patient_sat_score IS NOT NULL
),
department_max_score AS (
    SELECT 
        department_referral, 
        MAX(patient_sat_score) AS max_score
    FROM patient_with_department
    GROUP BY department_referral
)
SELECT 
    pwd.department_referral, 
    pwd.patient_first_inital, 
    pwd.patient_last_name, 
    pwd.patient_sat_score
FROM patient_with_department pwd
JOIN department_max_score dms
ON pwd.department_referral = dms.department_referral
AND pwd.patient_sat_score = dms.max_score
ORDER BY pwd.department_referral;
