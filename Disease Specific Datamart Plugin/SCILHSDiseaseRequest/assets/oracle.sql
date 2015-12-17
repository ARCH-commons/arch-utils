        -- {$0} - Version 1.3
-----------------------------------------------------------------------------------------
-- This script contains both the DataMart and the Ontology.   Run each on the correct DB
-----------------------------------------------------------------------------------------



/*********************************************************/
--	
--				RUN ON DATAMART CRC DATABASE
--
/*********************************************************/




--============================================================================
-- Table: ARCHIVE_OBSERVATION_FACT (HOLDS DELETED ENTRIES OF OBSERVATION_FACT) 
--============================================================================
CREATE TABLE ARCHIVE_OBSERVATION_FACT NOLOGGING AS (
	SELECT * FROM OBSERVATION_FACT WHERE 1= 2)
;

ALTER TABLE ARCHIVE_OBSERVATION_FACT  ADD ( ARCHIVE_UPLOAD_ID NUMBER(22,0))
;

CREATE INDEX PK_ARCHIVE_OBSFACT ON ARCHIVE_OBSERVATION_FACT
 		(ENCOUNTER_NUM,PATIENT_NUM,CONCEPT_CD,PROVIDER_ID,START_DATE,MODIFIER_CD,ARCHIVE_UPLOAD_ID)
;


--==============================================================
-- Table: DATAMART_REPORT			                    	
--==============================================================
CREATE TABLE DATAMART_REPORT ( 
	TOTAL_PATIENT         NUMBER(38,0), 
	TOTAL_OBSERVATIONFACT NUMBER(38,0), 
	TOTAL_EVENT           NUMBER(38,0),
	REPORT_DATE           DATE
)
; 


--==============================================================
-- Table: UPLOAD_STATUS 					                    
--==============================================================
CREATE TABLE UPLOAD_STATUS (
	UPLOAD_ID 		    NUMBER(38,0), 	
    UPLOAD_LABEL 		VARCHAR2(500) NOT NULL, 
    USER_ID      		VARCHAR2(100) NOT NULL, 
    SOURCE_CD   		VARCHAR2(50) NOT NULL,
    NO_OF_RECORD 		NUMBER,
    LOADED_RECORD 		NUMBER,
    DELETED_RECORD		NUMBER, 
    LOAD_DATE    		DATE NOT NULL,
	END_DATE 	        DATE, 
    LOAD_STATUS  		VARCHAR2(100), 
    MESSAGE				CLOB,
    INPUT_FILE_NAME 	CLOB, 
    LOG_FILE_NAME 		CLOB, 
    TRANSFORM_NAME 		VARCHAR2(500),
    CONSTRAINT PK_UP_UPSTATUS_UPLOADID PRIMARY KEY (UPLOAD_ID)
)
;


--==============================================================
-- Table: SET_TYPE						                        
--==============================================================
CREATE TABLE SET_TYPE (
	ID 				INTEGER, 
    NAME			VARCHAR2(500),
    CREATE_DATE     DATE,
    CONSTRAINT PK_ST_ID PRIMARY KEY (ID)
)
;


--==============================================================
-- Table: SOURCE_MASTER					                        
--==============================================================
CREATE TABLE SOURCE_MASTER ( 
   SOURCE_CD 				VARCHAR(50) NOT NULL,
   DESCRIPTION  			VARCHAR(300),
   CREATE_DATE 				DATE,
   CONSTRAINT PK_SOURCEMASTER_SOURCECD PRIMARY KEY (SOURCE_CD)
)
;


-- ==============================================================
-- Table: SET_UPLOAD_STATUS				                        
--==============================================================
CREATE TABLE SET_UPLOAD_STATUS (
    UPLOAD_ID			NUMBER,
    SET_TYPE_ID         INTEGER,
    SOURCE_CD  		    VARCHAR(50) NOT NULL,
    NO_OF_RECORD 		NUMBER,
    LOADED_RECORD 		NUMBER,
    DELETED_RECORD		NUMBER, 
    LOAD_DATE    		DATE NOT NULL,
    END_DATE            DATE,
    LOAD_STATUS  		VARCHAR2(100), 
    MESSAGE			    CLOB,
    INPUT_FILE_NAME 	CLOB, 
    LOG_FILE_NAME 		CLOB, 
    TRANSFORM_NAME 		VARCHAR2(500),
    CONSTRAINT PK_UP_UPSTATUS_IDSETTYPEID PRIMARY KEY (UPLOAD_ID,SET_TYPE_ID),
    CONSTRAINT FK_UP_SET_TYPE_ID FOREIGN KEY (SET_TYPE_ID) REFERENCES SET_TYPE(ID)
)
;


--=============================================================
-- Sequences for generating primary keys.					
--==============================================================
CREATE SEQUENCE SQ_UPLOADSTATUS_UPLOADID
  INCREMENT BY 1
  START WITH 1
  MINVALUE 1
  MAXVALUE 9999999999999
  NOCYCLE
  NOCACHE
  ORDER
;

CREATE SEQUENCE SQ_UP_ENCDIM_ENCOUNTERNUM
  INCREMENT BY 1
  START WITH 1
  MINVALUE 1
  MAXVALUE 9999999999999
  NOCYCLE
  NOCACHE
  ORDER
;

CREATE SEQUENCE SQ_UP_PATDIM_PATIENTNUM
  INCREMENT BY 1
  START WITH 1
  MINVALUE 1
  MAXVALUE 9999999999999
  NOCYCLE
  NOCACHE
  ORDER
;


--==============================================================
--  Adding seed data for SOURCE_MASTER table.  					
--==============================================================
INSERT INTO SOURCE_MASTER(SOURCE_CD,DESCRIPTION,CREATE_DATE) values ('I2B2PulmX','i2b2 Pulminory Extract',sysdate);


--==============================================================
--  Adding seed data for SET_TYPE table.  					    
--==============================================================
INSERT INTO SET_TYPE(ID,NAME,CREATE_DATE) values (1,'event_set',sysdate)
;
INSERT INTO SET_TYPE(ID,NAME,CREATE_DATE) values (2,'patient_set',sysdate)
;
INSERT INTO SET_TYPE(ID,NAME,CREATE_DATE) values (3,'concept_set',sysdate)
;
INSERT INTO SET_TYPE(ID,NAME,CREATE_DATE) values (4,'observer_set',sysdate)
;
INSERT INTO SET_TYPE(ID,NAME,CREATE_DATE) values (5,'observation_set',sysdate)
;
INSERT INTO SET_TYPE(ID,NAME,CREATE_DATE) values (6,'pid_set',sysdate)
;
INSERT INTO SET_TYPE(ID,NAME,CREATE_DATE) values (7,'eid_set',sysdate)
;
INSERT INTO SET_TYPE(ID,NAME,CREATE_DATE) values (8,'modifier_set',sysdate)
;


CREATE TABLE ENCOUNTER_MAPPING ( 
    ENCOUNTER_IDE       	VARCHAR2(200) NOT NULL,
    ENCOUNTER_IDE_SOURCE	VARCHAR2(50) NOT NULL,
    PROJECT_ID              VARCHAR2(50) NOT NULL,
    ENCOUNTER_NUM       	NUMBER(38,0) NOT NULL,
    PATIENT_IDE         	VARCHAR2(200) NOT NULL,
    PATIENT_IDE_SOURCE  	VARCHAR2(50) NOT NULL,
    ENCOUNTER_IDE_STATUS	VARCHAR2(50),
    UPLOAD_DATE         	DATE,
    UPDATE_DATE             DATE,
    DOWNLOAD_DATE       	DATE,
	IMPORT_DATE			    DATE,
    SOURCESYSTEM_CD     	VARCHAR2(50),
	UPLOAD_ID           	NUMBER(38,0),
    CONSTRAINT ENCOUNTER_MAPPING_PK PRIMARY KEY(ENCOUNTER_IDE, ENCOUNTER_IDE_SOURCE, PROJECT_ID, PATIENT_IDE, PATIENT_IDE_SOURCE)
 )
/
CREATE INDEX EM_UPLOADID_IDX ON ENCOUNTER_MAPPING(UPLOAD_ID)

/
CREATE  INDEX EM_IDX_ENCPATH ON ENCOUNTER_MAPPING(ENCOUNTER_IDE,ENCOUNTER_IDE_SOURCE,PATIENT_IDE,PATIENT_IDE_SOURCE,ENCOUNTER_NUM )

/
CREATE INDEX EM_ENCNUM_IDX ON ENCOUNTER_MAPPING(ENCOUNTER_NUM)

/
-------------------------------------------------------------------------------------
-- create PATIENT_MAPPING table with clustered PK on PATIENT_IDE, PATIENT_IDE_SOURCE
-------------------------------------------------------------------------------------

CREATE TABLE PATIENT_MAPPING ( 
    PATIENT_IDE       	VARCHAR2(200) NOT NULL,
    PATIENT_IDE_SOURCE	VARCHAR2(50) NOT NULL,
    PATIENT_NUM       	NUMBER(38,0) NOT NULL,
    PATIENT_IDE_STATUS	VARCHAR2(50),
    PROJECT_ID          VARCHAR2(50) NOT NULL,
    UPLOAD_DATE       	DATE,
    UPDATE_DATE         DATE,
    DOWNLOAD_DATE     	DATE,
    IMPORT_DATE			DATE,
    SOURCESYSTEM_CD   	VARCHAR2(50),
    UPLOAD_ID         	NUMBER(38,0),
    CONSTRAINT PATIENT_MAPPING_PK PRIMARY KEY(PATIENT_IDE, PATIENT_IDE_SOURCE, PROJECT_ID)
 )

/
CREATE INDEX PM_UPLOADID_IDX ON PATIENT_MAPPING(UPLOAD_ID)

/
CREATE INDEX PM_PATNUM_IDX ON PATIENT_MAPPING(PATIENT_NUM)

/
CREATE INDEX PM_ENCPNUM_IDX ON 
PATIENT_MAPPING(PATIENT_IDE,PATIENT_IDE_SOURCE,PATIENT_NUM)

/


------------------------------------------------------------------------------
-- create CODE_LOOKUP table with clustered PK on TABLE_CD, COLUMN_CD, CODE_CD 
------------------------------------------------------------------------------

CREATE TABLE CODE_LOOKUP ( 
	TABLE_CD            VARCHAR2(100) NOT NULL,
	COLUMN_CD           VARCHAR2(100) NOT NULL,
	CODE_CD             VARCHAR2(50) NOT NULL,
	NAME_CHAR           VARCHAR2(650) NULL,
	LOOKUP_BLOB			CLOB,
    UPLOAD_DATE       	DATE NULL,
    UPDATE_DATE     	DATE NULL,
	DOWNLOAD_DATE   	DATE NULL,
	IMPORT_DATE     	DATE NULL,
	SOURCESYSTEM_CD 	VARCHAR2(50) NULL,
	UPLOAD_ID       	NUMBER(38,0) NULL,
    CONSTRAINT CODE_LOOKUP_PK PRIMARY KEY(TABLE_CD,COLUMN_CD,CODE_CD)
	)

/
-- add index on name_char field 
CREATE INDEX CL_IDX_NAME_CHAR ON CODE_LOOKUP(NAME_CHAR)

/
CREATE INDEX CL_IDX_UPLOADID ON CODE_LOOKUP(UPLOAD_ID)

/


--------------------------------------------------------------------
-- create CONCEPT_DIMENSION table with clustered PK on CONCEPT_PATH 
--------------------------------------------------------------------

CREATE TABLE CONCEPT_DIMENSION ( 
	CONCEPT_PATH    	VARCHAR2(700) NOT NULL,
	CONCEPT_CD          VARCHAR2(50) NOT NULL,
	NAME_CHAR       	VARCHAR2(2000) NULL,
	CONCEPT_BLOB        CLOB NULL,
	UPDATE_DATE         DATE NULL,
	DOWNLOAD_DATE       DATE NULL,
	IMPORT_DATE         DATE NULL,
	SOURCESYSTEM_CD     VARCHAR2(50) NULL,
	UPLOAD_ID       	NUMBER(38,0) NULL,
    CONSTRAINT CONCEPT_DIMENSION_PK PRIMARY KEY(CONCEPT_PATH)
	)
/
CREATE INDEX CD_UPLOADID_IDX ON CONCEPT_DIMENSION(UPLOAD_ID)

/


----------------------------------------------------------------------------------
--        create OBSERVATION_FACT table with NONclustered PK on
-- ENCOUNTER_NUM, CONCEPT_CD, PROVIDER_ID, START_DATE, MODIFIER_CD, INSTANCE_NUM 
----------------------------------------------------------------------------------

