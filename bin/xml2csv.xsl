<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!--
       Derived from the sample "Converting XML to CSV using XSLT 1.0" at
       http://fahdshariff.blogspot.com.au/2014/07/converting-xml-to-csv-using-xslt-10.html
       by Fahd Shariff under GNU GENERAL PUBLIC LICENSE Version 3.

       Copyright (c) 2015, Flinders University, South Australia. All rights reserved.
       Contributors: Library, Information Services, Flinders University.
       See the accompanying gpl-3.0.txt file (or http://www.gnu.org/licenses/gpl-3.0.html).

       PURPOSE
       This XSLT transforms *modified* Australasian Digital Theses (ADT)
       legacy web pages into a format suitable for loading into an
       Equella digital repository (http://www.equella.com/) via the
       Equella Bulk Importer (EBI). This is part of the following workflow:
       - Extract metadata and thesis attachments from ADT web pages in the
         filesystem
       - convert to an intermediate XML format (via a shell script)
       - convert to a EBI-compatible CSV file via this XSLT file (using
         xsltproc)
       - load into an Equella thesis collection

       ADT REFERENCES
       http://ausweb.scu.edu.au/aw02/papers/edited/borchert/paper.htm
       http://www.caul.edu.au/caul-programs/australasian-digital-theses/finding-theses
  -->
  <xsl:output method="text" />
 
  <!--
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       We can pass these parameters into this XSLT script from the command
       line using the xsltproc "param" or "stringparam" option. Eg.
         xsltproc \-\-param add_csv_header "true()"  \-\-stringparam embargoed_str false ...
         xsltproc \-\-param add_csv_header "false()" \-\-stringparam embargoed_str true ...
  -->
  <xsl:param name="add_csv_header" select="true()" />
  <!-- Other scripts compare embargoed_str with 'false'. Do the same below. -->
  <xsl:param name="embargoed_str" select="''"/>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Field delim for CSV EBI file -->
  <xsl:variable name="field_delim" select="','" />
  <!-- Quote fields so they may contain $field_delim -->
  <xsl:variable name="quote" select="'&quot;'" />
  <!-- This subfield generates multiple Equella fields -->
  <xsl:variable name="subfield_delim" select="'|'" />
  <!-- Alternative subfield for DC.Subject - does not generate multiple Equella fields -->
  <xsl:variable name="subfield_delim_alt" select="','" />
 
  <!-- An "array" containing the XML field-names (and their associated CSV header-names) -->
  <xsl:variable name="fieldArray">
    <field csv_header_name="item/curriculum/people/students/student/email">DC.Creator.personalName.address</field>
    <field csv_header_name="item/curriculum/thesis/title">DC.Title</field>

    <field csv_header_name="item/curriculum/thesis/keywords/keyword">DC.Subject</field>
    <field csv_header_name="item/curriculum/thesis/version/abstract/text">DC.Description.abstract</field>
    <field csv_header_name="item/curriculum/thesis/complete_year">DC.Date.fixed</field>
    <field csv_header_name="item/curriculum/thesis/language">DC.Language</field>
    <!-- FIXME: I think DC.Publisher is derived from X.institution & X.school; use the components?
    <field csv_header_name="item/curriculum/thesis/publisher">DC.Publisher</field>
    -->
    <field csv_header_name="item/curriculum/thesis/@type">X.thesis_type</field>
    <field csv_header_name="item/curriculum/thesis/publisher">X.institution</field>
    <field csv_header_name="item/curriculum/thesis/faculties/primary">X.dept</field>
    <field csv_header_name="item/curriculum/thesis/schools/primary">X.school</field>
    <field csv_header_name="item/curriculum/people/coords/coord/name">X.chair</field>
    <!-- FIXME: This release date is NOT suitable for embargoed theses!!! -->
    <field csv_header_name="item/curriculum/thesis/release/release_date">X.upload_date</field>
    <!-- FIXME: Other file attributes? -->
    <field csv_header_name="item/attachments/attachment/file">I.attachment</field>
    <!-- FIXME: What is XPath for previous ADT identifier?  -->
    <field csv_header_name="item/xxxx/previous_identifier_url">DC.Identifier.fixed</field>

  </xsl:variable>
  <xsl:variable name="fields" select="document('')/*/xsl:variable[@name='fieldArray']/*" />
 
  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- TEMPLATE-BASED FUNCTIONS - can only return text or element-sequences -->
  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <xsl:template name="do_student_name">
    <xsl:param name="is_csv_header" select="false()" />

    <xsl:choose>
      <xsl:when test="$is_csv_header">
        <xsl:value-of select="concat($field_delim, $quote, 'item/curriculum/people/students/student/lastname', $quote)" />
        <xsl:value-of select="concat($field_delim, $quote, 'item/curriculum/people/students/student/firstname', $quote)" />
        <xsl:value-of select="concat($field_delim, $quote, 'item/curriculum/people/students/student/lastname_display', $quote)" />
        <xsl:value-of select="concat($field_delim, $quote, 'item/curriculum/people/students/student/firstname_display', $quote)" />
        <xsl:value-of select="concat($field_delim, $quote, 'item/curriculum/people/students/student/name_display', $quote)" />
      </xsl:when>

      <xsl:otherwise>
        <xsl:variable name="full_name" select="/ADT_METADATA/HEAD/META[@NAME='DC.Creator.personalName']/@CONTENT" />
        <xsl:variable name="surname" select="normalize-space(substring-before($full_name, ','))" />
        <xsl:variable name="given_names" select="normalize-space(substring-after($full_name, ','))" />
        <xsl:variable name="surname_given_names" select="concat($given_names, ' ', $surname)" />

        <xsl:value-of select="concat($field_delim, $quote, $surname, $quote)" />
        <xsl:value-of select="concat($field_delim, $quote, $given_names, $quote)" />
        <xsl:value-of select="concat($field_delim, $quote, $surname, $quote)" />
        <xsl:value-of select="concat($field_delim, $quote, $given_names, $quote)" />
        <xsl:value-of select="concat($field_delim, $quote, $surname_given_names, $quote)" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- TEMPLATES -->
  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->

  <!-- Root template -->
  <xsl:template match="/">
 
    <xsl:if test="$add_csv_header = true()">
      <!-- output the header row -->
      <xsl:for-each select="$fields">
        <xsl:if test="position() != 1">
          <xsl:value-of select="$field_delim"/>
        </xsl:if>
        <xsl:value-of select="concat($quote, @csv_header_name, $quote)" />
      </xsl:for-each>
 
      <!-- Output processed fields -->
      <xsl:call-template name="do_student_name">
        <xsl:with-param name="is_csv_header" select="true()" />
      </xsl:call-template>

      <!-- Output constant fields -->
      <xsl:value-of select="concat($field_delim, $quote, 'item/curriculum/thesis/subjects/subject', $quote)" />
      <xsl:value-of select="concat($field_delim, $quote, 'item/curriculum/thesis/version/thesis_version', $quote)" />
      <xsl:value-of select="concat($field_delim, $quote, 'item/curriculum/thesis/agreements/authenticity', $quote)" />
      <xsl:value-of select="concat($field_delim, $quote, 'item/curriculum/thesis/agreements/declaration', $quote)" />
      <xsl:value-of select="concat($field_delim, $quote, 'item/curriculum/thesis/agreements/copyright', $quote)" />

      <xsl:value-of select="concat($field_delim, $quote, 'item/curriculum/thesis/release/status', $quote)" />
      <xsl:if test="$embargoed_str != 'false'">
        <!-- Only add this column for embargoed theses. Hence all embargoed
             theses in one CSV file and all non-embargoed theses in another.
        -->
        <xsl:value-of select="concat($field_delim, $quote, 'item/curriculum/thesis/agreements/embargo', $quote)" />
      </xsl:if>

      <!-- Output newline -->
      <xsl:text>&#xa;</xsl:text>
    </xsl:if>
 
    <xsl:apply-templates select="ADT_METADATA"/>
  </xsl:template>
 
  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <xsl:template match="ADT_METADATA">
    <xsl:variable name="currNode" select="." />
 
    <!-- output the data row -->
    <!-- loop over the field names and find the value of each one in the xml -->
    <xsl:for-each select="$fields">
      <xsl:if test="position() != 1">
        <xsl:value-of select="$field_delim"/>
      </xsl:if>
      <xsl:value-of select="$quote"/>

      <!-- Permit repeated fields -->
      <xsl:variable name="currName" select="current()" />
      <xsl:for-each select="$currNode/*/META[@NAME = current()]/@CONTENT">

        <xsl:if test="position() != 1">
          <xsl:choose>
            <xsl:when test="$currName = 'DC.Subject'"> <xsl:value-of select="$subfield_delim_alt"/> </xsl:when>
            <xsl:otherwise> <xsl:value-of select="$subfield_delim"/> </xsl:otherwise>
          </xsl:choose>
        </xsl:if>

        <xsl:value-of select="." />
      </xsl:for-each>

      <xsl:value-of select="$quote"/>
    </xsl:for-each>
 
    <!-- Output processed fields -->

    <xsl:call-template name="do_student_name">
      <xsl:with-param name="is_csv_header" select="false()" />
    </xsl:call-template>

    <!-- Output constant fields -->

    <!-- Field: item/curriculum/thesis/subjects/subject -->
    <xsl:value-of select="concat($field_delim, $quote, '', $quote)" />
    <!-- Field: item/curriculum/thesis/version/thesis_version -->
    <xsl:value-of select="concat($field_delim, $quote, '2015 lib import version', $quote)" />
    <!-- Field: item/curriculum/thesis/agreements/authenticity -->
    <xsl:value-of select="concat($field_delim, $quote, 'I agree', $quote)" />
    <!-- Field: item/curriculum/thesis/agreements/declaration -->
    <xsl:value-of select="concat($field_delim, $quote, 'Yes', $quote)" />
    <!-- Field: item/curriculum/thesis/agreements/copyright -->
    <xsl:value-of select="concat($field_delim, $quote, 'Yes', $quote)" />

    <xsl:choose>
      <xsl:when test="$embargoed_str != 'false'">
        <!-- Field: item/curriculum/thesis/release/status -->
        <xsl:value-of select="concat($field_delim, $quote, 'Restricted Access', $quote)" />
        <!-- Field: item/curriculum/thesis/agreements/embargo -->
        <xsl:value-of select="concat($field_delim, $quote, 'Yes', $quote)" />
      </xsl:when>
      <xsl:otherwise>
        <!-- Field: item/curriculum/thesis/release/status -->
        <xsl:value-of select="concat($field_delim, $quote, 'Open Access', $quote)" />
      </xsl:otherwise>
    </xsl:choose>

    <!-- output newline -->
    <xsl:text>&#xa;</xsl:text>
  </xsl:template>
</xsl:stylesheet>

