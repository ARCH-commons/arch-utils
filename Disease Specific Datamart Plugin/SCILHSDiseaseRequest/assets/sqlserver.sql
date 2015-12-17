        -- {$0} - Version 1.5
-----------------------------------------------------------------------------------------
-- This script contains both the DataMart and the Ontology.   Run each on the correct DB
-----------------------------------------------------------------------------------------



/*********************************************************/
--	
--				RUN ON DATAMART CRC DATABASE
--
/*********************************************************/




/*============================================================================*/
/* Table: ARCHIVE_OBSERVATION_FACT (HOLDS DELETED ENTRIES OF OBSERVATION_FACT) */
/*============================================================================*/
select * into ARCHIVE_OBSERVATION_FACT from OBSERVATION_FACT where 1=2 
;

ALTER TABLE ARCHIVE_OBSERVATION_FACT  ADD  ARCHIVE_UPLOAD_ID int
;

CREATE INDEX PK_ARCHIVE_OBSFACT ON ARCHIVE_OBSERVATION_FACT
 		(ENCOUNTER_NUM , PATIENT_NUM , CONCEPT_CD , PROVIDER_ID , START_DATE , MODIFIER_CD , ARCHIVE_UPLOAD_ID) 
;


/*==============================================================*/
/* Table: DATAMART_REPORT			                    		*/
/*==============================================================*/
create table DATAMART_REPORT ( 
	TOTAL_PATIENT         int, 
	TOTAL_OBSERVATIONFACT int, 
	TOTAL_EVENT           int,
	REPORT_DATE           DATETIME)
;




/*==============================================================*/
/* Table: UPLOAD_STATUS 					                    */
/*==============================================================*/
CREATE TABLE UPLOAD_STATUS (
	UPLOAD_ID 		    int identity(1,1) PRIMARY KEY, 	
    UPLOAD_LABEL 		VARCHAR(500) NOT NULL, 
    USER_ID      		VARCHAR(100) NOT NULL, 
    SOURCE_CD   		VARCHAR(50) NOT NULL,
    NO_OF_RECORD 		bigint,
    LOADED_RECORD 		bigint,
    DELETED_RECORD		bigint, 
    LOAD_DATE    		DATETIME			  NOT NULL,
	END_DATE 	        DATETIME , 
    LOAD_STATUS  		VARCHAR(100), 
    MESSAGE				TEXT,
    INPUT_FILE_NAME 	TEXT, 
    LOG_FILE_NAME 		TEXT, 
    TRANSFORM_NAME 		VARCHAR(500)
   
) 
;

/*==============================================================*/
/* Table: SET_TYPE						                        */
/*==============================================================*/
CREATE TABLE SET_TYPE (
	ID 				INT, 
    NAME			VARCHAR(500),
    CREATE_DATE     DATETIME,
    CONSTRAINT PK_ST_ID PRIMARY KEY (ID)
) 
;



/*==============================================================*/
/* Table: SOURCE_MASTER					                        */
/*==============================================================*/
CREATE TABLE SOURCE_MASTER ( 
   SOURCE_CD 				VARCHAR(50) NOT NULL,
   DESCRIPTION  			VARCHAR(300),
   CREATE_DATE 				DATETIME,
   CONSTRAINT PK_SOURCEMASTER_SOURCECD  PRIMARY KEY (SOURCE_CD)
)
;


/*==============================================================*/
/* Table: SET_UPLOAD_STATUS				                        */
/*==============================================================*/
CREATE TABLE SET_UPLOAD_STATUS  (
    UPLOAD_ID			INT,
    SET_TYPE_ID         INT,
    SOURCE_CD  		    VARCHAR(50) NOT NULL,
    NO_OF_RECORD 		BIGINT,
    LOADED_RECORD 		BIGINT,
    DELETED_RECORD		BIGINT, 
    LOAD_DATE    		DATETIME NOT NULL,
    END_DATE            DATETIME ,
    LOAD_STATUS  		VARCHAR(100), 
    MESSAGE			    TEXT,
    INPUT_FILE_NAME 	TEXT, 
    LOG_FILE_NAME 		TEXT, 
    TRANSFORM_NAME 		VARCHAR(500),
    CONSTRAINT PK_UP_UPSTATUS_IDSETTYPEID  PRIMARY KEY (UPLOAD_ID,SET_TYPE_ID),
    CONSTRAINT FK_UP_SET_TYPE_ID FOREIGN KEY (SET_TYPE_ID) REFERENCES SET_TYPE(ID)
) 
;


 
/*==============================================================*/
/*  Adding seed data for SET_TYPE table.  					    */
/*==============================================================*/
INSERT INTO SET_TYPE(id,name,create_date) values (1,'event_set',getdate());
INSERT INTO SET_TYPE(id,name,create_date) values (2,'patient_set',getdate());
INSERT INTO SET_TYPE(id,name,create_date) values (3,'concept_set',getdate());
INSERT INTO SET_TYPE(id,name,create_date) values (4,'observer_set',getdate());
INSERT INTO SET_TYPE(id,name,create_date) values (5,'observation_set',getdate());
INSERT INTO SET_TYPE(id,name,create_date) values (6,'pid_set',getdate());
INSERT INTO SET_TYPE(id,name,create_date) values (7,'eid_set',getdate());
INSERT INTO SET_TYPE(id,name,create_date) values (8,'modifier_set',getdate());
 


