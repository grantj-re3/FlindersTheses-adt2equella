# Alma configuration


## Create an Import Profile for a Digital profile-type
- Prerequisite: In Equella, create an OAI-PMH data provider for Qualified Dublin Core, QDC (or Dublin Core, DC)
- Prerequisite: Create a top level collection and sub-collection
- Optional: [Create a normalization rule for subject-discipline](#create-a-normalization-rule-for-subject-discipline)

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
  * Correct the data using: Select the normalization rule set
  * Handle invalid data using: [MarcXML Bib Import]
  * Click Next
- Part 3
  * Serial match method: 035 (Other System Identifier) Match Method
  * Non Serial match method: 035 (Other System Identifier) Match Method
  * Handling method: [Automatic]
  * Upon match: Overlay
  * Merge method: [Overlay all fields but local]
  * ...
  * Upon no match: \[Import\]
  * Click Next
- Part 4
  * Leave defaults
  * Click Next
- Part 5
  * Status: [Active]
  * Collection assignment: Select a top level collection or sub-collection
  * Library: Main Library
  * IE Entity Type: [Generic Resource]
  * Click Save

## Create a normalization rule for subject-discipline

Equella OAI-PMH delivers 2 types of subject metadata.

1. &lt;dc:subject>Barbeque&lt;/dc:subject> which maps to MARC 653$a.
2. &lt;dc:subject>Subject discipline:Cooking&lt;/dc:subject> which also maps
   to MARC 653$a, but the "Subject discipline:" prefix tells Alma that
   we want it to map to 695$a. We can achieve this mapping with the
   following Alma normalization rule.

```
  rule "Move 653 to 695 if 653.a starts-with 'Subject discipline:'; Remove 'Subject discipline:'"
    when
      (TRUE)
    then
      changeField "653" to "695" if (exists "653.a.Subject discipline:*")
      replaceContents "695.a.Subject discipline:" with ""
  end
```

## Create a normalization rule for ...

```
  rule "Equella Research Higher Degree thesis - fix LDR"
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

