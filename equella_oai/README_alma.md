# Alma configuration


## Create an Import Profile for a Digital profile-type
- Equella prerequisite: Create an OAI-PMH data provider for Qualified Dublin Core, QDC (or Dublin Core, DC)
- Alma prerequisite: [Create a top level collection and sub-collection](#create-a-top-level-collection-and-sub-collection)
- Alma prerequisite: [Create normalization rules](#normalization-rules)
- Alma prerequisite: [Create a normalization rule process](#create-a-normalization-rule-process)
- Alma prerequisite: [Modify the linking parameter](#modify-the-linking-parameter)

## Steps
- Resource Management > Resource Configuration > Configuration Menu > Record Import > Import Profiles
- Add New Profile > Digital > Next
- Part 1 - Profile Details
  * Profile name: Electronic Thesis Collection
  * Profile description: Load QDC XML records from Equella OAI
  * Digital remote repository instance: Equella OAI Qualified DC Format
  * Import Protocol: OAI
  * Status: [Active]
  * OAI base URL: https://example.com/oai; Click "Connect and Edit"
  * Authentication: [Uncheck]
  * Metadata Prefix: Select oai_qdc_rhd
  * Set: Select XXXX
  * Harvest start date: Select earlier date if required
  * Click "Open test page" to verify first record
  * Click Next
- Part 2 - Normalization & Validation
  * Correct the data using: Select the normalization rule process (as per the prerequisite)
  * Handle invalid data using: [MarcXML Bib Import]
  * Click Next
- Part 3 - Match Profile
  * Serial match method: 035 (Other System Identifier) Match Method
  * Non Serial match method: 035 (Other System Identifier) Match Method
  * Handling method: [Automatic]
  * Upon match: Overlay
  * Merge method: [Overlay all fields but local]
  * ...
  * Upon no match: [Import]
  * Click Next
- Part 4 - Set Management Tags
  * Suppress record/s from publish/delivery: [Uncheck]
  * Synchronize with OCLC: [Don't publish]
  * Synchronize with Libraries Australia: Publish Bibliographic records
  * Click Next
- Part 5 - Inventory Information
  * Status: [Active]
  * Collection assignment: Electronic thesis collection (created as per the prerequisite)
  * Library: Main Library
  * IE Entity Type: [Generic Resource]
  * Click Save


## Create a top level collection and sub-collection

Create a top level collection:

- Resource Management > Create Inventory > Add Top Level Collection
  * Collection Title: Thesis collection
  * Description: Thesis collection
  * Collection Name: Thesis collection
  * External Id: -
  * External System: -
  * Library: Special Collections
  * Click "Save and continue" to create a sub-collection now or click "Save" to create a sub-collection later

Create a sub-collection:

- If you did not click "Save and continue" above, navigate to:
  Resource Management > Search and Sets > Top Level Collections.
  For the "Thesis collection" created above, click on "Edit Collection".
- In the Sub-collections tab, click Add Sub-collection.
  * Collection Title: Electronic thesis collection
  * Description: Electronic thesis collection
  * Collection Name: Electronic thesis collection
  * External Id: -
  * External System: -
  * Library: Special Collections (will inherit from the parent collection)
  * Click "Save and continue"


## Normalization rules

### Normalization rule for subject-discipline

Equella OAI-PMH delivers 2 types of subject metadata.

1. &lt;dc:subject>Barbeque&lt;/dc:subject> which maps to MARC 653$a.
2. &lt;dc:subject>Subject discipline:Cooking&lt;/dc:subject> which also maps
   to MARC 653$a, but the "Subject discipline:" prefix tells Alma that
   we want it to map to 695$a. We can achieve this mapping with the
   following Alma normalization rule.

```
rule "Equella thesis - move 653 to 695 if 653.a starts-with 'Subject discipline:'; Remove 'Subject discipline:'"
  when
    exists "024.a.flex-*"
  then
    changeField "653" to "695" if (exists "653.a.Subject discipline:*")
    replaceContents "695.a.Subject discipline:" with ""
end
```

### Normalization rule-file for adding 695.d

This rule must appear after the subject-discipline rule which creates 695.a

```
rule "Equella thesis - add 695.d.Doctorate"
  when
    (exists "024.a.flex-*") AND (exists "695.a.* thesis") AND (exists "655.a.Doctor of Philosophy|Professional Doctorate")
  then
    AddSubfield "695.d.Doctorate" if (not exists "695.d")
end

rule "Equella thesis - add 695.d.Masters"
  when
    (exists "024.a.flex-*") AND (exists "695.a.* thesis") AND (exists "655.a.Masters by Research|Masters by Coursework")
  then
    AddSubfield "695.d.Masters" if (not exists "695.d")
end
```

### Normalization rule for MARC Leader

```
rule "Equella thesis - fix LDR"
  when
    exists "024.a.flex-*"
  then
    ReplaceControlContents "LDR.{5,1}" with "n" if(existsControl "LDR.{5,1}. ")
    ReplaceControlContents "LDR.{20,1}" with "4" if(existsControl "LDR.{20,1}. ")
    ReplaceControlContents "LDR.{21,1}" with "5" if(existsControl "LDR.{21,1}. ")
    ReplaceControlContents "LDR.{22,1}" with "0" if(existsControl "LDR.{22,1}. ")
    ReplaceControlContents "LDR.{23,1}" with "0" if(existsControl "LDR.{23,1}. ")
end
```

### Normalization rule-file for 008

This rule is generated by the script alma_normrule_008.sh - an excerpt is given below.

```
rule "Equella thesis - Add 008 for year 1966"
  when
    (exists "024.a.flex-*") AND (not existsControl "008") AND (exists "260.c.1966")
  then
    addcontrolField "008.660101s1966    xra||||fsm||||000#||eng|d"
end

rule "Equella thesis - Add 008 for year 1967"
  when
    (exists "024.a.flex-*") AND (not existsControl "008") AND (exists "260.c.1967")
  then
    addcontrolField "008.670101s1967    xra||||fsm||||000#||eng|d"
end

...

rule "Equella thesis - Add 008 for year 2040"
  when
    (exists "024.a.flex-*") AND (not existsControl "008") AND (exists "260.c.2040")
  then
    addcontrolField "008.400101s2040    xra||||fsm||||000#||eng|d"
end
```

### Normalization rule for target URL

```
rule "Equella thesis - move 024.a to 856.u if 024.a is a hyperlink"
  when
    exists "024.a.flex-*"
  then
    changeField "024" to "856" if (exists "024.a.http://*")
    changeField "024" to "856" if (exists "024.a.https://*")
    changeSubField "856.a" to "u"
    changeFirstIndicator "856" to "4"
    changeSecondIndicator "856" to "1"
end
```

### Normalization rule for Projected Publication Date

```
rule "Equella thesis - move 307.a to 263.a"
  when
    exists "024.a.flex-*"
  then
    changeField "307" to "263" if (exists "307.a")
end
```

### Normalization rule to fix 655 indicators

```
rule "Equella thesis - fix 655 indicators"
  when
    exists "024.a.flex-*"
  then
    changeFirstIndicator  "655" to " " if (exists "655.a")
    changeSecondIndicator "655" to "4" if (exists "655.a")
    removeSubField "655.2" if (exists "655.a")
end
```


## Create a normalization rule process

These steps allow you to apply an ordered-set of normalization rules as a single job.

Steps:

- Resource Management > Resource Configuration > Configuration Menu > Cataloging > Metadata Configuration
- Profile: MARC21 Bibliographic > Normalization Processes tab
- Click "Add Process"
  * Part 1 - General Information tab
    - Profile name: Electronic Thesis Collection normalization
    - Profile description: Normalize Electronic Thesis Collection imported from Equella QDC OAI
    - Status: Active
    - Click Next
  * Part 2 - Task List tab
    - Select one or more processes from the Process List Pool section. Click "Add To Selection"
    - You can add more than one instance of the same process (eg. MarcDroolNormalization) to the Processes Selected section.
    - In the Processes Selected section, move processes as required (using up/down arrows)
    - Click Next
  * Part 3 - Task Parameters tab
    - For each Marc Drool Normalization entry, select a normalization rule via the Drools File Key list.
    - Click Save


## Modify the linking parameter

Allow Primo to link through to URLs in Equella

- Resource Management > Resource Configuration > Configuration Menu > Record Import > Remote Digital Repositories
- For Remote Repository Name "Equella OAI Qualified DC format", click Action > Edit
- Part 2 - Transformer Rules tab
  * Verify that Target Field "LinkingParameter1" is mapped to Source Field "header:identifier"
- Part 3 - Delivery tab
  * Repository Name: Equella Repository
  * Object Template: https://theses.flinders.edu.au/view/$$LinkingParameter1
  * Thumbnail Template: -

