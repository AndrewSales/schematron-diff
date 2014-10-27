schematron-diff
===============

Generates a Schematron schema from an XML instance.

The automatically-generated schema asserts the presence and string
value of every element and attribute in the document, further asserting that no
unexpected attributes or elements are present.

The result can be used to detect whether a document has been changed.
A typical application is document comparison, e.g. in a conversion 
workflow. Once run on a desired output instance, the generated Schematron schema can 
be used to check where a generated output instance differs from the target.
