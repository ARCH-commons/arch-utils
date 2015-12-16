--*****************************************************************************************			
--*****************************************************************************************			
--*** INTRODUCTION			
--*****************************************************************************************			
--*****************************************************************************************			
--			
--/*			
--			
--Identifying loyalty cohorts in an i2b2 database			
--Griffin M Weber, MD, PhD			
--weber@hms.harvard.edu			
--January 14, 2015			
--			
--This script identifies "loyalty cohorts", or patients with "complete" data in an i2b2 CRC			
--database. It uses a set of 16 heuristic filters. All combinations of filters are tested,			
--creating 2^16 = 65536 possible loyalty cohorts. Summary statistics about each loyalty			
--cohort are generated to help select the best set of filters for a given application.			
--			
--This script is designed to be run in a standard implementation of the i2b2 CRC cell 			
--(version 1.3 or higher) in Microsoft SQL Server 2005 or later. In a i2b2 database with			
--2.5 million patients and 270 million facts, the script required about 1 GB of storage			
--and took about 10 minutes to run. Though, this can vary greatly depending on the data			
--and hardware.			
--			
--The script creates several tables in the default schema with the prefix "loyalty_cohort_".			
--At the end of the script are commented out statements which can be used to drop these new 			
--tables. If you do not have permissions to create new tables in your CRC database, then 			
--try a global replace of "loyalty_cohort_" with "#loyalty_cohort_" to create the tables 			
--in the temp database.			
--READ ALL COMMENTS IN THIS FILE!!! You will need to make modifications based on the			
--particular ontology paths and codes in your i2b2 database. The queries that you will			
--most likely need to modify are indicated by comments that start with the phrase			
--"*** INSTRUCTIONS ***" and explain what you need to do. Comments that start with			
--"*** NOTE ***" also contain important information.			
--			
--The output of this script is three recordsets, which provide aggregate counts of the 			
--number of patients who match each filter and summary statistics about those patients.			
--These values will be combined with other sites to determine the total number of loyalty			
--cohort patients in the network.			
--			
--There are additional queries at the bottom of the script that are commented out. These			
--present the results in a more readable way than the raw counts.			
--			
--*** At the bottom of this script are commands to drop all the loyalty_cohort tables.			
--Make sure you drop or rename those tables before running this script a second time.			
--*/			
--			
--*****************************************************************************************			
--*****************************************************************************************			
--*** DEFINE FILTERS			
--*****************************************************************************************			
--*****************************************************************************************			
--			
-------------------------------------------------------------------------------------------			
-- Individual Filters			
-------------------------------------------------------------------------------------------			
--			
			
			
			
			
drop table loyalty_cohort_filters;			
drop table loyalty_cohort_filter_sets;			
drop table loyalty_cohort_concept_type;			
drop table loyalty_chrt_pat_cncpt_type;			
drop table loyalty_cohort_patient_facts;			
drop table loyalty_cohort_patient_filter;			
drop table loyalty_cohort_patient_summary;			
			
			
create table loyalty_cohort_filters (			
    filter number primary key,			
    filter_bit  number,			
    description varchar2(100)			
);			
			
insert into loyalty_cohort_filters (filter,description) values (1,'AgeSex');			
insert into loyalty_cohort_filters (filter,description) values (2,'Race');			
insert into loyalty_cohort_filters (filter,description) values (3,'SameState');			
insert into loyalty_cohort_filters (filter,description) values (4,'All6MonthPeriods');			
insert into loyalty_cohort_filters (filter,description) values (5,'All1YearPeriods');			
insert into loyalty_cohort_filters (filter,description) values (6,'FirstLastYear');			
insert into loyalty_cohort_filters (filter,description) values (7,'Diagnoses');			
insert into loyalty_cohort_filters (filter,description) values (8,'Medications');			
insert into loyalty_cohort_filters (filter,description) values (9,'LabTests');			
insert into loyalty_cohort_filters (filter,description) values (10,'VitalSigns');			
insert into loyalty_cohort_filters (filter,description) values (11,'RoutineVisit');			
insert into loyalty_cohort_filters (filter,description) values (12,'OutpatientVisit');			
insert into loyalty_cohort_filters (filter,description) values (13,'Alive');			
insert into loyalty_cohort_filters (filter,description) values (14,'NoSmallFactCount');			
insert into loyalty_cohort_filters (filter,description) values (15,'FirstLast18Months');			
insert into loyalty_cohort_filters (filter,description) values (16,'AgeCutoffs');			
			
