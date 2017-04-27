################################################################################
# Totalnum counter for Oracle, written in Python, 6/13/16
# Written by Kun Wei at Wake Forest University
# Untested and unsupported by SCILHS, use at your own risk!
#
# Updated by Bill Riedl at UC Davis in August 2016
# Functionality Changes
#   Now prints output in required 3 column format; c_fullname, concept_cd, count
#
#   Now creates a single file with all data included in addition to original output
#   #TODO - in order to accomplish this I placed some hard coded 'filters'
#           (if statements) in the write_csv and write_audit_db functions
#           such that root level c_fullnames would not be included.  This is
#           due to the fact that the scope of the analysis is limited to the
#           domain of any given ontology table.  We would have to add a 'layer'
#           on top for true root level summarization.  This is slated for
#           future development
#
#   Metatdata tables to process no longer hard coded.  The script
#   retrieves the table list from table_access.  This can now be used on
#   any i2b2 database
#
#   Script now takes 3 arguments:
#   2 are mandatory:
#       Metadata schema connection string. Example:
#       CRC schema name. Example: i2b2demodata
#   3rd is optional:
#       i2b2 audit schema connection string. Example:
#       If you provide this parameter the script will write the count data plus
#       a timestamp to a database table, which must exist at the connection
#       you provide.  Here is the table definition:
        # CREATE TABLE I2B2_DATA_AUDIT
        # (
        #     AUDIT_DATE DATE,
	    #     C_FULLNAME VARCHAR2(3000 BYTE),
	    #     CONCEPT_CD VARCHAR2(1000 BYTE),
        #     MYCOUNT NUMBER(8,0)
        # )
#   Example script call with all three arguments:
#   python I2B2_totalnum_ora.py metadata_schema_name/metadata_schema_password@//i2b2_metadata_oracle_host:1521/SERVICE_NAME CRC_SCHEMANAME i2b2_audit_db_schema/i2b2_audit_db_schema_password@//i2b2_audit_db_oracle_host:1521/SERVICE_NAME
#   Example script call with only the 2 mandatory arguments
#   python I2B2_totalnum_ora.py metadata_schema_name/metadata_schema_password@//i2b2_metadata_oracle_host:1521/SERVICE_NAME CRC_SCHEMANAME
#
#   Debug features added.  By default the variable, debug, is set to false.
#   You can set it to true and the script will dump a lot of output to the
#   standard output using the print() command.  This will help you understand
#   what the script is doing
#
# Performance Changes
#   Performance improved via the use of increased SQL fetch size,
#   currently set at 500 but, you may change it.  Script now takes between
#   2 and 4 hours, mostly dependent upon the bandwidth between the machine
#   executing this script and your i2b2 database.  Your i2b2 database performance
#   itself will also play a large role.  Your milage will vary.
#
# Script is still technically unsupported but feel free to reach out :)
# awriedl at ucdavis dot edu
################################################################################

import string
import cx_Oracle
import csv
import glob
import time
import datetime
import sys

#Arg 1
oracle_i2b2metadata_string = ''
#Arg 2
crc_schemaname_arg = ''
#Arg 3
oracle_auditdb_string = ''

metadata_table_list = []
fullname_list = []
dict_fullname_concept = dict()
dict_concept_patientnumlist = dict()
dict_fullname_patientnumlist = dict()
dict_fullname_tree = dict()
dict_fullname_strip = dict()
dict_fullname_type = dict()
dict_fullname_patientcnt = dict()

#Outfile header
ls_header = ["fullname","c_basecode", "cnt"]

#SQL fetch size
g_arraysize = 500

#Set to true if you want to debug
debug = True

#Audit timestamp string
audit_ts =''

