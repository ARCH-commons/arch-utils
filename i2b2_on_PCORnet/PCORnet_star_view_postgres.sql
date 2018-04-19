----------------------------------------------------------------------------------------------------------------------------------------
-- Star-schema-based Multifact View of PCORNET CDM v3.0
-- Run this on an instatiation of the PCORnet CDM
-- For use with i2b2-on-PCORnet tools
-- By Matthew Joss with contributions from Jeff Klann, PhD
-- Converted to postgres-compatible by Jeff Klann, PhD
----------------------------------------------------------------------------------------------------------------------------------------

drop view pcornetdemodata.multifact_diagnosis_view;
CREATE VIEW pcornetdemodata.multifact_diagnosis_view
(patient_num, concept_cd, encounter_num, instance_num , provider_id, start_date, modifier_cd, observation_blob,
    valtype_cd, tval_char, nval_num, valueflag_cd, quantity_num, units_cd, end_date, location_cd,
    confidence_num, sourcesystem_cd, update_date, download_date, import_date, upload_id
)
AS
-- PDX AND DX_SOURCE---
SELECT  cast(patid as int4) ,
        CASE when (DX_TYPE = '09') then CONCAT('ICD9:' , DX)
             when (DX_TYPE = '10') then CONCAT('ICD10:' , DX)
        END, 
        cast(ENCOUNTERID as int4),
        1,
        PROVIDERID ,
        ADMIT_DATE ,
        unnest(array[PDX, DX_SOURCE]) AS MODIFIER_CD, 
        cast(null as varchar), --observation_blob
        ENC_TYPE ,
        DX_TYPE , --tval_char
        cast(null as decimal),
        DX_SOURCE , --valueflag_cd
        cast(null as decimal), --quantity_num
        cast(null as varchar),
        cast(null as timestamp), --end_date
        cast(null as varchar),
        cast(null as decimal),
        cast(null as varchar), --sourcesystem_cd
        cast(null as timestamp),
        cast(null as timestamp),
        cast(null as timestamp),
        cast(null as int)
FROM pcornetdemodata.pmndiagnosis
/*UNION ALL
-- CONDITION TABLE --
SELECT  patid ,
        CASE when (CONDITION_TYPE = '09') then CONCAT('ICD9:' , condition)
             when (CONDITION_TYPE = '10') then CONCAT('ICD10:' , condition)
        END, 
        cast(encounterid as int), --may need to do a convert function to convert from varchar to an int
        1,
        '@',
        report_date,
        'CONDITION_SOURCE:'||CONDITION_SOURCE,
        cast(null as varchar), --obs_blob
        cast(null as varchar),
        CONDITION_TYPE, --tval_char
        cast(null as decimal),
        cast(null as varchar) , -- valueflag_cd
        cast(null as decimal),
        cast(null as varchar),
        RESOLVE_DATE , --end_date
        CONDITION_SOURCE , --location_cd
        cast(null as decimal),
        cast(null as varchar),
        cast(null as timestamp), --update_date
        cast(null as timestamp),
        ONSET_DATE , --import_date
        cast(null as int)
FROM pcornetdemodata.PMNCONDITION*/
GO

drop view pcornetdemodata.MULTIFACT_ENROLLMENT_VIEW
GO
CREATE VIEW pcornetdemodata.MULTIFACT_ENROLLMENT_VIEW
(patient_num, concept_cd, encounter_num, instance_num , provider_id, start_date, modifier_cd, observation_blob,
    valtype_cd, tval_char, nval_num, valueflag_cd, quantity_num, units_cd, end_date, location_cd,
    confidence_num, sourcesystem_cd, update_date, download_date, import_date, upload_id
)
AS
SELECT cast(PATID as int4)  ,
        CONCAT('ENR_BASIS:' , ENR_BASIS) ,
         Cast(null as int) ,
        1,
        '@',
        ENR_START_DATE ,
        CHART ,
        cast(null as varchar),
        cast(null as varchar),
        cast(null as varchar),
        cast(null as decimal),
        cast(null as varchar),
        cast(null as decimal),
        cast(null as varchar),
        ENR_END_DATE  ,
        cast(null as varchar),
        cast(null as decimal),
        cast(null as varchar),
        cast(null as timestamp),
        cast(null as timestamp),
        cast(null as timestamp),
        cast(null as int)
