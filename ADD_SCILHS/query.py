from collections import OrderedDict
#import cx_Oracle as cx # Please uncomment this if using Oracle
import datetime
import logging
import os
import re
import sqlparse
import sys
import pymssql


class mockLog(object):
    def p(self, s):
        print s

    def info(self, s):
        p(s)

    def debug(self, s):
        ps(s)


def get_queries(log, sqldata):
    ''' get_queries - return individual queries from sql.
    >>> log = mockLog()

    Make sure we get the statements back with comments removed.
    >>> q = """--start with comment
    ... /* This is a comment...with
    ...     more than one line. */
    ... with agg as ( -- Inline comment
    ... select count(*) denom from demographics
    ... ),
    ... breakdown as (--another comment
    ...  select sex, count(*) cnt
    ...  from demographics
    ...  group by sex
    ... )
    ... select breakdown.sex "Sex", breakdown.cnt "Count",
    ... round((breakdown.cnt / agg.denom) * 100) "Percent"
    ... from breakdown, agg;--srsly
    ...
    ... select * from some_other_table;"""
    >>> for query in get_queries(log, q):
    ...     print query
    ... # doctest: +NORMALIZE_WHITESPACE
    with agg as (
    select count(*) denom from demographics
    ),
    breakdown as (
     select sex, count(*) cnt
     from demographics
     group by sex
    )
    select breakdown.sex "Sex", breakdown.cnt "Count",
    round((breakdown.cnt / agg.denom) * 100) "Percent"
    from breakdown, agg
    <BLANKLINE>
    select * from some_other_table

    Make sure that destructive stuff throws an exception.
    >>> get_queries(log, """delete from important_table;""")
    Traceback (most recent call last):
    ...
    ValueError: Illegal token delete

    >>> get_queries(log, """insert into important_table
    ...                (col1, col2)
    ...                values('a', 'b')""")
    Traceback (most recent call last):
    ...
    ValueError: Illegal token insert

    >>> get_queries(log, """truncate table important_table""")
    Traceback (most recent call last):
    ...
    ValueError: Illegal token truncate
    '''
    def _allowed(token_list,
                 allowed_tok=((sqlparse.tokens.Keyword, 'with', False),
                              (sqlparse.tokens.Keyword, 'from', False),
                              (sqlparse.tokens.Keyword, 'order', False),
                              (sqlparse.tokens.Keyword, 'by', False),
                              (sqlparse.tokens.DML, 'select', False),
                              (sqlparse.tokens.Whitespace, '.*', True),
                              (sqlparse.tokens.Newline, '.*', True),
                              (sqlparse.tokens.Punctuation, '.*', True),
                              (sqlparse.tokens.Comment.Single, '.*', True),
                              (sqlparse.tokens.Wildcard, '.*', True))):
        ''' Make sure we're not doing anything destructive.
        '''
        for token in token_list:
            for allowedt in allowed_tok:
                if token.match(*allowedt):
                    break
            else:
                if(not isinstance(token, sqlparse.sql.IdentifierList) and
                   not isinstance(token, sqlparse.sql.Identifier) and
                   not isinstance(token, sqlparse.sql.Where) and
                   not isinstance(token, sqlparse.sql.Parenthesis) and
                   not (str(token.value).startswith("'") and str(token.value).endswith("'")) and #jgk - added to clumsily handle literal string
                   not (isinstance(token, sqlparse.sql.Function) and
                        (str(token.value).startswith('count') or
                        str(token.value).startswith('round')))):
                    # Useful for debug: import pdb; pdb.set_trace()
                    raise ValueError('Illegal token %s' % token)

    statements = sqlparse.split(sqldata)
    queries = list()
    for stmt in statements:
        if len(stmt) > 0:
            # For each statement, tokenize and make sure it's allowed
            parsed = sqlparse.parse(stmt)[0]
            toks = [t for t in parsed.tokens
                    if not isinstance(t, sqlparse.sql.Comment)]
            _allowed(toks)
            # Then, put the query back together again
            query = ''.join([str(t)
                             for t in toks]).replace(';', '').strip() + '\n'
            # For some reason, I couldn't get inline comments out with sqlparse
            for comment in re.findall('.*?(--.*?)\n', query):
                query = query.replace(comment, '')
            queries.append(query.strip().strip('\n'))
    return queries