################################################################################
# recursively walks the tree and gets the patient sets.  It counts them up including child concepts
def collectPatients(sFullname):
    # Recursion until number of children = 0
    if len(dict_fullname_tree[sFullname])>0:
        for sSubFullName in dict_fullname_tree[sFullname]:
            collectPatients(sSubFullName)

    selfpatientset = set()

    if sFullname in dict_fullname_patientnumlist:
        selfpatientset = dict_fullname_patientnumlist[sFullname]
        pass
    else:
        if sFullname in dict_fullname_concept:
            selfcd = dict_fullname_concept[sFullname]
            # if the concept_cd, represented by selfcd is not null then get the patient set associated with it
            if selfcd is not None:
                selfcd = selfcd.strip()
                if len(selfcd) >0:
                    if selfcd in dict_concept_patientnumlist:
                        selfpatientset = dict_concept_patientnumlist[selfcd]

    patientresult = selfpatientset

    #Rolls all the child fullnames in the tree up to their parent
    for sSubFullName in dict_fullname_tree[sFullname]:
        subpatset = dict_fullname_patientnumlist[sSubFullName]
        if subpatset is not None:
            patientresult = patientresult | subpatset
            del dict_fullname_patientnumlist[sSubFullName]


    dict_fullname_patientnumlist[sFullname] = patientresult
    dict_fullname_patientcnt[sFullname] = len(patientresult)

    pass

################################################################################
def getConceptCD(sFullname):
    ret = dict_fullname_concept.get(sFullname)
    return ret

################################################################################
def getGoodFullName(sFullname):
    result = sFullname
    if sFullname.endswith("\\"):
        result = sFullname[:len(sFullname)-1]
    return result

################################################################################
def getOriginalFullname(fullname):
    if fullname not in dict_fullname_strip:
        return fullname
    return dict_fullname_strip[fullname]

################################################################################
#Gets the parent path by chopping sections off
def getParentPath(sFullname):
    sFullname =getGoodFullName(sFullname)

    idxPos = sFullname.rfind("\\")
    if idxPos==-1:
        return None
    if idxPos==0 :
        return "\\"
    return sFullname[:idxPos]

################################################################################
def insertElement(sFullnamestring, treeFullname):
    # dont add an element multiple times
    if sFullnamestring in treeFullname:
        return

    #Create an empty set in treeFullname(dict_fullname_tree) for every fullname
    treeFullname[sFullnamestring] = set()

    #Gets the current fullname and parent fullname
    sCurrentPath = sFullnamestring
    sParentPath = getParentPath(sCurrentPath)

    #Adds all child paths to parent path
    while sParentPath is not None and sParentPath not in treeFullname:
        treeFullname[sParentPath] = set()
        treeFullname[sParentPath].add(sCurrentPath)

        sCurrentPath =sParentPath
        sParentPath = getParentPath(sParentPath)

    if sParentPath is not None:
        treeFullname[sParentPath].add(sCurrentPath)

    pass


################################################################################
def makeTree(pathfullname_list, treeFullname):
    print(time.strftime('%a %H:%M:%S') + "---" + "Making tree...")
    for fullname in pathfullname_list:
        insertElement(fullname, treeFullname)
    print(time.strftime('%a %H:%M:%S') + "---" + "Finished making tree...")
    pass



