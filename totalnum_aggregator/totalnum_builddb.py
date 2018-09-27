import datetime as dt
import sqlite3
from os import listdir

import numpy as np
import pandas as pd

import totalnum_aggregator.totalnum_tools as totpkg

# Load totalnum reports into a SQLite3 db, as an aggregated ontology table (bigtotalnum) and a "totalnum fact" table (totalnum)
# All files must be named "joined_MMYY.csv" format, with columns [c_fulllname, c_name, totalnum_*]
# By Jeff Klann, PhD 09-2018

basedir = "/Users/jklann/Google Drive/SCILHS Phase II/Committee, Cores, Panels/Informatics & Technology Core/totalnums/joined"
conn = sqlite3.connect(basedir + '/totalnums.db')


def buildDb():
    files = [f for f in listdir(basedir) if ".csv" in f[-4:] and 'joined' in f]
    files = sorted(files,key=lambda x: dt.datetime.strptime(x[7:11],'%m%y'))
    totals = []
    totals_f= []
    tots_dfm = pd.DataFrame()
    # Load the files
    for f in files:
        print(f)
        tot = totpkg.Totalnum()
        tot.init(basedir+'/',f,minimal=True)
        tot.dfm = tot.totalnum_melt(tot.df)
        totals.append(tot)
        totals_f.append(f[7:11])

    # Build the master fullname index
    bigfullname = None
    for x,t in enumerate(totals):
        if bigfullname is None:
            bigfullname=t.df.c_name
        else:
            bigfullname = t.df.join(bigfullname,how='outer',rsuffix='_'+totals_f[x][-4:])
            bigfullname=bigfullname[[x for x in filter(lambda x:'c_name' in x, bigfullname.columns.tolist())]]
            bigfullname = bigfullname.apply(lambda x: x[0] if isinstance(x[0],str) else x[1], axis=1).rename('c_name') # Why is this so slow?
        print(len(bigfullname))
    bigfullname=bigfullname.to_frame('c_name').rename_axis('c_fullname')

    # Add c_hlevel, domain, and fullname_int columns
    bigfullname.insert(1, "c_hlevel", [x.count("\\") for x in bigfullname.index])
    bigfullname.insert(1, "domain", [x.split('\\')[2] if "PCORI_MOD" not in x else "MODIFIER" for x in bigfullname.index])
    bigfullname['fullname_int']=range(0,len(bigfullname))
    bigfullname.to_sql('bigfullname',conn,if_exists='replace')
    #bigfullname.to_csv(basedir + '/bigfullname.csv')

    # Gather the individual totals
    delish = None
    for x, v in enumerate(totals_f):
        refresh_date = v[:-2]+v[2:] # Reverse the indices so numerically 02-2017 is before 01-2018
        print(refresh_date)

        # Add refresh date gleaned on load
        if 'refresh_date' not in totals[x].dfm.columns:
            totals[x].dfm.insert(0, 'refresh_date', refresh_date)

        # Remove zeros and nulls
        z = totals[x].dfm.replace(0, np.nan)
        z = z.dropna(how='any', subset=['c'])

        if delish is not None:
            delish = delish.append(z)
        else:
            delish = z

    # Shrink the frame (remove c_name and fullname and hlevel and domain and add just the fullname_int)
    outdf = delish.join(bigfullname,rsuffix='_bf',how='inner').reset_index()[['fullname_int','refresh_date','site','c']]
    #outdf.to_csv(basedir + '/all_refreshes.csv')
    print("Writing SQL...")
    outdf.to_sql("totalnums",conn,if_exists='replace')

    # Add indexes
    cur = conn.cursor()
    cur.execute("CREATE INDEX bfn_0 on bigfullname(c_hlevel)")
    cur.execute("CREATE INDEX bfn_int on bigfullname(fullname_int)")
    cur.execute("CREATE INDEX tot_int on totalnums(fullname_int)")

if __name__=='__main__':
    buildDb()