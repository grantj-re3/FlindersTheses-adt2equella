# Alma configuration


## Create an Import Profile for a Digital profile-type
- Equella prerequisite: Create an OAI-PMH data provider for Qualified Dublin Core, QDC (or Dublin Core, DC)
- Alma prerequisite: [Create a top level collection and sub-collection](#create-a-top-level-collection-and-sub-collection)
- Alma prerequisite: [Create normalization rules](#normalization-rules)
- Alma prerequisite: [Create a normalization rule process](#create-a-normalization-rule-process)

## Steps
- Resource Management > Resource Configuration > Configuration Menu > Record Import > Import Profiles
- Add New Profile > Digital > Next
- Part 1
  * Profile name
  * Profile description
  * Digital remote repository instance: Equella OAI Qualified DC Format
  * Import Protocol: OAI
  * Status: [Active]
  * OAI base URL: https://example.com/oai; Click "Connect and Edit"
  * Metadata Prefix: Select XXXX
  * Set: Select XXXX
  * Harvest start date: Select earlier date if required
  * Click "Open test page" to verify first record
  * Click Next
- Part 2
  * Correct the data using: Select the normalization rule process (as per the prerequisite)
  * Handle invalid data using: [MarcXML Bib Import]
  * Click Next
- Part 3
  * Serial match method: 035 (Other System Identifier) Match Method
  * Non Serial match method: 035 (Other System Identifier) Match Method
  * Handling method: [Automatic]
  * Upon match: Overlay
  * Merge method: [Overlay all fields but local]
  * ...
  * Upon no match: [Import]
  * Click Next
- Part 4
  * Leave defaults
  * Click Next
- Part 5
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
  * Library: Main Library
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
  * Library: Main Library (will inherit from the parent collection)
  * Click "Save and continue"


## Create a normalization rule process

These steps allow you to apply an ordered-set of normalization rules as a single job.

Steps:

- Resource Management > Resource Configuration > Configuration Menu > Cataloging > Metadata Configuration
- Profile: MARC21 Bibliographic > Normalization Processes tab
- Click "Add Process"
  * General Information tab
    - Profile name
    - Profile description
    - Status: Active
  * Task List tab
    - Select one or more processes from the Process List Pool section. Click "Add To Selection"
    - You can add more than one instance of the same process (eg. MarcDroolNormalization) to the Processes Selected section.
    - In the Processes Selected section, move processes as required (using up/down arrows)
  * Task Parameters tab
    - For each Marc Drool Normalization entry, select a normalization rule via the Drools File Key list.
  * Click Save


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
    addSubField "856.z.My electronic location - public note (Norm Rule in Alma)."
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