----------------------------------------------------------------------------------
-- 	Table group:		Mapping tables
--	Table members:		patient_mapping, encounter_mapping
----------------------------------------------------------------------------------

	 
	

	/****** Object:  Table [dbo].[CODE_LOOKUP] ******/
	 
	IF  OBJECT_ID('code_lookup') IS NULL
BEGIN

CREATE TABLE CODE_LOOKUP ( 
    TABLE_CD            VARCHAR(100) NOT NULL,
    COLUMN_CD           VARCHAR(100) NOT NULL,
    CODE_CD             VARCHAR(50) NOT NULL,
    NAME_CHAR           VARCHAR(650) NULL,
    LOOKUP_BLOB         TEXT NULL, 
    UPLOAD_DATE       	DATETIME NULL,
    UPDATE_DATE         DATETIME NULL,
    DOWNLOAD_DATE     	DATETIME NULL,
    IMPORT_DATE         DATETIME NULL,
    SOURCESYSTEM_CD   	VARCHAR(50) NULL,
    UPLOAD_ID         	INT NULL,
	CONSTRAINT CODE_LOOKUP_PK PRIMARY KEY(TABLE_CD, COLUMN_CD, CODE_CD)
	)


----------------------------------------------------------------------------------
-- 	Table group:		Dimension tables
--	Table members:		Observation_Fact, Visit_Dimension, Provider_Dimension, Patient_Dimension, 
--						Concept_Dimension 
----------------------------------------------------------------------------------




	/*********************************************************/
	--  Create all the QT Tables
	/**********************************************************/

/*==============================================================*/
/* Sqlserver Database Script to create CRC query tables         */
/*==============================================================*/


/*============================================================================*/
-- Table: QT_QUERY_MASTER 											          */
/*============================================================================*/
IF OBJECT_ID('QT_QUERY_MASTER') IS NULL
CREATE TABLE QT_QUERY_MASTER (
	QUERY_MASTER_ID		INT  IDENTITY(1,1) PRIMARY KEY,
	NAME				VARCHAR(250) NOT NULL,
	USER_ID				VARCHAR(50) NOT NULL,
	GROUP_ID			VARCHAR(50) NOT NULL,
	MASTER_TYPE_CD		VARCHAR(2000),
	PLUGIN_ID			INT,
	CREATE_DATE			DATETIME NOT NULL,
	DELETE_DATE			DATETIME,
	DELETE_FLAG			VARCHAR(3),
	REQUEST_XML			TEXT,
	GENERATED_SQL		TEXT,
	I2B2_REQUEST_XML	TEXT,
	PM_XML				TEXT
)



/*============================================================================*/
-- Table: QT_QUERY_RESULT_TYPE										          */
/*============================================================================*/
IF OBJECT_ID('QT_QUERY_RESULT_TYPE') IS NULL
CREATE TABLE QT_QUERY_RESULT_TYPE (
	RESULT_TYPE_ID				INT   PRIMARY KEY,
	NAME						VARCHAR(100),
	DESCRIPTION					VARCHAR(200),
	DISPLAY_TYPE_ID				NVARCHAR(500),
	VISUAL_ATTRIBUTE_TYPE_ID	NVARCHAR(3)
)



/*============================================================================*/
-- Table: QT_QUERY_STATUS_TYPE										          */
/*============================================================================*/
IF OBJECT_ID('QT_QUERY_STATUS_TYPE') IS NULL
CREATE TABLE QT_QUERY_STATUS_TYPE (
	STATUS_TYPE_ID	INT   PRIMARY KEY,
	NAME			VARCHAR(100),
	DESCRIPTION		VARCHAR(200)
)