CREATE TABLE OBSERVATION_FACT (
	ENCOUNTER_NUM   	NUMBER(38,0) NOT NULL,
	PATIENT_NUM     	NUMBER(38,0) NOT NULL,
	CONCEPT_CD      	VARCHAR2(50) NOT NULL,
	PROVIDER_ID     	VARCHAR2(50) NOT NULL,
	START_DATE      	DATE NOT NULL,
	MODIFIER_CD     	VARCHAR2(100) default '@' NOT NULL,
	INSTANCE_NUM	    NUMBER(18,0) default '1' NOT NULL,
	VALTYPE_CD      	VARCHAR2(50) NULL,
	TVAL_CHAR       	VARCHAR2(255) NULL,
	NVAL_NUM        	NUMBER(18,5) NULL,
	VALUEFLAG_CD    	VARCHAR2(50) NULL,
	QUANTITY_NUM    	NUMBER(18,5) NULL,
	UNITS_CD        	VARCHAR2(50) NULL,
	END_DATE        	DATE NULL,
	LOCATION_CD     	VARCHAR2(50) NULL,
	OBSERVATION_BLOB	CLOB NULL,
	CONFIDENCE_NUM  	NUMBER(18,5) NULL,
	UPDATE_DATE     	DATE NULL,
	DOWNLOAD_DATE   	DATE NULL,
	IMPORT_DATE     	DATE NULL,
	SOURCESYSTEM_CD 	VARCHAR2(50) NULL,
	UPLOAD_ID       	NUMBER(38,0) NULL, 
    CONSTRAINT OBSERVATION_FACT_PK PRIMARY KEY(PATIENT_NUM, CONCEPT_CD,  MODIFIER_CD, START_DATE, ENCOUNTER_NUM, INSTANCE_NUM, PROVIDER_ID)
)

/
CREATE INDEX FACT_NOLOB ON OBSERVATION_FACT
(
	PATIENT_NUM,
	START_DATE, 
	CONCEPT_CD,
	ENCOUNTER_NUM,
	INSTANCE_NUM,
	NVAL_NUM, 
	TVAL_CHAR,
	VALTYPE_CD, 
	MODIFIER_CD,
	VALUEFLAG_CD, 
	PROVIDER_ID, 
	QUANTITY_NUM, 
	UNITS_CD, 
	END_DATE, 
	LOCATION_CD, 
	CONFIDENCE_NUM, 
	UPDATE_DATE, 
	DOWNLOAD_DATE, 
	IMPORT_DATE, 
	SOURCESYSTEM_CD, 
	UPLOAD_ID
)

/
CREATE INDEX FACT_CNPT_PAT_ENCT_IDX ON OBSERVATION_FACT
(CONCEPT_CD, INSTANCE_NUM, PATIENT_NUM, ENCOUNTER_NUM) 

/
CREATE INDEX FACT_PATCON_DATE_PRVD_IDX ON OBSERVATION_FACT
(PATIENT_NUM, CONCEPT_CD, START_DATE, END_DATE, ENCOUNTER_NUM, INSTANCE_NUM,
PROVIDER_ID, NVAL_NUM, VALTYPE_CD) 

/
CREATE INDEX FACT_CNPT_IDX ON OBSERVATION_FACT
(CONCEPT_CD) 

/



-------------------------------------------------------------------
-- create PATIENT_DIMENSION table with clustered PK on PATIENT_NUM 
-------------------------------------------------------------------

CREATE TABLE PATIENT_DIMENSION ( 
	PATIENT_NUM      	NUMBER(38,0) NOT NULL,
	VITAL_STATUS_CD  	VARCHAR2(50) NULL,
	BIRTH_DATE       	DATE NULL,
	DEATH_DATE       	DATE NULL,
	SEX_CD           	VARCHAR2(50) NULL,
	AGE_IN_YEARS_NUM 	NUMBER(38,0) NULL,
	LANGUAGE_CD      	VARCHAR2(50) NULL,
	RACE_CD          	VARCHAR2(50) NULL,
	MARITAL_STATUS_CD	VARCHAR2(50) NULL,
	RELIGION_CD      	VARCHAR2(50) NULL,
	ZIP_CD           	VARCHAR2(10) NULL,
	STATECITYZIP_PATH	VARCHAR2(700) NULL,
	INCOME_CD			VARCHAR2(50) NULL,
	PATIENT_BLOB     	CLOB NULL,
	UPDATE_DATE      	DATE NULL,
	DOWNLOAD_DATE    	DATE NULL,
	IMPORT_DATE      	DATE NULL,
	SOURCESYSTEM_CD  	VARCHAR2(50) NULL,
	UPLOAD_ID        	NUMBER(38,0) NULL,
    CONSTRAINT PATIENT_DIMENSION_PK PRIMARY KEY(PATIENT_NUM)
	)
/
-- add indexes on additional Patient_Dimension fields 
CREATE  INDEX PD_IDX_DATES ON PATIENT_DIMENSION(PATIENT_NUM, VITAL_STATUS_CD, BIRTH_DATE, DEATH_DATE)

/
CREATE  INDEX PD_IDX_AllPatientDim ON PATIENT_DIMENSION(PATIENT_NUM, VITAL_STATUS_CD, BIRTH_DATE, DEATH_DATE, SEX_CD, AGE_IN_YEARS_NUM, LANGUAGE_CD, RACE_CD, MARITAL_STATUS_CD, RELIGION_CD, ZIP_CD, INCOME_CD)

/
CREATE  INDEX PD_IDX_StateCityZip ON PATIENT_DIMENSION (STATECITYZIP_PATH, PATIENT_NUM)

/
CREATE INDEX PATD_UPLOADID_IDX ON PATIENT_DIMENSION(UPLOAD_ID)

/



-----------------------------------------------------------------------------------
-- create PROVIDER_DIMENSION table with clustered PK on PROVIDER_PATH, PROVIDER_ID 
-----------------------------------------------------------------------------------

CREATE TABLE PROVIDER_DIMENSION ( 
	PROVIDER_ID         VARCHAR2(50) NOT NULL,
	PROVIDER_PATH       VARCHAR2(700) NOT NULL,
	NAME_CHAR       	VARCHAR2(850) NULL,
	PROVIDER_BLOB       CLOB NULL,
	UPDATE_DATE     	DATE NULL,
	DOWNLOAD_DATE       DATE NULL,
	IMPORT_DATE         DATE NULL,
	SOURCESYSTEM_CD     VARCHAR2(50) NULL,
	UPLOAD_ID        	NUMBER(38,0) NULL,
    CONSTRAINT  PROVIDER_DIMENSION_PK PRIMARY KEY(PROVIDER_PATH,PROVIDER_ID)
	)

/
-- add index on provider_id, name_char 
CREATE INDEX PD_IDX_NAME_CHAR ON PROVIDER_DIMENSION(PROVIDER_ID,NAME_CHAR)

/
CREATE INDEX PROD_UPLOADID_IDX ON PROVIDER_DIMENSION(UPLOAD_ID)

/


-------------------------------------------------------------------
-- create VISIT_DIMENSION table with clustered PK on ENCOUNTER_NUM 
-------------------------------------------------------------------

CREATE TABLE VISIT_DIMENSION ( 
	ENCOUNTER_NUM       NUMBER(38,0) NOT NULL,
	PATIENT_NUM         NUMBER(38,0) NOT NULL,
    ACTIVE_STATUS_CD    VARCHAR2(50) NULL,
	START_DATE          DATE NULL,
	END_DATE            DATE NULL,
	INOUT_CD            VARCHAR2(50) NULL,
	LOCATION_CD         VARCHAR2(50) NULL,
	LOCATION_PATH  	    VARCHAR2(900) NULL,
	LENGTH_OF_STAY      NUMBER(38,0) NULL,
	VISIT_BLOB      	CLOB NULL,
	UPDATE_DATE         DATE NULL,
	DOWNLOAD_DATE       DATE NULL,
	IMPORT_DATE         DATE NULL,
	SOURCESYSTEM_CD     VARCHAR2(50) NULL,
	UPLOAD_ID       	NUMBER(38,0) NULL, 
    CONSTRAINT  VISIT_DIMENSION_PK PRIMARY KEY(ENCOUNTER_NUM,PATIENT_NUM)
	)

/
-- add indexes on addtional visit_dimension fields 
CREATE  INDEX VD_UPLOADID_IDX ON VISIT_DIMENSION(UPLOAD_ID)

/
CREATE INDEX VISITDIM_EN_PN_LP_IO_SD_IDX ON VISIT_DIMENSION
(ENCOUNTER_NUM, PATIENT_NUM, LOCATION_PATH, INOUT_CD, START_DATE,END_DATE, LENGTH_OF_STAY)

/
CREATE INDEX VISITDIM_STD_EDD_IDX ON VISIT_DIMENSION
(START_DATE, END_DATE)

/





------------------------------------------------------------
-- create MODIFIER_DIMENSION table with PK on MODIFIER_PATH 
------------------------------------------------------------

CREATE TABLE MODIFIER_DIMENSION ( 
	MODIFIER_PATH   	VARCHAR2(700) NOT NULL,
	MODIFIER_CD     	VARCHAR2(50) NULL,
	NAME_CHAR      		VARCHAR2(2000) NULL,
	MODIFIER_BLOB   	CLOB NULL,
	UPDATE_DATE    		DATE NULL,
	DOWNLOAD_DATE  		DATE NULL,
	IMPORT_DATE    		DATE NULL,
	SOURCESYSTEM_CD		VARCHAR2(50) NULL,
    UPLOAD_ID			NUMBER (38,0) NULL,
    CONSTRAINT MODIFIER_DIMENSION_PK PRIMARY KEY(modifier_path)
	)
/
CREATE INDEX MD_IDX_UPLOADID ON MODIFIER_DIMENSION(UPLOAD_ID)
/


CREATE INDEX OF_CTX_BLOB ON OBSERVATION_FACT(OBSERVATION_BLOB) INDEXTYPE IS CTXSYS.CONTEXT
 PARAMETERS ('SYNC (on commit)')
 /
 



--==============================================================
-- Database Script to create CRC query tables                   
--                                                            
-- This script will create tables, indexes and sequences. 	    
-- User should have permission to create VARRAY type            										                       
--==============================================================

--===========================================================================
-- Table: QT_QUERY_MASTER 											          
--============================================================================
CREATE TABLE QT_QUERY_MASTER (
	QUERY_MASTER_ID		NUMBER(5,0) PRIMARY KEY,
	NAME				VARCHAR2(250) NOT NULL,
	USER_ID				VARCHAR2(50) NOT NULL,
	GROUP_ID			VARCHAR2(50) NOT NULL,
	MASTER_TYPE_CD		VARCHAR2(2000),
	PLUGIN_ID			NUMBER(10,0),
	CREATE_DATE			DATE NOT NULL,
	DELETE_DATE			DATE,
	DELETE_FLAG			VARCHAR2(3),
	GENERATED_SQL		CLOB,
	REQUEST_XML			CLOB,
	I2B2_REQUEST_XML	CLOB,
	PM_XML				CLOB
)
/
CREATE INDEX QT_IDX_QM_UGID ON QT_QUERY_MASTER(USER_ID,GROUP_ID,MASTER_TYPE_CD)
/


--============================================================================
-- Table: QT_QUERY_RESULT_TYPE										          
--============================================================================
CREATE TABLE QT_QUERY_RESULT_TYPE (
	RESULT_TYPE_ID				NUMBER(3,0) PRIMARY KEY,
	NAME						VARCHAR2(100),
	DESCRIPTION					VARCHAR2(200),
	DISPLAY_TYPE_ID				VARCHAR2(500),
	VISUAL_ATTRIBUTE_TYPE_ID	VARCHAR2(3)	
)
/


--============================================================================
-- Table: QT_QUERY_STATUS_TYPE										          
--============================================================================
CREATE TABLE QT_QUERY_STATUS_TYPE (
	STATUS_TYPE_ID	NUMBER(3,0) PRIMARY KEY,
	NAME			VARCHAR2(100),
	DESCRIPTION		VARCHAR2(200)
)
/


--============================================================================
-- Table: QT_QUERY_INSTANCE 										          
--============================================================================
CREATE TABLE QT_QUERY_INSTANCE (
	QUERY_INSTANCE_ID	NUMBER(5,0) PRIMARY KEY,
	QUERY_MASTER_ID		NUMBER(5,0),
	USER_ID				VARCHAR2(50) NOT NULL,
	GROUP_ID			VARCHAR2(50) NOT NULL,
	BATCH_MODE			VARCHAR2(50),
	START_DATE			DATE NOT NULL,
	END_DATE			DATE,
	DELETE_FLAG			VARCHAR2(3),
	STATUS_TYPE_ID		NUMBER(5,0),
	MESSAGE				CLOB,
	CONSTRAINT QT_FK_QI_MID FOREIGN KEY (QUERY_MASTER_ID)
		REFERENCES QT_QUERY_MASTER (QUERY_MASTER_ID),
	CONSTRAINT QT_FK_QI_STID FOREIGN KEY (STATUS_TYPE_ID)
		REFERENCES QT_QUERY_STATUS_TYPE (STATUS_TYPE_ID)
)
/
CREATE INDEX QT_IDX_QI_UGID ON QT_QUERY_INSTANCE(USER_ID,GROUP_ID)
/
CREATE INDEX QT_IDX_QI_MSTARTID ON QT_QUERY_INSTANCE(QUERY_MASTER_ID,START_DATE)
/