update loyalty_cohort_filters set filter_bit = power(2,filter-1);			
			
commit;			
-------------------------------------------------------------------------------------------			
-- Filter Sets			
-------------------------------------------------------------------------------------------			
			
--/*			
--*** NOTE ***			
--The queries in this section build a list of all 2^16 = 65536 possible combinations of the			
--16 filters. Each combination is a filter "set". The "filters" field is an integer, whose			
--bits correspond to the filters in the set. For example, filters = 13 = 1 + 4 + 8 = (2^0)			
--+ (2^2) + (2^3) = bits 1, 3, and 4 = AgeSex + SameState + All6MonthPeriods. The filter			
--set with filters = 0 contains no filters and matches all patients. Patients who pass the			
--filter set with filters = 65535 match all filters. In SQL Server the "and" symbol is the			
--Bitwise AND operator.			
--*/			
			
create table loyalty_cohort_filter_sets (			
    filter_set number primary key,			
    num_filters  number,			
    bit_list varchar2(4000),			
    filter_list varchar2(4000)			
);			
			
insert into loyalty_cohort_filter_sets (filter_set,num_filters,bit_list,filter_list)			
with n as (			
	select a.n+b.n*8+c.n*8*8+d.n*8*8*8+e.n*8*8*8*8+f.n*8*8*8*8*8 n		
    from (select filter-1 n from loyalty_cohort_filters where filter < 9) a			
        cross join (select filter-1 n from loyalty_cohort_filters where filter < 9) b			
        cross join (select filter-1 n from loyalty_cohort_filters where filter < 9) c			
        cross join (select filter-1 n from loyalty_cohort_filters where filter < 9) d			
        cross join (select filter-1 n from loyalty_cohort_filters where filter < 9) e			
	cross join (select filter-1 n from loyalty_cohort_filters where filter < 3) f		
)			
			
    select n.n, count(*) m, '', ''			
    from n inner join loyalty_cohort_filters f			
        on f.filter_bit = bitand(n.n,f.filter_bit)			
    group by n.n;			
			
			
commit;			
			
begin			
for i in (select filter from loyalty_cohort_filters order by filter)			
loop			
update loyalty_cohort_filter_sets s			
set 			
  bit_list = bit_list || ',' || (select to_char(f.filter) from loyalty_cohort_filters f where f.filter = i.filter),			
  filter_list = filter_list || ','|| (select f.description from loyalty_cohort_filters f where f.filter = i.filter)			
where exists (select * from loyalty_cohort_filters f where f.filter = i.filter AND f.filter_bit = BITAND(s.filter_set, f.filter_bit));			
			
commit;			
			
end loop ;			
update loyalty_cohort_filter_sets set bit_list = substr(bit_list,2), filter_list = substr(filter_list,2);			
			
insert into loyalty_cohort_filter_sets (filter_set,num_filters,bit_list,filter_list) values (0,0,'0','None');			
commit;			
end;			
			
			
--*****************************************************************************************			
--*****************************************************************************************			
--*** GET TEMP INFO ABOUT PATIENTS			
--*****************************************************************************************			
--*****************************************************************************************			
			
-------------------------------------------------------------------------------------------			
-- Map concepts to categories			
-------------------------------------------------------------------------------------------			
			