def run_file_queries(log, sqlfile_data, host, port, sid, db_type, user, passwd):
    ''' Return a list of dictionaries of all results of running all the
    queries in the given file.
    '''
    queries = get_queries(log, sqlfile_data)
    results = list()

    # jgk: Added MSSQL option
    if db_type<>'MSSQL':
        dsn = cx.makedsn(host, int(port), sid)
        conn = cx.connect(user=user,
	                      password=passwd,
	                      dsn=dsn)
        cur = conn.cursor()
    else:
        conn = pymssql.connect(host=host, user=user, password=passwd, database=sid)
        cur = conn.cursor()
    
    for query in queries:
        log.info('Executing:\n%s\n' % query)
        cur.execute(query)
        # Make a list of dictionaries: [{col_name:value_from_db},...]
        qr = map(lambda row:
                 OrderedDict(zip([d[0]
                                  for d in cur.description], row)),
                 [v for v in cur.fetchall()])
        log.info('Query result:\n%s' % qr)
        results.append(qr)
    return results


def collapse_2dlist(list2d):
    '''
    >>> collapse_2dlist([[1,2], [3,4]])
    [1, 2, 3, 4]
    '''
    return [j for i in list2d for j in i]


def keyed_results(log, results):
    ''' Assumes that the key "SECTION" exists
    >>> log = mockLog()
    >>> print keyed_results(log, [[OrderedDict([
    ...       ('SECTION', 'Demographics'),
    ...       ('Unique PATIDs', 726)])]])
    ... # doctest: +NORMALIZE_WHITESPACE
    {'Demographics.Unique PATIDs': '726'}

    >>> print keyed_results(log, [[OrderedDict([
    ...    ('SECTION', 'Demographics'),
    ...    ('Minimum BIRTH_DATE', datetime.datetime(1877, 9, 19, 0, 0)),
    ...    ('Maximum BIRTH_DATE', datetime.datetime(2012, 2, 20, 0, 0))])]])
    ... # doctest: +NORMALIZE_WHITESPACE
    {'Demographics.Minimum BIRTH_DATE': '1877-09-19 00:00:00',
    'Demographics.Maximum BIRTH_DATE': '2012-02-20 00:00:00'}

    >>> print keyed_results(log, [[OrderedDict([
    ...                            ('SECTION', 'Demographics'),
    ...                            ('Sex', 'F'),
    ...                            ('Count', 377),
    ...                            ('Percent', 52)]),
    ...                            OrderedDict([
    ...                            ('SECTION', 'Demographics'),
    ...                            ('Sex', 'M'),
    ...                            ('Count', 346),
    ...                            ('Percent', 48)])]])
    ... # doctest: +NORMALIZE_WHITESPACE
    {'Demographics.Sex.M.Count': '346',
     'Demographics.Sex.M.Percent': '48',
     'Demographics.Sex.F.Percent': '52',
     'Demographics.Sex.F.Count': '377'}
    '''
    all_results = list()
    for qres in results:
        for fields in qres:
            keys = fields.keys()
            assert(keys[0].upper() == 'SECTION') # jgk - added upper for sqlserver script
            section = fields[keys[0]]
            if len(keys) < 4:
                start = 1
            else:
                section = '.'.join([section, keys[1], str(fields[keys[1]])])
                start = 2

            for i in range(start, len(keys)):
                res = ('.'.join([section, keys[i]]), str(fields[keys[i]]))
                all_results.append(res)

    return dict(all_results)

if __name__ == '__main__':
    log = logging.getLogger(__name__)
    logging.basicConfig(level=logging.DEBUG)

    sqlfile, host, port, sid, user_env, passwd_env = sys.argv[1:7]
    with open(sqlfile, 'r') as f:
        sqldata = f.read()

    user, passwd = (os.environ[user_env], os.environ[passwd_env])

    # Print the results for now
    log.info(keyed_results(log,
                           run_file_queries(log, sqldata, host, port,
                                            sid, user, passwd)))