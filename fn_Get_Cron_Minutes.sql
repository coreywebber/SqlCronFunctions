CREATE FUNCTION dbo.fn_Get_Scheduled_Minutes 
(
    @STRING VARCHAR (255)
) 
RETURNS TABLE
WITH SCHEMABINDING
AS 
RETURN
/*
    Corey:  This is a base query everything is based off of, here we are splitting the 
            field by comma, the high form of split, also if there was a '*' I am converting 
            them to this objects default answer
*/
WITH PARSE_COMMA AS 
(
    SELECT 
        [value]     = CASE WHEN [value] = '*' THEN '0-59/1' ELSE [value] END,
        [type]      = CASE 
                        WHEN [value] LIKE '*' THEN 'R' 
                        WHEN [value] LIKE '%-%' THEN 'R' 
                        ELSE 'V' 
                      END
    FROM STRING_SPLIT(@STRING, ',')
),
/*
    Corey:  This returns on the "striaght" value answers
*/
PARSE_VALUES AS 
(
    SELECT [value]
    FROM PARSE_COMMA
    WHERE [type] = 'V'
),
PARSE_RANGES AS 
(
    SELECT
        VAL_STRING      = S.VAL_STRING,
        VAL_RANGE       = S.VAL_RANGE,
        VAL_INTERVAL    = S.VAL_INTERVAL,
        S.[value]
    FROM
    (
        SELECT 
            ROW_NUMBER() OVER (PARTITION BY (SELECT 1) ORDER BY (SELECT 1)) AS ROW_NUM,
            R.VAL_STRING, R.VAL_RANGE, R.VAL_INTERVAL,
            H.[value]
        FROM 
            (
                VALUES 
                (0),  (1),  (2),  (3),  (4),  (5),  (6),  (7),  (8),  (9), 
                (10), (11), (12), (13), (14), (15), (16), (17), (18), (19),
                (20), (21), (22), (23), (24), (25), (26), (27), (28), (29),
                (30), (31), (32), (33), (34), (35), (36), (37), (38), (39),
                (40), (41), (42), (43), (44), (45), (46), (47), (48), (49),
                (50), (51), (52), (53), (54), (55), (56), (57), (58), (59)
            ) AS H(value)
            CROSS APPLY
            (
                SELECT 
                    VAL_STRING              = P.VAL_STRING,
                    VAL_RANGE               = P.VAL_RANGE,
                    VAL_INTERVAL            = P.VAL_INTERVAL,
                    LOW                     = CONVERT(TINYINT, P.[1]),
                    HIGH                    = CONVERT(TINYINT, P.[2])
                FROM
                (
                    SELECT
                        S.VAL_STRING, S.VAL_RANGE, S.VAL_INTERVAL,
                        ROW_NUMBER() OVER (PARTITION BY S.VAL_STRING, S.VAL_RANGE ORDER BY CONVERT(INT, S.[value]) ASC) AS ROW_NUM,
                        S.[value]
                    FROM
                    (
                        SELECT S.[value], r.VAL_STRING, R.VAL_RANGE, R.VAL_INTERVAL
                        FROM 
                            (
                                /*
                                    Corey:  This returns the range an intervals (or default intervals) for the
                                            field, we are going to type cast here as well.
                                */
                                SELECT 
                                    VAL_STRING      = P.S_VAL,
                                    VAL_RANGE       = P.[1],
                                    VAL_INTERVAL    = ISNULL(
                                                        CASE 
                                                            WHEN CONVERT(TINYINT, P.[2]) < 1 THEN 1
                                                            /*Check to see if Interval will be 0*/
                                                            WHEN (CONVERT(TINYINT, P.[2]) % 60) = 0 THEN 1
                                                            /*Cover all bases, if we go higher then 59, mod will over the issue*/
                                                            ELSE CONVERT(TINYINT, P.[2]) % 60
                                                        END, 1)
                                FROM 
                                (
                                    /*
                                        Corey:  Applying Row Count to splits, by parent
                                    */
                                    SELECT 
                                        ROW_NUMBER() OVER (PARTITION BY S.[value] ORDER BY (SELECT 1)) AS ROW_NUM,
                                        S.[value] AS S_VAL,
                                        I.[value] AS I_VAL
                                    FROM 
                                        PARSE_COMMA AS S
                                        CROSS APPLY STRING_SPLIT(S.[value], '/') AS I
                                    WHERE [type] = 'R'
                                ) AS S
                                PIVOT
                                (
                                    MAX(S.I_VAL)
                                    FOR ROW_NUM
                                    IN ( [1], [2] )
                                ) AS P
                            ) AS R 
                            CROSS APPLY STRING_SPLIT(R.VAL_RANGE, '-') AS S
                    ) AS S
                ) AS S 
                PIVOT
                (
                    MAX(S.VALUE)
                    FOR S.ROW_NUM
                    IN ( [1], [2] )
                ) AS P
            ) AS R
        WHERE H.[value] BETWEEN R.LOW AND R.HIGH
    ) AS S
    /*
        Corey:  I am applying the interval calulation by using MOD, check for 1, flip to 0
    */
    WHERE (S.ROW_NUM % S.VAL_INTERVAL)  = CASE WHEN S.VAL_INTERVAL = 1 THEN 0 ELSE 1 END
)
SELECT DISTINCT 
    COALESCE(S.[value], P.[value]) AS [Minutes]
FROM 
    PARSE_VALUES AS S 
    FULL JOIN PARSE_RANGES AS P ON P.[value] = S.[value]