/*============================================================================*/
-- Table: QT_QUERY_INSTANCE 										          */
/*============================================================================*/
IF OBJECT_ID('QT_QUERY_INSTANCE') IS NULL
CREATE TABLE QT_QUERY_INSTANCE (
	QUERY_INSTANCE_ID	INT  IDENTITY(1,1) PRIMARY KEY,
	QUERY_MASTER_ID		INT,
	USER_ID				VARCHAR(50) NOT NULL,
	GROUP_ID			VARCHAR(50) NOT NULL,
	BATCH_MODE			VARCHAR(50),
	START_DATE			DATETIME NOT NULL,
	END_DATE			DATETIME,
	DELETE_FLAG			VARCHAR(3),
	STATUS_TYPE_ID		INT,
	MESSAGE				TEXT,
	CONSTRAINT QT_FK_QI_MID FOREIGN KEY (QUERY_MASTER_ID)
		REFERENCES QT_QUERY_MASTER (QUERY_MASTER_ID),
	CONSTRAINT QT_FK_QI_STID FOREIGN KEY (STATUS_TYPE_ID)
		REFERENCES QT_QUERY_STATUS_TYPE (STATUS_TYPE_ID)
)




/*=============================================================================*/
-- Table: QT_QUERY_RESULT_INSTANCE   								          */
/*============================================================================*/
IF OBJECT_ID('QT_QUERY_RESULT_INSTANCE') IS NULL
	CREATE TABLE QT_QUERY_RESULT_INSTANCE (
	RESULT_INSTANCE_ID	INT  IDENTITY(1,1) PRIMARY KEY,
	QUERY_INSTANCE_ID	INT,
	RESULT_TYPE_ID		INT NOT NULL,
	SET_SIZE			INT,
	START_DATE			DATETIME NOT NULL,
	END_DATE			DATETIME,
	STATUS_TYPE_ID		INT NOT NULL,
	DELETE_FLAG			VARCHAR(3),
	MESSAGE				TEXT,
	DESCRIPTION			VARCHAR(200),
	REAL_SET_SIZE		INT,
	OBFUSC_METHOD		VARCHAR(500),
	CONSTRAINT QT_FK_QRI_RID FOREIGN KEY (QUERY_INSTANCE_ID)
		REFERENCES QT_QUERY_INSTANCE (QUERY_INSTANCE_ID),
	CONSTRAINT QT_FK_QRI_RTID FOREIGN KEY (RESULT_TYPE_ID)
		REFERENCES QT_QUERY_RESULT_TYPE (RESULT_TYPE_ID),
	CONSTRAINT QT_FK_QRI_STID FOREIGN KEY (STATUS_TYPE_ID)
		REFERENCES QT_QUERY_STATUS_TYPE (STATUS_TYPE_ID)
)



/*============================================================================*/
-- Table: QT_PATIENT_SET_COLLECTION									          */
/*============================================================================*/
IF OBJECT_ID('QT_PATIENT_SET_COLLECTION') IS NULL
CREATE TABLE QT_PATIENT_SET_COLLECTION ( 
	PATIENT_SET_COLL_ID	BIGINT  IDENTITY(1,1) PRIMARY KEY,
	RESULT_INSTANCE_ID	INT,
	SET_INDEX			INT,
	PATIENT_NUM			INT,
	CONSTRAINT QT_FK_PSC_RI FOREIGN KEY (RESULT_INSTANCE_ID )
		REFERENCES QT_QUERY_RESULT_INSTANCE (RESULT_INSTANCE_ID)
)


/*============================================================================*/
/* Table: QT_PATIENT_ENC_COLLECTION									          */
/*============================================================================*/
IF OBJECT_ID('QT_PATIENT_ENC_COLLECTION') IS NULL
CREATE TABLE QT_PATIENT_ENC_COLLECTION (
	PATIENT_ENC_COLL_ID	INT  IDENTITY(1,1) PRIMARY KEY,
	RESULT_INSTANCE_ID	INT,
	SET_INDEX			INT,
	PATIENT_NUM			INT,
	ENCOUNTER_NUM		INT,
	CONSTRAINT QT_FK_PESC_RI FOREIGN KEY (RESULT_INSTANCE_ID)
		REFERENCES QT_QUERY_RESULT_INSTANCE(RESULT_INSTANCE_ID)
)



