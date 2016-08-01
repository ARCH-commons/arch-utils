-----------------------------------------------------------------------------------------------------------------
-- Procedure to run totalnum counts on all tables in table_access that have a key like PCORI_
-- Depends on the TOTALNUM script at http://github.com/SCILHS-utils/totalnum , which must be run first
-----------------------------------------------------------------------------------------------------------------

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'RunTotalnum') AND type in (N'P', N'PC'))
DROP PROCEDURE RunTotalnum
GO

create procedure dbo.RunTotalnum as 

DECLARE @sqltext NVARCHAR(4000);
declare getsql cursor local for
select 'exec run_all_counts '+c_table_name
from TABLE_ACCESS where c_visualattributes like '%A%' and c_table_cd like 'PCORI%'

begin
OPEN getsql;
FETCH NEXT FROM getsql INTO @sqltext;
WHILE @@FETCH_STATUS = 0
BEGIN
	print @sqltext
	exec sp_executesql @sqltext
	FETCH NEXT FROM getsql INTO @sqltext;	
END

CLOSE getsql;
DEALLOCATE getsql;
end