FROM pcornetdemodata.pmnENROLLMENT
GO

drop view pcornetdemodata.MULTIFACT_LABRESULTS_VIEW
GO
CREATE VIEW pcornetdemodata.MULTIFACT_LABRESULTS_VIEW
(patient_num, concept_cd, encounter_num, instance_num , provider_id, start_date, modifier_cd, observation_blob,
    valtype_cd, tval_char, nval_num, valueflag_cd, quantity_num, units_cd, end_date, location_cd,
    confidence_num, sourcesystem_cd, update_date, download_date, import_date, upload_id
)
AS
SELECT cast(PATID as int4) ,
        CONCAT('LOINC:' , LAB_LOINC) ,
        cast(ENCOUNTERID as int4),
        1,
        '@',
        SPECIMEN_DATE,
        '@', --used to be RESULT_LOC
        cast(null as varchar),
        CASE when result_num IS NULL then 'T'
             ELSE 'N'
        END,
        CASE when result_num IS NULL then result_qual
             ELSE 'E'
        END,
        RESULT_NUM ,
        cast(null as varchar),
        cast(null as decimal),
        cast(null as varchar),
        RESULT_DATE ,
        cast(null as varchar),
        cast(null as decimal),
        cast(null as varchar),
        cast(null as timestamp),
        cast(null as timestamp),
        cast(null as timestamp),
        cast(null as int)
FROM pcornetdemodata.pmnlab_result_cm
GO

drop view pcornetdemodata.MULTIFACT_PRESCRIBING_VIEW
GO
CREATE VIEW pcornetdemodata.MULTIFACT_PRESCRIBING_VIEW
(patient_num, concept_cd, encounter_num, instance_num , provider_id, start_date, modifier_cd, observation_blob,
    valtype_cd, tval_char, nval_num, valueflag_cd, quantity_num, units_cd, end_date, location_cd,
    confidence_num, sourcesystem_cd, update_date, download_date, import_date, upload_id
)
AS
SELECT cast(PATID as int4),
        CONCAT('RXNORM:' , RXNORM_CUI),
        cast(ENCOUNTERID as int4) ,
        1,
        RX_PROVIDERID ,
        RX_START_DATE ,
        RX_FREQUENCY ,
        cast(null as varchar),
        cast(null as varchar),
        RX_BASIS ,
        cast(RX_QUANTITY as decimal),
        cast(null as varchar),
        cast(null as decimal),
        cast(null as varchar),
        RX_END_DATE ,
        cast(null as varchar),
        cast(null as decimal),
        cast(null as varchar),
        cast(null as timestamp),
        cast(null as timestamp),
        cast(null as timestamp),
        cast(null as int)
FROM pcornetdemodata.pmnprescribing
GO

drop view pcornetdemodata.MULTIFACT_PROCEDURE_VIEW;
CREATE VIEW pcornetdemodata.MULTIFACT_PROCEDURE_VIEW
(patient_num, concept_cd, encounter_num, instance_num , provider_id, start_date, modifier_cd, observation_blob,
    valtype_cd, tval_char, nval_num, valueflag_cd, quantity_num, units_cd, end_date, location_cd,
    confidence_num, sourcesystem_cd, update_date, download_date, import_date, upload_id
)
AS
SELECT cast(PATID as int4) ,
        CASE when (px_type = '09') then concat('ICD9:' , PX)
             when (px_type = 'CH') then concat ('CPT:' , PX)
             when (px_type = '10') then concat ('ICD10:' , PX)
        END,
        cast(ENCOUNTERID as int4),
        1,
        PROVIDERID ,
        ADMIT_DATE ,
        '@',
        cast(null as varchar),
        cast(null as varchar),
        ENC_TYPE ,
        cast(null as decimal),
        cast(null as varchar),
        cast(null as decimal),
        cast(null as varchar),
        PX_DATE ,
        cast(null as varchar),
        cast(null as decimal),
        cast(null as varchar),
        cast(null as timestamp),
        cast(null as timestamp),
        cast(null as timestamp),
        cast(null as int)
