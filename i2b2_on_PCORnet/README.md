# i2b2-on-PCORnet
## Version 0.1, January 2018
## by Jeff Klann, PhD and Matthew Joss

Here find the scripts to create the star-schema view and make the metadata updates to run i2b2 against a PCORnet database, in both MSSQL and Postgres format.

1. Install i2b2 1.7.09 or later 
2. Load the [ARCH PCORnet ontology](https://github.com/ARCH-commons/arch-ontology) into the metadata schema.
3. Create your pcornet dataset in the CRC schema.
4. Run the create-star-schema script from the CRC schema.
5. Run the metadata-update script from the metadata schema.
