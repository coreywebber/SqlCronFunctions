# Sql Server Cron Functions

These are a series of functions I use to interpret the CRON parameters and produce a table with their values.

```CRON
Format Value: #
Format List: #,#,#
Format Range: ##-##
Format Range with Interval:  ##-##/#
```

- **fn_Get_Cron_Minutes** - Get the list of minute
- **fn_Get_Cron_Hours** - Get the list of hours
- **fn_Get_Cron_DaysOfWeek** - Get the list of days of the week
- **fn_Get_Cron_DaysOfMonth** - Get the list of day of the month
- **fn_Get_Cron_Months** - Get the list of months
- **fn_Get_Cron_Years** - Get the list of years
