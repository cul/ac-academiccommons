<?xml version="1.0" encoding="UTF-8"?>	
<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"   
		xmlns:foxml="info:fedora/fedora-system:def/foxml#"
		xmlns:dc="http://purl.org/dc/elements/1.1/"
		xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
		xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
		xmlns:fedora-model="info:fedora/fedora-system:def/model#"
		xmlns:nsdl="http://ns.nsdl.org/api/relationships#"
		xmlns:cc="http://creativecommons.org/ns#"
		xmlns:cul="http://purl.oclc.org/NET/CUL/"
		xmlns:mods="http://www.loc.gov/mods/v3"
		xmlns:result="http://www.w3.org/2001/sw/DataAccess/rf1/result">

  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
	<xsl:variable name="docBoost" select="1.4*2.5"/> <!-- or any other calculation, default boost is 1.0 -->
	<xsl:param name="repositoryService"/>
	<xsl:variable name="repSrvcGet" select="concat($repositoryService, '/get/')"/>


	  <xsl:template match="/">
	    
	    <add> 
	      <doc>


		      <xsl:variable name="ac-pid" select="/doc/pid"/>

					      
		      <field name="pid">
			<xsl:value-of select="$ac-pid"/>
		      </field>

		      <xsl:for-each select="/doc/collection/member">
			<field name="member_of">
			  <xsl:value-of select="."/>
			</field>
			</xsl:for-each>


		      <xsl:variable name='meta-uri' select="document(concat($repSrvcGet, $ac-pid, '/ldpd:sdef.Core/describedBy?max=&amp;format=&amp;start='))/result:sparql/result:results/result:result/result:description/@uri"/>
		      <xsl:variable name="meta-pid" select="substring-after($meta-uri, '/')"/>
	  
		      <xsl:call-template name="mods-process">
			<xsl:with-param name="mods-pid" select="$meta-pid" />
		      </xsl:call-template>
	      	
	      	<xsl:for-each select="/doc/resources/resource">
	      		<xsl:call-template name="resource-process">
	      			<xsl:with-param name="resource-pid" select="./@pid"/>
	      			<xsl:with-param name="resource-position" select="./@position"/>
	      		</xsl:call-template>
	      	</xsl:for-each>
	      	


	      </doc>
	    </add>			
	  </xsl:template>


 <xsl:template name="mods-process"> 
    <xsl:param name="mods-pid" />
 

				<xsl:variable name="smallcase" select="'abcdefghijklmnopqrstuvwxyz'"/>
				<xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>


				<xsl:variable name="display_title">
				  <xsl:value-of select="document(concat($repSrvcGet, $mods-pid, '/CONTENT'))/mods:mods/mods:titleInfo/mods:nonSort"/>
				  <xsl:value-of select="document(concat($repSrvcGet, $mods-pid, '/CONTENT'))/mods:mods/mods:titleInfo/mods:title"/>
				</xsl:variable>


				<field name="title_display">
				  <xsl:value-of select="normalize-space($display_title)"/>
				</field>
				<field name="title_search">
				  <xsl:value-of select="normalize-space($display_title)"/>
				</field>

				<xsl:variable name="roles" select="document('./roles.xml')/roles/role"/>

				<xsl:for-each select="document(concat($repSrvcGet, $mods-pid, '/CONTENT'))/mods:mods/mods:name[@type='personal']">
				  <xsl:if test="$roles = ./mods:role/mods:roleTerm[@type='text']">
				    <xsl:variable name="fullname" select="concat(./mods:namePart[@type='family'], ', ', ./mods:namePart[@type='given'])"/>

				    <field name="author_search">
				      <xsl:value-of select="translate($fullname, $uppercase, $smallcase)"/>
				    </field>
				    <field name="author_facet">
				      <xsl:value-of select="$fullname"/>
				    </field>

				  </xsl:if>

				</xsl:for-each>


				<xsl:variable name="authors_display"/>


				<field name="authors_display">
				<xsl:for-each select="document(concat($repSrvcGet, $mods-pid, '/CONTENT'))/mods:mods/mods:name[@type='personal']">
				  <xsl:if test="$roles = ./mods:role/mods:roleTerm[@type='text']">
				    <xsl:variable name="fullname" select="concat(./mods:namePart[@type='family'], ', ', ./mods:namePart[@type='given'])"/>
				  <xsl:value-of select="$fullname"/>
				  <xsl:if test="not(position() = last())">; </xsl:if>
				  </xsl:if>
				</xsl:for-each>
				</field>



				<field name="date">
					<xsl:value-of select="document(concat($repSrvcGet, $mods-pid, '/CONTENT'))//mods:*[@keyDate = 'yes']"/>
				</field>

				<xsl:for-each select="document(concat($repSrvcGet, $mods-pid, '/CONTENT'))/mods:mods/mods:genre">
				<field name="genre_facet">
					<xsl:value-of select="text()"/>
				</field>

				<field name="genre_search">
					<xsl:value-of select="text()"/>
				</field>

				</xsl:for-each>


				<field name="abstract">
					<xsl:value-of select="document(concat($repSrvcGet, $mods-pid, '/CONTENT'))/mods:mods/mods:abstract"/>
				</field>

				<field name="handle">
				  <xsl:value-of select="document(concat($repSrvcGet, $mods-pid, '/CONTENT'))/mods:mods/mods:identifier[@type='hdl']"/>
				</field>


				<xsl:for-each select="document(concat($repSrvcGet, $mods-pid, '/CONTENT'))/mods:mods/mods:subject">
					<xsl:choose>
					<xsl:when test='./@authority'></xsl:when>
					<xsl:otherwise>
					<xsl:for-each select="./mods:topic">
					<field name="keyword_search">
						<xsl:value-of select="translate(text(), $uppercase, $smallcase)"/>
					</field>
					<field name="keyword_facet">
						<xsl:value-of select="text()"/>
					</field>
					</xsl:for-each>
					</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>


				<field name="tableOfContents">
				  <xsl:value-of select="document(concat($repSrvcGet, $mods-pid, '/CONTENT'))/mods:mods/mods:tableOfContents"/>
				</field>

				<xsl:for-each select="document(concat($repSrvcGet, $mods-pid, '/CONTENT'))/mods:mods/mods:note">
				<field name="notes">
				  <xsl:value-of select="text()"/>
				</field>
				</xsl:for-each> 

				<field name="book_journal_title">
					<xsl:value-of select="document(concat($repSrvcGet, $mods-pid, '/CONTENT'))/mods:mods/mods:relatedItem[@type='host']/mods:titleInfo/mods:title"/>
					<xsl:if test="document(concat($repSrvcGet, $mods-pid, '/CONTENT'))/mods:mods/mods:relatedItem[@type='host']/mods:name/mods:titleInfo/mods:subTitle">: <xsl:value-of select="document(concat($repSrvcGet, $mods-pid, '/CONTENT'))/mods:mods/mods:relatedItem[@type='host']/mods:name/mods:titleInfo/mods:subTitle"/>
					</xsl:if>
				</field>

				<field name="book_author">
					<xsl:if test="document(concat($repSrvcGet, $mods-pid, '/CONTENT'))/mods:mods/mods:relatedItem[@type='host']/mods:name/mods:namePart[@type='family']">
					<xsl:value-of select="document(concat($repSrvcGet, $mods-pid, '/CONTENT'))/mods:mods/mods:relatedItem[@type='host']/mods:name/mods:namePart[@type='family']"/>, <xsl:value-of select="document(concat($repSrvcGet, $mods-pid, '/CONTENT'))/mods:mods/mods:relatedItem[@type='host']/mods:name/mods:namePart[@type='given']"/>
					</xsl:if>
				</field>

				<field name="issn">
					<xsl:value-of select="document(concat($repSrvcGet, $mods-pid, '/CONTENT'))/mods:mods/mods:relatedItem[@type='host']/mods:identifier[@type='issn']"/>
				</field>

				<field name="publisher">
				  <xsl:value-of select="document(concat($repSrvcGet, $mods-pid, '/CONTENT'))/mods:mods/mods:relatedItem/mods:originInfo/mods:publisher"/>
				</field>

				<field name="publisher_location">