create table loyalty_cohort_concept_type (			
    concept_cd varchar2(50) primary key,			
    concept_type varchar2(1) not null			
);			
			
--/*			
--*** INSTRUCTIONS ***			
--Modify the expressions in the query below to select paths that correspond to 			
--diagnoses (D), medications (M), lab tests (L), procedures (P), or vital signs (V).			
--A special case is diagnoses that correspond to "routine visits", which should be mapped			
--to "C". These diagnoses are ICD-9 codes V20.2 (routine infant or child health check),			
--V70.0 (routine general medical examination at a health care facility), and V72.31			
--(routine gynecological examination).			
--*/			
			
insert into loyalty_cohort_concept_type (concept_cd, concept_type)			
    select concept_cd, concept_type			
    from (			
        select concept_cd,			
            min(case when concept_path like '\PCORI\DIAGNOSIS\09\%' and concept_cd in ('ICD9:V20.2','ICD9:V70.0','ICD9:V72.31') then 'C'			
                when concept_path like '\PCORI\DIAGNOSIS\09\%' then 'D'			
                when concept_path like '\PCORI\MEDICATION\RXNORM_CUI\%' then 'M'			
                when concept_path like '\PCORI\LAB_RESULT_CM\%' then 'L'			
                when concept_path like '\PCORI\PROCEDURE\%' then 'P'			
                when concept_path like '\PCORI\VITAL\%' then 'V'			
                else null end) concept_type			
        from concept_dimension			
        group by concept_cd			
    ) t			
    where concept_type is not null;			
			
-------------------------------------------------------------------------------------------			
-- Determine how many facts each patient has per category and time period			
-------------------------------------------------------------------------------------------			
			
create table loyalty_chrt_pat_cncpt_type (			
    patient_num number not null,			
    time_period number not null,			
    concept_type varchar2(1) not null,			
    num_facts number			
);			
			
--/*			
--*** NOTE ***--			
--Observations are grouped into 8 time periods, defined as 6 month blocks covering 4 yeras,			
--starting on July 1, 2010, and going through June 30, 2014. Time period 0 spans 7/1/2010			
--through 12/31/2010.			
--*/			
			
insert into loyalty_chrt_pat_cncpt_type (patient_num, time_period, concept_type, num_facts)			
    select patient_num, time_period, concept_type, count(*) num_facts			
    from (			
        select f.patient_num,			
             floor(months_between( start_date,to_date('01-Jul-2010','dd-mon-rrrr'))/6) time_period,			
            c.concept_type			
        from observation_fact f			
            inner join loyalty_cohort_concept_type c			
                on f.concept_cd = c.concept_cd			
        where  start_date between to_date('01-Jul-2010','dd-mon-rrrr') and to_date('30-Jun-2014','dd-mon-rrrr')			
    ) t			
    group by patient_num, time_period, concept_type;			
			
-------------------------------------------------------------------------------------------			
-- Determine the visit types for each patient and time period			
-------------------------------------------------------------------------------------------			
			
--/*			
--*** INSTRUCTIONS ***			
--The query below uses the inout_cd field of the visit_dimension to identify outpatient "O",			
--inpatient "I", and ED "E" visits. Modify this query if you use different codes or			
--represent visit type in a different way.			
--*/			
			
insert into loyalty_chrt_pat_cncpt_type (patient_num, time_period, concept_type, num_facts)			
    select patient_num, time_period, concept_type, count(*) num_facts			
    from (			
        select patient_num,			
            floor(months_between( start_date,to_date('01-Jul-2010','dd-mon-rrrr'))/6) time_period,			
            (case when inout_cd = 'O' then 'O'			
                when inout_cd = 'I' then 'I'			
                when inout_cd = 'E' then 'E'			
                else null end) concept_type			
        from visit_dimension			
        where  start_date between to_date('01-Jul-2010','dd-mon-rrrr') and to_date('30-Jun-2014','dd-mon-rrrr')			
    ) t			
    where concept_type in ('O','I','E')			
    group by patient_num, time_period, concept_type;			
			