--=============================================================================
-- Table: QT_QUERY_RESULT_INSTANCE   								        
--============================================================================
CREATE TABLE QT_QUERY_RESULT_INSTANCE (
	RESULT_INSTANCE_ID	NUMBER(5,0) PRIMARY KEY,
	QUERY_INSTANCE_ID	NUMBER(5,0),
	RESULT_TYPE_ID		NUMBER(3,0) NOT NULL,
	SET_SIZE			NUMBER(10,0),
	START_DATE			DATE NOT NULL,
	END_DATE			DATE,
	DELETE_FLAG			VARCHAR2(3),
	STATUS_TYPE_ID		NUMBER(3,0) NOT NULL,
	MESSAGE				CLOB,
	DESCRIPTION			VARCHAR2(200),
	REAL_SET_SIZE		NUMBER(10,0),
	OBFUSC_METHOD		VARCHAR2(500),
	CONSTRAINT QT_FK_QRI_RID FOREIGN KEY (QUERY_INSTANCE_ID)
		REFERENCES QT_QUERY_INSTANCE (QUERY_INSTANCE_ID),
	CONSTRAINT QT_FK_QRI_RTID FOREIGN KEY (RESULT_TYPE_ID)
		REFERENCES QT_QUERY_RESULT_TYPE (RESULT_TYPE_ID),
	CONSTRAINT QT_FK_QRI_STID FOREIGN KEY (STATUS_TYPE_ID)
		REFERENCES QT_QUERY_STATUS_TYPE (STATUS_TYPE_ID)
)
/


--============================================================================
-- Table: QT_PATIENT_SET_COLLECTION									         
--============================================================================
CREATE TABLE QT_PATIENT_SET_COLLECTION ( 
	PATIENT_SET_COLL_ID		NUMBER(10,0) PRIMARY KEY,
	RESULT_INSTANCE_ID		NUMBER(5,0),
	SET_INDEX				NUMBER(10,0),
	PATIENT_NUM				NUMBER(38,0),
	CONSTRAINT QT_FK_PSC_RI FOREIGN KEY (RESULT_INSTANCE_ID)
		REFERENCES QT_QUERY_RESULT_INSTANCE (RESULT_INSTANCE_ID)
)
/

CREATE INDEX QT_IDX_QPSC_RIID ON QT_PATIENT_SET_COLLECTION(RESULT_INSTANCE_ID)
/


--============================================================================
-- Table: QT_PATIENT_ENC_COLLECTION									         
--============================================================================
CREATE TABLE QT_PATIENT_ENC_COLLECTION (
	PATIENT_ENC_COLL_ID		NUMBER(10,0) PRIMARY KEY,
	RESULT_INSTANCE_ID		NUMBER(5,0),
	SET_INDEX				NUMBER(10,0),
	PATIENT_NUM				NUMBER(38,0),
	ENCOUNTER_NUM			NUMBER(38,0),
	CONSTRAINT QT_FK_PESC_RI FOREIGN KEY (RESULT_INSTANCE_ID)
		REFERENCES QT_QUERY_RESULT_INSTANCE(RESULT_INSTANCE_ID)
)
/


--============================================================================
-- Table: QT_XML_RESULT												          
--============================================================================
CREATE TABLE QT_XML_RESULT (
	XML_RESULT_ID		NUMBER(5,0) PRIMARY KEY,
	RESULT_INSTANCE_ID	NUMBER(5,0),
	XML_VALUE			CLOB,
	CONSTRAINT QT_FK_XMLR_RIID FOREIGN KEY (RESULT_INSTANCE_ID)
		REFERENCES QT_QUERY_RESULT_INSTANCE (RESULT_INSTANCE_ID)
)
/


--============================================================================
-- Table: QT_ANALYSIS_PLUGIN												          
--============================================================================
CREATE TABLE QT_ANALYSIS_PLUGIN (
	PLUGIN_ID			NUMBER(10,0) NOT NULL,
	PLUGIN_NAME			VARCHAR2(2000),
	DESCRIPTION			VARCHAR2(2000),
	VERSION_CD			VARCHAR2(50),			--support for version
	PARAMETER_INFO		CLOB,					-- plugin parameter stored as xml
	PARAMETER_INFO_XSD	CLOB,
	COMMAND_LINE		CLOB,
	WORKING_FOLDER		CLOB,
	COMMANDOPTION_CD	CLOB,
	PLUGIN_ICON			CLOB,
	STATUS_CD			VARCHAR2(50),			-- active,deleted,..
	USER_ID				VARCHAR2(50),
	GROUP_ID			VARCHAR2(50),
	CREATE_DATE			DATE,
	UPDATE_DATE			DATE,
	CONSTRAINT ANALYSIS_PLUGIN_PK PRIMARY KEY(PLUGIN_ID)
)
/
CREATE INDEX QT_APNAMEVERGRP_IDX ON QT_ANALYSIS_PLUGIN(PLUGIN_NAME,VERSION_CD,GROUP_ID)
/


--============================================================================
-- Table: QT_ANALYSIS_PLUGIN_RESULT_TYPE											          
--============================================================================
CREATE TABLE QT_ANALYSIS_PLUGIN_RESULT_TYPE (
	PLUGIN_ID		NUMBER(10,0),
	RESULT_TYPE_ID	NUMBER(10,0),
	CONSTRAINT ANALYSIS_PLUGIN_RESULT_PK PRIMARY KEY(PLUGIN_ID,RESULT_TYPE_ID)
)
/


--============================================================================
-- Table: QT_PDO_QUERY_MASTER											          
--============================================================================
CREATE TABLE QT_PDO_QUERY_MASTER (
	QUERY_MASTER_ID		NUMBER(5,0) PRIMARY KEY,
	USER_ID				VARCHAR2(50) NOT NULL,
	GROUP_ID			VARCHAR2(50) NOT NULL,
	CREATE_DATE			DATE NOT NULL,
	REQUEST_XML			CLOB,
	I2B2_REQUEST_XML	CLOB
)
/
CREATE INDEX QT_IDX_PQM_UGID ON QT_PDO_QUERY_MASTER(USER_ID,GROUP_ID)
/


--============================================================================
-- Table: QT_PRIVILEGE											          
--============================================================================
CREATE TABLE QT_PRIVILEGE (
	PROTECTION_LABEL_CD		VARCHAR2(1500),
	DATAPROT_CD				VARCHAR2(1000),
	HIVEMGMT_CD				VARCHAR2(1000),
	PLUGIN_ID				NUMBER(10,0)
)
/


--============================================================================
-- Table: QT_BREAKDOWN_PATH											          
--============================================================================
CREATE TABLE QT_BREAKDOWN_PATH ( 
	NAME			VARCHAR2(100),
	VALUE			VARCHAR2(2000),
	CREATE_DATE		DATE,
	UPDATE_DATE		DATE,
	USER_ID			VARCHAR2(50)
)
/


--============================================================================
-- CREATE GLOBALS
--============================================================================
create  GLOBAL TEMPORARY TABLE TEMP_PDO_INPUTLIST    ( 
char_param1 varchar2(100)
 ) ON COMMIT PRESERVE ROWS
/

-- DX
CREATE GLOBAL TEMPORARY TABLE DX  (
	ENCOUNTER_NUM	NUMBER(38,0),
	INSTANCE_NUM	NUMBER(38,0),
	PATIENT_NUM		NUMBER(38,0),
	CONCEPT_CD 		varchar2(50), 
	START_DATE 		DATE,
	PROVIDER_ID 	varchar2(50), 
	temporal_start_date date, 
	temporal_end_date DATE	
 ) on COMMIT PRESERVE ROWS
/

-- QUERY_GLOBAL_TEMP
CREATE GLOBAL TEMPORARY TABLE QUERY_GLOBAL_TEMP   ( 
	ENCOUNTER_NUM	NUMBER(38,0),
	PATIENT_NUM		NUMBER(38,0),
	INSTANCE_NUM	NUMBER(18,0) ,
	CONCEPT_CD      VARCHAR2(50),
	START_DATE	    DATE,
	PROVIDER_ID     VARCHAR2(50),
	PANEL_COUNT		NUMBER(5,0),
	FACT_COUNT		NUMBER(22,0),
	FACT_PANELS		NUMBER(5,0)
 ) on COMMIT PRESERVE ROWS
/

-- GLOBAL_TEMP_PARAM_TABLE
 CREATE GLOBAL TEMPORARY TABLE GLOBAL_TEMP_PARAM_TABLE   (
	SET_INDEX	INT,
	CHAR_PARAM1	VARCHAR2(500),
	CHAR_PARAM2	VARCHAR2(500),
	NUM_PARAM1	INT,
	NUM_PARAM2	INT
) ON COMMIT PRESERVE ROWS
/

-- GLOBAL_TEMP_FACT_PARAM_TABLE
CREATE GLOBAL TEMPORARY TABLE GLOBAL_TEMP_FACT_PARAM_TABLE   (
	SET_INDEX	INT,
	CHAR_PARAM1	VARCHAR2(500),
	CHAR_PARAM2	VARCHAR2(500),
	NUM_PARAM1	INT,
	NUM_PARAM2	INT
) ON COMMIT PRESERVE ROWS
/

-- MASTER_QUERY_GLOBAL_TEMP
CREATE GLOBAL TEMPORARY TABLE MASTER_QUERY_GLOBAL_TEMP    ( 
	ENCOUNTER_NUM	NUMBER(38,0),
	PATIENT_NUM		NUMBER(38,0),
	INSTANCE_NUM	NUMBER(18,0) ,
	CONCEPT_CD      VARCHAR2(50),
	START_DATE	    DATE,
	PROVIDER_ID     VARCHAR2(50),
	MASTER_ID		VARCHAR2(50),
	LEVEL_NO		NUMBER(5,0),
	TEMPORAL_START_DATE DATE,
	TEMPORAL_END_DATE DATE
 ) ON COMMIT PRESERVE ROWS
/


--------------------------------------------------------
--SEQUENCE CREATION
--------------------------------------------------------

--QUERY MASTER SEQUENCE
CREATE SEQUENCE QT_SQ_QM_QMID START WITH 1
/

--QUERY RESULT 
CREATE SEQUENCE QT_SQ_QR_QRID START WITH 1
/

CREATE SEQUENCE QT_SQ_QS_QSID START WITH 1
/

--QUERY INSTANCE SEQUENCE
CREATE SEQUENCE QT_SQ_QI_QIID START WITH 1
/

--QUERY RESULT INSTANCE ID
CREATE SEQUENCE QT_SQ_QRI_QRIID START WITH 1
/

--QUERY PATIENT SET RESULT COLLECTION ID
CREATE SEQUENCE QT_SQ_QPR_PCID START WITH 1
/

--QUERY PATIENT ENCOUNTER SET RESULT COLLECTION ID
CREATE SEQUENCE QT_SQ_QPER_PECID START WITH 1
/

--QUERY XML RESULT INSTANCE ID
CREATE SEQUENCE QT_SQ_QXR_XRID START WITH 1
/

--QUERY PDO MASTER SEQUENCE
CREATE SEQUENCE QT_SQ_PQM_QMID START WITH 1
/



--------------------------------------------------------
--INIT WITH SEED DATA
--------------------------------------------------------
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(1,'QUEUED',' WAITING IN QUEUE TO START PROCESS')
/
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(2,'PROCESSING','PROCESSING')
/
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(3,'FINISHED','FINISHED')
/
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(4,'ERROR','ERROR')
/
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(5,'INCOMPLETE','INCOMPLETE')
/
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(6,'COMPLETED','COMPLETED')
/
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(7,'MEDIUM_QUEUE','MEDIUM QUEUE')
/
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(8,'LARGE_QUEUE','LARGE QUEUE')
/
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(9,'CANCELLED','CANCELLED')
/
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(10,'TIMEDOUT','TIMEDOUT')
/


insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(1,'PATIENTSET','Patient set','LIST','LA')
/
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(2,'PATIENT_ENCOUNTER_SET','Encounter set','LIST','LA')
/
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(3,'XML','Generic query result','CATNUM','LH')
/
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(4,'PATIENT_COUNT_XML','Number of patients','CATNUM','LA')
/
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(5,'PATIENT_GENDER_COUNT_XML','Gender patient breakdown','CATNUM','LA')
/
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(6,'PATIENT_VITALSTATUS_COUNT_XML','Vital Status patient breakdown','CATNUM','LA')
/
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(7,'PATIENT_RACE_COUNT_XML','Race patient breakdown','CATNUM','LA')
/
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(8,'PATIENT_AGE_COUNT_XML','Age patient breakdown','CATNUM','LA')
/
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(9,'PATIENTSET','Timeline','LIST','LA')
/