################################################################################
def read_db_metadata_fullname(sTableName):
    i2b2metadata = cx_Oracle.connect(oracle_i2b2metadata_string)
    cursor_d = i2b2metadata.cursor()
    #Sets this cursors arraysize to the value defined at the top of the script
    #This is done to improve database recall performance
    cursor_d.arraysize = g_arraysize

    sql = """
select distinct C_FULLNAME, C_BASECODE, C_TABLENAME from pcornet_tablename
    """
    sql = sql.replace("pcornet_tablename",sTableName)

    print(time.strftime('%a %H:%M:%S') + "---" + "Executing SQL1: \n" +  sql)
    cursor_d.execute(sql)
    print(time.strftime('%a %H:%M:%S') + "---" + "Finished Execuating SQL1...")
    print(time.strftime('%a %H:%M:%S') + "---" + "Transferring data to local...")
    FULLNAME_BASECODE = cursor_d.fetchall()
    print(time.strftime('%a %H:%M:%S') + "---" + "Geting rows...")

    for row in FULLNAME_BASECODE:
        c_fullname_original = row[0]
        concept_cd = row[1]
        c_tablename = row[2]
        if c_fullname_original is not None:
            c_fullname_original.strip()
        if concept_cd is not None:
            concept_cd.strip()
        if c_tablename is not None:
            c_tablename.strip()
            c_tablename = c_tablename.upper()

        c_fullname = getGoodFullName(c_fullname_original)
        dict_fullname_strip[c_fullname] = c_fullname_original
        dict_fullname_concept[c_fullname] = concept_cd
        fullname_list.append(c_fullname)
        dict_fullname_type[c_fullname] = c_tablename

    print(time.strftime('%a %H:%M:%S') + "---" + "Finished geting rows in read_db_metadata_fullname...")
    cursor_d.close()
    i2b2metadata.close()


################################################################################
def read_db_demodata_concept_fact(sTableName):
    i2b2metadata = cx_Oracle.connect(oracle_i2b2metadata_string)
    cursor_d = i2b2metadata.cursor()
    #Sets this cursors arraysize to the value defined at the top of the script
    #This is done to improve database recall performance
    cursor_d.arraysize = g_arraysize

    sql = """
select distinct concept_cd, patient_num
from crcschema.OBSERVATION_FACT f
where
EXISTS (select C_BASECODE from pcornet_tablename m where f.concept_cd = m.C_BASECODE )
    """
    sql = sql.replace("pcornet_tablename",sTableName)
    sql = sql.replace("crcschema", crc_schemaname_arg)

    print(time.strftime('%a %H:%M:%S') + "---" + "Executing SQL in read_db_demodata_concept_fact: \n" + sql )
    cursor_d.execute(sql)
    print(time.strftime('%a %H:%M:%S') + "---" + "Finished Execuating SQL: " + sql)
    print(time.strftime('%a %H:%M:%S') + "---" + "Transferring data to local...")
    CONCEPT_PATIENT = cursor_d.fetchall()
    print(time.strftime('%a %H:%M:%S') + "---" + "Processing concept_patient rows locally")

    for row in CONCEPT_PATIENT:
        concept_cd = row[0]
        patient_num = row[1]

        if concept_cd is not None:
            concept_cd.strip()

        if concept_cd not in dict_concept_patientnumlist:
                dict_concept_patientnumlist[concept_cd] = set()
        dict_concept_patientnumlist[concept_cd].add(patient_num)
    print(time.strftime('%a %H:%M:%S') + "---" + "Finished processing concept_patient rows locally \n")

    cursor_d.close()
    i2b2metadata.close()



