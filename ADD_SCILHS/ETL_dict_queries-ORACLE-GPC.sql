/* ETL_dict_queries.sql - SQL queries to help fill out the "ETL Annotated Data 
Dictionary" form required by PCORI.  

See GPC ticket 144:
https://informatics.gpcnetwork.org/trac/Project/ticket/144

Attachment:
"PCORnet ETL Annotated Data Dictionary V1.0.xlsx"
*/

/* Questions from PCORnet ETL Annotated Data Dictionary V1.0.xlsx
*/
select ts.demographics section, count(*) "Unique PATIDs" from ts, demographics;

select ts.demographics section, min(birth_date) "Minimum BIRTH_DATE", max(birth_date) "Maximum BIRTH_DATE" 
from ts, demographics;

with agg as (
  select count(*) denom from demographics
  ),
breakdown as (
  select sex, count(*) cnt 
  from demographics
  group by sex
  )
select ts.demographics section, breakdown.sex "Sex", breakdown.cnt "Count", round((breakdown.cnt / agg.denom) * 100) "Percent"
from ts, breakdown, agg;

with agg as (
  select count(*) denom from demographics
  ),
breakdown as (
  select race, count(*) cnt 
  from demographics
  group by race
  )
select ts.demographics section, breakdown.race "Race", breakdown.cnt "Count", round((breakdown.cnt / agg.denom) * 100, 2) "Percent"
from ts, breakdown, agg
order by breakdown.race
;

-- Encounter
select ts.encounter section, count(distinct patid) "Unique PATIDs" from ts, encounter;

select ts.encounter section, min(admit_date) "Minimum ADMIT_DATE", max(admit_date) "Maximum ADMIT_DATE" from ts, encounter;

with agg as (
  select count(*) denom from encounter
  ),
breakdown as (
  select enc_type, count(*) cnt 
  from encounter
  group by enc_type
  )
select ts.encounter section,
  breakdown.enc_type "ENC_TYPE", breakdown.cnt "Count", 
  round((breakdown.cnt / agg.denom) * 100, 2) "Percent"
from ts, breakdown, agg
order by breakdown.enc_type
; 

-- Diagnosis Type
select ts.diagnosis section, count(distinct patid) "Unique PATIDs" from ts, diagnosis;
select ts.diagnosis section, min(admit_date) "Minimum ADMIT_DATE", max(admit_date) "Maximum ADMIT_DATE" from ts, diagnosis;

with agg as (
  select count(*) denom from diagnosis
  ),
breakdown as (
  select dx_type, count(*) cnt 
  from diagnosis
  group by dx_type
  )
select ts.diagnosis section,
  breakdown.dx_type "DX_TYPE", breakdown.cnt "Count", 
  round((breakdown.cnt / agg.denom) * 100, 2) "Percent"
from ts, breakdown, agg
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
  select patid, encounterid, enc_type, max(dx) dx from diagnosis
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
select ts.diagnosis section,
  breakdown.enc_type "ENC_TYPE", breakdown.cnt "Count", 
  round((breakdown.cnt / agg.denom) * 100, 2) "Percent"
from ts, breakdown, agg
order by breakdown.enc_type
; 


-- Procedure
select ts."PROCEDURE" section, count(distinct patid) "Unique PATIDs" from ts, "PROCEDURE";

select ts."PROCEDURE" section, min(admit_date) "Minimum ADMIT_DATE", max(admit_date) "Maximum ADMIT_DATE" from ts, "PROCEDURE";