insert into QT_PRIVILEGE(PROTECTION_LABEL_CD, DATAPROT_CD, HIVEMGMT_CD) values ('PDO_WITHOUT_BLOB','DATA_LDS','USER')
/
insert into QT_PRIVILEGE(PROTECTION_LABEL_CD, DATAPROT_CD, HIVEMGMT_CD) values ('PDO_WITH_BLOB','DATA_DEID','USER')
/
insert into QT_PRIVILEGE(PROTECTION_LABEL_CD, DATAPROT_CD, HIVEMGMT_CD) values ('SETFINDER_QRY_WITH_DATAOBFSC','DATA_OBFSC','USER')
/
insert into QT_PRIVILEGE(PROTECTION_LABEL_CD, DATAPROT_CD, HIVEMGMT_CD) values ('SETFINDER_QRY_WITHOUT_DATAOBFSC','DATA_AGG','USER')
/
insert into QT_PRIVILEGE(PROTECTION_LABEL_CD, DATAPROT_CD, HIVEMGMT_CD) values ('UPLOAD','DATA_OBFSC','MANAGER')
/
insert into QT_PRIVILEGE(PROTECTION_LABEL_CD, DATAPROT_CD, HIVEMGMT_CD) values ('SETFINDER_QRY_WITHOUT_LGTEXT','DATA_LDS','USER')
/
insert into QT_PRIVILEGE(PROTECTION_LABEL_CD, DATAPROT_CD, HIVEMGMT_CD) values ('SETFINDER_QRY_WITH_LGTEXT','DATA_DEID','USER')
/



--------------------------------------------------------
-- ARRAY TYPE FOR PDO QUERY
--------------------------------------------------------
CREATE OR REPLACE TYPE QT_PDO_QRY_INT_ARRAY AS varray(100000) of  NUMBER(20)
/

CREATE OR REPLACE TYPE QT_PDO_QRY_STRING_ARRAY AS varray(100000) of  VARCHAR2(150)
/




	/*****************************************************************
	* Create the set of patients to use based on the include and exclude
        * patient lists in QT_Patient_set_collection
	******************************************************************/

	CREATE TABLE patientset (
		patient_num NUMBER(38,0)
	)
    /


insert into patientset (patient_num) 
			select patient_num
			from  _CRCDB_.QT_PATIENT_SET_COLLECTION 
			 where result_instance_id = '{$1}' 
             and patient_num not in (select patient_num 
             from _CRCDB_.QT_PATIENT_SET_COLLECTION 
             where result_instance_id = '{$2}'
/


	/* patient_dimension */

insert into Patient_Dimension select * from _CRCDB_.patient_dimension where patient_num in (select patient_num from patientset)
/



	
	/* provider_dimension */

insert into provider_Dimension select * from  _CRCDB_.provider_dimension
/

	/* observation_fact */

insert into Observation_Fact (Encounter_Num,Patient_Num,Concept_Cd,Provider_Id,Start_Date,
                Modifier_Cd,instance_num,ValType_Cd ,TVal_Char,NVal_Num,ValueFlag_Cd,
                Quantity_Num,Units_Cd,End_Date,Location_Cd,Confidence_Num ,Observation_Blob,
                Update_Date,Download_Date,Import_Date,Sourcesystem_Cd ,UPLOAD_ID) 
                select  Encounter_Num,Patient_Num,Concept_Cd,Provider_Id,Start_Date,
                Modifier_Cd,instance_num,ValType_Cd ,TVal_Char,NVal_Num,ValueFlag_Cd,
                Quantity_Num,Units_Cd,End_Date,Location_Cd,Confidence_Num ,Observation_Blob,
                Update_Date,Download_Date,Import_Date,Sourcesystem_Cd ,UPLOAD_ID from _CRCDB_.observation_fact where 
patient_num in (select patient_num from patientset)
/


	/* visit_dimension */

insert into Visit_Dimension select * from _CRCDB_.visit_dimension where patient_num in (select patient_num from patientset) 
        and encounter_num in (select distinct(encounter_num) from observation_fact) 
/

	/* concept_dimension */

insert into Concept_Dimension select * from _CRCDB_.concept_dimension
/

        /* modifier_dimension */

insert into modifier_Dimension select * from _CRCDB_.modifier_dimension
/


	/*********************************************************
	*  Populate the mapping tables with self-mapping data.
	**********************************************************/

    insert into encounter_mapping (ENCOUNTER_IDE, ENCOUNTER_IDE_SOURCE, ENCOUNTER_NUM, ENCOUNTER_IDE_STATUS, PATIENT_IDE,  PATIENT_IDE_SOURCE, PROJECT_ID)
	(select  encounter_num, 'HIVE',encounter_num, 'A', '@',  'HIVE', '@' from visit_dimension 
	where encounter_num not in 
	(select DISTINCT  encounter_num from encounter_mapping where ENCOUNTER_IDE_SOURCE = 'HIVE'))
/

insert into encounter_mapping select * from _CRCDB_.encounter_mapping where encounter_num in (select distinct encounter_num from visit_dimension)
/
    

insert into Patient_mapping select * from _CRCDB_.patient_mapping where patient_num in (select distinct patient_num from patientset)
/




CREATE PROCEDURE CREATE_TEMP_CONCEPT_TABLE(tempConceptTableName IN VARCHAR, 
  errorMsg OUT VARCHAR) 
IS 

BEGIN 
execute immediate 'create table ' ||  tempConceptTableName || ' (
        CONCEPT_CD VARCHAR2(50) NOT NULL, 
	CONCEPT_PATH VARCHAR2(900) NOT NULL , 
	NAME_CHAR VARCHAR2(2000), 
	CONCEPT_BLOB CLOB, 
	UPDATE_DATE date, 
	DOWNLOAD_DATE DATE, 
	IMPORT_DATE DATE, 
	SOURCESYSTEM_CD VARCHAR2(50)
	 )';

 execute immediate 'CREATE INDEX idx_' || tempConceptTableName || '_pat_id ON ' || tempConceptTableName || '  (CONCEPT_PATH)';
  
   

EXCEPTION
	WHEN OTHERS THEN
		dbms_output.put_line(SQLCODE|| ' - ' ||SQLERRM);
END;

GO
CREATE PROCEDURE CREATE_TEMP_EID_TABLE(tempPatientMappingTableName IN VARCHAR ,errorMsg OUT VARCHAR) 
IS 

BEGIN 
execute immediate 'create table ' ||  tempPatientMappingTableName || ' (
	ENCOUNTER_MAP_ID       	VARCHAR2(200) NOT NULL,
    ENCOUNTER_MAP_ID_SOURCE	VARCHAR2(50) NOT NULL,
    PATIENT_MAP_ID          VARCHAR2(200), 
	PATIENT_MAP_ID_SOURCE   VARCHAR2(50), 
    ENCOUNTER_ID       	    VARCHAR2(200) NOT NULL,
    ENCOUNTER_ID_SOURCE     VARCHAR2(50) ,
    ENCOUNTER_NUM           NUMBER, 
    ENCOUNTER_MAP_ID_STATUS    VARCHAR2(50),
    PROCESS_STATUS_FLAG     CHAR(1),
	UPDATE_DATE DATE, 
	DOWNLOAD_DATE DATE, 
	IMPORT_DATE DATE, 
	SOURCESYSTEM_CD VARCHAR2(50)
)';

execute immediate 'CREATE INDEX idx_' || tempPatientMappingTableName || '_eid_id ON ' || tempPatientMappingTableName || '  (ENCOUNTER_ID, ENCOUNTER_ID_SOURCE, ENCOUNTER_MAP_ID, ENCOUNTER_MAP_ID_SOURCE, ENCOUNTER_NUM)';

 execute immediate 'CREATE INDEX idx_' || tempPatientMappingTableName || '_stateid_eid_id ON ' || tempPatientMappingTableName || '  (PROCESS_STATUS_FLAG)';  
EXCEPTION
	WHEN OTHERS THEN
		dbms_output.put_line(SQLCODE|| ' - ' ||SQLERRM);
END;

GO
CREATE PROCEDURE CREATE_TEMP_MODIFIER_TABLE(tempModifierTableName IN VARCHAR, 
  errorMsg OUT VARCHAR) 
IS 

BEGIN 
execute immediate 'create table ' ||  tempModifierTableName || ' (
        MODIFIER_CD VARCHAR2(50) NOT NULL, 
	MODIFIER_PATH VARCHAR2(900) NOT NULL , 
	NAME_CHAR VARCHAR2(2000), 
	MODIFIER_BLOB CLOB, 
	UPDATE_DATE date, 
	DOWNLOAD_DATE DATE, 
	IMPORT_DATE DATE, 
	SOURCESYSTEM_CD VARCHAR2(50)
	 )';

 execute immediate 'CREATE INDEX idx_' || tempModifierTableName || '_pat_id ON ' || tempModifierTableName || '  (MODIFIER_PATH)';
  
   

EXCEPTION
	WHEN OTHERS THEN
		dbms_output.put_line(SQLCODE|| ' - ' ||SQLERRM);
END;

GO
CREATE PROCEDURE CREATE_TEMP_PATIENT_TABLE(tempPatientDimensionTableName IN VARCHAR, 
    errorMsg OUT VARCHAR ) 
IS 

BEGIN 
	-- Create temp table to store encounter/visit information
	execute immediate 'create table ' ||  tempPatientDimensionTableName || ' (
		PATIENT_ID VARCHAR2(200), 
		PATIENT_ID_SOURCE VARCHAR2(50),
		PATIENT_NUM NUMBER(38,0),
	    VITAL_STATUS_CD VARCHAR2(50), 
	    BIRTH_DATE DATE, 
	    DEATH_DATE DATE, 
	    SEX_CD CHAR(50), 
	    AGE_IN_YEARS_NUM NUMBER(5,0), 
	    LANGUAGE_CD VARCHAR2(50), 
		RACE_CD VARCHAR2(50 ), 
		MARITAL_STATUS_CD VARCHAR2(50), 
		RELIGION_CD VARCHAR2(50), 
		ZIP_CD VARCHAR2(50), 
		STATECITYZIP_PATH VARCHAR2(700), 
		PATIENT_BLOB CLOB, 
		UPDATE_DATE DATE, 
		DOWNLOAD_DATE DATE, 
		IMPORT_DATE DATE, 
		SOURCESYSTEM_CD VARCHAR2(50)
	)';

execute immediate 'CREATE INDEX idx_' || tempPatientDimensionTableName || '_pat_id ON ' || tempPatientDimensionTableName || '  (PATIENT_ID, PATIENT_ID_SOURCE,PATIENT_NUM)';
  
     
    
EXCEPTION
	WHEN OTHERS THEN
		dbms_output.put_line(SQLCODE|| ' - ' ||SQLERRM);
END;

GO
CREATE PROCEDURE CREATE_TEMP_PID_TABLE(tempPatientMappingTableName IN VARCHAR,
    errorMsg OUT VARCHAR ) 
IS 

BEGIN 
execute immediate 'create table ' ||  tempPatientMappingTableName || ' (
	   	PATIENT_MAP_ID VARCHAR2(200), 
		PATIENT_MAP_ID_SOURCE VARCHAR2(50), 
		PATIENT_ID_STATUS VARCHAR2(50), 
		PATIENT_ID  VARCHAR2(200),
	    PATIENT_ID_SOURCE varchar(50),
		PATIENT_NUM NUMBER(38,0),
	    PATIENT_MAP_ID_STATUS VARCHAR2(50), 
		PROCESS_STATUS_FLAG CHAR(1), 
		UPDATE_DATE DATE, 
		DOWNLOAD_DATE DATE, 
		IMPORT_DATE DATE, 
		SOURCESYSTEM_CD VARCHAR2(50)

	 )';

execute immediate 'CREATE INDEX idx_' || tempPatientMappingTableName || '_pid_id ON ' || tempPatientMappingTableName || '  ( PATIENT_ID, PATIENT_ID_SOURCE )';

execute immediate 'CREATE INDEX idx_' || tempPatientMappingTableName || 'map_pid_id ON ' || tempPatientMappingTableName || '  
( PATIENT_ID, PATIENT_ID_SOURCE,PATIENT_MAP_ID, PATIENT_MAP_ID_SOURCE,  PATIENT_NUM )';
 
execute immediate 'CREATE INDEX idx_' || tempPatientMappingTableName || 'stat_pid_id ON ' || tempPatientMappingTableName || '  
(PROCESS_STATUS_FLAG)';


EXCEPTION
	WHEN OTHERS THEN
		dbms_output.put_line(SQLCODE|| ' - ' ||SQLERRM);
END;

GO
CREATE PROCEDURE CREATE_TEMP_PROVIDER_TABLE(tempProviderTableName IN VARCHAR, 
   errorMsg OUT VARCHAR) 
IS 

BEGIN 

execute immediate 'create table ' ||  tempProviderTableName || ' (
    PROVIDER_ID VARCHAR2(50) NOT NULL, 
	PROVIDER_PATH VARCHAR2(700) NOT NULL, 
	NAME_CHAR VARCHAR2(2000), 
	PROVIDER_BLOB CLOB, 
	UPDATE_DATE DATE, 
	DOWNLOAD_DATE DATE, 
	IMPORT_DATE DATE, 
	SOURCESYSTEM_CD VARCHAR2(50), 
	UPLOAD_ID NUMBER(*,0)
	 )';
 execute immediate 'CREATE INDEX idx_' || tempProviderTableName || '_ppath_id ON ' || tempProviderTableName || '  (PROVIDER_PATH)';


 
   

