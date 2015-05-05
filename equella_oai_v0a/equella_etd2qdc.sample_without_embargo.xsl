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
>

  <xsl:output method="xml" version="1.0" indent="yes" />
  <xsl:strip-space elements="*" />

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Root template -->
  <xsl:template match="/">
    <oai_qdc:qualifieddc xmlns:oai_qdc="http://example.org/appqualifieddc/"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
      xsi:schemaLocation="http://example.org/appqualifieddc/
        http://dublincore.org/schemas/xmls/qdc/2003/04/02/appqualifieddc.xsd"
    >

      <xsl:apply-templates select="/xml/item/rhd" />

    </oai_qdc:qualifieddc>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Suppress these elements from output -->
  <!--
  <xsl:template match="other|another|lang|my_thesis_url" />
  -->
  <xsl:template match="/xml/item/rhd/*[
    name()!='complete_year' and
    name()!='creator' and
    name()!='description' and
    name()!='format' and
    name()!='identifier' and
    name()!='language' and
    name()!='publish_date' and
    name()!='subject' and
    name()!='title' and
    name()!='type'
  ]" />

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Prefix these element names with the same name in the dc namespace -->
  <xsl:template match="creator|format|identifier|language|subject|title|type">
    <xsl:element name="dc:{name()}" namespace="http://purl.org/dc/elements/1.1/">
      <xsl:value-of select="." />
    </xsl:element>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Tranform element to a different element name -->
  <xsl:template match="complete_year">
    <dcterms:dateAccepted> <xsl:value-of select="." /> </dcterms:dateAccepted>
  </xsl:template>

  <xsl:template match="description">
    <dcterms:abstract> <xsl:value-of select="." /> </dcterms:abstract>
  </xsl:template>

  <xsl:template match="publish_date">
    <dcterms:issued> <xsl:value-of select="." /> </dcterms:issued>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Add an attribute -->
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

      3/ (http://www.w3schools.com/xml/xml_validator.asp claim both are ok! Poor -
         validation not strict?)

      4/ http://www.freeformatter.com/xml-validator-xsd.html says xsi:type is
         valid & type is not. Good - agrees with xmllint!
         -->

<!--
  <xsl:template match="language">
    <dc:language xsi:type="dcterms:RFC3066"> <xsl:value-of select="." /> </dc:language>
  </xsl:template>
  -->

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
<!--
  <xsl:template match="my_thesis_url">
    <dc:identifier xsi:type="dcterms:URI"> <xsl:value-of select="." /> </dc:identifier>
  </xsl:template>
  -->

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
<!--
  <xsl:template match="my_type">
    <dc:type xsi:type="dcterms:DCMIType"> <xsl:value-of select="." /> </dc:type>
  </xsl:template>
  -->
</xsl:stylesheet>

