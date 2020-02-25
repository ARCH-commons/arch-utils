import datetime as dt
from os import listdir
from zipfile import ZipFile

import pandas as pd

import totalnum_aggregator.totalnum_tools as totpkg

# Python version of totalnum mixer / pre-processor
# Requires pandas and Numpy. Python 3 syntax.
# By Jeff Klann, PhD 6/2017-10/2018
""" 
Instructions for use: 
  1) Create a directory of totalnum files, one per location, for a single point in time.
      Files must be in this csv format: c_fullname, c_name, totalnum_[sitename]
      NEW 10-01-18! Files can be zipped, except for totalnum_allpaths and any Excel files that need to be converted.
  2) From a reference database, generate the master ontology file:
    Using csvkit:
     a) Follow the installation instructions here: https://github.com/ARCH-commons/arch-utils/wiki/Uploading-your-totalnum-counts-to-SCILHS-(for-SCILHS-sites)
     b) Then run:
         sql2csv --db "mssql://pcori_dev" --query "select distinct c_fullname, c_name from pcornet_master_vw where c_synonym_cd!='Y' and c_visualattributes like '%A%'" -v >totalnums_allpaths.csv
     c) Move the generated file into your directory of totalnum files
  3) Optionally run convertXLS(numsdir,numsextdir) which will merge a multi-tabbed Excel file into a single csv sheet, with 
    only the correct three columns. (Note: only supports a column incorrectly labeled c_totalnum at present).
  4) Run process2CSV or just process, passing a basedir, and subdir for the nums files, and a subdir for output
  5) Optionally create a summation file that uses the most recent numbers available at every site, run buildSum

Performs the following cleanup when importing:
    - Supports any reasonable text encoding
    - Lowercases column names
    - If the totalnum column is called c_totalnum, renames it as totalnum_[site] where [site] is the shortest substring with an underscore in the filename.
    - Set totalnums that are strings to 5 (not sure if this is working)
    - Set totalnums 1-10 to 5 (obfuscate small counts) 
    - Remove RAW_* and NaN names
"""

# Shortcut - runs process and saves to a CSV file in numsdir+outdir/
def process2CSV(numsdir = '/Users/jeffklann/Google Drive/SCILHS Phase II/Committee, Cores, Panels/Informatics & Technology Core/totalnums/',
            numsextdir = 'nums_0818',outDirAndName= 'joined/joined_0818.csv'):
    process(numsdir,numsextdir).to_csv(numsdir+outDirAndName)

# After totalnums are built, find the most recent count for each site in the joined files, sum these, round down, and save
def buildSum(numsdir = '/Users/jeffklann/Google Drive/SCILHS Phase II/Committee, Cores, Panels/Informatics & Technology Core/totalnums/',
             joinedextdir = 'joined',outDirAndName='sum.csv',outDirAndNameAvg='avg.csv'):
    files = [f for f in listdir(numsdir+joinedextdir) if ".csv" in f[-4:] and 'joined' in f]
    files = sorted(files, key=lambda x: dt.datetime.strptime(x[7:11], '%m%y'))
    cols_all = []
    df_all = None
    dfp_all = None
    for f in files[::-1]:
        print(f)
        tot = totpkg.Totalnum()
        tot.init(numsdir+joinedextdir+'/',f,minimal=False)
        cols_new = [x for x in filter(lambda x: x!='na',[x if x not in cols_all else 'na' for x in tot.df.columns ])]
        cols_all=cols_all+cols_new
        print(cols_new)
        if df_all is None:
            df_all=tot.df[cols_new]
            dfp_all=tot.dfp[cols_new]
        elif len(cols_new)>0:
            df_all=df_all.join(tot.dfp[cols_new],how='left')
            dfp_all = dfp_all.join(tot.dfp[cols_new], how='left')

    # Compute sum column,save, and return
    sum = df_all[df_all.columns[df_all.columns.str.contains("#")]].sum(axis=1)
    sum=pd.to_numeric(sum,downcast='integer')
    sum = sum.apply(agg_val)
    sum.name = 'sum'
    sum.to_csv(numsdir+outDirAndName)

    # NEW 5/19 - Now compute avg and std dev too
    avg = dfp_all[dfp_all.columns[dfp_all.columns.str.contains("#")]].mean(axis=1)
    avg = pd.to_numeric(avg,downcast='integer')
    avg.name = 'avg'
    stdev = dfp_all[dfp_all.columns[dfp_all.columns.str.contains("#")]].std(axis=1)
    stdev = pd.to_numeric(stdev, downcast='float')
    stdev.name = 'stdev'
    outavg = pd.concat([df_all,avg,stdev],axis=1)
    outavg.to_csv(numsdir+outDirAndNameAvg)

    return sum

# One of our sites always submits as a multisheet excel file with extra columns, this converts to csv
# A limitation - it assumes the totalnum column is called c_totalnum
def convertXLS(numsdir = '/Users/jeffklann/Google Drive/SCILHS Phase II/Committee, Cores, Panels/Informatics & Technology Core/totalnums/',
            numsextdir = 'nums_0818'):
    files = [f for f in listdir(numsdir + numsextdir) if (".xls" in f[-4:] or '.xlsx' in f[-5:]) and f[0]!='~']
    print(files)
    for f in files:
        df = pd.read_excel(numsdir + numsextdir+'/'+f, sheet_name=None)
        out = []
        for k, v in df.items():
            print(k)
            out.append(v)
        outdf =pd.concat(out)
        outdf = outdf.rename(columns=lambda x: x.lower())
        outdf[['c_fullname', 'c_basecode', 'c_totalnum']].to_csv(numsdir+numsextdir+'/'+(f[:f.index('.')-1])+'.csv')

