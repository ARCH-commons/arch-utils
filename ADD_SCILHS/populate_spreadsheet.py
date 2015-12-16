from ConfigParser import SafeConfigParser
from find_cells import update_xls
from query import run_file_queries, keyed_results
import datetime
import logging
import os
import sys

if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO,
                        format='%(asctime)s %(name)-12s %(levelname)-8s '
                        '%(message)s',
                        filename='populate_spreadsheet_%s.log' %
                        datetime.datetime.now().strftime('%Y-%m-%d'))
    log = logging.getLogger()

    # Log to the console also, without timestamps
    console = logging.StreamHandler()
    formatter = logging.Formatter('%(name)-12s: %(levelname)-8s %(message)s')
    console.setFormatter(formatter)
    log.addHandler(console)

    # Parse options
    config_file = sys.argv[1]
    opts = SafeConfigParser()
    opts.read(config_file)
    db_opts = dict(opts.items('database'))
    sheet_opts = dict(opts.items('spreadsheet'))
    query_opts = dict(opts.items('queries'))

    log.debug('%s\n%s\n%s' % (db_opts, sheet_opts, query_opts))

    # Get the queries from sql file
    with open(query_opts['sql_file'], 'r') as f:
        sql_data = f.read()

    # Get query results - jgk: added db_type opt
    db_results = keyed_results(
        log, run_file_queries(log, sql_data, db_opts['host'],
                              db_opts['port'], db_opts['sid'], db_opts['db_type'],
                              os.environ[db_opts['user_env']],
                              os.environ[db_opts['pass_env']]))

    log.debug('Found the following keys in the database:\n%s'
              % sorted(db_results.keys()))

    # Update the spreadsheet
    update_xls(log, sheet_opts['input'], sheet_opts['output'],
               keyed_values=db_results)