################################################################################
def read_db_demodata_patient_vist(sTableName):
    i2b2metadata = cx_Oracle.connect(oracle_i2b2metadata_string)
    cursor_d = i2b2metadata.cursor()
    #Sets this cursors arraysize to the value defined at the top of the script
    #This is done to improve database recall performance
    cursor_d.arraysize = g_arraysize

    sql = """
select C_FULLNAME, C_BASECODE, C_FACTTABLECOLUMN, C_TABLENAME, C_COLUMNNAME, C_COLUMNDATATYPE, C_OPERATOR, C_DIMCODE from ---pcornet_tablename--- where C_FULLNAME ='---C_FULLNAME---' AND C_VISUALATTRIBUTES LIKE '%A%'
    """

    for fullname, tabletype in dict_fullname_type.items():
        if tabletype.upper() != "PATIENT_DIMENSION" and tabletype.upper() != "VISIT_DIMENSION"  :
            continue
        sql_curr = sql.replace("---pcornet_tablename---",sTableName)
        sql_curr = sql_curr.replace("---C_FULLNAME---",getOriginalFullname(fullname))
        cursor_d.execute(sql_curr)
        FULLNAME_PARAMETERS = cursor_d.fetchall()
        for row in FULLNAME_PARAMETERS:
            C_FACTTABLECOLUMN = row[2]
            C_TABLENAME = row[3]
            C_COLUMNNAME = row[4]
            C_COLUMNDATATYPE = row[5] ###
            C_OPERATOR = row[6]
            C_DIMCODE = row[7]

            if C_COLUMNNAME.upper() == 'ENCOUNTER':
                continue

            if C_OPERATOR.upper() == "IN":
                C_DIMCODE = '(' + C_DIMCODE + ')'
                #Handles case of local site adding parens in metadata tables
                C_DIMCODE = C_DIMCODE.replace("((","(")
                C_DIMCODE = C_DIMCODE.replace("))",")")
                pass
            elif C_OPERATOR.upper() == "LIKE" or C_OPERATOR.upper() == "=":
                C_DIMCODE = '\'' + C_DIMCODE + '\''

            sql_query = """
select distinct patient_num
from crcschema.---C_TABLENAME--- 
where
---C_COLUMNNAME--- ---C_OPERATOR--- ---C_DIMCODE---
            """
            sql_query_curr = sql_query.replace("---C_TABLENAME---",C_TABLENAME)
            sql_query_curr = sql_query_curr.replace("---C_COLUMNNAME---",C_COLUMNNAME)
            sql_query_curr = sql_query_curr.replace("---C_OPERATOR---",C_OPERATOR)
            sql_query_curr = sql_query_curr.replace("---C_DIMCODE---",C_DIMCODE)
            sql_query_curr = sql_query_curr.replace("crcschema", crc_schemaname_arg)

            print(time.strftime('%a %H:%M:%S') + "---" + "Executing patient vist SQL:")
            if debug:
                print(sql_query_curr)
            cursor_d.execute(sql_query_curr)
            PATIENTS = cursor_d.fetchall()
            set_patients = set()
            for row in PATIENTS:
                set_patients.add(row[0])
            dict_fullname_patientnumlist[fullname] = set_patients
            if debug:
                print("cnt = " + str(len(set_patients)))


    cursor_d.close()
    i2b2metadata.close()
    pass

################################################################################
def read_db_modifier(sTableName):
    i2b2metadata = cx_Oracle.connect(oracle_i2b2metadata_string)
    cursor_d = i2b2metadata.cursor()
    #Sets this cursors arraysize to the value defined at the top of the script
    #This is done to improve database recall performance
    cursor_d.arraysize = g_arraysize

    sql = """
select distinct m.C_FULLNAME, i.modifier_cd
from ---pcornet_tablename--- m inner join crcschema.modifier_dimension i on m.C_DIMCODE = i.MODIFIER_PATH
where UPPER(m.C_TABLENAME) ='MODIFIER_DIMENSION' and UPPER(m.C_OPERATOR) ='LIKE'
    """
    sql = sql.replace("---pcornet_tablename---",sTableName)
    sql = sql.replace("crcschema", crc_schemaname_arg)

    cursor_d.execute(sql)
    MODIFIER_NAMES = cursor_d.fetchall()
    for row in MODIFIER_NAMES:
        C_FULLNAME_original = row[0]
        modifier_cd = row[1]
        sql_query = """
select distinct patient_num
from crcschema.OBSERVATION_FACT
where modifier_cd = '---modifier_cd---'
        """
        sql_query = sql_query.replace("---modifier_cd---",modifier_cd)
        slq_query = sql_query.replace("crcschema", crc_schemaname_arg)
        print(time.strftime('%a %H:%M:%S') + "---" + "Executing modifier vist SQL:")
        if debug:
            print(sql_query)

        cursor_d.execute(sql_query)
        PATIENTS = cursor_d.fetchall()

        set_patients = set()
        for row in PATIENTS:
            set_patients.add(row[0])
        fullname = getGoodFullName(C_FULLNAME_original)
        dict_fullname_strip[fullname] = C_FULLNAME_original
        dict_fullname_patientnumlist[fullname] = set_patients


    cursor_d.close()
    i2b2metadata.close()
    pass