EXCEPTION
	WHEN OTHERS THEN
		dbms_output.put_line(SQLCODE|| ' - ' ||SQLERRM);
END;

GO
CREATE PROCEDURE CREATE_TEMP_TABLE(tempTableName IN VARCHAR, errorMsg OUT VARCHAR) 
IS 

BEGIN 
	execute immediate 'create table ' ||  tempTableName || '  (
		encounter_num  NUMBER(38,0),
		encounter_id varchar(200) not null, 
        encounter_id_source varchar(50) not null,
		concept_cd 	 VARCHAR(50) not null, 
                patient_num number(38,0), 
		patient_id  varchar(200) not null,
        patient_id_source  varchar(50) not null,
		provider_id   VARCHAR(50),
 		start_date   DATE, 
		modifier_cd VARCHAR2(100),
	    instance_num number(18,0),
 		valtype_cd varchar2(50),
		tval_char varchar(255),
 		nval_num NUMBER(18,5),
		valueflag_cd CHAR(50),
 		quantity_num NUMBER(18,5),
		confidence_num NUMBER(18,0),
 		observation_blob CLOB,
		units_cd VARCHAR2(50),
 		end_date    DATE,
		location_cd VARCHAR2(50),
 		update_date  DATE,
		download_date DATE,
 		import_date DATE,
		sourcesystem_cd VARCHAR2(50) ,
 		upload_id INTEGER
	) NOLOGGING';

    
    execute immediate 'CREATE INDEX idx_' || tempTableName || '_pk ON ' || tempTableName || '  ( encounter_num,patient_num,concept_cd,provider_id,start_date,modifier_cd,instance_num)';
    execute immediate 'CREATE INDEX idx_' || tempTableName || '_enc_pat_id ON ' || tempTableName || '  (encounter_id,encounter_id_source, patient_id,patient_id_source )';
    
EXCEPTION
	WHEN OTHERS THEN
		dbms_output.put_line(SQLCODE|| ' - ' ||SQLERRM);
END;

GO
CREATE PROCEDURE CREATE_TEMP_VISIT_TABLE(tempTableName IN VARCHAR, errorMsg OUT VARCHAR ) 
IS 

BEGIN 
	-- Create temp table to store encounter/visit information
	execute immediate 'create table ' ||  tempTableName || ' (
		encounter_id 			VARCHAR(200) not null,
		encounter_id_source 	VARCHAR(50) not null, 
		patient_id  			VARCHAR(200) not null,
		patient_id_source 		VARCHAR2(50) not null,
		encounter_num	 		    NUMBER(38,0), 
		inout_cd   			VARCHAR(50),
		location_cd 			VARCHAR2(50),
		location_path 			VARCHAR2(900),
 		start_date   			DATE, 
 		end_date    			DATE,
 		visit_blob 				CLOB,
 		update_date  			DATE,
		download_date 			DATE,
 		import_date 			DATE,
		sourcesystem_cd 		VARCHAR2(50)
	)';

    execute immediate 'CREATE INDEX idx_' || tempTableName || '_enc_id ON ' || tempTableName || '  ( encounter_id,encounter_id_source,patient_id,patient_id_source )';
    execute immediate 'CREATE INDEX idx_' || tempTableName || '_patient_id ON ' || tempTableName || '  ( patient_id,patient_id_source )';
    
EXCEPTION
	WHEN OTHERS THEN
		dbms_output.put_line(SQLCODE|| ' - ' ||SQLERRM);
END;

GO
CREATE PROCEDURE INSERT_CONCEPT_FROMTEMP (tempConceptTableName IN VARCHAR, upload_id IN NUMBER, errorMsg OUT VARCHAR ) 
IS 

BEGIN 
	--Delete duplicate rows with same encounter and patient combination
	execute immediate 'DELETE FROM ' || tempConceptTableName || ' t1 WHERE rowid > 
					   (SELECT  min(rowid) FROM ' || tempConceptTableName || ' t2
					     WHERE t1.concept_cd = t2.concept_cd 
                                            AND t1.concept_path = t2.concept_path
                                            )';
	
	   execute immediate ' UPDATE concept_dimension  set  (concept_cd,
                        name_char,concept_blob,
                        update_date,download_date,
                        import_date,sourcesystem_cd,
			     	UPLOAD_ID) = (select temp.concept_cd, temp.name_char,temp.concept_blob,temp.update_date,temp.DOWNLOAD_DATE,sysdate,temp.SOURCESYSTEM_CD,
			     	' || UPLOAD_ID  || ' from ' || tempConceptTableName || '  temp   where 
					temp.concept_path = concept_dimension.concept_path and temp.update_date >= concept_dimension.update_date) 
					where exists (select 1 from ' || tempConceptTableName || ' temp  where temp.concept_path = concept_dimension.concept_path 
					and temp.update_date >= concept_dimension.update_date) ';



   
    --Create new patient(patient_mapping) if temp table patient_ide does not exists 
	-- in patient_mapping table.
	execute immediate 'insert into concept_dimension  (concept_cd,concept_path,name_char,concept_blob,update_date,download_date,import_date,sourcesystem_cd,upload_id)
			    select  concept_cd, concept_path,
                        name_char,concept_blob,
                        update_date,download_date,
                        sysdate,sourcesystem_cd,
                         ' || upload_id || '  from ' || tempConceptTableName || '  temp
					where not exists (select concept_cd from concept_dimension cd where cd.concept_path = temp.concept_path)
					 
	';
	
	
    
    
EXCEPTION
	WHEN OTHERS THEN
		raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);	
END;

 
GO
CREATE PROCEDURE INSERT_EID_MAP_FROMTEMP (tempEidTableName IN VARCHAR,  upload_id IN NUMBER,
   errorMsg OUT VARCHAR ) 
is
 existingEncounterNum varchar2(32);
 maxEncounterNum number;

 TYPE distinctEIdCurTyp IS REF CURSOR;
distinctEidCur   distinctEIdCurTyp;
 sql_stmt  varchar2(400);
 
disEncounterId varchar2(100); 
disEncounterIdSource varchar2(100);

BEGIN
 sql_stmt := ' SELECT distinct encounter_id,encounter_id_source from ' || tempEidTableName ||' ';
 
  execute immediate ' delete  from ' || tempEidTableName ||  ' t1  where 
rowid > (select min(rowid) from ' || tempEidTableName || ' t2 
where t1.encounter_map_id = t2.encounter_map_id
and t1.encounter_map_id_source = t2.encounter_map_id_source
and t1.encounter_id = t2.encounter_id
and t1.encounter_id_source = t2.encounter_id_source) ';

 LOCK TABLE  encounter_mapping IN EXCLUSIVE MODE NOWAIT;
 select max(encounter_num) into maxEncounterNum from encounter_mapping ; 
 
if maxEncounterNum is null then 
  maxEncounterNum := 0;
end if;

  open distinctEidCur for sql_stmt ;
 
   loop
     FETCH distinctEidCur INTO disEncounterId, disEncounterIdSource;
      EXIT WHEN distinctEidCur%NOTFOUND;
       -- dbms_output.put_line(disEncounterId);
        
  if  disEncounterIdSource = 'HIVE'  THEN 
   begin
    --check if hive number exist, if so assign that number to reset of map_id's within that pid
    select encounter_num into existingEncounterNum from encounter_mapping where encounter_num = disEncounterId and encounter_ide_source = 'HIVE';
    EXCEPTION  
       when NO_DATA_FOUND THEN
           existingEncounterNum := null;
    end;
   if existingEncounterNum is not null then 
        execute immediate ' update ' || tempEidTableName ||' set encounter_num = encounter_id, process_status_flag = ''P''
        where encounter_id = :x and not exists (select 1 from encounter_mapping em where em.encounter_ide = encounter_map_id
        and em.encounter_ide_source = encounter_map_id_source)' using disEncounterId;
	
   else 
        -- generate new patient_num i.e. take max(_num) + 1 
        if maxEncounterNum < disEncounterId then 
            maxEncounterNum := disEncounterId;
        end if ;
        execute immediate ' update ' || tempEidTableName ||' set encounter_num = encounter_id, process_status_flag = ''P'' where 
        encounter_id =  :x and encounter_id_source = ''HIVE'' and not exists (select 1 from encounter_mapping em where em.encounter_ide = encounter_map_id
        and em.encounter_ide_source = encounter_map_id_source)' using disEncounterId;
      
   end if;    
   
   -- test if record fectched
   -- dbms_output.put_line(' HIVE ');

 else 
    begin
       select encounter_num into existingEncounterNum from encounter_mapping where encounter_ide = disEncounterId and 
        encounter_ide_source = disEncounterIdSource ; 

       -- test if record fetched. 
       EXCEPTION
           WHEN NO_DATA_FOUND THEN
           existingEncounterNum := null;
       end;
       if existingEncounterNum is not  null then 
            execute immediate ' update ' || tempEidTableName ||' set encounter_num = :x , process_status_flag = ''P''
            where encounter_id = :y and not exists (select 1 from encounter_mapping em where em.encounter_ide = encounter_map_id
        and em.encounter_ide_source = encounter_map_id_source)' using existingEncounterNum, disEncounterId;
       else 

            maxEncounterNum := maxEncounterNum + 1 ;
			--TODO : add update colunn
             execute immediate ' insert into ' || tempEidTableName ||' (encounter_map_id,encounter_map_id_source,encounter_id,encounter_id_source,encounter_num,process_status_flag
             ,encounter_map_id_status,update_date,download_date,import_date,sourcesystem_cd) 
             values(:x,''HIVE'',:y,''HIVE'',:z,''P'',''A'',sysdate,sysdate,sysdate,''edu.harvard.i2b2.crc'')' using maxEncounterNum,maxEncounterNum,maxEncounterNum; 
            execute immediate ' update ' || tempEidTableName ||' set encounter_num =  :x , process_status_flag = ''P'' 
            where encounter_id = :y and  not exists (select 1 from 
            encounter_mapping em where em.encounter_ide = encounter_map_id
            and em.encounter_ide_source = encounter_map_id_source)' using maxEncounterNum, disEncounterId;
            
       end if ;
    
      -- dbms_output.put_line(' NOT HIVE ');
 end if; 

END LOOP;
close distinctEidCur ;
commit;
 -- do the mapping update if the update date is old
   execute immediate ' merge into encounter_mapping
      using ' || tempEidTableName ||' temp
      on (temp.encounter_map_id = encounter_mapping.ENCOUNTER_IDE 
  		  and temp.encounter_map_id_source = encounter_mapping.ENCOUNTER_IDE_SOURCE
	   ) when matched then 
  		update set ENCOUNTER_NUM = temp.encounter_id,
    	patient_ide   =   temp.patient_map_id ,
    	patient_ide_source  =	temp.patient_map_id_source ,
    	encounter_ide_status	= temp.encounter_map_id_status  ,
    	update_date = temp.update_date,
    	download_date  = temp.download_date ,
		import_date = sysdate ,
    	sourcesystem_cd  = temp.sourcesystem_cd ,
		upload_id = ' || upload_id ||'  
    	where  temp.encounter_id_source = ''HIVE'' and temp.process_status_flag is null  and
        nvl(encounter_mapping.update_date,to_date(''01-JAN-1900'',''DD-MON-YYYY''))<= nvl(temp.update_date,to_date(''01-JAN-1900'',''DD-MON-YYYY'')) ' ;

-- insert new mapping records i.e flagged P
execute immediate ' insert into encounter_mapping (encounter_ide,encounter_ide_source,encounter_ide_status,encounter_num,patient_ide,patient_ide_source,update_date,download_date,import_date,sourcesystem_cd,upload_id) 
    select encounter_map_id,encounter_map_id_source,encounter_map_id_status,encounter_num,patient_map_id,patient_map_id_source,update_date,download_date,sysdate,sourcesystem_cd,' || upload_id || ' from ' || tempEidTableName || '  
    where process_status_flag = ''P'' ' ; 
commit;
EXCEPTION
   WHEN OTHERS THEN
      if distinctEidCur%isopen then
          close distinctEidCur;
      end if;
      rollback;
      raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
end;
GO
CREATE PROCEDURE INSERT_ENCOUNTERVISIT_FROMTEMP (tempTableName IN VARCHAR, upload_id IN NUMBER,
  errorMsg OUT VARCHAR) 
