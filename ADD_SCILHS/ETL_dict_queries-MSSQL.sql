/* ETL_dict_queries.sql - SQL queries to help fill out the "ETL Annotated Data 
Dictionary" form required by PCORI.  

See GPC ticket 144:
https://informatics.gpcnetwork.org/trac/Project/ticket/144

Attachment:
"PCORnet ETL Annotated Data Dictionary V1.0.xlsx"

Updated for SCILHS and SQL Server by Jeff Klann, PhD 12/11/14:
- Table names changed
- Cast to float added for percentages
- 'Section' literals changed or MSSQL
*/

/* Questions from PCORnet ETL Annotated Data Dictionary V1.0.xlsx
*/
select 'Demographics' section, count(*) "Unique PATIDs" from  pmndemographic;

select 'Demographics' section, min(birth_date) "Minimum BIRTH_DATE", max(birth_date) "Maximum BIRTH_DATE" 
from  pmndemographic;

with agg as (
  select count(*) denom from pmndemographic
  ),
breakdown as (
  select sex, count(*) cnt 
  from pmndemographic
  group by sex
  )
select 'Demographics' section, breakdown.sex "Sex", breakdown.cnt "Count",ROUND(((cast (breakdown.cnt as FLOAT)) / agg.denom) * 100,0) "Percent"
from  breakdown, agg;

with agg as (
  select count(*) denom from pmndemographic
  ),
breakdown as (
  select race, count(*) cnt 
  from pmndemographic
  group by race
  )
select 'Demographics' section, breakdown.race "Race", breakdown.cnt "Count", round((CAST (breakdown.cnt AS FLOAT) / agg.denom) * 100, 0) "Percent"
from  breakdown, agg
order by breakdown.race
;

-- Encounter
select 'Encounter' section, count(distinct patid) "Unique PATIDs" from  PMNencounter;

select 'Encounter' section, min(admit_date) "Minimum ADMIT_DATE", max(admit_date) "Maximum ADMIT_DATE" from  PMNencounter;

with agg as (
  select count(*) denom from PMNencounter
  ),
breakdown as (
  select enc_type, count(*) cnt 
  from PMNencounter
  group by enc_type
  )
select 'Encounter' section,
  breakdown.enc_type "ENC_TYPE", breakdown.cnt "Count", 
  round((CAST(breakdown.cnt AS FLOAT)/ agg.denom) * 100, 0) "Percent"
from  breakdown, agg
order by breakdown.enc_type
; 

-- Diagnosis Type
select 'Diagnosis' section, count(distinct patid) "Unique PATIDs" from  pmndiagnosis;
select 'Diagnosis' section, min(admit_date) "Minimum ADMIT_DATE", max(admit_date) "Maximum ADMIT_DATE" from  pmndiagnosis;

with agg as (
  select count(*) denom from pmndiagnosis
  ),
breakdown as (
  select dx_type, count(*) cnt 
  from pmndiagnosis
  group by dx_type
  )
select 'Diagnosis' section,
  breakdown.dx_type "DX_TYPE", breakdown.cnt "Count", 
  round((cast(breakdown.cnt as float)/ agg.denom) * 100, 0) "Percent"
from  breakdown, agg
order by breakdown.dx_type
; 


-- Diagnosis encounter type
/* As per: http://listserv.kumc.edu/pipermail/gpc-dev/2014q3/000483.html
DATA SUMMARY.ENCOUNTER.ENC_TYPE should have inclusive stats of all encounters by
type on your site

...DIAGNOSIS.ENC_TYPE should have (fewer) entries and should be all encounters 
populated w diagnosis data

...PROCEDURES.ENC_TYPE should have fewer than ENCOUNTER numbers and should be a 
count of all encounters by type populated with procedure data
*/
with 
one_diag_per_enc as (
  select patid, encounterid, enc_type, max(dx) dx from pmndiagnosis
  group by patid, encounterid, enc_type
  ),
agg as (
  select count(*) denom from one_diag_per_enc
  ),
breakdown as (
  select enc_type, count(*) cnt 
  from one_diag_per_enc
  group by enc_type
  )
select 'Diagnosis' section,
  breakdown.enc_type "ENC_TYPE", breakdown.cnt "Count", 
  round((cast(breakdown.cnt as float)/ agg.denom) * 100, 0) "Percent"
from  breakdown, agg
order by breakdown.enc_type
; 


-- Procedure
select 'Procedure' section, count(distinct patid) "Unique PATIDs" from  pmnprocedure;

select 'Procedure' section, min(admit_date) "Minimum ADMIT_DATE", max(admit_date) "Maximum ADMIT_DATE" from  pmnprocedure;

