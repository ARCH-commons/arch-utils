-- Janice's Test Script - Version 1.0
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON

	-- Sql variables
	DECLARE @ExecSql			NVARCHAR(max)

	-- variables
	DECLARE @PatientListID		int
	DECLARE @ExcludeListID		int
	DECLARE @CRCDBname			VARCHAR (100)
	DECLARE @OntologyDBname		VARCHAR (100)
	
	-- Internal 
	DECLARE @ReturnValue		INT	
	DECLARE @GetTime			DATETIME
	DECLARE @PatientListTable	VARCHAR(100)
	DECLARE @DbOwner     	 	VARCHAR (20)
	DECLARE @pathcounter		INT
	DECLARE @pathname			VARCHAR(450)
    DECLARE @tabname            varchar(100)

	-- Initialize Variables
	SET @PatientListID = 27
	SET @ExcludeListID = null
	SET @CRCDBname = 'i2b2demodata'
	SET @OntologyDBname = 'i2b2metadata'


	SET @DbOwner	 = N'.dbo.'
	SET @Debug = 1

	SET @PatientListTable = 'QT_PATIENT_SET_COLLECTION'

-- BEGIN PROCESSING

----------------------------------------------------------------------------------
-- 	Table group:		Mapping tables
--	Table members:		patient_mapping, encounter_mapping
----------------------------------------------------------------------------------

	/****** Object:  Table [dbo].[patient_mapping] ******/
	 
	IF OBJECT_ID('Patient_Mapping') IS NOT NULL
		DROP TABLE Patient_mapping	

	CREATE TABLE  PATIENT_MAPPING (
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

	
	/****** Object:  Table [dbo].[encounter_mapping] ******/

	IF OBJECT_ID('Encounter_Mapping') IS NOT NULL
		DROP TABLE Encounter_mapping	

	CREATE TABLE   ENCOUNTER_MAPPING (
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

	

----------------------------------------------------------------------------------
-- 	Table group:		Metadata tables
--	Table members:		i2b2MetaData, TABLE_ACCESS, SCHEMES, CODE_LOOKUP				
----------------------------------------------------------------------------------
/*
	IF  OBJECT_ID('i2b2metadata') IS NOT NULL
		DROP TABLE i2b2metadata
	
  CREATE TABLE I2B2METADATA 
   (	C_HLEVEL INT			NOT NULL, 
	C_FULLNAME VARCHAR(700)	NOT NULL, 
	C_NAME VARCHAR(2000)		NOT NULL, 
	C_SYNONYM_CD CHAR(1)		NOT NULL, 
	C_VISUALATTRIBUTES CHAR(3)	NOT NULL, 
	C_TOTALNUM INT			NULL, 
	C_BASECODE VARCHAR(50)	NULL, 
	C_METADATAXML TEXT		NULL, 
	C_FACTTABLECOLUMN VARCHAR(50)	NOT NULL, 
	C_TABLENAME VARCHAR(50)	NOT NULL, 
	C_COLUMNNAME VARCHAR(50)	NOT NULL, 
	C_COLUMNDATATYPE VARCHAR(50)	NOT NULL, 
	C_OPERATOR VARCHAR(10)	NOT NULL, 
	C_DIMCODE VARCHAR(700)	NOT NULL, 
	C_COMMENT TEXT			NULL, 
	C_TOOLTIP VARCHAR(900)	NULL,
	M_APPLIED_PATH VARCHAR(700)	NOT NULL, 
	UPDATE_DATE DATETIME		NOT NULL, 
	DOWNLOAD_DATE DATETIME	NULL, 
	IMPORT_DATE DATETIME	NULL, 
	SOURCESYSTEM_CD VARCHAR(50)	NULL, 
	VALUETYPE_CD VARCHAR(50)	NULL,
	M_EXCLUSION_CD	VARCHAR(25) NULL,
	C_PATH	VARCHAR(700)   NULL,
	C_SYMBOL	VARCHAR(50)	NULL
   ) 
   
   CREATE INDEX META_FULLNAME_IDX ON I2B2METADATA(C_FULLNAME)


   CREATE INDEX META_APPLIED_PATH_IDX ON I2B2METADATA(M_APPLIED_PATH)

   CREATE INDEX META_EXCLUSION_IDX ON I2B2METADATA(M_EXCLUSION_CD)

   CREATE INDEX META_HLEVEL_IDX ON I2B2METADATA(C_HLEVEL)

   CREATE INDEX META_SYNONYM_IDX ON I2B2METADATA(C_SYNONYM_CD)
*/

	/****** Object:  Table [dbo].[CODE_LOOKUP] ******/
	 
	IF  OBJECT_ID('code_lookup') IS NOT NULL
		DROP TABLE code_lookup

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


	/****** Object:  Table [dbo].[SCHEMES]  ******/
	 IF  OBJECT_ID('schemes') IS NOT NULL
		DROP TABLE schemes
	
		  CREATE TABLE SCHEMES 
   (	C_KEY VARCHAR(50)	 	NOT NULL,
	C_NAME VARCHAR(50)		NOT NULL,
	C_DESCRIPTION VARCHAR(100)	NULL,
	 CONSTRAINT SCHEMES_PK PRIMARY KEY(C_KEY)
   )

	/****** Object:  Table [dbo].[TABLE_ACCESS] ******/

	IF  OBJECT_ID('table_access') IS NOT NULL
		DROP TABLE table_access
	
  CREATE TABLE TABLE_ACCESS
   (	C_TABLE_CD VARCHAR(50)	NOT NULL, 
	C_TABLE_NAME VARCHAR(50)	NOT NULL, 
	C_PROTECTED_ACCESS CHAR(1)	NULL,
	C_HLEVEL INT				NOT NULL, 
	C_FULLNAME VARCHAR(700)	NOT NULL, 
	C_NAME VARCHAR(2000)		NOT NULL, 
	C_SYNONYM_CD CHAR(1)	NOT NULL, 
	C_VISUALATTRIBUTES CHAR(3)	NOT NULL, 
	C_TOTALNUM INT			NULL, 
	C_BASECODE VARCHAR(50)	NULL, 
	C_METADATAXML TEXT		NULL, 
	C_FACTTABLECOLUMN VARCHAR(50)	NOT NULL, 
	C_DIMTABLENAME VARCHAR(50)	NOT NULL, 
	C_COLUMNNAME VARCHAR(50)	NOT NULL, 
	C_COLUMNDATATYPE VARCHAR(50)	NOT NULL, 
	C_OPERATOR VARCHAR(10)	NOT NULL, 
	C_DIMCODE VARCHAR(700)	NOT NULL, 
	C_COMMENT TEXT	NULL, 
	C_TOOLTIP VARCHAR(900)	NULL, 
	C_ENTRY_DATE DATETIME		NULL, 
	C_CHANGE_DATE DATETIME	NULL, 
	C_STATUS_CD CHAR(1)		NULL,
	VALUETYPE_CD VARCHAR(50)	NULL,
   )

----------------------------------------------------------------------------------
-- 	Table group:		Dimension tables
--	Table members:		Observation_Fact, Visit_Dimension, Provider_Dimension, Patient_Dimension, 
--						Concept_Dimension 
----------------------------------------------------------------------------------

IF OBJECT_ID('Concept_dimension') IS NOT NULL
		DROP TABLE concept_dimension

CREATE TABLE CONCEPT_DIMENSION ( 
	CONCEPT_PATH   		VARCHAR(700) NOT NULL,
	CONCEPT_CD     		VARCHAR(50) NULL,
	NAME_CHAR      		VARCHAR(2000) NULL,
	CONCEPT_BLOB   		TEXT NULL,
	UPDATE_DATE    		DATETIME NULL,
	DOWNLOAD_DATE  		DATETIME NULL,
	IMPORT_DATE    		DATETIME NULL,
	SOURCESYSTEM_CD		VARCHAR(50) NULL,
    UPLOAD_ID			INT NULL,
    CONSTRAINT CONCEPT_DIMENSION_PK PRIMARY KEY(CONCEPT_PATH)
	)

CREATE INDEX CD_IDX_UPLOADID ON CONCEPT_DIMENSION(UPLOAD_ID)


/* create observation_fact table with NONclustered PK on encounter_num,concept_cd,provider_id,start_date,modifier_cd  */

IF OBJECT_ID('observation_fact') IS NOT NULL
		DROP TABLE observation_fact

CREATE TABLE OBSERVATION_FACT ( 
	ENCOUNTER_NUM  		INT NOT NULL,
	PATIENT_NUM    		INT NOT NULL,
	CONCEPT_CD     		VARCHAR(50) NOT NULL,
	PROVIDER_ID    		VARCHAR(50) NOT NULL,
	START_DATE     		DATETIME NOT NULL,
	MODIFIER_CD    		VARCHAR(100) default '@' NOT NULL,
	INSTANCE_NUM		INT default (1) NOT NULL,
	VALTYPE_CD     		VARCHAR(50) NULL,
	TVAL_CHAR      		VARCHAR(255) NULL,
	NVAL_NUM       		DECIMAL(18,5) NULL,
	VALUEFLAG_CD   		VARCHAR(50) NULL,
	QUANTITY_NUM   		DECIMAL(18,5) NULL,
	UNITS_CD       		VARCHAR(50) NULL,
	END_DATE       		DATETIME NULL,
	LOCATION_CD    		VARCHAR(50) NULL,
	OBSERVATION_BLOB	TEXT NULL,
	CONFIDENCE_NUM 		DECIMAL(18,5) NULL,
	UPDATE_DATE    		DATETIME NULL,
	DOWNLOAD_DATE  		DATETIME NULL,
	IMPORT_DATE    		DATETIME NULL,
	SOURCESYSTEM_CD		VARCHAR(50) NULL, 
    UPLOAD_ID         	INT NULL,
    TEXT_SEARCH_INDEX   INT IDENTITY(1,1),
    CONSTRAINT OBSERVATION_FACT_PK PRIMARY KEY nonclustered (PATIENT_NUM, CONCEPT_CD,  MODIFIER_CD, START_DATE, ENCOUNTER_NUM, INSTANCE_NUM, PROVIDER_ID)
	)
;

/* add index on concept_cd */
CREATE CLUSTERED INDEX OF_IDX_ClusteredConcept ON OBSERVATION_FACT
(
	CONCEPT_CD 
)


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

/* add additional indexes on observation_fact fields */
CREATE INDEX OF_IDX_Start_Date ON OBSERVATION_FACT(START_DATE, PATIENT_NUM)

CREATE INDEX OF_IDX_Modifier ON OBSERVATION_FACT(MODIFIER_CD)

CREATE INDEX OF_IDX_Encounter_Patient ON OBSERVATION_FACT(ENCOUNTER_NUM, PATIENT_NUM, INSTANCE_NUM)

CREATE INDEX OF_IDX_UPLOADID ON OBSERVATION_FACT(UPLOAD_ID)

CREATE INDEX OF_IDX_SOURCESYSTEM_CD ON OBSERVATION_FACT(SOURCESYSTEM_CD)

CREATE UNIQUE INDEX OF_TEXT_SEARCH_UNIQUE ON OBSERVATION_FACT(TEXT_SEARCH_INDEX)

/*EXEC SP_FULLTEXT_DATABASE 'ENABLE' 

IF OBJECT_ID('FULLTEXT') IS NOT NULL
CREATE FULLTEXT CATALOG FTCATALOG AS DEFAULT

CREATE FULLTEXT INDEX ON OBSERVATION_FACT(OBSERVATION_BLOB)
 KEY INDEX OF_TEXT_SEARCH_UNIQUE */



/* create Patient_Dimension table with clustered PK on patient_num */
IF OBJECT_ID('patient_dimension') IS NOT NULL
		DROP TABLE patient_dimension


CREATE TABLE PATIENT_DIMENSION ( 
	PATIENT_NUM      	INT NOT NULL,
	VITAL_STATUS_CD  	VARCHAR(50) NULL,
	BIRTH_DATE       	DATETIME NULL,
	DEATH_DATE       	DATETIME NULL,
	SEX_CD           	VARCHAR(50) NULL,
	AGE_IN_YEARS_NUM	INT NULL,
	LANGUAGE_CD      	VARCHAR(50) NULL,
	RACE_CD          	VARCHAR(50) NULL,
	MARITAL_STATUS_CD	VARCHAR(50) NULL,
	RELIGION_CD      	VARCHAR(50) NULL,
	ZIP_CD           	VARCHAR(10) NULL,
	STATECITYZIP_PATH	VARCHAR(700) NULL,
	INCOME_CD			VARCHAR(50) NULL,
	PATIENT_BLOB     	TEXT NULL,
	UPDATE_DATE      	DATETIME NULL,
	DOWNLOAD_DATE    	DATETIME NULL,
	IMPORT_DATE      	DATETIME NULL,
	SOURCESYSTEM_CD  	VARCHAR(50) NULL,
    UPLOAD_ID         	INT NULL, 
    CONSTRAINT PATIENT_DIMENSION_PK PRIMARY KEY(PATIENT_NUM)
	)


/* add indexes on additional PATIENT_DIMENSION fields */
CREATE  INDEX PD_IDX_DATES ON PATIENT_DIMENSION(PATIENT_NUM, VITAL_STATUS_CD, BIRTH_DATE, DEATH_DATE)

CREATE  INDEX PD_IDX_AllPatientDim ON PATIENT_DIMENSION(PATIENT_NUM, VITAL_STATUS_CD, BIRTH_DATE, DEATH_DATE, SEX_CD, AGE_IN_YEARS_NUM, LANGUAGE_CD, RACE_CD, MARITAL_STATUS_CD, INCOME_CD, RELIGION_CD, ZIP_CD)

CREATE  INDEX PD_IDX_StateCityZip ON PATIENT_DIMENSION (STATECITYZIP_PATH, PATIENT_NUM)

CREATE INDEX PA_IDX_UPLOADID ON PATIENT_DIMENSION(UPLOAD_ID)


/* create Provider_Dimension table with clustered PK on provider_path, provider_id */
IF OBJECT_ID('Provider_dimension') IS NOT NULL
		DROP TABLE provider_dimension

CREATE TABLE PROVIDER_DIMENSION ( 
	PROVIDER_ID    		VARCHAR(50) NOT NULL,
	PROVIDER_PATH  		VARCHAR(700) NOT NULL,
	NAME_CHAR      		VARCHAR(850) NULL,
	PROVIDER_BLOB  		TEXT NULL,
	UPDATE_DATE    		DATETIME NULL,
	DOWNLOAD_DATE  		DATETIME NULL,
	IMPORT_DATE    		DATETIME NULL,
	SOURCESYSTEM_CD		VARCHAR(50) NULL ,
    UPLOAD_ID         	INT NULL,
    CONSTRAINT PROVIDER_DIMENSION_PK PRIMARY KEY(PROVIDER_PATH, PROVIDER_ID)
	)


/* add index on PROVIDER_ID, NAME_CHAR */
CREATE INDEX PD_IDX_NAME_CHAR ON PROVIDER_DIMENSION(PROVIDER_ID, NAME_CHAR)

CREATE INDEX PD_IDX_UPLOADID ON PROVIDER_DIMENSION(UPLOAD_ID)


/* create Visit_Dimension table with clustered PK on encounter_num */
IF OBJECT_ID('visit_dimension') IS NOT NULL
		DROP TABLE visit_dimension

CREATE TABLE VISIT_DIMENSION ( 
	ENCOUNTER_NUM  		INT NOT NULL,
	PATIENT_NUM    		INT NOT NULL,
	ACTIVE_STATUS_CD	VARCHAR(50) NULL,
	START_DATE     		DATETIME NULL,
	END_DATE       		DATETIME NULL,
	INOUT_CD       		VARCHAR(50) NULL,
	LOCATION_CD    		VARCHAR(50) NULL,
    LOCATION_PATH  		VARCHAR(900) NULL,
	LENGTH_OF_STAY		INT NULL,
	VISIT_BLOB     		TEXT NULL,
	UPDATE_DATE    		DATETIME NULL,
	DOWNLOAD_DATE  		DATETIME NULL,
	IMPORT_DATE    		DATETIME NULL,
	SOURCESYSTEM_CD		VARCHAR(50) NULL ,
    UPLOAD_ID         	INT NULL, 
    CONSTRAINT VISIT_DIMENSION_PK PRIMARY KEY(ENCOUNTER_NUM, PATIENT_NUM)
	)


/* add indexes on addtional visit_dimension fields */
CREATE  INDEX VD_IDX_DATES ON VISIT_DIMENSION(ENCOUNTER_NUM, START_DATE, END_DATE)

CREATE  INDEX VD_IDX_AllVisitDim ON VISIT_DIMENSION(ENCOUNTER_NUM, PATIENT_NUM, INOUT_CD, LOCATION_CD, START_DATE, LENGTH_OF_STAY, END_DATE)

CREATE  INDEX VD_IDX_UPLOADID ON VISIT_DIMENSION(UPLOAD_ID)



/* create Modifier_Dimension table with clustered PK on encounter_num */
IF OBJECT_ID('modifier_dimension') IS NOT NULL
		DROP TABLE modifier_dimension


CREATE TABLE MODIFIER_DIMENSION ( 
	MODIFIER_PATH   	VARCHAR(700) NOT NULL,
	MODIFIER_CD     	VARCHAR(50) NULL,
	NAME_CHAR      		VARCHAR(2000) NULL,
	MODIFIER_BLOB   	TEXT NULL,
	UPDATE_DATE    		DATETIME NULL,
	DOWNLOAD_DATE  		DATETIME NULL,
	IMPORT_DATE    		DATETIME NULL,
	SOURCESYSTEM_CD		VARCHAR(50) NULL,
    UPLOAD_ID			INT NULL,
    CONSTRAINT MODIFIER_DIMENSION_PK PRIMARY KEY(modifier_path)
	)

CREATE INDEX MD_IDX_UPLOADID ON MODIFIER_DIMENSION(UPLOAD_ID)

	/*********************************************************
	*  Create all the QT Tables
	**********************************************************/

/*==============================================================*/
/* Sqlserver Database Script to create CRC query tables         */
/*==============================================================*/


/*============================================================================*/
/* Table: QT_QUERY_MASTER 											          */
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
/* Table: QT_QUERY_RESULT_TYPE										          */
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
/* Table: QT_QUERY_STATUS_TYPE										          */
/*============================================================================*/
IF OBJECT_ID('QT_QUERY_STATUS_TYPE') IS NULL
CREATE TABLE QT_QUERY_STATUS_TYPE (
	STATUS_TYPE_ID	INT   PRIMARY KEY,
	NAME			VARCHAR(100),
	DESCRIPTION		VARCHAR(200)
)



/*============================================================================*/
/* Table: QT_QUERY_INSTANCE 										          */
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
/* Table: QT_QUERY_RESULT_INSTANCE   								          */
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
/* Table: QT_PATIENT_SET_COLLECTION									          */
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

/*
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
*/


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






	/*********************************************************
	*  Populate the tables.
	**********************************************************/

	-- Temporarily turn off constraints while populating tables
	EXEC sp_msforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"
	
	SET @GetTime = getdate()
	-- Initialize Variables
	SET @Debug = 1


	/*********************************************************
	*  Populate TABLE_ACCESS with one row for every metadata table.
    *  This tells the workbench which tables to use for metadata.
	*********************************************************
	
		INSERT INTO TABLE_ACCESS (
		C_TABLE_CD, C_TABLE_NAME, C_HLEVEL, C_FULLNAME, C_NAME, 
		C_SYNONYM_CD, C_VISUALATTRIBUTES, C_TOTALNUM, C_BASECODE, C_METADATAXML, 
		C_FACTTABLECOLUMN, C_DIMTABLENAME, C_COLUMNNAME, C_COLUMNDATATYPE, C_OPERATOR, 
		C_DIMCODE, C_COMMENT, C_TOOLTIP, C_ENTRY_DATE, C_CHANGE_DATE, 
		C_STATUS_CD, C_PROTECTED_ACCESS)
		VALUES('i2b2MetaData', 'i2b2MetaData',  0, '\i2b2MetaData\', 'i2b2metadata', 
		'N', 'CA', NULL, NULL, NULL, 
		'concept_cd', 'concept_dimension', 'concept_path', 'T', 'LIKE', 
		'\i2b2MetaData\', NULL, NULL, NULL, NULL, 
		NULL,  'N')
*/

	/*********************************************************
	*  Populate the SCHEMES table with prefixes used for metadata.
	**********************************************************/

	INSERT INTO SCHEMES(C_KEY, C_NAME, C_DESCRIPTION)
	VALUES('ICD9:', 'ICD9', 'ICD9 code for diagnoses and procedures')
	
	INSERT INTO SCHEMES(C_KEY, C_NAME, C_DESCRIPTION)
	VALUES ('LOINC:', 'LOINC', 'Lab codes')
	
	INSERT INTO SCHEMES(C_KEY, C_NAME, C_DESCRIPTION)
	VALUES ('NDC:', 'NDC', 'National Drug Codes')
	

	/*****************************************************************
	* Create the set of patients to use based on the include and exclude
    * patient lists in QT_Patient_set_collection
	******************************************************************/

	IF OBJECT_ID('patientset') IS NOT NULL
		DROP TABLE patientset

	CREATE TABLE patientset (
		patient_num INT
	)


	SET @ExecSQL = 'insert into patientset (' + 
				'patient_num' + 
			') ' + 
			'select patient_num ' + 
			'from ' +@CRCDBname + @DBowner + @PatientListTable + ' ' + 
			'where result_instance_id = ''' + cast(@patientlistid  as varchar(10))+ ''''+
            'and patient_num not in (select patient_num '+
            'from '+@CRCDBname + @DBowner + @PatientListTable + ' ' + 
            'where result_instance_id = ''' + cast(@excludelistid  as varchar(10))+ ''')'


	BEGIN TRY
		EXEC sp_executesql @ExecSQL

		IF (@Debug = 1)
		BEGIN
			PRINT 'Finished creation of patientset: ' + cast(cast(datediff(ms, @gettime, getdate()) as decimal(18, 2))/1000 as varchar(100)) + ' seconds'
			SET @gettime = getdate()
		END
	END TRY
	BEGIN CATCH 
		SELECT @ErrorMessage = 'ERROR Creating PatientSet Line ' + cast(ERROR_LINE() as varchar(50)) + 
			': ' + ERROR_MESSAGE() 
		RETURN 0
	END CATCH


	/*****************************************************************
	* Populate the Star Schema tables
	******************************************************************/


	SET @ExecSQL = 'insert into table_access select * ' + 
			'from ' +@CRCDBname + @DBowner +  'table_access '


	BEGIN TRY
		EXEC sp_executesql @ExecSQL

		IF (@Debug = 1)
		BEGIN
			PRINT 'Finished creation of table_access: ' + cast(cast(datediff(ms, @gettime, getdate()) as decimal(18, 2))/1000 as varchar(100)) + ' seconds'
			SET @gettime = getdate()
		END
	END TRY
	BEGIN CATCH 
		SELECT @ErrorMessage = 'ERROR Creating table_access Line ' + cast(ERROR_LINE() as varchar(50)) + 
			': ' + ERROR_MESSAGE() 
		RETURN 0
	END CATCH

    Declare c CURSOR
            Local Fast_Forward
            For
                    select c_table_name from table_access
    Open c
            fetch next from c into @tabname
    WHILE @@FETCH_STATUS = 0
    Begin

            IF OBJECT_ID(@tabname) IS NOT NULL begin
                    set @ExecSQL='drop  table '+ @OntologyDBname + @DBowner + @tabname
                    execute sp_executesql @ExecSQL
             end
                    set @ExecSQL='select * into '+ @OntologyDBname + @DBowner +@tabname+' from ' + @OntologyDBname + @DBowner  + @tabname
                   --print @sqlstr
                execute sp_executesql @ExecSQL
                  fetch next from c into @tabname
    End
    close c
    deallocate c


	/*****************************************************************
	* Populate the Star Schema tables
	******************************************************************/

	/* patient_dimension */

	SET @execsql = 'insert into Patient_Dimension select * from ' + 
		@CRCDBname + @DBowner  + 
		'patient_dimension where patient_num in (select patient_num from patientset)'

	BEGIN TRY
	EXEC sp_executesql @ExecSQL

		IF (@Debug = 1)
		BEGIN
			PRINT 'Finished creation of patient_dimension: ' + cast(cast(datediff(ms, @gettime, getdate()) as decimal(18, 2))/1000 as varchar(100)) + ' seconds'
			SET @gettime = getdate()
		END
	END TRY
	BEGIN CATCH 
		SELECT @ErrorMessage = 'ERROR Creating patient_dimension Line ' + cast(ERROR_LINE() as varchar(50)) + 
			': ' + ERROR_MESSAGE() 
		RETURN 0
	END CATCH

	/* i2b2metadata */

	IF OBJECT_ID('getPaths') IS NOT NULL
		DROP TABLE getPaths

	CREATE TABLE getPaths (
		path_num int identity(1,1),
		pathname varchar(450)
	)
/*
    insert into getpaths
	select directive_value from processing_directives where processingflag = 'metadata_path'

	select  @pathcounter=max(path_num) from getpaths

	while @pathcounter > 0
	begin
	
		select @pathname = pathname from getpaths where path_num=@pathcounter
	
		SET @execsql = 'insert into i2b2metadata select * from ' + 
		@CRCDBname + @DBowner + 'i2b2metadata where c_fullname like '''+@pathname+ '%'''

		BEGIN TRY
			EXEC sp_executesql @ExecSQL

			IF (@Debug = 1)
			BEGIN
				PRINT 'Finished creation of i2b2metadata : ' + cast(cast(datediff(ms, @gettime, getdate()) as decimal(18, 2))/1000 as varchar(100)) + ' seconds'
				SET @gettime = getdate()
			END
		END TRY
		BEGIN CATCH 
			SELECT @ErrorMessage = 'ERROR Creating i2b2metadata  Line ' + cast(ERROR_LINE() as varchar(50)) + 
			': ' + ERROR_MESSAGE() 
			RETURN 0
		END CATCH

	set @pathcounter=@pathcounter-1
	end
*/
    /* c_fullname and c_dimcode should end with a backslash.
     if they do not, add it here */
/*
    update i2b2metadata set c_fullname = c_fullname + '\'
    where c_fullname not like '%\'

	update i2b2metadata set c_dimcode = c_dimcode + '\'
    where c_dimcode not like '%\'
*/
	/* provider_dimension */

	SET @execsql = 'insert into provider_Dimension select * from  ' + 
		@CRCDBname + @DBowner  + 'provider_dimension'

	BEGIN TRY
		EXEC sp_executesql @ExecSQL

		IF (@Debug = 1)
		BEGIN
			PRINT 'Finished creation of provider_dimension: ' + cast(cast(datediff(ms, @gettime, getdate()) as decimal(18, 2))/1000 as varchar(100)) + ' seconds'
			SET @gettime = getdate()
		END
	END TRY
	BEGIN CATCH 
		SELECT @ErrorMessage = 'ERROR Creating provider_dimension Line ' + cast(ERROR_LINE() as varchar(50)) + 
			': ' + ERROR_MESSAGE() 
		RETURN 0
	END CATCH

	/* observation_fact */

	SET @execsql = 'insert into Observation_Fact (Encounter_Num,Patient_Num,Concept_Cd,Provider_Id,Start_Date,
                Modifier_Cd,instance_num,ValType_Cd ,TVal_Char,NVal_Num,ValueFlag_Cd,
                Quantity_Num,Units_Cd,End_Date,Location_Cd,Confidence_Num ,Observation_Blob,
                Update_Date,Download_Date,Import_Date,Sourcesystem_Cd ,UPLOAD_ID) 
                select  Encounter_Num,Patient_Num,Concept_Cd,Provider_Id,Start_Date,
                Modifier_Cd,instance_num,ValType_Cd ,TVal_Char,NVal_Num,ValueFlag_Cd,
                Quantity_Num,Units_Cd,End_Date,Location_Cd,Confidence_Num ,Observation_Blob,
                Update_Date,Download_Date,Import_Date,Sourcesystem_Cd ,UPLOAD_ID from '+
		@CRCDBname + @DBowner  + 
		'observation_fact where patient_num in (select patient_num from patientset) '

	BEGIN TRY
		EXEC sp_executesql @ExecSQL

		IF (@Debug = 1)
		BEGIN
			PRINT 'Finished creation of observation_fact: ' + cast(cast(datediff(ms, @gettime, getdate()) as decimal(18, 2))/1000 as varchar(100)) + ' seconds'
			SET @gettime = getdate()
		END
	END TRY
	BEGIN CATCH 
		SELECT @ErrorMessage = 'ERROR Creating observation_fact Line ' + cast(ERROR_LINE() as varchar(50)) + 
			': ' + ERROR_MESSAGE() 
		RETURN 0
	END CATCH

	/* visit_dimension */

	SET @execsql = 'insert into Visit_Dimension select * from ' + 
		@CRCDBname + @DBowner  + 
		'visit_dimension where patient_num in (select patient_num from patientset) '+
       'and encounter_num in (select distinct(encounter_num) from observation_fact) '

		BEGIN TRY
		EXEC sp_executesql @ExecSQL

		IF (@Debug = 1)
		BEGIN
			PRINT 'Finished creation of visit_dimension: ' + cast(cast(datediff(ms, @gettime, getdate()) as decimal(18, 2))/1000 as varchar(100)) + ' seconds'
			SET @gettime = getdate()
		END
	END TRY
	BEGIN CATCH 
		SELECT @ErrorMessage = 'ERROR Creating visit_dimension Line ' + cast(ERROR_LINE() as varchar(50)) + 
			': ' + ERROR_MESSAGE() 
		RETURN 0
	END CATCH

	/* concept_dimension */

	SET @execsql = 'insert into Concept_Dimension select * from ' + 
		@CRCDBname + @DBowner  + 'concept_dimension'

	BEGIN TRY
		EXEC sp_executesql @ExecSQL

		IF (@Debug = 1)
		BEGIN
			PRINT 'Finished creation of concept_dimension: ' + cast(cast(datediff(ms, @gettime, getdate()) as decimal(18, 2))/1000 as varchar(100)) + ' seconds'
			SET @gettime = getdate()
		END
	END TRY
	BEGIN CATCH 
		SELECT @ErrorMessage = 'ERROR Creating concept_dimension Line ' + cast(ERROR_LINE() as varchar(50)) + 
			': ' + ERROR_MESSAGE() 
		RETURN 0
	END CATCH

	/*********************************************************
	*  Populate the mapping tables with self-mapping data.
	**********************************************************/
	insert into encounter_mapping (ENCOUNTER_IDE, ENCOUNTER_IDE_SOURCE, ENCOUNTER_NUM, ENCOUNTER_IDE_STATUS, PATIENT_IDE,  PATIENT_IDE_SOURCE, PROJECT_ID)
	(select  encounter_num, 'HIVE',encounter_num, 'A', '@',  'HIVE', '@' from visit_dimension 
	where encounter_num not in 
	(select DISTINCT  encounter_num from encounter_mapping where ENCOUNTER_IDE_SOURCE = 'HIVE'))


	insert into patient_mapping (PATIENT_IDE, PATIENT_IDE_SOURCE, PATIENT_NUM, PATIENT_IDE_STATUS,PROJECT_ID,DOWNLOAD_DATE,IMPORT_DATE)
	(select  patient_num, 'HIVE', patient_num, 'A','@',getdate(),getdate() from patient_dimension 
	where patient_num not in 
	(select DISTINCT patient_num from patient_mapping where PATIENT_IDE_SOURCE = 'HIVE'))

	-- Finished populating, turn constraints back on 
	exec sp_msforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all"

PRINT 'Finished creation of datamart'
	