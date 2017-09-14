# Totalnum counter for Oracle, written in Python, 6/13/16
# Written by Kun Wei at Wake Forest University
# Untested and unsupported by SCILHS, use at your own risk!

import string
import cx_Oracle

import csv
import glob
import time

import datetime


oracle_i2b2metadata_string = 'i2b2metadata/password@//hostname.server.edu:1521/ServiceName'

fullname_list = []
dict_fullname_concept = dict()

dict_concept_patientnumlist = dict()
dict_fullname_patientnumlist = dict()

dict_fullname_tree = dict()

dict_fullname_strip = dict()

dict_fullname_type = dict()


dict_fullname_patientnumlist = dict()
dict_fullname_patientcnt = dict()



def collectPatients(sFullname):
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
            if selfcd is not None :
                selfcd = selfcd.strip()
                if len(selfcd) >0:
                    if selfcd in dict_concept_patientnumlist:
                        selfpatientset = dict_concept_patientnumlist[selfcd]

    patientresult = selfpatientset
    for sSubFullName in dict_fullname_tree[sFullname]:
        subpatset = dict_fullname_patientnumlist[sSubFullName]
        if subpatset is not None:
            patientresult = patientresult | subpatset
            del dict_fullname_patientnumlist[sSubFullName]

    dict_fullname_patientnumlist[sFullname] = patientresult
    dict_fullname_patientcnt[sFullname] = len(patientresult)


    pass


def getGoodFullName(sFullname):
    result = sFullname
    if sFullname.endswith("\\"):
        result = sFullname[:len(sFullname)-1]
    return result
def getOriginalFullname(fullname):
    if fullname not in dict_fullname_strip:
        return fullname
    return dict_fullname_strip[fullname]


def getParentPath(sFullname):
    sFullname =getGoodFullName(sFullname)

    idxPos = sFullname.rfind("\\")
    if idxPos==-1:
        return None
    if idxPos==0 :
        return "\\"
    return sFullname[:idxPos]



def insertElement(sFullnamestring, treeFullname):
    if sFullnamestring in treeFullname:
        return

    treeFullname[sFullnamestring] = set()

    sCurrentPath = sFullnamestring
    sParentPath = getParentPath(sCurrentPath)

    while sParentPath is not None and sParentPath not in treeFullname:
        treeFullname[sParentPath] = set()
        treeFullname[sParentPath].add(sCurrentPath)

        sCurrentPath =sParentPath
        sParentPath = getParentPath(sParentPath)

    if sParentPath is not None:
        treeFullname[sParentPath].add(sCurrentPath)

    pass


def makeTree(pathfullname_list, treeFullname):
    print(time.strftime('%a %H:%M:%S') + "---" + "Making tree...")
    for fullname in pathfullname_list:
        insertElement(fullname, treeFullname)
    print(time.strftime('%a %H:%M:%S') + "---" + "Finished making tree...")
    pass




def read_db_metadata_fullname(sTableName):
    i2b2metadata = cx_Oracle.connect(oracle_i2b2metadata_string)
    cursor_d = i2b2metadata.cursor()

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

    print(time.strftime('%a %H:%M:%S') + "---" + "Finished geting rows...")
    cursor_d.close()
    i2b2metadata.close()



def read_db_demodata_concept_fact(sTableName):

    i2b2metadata = cx_Oracle.connect(oracle_i2b2metadata_string)
    cursor_d = i2b2metadata.cursor()

    sql = """
select distinct concept_cd, patient_num
from I2B2DEMODATA.OBSERVATION_FACT f
where
EXISTS (select C_BASECODE from pcornet_tablename m where f.concept_cd = m.C_BASECODE )
    """
    sql = sql.replace("pcornet_tablename",sTableName)

    print(time.strftime('%a %H:%M:%S') + "---" + "Executing SQL2: \n" + sql )
    cursor_d.execute(sql)
    print(time.strftime('%a %H:%M:%S') + "---" + "Finished Execuating SQL2...")
    print(time.strftime('%a %H:%M:%S') + "---" + "Transferring data to local...")
    CONCEPT_PATIENT = cursor_d.fetchall()
    print(time.strftime('%a %H:%M:%S') + "---" + "Geting rows...")

    for row in CONCEPT_PATIENT:
        concept_cd = row[0]
        patient_num = row[1]

        if concept_cd is not None:
            concept_cd.strip()
        #if patient_num is not None:
        #    patient_num.strip()

        if concept_cd not in dict_concept_patientnumlist:
                dict_concept_patientnumlist[concept_cd] = set()
        dict_concept_patientnumlist[concept_cd].add(patient_num)
    print(time.strftime('%a %H:%M:%S') + "---" + "Finished geting rows...")

    cursor_d.close()
    i2b2metadata.close()


