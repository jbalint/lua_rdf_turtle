-- tests for Turtle library
-- using Telescope framework (https://github.com/norman/telescope)

local turtle = require("turtle")

describe("Turtle Parsing of Example Documents", function()
			context("test1", function ()
					   local test1 = [[
                               # First test snippet
                               @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
                               @prefix dc: <http://purl.org/dc/elements/1.1/> .
                               @prefix ex: <http://example.org/stuff/1.0/> .

                               ex:jess a ex:NonExistingClass ; a ex:AnotherClass .
                               ex:jess2 a ex:NonExistingClass , ex:AnotherClass .
# TODO need to handle the nested Bnode
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
							 assert_equal("IriRef", predObj.predicate:nodeType())
							 assert_equal("http://www.w3.org/1999/02/22-rdf-syntax-ns#type", predObj.predicate.iri)
							 assert_equal(turtle.RdfTypeIri.iri, predObj.predicate.iri)
							 assert_equal(1, #predObj.objectList)
							 local obj = predObj.objectList[1]
							 assert_equal("PrefixedName", obj:nodeType())
							 assert_equal("ex", obj.prefix)
							 assert_equal("NonExistingClass", obj.name)

							 predObj = spo.predicateObjectList[2]
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
