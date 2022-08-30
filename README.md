# r720-fanspeed
Dell PowerEdge r720 FanSpeed Controls via IPMI

Description:
------------
A CRON Task script to monitor CPU Temp's on the r720 and utilize the IPMI feature of Dell's iDRAC to adjust fan speeds based on preferred fan curves.  3 fan curves to start, Low/Normal/Hot are used based on the ambient temp at the inlet.  System uses 3 hysteresis values (1) for each curve to determine the degree of change in CPU Temp's before adjusting fan speeds.  Low curve uses a large degree of change, Normal uses a more nominal value and the Hot Fan Curve uses a more aggressive value.

History:
--------
I started out searching the interwebs for a method of controlling my r720's fan speeds,  I upgraded for a 8-Bay 2.5" Chassis that had no issues with iDRAC controlling fan speeds to a 16-Bay 2.5" Chassis that set the fan speeds to 100% no matter what I did.  The only difference was the new system uses a PERC h710 versus the PERC h310 in the 8 Bay chassis,  The NIC, HBA's, SSD's are all from the old system.

Features:
* Multiple Fan Curves (Low/Normal/Hot)
* Built in hysteresis
* Runs as a CRON task
* Soon(tm)

Do-To List:
* Soon(tm)
* Build in some type of logging, not sure how has this could potentially take up alot of space depending how ofter it runs.
* Switch from a CRON Task to a System Service)

Credits:<br>
Adapted from https://github.com/That-Guy-Jack/HP-ILO-Fan-Control/<br>
by jcx (https://jcx.life)<br>
Initial Dell iDRAC modification<br>
by jcx (https://jcx.life)<br>