################################################################################
def write_csv(sTableName):
    ls_result = []
    # Creates a list of lists
    for fullname, cnt in dict_fullname_patientcnt.items():

        printedFullname = getOriginalFullname(fullname)
        #Zero counts as empty cells
        if cnt == 0:
            cnt=""
        #Dont add "\\","\\PCORI","\\PCORI_MOD"
        if printedFullname != "\\" and printedFullname != "\\PCORI" and printedFullname != "\\PCORI_MOD" and printedFullname != "\\i2b2":
            ls_result.append([printedFullname, getConceptCD(fullname), cnt])

    print(time.strftime('%a %H:%M:%S') + "---" + "Outputing result to CSV file...")
    #with open("./output_"+ sTableName  +".csv", "w", newline='') as outfile:
    with open("./output_"+ sTableName  +".csv", "w") as outfile:
        writer = csv.writer(outfile)
        writer.writerow(ls_header)
        writer.writerows(ls_result)

    print(time.strftime('%a %H:%M:%S') + "---" + "Adding same results to Master outfile...")
    with open("./master_output.csv","a") as masteroutfile:
        masterwriter = csv.writer(masteroutfile)
        masterwriter.writerows(ls_result)


################################################################################
def write_audit_db(sTableName):
    ls_result = []
    # Creates a list of lists
    for fullname, cnt in dict_fullname_patientcnt.items():
        printedFullname = getOriginalFullname(fullname)

        #Dont add "\\","\\PCORI","\\PCORI_MOD"
        if printedFullname != "\\" and printedFullname != "\\PCORI" and printedFullname != "\\PCORI_MOD" and printedFullname != "\\i2b2":
            ls_result.append([audit_ts, printedFullname, getConceptCD(fullname), cnt])

    auditdbcon = cx_Oracle.connect(oracle_auditdb_string)
    cursor = auditdbcon.cursor()
    cursor.execute("ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI'")
    cursor.prepare('insert into i2b2_data_audit (AUDIT_DATE, C_FULLNAME, CONCEPT_CD, MYCOUNT) values (:1,:2,:3,:4)')
    cursor.executemany(None, ls_result)
    auditdbcon.commit()
    cursor.close()
    auditdbcon.close()

################################################################################
def write_sql(sTableName):
    sql_prefix ='UPDATE pcornet_tablename SET c_totalnum = '
    sql_prefix = sql_prefix.replace("pcornet_tablename",sTableName)

    print(time.strftime('%a %H:%M:%S') + "---" + "Writing update SQLs to file...")
    with open("./db_output_" + sTableName + ".sql" , 'a') as out:
        for fullname, cnt in dict_fullname_patientcnt.items():
            if fullname == '\\':
                continue
            if cnt != 0:
                sql = sql_prefix +  str(cnt) + ' where c_fullname=\'' + getOriginalFullname(fullname) +'\';'
                out.write(sql + '\n')
            else:
                #sql = sql_prefix +  'null' + ' where c_fullname=\'' + getOriginalFullname(fullname) +'\';'
                #out.write(sql + '\n')
                pass




################################################################################
def masterOutfileInit():
    #open the master_output file obliterating what was there before and write the header line only
    #all other data will be appended in write_csv
    masteroutfile = open("./master_output.csv","w")
    headerwriter = csv.writer(masteroutfile)
    headerwriter.writerow(ls_header)
    masteroutfile.close()

################################################################################
def getMetadataTableList():
    i2b2metadata = cx_Oracle.connect(oracle_i2b2metadata_string)
    cursor_d = i2b2metadata.cursor()
    #Sets this cursors arraysize to the value defined at the top of the script
    #This is done to improve database recall performance
    cursor_d.arraysize = g_arraysize

    sql = """SELECT DISTINCT C_TABLE_NAME FROM TABLE_ACCESS WHERE C_VISUALATTRIBUTES LIKE '%A%'"""
    cursor_d.execute(sql)
    metadataTableNamesResultSet = cursor_d.fetchall()
    for row in metadataTableNamesResultSet:
        metadataTableName = row[0]
        metadata_table_list.append(metadataTableName)



