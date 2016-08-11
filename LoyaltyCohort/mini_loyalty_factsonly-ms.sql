
-- A really underpowered version of the LoyaltyCohort script by Griffin Weber, MD, PhD
-- Explores only no filter (except excluding facts prior to 1/1/10), and percent of patients in each percent of fact count by age and race decile (and those with at least one procedure in those ranges)
-- Outputs miniloyalty and fact_pcnt
-- Ignore table drop errors, I did not make them conditionals
-- By Jeff Klann, PhD 7/27/16 11pm

create table miniloyalty(filter char(10) primary key, numpatients int)
GO
delete from miniloyalty
GO

drop table #with_proc
GO

-- Count patients with procedures
select patient_num into #with_proc from observation_fact 
 where concept_cd in (select concept_cd from concept_dimension where (CONCEPT_PATH like '\PCORI\PROCEDURE\%' or concept_path like '\PPRO\%'))
 and start_date>='1/1/2010' group by PATIENT_NUM
GO

-- NO FILTER (except date)
insert into miniloyalty(filter, numpatients) select 'NONEobs' filter, count(distinct o.patient_num) numpatients from observation_fact o
 inner join patient_dimension p on p.patient_num=o.patient_num where o.start_date >= '1/1/2010'
 and concept_cd in (select concept_cd from concept_dimension where concept_path like '\P%') -- Should expand to \PCORI\ if your paths are standard
GO

drop table #miniloyalty_patient_facts
GO
-- Count total PCORI facts per patient
select 
    o.patient_num, count(*) num_facts
    into #miniloyalty_patient_facts
	from observation_fact o 
    inner join patient_dimension p on p.patient_num=o.patient_num
    inner join visit_dimension v on v.patient_num=o.patient_num -- Also only count patients with visits
	where concept_cd in (select concept_cd from concept_dimension where concept_path like '\P%') -- Should expand to \PCORI\ if your paths are standard
    and o.start_date>='1/1/2010'
	group by o.patient_num
GO
alter table #miniloyalty_patient_facts add primary key (patient_num)
GO

drop table fact_pcnt
GO
-- Count the patients & avg # facts by %
 select k,count(t.patient_num) p,count(p.patient_num) p_proc,avg(f) f into fact_pcnt 
       from (
            select patient_num, k, sum(f) f from
                (select patient_num, ntile(100) over (partition by a, s order by f, patient_num) k,f
                from (
                    select p.patient_num, floor(age_in_years_num/10) a, sex_cd s, isnull(f.num_facts,0) f
                    from patient_dimension p
                        inner join #miniloyalty_patient_facts f -- Inner join bc 0-fact patients are never included in transform
                            on p.patient_num = f.patient_num
                ) t
              ) t group by PATIENT_NUM,k
         ) t
            left join #with_proc p on p.patient_num=t.patient_num
        group by k order by k
GO

-- Characterize low fact count pts
select * into lowfact_dc from
(select vw2.c_name, k, avg(f) avg_fact_count, count(*) c from observation_fact f inner join pcornet_master_vw vw on vw.C_BASECODE=f.CONCEPT_CD inner join
    pcornet_master_vw vw2 on vw.C_PATH=vw2.C_FULLNAME inner join
(select patient_num, k, f from
(select patient_num, k, sum(f) f from
    (select patient_num, ntile(100) over (order by f, patient_num) k,f
    from (
        select p.patient_num, isnull(f.num_facts,0) f
        from patient_dimension p
            inner join #miniloyalty_patient_facts f -- Inner join bc 0-fact patients are never included in transform
                on p.patient_num = f.patient_num
    ) t
  ) t group by PATIENT_NUM,k) t where k<6) t on t.patient_num=f.patient_num group by k, vw2.c_name) t where c>=10 order by k asc, c desc
GO

select sum( p) from fact_pcnt
union all
select count(distinct patient_num) from #miniloyalty_patient_facts
union all
select count(distinct patient_num) from #with_proc

select * from miniloyalty
GO
select * from fact_pcnt
GO
select * from lowfact_dc order by k asc,avg_fact_count asc,c desc
GO
