# Alma configuration - Part 2

## Contents

- *[Alma configuration - Part 1](README_alma1.md)*
- *[Alma configuration - Part 2](README_alma2.md)* - this document
- *[Alma configuration - Part 3](README_alma3.md)*


## Introduction

After following *[Alma configuration - Part 1](README_alma1.md)*
(which creates an
Import Profile for a Digital profile-type) and running the
associated Import Profile job, you should have a collection
populated with bibliographic records which have *digital*
holdings. However, at the time of writing, only bibliographic
records with physical or electronic holdings will be exported
from Alma to Libraries Australia (and then to Trove).

The purpose of these instructions is to add an electronic
holding (i.e. portfolio) to each bibliographic record so that
they will be automatically exported from Alma to Libraries
Australia.

The high-level steps are as follows.
1. Harvest bibliographic records and associated digital holdings
   from Equella into Alma via an (Alma OAI-PMH Remote-Digital)
   Import Profile.  The Equella OAI-PMH metadata is in Qualified
   Dublin Core format and is crosswalked into MARC during the Alma
   import process. The configuration is covered in
   *[Alma configuration - Part 1](README_alma1.md)*.
2. Export MARC-XML bibliographic records from Alma to an
   institutional server via a Publishing Profile.
3. Import MARC-XML bibliographic records from the institutional
   server into Alma to create electronic holdings (i.e. portfolios)
   via an (Alma FTP Repository) Import Profile.
   The configuration is covered in
   *[Alma configuration - Part 3](README_alma3.md)*.

The purpose of this document is to describe the Publishing Profile.


## Create a Publishing Profile - Steps

- Resources > Publishing: Publishing Profiles
- Add Profile > General Profile
- Page 1 - Profile Details:
  * Profile Details:
    + Content Type: Bibliographic
    + Profile Name: Electronic Thesis Collection - step 2 - Export
    + Profile Description: Export electronic theses to the Flinders data-exchange server. In preparation for an import which adds portfolios.
  * Publishing Parameters:
    + Status: Active
    + Scheduling: Every day at 01:30
    + Publishing Mode: Incremental
    + Email notifications: [As required]
  * Content:
    + Set name: Equella digital thesis set
    + Filter records: -
    + Publish on: Bibliographic level
    + Output format: MARC21 Bibliographic
  * Publishing protocol:
    + FTP
    + FTP configuration: [The institutional Linux exchange server]
    + Sub-directory: ethesis/from_alma
    + Disable file compression: -
    + Compressed file extension: tar.gz
    + Physical format: XML
    + Number of records in file: 1000
    + Use default file name: Yes
    + Thesis_bibs
    + OAI: -
    + Z39.50: -
  * Click Next
- Page 2 - Data Enrichment:
  * All fields are blank (ie. no normalization rules nor other enrichment)
  * Click Save


## Processing bibliographic records on the institutional Linux exchange server

After exporting bibliographic records from Alma to the institutional
Linux "exchange server" and before importing them back into Alma via a
Repository Import Profile, the files need to be unzipped. You may
also wish to archive them for a few weeks or months. A Linux shell
script which performs both actions and which can be run via a
cron-job can be found [here](linux_exchange_server/bin/thesis_import_prep.sh).

**Note:** Despite the above *Publishing protocol* showing the option
*Disable file compression*, at the time of writing it did not appear
to permit file compression to be disabled. In addition, the Repository
Import Profile did not import tar.gz compressed files. Hence the
unzip cron-job was needed.