IS 
maxEncounterNum number; 
BEGIN 

     --Delete duplicate rows with same encounter and patient combination
	execute immediate 'DELETE FROM ' || tempTableName || ' t1 WHERE rowid > 
					   (SELECT  min(rowid) FROM ' || tempTableName || ' t2
					     WHERE t1.encounter_id = t2.encounter_id 
                                            AND t1.encounter_id_source = t2.encounter_id_source
                                            AND nvl(t1.patient_id,'''') = nvl(t2.patient_id,'''')
                                            AND nvl(t1.patient_id_source,'''') = nvl(t2.patient_id_source,''''))';

	 LOCK TABLE  encounter_mapping IN EXCLUSIVE MODE NOWAIT;
    -- select max(encounter_num) into maxEncounterNum from encounter_mapping ;

	 --Create new patient(patient_mapping) if temp table patient_ide does not exists 
	-- in patient_mapping table.
     execute immediate ' insert into encounter_mapping (encounter_ide,encounter_ide_source,encounter_num,patient_ide,patient_ide_source,encounter_ide_status, upload_id)
     	(select distinctTemp.encounter_id, distinctTemp.encounter_id_source, distinctTemp.encounter_id,  distinctTemp.patient_id,distinctTemp.patient_id_source,''A'',  '|| upload_id ||'
				from 
					(select distinct encounter_id, encounter_id_source,patient_id,patient_id_source from ' || tempTableName || '  temp
					where 
				     not exists (select encounter_ide from encounter_mapping em where em.encounter_ide = temp.encounter_id and em.encounter_ide_source = temp.encounter_id_source)
					 and encounter_id_source = ''HIVE'' )   distinctTemp) ' ;

	
	
	-- update patient_num for temp table
execute immediate ' UPDATE ' ||  tempTableName
 || ' SET encounter_num = (SELECT em.encounter_num
		     FROM encounter_mapping em
		     WHERE em.encounter_ide = '|| tempTableName ||'.encounter_id
                     and em.encounter_ide_source = '|| tempTableName ||'.encounter_id_source 
					 and nvl(em.patient_ide_source,'''') = nvl('|| tempTableName ||'.patient_id_source,'''')
				     and nvl(em.patient_ide,'''')= nvl('|| tempTableName ||'.patient_id,'''')
	 	    )
WHERE EXISTS (SELECT em.encounter_num 
		     FROM encounter_mapping em
		     WHERE em.encounter_ide = '|| tempTableName ||'.encounter_id
                     and em.encounter_ide_source = '||tempTableName||'.encounter_id_source
					 and nvl(em.patient_ide_source,'''') = nvl('|| tempTableName ||'.patient_id_source,'''')
				     and nvl(em.patient_ide,'''')= nvl('|| tempTableName ||'.patient_id,''''))';	

	 execute immediate ' UPDATE visit_dimension  set  (	START_DATE,END_DATE,INOUT_CD,LOCATION_CD,VISIT_BLOB,UPDATE_DATE,DOWNLOAD_DATE,IMPORT_DATE,SOURCESYSTEM_CD, UPLOAD_ID ) 
			= (select temp.START_DATE,temp.END_DATE,temp.INOUT_CD,temp.LOCATION_CD,temp.VISIT_BLOB,temp.update_date,temp.DOWNLOAD_DATE,sysdate,temp.SOURCESYSTEM_CD,
			     	' || UPLOAD_ID  || ' from ' || tempTableName || '  temp   where 
					temp.encounter_num = visit_dimension.encounter_num and temp.update_date >= visit_dimension.update_date) 
					where exists (select 1 from ' || tempTableName || ' temp  where temp.encounter_num = visit_dimension.encounter_num 
					and temp.update_date >= visit_dimension.update_date) ';

   execute immediate 'insert into visit_dimension  (encounter_num,patient_num,START_DATE,END_DATE,INOUT_CD,LOCATION_CD,VISIT_BLOB,UPDATE_DATE,DOWNLOAD_DATE,IMPORT_DATE,SOURCESYSTEM_CD, UPLOAD_ID)
	               select temp.encounter_num, pm.patient_num,
					temp.START_DATE,temp.END_DATE,temp.INOUT_CD,temp.LOCATION_CD,temp.VISIT_BLOB,
					temp.update_date,
					temp.download_date,
					sysdate, -- import date
					temp.sourcesystem_cd,
		            '|| upload_id ||'
			from 
				' || tempTableName || '  temp , patient_mapping pm 
			where 
                 temp.encounter_num is not null and 
		      	 not exists (select encounter_num from visit_dimension vd where vd.encounter_num = temp.encounter_num) and 
				 pm.patient_ide = temp.patient_id and pm.patient_ide_source = temp.patient_id_source
	 ';
commit;
		        
EXCEPTION
	WHEN OTHERS THEN
		rollback;
		raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);	
END;
 

GO
CREATE PROCEDURE INSERT_MODIFIER_FROMTEMP (tempModifierTableName IN VARCHAR, upload_id IN NUMBER, errorMsg OUT VARCHAR ) 
IS 

BEGIN 
	--Delete duplicate rows 
	execute immediate 'DELETE FROM ' || tempModifierTableName || ' t1 WHERE rowid > 
					   (SELECT  min(rowid) FROM ' || tempModifierTableName || ' t2
					     WHERE t1.modifier_cd = t2.modifier_cd 
                                            AND t1.modifier_path = t2.modifier_path
                                            )';
	
	   execute immediate ' UPDATE modifier_dimension  set  (modifier_cd,
                        name_char,modifier_blob,
                        update_date,download_date,
                        import_date,sourcesystem_cd,
			     	UPLOAD_ID) = (select temp.modifier_cd, temp.name_char,temp.modifier_blob,temp.update_date,temp.DOWNLOAD_DATE,sysdate,temp.SOURCESYSTEM_CD,
			     	' || UPLOAD_ID  || ' from ' || tempModifierTableName || '  temp   where 
					temp.modifier_path = modifier_dimension.modifier_path and temp.update_date >= modifier_dimension.update_date) 
					where exists (select 1 from ' || tempModifierTableName || ' temp  where temp.modifier_path = modifier_dimension.modifier_path 
					and temp.update_date >= modifier_dimension.update_date) ';



   
    --Create new modifier if temp table modifier_path does not exists 
	-- in modifier dimension table.
	execute immediate 'insert into modifier_dimension  (modifier_cd,modifier_path,name_char,modifier_blob,update_date,download_date,import_date,sourcesystem_cd,upload_id)
			    select  modifier_cd, modifier_path,
                        name_char,modifier_blob,
                        update_date,download_date,
                        sysdate,sourcesystem_cd,
                         ' || upload_id || '  from ' || tempModifierTableName || '  temp
					where not exists (select modifier_cd from modifier_dimension cd where cd.modifier_path = temp.modifier_path)
					 
	';
	
	
    
    
EXCEPTION
	WHEN OTHERS THEN
		raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);	
END;

 
GO
CREATE PROCEDURE INSERT_PATIENT_MAP_FROMTEMP (tempPatientTableName IN VARCHAR,  upload_id IN NUMBER,
   errorMsg OUT VARCHAR ) 
IS 

BEGIN 
	
	--Create new patient mapping entry for HIVE patient's if they are not already mapped in mapping table
	execute immediate 'insert into patient_mapping (
		select distinct temp.patient_id, temp.patient_id_source,''A'',temp.patient_id ,' || upload_id || '
		from ' || tempPatientTableName ||'  temp 
		where temp.patient_id_source = ''HIVE'' and 
   		not exists (select patient_ide from patient_mapping pm where pm.patient_num = temp.patient_id and pm.patient_ide_source = temp.patient_id_source) 
		)'; 

    --Create new visit for above inserted encounter's
	--If Visit table's encounter and patient num does match temp table,
	--then new visit information is created.
	execute immediate 'MERGE  INTO patient_dimension pd
		   USING ( select case when (ptemp.patient_id_source=''HIVE'') then to_number(ptemp.patient_id)
                                       else pmap.patient_num end patient_num,
                                  ptemp.VITAL_STATUS_CD, 
                                  ptemp.BIRTH_DATE,
                                  ptemp.DEATH_DATE, 
                                  ptemp.SEX_CD ,
                                  ptemp.AGE_IN_YEARS_NUM,
                                  ptemp.LANGUAGE_CD,
                                  ptemp.RACE_CD,
                                  ptemp.MARITAL_STATUS_CD,
                                  ptemp.RELIGION_CD,
                                  ptemp.ZIP_CD,
								  ptemp.STATECITYZIP_PATH , 
								  ptemp.PATIENT_BLOB, 
								  ptemp.UPDATE_DATE, 
								  ptemp.DOWNLOAD_DATE, 
								  ptemp.IMPORT_DATE, 
								  ptemp.SOURCESYSTEM_CD
								 
                   from ' || tempPatientTableName || '  ptemp , patient_mapping pmap
                   where   ptemp.patient_id = pmap.patient_ide(+)
                   and ptemp.patient_id_source = pmap.patient_ide_source(+)
           ) temp
		   on (
				pd.patient_num = temp.patient_num
		    )    
			when matched then 
			 	update  set 
			 		pd.VITAL_STATUS_CD= temp.VITAL_STATUS_CD,
                    pd.BIRTH_DATE= temp.BIRTH_DATE,
                    pd.DEATH_DATE= temp.DEATH_DATE,
                    pd.SEX_CD= temp.SEX_CD,
                    pd.AGE_IN_YEARS_NUM=temp.AGE_IN_YEARS_NUM,
                    pd.LANGUAGE_CD=temp.LANGUAGE_CD,
                    pd.RACE_CD=temp.RACE_CD,
                    pd.MARITAL_STATUS_CD=temp.MARITAL_STATUS_CD,
                    pd.RELIGION_CD=temp.RELIGION_CD,
                    pd.ZIP_CD=temp.ZIP_CD,
					pd.STATECITYZIP_PATH =temp.STATECITYZIP_PATH,
					pd.PATIENT_BLOB=temp.PATIENT_BLOB,
					pd.UPDATE_DATE=temp.UPDATE_DATE,
					pd.DOWNLOAD_DATE=temp.DOWNLOAD_DATE,
					pd.SOURCESYSTEM_CD=temp.SOURCESYSTEM_CD,
					pd.UPLOAD_ID = '||upload_id||'
                    where temp.update_date > pd.update_date
			 when not matched then 
			 	insert (
					PATIENT_NUM,
					VITAL_STATUS_CD,
                    BIRTH_DATE,
                    DEATH_DATE,
                    SEX_CD,
                    AGE_IN_YEARS_NUM,
                    LANGUAGE_CD,
                    RACE_CD,
                    MARITAL_STATUS_CD,
                    RELIGION_CD,
                    ZIP_CD,
					STATECITYZIP_PATH,
					PATIENT_BLOB,
					UPDATE_DATE,
					DOWNLOAD_DATE,
					SOURCESYSTEM_CD,
					import_date,
	                upload_id
 					) 
			 	values (
 					temp.PATIENT_NUM,
					temp.VITAL_STATUS_CD,
                    temp.BIRTH_DATE,
                    temp.DEATH_DATE,
                    temp.SEX_CD,
                    temp.AGE_IN_YEARS_NUM,
                    temp.LANGUAGE_CD,
                    temp.RACE_CD,
                    temp.MARITAL_STATUS_CD,
                    temp.RELIGION_CD,
                    temp.ZIP_CD,
					temp.STATECITYZIP_PATH,
					temp.PATIENT_BLOB,
					temp.UPDATE_DATE,
					temp.DOWNLOAD_DATE,
					temp.SOURCESYSTEM_CD,
					sysdate,
	     			'||upload_id||'
 				)';

    
EXCEPTION
	WHEN OTHERS THEN
		raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);	
END;
 

GO
CREATE PROCEDURE INSERT_PID_MAP_FROMTEMP (tempPidTableName IN VARCHAR,  upload_id IN NUMBER, 
   errorMsg OUT VARCHAR) 
is
 existingPatientNum varchar2(32);
 maxPatientNum number;

 TYPE distinctPidCurTyp IS REF CURSOR;
distinctPidCur   distinctPidCurTyp;
 sql_stmt  varchar2(400);
 
disPatientId varchar2(100); 
disPatientIdSource varchar2(100);

BEGIN
 sql_stmt := ' SELECT distinct patient_id,patient_id_source from ' || tempPidTableName ||' ';
 
  --delete the data if they miss 
  execute immediate ' delete  from ' || tempPidTableName ||  ' t1  where 
rowid > (select min(rowid) from ' || tempPidTableName || ' t2 
where t1.patient_map_id = t2.patient_map_id
and t1.patient_map_id_source = t2.patient_map_id_source) ';
  
 LOCK TABLE  patient_mapping IN EXCLUSIVE MODE NOWAIT;
 select max(patient_num) into maxPatientNum from patient_mapping ; 
 -- set max patient num to zero of the value is null
 if maxPatientNum is null then 
  maxPatientNum := 0;
end if;

  open distinctPidCur for sql_stmt ;
 
   loop
   
     FETCH distinctPidCur INTO disPatientId, disPatientIdSource;
      EXIT WHEN distinctPidCur%NOTFOUND;
        -- dbms_output.put_line(disPatientId);
        
  if  disPatientIdSource = 'HIVE'  THEN 
   begin
    --check if hive number exist, if so assign that number to reset of map_id's within that pid
    select patient_num into existingPatientNum from patient_mapping where patient_num = disPatientId and patient_ide_source = 'HIVE';
    EXCEPTION  
       when NO_DATA_FOUND THEN
           existingPatientNum := null;
    end;
   if existingPatientNum is not null then 
        execute immediate ' update ' || tempPidTableName ||' set patient_num = patient_id, process_status_flag = ''P''
        where patient_id = :x and not exists (select 1 from patient_mapping pm where pm.patient_ide = patient_map_id
        and pm.patient_ide_source = patient_map_id_source)' using disPatientId;
   else 
        -- generate new patient_num i.e. take max(patient_num) + 1 
        if maxPatientNum < disPatientId then 
            maxPatientNum := disPatientId;
        end if ;
        execute immediate ' update ' || tempPidTableName ||' set patient_num = patient_id, process_status_flag = ''P'' where 
        patient_id = :x and patient_id_source = ''HIVE'' and not exists (select 1 from patient_mapping pm where pm.patient_ide = patient_map_id
        and pm.patient_ide_source = patient_map_id_source)' using disPatientId;
   end if;    
    
   -- test if record fectched
   -- dbms_output.put_line(' HIVE ');

 else 
    begin
       select patient_num into existingPatientNum from patient_mapping where patient_ide = disPatientId and 
        patient_ide_source = disPatientIdSource ; 

       -- test if record fetched. 
       EXCEPTION
           WHEN NO_DATA_FOUND THEN
           existingPatientNum := null;
       end;
       if existingPatientNum is not null then 
            execute immediate ' update ' || tempPidTableName ||' set patient_num = :x , process_status_flag = ''P''
            where patient_id = :y and not exists (select 1 from patient_mapping pm where pm.patient_ide = patient_map_id
        and pm.patient_ide_source = patient_map_id_source)' using  existingPatientNum,disPatientId;
       else 

            maxPatientNum := maxPatientNum + 1 ; 
             execute immediate 'insert into ' || tempPidTableName ||' (patient_map_id,patient_map_id_source,patient_id,patient_id_source,patient_num,process_status_flag
             ,patient_map_id_status,update_date,download_date,import_date,sourcesystem_cd) 
             values(:x,''HIVE'',:y,''HIVE'',:z,''P'',''A'',sysdate,sysdate,sysdate,''edu.harvard.i2b2.crc'')' using maxPatientNum,maxPatientNum,maxPatientNum; 
            execute immediate 'update ' || tempPidTableName ||' set patient_num =  :x , process_status_flag = ''P'' 
             where patient_id = :y and  not exists (select 1 from 
            patient_mapping pm where pm.patient_ide = patient_map_id
            and pm.patient_ide_source = patient_map_id_source)' using maxPatientNum, disPatientId  ;
            
       end if ;
    
      -- dbms_output.put_line(' NOT HIVE ');
 end if; 

END LOOP;
close distinctPidCur ;
commit;

-- do the mapping update if the update date is old
   execute immediate ' merge into patient_mapping
      using ' || tempPidTableName ||' temp
      on (temp.patient_map_id = patient_mapping.patient_IDE 
  		  and temp.patient_map_id_source = patient_mapping.patient_IDE_SOURCE
	   ) when matched then 
  		update set patient_num = temp.patient_id,
    	patient_ide_status	= temp.patient_map_id_status  ,
    	update_date = temp.update_date,
    	download_date  = temp.download_date ,
		import_date = sysdate ,
    	sourcesystem_cd  = temp.sourcesystem_cd ,
		upload_id = ' || upload_id ||'  
    	where  temp.patient_id_source = ''HIVE'' and temp.process_status_flag is null  and
        nvl(patient_mapping.update_date,to_date(''01-JAN-1900'',''DD-MON-YYYY''))<= nvl(temp.update_date,to_date(''01-JAN-1900'',''DD-MON-YYYY'')) ' ;

-- insert new mapping records i.e flagged P
execute immediate ' insert into patient_mapping (patient_ide,patient_ide_source,patient_ide_status,patient_num,update_date,download_date,import_date,sourcesystem_cd,upload_id) 
    select patient_map_id,patient_map_id_source,patient_map_id_status,patient_num,update_date,download_date,sysdate,sourcesystem_cd,' || upload_id ||' from '|| tempPidTableName || ' 
    where process_status_flag = ''P'' ' ; 
commit;
EXCEPTION
   WHEN OTHERS THEN
      if distinctPidCur%isopen then
          close distinctPidCur;
      end if;
      rollback;
      raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
end;

GO
CREATE PROCEDURE INSERT_PROVIDER_FROMTEMP (tempProviderTableName IN VARCHAR, upload_id IN NUMBER,
   errorMsg OUT VARCHAR)

IS 

BEGIN 
	--Delete duplicate rows with same encounter and patient combination
	execute immediate 'DELETE FROM ' || tempProviderTableName || ' t1 WHERE rowid > 
					   (SELECT  min(rowid) FROM ' || tempProviderTableName || ' t2
					     WHERE t1.provider_id = t2.provider_id 
                                            AND t1.provider_path = t2.provider_path
                                            )';
	
	

 execute immediate ' UPDATE provider_dimension  set  (provider_id,
                        name_char,provider_blob,
                        update_date,download_date,
                        import_date,sourcesystem_cd,
			     	UPLOAD_ID) = (select temp.provider_id, temp.name_char,temp.provider_blob,temp.update_date,temp.DOWNLOAD_DATE,sysdate,temp.SOURCESYSTEM_CD,
			     	' || UPLOAD_ID  || ' from ' || tempProviderTableName || '  temp   where 
					temp.provider_path = provider_dimension.provider_path and temp.update_date >= provider_dimension.update_date) 
					where exists (select 1 from ' || tempProviderTableName || ' temp  where temp.provider_path = provider_dimension.provider_path 
					and temp.update_date >= provider_dimension.update_date) ';

   
    --Create new patient(patient_mapping) if temp table patient_ide does not exists 
	-- in patient_mapping table.
	execute immediate 'insert into provider_dimension  (provider_id,provider_path,name_char,provider_blob,update_date,download_date,import_date,sourcesystem_cd,upload_id)
			    select  provider_id,provider_path, 
                        name_char,provider_blob,
                        update_date,download_date,
                        sysdate,sourcesystem_cd, ' || upload_id || '
	                    
                         from ' || tempProviderTableName || '  temp
					where not exists (select provider_id from provider_dimension pd where pd.provider_path = temp.provider_path )';
	
	
    
    
