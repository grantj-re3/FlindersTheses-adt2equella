Equella thesis-type attributes
==============================

## New node xml/item/curriculum/thesis/@collection_type

OAI-PMH XSLT is **not** expected to use this node. Has values:

- RHD
- Coursework
- Online by request
- perhaps in future: Honours

## New node xml/item/curriculum/thesis/@selected_type

Values were previously in @type (for original RHD collection).
OAI-PMH XSLT is **not** expected to use this node.

- In RHD collection, the values are:
  * Doctor of Philosophy
  * Professional Doctorate
  * Masters by Research
- In Coursework collection, the values are:
  * EdD commenced before 2014
  * DrPH commenced before 2013
  * Masters Degree
  * Graduate Diploma
  * Graduate Certificate
- In future there may also be an Honours collection.

## Changed node xml/item/curriculum/thesis/@type

Has values:
- Doctor of Philosophy
- Professional Doctorate
- Masters
- Graduate Diploma
- Graduate Certificate
- Honours (not currently in use)

## New node xml/item/curriculum/thesis/@degree_ type

Has values:
- Research Higher Degree
- Coursework
- Honours

## New node xml/item/curriculum/thesis/@marc_ type

Derived from @type above.
Expected use in MARC 655$a and 695$d.
Has values:
- Doctorate (for Doctor of Philosophy, Professional Doctorate)
- Masters
- Diploma (for Graduate Diploma, Graduate Certificate)
- Honours