with 
one_proc_per_enc as (
  select patid, encounterid, enc_type, max(px) px from "PROCEDURE"
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
select ts."PROCEDURE" section,
  breakdown.enc_type "ENC_TYPE", breakdown.cnt "Count", 
  round((breakdown.cnt / agg.denom) * 100, 2) "Percent"
from ts, breakdown, agg
order by breakdown.enc_type
;

with agg as (
  select count(*) denom from "PROCEDURE"
  ),
breakdown as (
  select px_type, count(*) cnt 
  from "PROCEDURE"
  group by px_type
  )
select ts."PROCEDURE" section,
  breakdown.px_type "PX_TYPE", breakdown.cnt "Count", 
  round((breakdown.cnt / agg.denom) * 100, 2) "Percent"
from ts, breakdown, agg
order by breakdown.px_type
;

-- Vital
select ts.vital section, count(distinct patid) "Unique PATIDs" from ts, vital;

select ts.vital section, min(admit_date) "Minimum ADMIT_DATE", max(admit_date) "Maximum ADMIT_DATE" from ts, vital;

with agg as (
  select count(*) denom from vital
  ),
breakdown as (
  select vital_source, count(*) cnt 
  from vital
  group by vital_source
  )
select ts.vital section,
  breakdown.vital_source "VITAL_SOURCE", breakdown.cnt "Count", 
  round((breakdown.cnt / agg.denom) * 100, 2) "Percent"
from ts, breakdown, agg
;

-- Enrollment
select ts.enrollment section, count(distinct patid) "Unique PATIDs" from ts, enrollment;

select ts.enrollment section, min(enr_start) "Minimum ENR_START_DATE", max(enr_start) "Maximum ENR_START_DATE" from ts, enrollment;

with agg as (
  select count(*) denom from enrollment
  ),
breakdown as (
  select basis, count(*) cnt 
  from enrollment
  group by basis
  )
select ts.enrollment section,
  breakdown.basis "ENR_BASIS", breakdown.cnt "Count", 
  round((breakdown.cnt / agg.denom) * 100, 2) "Percent"
from ts, breakdown, agg
;

/*******************************************************************************
PCORI CDM Compliance Worksheet queries
*******************************************************************************/

-- Demographics
with agg as (
  select count(*) denom from demographics
  ),
breakdown as (
  select hispanic, count(*) cnt 
  from demographics
  group by hispanic
  )
select ts.demographics section,
  breakdown.hispanic "Hispanic", breakdown.cnt "Count", 
  round((breakdown.cnt / agg.denom) * 100, 2) "Percent"
from ts, breakdown, agg
;

with total as (
  select count(*) denom from demographics
  ),
bd as (
  select count(*) cnt from demographics where birth_date is not null
  )
select ts.demographics section,
  bd.cnt "Birthdate Count", round((bd.cnt / total.denom) * 100, 2) "Percent"
from ts, bd, total
;

with total as (
  select count(*) denom from demographics
  ),
bfy as (
  select count(*) cnt from demographics where biobank_flag = 'Y'
  ),
bfn as (
  select count(*) cnt from demographics where biobank_flag = 'N'
  )
select ts.demographics section,
  bfy.cnt "Biobank Flag 'Y' Count", round((bfy.cnt / total.denom) * 100, 2) "Percent",
  bfn.cnt "Biobank Flag 'N' Count", round((bfn.cnt / total.denom) * 100, 2) "Percent"
from ts, bfy, bfn, total
;


-- Encounter
with total as (
  select count(*) denom from encounter
  ),
adt as (
  select count(*) cnt from encounter where admit_time is not null
  ),
adtm as (
  select count(*) cnt from encounter where admit_time = '00:00:00'
  )
select ts.encounter section,
  adt.cnt "Admit time not null Count", round((adt.cnt / total.denom) * 100, 2) "Percent",
  adtm.cnt "Admit time midnight", round((adtm.cnt / total.denom) * 100, 2) "Percent"
from ts, adt, adtm, total
;

select ts.encounter section, count(distinct encounterid) "Distinct encounter ID" from ts, encounter;

-- DRG breakdown for inpatient encounters only
with agg as (
  select count(*) denom from encounter where enc_type = 'IP'
  ),
breakdown as (
  select drg_type, count(*) cnt 
  from encounter
  where enc_type = 'IP'
  group by drg_type
  )
select ts.encounter section,
  breakdown.drg_type "DRG type", breakdown.cnt "Count", 
  round((breakdown.cnt / agg.denom) * 100, 2) "Percent"
from ts, breakdown, agg
;


with agg as (
  select count(*) denom from encounter
  ),
breakdown as (
  select discharge_disposition, count(*) cnt 
  from encounter
  group by discharge_disposition
  )
select ts.encounter section,
  breakdown.discharge_disposition "Discharge Disposition", breakdown.cnt "Count", 
  round((breakdown.cnt / agg.denom) * 100, 2) "Percent"
from ts, breakdown, agg
;

with agg as (
  select count(*) denom from encounter
  ),
breakdown as (
  select discharge_status, count(*) cnt 
  from encounter
  group by discharge_status
  )
select ts.encounter section,
  breakdown.discharge_status "Discharge Status", breakdown.cnt "Count", 
  round((breakdown.cnt / agg.denom) * 100, 2) "Percent"
from ts, breakdown, agg
;

-- Diagnosis
select ts.diagnosis section, count(distinct encounterid) "Distinct Encounter ID" from ts, diagnosis;
select ts.diagnosis section, count(distinct patid) "Distinct Patient ID" from ts, diagnosis;

-- Procedure
select ts.procedure section, count(distinct encounterid) "Distinct Encounter ID" from ts, "PROCEDURE";

-- Vitals
with total as (
  select count(*) denom from vital
  ),
ht as (
  select count(*) cnt from vital where ht is not null
  )
select ts.vital section,
  ht.cnt "Height Count", round((ht.cnt / total.denom) * 100, 2) "Percent",
  (total.denom - ht.cnt) "Height Count NI", round(((total.denom - ht.cnt) / total.denom) * 100, 2) "Percent NI"
from ts, ht, total
;

with total as (
  select count(*) denom from vital
  ),
wt as (
  select count(*) cnt from vital where wt is not null
  )
select ts.vital section,
  wt.cnt "Weight Count", round((wt.cnt / total.denom) * 100, 2) "Percent",
  (total.denom - wt.cnt) "Weight Count NI", round(((total.denom - wt.cnt) / total.denom) * 100, 2) "Percent"
from ts, wt, total
;


with total as (
  select count(*) denom from vital
  ),
sys as (
  select count(*) cnt from vital where systolic is not null
  )
select ts.vital section,
  sys.cnt "Systolic Count", round((sys.cnt / total.denom) * 100, 2) "Percent",
  (total.denom - sys.cnt) "Systolic Count NI", round(((total.denom - sys.cnt) / total.denom) * 100, 2) "Percent"
from ts, sys, total
;


with total as (
  select count(*) denom from vital
  ),
dys as (
  select count(*) cnt from vital where diastolic is not null
  )
select ts.vital section,
  dys.cnt "Diastolic Count", round((dys.cnt / total.denom) * 100, 2) "Percent",
  (total.denom - dys.cnt) "Systolic Count NI", round(((total.denom - dys.cnt) / total.denom) * 100, 2) "Percent"
from ts, dys, total
;

with total as (
  select count(*) denom from vital
  ),
bmi as (
  select count(*) cnt from vital where original_bmi is not null
  )
select ts.vital section,
  bmi.cnt "BMI Count", round((bmi.cnt / total.denom) * 100, 2) "Percent",
  (total.denom - bmi.cnt) "BMI Count NI", round(((total.denom - bmi.cnt) / total.denom) * 100, 2) "Percent"
from ts, bmi, total
;

-- Enrollment
with agg as (
  select count(*) denom from enrollment
  ),
breakdown as (
  select chart, count(*) cnt 
  from enrollment
  group by chart
  )
select ts.enrollment section,
  breakdown.chart "Chart", breakdown.cnt "Count", 
  round((breakdown.cnt / agg.denom) * 100, 2) "Percent"
from ts, breakdown, agg
;