EXCEPTION
	WHEN OTHERS THEN
		raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);	
END;
 

GO
CREATE PROCEDURE REMOVE_TEMP_TABLE(tempTableName VARCHAR) 
IS
BEGIN 
	execute immediate 'drop table ' || tempTableName || ' cascade constraints';
	
EXCEPTION
	WHEN OTHERS THEN
		dbms_output.put_line(SQLCODE|| ' - ' ||SQLERRM);
END;

GO
CREATE PROCEDURE SYNC_CLEAR_CONCEPT_TABLE (tempConceptTableName in VARCHAR, backupConceptTableName IN VARCHAR, uploadId in NUMBER, errorMsg OUT VARCHAR ) 
IS 

interConceptTableName  varchar2(400);

BEGIN 
	interConceptTableName := backupConceptTableName || '_inter';
	
		--Delete duplicate rows with same encounter and patient combination
	execute immediate 'DELETE FROM ' || tempConceptTableName || ' t1 WHERE rowid > 
					   (SELECT  min(rowid) FROM ' || tempConceptTableName || ' t2
					     WHERE t1.concept_cd = t2.concept_cd 
                                            AND t1.concept_path = t2.concept_path
                                            )';

    execute immediate 'create table ' ||  interConceptTableName || ' (
    CONCEPT_CD          VARCHAR2(50) NOT NULL,
	CONCEPT_PATH    	VARCHAR2(700) NOT NULL,
	NAME_CHAR       	VARCHAR2(2000) NULL,
	CONCEPT_BLOB        CLOB NULL,
	UPDATE_DATE         DATE NULL,
	DOWNLOAD_DATE       DATE NULL,
	IMPORT_DATE         DATE NULL,
	SOURCESYSTEM_CD     VARCHAR2(50) NULL,
	UPLOAD_ID       	NUMBER(38,0) NULL,
    CONSTRAINT '|| interConceptTableName ||'_pk  PRIMARY KEY(CONCEPT_PATH)
	 )';
    
    --Create new patient(patient_mapping) if temp table patient_ide does not exists 
	-- in patient_mapping table.
	execute immediate 'insert into '|| interConceptTableName ||'  (concept_cd,concept_path,name_char,concept_blob,update_date,download_date,import_date,sourcesystem_cd,upload_id)
			    select  concept_cd, substr(concept_path,1,700),
                        name_char,concept_blob,
                        update_date,download_date,
                        sysdate,sourcesystem_cd,
                         ' || uploadId || '  from ' || tempConceptTableName || '  temp ';
	--backup the concept_dimension table before creating a new one
	execute immediate 'alter table concept_dimension rename to ' || backupConceptTableName  ||'' ;
    
	-- add index on upload_id 
    execute immediate 'CREATE INDEX ' || interConceptTableName || '_uid_idx ON ' || interConceptTableName || '(UPLOAD_ID)';

    -- add index on upload_id 
    execute immediate 'CREATE INDEX ' || interConceptTableName || '_cd_idx ON ' || interConceptTableName || '(concept_cd)';

    
    --backup the concept_dimension table before creating a new one
	execute immediate 'alter table ' || interConceptTableName  || ' rename to concept_dimension' ;
 
EXCEPTION
	WHEN OTHERS THEN
		raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);	
END;

 
GO
CREATE PROCEDURE SYNC_CLEAR_MODIFIER_TABLE (tempModifierTableName in VARCHAR, backupModifierTableName IN VARCHAR, uploadId in NUMBER, errorMsg OUT VARCHAR ) 
IS 

interModifierTableName  varchar2(400);

BEGIN 
	interModifierTableName := backupModifierTableName || '_inter';
	
	--Delete duplicate rows with same modifier_path and modifier cd
	execute immediate 'DELETE FROM ' || tempModifierTableName || ' t1 WHERE rowid > 
					   (SELECT  min(rowid) FROM ' || tempModifierTableName || ' t2
					     WHERE t1.modifier_cd = t2.modifier_cd 
                                            AND t1.modifier_path = t2.modifier_path
                                            )';

    execute immediate 'create table ' ||  interModifierTableName || ' (
        MODIFIER_CD          VARCHAR2(50) NOT NULL,
	MODIFIER_PATH    	VARCHAR2(700) NOT NULL,
	NAME_CHAR       	VARCHAR2(2000) NULL,
	MODIFIER_BLOB        CLOB NULL,
	UPDATE_DATE         DATE NULL,
	DOWNLOAD_DATE       DATE NULL,
	IMPORT_DATE         DATE NULL,
	SOURCESYSTEM_CD     VARCHAR2(50) NULL,
	UPLOAD_ID       	NUMBER(38,0) NULL,
    CONSTRAINT '|| interModifierTableName ||'_pk  PRIMARY KEY(MODIFIER_PATH)
	 )';
    
    --Create new patient(patient_mapping) if temp table patient_ide does not exists 
	-- in patient_mapping table.
	execute immediate 'insert into '|| interModifierTableName ||'  (modifier_cd,modifier_path,name_char,modifier_blob,update_date,download_date,import_date,sourcesystem_cd,upload_id)
			    select  modifier_cd, substr(modifier_path,1,700),
                        name_char,modifier_blob,
                        update_date,download_date,
                        sysdate,sourcesystem_cd,
                         ' || uploadId || '  from ' || tempModifierTableName || '  temp ';
	--backup the modifier_dimension table before creating a new one
	execute immediate 'alter table modifier_dimension rename to ' || backupModifierTableName  ||'' ;
    
	-- add index on upload_id 
    execute immediate 'CREATE INDEX ' || interModifierTableName || '_uid_idx ON ' || interModifierTableName || '(UPLOAD_ID)';

    -- add index on upload_id 
    execute immediate 'CREATE INDEX ' || interModifierTableName || '_cd_idx ON ' || interModifierTableName || '(modifier_cd)';

    
       --backup the modifier_dimension table before creating a new one
	execute immediate 'alter table ' || interModifierTableName  || ' rename to modifier_dimension' ;
 
EXCEPTION
	WHEN OTHERS THEN
		raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);	
END;

 
GO
CREATE PROCEDURE SYNC_CLEAR_PROVIDER_TABLE (tempProviderTableName in VARCHAR, backupProviderTableName IN VARCHAR, uploadId in NUMBER, errorMsg OUT VARCHAR ) 
IS 

interProviderTableName  varchar2(400);

