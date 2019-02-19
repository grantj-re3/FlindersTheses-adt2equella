# Alma configuration - Part 3

## Contents

- *[Alma configuration - Part 1](README_alma1.md)*
- *[Alma configuration - Part 2](README_alma2.md)*
- *[Alma configuration - Part 3](README_alma3.md)* - this document


## Introduction

After following *[Alma configuration - Part 1](README_alma1.md)*
(which creates an
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
   *[Alma configuration - Part 1](README_alma1.md)*.
2. Export MARC-XML bibliographic records from Alma to an
   institutional server via an (Alma FTP) Publishing Profile.
   The configuration is covered in
   *[Alma configuration - Part 2](README_alma2.md)*.
3. Import MARC-XML bibliographic records from the institutional
   server into Alma to create electronic holdings (i.e. portfolios)
   via an (Alma FTP Repository) Import Profile.


## Create an Import Profile for a Repository profile-type
- Alma/equella prerequisite: Follow the steps in
  *[Alma configuration - Part 1](README_alma1.md)*
- Alma prerequisite: Create an electronic collection,
  *Flinders Digital Theses* (FIXME: provide the configuration)
- Alma prerequisite: Create an Publishing Profile for thesis
  bibliographic records via FTP to an institutional server
  by following the steps in *[Alma configuration - Part 2](README_alma2.md)*.

## Steps
- Resources > Import: Manage Import Profiles
- Add new profile > Repository > Next
- Part 1 - Profile Details
  * Profile name: Electronic Thesis Collection - Step 3 - Import 2
  * Profile description: Load previously exported MARC-XML bib records to create portfolios for existing bib records
  * Originating system: [Equella - Flinders] (FIXME: provide the configuration)
  * Import protocol: [FTP]
  * Physical source format: [XML]
  * Source format: [MARC21 Bibliographic]
  * Status: Active
  * File name patterns: -
  * Cross walk: [No]
  * Target format: MARC21 Bibliographic
  * Scheduling: As required
  * FTP Information: As required
  * Click Next
- Part 2 - Normalization & Validation
  * Filter: Filter out the data using: -
  * Normalization: Correct the data using: -
  * Validation Exception Profile: Handle invalid data using: MarcXML Bib Import
  * Click Next
- Part 3 - Match Profile
  * Match Profile
    + Match by Serial / Non Serial: [Yes]
    + Serial match method: [001 To MMS_ID Match Method]
    + Non Serial match method: [001 To MMS_ID Match Method]
  * Match Actions
    + Handling method: [Automatic]
    + Upon match: [Overlay]
    + Merge method: [Keep only old value]
    + Select Action - Allow bibliographic record deletion: -
    + Select Action - Do not override/merge a record with lower brief version: -
    + Select Action - Unlink bibliographic records from community zone: -
    + Do not override/ merge record with an older version: [Disabled]
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
  * Click Next
- Part 4 - Set Management Tags
  * Suppress record/s from publish/delivery: -
  * Synchronize with OCLC: [Don't publish]
  * Synchronize with Libraries Australia: [Publish Bibliographic records]
  * Condition: [Unconditionally]
  * Click Next
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
  * Click Save

