----------------------------------------------------------------------------------------------------------------------------------------
-- i2b2-on-PCORnet ontology
-- Contributors: Jeff Klann, PhD; Matthew Joss
-- 
-- 1. Download and install the PCORnet ontology on your PCORnet CDM instance.
--     https://github.com/SCILHS/scilhs-ontology/blob/master/Documentation/INSTALL.md
-- 2. Run this script to update the ontology for i2b2-on-PCORnet.
-- 3. Separately, run the "create views" script.
----------------------------------------------------------------------------------------------------------------------------------------

-- NOT YET FINISHED!

update pcornet_proc set c_facttablecolumn='MULTIFACT_PROCEDURE_VIEW.'+c_facttablecolumn
GO
update pcornet_diag set c_facttablecolumn='MULTIFACT_DIAGNOSIS_VIEW.'+c_facttablecolumn
GO
update pcornet_med set c_facttablecolumn='MULTIFACT_PRESCRIBING_VIEW.'+c_facttablecolumn
GO
update pcornet_lab set c_facttablecolumn='MULTIFACT_LABRESULTS_VIEW.'+c_facttablecolumn
GO
update pcornet_vital set c_facttablecolumn='MULTIFACT_VITAL_VIEW.'+c_facttablecolumn
GO
-- ENROLL, ENC, DEMO