with 
one_proc_per_enc as (
  select patid, encounterid, enc_type, max(px) px from pmnprocedure
  group by patid, encounterid, enc_type
  ),
agg as (
  select count(*) denom from one_proc_per_enc
  ),
breakdown as (
  select enc_type, count(*) cnt 
  from one_proc_per_enc
  group by enc_type
  )
select 'Procedure' section,
  breakdown.enc_type "ENC_TYPE", breakdown.cnt "Count", 
  round((cast(breakdown.cnt as float) / agg.denom) * 100, 2) "Percent"
from  breakdown, agg
order by breakdown.enc_type
;

with agg as (
  select count(*) denom from pmnprocedure
  ),
breakdown as (
  select px_type, count(*) cnt 
  from pmnprocedure
  group by px_type
  )
select 'Procedure' section,
  breakdown.px_type "PX_TYPE", breakdown.cnt "Count", 
  round((cast(breakdown.cnt as float) / agg.denom) * 100, 2) "Percent"
from  breakdown, agg
order by breakdown.px_type
;

-- Vital
select 'Vitals' section, count(distinct patid) "Unique PATIDs" from  pmnvital;

--jgk: THERE IS NO ADMIT DATE ON THE VITALS TABLE!
select 'Vitals' section, min(measure_date) "Minimum ADMIT_DATE", max(measure_date) "Maximum ADMIT_DATE" from  pmnvital;

with agg as (
  select count(*) denom from pmnvital
  ),
breakdown as (
  select vital_source, count(*) cnt 
  from pmnvital
  group by vital_source
  )
select 'Vitals' section,
  breakdown.vital_source "VITAL_SOURCE", breakdown.cnt "Count", 
  round((cast(breakdown.cnt as float) / agg.denom) * 100, 2) "Percent"
from  breakdown, agg
;

-- Enrollment
select 'Enrollment' section, count(distinct patid) "Unique PATIDs" from  pmnenrollment;

select 'Enrollment' section, min(enr_start_date) "Minimum ENR_START_DATE", max(enr_start_date) "Maximum ENR_START_DATE" from  pmnenrollment;

with agg as (
  select count(*) denom from pmnenrollment
  ),
breakdown as (
  select basis, count(*) cnt 
  from pmnenrollment
  group by basis
  )
select 'Enrollment' section,
  breakdown.basis "ENR_BASIS", breakdown.cnt "Count", 
  round((cast(breakdown.cnt as float) / agg.denom) * 100, 2) "Percent"
from  breakdown, agg
;

/*******************************************************************************
PCORI CDM Compliance Worksheet queries
*******************************************************************************/

-- pmndemographic
with agg as (
  select count(*) denom from pmndemographic
  ),
breakdown as (
  select hispanic, count(*) cnt 
  from pmndemographic
  group by hispanic
  )
select 'demographic' section,
  breakdown.hispanic "Hispanic", breakdown.cnt "Count", 
  round((cast(breakdown.cnt as float) / agg.denom) * 100, 2) "Percent"
from  breakdown, agg
;

with total as (
  select count(*) denom from pmndemographic
  ),
bd as (
  select count(*) cnt from pmndemographic where birth_date is not null
  )
select 'demographic' section,
  bd.cnt "Birthdate Count", round((bd.cnt / total.denom) * 100, 2) "Percent"
from  bd, total
;

with total as (
  select count(*) denom from pmndemographic
  ),
bfy as (
  select count(*) cnt from pmndemographic where biobank_flag = 'Y'
  ),
bfn as (
  select count(*) cnt from pmndemographic where biobank_flag = 'N'
  )
select 'demographic' section,
  bfy.cnt "Biobank Flag 'Y' Count", round((bfy.cnt / total.denom) * 100, 2) "Percent",
  bfn.cnt "Biobank Flag 'N' Count", round((bfn.cnt / total.denom) * 100, 2) "Percent"
from  bfy, bfn, total
;


-- Encounter
with total as (
  select count(*) denom from pmnencounter
  ),
adt as (
  select count(*) cnt from pmnencounter where admit_time is not null
  ),
adtm as (
  select count(*) cnt from pmnencounter where admit_time = '00:00:00'
  )
select 'Encounter' section,
  adt.cnt "Admit time not null Count", round((adt.cnt / total.denom) * 100, 2) "Percent",
  adtm.cnt "Admit time midnight", round((adtm.cnt / total.denom) * 100, 2) "Percent"
from  adt, adtm, total
;