def read_db_demodata_patient_vist(sTableName):
    i2b2metadata = cx_Oracle.connect(oracle_i2b2metadata_string)
    cursor_d = i2b2metadata.cursor()
    sql = """
select C_FULLNAME, C_BASECODE, C_FACTTABLECOLUMN, C_TABLENAME, C_COLUMNNAME, C_COLUMNDATATYPE, C_OPERATOR, C_DIMCODE from ---pcornet_tablename--- where C_FULLNAME ='---C_FULLNAME---'
    """

    for fullname, tabletype in dict_fullname_type.items():
        if tabletype != "PATIENT_DIMENSION" and tabletype != "VISIT_DIMENSION"  :
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
                pass
            elif C_OPERATOR.upper() == "LIKE" or C_OPERATOR.upper() == "=":
                C_DIMCODE = '\'' + C_DIMCODE + '\''
            sql_query = """
select distinct patient_num
from I2B2DEMODATA.---C_TABLENAME--- f
where
---C_COLUMNNAME--- ---C_OPERATOR--- ---C_DIMCODE---
            """
            sql_query_curr = sql_query.replace("---C_TABLENAME---",C_TABLENAME)
            sql_query_curr = sql_query_curr.replace("---C_COLUMNNAME---",C_COLUMNNAME)
            sql_query_curr = sql_query_curr.replace("---C_OPERATOR---",C_OPERATOR)
            sql_query_curr = sql_query_curr.replace("---C_DIMCODE---",C_DIMCODE)

            print(time.strftime('%a %H:%M:%S') + "---" + "Executing patient vist SQL:")
            print(sql_query_curr)
            cursor_d.execute(sql_query_curr)
            PATIENTS = cursor_d.fetchall()
            set_patients = set()
            for row in PATIENTS:
                set_patients.add(row[0])
            dict_fullname_patientnumlist[fullname] = set_patients
            print("cnt = " + str(len(set_patients)))


    cursor_d.close()
    i2b2metadata.close()
    pass

def read_db_modifier(sTableName):
    i2b2metadata = cx_Oracle.connect(oracle_i2b2metadata_string)
    cursor_d = i2b2metadata.cursor()
    sql = """
select distinct m.C_FULLNAME, i.modifier_cd
from ---pcornet_tablename--- m inner join I2B2DEMODATA.modifier_dimension i on m.C_DIMCODE = i.MODIFIER_PATH
where UPPER(m.C_TABLENAME) ='MODIFIER_DIMENSION' and UPPER(m.C_OPERATOR) ='LIKE'
    """
    sql = sql.replace("---pcornet_tablename---",sTableName)
    cursor_d.execute(sql)
    MODIFIER_NAMES = cursor_d.fetchall()
    for row in MODIFIER_NAMES:
        C_FULLNAME_original = row[0]
        modifier_cd = row[1]
        sql_query = """
select distinct patient_num
from I2B2DEMODATA.OBSERVATION_FACT
where modifier_cd = '---modifier_cd---'
        """
        sql_query = sql_query.replace("---modifier_cd---",modifier_cd)

        print(time.strftime('%a %H:%M:%S') + "---" + "Executing modifier vist SQL:")
        print(sql_query)

        cursor_d.execute(sql_query)
        print("--ff1--")
        PATIENTS = cursor_d.fetchall()
        print("--ff2--")
        print(PATIENTS)

        set_patients = set()
        for row in PATIENTS:
            set_patients.add(row[0])
        fullname = getGoodFullName(C_FULLNAME_original)
        dict_fullname_strip[fullname] = C_FULLNAME_original
        dict_fullname_patientnumlist[fullname] = set_patients
        print("cnt = " + str(len(set_patients)))

    cursor_d.close()
    i2b2metadata.close()
    pass




