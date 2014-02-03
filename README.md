Usage
=====

    find-lacking-hourly_generated_log.sh [-h] [-p FilenamePattern] [yyyy] [mm] [yyyy] [mm]

Options
-----------

### -h

Show usge and exit

### -p "FilenamePattern"

Pattern string of Path to search

"Filename Pattern" must be ...

 * `[path-to-dir/]*yyyy*mm*dd*hh*`
 * `[path-to-dir/]*yyyy*mm*dd*`

Only the first match each one is replaced with "year/month/day/hour"

Args
-----------

* yyyy
 * year(from,to)
* mm
 * month(from,to)