FROM pcornetdemodata.pmnprocedure
GO
/*
CREATE VIEW pcornetdemodata.MULTIFACT_VITAL_VIEW
(patient_num, concept_cd, encounter_num, instance_num , provider_id, start_date, modifier_cd, observation_blob,
    valtype_cd, tval_char, nval_num, valueflag_cd, quantity_num, units_cd, end_date, location_cd,
    confidence_num, sourcesystem_cd, update_date, download_date, import_date, upload_id
)
AS
SELECT PATID ,
        cast(null as varchar), --fix later
        ENCOUNTERID ,
        1,
        '@',
        MEASURE_DATE ,
        '@',
        cast(null as varchar),
        cast(null as varchar),
        cast(null as varchar),
        cast(null as decimal),
        cast(null as varchar),
        cast(null as decimal),
        cast(null as varchar),
        MEASURE_TIME,
        cast(null as varchar),
        cast(null as decimal),
        cast(null as varchar),
        cast(null as timestamp),
        cast(null as timestamp),
        cast(null as timestamp),
        cast(null as int)
FROM pmnvital
GO*/

drop view pcornetdemodata.PATIENT_DIMENSION;
CREATE VIEW pcornetdemodata.PATIENT_DIMENSION
(patient_num, vital_status_cd, birth_date, death_date , sex_cd, age_in_years_num, language_cd, race_cd,
    marital_status_cd, religion_cd, zip_cd, statecityzip_path, income_cd, patient_blob, update_date, download_date,
    import_date, sourcesystem_cd, upload_id
)
AS
SELECT  cast(patid as int) ,
        biobank_flag , 
        birth_date ,
        cast(null as timestamp), --death_date
        sex, 
        cast(null as int) ,
        cast(null as varchar), --language_cd
        RACE, 
        cast(null as varchar) , --marital_status_cd
        cast(null as varchar) , --religion_cd
        cast(null as varchar),
        cast(null as varchar) , --statecityzip_path
        cast(null as varchar),
        cast(null as varchar) , --patient_blob
        cast(null as timestamp) , --update_date
        cast(null as timestamp) ,
        cast(null as timestamp), --import_date
        cast(null as varchar),
        cast(null as int)
FROM pcornetdemodata.pmndemographic
GO

drop view pcornetdemodata.VISIT_DIMENSION;
CREATE VIEW pcornetdemodata.VISIT_DIMENSION
(patient_num, encounter_num, active_status_cd, start_date, end_date, inout_cd,
    location_cd, location_path, length_of_stay, visit_blob, update_date, download_date, import_date,  
    sourcesystem_cd, upload_id, drg, discharge_status, discharge_disposition, location_zip,
    admitting_source, facilityid, providerid
)
AS
SELECT  cast(PATID as int)  ,
        cast(encounterid as int) , 
        cast(null as varchar), --active_status_cd
        admit_date,
        discharge_date ,
        enc_type , --inout_cd
        facility_location , 
        cast(null as varchar) , --location_path
        cast(null as int) ,
        cast(null as varchar) , --visit_blob
        cast(null as timestamp),
        cast(null as timestamp) ,
        cast(null as timestamp) ,
        cast(null as varchar) , --sourcesystem_cd
        cast(null as int) ,
        drg ,
        discharge_status,
        DISCHARGE_DISPOSITION ,
        facility_location , --location_zip
        providerid ,
        facilityid ,
        providerid
FROM pcornetdemodata.pmnencounter
GO

GRANT SELECT ON ALL TABLES IN SCHEMA pcornetdemodata TO i2b2demodata ;