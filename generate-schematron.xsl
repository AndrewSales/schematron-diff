<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    Generates a Schematron schema from an XML instance, asserting the presence and string
    value of every element and attribute in the document, and further asserting that no
    unexpected attributes or elements are present.
    
    The result can be used for document comparison, e.g. in a conversion 
    workflow. Once run on a desired output instance, the generated Schematron schema can 
    be used to check where a generated output instance differs from the target.
    
    Author: Andrew Sales <mailto:andrew@andrewsales.com>
    Date: 20140401
    Revision: 0.1
    Comments:
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="http://purl.oclc.org/dsdl/schematron"
    exclude-result-prefixes="xs" version="2.0">

    <xsl:output indent="yes"/>

    <xsl:template match="/">
        <schema queryBinding="xslt2">
            <!-- namespace declarations -->
            <xsl:for-each select="*/namespace::node()">
                <ns uri="{.}" prefix="{name()}"/>
            </xsl:for-each>

            <!-- rule for root node: check root element -->
            <pattern>
                <rule context='/'>
                    <xsl:apply-templates select="*" mode="expected-child"/>
                </rule>
            </pattern>

            <xsl:apply-templates select="*"/>

        </schema>
    </xsl:template>
    
    <!-- For every element in the document, check:
        1. attributes and their values as expected
        2. element children as expected
        3. string value of context element as expected.
    -->
    <xsl:template match="*">
        <xsl:variable name="xpath">
            <xsl:variable name="ancestor-or-self" select="ancestor-or-self::*"/>
            <xsl:for-each select="$ancestor-or-self">
                <xsl:value-of
                    select="concat( '/', name(.), '[', count(preceding-sibling::*[name() = current()/name()]) + 1, ']' )"/>
            </xsl:for-each>
        </xsl:variable>
        <!-- TODO: investigate pattern/rule ordering to reduce noise -->
        <pattern>
            <rule context="{$xpath}">
                <!-- ATTRIBUTES -->
                <xsl:choose>
                    <xsl:when test="empty(@*)">
                        <assert test="empty(@*)">no attributes expected; found '<value-of select="string-join(@*/name(), &#34;', '&#34;)"/>'</assert>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="attributes-rule"/>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- ELEMENTS -->
                <xsl:choose>
                    <xsl:when test="empty(*)">
                        <assert test="empty(*)">no element children expected; found '<value-of select="string-join(*/name(), &#34;', '&#34;)"/>'</assert>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="child-elements-rule"/>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- STRING VALUE -->
                <assert test='.="{.}"'>expected string value '<xsl:value-of select="."/>'; got '<value-of select='.'/>'</assert>
            </rule>
        </pattern>
        <xsl:apply-templates select="*"/>
    </xsl:template>
    
    <xsl:template name="child-elements-rule">
        <!-- unexpected elements: -->
        <let name="expected-elems" value="({string-join(*/name(), ',')})"/>
        <assert test="empty(* except $expected-elems)">unexpected element '<value-of select='string-join(((* except $expected-elems)/name()), "&apos;, &apos;")'/>'; expected '<value-of select='string-join((($expected-elems)/name()), "&apos;, &apos;")'/>'</assert>
        
        <!-- element children: -->
        <xsl:apply-templates select="*" mode="expected-child"/>
        
    </xsl:template>
    
    <xsl:template match="*" mode="expected-child">
        <!-- TODO: strengthen predicate to assert no. of preceding siblings of same name -->
        <assert test="*[{position()}][self::{name()}]">missing child element '<xsl:value-of select="name()"/>' at position <xsl:value-of select="position()"/>; got '<value-of select="name(*[{position()}])"/>'</assert>
    </xsl:template>        
    
    <xsl:template match="@*" mode="expected-attribute">
        <assert test="exists(@{name()})">missing attribute '<xsl:value-of select="name()"/>'</assert>
        <xsl:apply-templates select="." mode="expected-value"/>
    </xsl:template>
    
    <xsl:template match="@*" mode="expected-value">
        <assert test='@{name()} = "{.}"'>expected attribute value '<xsl:value-of select="."/>'; got '<value-of select="@{name()}"/>'</assert>
    </xsl:template>
    
    <xsl:template name="attributes-rule">
        <!-- unexpected attributes: -->
        <let name="expected-atts" value="({string-join( for $att in @*/name() return concat('@', $att), ',')})"/>
        <assert test="empty(@* except $expected-atts)">unexpected attribute '<value-of select='string-join(((@* except $expected-atts)/name()), "&apos;, &apos;")'/>'; expected '<value-of select='string-join((($expected-atts)/name()), "&apos;, &apos;")'/>'</assert>
        
        <xsl:apply-templates select="@*" mode='expected-attribute'/>
    </xsl:template>

</xsl:stylesheet>