/*============================================================================*/
/* Table: QT_XML_RESULT												          */
/*============================================================================*/
IF OBJECT_ID('QT_XML_RESULT') IS NULL
CREATE TABLE QT_XML_RESULT (
	XML_RESULT_ID		INT  IDENTITY(1,1) PRIMARY KEY,
	RESULT_INSTANCE_ID	INT,
	XML_VALUE			TEXT,
	CONSTRAINT QT_FK_XMLR_RIID FOREIGN KEY (RESULT_INSTANCE_ID)
		REFERENCES QT_QUERY_RESULT_INSTANCE (RESULT_INSTANCE_ID)
)



/*============================================================================*/
/* Table: QT_ANALYSIS_PLUGIN										          */
/*============================================================================*/
IF OBJECT_ID('QT_ANALYSIS_PLUGIN') IS NULL
CREATE TABLE QT_ANALYSIS_PLUGIN (
	PLUGIN_ID			INT NOT NULL,
	PLUGIN_NAME			VARCHAR(2000),
	DESCRIPTION			VARCHAR(2000),
	VERSION_CD			VARCHAR(50),	--support for version
	PARAMETER_INFO		TEXT,			-- plugin parameter stored as xml
	PARAMETER_INFO_XSD	TEXT,
	COMMAND_LINE		TEXT,
	WORKING_FOLDER		TEXT,
	COMMANDOPTION_CD	TEXT,
	PLUGIN_ICON         TEXT,
	STATUS_CD			VARCHAR(50),	-- active,deleted,..
	USER_ID				VARCHAR(50),
	GROUP_ID			VARCHAR(50),
	CREATE_DATE			DATETIME,
	UPDATE_DATE			DATETIME,
	CONSTRAINT ANALYSIS_PLUGIN_PK PRIMARY KEY(PLUGIN_ID)
)



/*============================================================================*/
/* Table: QT_ANALYSIS_PLUGIN_RESULT_TYPE							          */
/*============================================================================*/
IF OBJECT_ID('QT_ANALYSIS_PLUGIN_RESULT_TYPE') IS NULL
CREATE TABLE QT_ANALYSIS_PLUGIN_RESULT_TYPE (
	PLUGIN_ID		INT,
	RESULT_TYPE_ID	INT,
	CONSTRAINT ANALYSIS_PLUGIN_RESULT_PK PRIMARY KEY(PLUGIN_ID,RESULT_TYPE_ID)
)


/*============================================================================*/
/* Table: QT_PRIVILEGE												          */
/*============================================================================*/
IF OBJECT_ID('QT_PRIVILEGE') IS NULL
CREATE TABLE QT_PRIVILEGE(
	PROTECTION_LABEL_CD		VARCHAR(1500),
	DATAPROT_CD				VARCHAR(1000),
	HIVEMGMT_CD				VARCHAR(1000),
	PLUGIN_ID				INT
)



/*============================================================================*/
/* Table: QT_BREAKDOWN_PATH											          */
/*============================================================================*/
IF OBJECT_ID('QT_BREAKDOWN_PATH') IS NULL
CREATE TABLE QT_BREAKDOWN_PATH (
	NAME			VARCHAR(100), 
	VALUE			VARCHAR(2000), 
	CREATE_DATE		DATETIME,
	UPDATE_DATE		DATETIME,
	USER_ID			VARCHAR(50)
)



/*============================================================================*/
/* Table:QT_PDO_QUERY_MASTER 										          */
/*============================================================================*/
IF OBJECT_ID('QT_PDO_QUERY_MASTER') IS NULL
CREATE TABLE QT_PDO_QUERY_MASTER (
	QUERY_MASTER_ID		INT  IDENTITY(1,1) PRIMARY KEY,
	USER_ID				VARCHAR(50) NOT NULL,
	GROUP_ID			VARCHAR(50) NOT NULL,
	CREATE_DATE			DATETIME NOT NULL,
	REQUEST_XML			TEXT,
	I2B2_REQUEST_XML	TEXT
)


IF OBJECT_ID('QT_IDX_QM_UGID') IS NULL
CREATE INDEX QT_IDX_QM_UGID ON QT_QUERY_MASTER(USER_ID,GROUP_ID,MASTER_TYPE_CD)

IF OBJECT_ID('QT_IDX_QI_UGID') IS NULL
CREATE INDEX QT_IDX_QI_UGID ON QT_QUERY_INSTANCE(USER_ID,GROUP_ID)

IF OBJECT_ID('QT_IDX_QI_MSTARTID') IS NULL
CREATE INDEX QT_IDX_QI_MSTARTID ON QT_QUERY_INSTANCE(QUERY_MASTER_ID,START_DATE)

