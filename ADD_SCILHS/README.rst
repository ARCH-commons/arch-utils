This is the original README that was delivered with the Greater Plains Collaborative's version.
 
PCORI Annotated Data Dictionary
===============================

:Authors: Dan Connolly / Nathan Graham 
:Contact: http://informatics.kumc.edu/
:Copyright: Copyright (c) 2014 Univeristy of Kansas Medical Center
:License: MIT

The `Greater Plains Collaborative (GPC)`__, a PCORI__ CDRN, uses i2b2__ as its
core technology. PCORI has required the GPC to provide an 
`ETL Annotated Data Dictionary form`__.

__ https://informatics.gpcnetwork.org/
__ http://www.pcori.org/
__ https://www.i2b2.org/
__ https://informatics.gpcnetwork.org/trac/Project/ticket/144

This project leverages work by Dan Connolly and Jeffrey Klann to represent the 
`PCORNet Common Data Model (CDMV1.0)`__ as i2b2 terminology (see 
`pcornet-dm BitBucket repository`__).  

__ https://pcornet.centraldesktop.com/taskforces/folder/3609634/#folder:3844737
__ https://bitbucket.org/DanC/pcornet-dm

Relevant GPC Trac Tickets
-------------------------

* #144: `ETL Annotated Data Dictionary form required by PCORI`__
* #145: `Transform i2b2 query results to PCORNet CDM`__
* #146: `Map CDM-in-i2b2 to existing i2b2 data and/or ontologies`__
* #114: `Milestone 2.7 GPC harmonizes with PCORI CDM V1.0`__

__ https://informatics.gpcnetwork.org/trac/Project/ticket/144
__ https://informatics.gpcnetwork.org/trac/Project/ticket/145
__ https://informatics.gpcnetwork.org/trac/Project/ticket/146
__ https://informatics.gpcnetwork.org/trac/Project/ticket/114

Contents
--------

Core files for answering the questions in the ETL Annotated Data Dictionary
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

CDM_transform.sql
 - SQL to transform i2b2 query paths in to PCORI Common Data Model tables.

ETL_dict_queries.sql
 - SQL to query information for the ETL Annotated Data Dictionary.

heron_to_pcori.csv
 - Mapping from HERON i2b2 paths to CDM i2b2 paths.

"Helper" scripts
~~~~~~~~~~~~~~~~

heron_to_pcori_helper.sql
 - PostgreSQL SQL to help generate heron_to_pcori.csv.

Query/Spreadsheet Automation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A (mostly) successful attempt to fill in the PCORI Annotated Data Dictionary
automatically given a SQL file with specifically formatted queries and an 
Oracle connection to the i2b2 database.

Usage:

 .. code-block::

  populate_spreadsheet.py config.ini

See config.ini.example for configuration options and ETL_dict_queries.sql
for specifically formatted SQL.

populate_spreadsheet.py
 - Script that attempts to automatically fill in the relevant fields in
   the PCORI Annotated Data Dictionary spreadsheet "Data Summary" sheet.

config.ini.example
 - Example configuration file for populate_spreadsheet.py.

find_cells.py
 - Find relevant cells in the PCORI spreadsheet.  Not designed to be 
   used independently of populated_spreadsheet.py

query.py
 - Run queries against the CDM.  Not designed to be used independently 
   of populated_spreadsheet.py

requirements.txt
 - Python requirements for automatic population scripts.