alter table loyalty_chrt_pat_cncpt_type add primary key (patient_num, time_period, concept_type);			
			
-------------------------------------------------------------------------------------------			
-- Determine the total number of facts for each patient			
-------------------------------------------------------------------------------------------			
			
create table loyalty_cohort_patient_facts (			
    patient_num int not null,			
    num_facts int			
);			
			
insert into loyalty_cohort_patient_facts			
    select patient_num, sum(num_facts) num_facts			
    from loyalty_chrt_pat_cncpt_type			
    where concept_type not in ('O','I','E')			
    group by patient_num;			
			
alter table loyalty_cohort_patient_facts add primary key (patient_num);			
			
			
--*****************************************************************************************			
--*****************************************************************************************			
--*** DETERMINE WHICH FILTERS EACH PATIENT PASSES			
--*****************************************************************************************			
--*****************************************************************************************			
			
--/*			
--*** INSTRUCTIONS ***			
--Examine each query in this section to determine whether you need to modify it. In			
--particular, check the codes used for sex, race, and vital status; the zip_cd pattern;			
--and how to determine if the patient has a PCP at your institution. Don't worry if you do			
--not have the data for a filter. Just comment out that query. Zero patients will match			
--the filter, but that is ok. Part of this experiment is to determine what types of filters			
--work at different sites.			
--*/			
			
-- Create the table			
create table loyalty_cohort_patient_filter (			
    patient_num number not null,			
    filter number not null			
)			
;			
			
-- All patients			
insert into loyalty_cohort_patient_filter (patient_num, filter)			
    select patient_num, 0			
    from patient_dimension;			
			
-- AgeSex			
insert into loyalty_cohort_patient_filter (patient_num, filter)			
    select patient_num, 1			
    from patient_dimension			
    where birth_date is not null and sex_cd in ('M','F');			
			
-- Race			
insert into loyalty_cohort_patient_filter (patient_num, filter)			
    select patient_num, 2			
    from patient_dimension			
    where race_cd is not null and race_cd not in ('@','U');			
    			
    commit;			
			
-- State			
--/*			
--*** INSTRUCTIONS ***			
--Change the query to match zip codes in your state. The pattern below is for MA.			
--*/			
insert into loyalty_cohort_patient_filter (patient_num, filter)			
    select patient_num, 3			
    from patient_dimension			
    where  regexp_like (zip_cd, '^2([7-8])');			
			
-- All6MonthPeriods			
insert into loyalty_cohort_patient_filter (patient_num, filter)			
    select patient_num, 4			
    from loyalty_chrt_pat_cncpt_type			
    group by patient_num			
    having count(distinct time_period) >= 8;			
			
-- All1YearPeriods			
insert into loyalty_cohort_patient_filter (patient_num, filter)			
    select patient_num, 5			
    from (			
        select distinct patient_num, floor(time_period/2) time_period_year			
        from loyalty_chrt_pat_cncpt_type			
    ) t			
    group by patient_num			
    having count(distinct time_period_year) >= 4;			
    			
			
			
-- FirstLastYear			
insert into loyalty_cohort_patient_filter (patient_num, filter)			
    select patient_num, 6			
    from (			
        select distinct patient_num, 			
            (case when time_period in (0,1) then 0 else 6 end) time_period			
        from loyalty_chrt_pat_cncpt_type			
        where time_period in (0,1,6,7)			
    ) t			
    group by patient_num			
    having count(distinct time_period) = 2;			
			
-- ConceptTypes			
insert into loyalty_cohort_patient_filter (patient_num, filter)			
    select distinct patient_num,			
        (case when concept_type in ('C','D') then 7			
            when concept_type = 'M' then 8			
            when concept_type = 'L' then 9			
            when concept_type = 'V' then 10			
            when concept_type = 'O' then 12			
            else null end)			
    from loyalty_chrt_pat_cncpt_type			
    where concept_type in ('C','D','M','L','V','O');			
    			
			