################################################################################
def process(sTableName):
    # Initialize variables
    global metadata_table_list
    global fullname_list
    global dict_fullname_concept
    global dict_concept_patientnumlist
    global dict_fullname_patientnumlist
    global dict_fullname_tree
    global dict_fullname_strip
    global dict_fullname_type
    global dict_fullname_patientcnt

    metadata_table_list = []
    fullname_list = []
    dict_fullname_concept = dict()
    dict_concept_patientnumlist = dict()
    dict_fullname_patientnumlist = dict()
    dict_fullname_tree = dict()
    dict_fullname_strip = dict()
    dict_fullname_type = dict()
    dict_fullname_patientcnt = dict()

############################################
# Start processing
############################################

    print(time.strftime('%a %H:%M:%S') + "---" + "Processing: "+ sTableName)

    ##  #########################  ##
    #read_db_metadata_fullname(sTableName) - creates 3 global dict objects
        #dict_fullname_strip[getGoodFullName(c_fullname_original)]:c_fullname --> stores the original c_fullname indexed by the new one. Get back to original
        #dict_fullname_concept[getGoodFullName(c_fullname_original)]:concept_cd --> Get from c_fullname to concept_cd quickly
        #dict_fullname_type[getGoodFullName(c_fullname_original)]:c_tablename --> get from c_fullname to table in which it is stored quickly
    # It also creates one global list
        #fullname_list[getGoodFullName(c_fullname_original)] --> just a list of 'cleaned' full names.  Cleaning just strips last '\'
    ##  #########################  ##
    print("\n-------------------read_db_metadata_fullname--------------------------\n")
    read_db_metadata_fullname(sTableName)
    # Debugging steps
    if debug:
        print("These objects were created in read_db_metadata_fullname:")
        print("Printing dict_fullname_strip")
        print(dict_fullname_strip)
        print("\n")
        print("Printing dict_fullname_concept")
        print(dict_fullname_concept)
        print("\n")
        print("Printing dict_fullname_type")
        print(dict_fullname_type)
        print("\n")
        print("fullname_list")
        print(fullname_list)

    ##  #########################  ##
    # Gets a count of distinct patient_num per concept_cd from obs_fact
    # for each concept_cd it creates a list of patient_nums associated with it
        #dict_concept_patientnumlist[concept_cd]:[patient_num1, patient_num2,...]
    # Simply joins the metadata table with obs_fact on C_BASECODE = concept_cd
    ##  #########################  ##
    print("\n-------------------read_db_demodata_concept_fact--------------------------\n")
    read_db_demodata_concept_fact(sTableName)
    if debug:
        print("\n")
        print("These objects were created in read_db_demodata_concept_fact:")
        print("Printing dict_concept_patientnumlist:")
        for k,v in dict_concept_patientnumlist.iteritems():
            print(k+" "+str(len(v)))

    ##  #########################  ##
    # Gets a count of distinct patient_num from PATIENT_DIMENSION and VISIT_DIMENSION
    # for each fullname stores a set of patient_nums
        #dict_fullname_patientnumlist[c_fullname]:[patient_num1, patient_num2,...]
        # This objects represents one of the key outputs of this script.  Since we know the relationship between full name and a column in either PATIENT_DIMENSION or VISIT_DIMENSION is 1-1; we write directly to this structure here
        # It's more complicated to do this with the data in OBSERVATION_FACT
    ##  #########################  ##
    print("\n-------------------read_db_demodata_patient_vist--------------------------\n")
    read_db_demodata_patient_vist(sTableName)
    if debug:
        print("\n")
        print("These objects were created in read_db_demodata_patient_vist:")
        print("Printing dict_fullname_patientnumlist:")
        for k,v in dict_fullname_patientnumlist.iteritems():
            print(k+" "+str(len(v)))
        print("\n")

    ##  #########################  ##
    #  NOTE: We dont currently run this!!
    #  Iterates through modifiers in metadata table
    #  Identifies unituq patient count that have the modifiers
    #  Adds modifier entries to dict_fullname_strip
    #  Adds patient_num set to dict_fullname_patientnumlist indexed by c_fullname of the modifier
    ##  #########################  ##
    # read_db_modifier(sTableName)
    # if debug:
    #     print("\n")
    #     print("These objects were created in read_db_modifier:")
    #     print("Printing dict_fullname_patientnumlist:")
    #     for k,v in dict_fullname_patientnumlist.iteritems():
    #         print(k+" "+str(len(v)))

    ##  #########################  ##
    # iterates through fullname_list and adds elements to treeFullname AKA dict_fullname_tree
    #
    ##  #########################  ##
    print(time.strftime('%a %H:%M:%S') + "---" + "Making Tree... ")
    makeTree(fullname_list, dict_fullname_tree)

    if debug:
        print("\n")
        print("These objects were created in makeTree:")
        print("Printing dict_fullname_tree")
        print(dict_fullname_tree)
        print("Printing formatted dict_fullname_tree")
        for key,valuelist in dict_fullname_tree.iteritems():
            print(key)
            for item in valuelist:
                print("\t" + item)
        print("\n")

    ##  #########################  ##
    #   Collects lists of patients associated
    #   with c_fullnames
    ##  #########################  ##
    print(time.strftime('%a %H:%M:%S') + "---" + "Collecting patients... ")
    collectPatients('\\')


    ##  #########################  ##
    #Creates formatted CSV file to submit
    ##  #########################  ##
    print(time.strftime('%a %H:%M:%S') + "---" + "Writing to CSV outfiles... ")
    write_csv(sTableName)

    ##  #########################  ##
    # Writes counts to audit database
    # only if you passed in an audit
    # DB connection string
    ##  #########################  ##
    if oracle_auditdb_string != 'NONE':
        print(time.strftime('%a %H:%M:%S') + "---" + "Writing to audit DB... ")
        write_audit_db(sTableName)

    ##  #########################  ##
    #Creates SQL that can be executed to update c_totalnum
    ##  #########################  ##
    print(time.strftime('%a %H:%M:%S') + "---" + "Writing update c_totalnum sql to file... ")
    write_sql(sTableName)