select 'Encounter' section, count(distinct encounterid) "Distinct encounter ID" from  pmnencounter;

-- DRG breakdown for inpatient encounters only
with agg as (
  select count(*) denom from pmnencounter where enc_type = 'IP'
  ),
breakdown as (
  select drg_type, count(*) cnt 
  from pmnencounter
  where enc_type = 'IP'
  group by drg_type
  )
select 'Encounter' section,
  breakdown.drg_type "DRG type", breakdown.cnt "Count", 
  round((cast(breakdown.cnt as float) / agg.denom) * 100, 2) "Percent"
from  breakdown, agg
;


with agg as (
  select count(*) denom from pmnencounter
  ),
breakdown as (
  select discharge_disposition, count(*) cnt 
  from pmnencounter
  group by discharge_disposition
  )
select 'Encounter' section,
  breakdown.discharge_disposition "Discharge Disposition", breakdown.cnt "Count", 
  round((cast(breakdown.cnt as float) / agg.denom) * 100, 2) "Percent"
from  breakdown, agg
;

with agg as (
  select count(*) denom from pmnencounter
  ),
breakdown as (
  select discharge_status, count(*) cnt 
  from pmnencounter
  group by discharge_status
  )
select 'Encounter' section,
  breakdown.discharge_status "Discharge Status", breakdown.cnt "Count", 
  round((cast(breakdown.cnt as float) / agg.denom) * 100, 2) "Percent"
from  breakdown, agg
;

-- Diagnosis
select 'Diagnosis' section, count(distinct encounterid) "Distinct Encounter ID" from  pmndiagnosis;
select 'Diagnosis' section, count(distinct patid) "Distinct Patient ID" from  pmndiagnosis;

-- Procedure
select 'Procedure' section, count(distinct encounterid) "Distinct Encounter ID" from  pmnprocedure;

-- Vitals
with total as (
  select count(*) denom from pmnvital
  ),
ht as (
  select count(*) cnt from pmnvital where ht is not null
  )
select 'Vitals' section,
  ht.cnt "Height Count", round((cast(ht.cnt as float) / total.denom) * 100, 2) "Percent",
  (total.denom - ht.cnt) "Height Count NI", round(((cast(total.denom as float) - ht.cnt) / total.denom) * 100, 2) "Percent NI"
from  ht, total
;

with total as (
  select count(*) denom from pmnvital
  ),
wt as (
  select count(*) cnt from pmnvital where wt is not null
  )
select 'Vitals' section,
  wt.cnt "Weight Count", round((cast(wt.cnt as float) / total.denom) * 100, 2) "Percent",
  (total.denom - wt.cnt) "Weight Count NI", round(((cast(total.denom as float) - wt.cnt) / total.denom) * 100, 2) "Percent"
from  wt, total
;


with total as (
  select count(*) denom from pmnvital
  ),
sys as (
  select count(*) cnt from pmnvital where systolic is not null
  )
select 'Vitals' section,
  sys.cnt "Systolic Count", round((cast(sys.cnt as float) / total.denom) * 100, 2) "Percent",
  (total.denom - sys.cnt) "Systolic Count NI", round(((cast(total.denom as float) - sys.cnt) / total.denom) * 100, 2) "Percent"
from  sys, total
;


with total as (
  select count(*) denom from pmnvital
  ),
dys as (
  select count(*) cnt from pmnvital where diastolic is not null
  )
select 'Vitals' section,
  dys.cnt "Diastolic Count", round((cast(dys.cnt as float) / total.denom) * 100, 2) "Percent",
  (total.denom - dys.cnt) "Systolic Count NI", round(((cast(total.denom as float) - dys.cnt) / total.denom) * 100, 2) "Percent"
from  dys, total
;

with total as (
  select count(*) denom from pmnvital
  ),
bmi as (
  select count(*) cnt from pmnvital where original_bmi is not null
  )
select 'Vitals' section,
  bmi.cnt "BMI Count", round((cast(bmi.cnt as float) / total.denom) * 100, 2) "Percent",
  (total.denom - bmi.cnt) "BMI Count NI", round(((cast(total.denom as float) - bmi.cnt) / total.denom) * 100, 2) "Percent"
from  bmi, total
;

-- Enrollment
with agg as (
  select count(*) denom from pmnenrollment
  ),
breakdown as (
  select chart, count(*) cnt 
  from pmnenrollment
  group by chart
  )
select 'Enrollment' section,
  breakdown.chart "Chart", breakdown.cnt "Count", 
  round((cast(breakdown.cnt as float) / agg.denom) * 100, 2) "Percent"
from  breakdown, agg
;