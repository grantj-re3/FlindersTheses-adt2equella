<?xml version="1.0"?>
<!--
     Copyright (c) 2015, Flinders University, South Australia. All rights reserved.
     Contributors: Library, Information Services, Flinders University.
     See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).

     PURPOSE
     To tranform Equella XML to Qualified Dublin Core (QDC) metadata at
     the Equella OAI-PMH output interface.
  -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:dcterms="http://purl.org/dc/terms/"
  xmlns:date="http://exslt.org/dates-and-times"
>

  <xsl:output method="xml" version="1.0" indent="yes" />
  <xsl:strip-space elements="*" />
  <xsl:variable name="today" select="substring(date:date-time(),1,10)"/>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Root template -->
  <xsl:template match="/">
    <oai_qdc:qualifieddc xmlns:oai_qdc="http://example.org/appqualifieddc/"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
      xsi:schemaLocation="http://example.org/appqualifieddc/
        http://dublincore.org/schemas/xmls/qdc/2003/04/02/appqualifieddc.xsd"
    >

      <xsl:apply-templates select="/xml/item/rhd/publish_date" />

    </oai_qdc:qualifieddc>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- We need very strict control of embargo_date (publish_date?) format -->
  <xsl:template match="/xml/item/rhd/publish_date">
    <dc:description>
      <xsl:value-of select="concat('DEBUG: Embargo end date=&quot;',
        current(), '&quot;  today=&quot;', $today, '&quot;')" />
    </dc:description>

    <xsl:choose>
      <xsl:when test="current() = '' or
          translate($today, '-', '')  &gt;= translate(current(), '-', '')">
        <dc:description>DEBUG: PAST THE EMBARGO DATE OR EMBARGO DATE IS EMPTY</dc:description>
        <xsl:apply-templates select="/xml/item/rhd/*[name()!='publish_date']" />
        <dcterms:valid> <xsl:value-of select="." /></dcterms:valid>
      </xsl:when>

      <xsl:otherwise>
        <dc:description>DEBUG: UNDER EMBARGO</dc:description>
      </xsl:otherwise>
    </xsl:choose>
 </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Suppress these elements from output -->
  <xsl:template match="other|another|lang|my_thesis_url" />

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Prefix these element names with the same name in the dc namespace -->
  <xsl:template match="title|type|subject|format|identifier|language|complete_year|creator">
    <xsl:element name="dc:{name()}" namespace="http://purl.org/dc/elements/1.1/">
      <xsl:value-of select="." />
    </xsl:element>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Tranform element to a different element name in the dc namespace -->
  <xsl:template match="description">
    <dcterms:abstract> <xsl:value-of select="." /> </dcterms:abstract>
  </xsl:template>

  <xsl:template match="date">
    <dcterms:issued> <xsl:value-of select="." /> </dcterms:issued>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Add an attribute to an element -->
  <!--
      1/ xsltproc (wrongly I suspect) gives the following error:
           namespace error : Namespace prefix xsi for type on language is not defined
         for:
           <dc:language xsi:type="dcterms:RFC3066"> ... </dc:language>

         However, xsltproc (wrongly I believe) says the following is ok:
           <dc:language type="dcterms:RFC3066"> ... </dc:language>
         even though no default namespace is defined in this xsl file!

      2/ xmllint (correctly I believe) says xsi:type="..." is valid & type="..."
         is not. Good!

      3/ http://www.w3schools.com/xml/xml_validator.asp claim both are ok!
         Validation not strict?

      4/ http://www.freeformatter.com/xml-validator-xsd.html says xsi:type is
         valid & type is not. Good - agrees with xmllint!
    -->

<!--
  <xsl:template match="language">
    <dc:language xsi:type="dcterms:RFC3066"> <xsl:value-of select="." /> </dc:language>
  </xsl:template>
  -->

</xsl:stylesheet>

