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

  <!-- 0 = No debug; 1 = Debug info; 2 = More debug info -->
  <xsl:variable name="debug_level" select="'1'" />
  <!-- Output debug info using this element name.
       Choose a field which will cause Alma to NOT load
       "unexpected" records (eg. do NOT use dc:title).
  -->
  <xsl:variable name="debug_element_name" select="'dc:coverage'" />

  <xsl:variable name="today" select="substring(date:date-time(),1,10)" />
  <xsl:variable name="target_url_prefix" select="'http://www.flinders.edu.au/theses/'" />
  <xsl:variable name="identifier_prefix" select="'flex-'" />
  <xsl:variable name="rights_statement" 
    select="'This electronic version is made publicly available by Flinders University in accordance with its open access policy for student theses. Copyright in this thesis remains with the author. This thesis may incorporate third party material which has been used by the author pursuant to Fair Dealing exceptions. If you are the owner of any included third party copyright material and/or you believe that any material has been made available without permission of the copyright owner please contact copyright@flinders.edu.au with the details'"
  />

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- TEMPLATE-BASED FUNCTIONS - can only return text or element-sequences -->
  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->

  <!-- Recursive function to split a delimiter-separated string into multiple elements.
       - Sub-fields are "trimmed" with normalize-space()
       - Empty "trimmed" sub-fields are omitted from the output
       Eg. If string="'one,, two ,'" and element_name="'count'" and
       element_value_prefix="'Normalise:'" and delim="','", this function produces:
         <count>Normalise:one</count>
         <count>Normalise:two</count>
  -->
  <xsl:template name="split_into_elements">
    <xsl:param name="string" />
    <xsl:param name="element_name" />
    <xsl:param name="element_value_prefix" select="''" />
    <xsl:param name="delim" select="','" />

    <xsl:choose>
      <xsl:when test="contains($string, $delim)">
        <xsl:variable name="trimmed_str" select="normalize-space(substring-before($string, $delim))" />
        <xsl:if test="$trimmed_str != ''">
          <xsl:element name="{$element_name}">
            <xsl:value-of select="concat($element_value_prefix, $trimmed_str)" />
          </xsl:element>
        </xsl:if>

        <xsl:call-template name="split_into_elements">
          <xsl:with-param name="string" select="substring-after($string, $delim)" />
          <xsl:with-param name="element_name" select="$element_name" />
          <xsl:with-param name="element_value_prefix" select="$element_value_prefix" />
          <xsl:with-param name="delim" select="$delim" />
        </xsl:call-template>
      </xsl:when>

      <xsl:otherwise>
        <xsl:variable name="trimmed_str" select="normalize-space($string)" />
        <xsl:if test="$trimmed_str != ''">
          <xsl:element name="{$element_name}">
            <xsl:value-of select="concat($element_value_prefix, $trimmed_str)" />
          </xsl:element>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Return string 'true' if iso_date param has format YYYY-MM-DD; else return 'false' -->
  <xsl:template name="is_iso_date">
    <xsl:param name="iso_date" />
    <xsl:param name="year_min" select="'1900'" />
    <xsl:param name="year_max" select="'2099'" />

    <xsl:value-of select="boolean(
      string-length($iso_date) = 10 and
      translate($iso_date, '0123456789', '') = '--' and
      number(substring($iso_date, 1, 4)) &gt;= $year_min and
      number(substring($iso_date, 1, 4)) &lt;= $year_max and
      substring($iso_date, 5, 1) = '-' and
      number(substring($iso_date, 6, 2)) &gt;=  1 and
      number(substring($iso_date, 6, 2)) &lt;= 12 and
      substring($iso_date, 8, 1) = '-' and
      number(substring($iso_date, 9, 2)) &gt;=  1 and
      number(substring($iso_date, 9, 2)) &lt;= 31
    )" />
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- TEMPLATES -->
  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->

  <!-- Root template -->
  <xsl:template match="/">
    <oai_qdc:qualifieddc xmlns:oai_qdc="http://example.org/appqualifieddc/"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
      xsi:schemaLocation="http://example.org/appqualifieddc/
        http://dublincore.org/schemas/xmls/qdc/2003/04/02/appqualifieddc.xsd"
  >

      <xsl:apply-templates select="/xml/item/curriculum/thesis/release" />

    </oai_qdc:qualifieddc>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <xsl:template match="/xml/item/curriculum/thesis/release">
    <!--
      Make OAI-PMH record available if:
        /xml/item/@itemstatus = 'live' and
        /xml/item/curriculum/thesis/release/status = ('Open Access' or 'Restricted Access')
    -->
    <xsl:variable name="is_live" select="boolean(/xml/item/@itemstatus = 'live')" />
    <xsl:variable name="will_be_open_access" select="boolean(status = 'Open Access' or status = 'Restricted Access')" />

    <xsl:if test="$debug_level &gt;= 2">
      <xsl:element name="{$debug_element_name}"> <xsl:value-of select="concat('DEBUG: is_live                 = ', $is_live)" /> </xsl:element>
      <xsl:element name="{$debug_element_name}"> <xsl:value-of select="concat('DEBUG: will_be_open_access     = ', $will_be_open_access)" /> </xsl:element>
    </xsl:if>

    <xsl:choose>
      <xsl:when test="$is_live and $will_be_open_access">
        <xsl:apply-templates select="/xml/item/@id" />
        <xsl:apply-templates select="/xml/item/curriculum/thesis/@type" />
        <xsl:apply-templates select="/xml/item/curriculum/people/students/student/name_display" />

        <xsl:apply-templates select="/xml/item/curriculum/thesis/version/abstract/text" />
        <xsl:apply-templates select="/xml/item/curriculum/thesis/*[name()!='release']" />
        <xsl:apply-templates select="/xml/item/curriculum/thesis/keywords/keyword" />
        <xsl:apply-templates select="/xml/item/curriculum/thesis/subjects/subject" />
        <xsl:apply-templates select="/xml/item/curriculum/thesis/agreements/copyright" />
        <xsl:apply-templates select="/xml/item/curriculum/thesis/release/release_date" />
      </xsl:when>

      <xsl:otherwise>
        <!-- Unexpected record --> 
        <xsl:if test="$debug_level &gt;= 1">
          <xsl:element name="{$debug_element_name}"> <xsl:value-of select="'DEBUG: ITEM IS UNPUBLISHED OR UNDER EMBARGO OR HAS AN INVALID DATE FORMAT'" /> </xsl:element>
          <xsl:element name="{$debug_element_name}"> <xsl:value-of select="concat('DEBUG: Unexpected record. Identifier: ', $identifier_prefix, /xml/item/@id)" /> </xsl:element>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- List Equella elements here (but not attributes) which we want to
       suppress from the apply-templates wildcard above
  -->
  <xsl:template match="/xml/item/curriculum/thesis/*[
    name()!='release' and
    name()!='complete_year' and
    name()!='language' and
    name()!='publisher' and
    name()!='title'
  ]" />

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Prefix these element names with the same name in the dc namespace -->
  <xsl:template match="language|publisher|title">
    <xsl:element name="dc:{name()}" namespace="http://purl.org/dc/elements/1.1/">
      <xsl:value-of select="." />
    </xsl:element>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- dcterms:available -->
  <!-- Output format as ISO date: YYYY-MM
       Map to MARC 263 (with format YYYYMM)
       Only populate this item if release_date is in the future.

       We need very strict control of release_date format!
  -->
  <xsl:template match="release/release_date">
    <xsl:variable name="is_in_future" select="boolean(translate(., '-', '') &gt;=  translate($today, '-', ''))" />
    <xsl:variable name="s_is_valid_release_date">
      <xsl:call-template name="is_iso_date">
        <xsl:with-param name="iso_date" select="." />
      </xsl:call-template>
    </xsl:variable>

    <xsl:if test="$debug_level &gt;= 2">
      <xsl:element name="{$debug_element_name}"> <xsl:value-of select="concat('DEBUG: is_in_future            = ', $is_in_future)" /> </xsl:element>
      <xsl:element name="{$debug_element_name}"> <xsl:value-of select="concat('DEBUG: s_is_valid_release_date = ', $s_is_valid_release_date)" /> </xsl:element>
      <xsl:element name="{$debug_element_name}"> <xsl:value-of select="concat('DEBUG: today         = ', $today)" /> </xsl:element>
      <xsl:element name="{$debug_element_name}"> <xsl:value-of select="concat('DEBUG: today2        = ', translate($today, '-', ''))" /> </xsl:element>
      <xsl:element name="{$debug_element_name}"> <xsl:value-of select="concat('DEBUG: release_date  = ', .)" /> </xsl:element>
      <xsl:element name="{$debug_element_name}"> <xsl:value-of select="concat('DEBUG: release_date2 = ', translate(., '-', ''))" /> </xsl:element>
    </xsl:if>

    <xsl:if test="$is_in_future and $s_is_valid_release_date='true'">
      <dcterms:available> <xsl:value-of select="substring(., 1, 7)" /> </dcterms:available>
    </xsl:if>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Tranform element to a different element name in the dc namespace -->

  <!-- dc:creator -->
  <xsl:template match="student/name_display">
    <dc:creator> <xsl:value-of select="." /> </dc:creator>
  </xsl:template>

  <!-- dc:date -->
  <xsl:template match="complete_year">
    <dc:date> <xsl:value-of select="." /> </dc:date>
  </xsl:template>

  <!-- dc:description -->
  <xsl:template match="abstract/text">
    <dc:description> <xsl:value-of select="." /> </dc:description>
  </xsl:template>

  <!-- 2x dc:identifier -->
  <xsl:template match="item/@id">
    <!-- The ID for this thesis -->
    <dc:identifier>
      <xsl:value-of select="concat($identifier_prefix, .)" />
    </dc:identifier>

    <!-- The target URL for this thesis -->
    <dc:identifier type="dcterms:URI">
      <xsl:value-of select="concat($target_url_prefix, ., '/', /xml/item/@version)" />
    </dc:identifier>
  </xsl:template>

  <!-- dc:rights -->
  <xsl:template match="copyright">
    <xsl:if test=". = 'Yes'">
      <dc:rights> <xsl:value-of select="$rights_statement" /> </dc:rights>
    </xsl:if>
  </xsl:template>

  <!-- dc:subject -->
  <xsl:template match="keyword">
    <xsl:call-template name="split_into_elements">
      <xsl:with-param name="string" select="." />
      <xsl:with-param name="element_name" select="'dc:subject'" />
      <xsl:with-param name="element_value_prefix" select="''" />
      <xsl:with-param name="delim" select="','" />
    </xsl:call-template>
  </xsl:template>

  <!-- dc:subject (discipline) -->
  <xsl:template match="subjects/subject">
    <xsl:call-template name="split_into_elements">
      <xsl:with-param name="string" select="." />
      <xsl:with-param name="element_name" select="'dc:subject'" />
      <xsl:with-param name="element_value_prefix" select="'Subject discipline:'" />
      <xsl:with-param name="delim" select="','" />
    </xsl:call-template>
  </xsl:template>

  <!-- dc:type -->
  <xsl:template match="thesis/@type">
    <dc:type> <xsl:value-of select="." /> </dc:type>
  </xsl:template>

</xsl:stylesheet>