-- RoutineVisit			
insert into loyalty_cohort_patient_filter (patient_num, filter)			
    select distinct patient_num, 11			
    from loyalty_chrt_pat_cncpt_type			
    where concept_type = 'C';			
			
-- Alive			
--/*			
--*** INSTRUCTIONS ***			
--Change the query to select patients who are alive, based on the vital_status_cd,			
--death_date, or other fields in your database. 			
--*/			
insert into loyalty_cohort_patient_filter (patient_num, filter)			
    select patient_num, 13			
   from patient_dimension			
    where vital_status_cd != 'Y';			
-- NoSmallFactCount			
--/*			
--*** NOTE ***			
--This query filters out patients whose total fact count is in the bottom 10%			
--for their 10-year age group and sex.			
--*/			
insert into loyalty_cohort_patient_filter (patient_num, filter)			
    select patient_num, 14			
    from (			
        select patient_num, ntile(10) over (partition by a, s order by f, patient_num) k			
        from (			
            select p.patient_num, floor(age_in_years_num/10) a, sex_cd s, nvl(f.num_facts,0) f			
            from patient_dimension p			
                inner join loyalty_cohort_patient_facts f			
                    on p.patient_num = f.patient_num			
        ) t			
    ) t			
    where k > 1;			
			
-- FirstLast18Months			
insert into loyalty_cohort_patient_filter (patient_num, filter)			
	select patient_num, 15		
	from (		
		select distinct patient_num, 	
			(case when time_period in (0,1,2) then 0 else 5 end) time_period
		from loyalty_chrt_pat_cncpt_type	
		where time_period in (0,1,2,5,6,7)	
	) t		
	group by patient_num		
	having count(distinct time_period) = 2;		
			
-- AgeCutoffs			
--/*			
--*** INSTRUCTIONS ***			
--Pediatric hospitals should uncomment the clause that selects only patients whose age			
--is "< 30". Adult hospitals that typically do not see children should uncomment the			
--clause the selects only patients whose age is ">= 20". Hospitals that treat patients			
--of all ages should not modify this query.			
--*/			
insert into loyalty_cohort_patient_filter (patient_num, filter)			
	select patient_num, 16		
	from patient_dimension		
	where birth_date is not null;		
		#NAME?	
		#NAME?	
			
-- Add primary key			
alter table loyalty_cohort_patient_filter add primary key (patient_num, filter);			
			
			
--*****************************************************************************************			
--*****************************************************************************************			
--*** SUMMARIZE PATIENT INFO			
--*****************************************************************************************			
--*****************************************************************************************			
			
			
create table loyalty_cohort_patient_summary (			
    patient_num int not null,			
    filter_set  number,			
    num_facts  number,			
    num_diagnoses  number,			
    routine_visits  number,			
    outpatient_visits  number,			
    inpatient_visits  number,			
    emergency_visits  number,			
    procedures  number,			
    age_group  number,			
    sex_cd varchar2(1)			
);			
			
--/*			
--*** INSTRUCTIONS ***			
--Change the sex_cd codes for male/female if needed.			
--*/			
			