IF OBJECT_ID('QT_IDX_QPSC_RIID') IS NULL
CREATE INDEX QT_IDX_QPSC_RIID ON QT_PATIENT_SET_COLLECTION(RESULT_INSTANCE_ID)

IF OBJECT_ID('QT_APNAMEVERGRP_IDX') IS NULL
CREATE INDEX QT_APNAMEVERGRP_IDX ON QT_ANALYSIS_PLUGIN(PLUGIN_NAME,VERSION_CD,GROUP_ID)

IF OBJECT_ID('QT_IDX_PQM_UGID') IS NULL
CREATE INDEX QT_IDX_PQM_UGID ON QT_PDO_QUERY_MASTER(USER_ID,GROUP_ID);



--------------------------------------------------------
--INIT WITH SEED DATA
--------------------------------------------------------
delete from QT_QUERY_STATUS_TYPE

insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(1,'QUEUED',' WAITING IN QUEUE TO START PROCESS');
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(2,'PROCESSING','PROCESSING');
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(3,'FINISHED','FINISHED');
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(4,'ERROR','ERROR');
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(5,'INCOMPLETE','INCOMPLETE');
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(6,'COMPLETED','COMPLETED');
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(7,'MEDIUM_QUEUE','MEDIUM QUEUE');
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(8,'LARGE_QUEUE','LARGE QUEUE');
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(9,'CANCELLED','CANCELLED');
insert into QT_QUERY_STATUS_TYPE(STATUS_TYPE_ID,NAME,DESCRIPTION) values(10,'TIMEDOUT','TIMEDOUT');

delete from QT_QUERY_RESULT_TYPE

insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(1,'PATIENTSET','Patient set','LIST','LA');
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(2,'PATIENT_ENCOUNTER_SET','Encounter set','LIST','LA');
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(3,'XML','Generic query result','CATNUM','LH');
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(4,'PATIENT_COUNT_XML','Number of patients','CATNUM','LA');
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(5,'PATIENT_GENDER_COUNT_XML','Gender patient breakdown','CATNUM','LA');
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(6,'PATIENT_VITALSTATUS_COUNT_XML','Vital Status patient breakdown','CATNUM','LA');
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(7,'PATIENT_RACE_COUNT_XML','Race patient breakdown','CATNUM','LA');
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(8,'PATIENT_AGE_COUNT_XML','Age patient breakdown','CATNUM','LA');
insert into QT_QUERY_RESULT_TYPE(RESULT_TYPE_ID,NAME,DESCRIPTION,DISPLAY_TYPE_ID,VISUAL_ATTRIBUTE_TYPE_ID) values(9,'PATIENTSET','Timeline','LIST','LA');

delete from QT_PRIVILEGE

insert into QT_PRIVILEGE(PROTECTION_LABEL_CD,DATAPROT_CD,HIVEMGMT_CD) values ('PDO_WITHOUT_BLOB','DATA_LDS','USER');
insert into QT_PRIVILEGE(PROTECTION_LABEL_CD,DATAPROT_CD,HIVEMGMT_CD) values ('PDO_WITH_BLOB','DATA_DEID','USER');
insert into QT_PRIVILEGE(PROTECTION_LABEL_CD,DATAPROT_CD,HIVEMGMT_CD) values ('SETFINDER_QRY_WITH_DATAOBFSC','DATA_OBFSC','USER');
insert into QT_PRIVILEGE(PROTECTION_LABEL_CD,DATAPROT_CD,HIVEMGMT_CD) values ('SETFINDER_QRY_WITHOUT_DATAOBFSC','DATA_AGG','USER');
insert into QT_PRIVILEGE(PROTECTION_LABEL_CD,DATAPROT_CD,HIVEMGMT_CD) values ('UPLOAD','DATA_OBFSC','MANAGER');
insert into QT_PRIVILEGE(PROTECTION_LABEL_CD,DATAPROT_CD,HIVEMGMT_CD) values ('SETFINDER_QRY_WITH_LGTEXT','DATA_DEID','USER'); 



			select patient_num
			into patientset
			from  _CRCDB_.dbo.QT_PATIENT_SET_COLLECTION 
			 where result_instance_id = {$1} 
             and patient_num not in (select patient_num 
             from _CRCDB_.dbo.QT_PATIENT_SET_COLLECTION 
             where result_instance_id = {$2})
;




	/* patient_dimension */

select * into Patient_Dimension from _CRCDB_.dbo.patient_dimension where patient_num in (select patient_num from patientset)
;