################################################################################
def main():
    #These will be set with a parameters passed in at script call time
    global oracle_i2b2metadata_string
    global crc_schemaname_arg
    global oracle_auditdb_string
    global audit_ts

    print("Hello. I am going to start evaluating your I2B2 data now")
    if debug:
        print("DEBUG is true; expect a lot of output")

    #Set up oracle connection string
    oracle_i2b2metadata_string = sys.argv[1] if len(sys.argv) >=2 else 'NONE'
    print("New Oracle Connect String " + oracle_i2b2metadata_string)

    #Set up crc_schemaname_arg
    crc_schemaname_arg = sys.argv[2] if len(sys.argv) >=3 else 'NONE'
    print("CRC Schema name is: " + crc_schemaname_arg)

    #Set up audit db name
    oracle_auditdb_string = sys.argv[3] if len(sys.argv) >=4 else 'NONE'
    print("Audit db string is: " + oracle_auditdb_string)

    #Set up audit timestamp
    audit_ts = time.strftime('%Y-%m-%d %H:%M')

    #Initializing masteroutfile - empty it and place a single 3 column header line
    masterOutfileInit()

    #set up loop that iterates through the metadata tables
    getMetadataTableList()
    for metadatatable in metadata_table_list:
        print("------------- Now Processing: "+metadatatable+"---------------------------------")
        process(metadatatable)

    print(time.strftime('%a %H:%M:%S') + "---" + "FINISHED !!!")


if __name__ == '__main__':
    main()
