# Alma configuration - Part 2

## Introduction

After following *Alma configuration - Part 1* (which creates an
Import Profile for a Digital profile-type) and running the
associated Import Profile job, you should have a collection
populated with bibliographic records which have *digital*
holdings. However, at the time of writing, only bibliographic
records with physical or electronic holdings will be exported
from Alma to Libraries Australia (and then to Trove).

The purpose of the instructions below is to add an electronic
holding (i.e. portfolio) to each bibliographic record so that
they will be automatically exported from Alma to Libraries
Australia.

The high-level steps are as follows.
1. Harvest bibliographic records and associated digital holdings
   from Equella into Alma via an (Alma OAI-PMH Remote-Digital)
   Import Profile.  The Equella OAI-PMH metadata is in Qualified
   Dublin Core format and is crosswalked into MARC during the Alma
   import process. The configuration is covered in
  [Alma configuration - Part 1](README_alma1.md).
2. Export MARC-XML bibliographic records from Alma to an
   institutional server via an (Alma FTP) Export Profile.
3. Import MARC-XML bibliographic records from the institutional
   server into Alma to create electronic holdings (i.e. portfolios)
   via an (Alma FTP Repository) Import Profile.


## Create an Import Profile for a Repository profile-type
- Alma/equella prerequisite: Follow the steps in
  [Alma configuration - Part 1](README_alma1.md)
- Alma prerequisite: Create an electronic collection,
  *Flinders Digital Theses* (FIXME: provide the configuration)
- Alma prerequisite: Create an export profile for thesis
  bibliographic records via FTP to an institutional server

## Steps
- Resources > Import: Manage Import Profiles
- Add new profile > Repository > Next
- Part 1 - Profile Details
  * Profile name: Electronic Thesis Collection - Step 3 - Import 2
  * Profile description: Load previously exported MARC-XML bib records to create portfolios for existing bib records
  * Originating system: [Equella - Flinders]
  * Import protocol: [FTP]
  * Physical source format: [XML]
  * Source format: [MARC21 Bibliographic]
  * Status: Active
  * File name patterns: -
  * Cross walk: [Uncheck]
  * Target format: MARC21 Bibliographic
- Part 2 - Normalization & Validation
  * Filter out the data using: -
  * Correct the data using: -
  * Handle invalid data using: MarcXML Bib Import
- Part 3 - Match Profile
  * Match Profile
    + Match by Serial / Non Serial: [Check]
    + Serial match method: [001 To MMS_ID Match Method]
    + Non Serial match method: [001 To MMS_ID Match Method]
  * Match Actions
    + Handling method: [Automatic]
    + Upon match: [Overlay]
    + Merge method: [Keep only old value]
    + Select Action - Allow bibliographic record deletion: -
    + Select Action - Do not override/merge a record with lower brief version: -
    + Select Action - Unlink bibliographic records from community zone: -
  * Automatic Multi-Branch Handling
    + Select Action - Disregard matches for bibliographic CZ linked records: -
    + Select Action - Disregard invalid/canceled system control number identifiers: -
    + Select Action - Prefer record with the same inventory type (electronic/physical): -
    + Select Action - Skip and do not import unresolved records: [Check]
  * Handle Record Redirection
    + Canceled record field: -
    + Canceled record subfield: -
    + Canceled record: [Delete]
    + Merge method: [Overlay all fields but local]
    + Update holdings call number: -
  * No Match
    + Upon no match: [Do Not Import]
- Part 4 - Set Management Tags
  * Suppress record/s from publish/delivery: -
  * Synchronize with OCLC: [Don't publish]
  * Synchronize with Libraries Australia: [Publish Bibliographic records]
  * Condition: [Unconditionally]
- Part 5 - Inventory Information
  * Inventory Operations: [Electronic]
  * E-Book Mapping
    + Delete/deactivate portfolios: [Uncheck]
    + Portfolio type: [Part of an electronic collection]
    + Electronic Collection: Flinders Digital Theses
    + Service: Full Text
    + Material type: Dissertation
    + Single portfolio: [Check]
    + Extract access URL from field/subfield: 856 u
    + Indicators to skip (use # for empty indicator): -
    + Extract internal description note from field/subfield: - -
    + Default internal description note: -
    + Extract authentication note from field/subfield: - -
    + Default authentication note: -
    + Extract public note from field/subfield: - -
    + Default public note: -
    + Extract library from field/subfield: - -
    + Default library: Central Library
    + License: -
    + Activate resource: [Check]