/* add indexes on additional PATIENT_DIMENSION fields */
CREATE  INDEX PD_IDX_DATES ON PATIENT_DIMENSION(PATIENT_NUM, VITAL_STATUS_CD, BIRTH_DATE, DEATH_DATE)
;
CREATE  INDEX PD_IDX_AllPatientDim ON PATIENT_DIMENSION(PATIENT_NUM, VITAL_STATUS_CD, BIRTH_DATE, DEATH_DATE, SEX_CD, AGE_IN_YEARS_NUM, LANGUAGE_CD, RACE_CD, MARITAL_STATUS_CD, INCOME_CD, RELIGION_CD, ZIP_CD)
;
CREATE  INDEX PD_IDX_StateCityZip ON PATIENT_DIMENSION (STATECITYZIP_PATH, PATIENT_NUM)
;
CREATE INDEX PA_IDX_UPLOADID ON PATIENT_DIMENSION(UPLOAD_ID)
;
	
	/* provider_dimension */

select * into provider_Dimension from  _CRCDB_.dbo.provider_dimension
;

/* add index on PROVIDER_ID, NAME_CHAR */
CREATE INDEX PD_IDX_NAME_CHAR ON PROVIDER_DIMENSION(PROVIDER_ID, NAME_CHAR)
;
CREATE INDEX PD_IDX_UPLOADID ON PROVIDER_DIMENSION(UPLOAD_ID)
;


	/* observation_fact */

select * into Observation_Fact from _CRCDB_.dbo.observation_fact where 
patient_num in (select patient_num from patientset)
;


/* add index on concept_cd */
CREATE CLUSTERED INDEX OF_IDX_ClusteredConcept ON OBSERVATION_FACT
(
	CONCEPT_CD 
)
;

/* add an index on most of the observation_fact fields */
CREATE INDEX OF_IDX_ALLObservation_Fact ON OBSERVATION_FACT
(
	PATIENT_NUM ,
	ENCOUNTER_NUM ,
	CONCEPT_CD ,
	START_DATE ,
	PROVIDER_ID ,
	MODIFIER_CD ,
	INSTANCE_NUM,
	VALTYPE_CD ,
	TVAL_CHAR ,
	NVAL_NUM ,
	VALUEFLAG_CD ,
	QUANTITY_NUM ,
	UNITS_CD ,
	END_DATE ,
	LOCATION_CD ,
	CONFIDENCE_NUM
)
;
/* add additional indexes on observation_fact fields */
CREATE INDEX OF_IDX_Start_Date ON OBSERVATION_FACT(START_DATE, PATIENT_NUM)
;
CREATE INDEX OF_IDX_Modifier ON OBSERVATION_FACT(MODIFIER_CD)
;
CREATE INDEX OF_IDX_Encounter_Patient ON OBSERVATION_FACT(ENCOUNTER_NUM, PATIENT_NUM, INSTANCE_NUM)
;
CREATE INDEX OF_IDX_UPLOADID ON OBSERVATION_FACT(UPLOAD_ID)
;
CREATE INDEX OF_IDX_SOURCESYSTEM_CD ON OBSERVATION_FACT(SOURCESYSTEM_CD)
;
CREATE UNIQUE INDEX OF_TEXT_SEARCH_UNIQUE ON OBSERVATION_FACT(TEXT_SEARCH_INDEX)
;
EXEC SP_FULLTEXT_DATABASE 'ENABLE'
;
CREATE FULLTEXT CATALOG FTCATALOG AS DEFAULT
;
CREATE FULLTEXT INDEX ON OBSERVATION_FACT(OBSERVATION_BLOB)
 KEY INDEX OF_TEXT_SEARCH_UNIQUE 
;



	/* visit_dimension */

select * into Visit_Dimension from _CRCDB_.dbo.visit_dimension where patient_num in (select patient_num from patientset) 
        and encounter_num in (select distinct(encounter_num) from observation_fact) 
;

/* add indexes on addtional visit_dimension fields */
CREATE  INDEX VD_IDX_DATES ON VISIT_DIMENSION(ENCOUNTER_NUM, START_DATE, END_DATE)
;
CREATE  INDEX VD_IDX_AllVisitDim ON VISIT_DIMENSION(ENCOUNTER_NUM, PATIENT_NUM, INOUT_CD, LOCATION_CD, START_DATE, LENGTH_OF_STAY, END_DATE)
;
CREATE  INDEX VD_IDX_UPLOADID ON VISIT_DIMENSION(UPLOAD_ID)
;

	/* concept_dimension */