# Load the totalnum files, join them to the master ontology, compute an obfuscated network-wide sum, and output as a big dataframe report
def process(numsdir = '/Users/jeffklann/Google Drive/SCILHS Phase II/Committee, Cores, Panels/Informatics & Technology Core/totalnums/',
            numsextdir = 'nums_0818'):
    global totalnums,allpaths,df
    allpaths = read_csv_multiformat(numsdir+numsextdir+'/totalnums_allpaths.csv')
    totalnums = []

    # Take a loaded totalnum df, do a little cleanup, return it
    # f is the filename in case site abbreviation needs cleanup
    def process_file(df,f):
        # Convert non-numeric values in totalnum column to 5
        # (One of our sites labels counts that are less than ten with a string)
        if df.dtypes[-1] == 'O':  # Column has strings
            print("Converting strings to 5 for " + f)
            df.loc[df.iloc[:, -1].str.isnumeric() == False, df.columns[-1]] = 5
        # If the totalnum column is called c_totalnum, rather than something site-specific, rename it:
        if 'c_totalnum' in df.columns[-1] and len(df.columns[-1]) <= len('c_totalnum') + 1:
            siteabbr = min(f.split('_'), key=len)
            print(f + 'is not labeled right, I could change it to: totalnum_' + siteabbr)
            df = df.rename(columns={'c_totalnum': 'totalnum_' + siteabbr})
        return df

    # Load .csv files
    files = [f for f in listdir(numsdir+numsextdir) if ".csv" in f[-4:]]
    for f in files:
        if 'allpaths.csv' not in f: # skip allpaths
            print(f)
            # Load the csv
            totalnums.append(process_file(read_csv_multiformat(numsdir+numsextdir+"/"+f),f))

    # Load .zip files
    files = [f for f in listdir(numsdir+numsextdir) if '.zip' in f[-4:]]
    for f in files:
        z = ZipFile(numsdir+numsextdir+"/"+f)
        zf = [zi.filename for zi in z.infolist() if ".csv" in zi.filename[-4:] and zi.filename[0] not in ('.','_')] # Include only non-hidden csvs
        for zn in zf:
            print(f+":"+zn)
            totalnums.append(process_file(read_csv_multiformat(z.open(zn)),zn))

    i = 0
    df = allpaths
    for t in totalnums:
        print("Joining " + str(i))
        df = df.join(t, how="left", rsuffix=i)
        i += 1
    cols = [c for c in df.columns if "totalnum" in c.lower()]
    cols2 = [c for c in df.columns[0:1]]
    print(df.columns)
    for c in cols:
        print("Appending " + str(c))
        #if df[c].isnull(): df[c]=0
        try:
            df[df[c]<11].c = 5 # Obfuscate small counts - bugfix 02218 added .c otherwise would null out any counts if one site had small values
        except:
            print("ERR obfuscating small counts!")
            #print(df[c])
        cols2.append(c)
    print("Saving....")

    # Lowercase columnames, remove na values
    df=df[cols2].dropna(how='any',thresh=2).rename(columns=lambda x: x.lower())

    # Remove RAW values
    df = df[~df.c_name.str.contains("RAW_", na=False)]
    df = df.drop_duplicates()  # Bugfix, there seem to be a lot of dups

    # Compute sum column and return
    sum = df[df.columns[df.columns.str.contains("totalnum")]].sum(axis=1).apply(agg_val)
    sum.name = 'sum'
    df = pd.concat([df, sum], axis=1)

    # Make sure the axis is labeled!
    df = df.rename_axis('c_fullname')

    return df

def agg_val(tot):
    if tot > 0:
        if tot < 10:
            tot = ' (<10)'
        elif tot < 100:
            tot = ' (>' + str(round(tot, -1)) + ')'
        elif tot < 1000:
            tot = ' (>' + str(round(tot, -2)) + ')'
        else:
            tot = ' (>' + str(round(tot, -3)) + ')'
        return tot




def read_csv_multiformat(fname):
    encodings = ['ascii','utf-8','utf-16','windows-1250','windows-1252']
    delimiters = [',','\t']
    delim = 0
    enc = 0
    ok=False
    #df = pd.DataFrame()
    print(fname)
    while not ok:
        # No infinite loops
        if len(delimiters)<=delim and len(encodings)<=enc:
            break
        try:
            # Try it
            df = pd.read_csv(fname, encoding=encodings[enc], index_col=0, delimiter=delimiters[delim])
            ok=True
        except UnicodeError:
            print('got unicode error with %s , trying different encoding' % encodings[enc])
            enc=enc+1
        except pd.errors.ParserError as e:
            print(e)
            print('got error with delimiter %s, trying next...' % delimiters[delim])
            delim=delim+1
        else:
            print('opening the file with encoding %s , delimiter %s ' , encodings[enc] , delimiters[delim])
            break

    return df

"""    for e in encodings:
        try:
            print(fname)
            df = pd.read_csv(fname,encoding=e,index_col=0,delimiter=delimiters[delim])
#            print("CSV: " + len(df.columns))
        except UnicodeDecodeError:
            print('got unicode error with %s , trying different encoding' % e)
        except pd.errors.ParserError:
            try:
                print("Trying TSV format...")
                df = pd.read_csv(fname, encoding=e, index_col=0, delimiter='\t')
            except UnicodeError:
                print("still unicode error on %s " % e)
        else:
            print('opening the file with encoding:  %s ' % e)
            break
"""

if __name__ == "__main__":
#    convertXLS()
#    process2CSV()
    buildSum()