def read_db(sTableName):
    read_db_metadata_fullname(sTableName)
    read_db_demodata_concept_fact(sTableName)
    read_db_demodata_patient_vist(sTableName)
    #read_db_modifier(sTableName)

    pass





def write_csv(sTableName):
    ls_header = ["fullname", "cnt"]
    ls_result = []
    for fullname, cnt in dict_fullname_patientcnt.items():
        ls_result.append([getOriginalFullname(fullname), cnt])
    print(time.strftime('%a %H:%M:%S') + "---" + "Outputing result to CSV file...")
    with open("./output_"+ sTableName  +".csv", "w", newline='') as outfile:
        writer = csv.writer(outfile)
        writer.writerow(ls_header)
        writer.writerows(ls_result)


def write_sql(sTableName):
    sql_prefix ='UPDATE pcornet_tablename SET c_totalnum = '
    sql_prefix = sql_prefix.replace("pcornet_tablename",sTableName)

    print(time.strftime('%a %H:%M:%S') + "---" + "Writing update SQLs to file...")
    with open(".\output_" + sTableName + ".sql" , 'a') as out:
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



def update_db(sTableName):
    try:
        i2b2metadata = cx_Oracle.connect(oracle_i2b2metadata_string)

        cursor_m = i2b2metadata.cursor()

        sql_prefix ='UPDATE pcornet_tablename SET c_totalnum = '
        sql_prefix = sql_prefix.replace("pcornet_tablename",sTableName)

        i = 0


        for fullname, cnt in dict_fullname_patientcnt.items():
            if fullname == '\\':
                continue

            if cnt != 0:
                sql = sql_prefix +  str(cnt) + ' where c_fullname=\'' + getOriginalFullname(fullname) +'\''
            else:
                #sql = sql_prefix +  'null' + ' where c_fullname=\'' + getOriginalFullname(fullname) +'\''
                continue

            #print(time.strftime('%a %H:%M:%S') + "---" + "Updating SQL: " + sql )
            print('.', end="")
            cursor_m.execute(sql)
            if i>=1000:
                i2b2metadata.commit()
                i=0



    finally:
            i2b2metadata.commit()
            cursor_m.close()
    pass


def process(sTableName):
    global fullname_list
    global dict_fullname_concept
    global dict_concept_patientnumlist
    global dict_fullname_patientnumlist
    global dict_fullname_tree
    global dict_fullname_strip
    global dict_fullname_type
    global dict_fullname_patientnumlist
    global dict_fullname_patientcnt


    fullname_list = []
    dict_fullname_concept = dict()

    dict_concept_patientnumlist = dict()
    dict_fullname_patientnumlist = dict()

    dict_fullname_tree = dict()
    dict_fullname_strip = dict()
    dict_fullname_type = dict()

    dict_fullname_patientnumlist = dict()
    dict_fullname_patientcnt = dict()

#########################################################################
    read_db(sTableName)


    makeTree(fullname_list, dict_fullname_tree)
    print(time.strftime('%a %H:%M:%S') + "---" + "Collecting patients... ")
    collectPatients('\\')


    write_csv(sTableName)
    write_sql(sTableName)
    #update_db(sTableName)




def main():

    process("pcornet_vital")
    process("pcornet_demo")
    process("pcornet_diag")
    process("pcornet_lab")
    process("pcornet_med")
    process("pcornet_proc")


    process("pcornet_enc")
    process("pcornet_enroll")


    print(time.strftime('%a %H:%M:%S') + "---" + "FINISHED !!!")


if __name__ == '__main__':
    main()