select * into Concept_Dimension from _CRCDB_.dbo.concept_dimension
;

CREATE INDEX CD_IDX_UPLOADID ON CONCEPT_DIMENSION(UPLOAD_ID)
;


select * into MODIFIER_DIMENSION from _CRCDB_.dbo.MODIFIER_DIMENSION
;

CREATE INDEX MD_IDX_UPLOADID ON MODIFIER_DIMENSION(UPLOAD_ID)
;


CREATE TABLE ENCOUNTER_MAPPING ( 
    ENCOUNTER_IDE       	VARCHAR(200)  NOT NULL,
    ENCOUNTER_IDE_SOURCE	VARCHAR(50)  NOT NULL,
    PROJECT_ID              VARCHAR(50) NOT NULL,
    ENCOUNTER_NUM			INT NOT NULL,
    PATIENT_IDE         	VARCHAR(200) NOT NULL,
    PATIENT_IDE_SOURCE  	VARCHAR(50) NOT NULL,
    ENCOUNTER_IDE_STATUS	VARCHAR(50) NULL,
    UPLOAD_DATE         	DATETIME NULL,
    UPDATE_DATE             DATETIME NULL,
    DOWNLOAD_DATE       	DATETIME NULL,
    IMPORT_DATE             DATETIME NULL,
    SOURCESYSTEM_CD         VARCHAR(50) NULL,
    UPLOAD_ID               INT NULL,
    CONSTRAINT ENCOUNTER_MAPPING_PK PRIMARY KEY(ENCOUNTER_IDE, ENCOUNTER_IDE_SOURCE, PROJECT_ID, PATIENT_IDE, PATIENT_IDE_SOURCE)
 )
;
CREATE  INDEX EM_IDX_ENCPATH ON ENCOUNTER_MAPPING(ENCOUNTER_IDE, ENCOUNTER_IDE_SOURCE, PATIENT_IDE, PATIENT_IDE_SOURCE, ENCOUNTER_NUM)
;
CREATE  INDEX EM_IDX_UPLOADID ON ENCOUNTER_MAPPING(UPLOAD_ID)
;
CREATE INDEX EM_ENCNUM_IDX ON ENCOUNTER_MAPPING(ENCOUNTER_NUM)
;


-------------------------------------------------------------------------------------
-- create PATIENT_MAPPING table with clustered PK on PATIENT_IDE, PATIENT_IDE_SOURCE
-------------------------------------------------------------------------------------

CREATE TABLE PATIENT_MAPPING ( 
    PATIENT_IDE         VARCHAR(200)  NOT NULL,
    PATIENT_IDE_SOURCE	VARCHAR(50)  NOT NULL,
    PATIENT_NUM       	INT NOT NULL,
    PATIENT_IDE_STATUS	VARCHAR(50) NULL,
    PROJECT_ID          VARCHAR(50) NOT NULL,
    UPLOAD_DATE       	DATETIME NULL,
    UPDATE_DATE       	DATETIME NULL,
    DOWNLOAD_DATE     	DATETIME NULL,
    IMPORT_DATE         DATETIME NULL,
    SOURCESYSTEM_CD   	VARCHAR(50) NULL,
    UPLOAD_ID         	INT NULL,
    CONSTRAINT PATIENT_MAPPING_PK PRIMARY KEY(PATIENT_IDE, PATIENT_IDE_SOURCE, PROJECT_ID)
 )
;
CREATE  INDEX PM_IDX_UPLOADID ON PATIENT_MAPPING(UPLOAD_ID)
;
CREATE INDEX PM_PATNUM_IDX ON PATIENT_MAPPING(PATIENT_NUM)
;
CREATE INDEX PM_ENCPNUM_IDX ON 
PATIENT_MAPPING(PATIENT_IDE,PATIENT_IDE_SOURCE,PATIENT_NUM) ;



	/*********************************************************/
	--  Populate the mapping tables with self-mapping data.
	/**********************************************************/


insert into encounter_mapping select * from _CRCDB_.encounter_mapping where encounter_num in (select distinct encounter_num from visit_dimension);
   

insert into Patient_mapping select * from _CRCDB_.patient_mapping where patient_num in (select distinct patient_num from patientset);




/*********************************************************/
--
--                              RUN ON WORKPLACE DATABASE
--
/*********************************************************/



