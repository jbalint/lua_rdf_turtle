-- tests for Turtle library
-- using Telescope framework (https://github.com/norman/telescope)

local turtle = require("turtle")
local _dump = require("pl.pretty").dump

describe("Turtle Parsing of Example Documents", function()
			context("test document 1", function ()
					   local test1 = [[
                               # First test snippet
                               @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
                               @prefix dc: <http://purl.org/dc/elements/1.1/> .
                               @prefix ex: <http://example.org/stuff/1.0/> .

                               ex:jess a ex:NonExistingClass ; a ex:AnotherClass .
                               ex:jess2 a ex:NonExistingClass , ex:AnotherClass .

                               <http://www.w3.org/TR/rdf-syntax-grammar>
                                 dc:title "RDF/XML Syntax Specification (Revised)" ;
                                 ex:editor [
                                   ex:fullname "Dave Beckett";
                                   ex:homePage <http://purl.org/net/dajobe/>
                                 ] .
                               ]]
					   local parsed
					   it("should parse the document", function ()
							 parsed = turtle.parse(test1)
							 assert_equal("table", type(parsed))
							 assert_equal("table", type(parsed[1]))
							 assert_equal(6, #parsed)
					   end)
					   it("should represent the prefixes", function ()
							 local prefix = parsed[1]
							 assert_equal("Prefix", prefix:nodeType())
							 assert_equal("rdf", prefix.prefix)
							 assert_equal("IriRef", prefix.iriRef:nodeType())
							 assert_equal("http://www.w3.org/1999/02/22-rdf-syntax-ns#", prefix.iriRef.iri)
							 prefix = parsed[2]
							 assert_equal("Prefix", prefix:nodeType())
							 assert_equal("dc", prefix.prefix)
							 assert_equal("IriRef", prefix.iriRef:nodeType())
							 assert_equal("http://purl.org/dc/elements/1.1/", prefix.iriRef.iri)
							 prefix = parsed[3]
							 assert_equal("Prefix", prefix:nodeType())
							 assert_equal("ex", prefix.prefix)
							 assert_equal("IriRef", prefix.iriRef:nodeType())
							 assert_equal("http://example.org/stuff/1.0/", prefix.iriRef.iri)
					   end)
					   it("should parse the basic triples", function ()
							 -- first triple/line
							 local spo = parsed[4]
							 assert_equal("SpoTriple", spo:nodeType())
							 assert_equal("PrefixedName", spo.subject:nodeType())
							 assert_equal("ex", spo.subject.prefix)
							 assert_equal("jess", spo.subject.name)
							 assert_equal(2, #spo.predicateObjectList)

							 local predObj = spo.predicateObjectList[1]
							 assert_equal("PredicateObject", predObj:nodeType())
							 assert_equal("IriRef", predObj.predicate:nodeType())
							 assert_equal("http://www.w3.org/1999/02/22-rdf-syntax-ns#type", predObj.predicate.iri)
							 assert_equal(turtle.RdfTypeIri.iri, predObj.predicate.iri)
							 assert_equal(1, #predObj.objectList)
							 local obj = predObj.objectList[1]
							 assert_equal("PrefixedName", obj:nodeType())
							 assert_equal("ex", obj.prefix)
							 assert_equal("NonExistingClass", obj.name)

							 predObj = spo.predicateObjectList[2]
							 assert_equal("PredicateObject", predObj:nodeType())
							 assert_equal("IriRef", predObj.predicate:nodeType())
							 assert_equal("http://www.w3.org/1999/02/22-rdf-syntax-ns#type", predObj.predicate.iri)
							 assert_equal(turtle.RdfTypeIri.iri, predObj.predicate.iri)
							 assert_equal(1, #predObj.objectList)
							 obj = predObj.objectList[1]
							 assert_equal("PrefixedName", obj:nodeType())
							 assert_equal("ex", obj.prefix)
							 assert_equal("AnotherClass", obj.name)

							 -- second triple/line
							 local spo = parsed[5]
							 assert_equal("SpoTriple", spo:nodeType())
							 assert_equal("PrefixedName", spo.subject:nodeType())
							 assert_equal("ex", spo.subject.prefix)
							 assert_equal("jess2", spo.subject.name)
							 assert_equal(1, #spo.predicateObjectList)

							 predObj = spo.predicateObjectList[1]
							 assert_equal("PredicateObject", predObj:nodeType())
							 assert_equal("IriRef", predObj.predicate:nodeType())
							 assert_equal("http://www.w3.org/1999/02/22-rdf-syntax-ns#type", predObj.predicate.iri)
							 assert_equal(2, #predObj.objectList)
							 obj = predObj.objectList[1]
							 assert_equal("PrefixedName", obj:nodeType())
							 assert_equal("ex", obj.prefix)
							 assert_equal("NonExistingClass", obj.name)
							 obj = predObj.objectList[2]
							 assert_equal("PrefixedName", obj:nodeType())
							 assert_equal("ex", obj.prefix)
							 assert_equal("AnotherClass", obj.name)
					   end)
					   it("should parse the bnode property list", function ()
							 local triple = parsed[6]
							 assert_equal("SpoTriple", triple:nodeType())
							 assert_equal("IriRef", triple.subject:nodeType())
							 assert_equal("http://www.w3.org/TR/rdf-syntax-grammar", triple.subject.iri)
							 assert_equal(2, #triple.predicateObjectList)
							 local predObj = triple.predicateObjectList[1]
							 assert_equal("PrefixedName", predObj.predicate:nodeType())
							 assert_equal("dc:title", tostring(predObj.predicate))
							 assert_equal(1, #predObj.objectList)
							 local obj = predObj.objectList[1]
							 assert_equal("TypedString", obj:nodeType())
							 assert_equal("RDF/XML Syntax Specification (Revised)", obj.value)
							 assert_equal("PrefixedName", obj.datatype:nodeType())
							 assert_equal("xsd:string", tostring(obj.datatype))

							 predObj = triple.predicateObjectList[2]
							 assert_equal("PrefixedName", predObj.predicate:nodeType())
							 assert_equal("ex:editor", tostring(predObj.predicate))
							 assert_equal(1, #predObj.objectList)
							 obj = predObj.objectList[1]
							 assert_equal("Bnode", obj:nodeType())
							 assert_equal(2, #obj.predicateObjectList)

							 -- overwrite the "parent" predObj
							 predObj = obj.predicateObjectList[1]
							 assert_equal("PredicateObject", predObj:nodeType())
							 assert_equal("PrefixedName", predObj.predicate:nodeType())
							 assert_equal("ex:fullname", tostring(predObj.predicate))
							 assert_equal(1, #predObj.objectList)
							 assert_equal("Dave Beckett", predObj.objectList[1].value)

							 predObj = obj.predicateObjectList[2]
							 assert_equal("PredicateObject", predObj:nodeType())
							 assert_equal("PrefixedName", predObj.predicate:nodeType())
							 assert_equal("ex:homePage", tostring(predObj.predicate))
							 assert_equal(1, #predObj.objectList)
							 assert_equal("IriRef", predObj.objectList[1]:nodeType())
							 assert_equal("http://purl.org/net/dajobe/", predObj.objectList[1].iri)
					   end)
			end)
end)

local test2 = [[
@prefix ericFoaf: <http://www.w3.org/People/Eric/ericP-foaf.rdf#> .
@prefix : <http://xmlns.com/foaf/0.1/> .

ericFoaf:ericP :givenName "Eric" ;
              :knows <http://norman.walsh.name/knows/who/dan-brickley> ,
                      [ :mbox <mailto:timbl@w3.org> ] ,
                      <http://getopenid.com/amyvdh> .
]]

local test3 = [[
@prefix : <http://example.org/stuff/1.0/> .
:a :b ( "apple" "banana" ) .
:a :b ( :apple "banana" <http://example.org/stuff/1.0/Pear> ) .
]]

local test4 = [[
@prefix : <http://example.org/stuff/1.0/> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
:a :b
  [ rdf:first "apple";
    rdf:rest [ rdf:first "banana";
               rdf:rest rdf:nil ]
  ] .
]]

local test5 = [[
@prefix : <http://example.org/stuff/1.0/> .

:a :b "1The first line\nThe second line\n  more" .

:a :b """2The first line
The second line
  more""" .
]]
