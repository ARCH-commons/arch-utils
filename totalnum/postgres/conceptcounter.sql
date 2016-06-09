-- Simple concept count procedure, v1.0 Postgres.
-- Not as efficient as the totalnum script adapted from Griffin Weber, but more portable across RDBMS platforms.
-- UNTESTED on large databases!
-- Usage: eg "select conceptct('pcornet_med')"
-- Jeff Klann, PhD
CREATE OR REPLACE FUNCTION conceptct(tablename VARCHAR(70)) 
RETURNS void AS $$
DECLARE
stmt text;
BEGIN

stmt := 'create table conceptCountOnt as select C_FULLNAME, C_BASECODE from '||tablename||' where 
   lower(c_facttablecolumn) = ''concept_cd''
		and lower(c_tablename) = ''concept_dimension''
		and lower(c_columnname) = ''concept_path''
		and upper(c_synonym_cd) = ''N''
		and upper(c_columndatatype) = ''T''
		and upper(c_operator) = ''LIKE''
		and m_applied_path = ''@''
        and c_basecode in (select concept_cd from observation_fact);';

--drop table conceptcountont;
--drop table conceptpath;

EXECUTE  stmt;


create temporary table ConceptPath as
select  a.c_fullname, count(distinct patient_num) c
	from conceptCountOnt a
		inner join conceptCountOnt b
			on b.c_fullname like a.c_fullname||'%' escape '&'
        inner join observation_fact f
            on b.c_basecode=f.concept_cd
         group by a.c_fullname;

update pcornet_med o set c_totalnum=(select c from ConceptPath p where o.c_fullname=p.c_fullname and c_synonym_cd='N');

drop table ConceptPath;
drop table conceptCountOnt;

 END;
    $$ LANGUAGE plpgsql;