BEGIN 
	interProviderTableName := backupProviderTableName || '_inter';
	
		--Delete duplicate rows with same encounter and patient combination
	execute immediate 'DELETE FROM ' || tempProviderTableName || ' t1 WHERE rowid > 
					   (SELECT  min(rowid) FROM ' || tempProviderTableName || ' t2
					     WHERE t1.provider_id = t2.provider_id 
                                            AND t1.provider_path = t2.provider_path
                                            )';

    execute immediate 'create table ' ||  interProviderTableName || ' (
    PROVIDER_ID         VARCHAR2(50) NOT NULL,
	PROVIDER_PATH       VARCHAR2(700) NOT NULL,
	NAME_CHAR       	VARCHAR2(850) NULL,
	PROVIDER_BLOB       CLOB NULL,
	UPDATE_DATE     	DATE NULL,
	DOWNLOAD_DATE       DATE NULL,
	IMPORT_DATE         DATE NULL,
	SOURCESYSTEM_CD     VARCHAR2(50) NULL,
	UPLOAD_ID        	NUMBER(38,0) NULL ,
    CONSTRAINT  ' || interProviderTableName || '_pk PRIMARY KEY(PROVIDER_PATH,provider_id)
	 )';
    
    --Create new patient(patient_mapping) if temp table patient_ide does not exists 
	-- in patient_mapping table.
	execute immediate 'insert into ' ||  interProviderTableName || ' (provider_id,provider_path,name_char,provider_blob,update_date,download_date,import_date,sourcesystem_cd,upload_id)
			    select  provider_id,provider_path, 
                        name_char,provider_blob,
                        update_date,download_date,
                        sysdate,sourcesystem_cd, ' || uploadId || '
	                     from ' || tempProviderTableName || '  temp ';
					
	--backup the concept_dimension table before creating a new one
	execute immediate 'alter table provider_dimension rename to ' || backupProviderTableName  ||'' ;
    
	-- add index on provider_id, name_char 
    execute immediate 'CREATE INDEX ' || interProviderTableName || '_id_idx ON ' || interProviderTableName  || '(Provider_Id,name_char)';
    execute immediate 'CREATE INDEX ' || interProviderTableName || '_uid_idx ON ' || interProviderTableName  || '(UPLOAD_ID)';

	--backup the concept_dimension table before creating a new one
	execute immediate 'alter table ' || interProviderTableName  || ' rename to provider_dimension' ;
 
EXCEPTION
	WHEN OTHERS THEN
		raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);	
END;

 
GO
CREATE PROCEDURE UPDATE_OBSERVATION_FACT (upload_temptable_name IN VARCHAR, upload_id IN NUMBER, appendFlag IN NUMBER,
   errorMsg OUT VARCHAR)
IS
BEGIN



--Delete duplicate records(encounter_ide,patient_ide,concept_cd,start_date,modifier_cd,provider_id)
execute immediate 'DELETE FROM ' || upload_temptable_name ||'  t1 
  where rowid > (select min(rowid) from ' || upload_temptable_name ||' t2 
    where t1.encounter_id = t2.encounter_id  
          and
          t1.encounter_id_source = t2.encounter_id_source
          and
          t1.patient_id = t2.patient_id 
          and 
          t1.patient_id_source = t2.patient_id_source
          and 
          t1.concept_cd = t2.concept_cd
          and 
          t1.start_date = t2.start_date
          and 
          nvl(t1.modifier_cd,''xyz'') = nvl(t2.modifier_cd,''xyz'')
		  and 
		  t1.instance_num = t2.instance_num
          and 
          t1.provider_id = t2.provider_id)';

          
--Delete records having null in start_date
execute immediate 'DELETE FROM ' || upload_temptable_name ||'  t1           
 where t1.start_date is null';
           
           
--One time lookup on encounter_ide to get encounter_num 
execute immediate 'UPDATE ' ||  upload_temptable_name
 || ' SET encounter_num = (SELECT distinct em.encounter_num
		     FROM encounter_mapping em
		     WHERE em.encounter_ide = ' || upload_temptable_name||'.encounter_id
                     and em.encounter_ide_source = '|| upload_temptable_name||'.encounter_id_source
	 	    )
WHERE EXISTS (SELECT distinct em.encounter_num
		     FROM encounter_mapping em
		     WHERE em.encounter_ide = '|| upload_temptable_name||'.encounter_id
                     and em.encounter_ide_source = '||upload_temptable_name||'.encounter_id_source)';		     




             
--One time lookup on patient_ide to get patient_num 
execute immediate 'UPDATE ' ||  upload_temptable_name
 || ' SET patient_num = (SELECT distinct pm.patient_num
		     FROM patient_mapping pm
		     WHERE pm.patient_ide = '|| upload_temptable_name||'.patient_id
                     and pm.patient_ide_source = '|| upload_temptable_name||'.patient_id_source
	 	    )
WHERE EXISTS (SELECT distinct pm.patient_num 
		     FROM patient_mapping pm
		     WHERE pm.patient_ide = '|| upload_temptable_name||'.patient_id
                     and pm.patient_ide_source = '||upload_temptable_name||'.patient_id_source)';		     



IF (appendFlag = 0) THEN
--Archive records which are to be deleted in observation_fact table
execute immediate 'INSERT ALL INTO  archive_observation_fact 
		SELECT obsfact.*, ' || upload_id ||' archive_upload_id 
		FROM observation_fact obsfact
		WHERE obsfact.encounter_num IN 
			(SELECT temp_obsfact.encounter_num
			FROM  ' ||upload_temptable_name ||' temp_obsfact
                        group by temp_obsfact.encounter_num  
            )';


--Delete above archived row from observation_fact
execute immediate 'DELETE  observation_fact 
					WHERE EXISTS (
					SELECT archive.encounter_num
					FROM archive_observation_fact  archive
					where archive.archive_upload_id = '||upload_id ||'
                                         AND archive.encounter_num=observation_fact.encounter_num
										 AND archive.concept_cd = observation_fact.concept_cd
										 AND archive.start_date = observation_fact.start_date
                    )';
END IF;

-- if the append is true, then do the update else do insert all
IF (appendFlag = 0) THEN

--Transfer all rows from temp_obsfact to observation_fact
execute immediate 'INSERT ALL INTO observation_fact(encounter_num,concept_cd, patient_num,provider_id, start_date,modifier_cd,instance_num,valtype_cd,tval_char,nval_num,valueflag_cd,
quantity_num,confidence_num,observation_blob,units_cd,end_date,location_cd, update_date,download_date,import_date,sourcesystem_cd,
upload_id) 
SELECT encounter_num,concept_cd, patient_num,provider_id, start_date,modifier_cd,instance_num,valtype_cd,tval_char,nval_num,valueflag_cd,
quantity_num,confidence_num,observation_blob,units_cd,end_date,location_cd, update_date,download_date,sysdate import_date,sourcesystem_cd,
temp.upload_id 
FROM ' || upload_temptable_name ||' temp
where temp.patient_num is not null and  temp.encounter_num is not null';

ELSE

execute immediate ' UPDATE observation_fact  set 
			 		valtype_cd = temp.valtype_cd,
                    tval_char = temp.tval_char,
                    nval_num = temp.nval_num ,
                    valueflag_cd = temp.valueflag_cd,
                    quantity_num = temp.quantity_num,
                    confidence_num = temp.confidence_num ,
                    observation_blob = temp.observation_blob,
                    units_cd = temp.units_cd,
                    end_date = temp.end_date,
                    location_cd = temp.location_cd,
                    update_date= temp.update_date,
                    download_date = temp.download_date,
                    import_date = getdate(),
                    sourcesystem_cd = temp.sourcesystem_cd,
					UPLOAD_ID = '||upload_id ||' 
					from observation_fact obsfact 
                    inner join ' || upload_temptable_name ||'  temp
                    on  obsfact.encounter_num = temp.encounter_num 
				    and obsfact.patient_num = temp.patient_num
                    and obsfact.concept_cd = temp.concept_cd
					and obsfact.start_date = temp.start_date
		            and obsfact.provider_id = temp.provider_id
			 		and obsfact.modifier_cd = temp.modifier_cd
					and obsfact.instance_num = temp.instance_num
                    where isnull(obsfact.update_date,0) <= isnull(temp.update_date,0)';


execute immediate  'insert into observation_fact(encounter_num,
	patient_num,concept_cd,provider_id,start_date,modifier_cd,instance_num,valtype_cd,tval_char,
	nval_num,valueflag_cd,quantity_num,units_cd,end_date,location_cd ,confidence_num,observation_blob,
	update_date,download_date,import_date,sourcesystem_cd,upload_id) 
     select  temp.encounter_num, temp.patient_num,temp.concept_cd,temp.provider_id,temp.start_date,temp.modifier_cd,temp.instance_num,temp.valtype_cd,temp.tval_char,
	temp.nval_num,temp.valueflag_cd,temp.quantity_num,temp.units_cd,temp.end_date,temp.location_cd,temp.confidence_num,temp.observation_blob,
	temp.update_date,temp.download_date,getdate(),temp.sourcesystem_cd, '||upload_id ||' from  ' || upload_temptable_name ||'  temp 
					 where temp.patient_num is not null and  temp.encounter_num is not null and not exists (select obsfact.concept_cd from observation_fact obsfact where  
				     obsfact.encounter_num = temp.encounter_num 
				      and obsfact.patient_num = temp.patient_num
                      and obsfact.concept_cd = temp.concept_cd
					  and obsfact.start_date = temp.start_date
		              and obsfact.provider_id = temp.provider_id
			 		  and obsfact.modifier_cd = temp.modifier_cd
					  and obsfact.instance_num = temp.instance_num
					) ';

END IF;

EXCEPTION
	WHEN OTHERS THEN
		raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);	
END;
GO





/*********************************************************/
--
--                              RUN ON WORKPLACE DATABASE
--
/*********************************************************/


CREATE TABLE WORKPLACE ( 
	C_NAME     	VARCHAR2(255) NOT NULL,
	C_USER_ID	VARCHAR2(255) NOT NULL,
	C_GROUP_ID	VARCHAR2(255) NOT NULL,
	C_SHARE_ID	VARCHAR2(255) NULL,
	C_INDEX  	VARCHAR2(255) NOT NULL,
	C_PARENT_INDEX  	VARCHAR2(255) NULL,
	C_VISUALATTRIBUTES   	CHAR(3) NOT NULL,
	C_PROTECTED_ACCESS    	CHAR(1) NULL,
	C_TOOLTIP      	VARCHAR2(255) NULL,
	C_WORK_XML      	CLOB NULL,
	C_WORK_XML_SCHEMA      	CLOB NULL,
	C_WORK_XML_I2B2_TYPE      	VARCHAR2(255) NULL,
	C_ENTRY_DATE   	DATE NULL,
	C_CHANGE_DATE  	DATE NULL,
	C_STATUS_CD    	CHAR(1) NULL,
 CONSTRAINT WORKPLACE_PK PRIMARY KEY(C_INDEX)  
	);


CREATE TABLE WORKPLACE_ACCESS ( 
	C_TABLE_CD   	VARCHAR2(255) NOT NULL,
	C_TABLE_NAME      VARCHAR2(255) NOT NULL,
	C_PROTECTED_ACCESS    	CHAR(1) NULL,
	C_HLEVEL	INT NOT NULL,
	C_NAME     	VARCHAR2(255) NOT NULL,
	C_USER_ID	VARCHAR2(255) NOT NULL,
	C_GROUP_ID	VARCHAR2(255) NOT NULL,
	C_SHARE_ID	VARCHAR2(255) NULL,
	C_INDEX  	VARCHAR2(255) NOT NULL,
	C_PARENT_INDEX  	VARCHAR2(255) NULL,
	C_VISUALATTRIBUTES   	CHAR(3) NOT NULL,
	C_TOOLTIP      	VARCHAR2(255) NULL,
	C_ENTRY_DATE   	DATE NULL,
	C_CHANGE_DATE  	DATE NULL,
	C_STATUS_CD    	CHAR(1) NULL,
 CONSTRAINT WORKPLACE_ACCESS_PK PRIMARY KEY(C_INDEX) 
	);
	



	
	





/*********************************************************
*
*				RUN ON ONTOLOGY DATABASE
*
/*********************************************************


CREATE TABLE ONT_PROCESS_STATUS (
    PROCESS_ID			NUMBER(5,0) PRIMARY KEY, 
    PROCESS_TYPE_CD		VARCHAR(50),
    START_DATE			DATE, 
    END_DATE			DATE,
    PROCESS_STEP_CD		VARCHAR2(50),
    PROCESS_STATUS_CD   VARCHAR2(50),
    CRC_UPLOAD_ID		NUMBER(38,0),
    STATUS_CD			VARCHAR2(50),
    MESSAGE			CLOB,
    ENTRY_DATE			DATE,
    CHANGE_DATE			DATE,
    CHANGEDBY_CHAR		CHAR(50)
)
/


	/*****************************************************************
	* Populate the Star Schema tables
	******************************************************************/

	create table SCHEMES as select * from _ONTDB_.SCHEMES
/
	create table PCORNET_DEMO as select * from _ONTDB_.PCORNET_DEMO
/
	create table PCORNET_DIAG as select * from _ONTDB_.PCORNET_DIAG
/
	create table PCORNET_ENC as select * from _ONTDB_.PCORNET_ENC
/
	create table PCORNET_PROC as select * from _ONTDB_.PCORNET_PROC
/
	create table PCORNET_VITAL as select * from _ONTDB_.PCORNET_VITAL
/
	create table PCORNET_ENROLL as select * from _ONTDB_.PCORNET_ENROLL
/
	create table table_access as select * from _ONTDB_.table_access
/