<xsl:value-of select="document(concat($repSrvcGet, $mods-pid, '/CONTENT'))/mods:mods/mods:relatedItem/mods:originInfo/mods:place/mods:placeTerm[@type='text']"/>
				</field>


				<xsl:for-each select="document(concat($repSrvcGet, $mods-pid, '/CONTENT'))/mods:mods/mods:subject[@authority='local']/mods:topic">
				<field name="subject">
				  <xsl:value-of select="text()"/>
				</field>

				<field name="subject_search">
				  <xsl:value-of select="text()"/>
				</field>

				</xsl:for-each>

				<field name="isbn">
				  <xsl:value-of select="document(concat($repSrvcGet, $mods-pid, '/CONTENT'))/mods:mods/mods:relatedItem/mods:identifier[@type='isbn']"/>
				</field>

				<field name="doi">
				  <xsl:value-of select="document(concat($repSrvcGet, $mods-pid, '/CONTENT'))/mods:mods/mods:identifier[@type='doi'][@displayLabel='Published version']"/>
				</field>
 	
				<xsl:for-each select="document(concat($repSrvcGet, $mods-pid, '/CONTENT'))/mods:mods/mods:physicalDescription/mods:internetMediaType">
				<field name="media_type_facet">
				  <xsl:value-of select="text()"/>
				</field>
				</xsl:for-each>

				<xsl:for-each select="document(concat($repSrvcGet, $mods-pid, '/CONTENT'))/mods:mods/mods:typeOfResource">
				<field name="type_of_resource_facet">
				  <xsl:value-of select="text()"/>
				</field>
				</xsl:for-each>


			      <xsl:for-each select="document(concat($repSrvcGet, $mods-pid, '/CONTENT'))/mods:mods/mods:subject/mods:geographic">
				<field name="geographic_area">
				  <xsl:value-of select="text()"/>
				</field>

				<field name="geographic_area_search">
				  <xsl:value-of select="text()"/>
				</field>

				</xsl:for-each>

      </xsl:template>
	
	<xsl:template name="resource-process">
		<xsl:param name="resource-pid"/>
		<xsl:param name="resource-position"/>
		
		<field>
			<xsl:attribute name="name">
				<xsl:value-of select="concat('ac.fulltext_', $resource-position)"/>
			</xsl:attribute>
			<xsl:value-of select="."/>
		</field>
	</xsl:template>
	


</xsl:stylesheet>