insert into loyalty_cohort_patient_summary			
  with a as (			
    select patient_num,			
        sum(case when filter = 0 then 0 else power(2,filter-1) end) Filters			
    from loyalty_cohort_patient_filter			
    group by patient_num			
),			
 b as (			
    select patient_num, 			
        sum(case when concept_type not in ('O','I','E') then num_facts else 0 end) num_facts,			
        sum(case when concept_type in ('C','D') then 1 else 0 end) num_diagnoses,			
        sum(case when concept_type = 'C' then 1 else 0 end) routine_visits,			
        sum(case when concept_type = 'O' then 1 else 0 end) outpatient_visits,			
        sum(case when concept_type = 'I' then 1 else 0 end) inpatient_visits,			
        sum(case when concept_type = 'E' then 1 else 0 end) emergency_visits,			
        sum(case when concept_type = 'P' then 1 else 0 end) procedures			
    from loyalty_chrt_pat_cncpt_type			
    group by patient_num			
)			
			
 select a.patient_num, a.Filters,			
        nvl(b.num_facts,0), 			
        nvl(b.num_diagnoses,0), 			
        nvl(b.routine_visits,0),			
        nvl(b.outpatient_visits,0),			
        nvl(b.inpatient_visits,0),			
        nvl(b.emergency_visits,0),			
        nvl(b.procedures,0),			
        (case when p.age_in_years_num < 0 then 0			
            when p.age_in_years_num >= 90 then 9			
            else floor(p.age_in_years_num/10) end),			
        (case when p.sex_cd = 'F' then 'F'			
            when p.sex_cd = 'M' then 'M'			
            else NULL end)			
            from a			
          inner join patient_dimension p on a.patient_num = p.patient_num			
        left outer join b on a.patient_num = b.patient_num;			
                			
			
alter table loyalty_cohort_patient_summary add primary key (patient_num);			
			
create unique  index idx_fp on loyalty_cohort_patient_summary(filter_set,patient_num);			
			
			
--*****************************************************************************************			
--*****************************************************************************************			
--*** CREATE REPORTS			
--*****************************************************************************************			
--*****************************************************************************************			
			
-------------------------------------------------------------------------------------------			
-- Number of patients who pass each filter independently			
-------------------------------------------------------------------------------------------			
with a as (			
    select filter, count(*) n			
    from loyalty_cohort_patient_filter			
    group by filter			
)			
select f.filter, f.description, nvl(a.n,0) patients			
        from loyalty_cohort_filters f			
            left outer join a			
                on f.filter = a.filter			
    union all			
    select 0, 'AllPatients', count(*)			
        from loyalty_cohort_patient_summary			
    order by 1;			
			
-------------------------------------------------------------------------------------------			
-- Number of patients who pass each filter set			
-------------------------------------------------------------------------------------------			
select filter_set, 			
        count(*) num_patients, 			
        sum(cast(num_facts as number)) total_facts,			
        sum(num_diagnoses) total_diagnoses,			
        sum(routine_visits) total_routine_visits,			
        sum(outpatient_visits) total_outpatient_visits,			
        sum(inpatient_visits) total_inpatient_visits,			
        sum(emergency_visits) total_emergency_visits,			
        sum(procedures) total_procedures,			
        sum(case when num_diagnoses > 0 then 1 else 0 end) patients_with_diagnoses,			
        sum(case when routine_visits > 0 then 1 else 0 end) patients_with_routine_visits,			
        sum(case when outpatient_visits > 0 then 1 else 0 end) patients_with_outpatient_visit,			
        sum(case when inpatient_visits > 0 then 1 else 0 end) patients_with_inpatient_visits,			
        sum(case when emergency_visits > 0 then 1 else 0 end) patients_with_emergency_visits,			
        sum(case when procedures > 0 then 1 else 0 end) patients_with_procedures,			
        sum(case when sex_cd = 'F' then 1 else 0 end) female_patients,			
        sum(case when sex_cd = 'M' then 1 else 0 end) male_patients,			
        nvl(sum(cast(age_group as number)),-1) sum_age_group			
    from loyalty_cohort_patient_summary			
    group by filter_set ;			
-------------------------------------------------------------------------------------------			
-- Number of patients who pass each filter set, broken down by age_group and sex_cd			
-------------------------------------------------------------------------------------------			
select filter_set, nvl(age_group,-1) age_group, nvl(sex_cd,'@') sex_cd,			
        count(*) num_patients, 			
        sum(cast(num_facts as number)) total_facts			
    from loyalty_cohort_patient_summary			
    group by filter_set, age_group, sex_cd order by filter_set, age_group, sex_cd ;			
			
