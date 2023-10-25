  CREATE OR ALTER FUNCTION [dbo].[fn_GetTotalWorkingDaysUsingLoop]
      (@DateFrom DATE,
      @DateTo   DATE
      )
      RETURNS INT
      AS
          BEGIN
              DECLARE @TotWorkingDays INT= 0;
              WHILE @DateFrom <= @DateTo
                  BEGIN
                      IF DATENAME(WEEKDAY, @DateFrom) IN('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday')
                          BEGIN
                              SET @TotWorkingDays = @TotWorkingDays + 1;
                      END;
                      SET @DateFrom = DATEADD(DAY, 1, @DateFrom);
                  END;
              RETURN @TotWorkingDays;
          END;
      GO
-- prevent set or regional settings from interfering with 
-- interpretation of dates / literals
SET DATEFIRST  7, -- 1 = Monday, 7 = Sunday
    DATEFORMAT ymd, 
    LANGUAGE   US_ENGLISH;
-- assume the above is here in all subsequent code blocks.


DECLARE @StartDate  date = '20100101';

DECLARE @CutoffDate date = DATEADD(DAY, -1, DATEADD(YEAR, 30, @StartDate));

;WITH seq(n) AS 
(
  SELECT 0 UNION ALL SELECT n + 1 FROM seq
  WHERE n < DATEDIFF(DAY, @StartDate, @CutoffDate)
),
d(d) AS 
(
  SELECT DATEADD(DAY, n, @StartDate) FROM seq
),
src AS
(
  SELECT
    the_date         = CONVERT(date, d),
    the_day          = DATEPART(DAY,       d),
    the_day_of_week    = DATEPART(WEEKDAY,   d),    
    the_day_name      = DATENAME(WEEKDAY,   d),
    the_week         = DATEPART(WEEK,      d),
    the_iso_week      = DATEPART(ISO_WEEK,  d),
    the_month        = DATEPART(MONTH,     d),
    the_month_name    = DATENAME(MONTH,     d),
    the_quarter      = DATEPART(Quarter,   d),
    the_year         = DATEPART(YEAR,      d),
    the_first_of_month = DATEFROMPARTS(YEAR(d), MONTH(d), 1),
    the_last_of_year   = DATEFROMPARTS(YEAR(d), 12, 31),
    the_day_of_year    = CAST(DATEPART(DAYOFYEAR, d) AS INT)

  FROM d
), dim AS (
    SELECT *
    FROM src
)
insert into calendar
SELECT 
    the_date,
    the_day,
    is_weekend           = CASE WHEN the_day_of_week IN (CASE @@DATEFIRST WHEN 1 THEN 6 WHEN 7 THEN 1 END,7) 
                            THEN 'TRUE' ELSE 'FALSE' END,       
    is_working_day           = CASE WHEN the_day_of_week IN (CASE @@DATEFIRST WHEN 1 THEN 6 WHEN 7 THEN 1 END,7) 
                            THEN 'FALSE' ELSE 'TRUE' END,       
    the_day_name,
    the_week,
    the_iso_week,
    the_month,
    the_month_name,
    the_month_working_day = 0,
    the_quarter,
    the_year,
    the_year_working_day = 0,
    the_first_of_month,
    the_last_of_year,
    the_day_of_year,
    the_day_of_week
FROM dim
  ORDER BY the_date
  OPTION (MAXRECURSION 0);