CREATE TABLE WORKPLACE ( 
	C_NAME					VARCHAR(255) NOT NULL,
	C_USER_ID				VARCHAR(255) NOT NULL,
	C_GROUP_ID				VARCHAR(255) NOT NULL,
	C_SHARE_ID				VARCHAR(255) NULL,
	C_INDEX  				VARCHAR(255) NOT NULL,
	C_PARENT_INDEX  		VARCHAR(255) NULL,
	C_VISUALATTRIBUTES		CHAR(3) NOT NULL,
	C_PROTECTED_ACCESS		CHAR(1) NULL,
	C_TOOLTIP      			VARCHAR(255) NULL,
	C_WORK_XML      		TEXT NULL,
	C_WORK_XML_SCHEMA      	TEXT NULL,
	C_WORK_XML_I2B2_TYPE	VARCHAR(255) NULL,
	C_ENTRY_DATE   			DATETIME NULL,
	C_CHANGE_DATE  			DATETIME NULL,
	C_STATUS_CD    			CHAR(1) NULL,
 CONSTRAINT WORKPLACE_PK PRIMARY KEY(C_INDEX)  
	);


CREATE TABLE WORKPLACE_ACCESS ( 
	C_TABLE_CD			VARCHAR(255) NOT NULL,
	C_TABLE_NAME		VARCHAR(255) NOT NULL,
	C_PROTECTED_ACCESS	CHAR(1) NULL,
	C_HLEVEL			INT NOT NULL,
	C_NAME				VARCHAR(255) NOT NULL,
	C_USER_ID			VARCHAR(255) NOT NULL,
	C_GROUP_ID			VARCHAR(255) NOT NULL,
	C_SHARE_ID			VARCHAR(255) NULL,
	C_INDEX				VARCHAR(255) NOT NULL,
	C_PARENT_INDEX  	VARCHAR(255) NULL,
	C_VISUALATTRIBUTES	CHAR(3) NOT NULL,
	C_TOOLTIP			VARCHAR(255) NULL,
	C_ENTRY_DATE		DATETIME NULL,
	C_CHANGE_DATE		DATETIME NULL,
	C_STATUS_CD			CHAR(1) NULL,
 CONSTRAINT WORKPLACE_ACCESS_PK PRIMARY KEY(C_INDEX) 
	);
	

	
	





/*********************************************************/
--
--				RUN ON ONTOLOGY DATABASE
--
/*********************************************************/


CREATE TABLE ONT_PROCESS_STATUS (
    PROCESS_ID			INT IDENTITY(1,1) PRIMARY KEY, 
    PROCESS_TYPE_CD		VARCHAR(50),
    START_DATE			DATETIME, 
    END_DATE			DATETIME,
    PROCESS_STEP_CD		VARCHAR(50),
    PROCESS_STATUS_CD   VARCHAR(50),
    CRC_UPLOAD_ID		INT,
    STATUS_CD			VARCHAR(50),
    MESSAGE				TEXT,
    ENTRY_DATE			DATETIME,
    CHANGE_DATE			DATETIME,
    CHANGEDBY_CHAR		CHAR(50)
);



	/******************************************************************/
	-- Populate the Star Schema tables
	/******************************************************************/

 select * into SCHEMES from _ONTDB_.dbo.SCHEMES
;
 select * into PCORNET_DEMO from _ONTDB_.dbo.PCORNET_DEMO
;
 select * into PCORNET_DIAG from _ONTDB_.dbo.PCORNET_DIAG
;
 select * into PCORNET_ENC from _ONTDB_.dbo.PCORNET_ENC
;
 select * into PCORNET_PROC from _ONTDB_.dbo.PCORNET_PROC
;
 select * into PCORNET_VITAL from _ONTDB_.dbo.PCORNET_VITAL
;
 select * into PCORNET_ENROLL from _ONTDB_.dbo.PCORNET_ENROLL
;
 select *  into table_access from _ONTDB_.dbo.table_access
;






DECLARE @sql nvarchar(max);

DECLARE c CURSOR FOR 
   SELECT Definition
   FROM [_CRCDB_].[sys].[procedures] p
   INNER JOIN [_CRCDB_].sys.sql_modules m ON p.object_id = m.object_id

OPEN c

FETCH NEXT FROM c INTO @sql

WHILE @@FETCH_STATUS = 0 
BEGIN
   SET @sql = REPLACE(@sql,'''','''''')
   SET @sql = 'EXEC(''' + @sql + ''')'

   EXEC(@sql)

   FETCH NEXT FROM c INTO @sql
END             

CLOSE c
DEALLOCATE c

END