--*****************************************************************************************			
--*****************************************************************************************			
--*** EXTRA OPTIONAL REPORTS			
--*****************************************************************************************			
--*****************************************************************************************			
			
/*			
			
-------------------------------------------------------------------------------------------			
-- Summary of patients who pass each filter independently			
-------------------------------------------------------------------------------------------			
with t as (			
    select filter, description, filter_bit from loyalty_cohort_filters			
    union all			
    select 17, 'None (All Patients)', 0 from dual			
)			
select t.filter, t.description, 			
        count(*) num_patients, 			
        count(*)/(select count(*)*1.0 total_patients from loyalty_cohort_patient_summary) frac_patients,			
        avg(num_facts*1.0) avg_num_facts,			
        avg(num_diagnoses*1.0) avg_num_diagnoses,			
        avg(routine_visits*1.0) avg_routine_visits,			
        sum(case when routine_visits = 0 then 0 else 1 end)/(count(*)*1.0) frac_routine_visits,			
        sum(case when outpatient_visits = 0 then 0 else 1 end)/(count(*)*1.0) frac_outpatient_visits,			
        sum(case when inpatient_visits = 0 then 0 else 1 end)/(count(*)*1.0) frac_inpatient_visits,			
        sum(case when emergency_visits = 0 then 0 else 1 end)/(count(*)*1.0) frac_emergency_visits,			
        sum(case when procedures = 0 then 0 else 1 end)/(count(*)*1.0) frac_procedures			
    from loyalty_cohort_patient_summary s			
        inner join t on t.filter_bit = bitand(s.filter_set,t.filter_bit)			
    group by t.filter, t.description			
    order by 1			
			
			
			
-------------------------------------------------------------------------------------------			
-- Pairs of filters			
-------------------------------------------------------------------------------------------			
with t as (			
    select a.filter filter1, b.filter filter2, a.description desc1, b.description desc2, 			
        count(*) num_patients, avg(num_facts*1.0) avg_facts			
    from loyalty_cohort_filters a			
        cross join loyalty_cohort_filters b			
        inner join loyalty_cohort_patient_summary t			
            on a.filter_bit =bitand(t.filter_set, a.filter_bit)			
                and b.filter_bit =bitand(t.filter_set, b.filter_bit)			
    group by a.filter, b.filter, a.description, b.description			
)			
select t.filter1, t.filter2, t.desc1, t.desc2, 			
        t.num_patients/(v.num_patients*1.0) frac_patients, t.num_patients, t.avg_facts			
    from t inner join t v on t.filter1 = v.filter1 and t.filter1 = v.filter2			
    order by 1, 2			
			
-------------------------------------------------------------------------------------------			
-- Number of patients who pass each filter set			
-------------------------------------------------------------------------------------------			
select			
 t.filter_set, count(*) num_patients, 			
        avg(num_facts*1.0) avg_num_facts,			
        avg(num_diagnoses*1.0) avg_num_diagnoses,			
        avg(routine_visits*1.0) avg_routine_visits,			
        sum(case when routine_visits = 0 then 0 else 1 end)/(count(*)*1.0) frac_routine_visits,			
        sum(case when outpatient_visits = 0 then 0 else 1 end)/(count(*)*1.0) frac_outpatient_visits,			
        sum(case when inpatient_visits = 0 then 0 else 1 end)/(count(*)*1.0) frac_inpatient_visits,			
        sum(case when emergency_visits = 0 then 0 else 1 end)/(count(*)*1.0) frac_emergency_visits,			
        sum(case when procedures = 0 then 0 else 1 end)/(count(*)*1.0) frac_procedures,			
        t.bit_list,			
        t.filter_list			
    from loyalty_cohort_patient_summary s			
        inner join loyalty_cohort_filter_sets t on  t.filter_set = bitand(s.filter_set,t.filter_set)			
    group by t.filter_set, t.bit_list, t.filter_list			
			
-------------------------------------------------------------------------------------------			
-- Filters applied sequentially (one example of a ordering)			
-------------------------------------------------------------------------------------------			
declare @f table (i int identity(1,1) primary key, f  number, g int)			
insert into @f (f) values (0); --AllPatients			
insert into @f (f) values (1); --AgeSex			
insert into @f (f) values (2); --Race			
insert into @f (f) values (13); --Alive			
insert into @f (f) values (3); --SameState			
insert into @f (f) values (15); --FirstLast18Months			
insert into @f (f) values (14); --NoSmallFactCount			
insert into @f (f) values (7); --Diagnoses			
insert into @f (f) values (16); --AgeCutoffs			
insert into @f (f) values (10); --VitalSigns			
insert into @f (f) values (9); --LabTests			
insert into @f (f) values (8); --Medications			
insert into @f (f) values (12); --OutpatientVisit			
insert into @f (f) values (11); --RoutineVisit			
insert into @f (f) values (6); --FirstLastYear			
insert into @f (f) values (5); --All1YearPeriods			
insert into @f (f) values (4); --All6MonthPeriods			
update f			
    set f.g = t.g			
    from @f f inner join (			
        select f.i, f.f, sum(case when e.f=0 then 0 else power(2,e.f-1) end) g			
        from @f f inner join @f e on e.i <= f.i			
        group by f.i, f.f			
    ) t on f.i = t.i			
			
;with t as (			
    select g.i, g.f, g.g, isnull(f.description,'AllPatients') d			
    from @f g			
        left outer join loyalty_cohort_filters f			
            on g.f = f.filter			
)			
select t.i, t.f, t.d description, count(*) num_patients, 			
        avg(num_facts*1.0) avg_num_facts,			
        avg(num_diagnoses*1.0) avg_num_diagnoses,			
        avg(routine_visits*1.0) avg_routine_visits,			
        sum(case when routine_visits = 0 then 0 else 1 end)/(count(*)*1.0) frac_routine_visits,			
        sum(case when outpatient_visits = 0 then 0 else 1 end)/(count(*)*1.0) frac_outpatient_visits,			
        sum(case when inpatient_visits = 0 then 0 else 1 end)/(count(*)*1.0) frac_inpatient_visits,			
        sum(case when emergency_visits = 0 then 0 else 1 end)/(count(*)*1.0) frac_emergency_visits,			
        sum(case when procedures = 0 then 0 else 1 end)/(count(*)*1.0) frac_procedures			
    from loyalty_cohort_patient_summary s			
        inner join t on s.filter_set bitand t.g = t.g			
    group by t.i, t.f, t.d			
    order by 1			
			
*/			
			
--*****************************************************************************************			
--*****************************************************************************************			
--*** CLEANUP			
--*****************************************************************************************			
--*****************************************************************************************			
			
/*			
*** INSTRUCTIONS ***			
Remove the comments to drop the tables created by this script.			
*/			
			
/*			
drop table loyalty_cohort_filters			
drop table loyalty_cohort_filter_sets			
drop table loyalty_cohort_concept_type			
drop table loyalty_chrt_pat_cncpt_type			
drop table loyalty_cohort_patient_facts			
drop table loyalty_cohort_patient_filter			
drop table loyalty_cohort_patient_summary			
*/			
			
			
			
--drop table loyalty_cohort_filters;			
--drop table loyalty_cohort_filter_sets;			
--drop table loyalty_cohort_concept_type;			
--drop table loyalty_chrt_pat_cncpt_type;			
--drop table loyalty_cohort_patient_facts;			
--drop table loyalty_cohort_patient_filter;			
--drop table loyalty_cohort_patient_summary;			
