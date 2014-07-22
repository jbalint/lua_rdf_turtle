-- tests for Turtle library
-- using Telescope framework (https://github.com/norman/telescope)

local turtle = require("turtle")
local _dump = require("pl.pretty").dump

describe("Turtle Parsing of Example Documents", function()
			---------------------------------------
			context("test document 1 - basics", function ()
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
							 assert_equal("RdfDoc", parsed:nodeType())
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

			---------------------------------------
			context("test document 2", function ()
					   local test2 = [[
                               @prefix ericFoaf: <http://www.w3.org/People/Eric/ericP-foaf.rdf#> .
                               @prefix : <http://xmlns.com/foaf/0.1/> .
                               
                               ericFoaf:ericP :givenName "Eric" ;
                                             :knows <http://norman.walsh.name/knows/who/dan-brickley> ,
                                                     [ :mbox <mailto:timbl@w3.org> ] ,
                                                     <http://getopenid.com/amyvdh> .
                               ]]
					   local parsed
					   it("should parse the document", function ()
							 parsed = turtle.parse(test2)
							 assert_equal("table", type(parsed))
							 assert_equal("table", type(parsed[1]))
							 assert_equal(3, #parsed)
					   end)
					   it("should handle blank prefixes", function ()
							 local prefix = parsed[2]
							 assert_equal("Prefix", prefix:nodeType())
							 assert_equal("", prefix.prefix)
							 assert_equal("IriRef", prefix.iriRef:nodeType())
							 assert_equal("http://xmlns.com/foaf/0.1/", prefix.iriRef.iri)
					   end)
					   it("should represent structure", function ()
							 local triple = parsed[3]
							 assert_equal("SpoTriple", triple:nodeType())
							 assert_equal("PrefixedName", triple.subject:nodeType())
							 assert_equal("ericFoaf:ericP", tostring(triple.subject))
							 assert_equal(2, #triple.predicateObjectList)

							 local predObj = triple.predicateObjectList[1]
							 assert_equal("PrefixedName", predObj.predicate:nodeType())
							 assert_equal(":givenName", tostring(predObj.predicate))
							 assert_equal("Eric", predObj.objectList[1].value)

							 predObj = triple.predicateObjectList[2]
							 assert_equal(":knows", tostring(predObj.predicate))
							 assert_equal(3, #predObj.objectList)

							 local obj = predObj.objectList[1]
							 assert_equal("IriRef", obj:nodeType())
							 assert_equal("http://norman.walsh.name/knows/who/dan-brickley", obj.iri)

							 obj = predObj.objectList[2]
							 assert_equal("Bnode", obj:nodeType())
							 assert_equal(1, #obj.predicateObjectList)
							 assert_equal(":mbox", tostring(obj.predicateObjectList[1].predicate))
							 assert_equal(1, #obj.predicateObjectList[1].objectList)
							 assert_equal("IriRef", obj.predicateObjectList[1].objectList[1]:nodeType())
							 assert_equal("mailto:timbl@w3.org", obj.predicateObjectList[1].objectList[1].iri)

							 obj = predObj.objectList[3]
							 assert_equal("IriRef", obj:nodeType())
							 assert_equal("http://getopenid.com/amyvdh", obj.iri)
					   end)
			end)

			---------------------------------------
			context("test document 3 - collections, short syntax", function ()
					   local test3 = [[
                               @prefix : <http://example.org/stuff/1.0/> .
                               :a :b ( "apple" "banana" ) .
                               :a :b ( :apple "banana" <http://example.org/stuff/1.0/Pear> ) .
                               ]]
					   local parsed
					   it("should parse the document", function ()
							 parsed = turtle.parse(test3)
							 assert_equal("table", type(parsed))
							 assert_equal("table", type(parsed[1]))
							 assert_equal(3, #parsed)
					   end)
					   it("should handle basic collections", function ()
							 local triple = parsed[2]
							 assert_equal("SpoTriple", triple:nodeType())
							 assert_equal(1, #triple.predicateObjectList)
							 assert_equal(1, #triple.predicateObjectList[1].objectList)
							 local obj = triple.predicateObjectList[1].objectList[1]
							 assert_equal("Collection", obj:nodeType())
							 assert_equal(2, #obj)
							 assert_equal("TypedString", obj[1]:nodeType())
							 assert_equal("apple", obj[1].value)
							 assert_equal("TypedString", obj[2]:nodeType())
							 assert_equal("banana", obj[2].value)

							 triple = parsed[3]
							 assert_equal("SpoTriple", triple:nodeType())
							 assert_equal(1, #triple.predicateObjectList)
							 assert_equal(":b", tostring(triple.predicateObjectList[1].predicate))
							 assert_equal(1, #triple.predicateObjectList[1].objectList)
							 obj = triple.predicateObjectList[1].objectList[1]
							 assert_equal(3, #obj)
							 assert_equal("Collection", obj:nodeType())
							 assert_equal("PrefixedName", obj[1]:nodeType())
							 assert_equal(":apple", tostring(obj[1]))
							 assert_equal("TypedString", obj[2]:nodeType())
							 assert_equal("banana", obj[2].value)
							 assert_equal("IriRef", obj[3]:nodeType())
							 assert_equal("http://example.org/stuff/1.0/Pear", obj[3].iri)
					   end)
			end)

			---------------------------------------
			context("test document 4 - collections, pure rdf", function ()
					   local test4 = [[
                               @prefix : <http://example.org/stuff/1.0/> .
                               @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
                               :a :b
                                 [ rdf:first "apple";
                                   rdf:rest [ rdf:first "banana";
                                              rdf:rest rdf:nil ]
                                 ] .
                               ]]
					   local parsed
					   it("should parse the document", function ()
							 parsed = turtle.parse(test4)
							 assert_equal("table", type(parsed))
							 assert_equal("table", type(parsed[1]))
							 assert_equal(3, #parsed)
					   end)
					   it("should represent the collection properly", function ()
							 local triple = parsed[3]
							 assert_equal("SpoTriple", triple:nodeType())
							 assert_equal(1, #triple.predicateObjectList)
							 local predObj = triple.predicateObjectList[1]
							 assert_equal(1, #predObj.objectList)
							 -- into the [rdf:first ...] node
							 local obj = predObj.objectList[1]
							 assert_equal("Bnode", obj:nodeType())
							 assert_equal(2, #obj.predicateObjectList)
							 predObj = obj.predicateObjectList[1]
							 assert_equal("rdf:first", tostring(predObj.predicate))
							 assert_equal(1, #predObj.objectList)
							 assert_equal("apple", predObj.objectList[1].value)
							 predObj = obj.predicateObjectList[2]
							 assert_equal("rdf:rest", tostring(predObj.predicate))
							 assert_equal(1, #predObj.objectList)
							 -- into the [rdf:rest ...] node
							 obj = predObj.objectList[1]
							 assert_equal("Bnode", obj:nodeType())
							 assert_equal(2, #obj.predicateObjectList)
							 predObj = obj.predicateObjectList[1]
							 assert_equal("rdf:first", tostring(predObj.predicate))
							 assert_equal(1, #predObj.objectList)
							 assert_equal("banana", predObj.objectList[1].value)
							 predObj = obj.predicateObjectList[2]
							 assert_equal("rdf:rest", tostring(predObj.predicate))
							 assert_equal(1, #predObj.objectList)
							 assert_equal("rdf:nil", tostring(predObj.objectList[1]))
					   end)
			end)

			---------------------------------------
			context("test document 5 - strings", function ()
					   -- the \n are represented by two-bytes
					   -- (literally) in Lua long strings - but
					   -- replaced by single-byte newlines in Turtle
					   -- parsing
					   local test5 = [[
                               @prefix : <http://example.org/stuff/1.0/> .

                               :a :b "1The first line\nThe second line\n  more" .

                               :a :b """2The first line
                               The second line
                                 more""" .

                               :a :b '3single quote string'.

                               :a :b '''4triple single quote string'''.
                               ]]
					   local parsed
					   it("should parse the document", function ()
							 parsed = turtle.parse(test5)
							 assert_equal("table", type(parsed))
							 assert_equal("table", type(parsed[1]))
							 assert_equal(5, #parsed)
					   end)
					   it("should parse strings correctly", function ()
							 local str = parsed[2].predicateObjectList[1].objectList[1].value
							 assert_equal("1The first line\nThe second line\n  more", str)
							 str = parsed[3].predicateObjectList[1].objectList[1].value
							 assert_equal("2The first line\n                               The second line\n                                 more", str)
							 str = parsed[4].predicateObjectList[1].objectList[1].value
							 assert_equal("3single quote string", str)
							 str = parsed[5].predicateObjectList[1].objectList[1].value
							 assert_equal("4triple single quote string", str)
					   end)
			end)
end)

-- assigned locally in test, pass here before calling external
-- functions
local Massert_equal

local function testPrefix(s, iri, prefix)
   Massert_equal("Prefix", s:nodeType())
   Massert_equal(prefix, s.prefix)
   Massert_equal(iri, s.iriRef.iri)
end

local function testPrefixedName(s, prefix, name)
   Massert_equal("PrefixedName", s:nodeType())
   Massert_equal(prefix, s.prefix)
   Massert_equal(name, s.name)
end

local function testIriRef(s, iri)
   Massert_equal("IriRef", s:nodeType())
   Massert_equal(iri, s.iri)
end

local function testParseAndSerialize(ttl_string)
   local s = turtle.parse(ttl_string)
   Massert_equal("RdfDoc", s:nodeType(), "parse should produce a list of tables")
   local serialized = turtle.serialize(s)
   Massert_equal(ttl_string, serialized)
end

describe("Basic Turtle Parsing", function ()

			context("strings", function ()
					   it("should parse simple strings", function ()
							 local s = turtle.parse('test:X a "abc".')
							 assert_equal("abc", s[1].predicateObjectList[1].objectList[1].value)
					   end)
					   it("should un-escape embedded escaped quotes", function ()
							 local s = turtle.parse('test:X a "a\\\"bc".')
							 assert_equal("a\"bc", s[1].predicateObjectList[1].objectList[1].value)
					   end)
			end)

			context("long strings", function ()
					   it("should parse long strings", function ()
							 local s = turtle.parse([[test:X a """blablabla""".]])
							 assert_equal("blablabla", s[1].predicateObjectList[1].objectList[1].value)
					   end)
					   it("should process escapes in long strings", function ()
							 -- \n appears literally when inside [[ ... ]]
							 local s = turtle.parse([[test:X a """bla\nbla\nbla""".]])
							 assert_equal("bla\nbla\nbla", s[1].predicateObjectList[1].objectList[1].value)
					   end)
					   it("should unescape and support two quotes", function ()
							 local s = turtle.parse([[test:X a """hey \"BOY\"z he said "hi" two quotes "" cool """.]])
							 assert_equal("hey \"BOY\"z he said \"hi\" two quotes \"\" cool ", s[1].predicateObjectList[1].objectList[1].value)
							 s = turtle.parse([[test:X a """hey \"BOY\"z he said "hi" two quotes "" cool """^^xsd:string.]])
							 assert_equal("hey \"BOY\"z he said \"hi\" two quotes \"\" cool ", s[1].predicateObjectList[1].objectList[1].value)
					   end)
					   it("should process other escapes and handle single quotes", function ()
							 local s = turtle.parse([[test:X a """hey \"BOY"z ''" bsaid
two \tquotes\ncool """.]])
							 assert_equal("hey \"BOY\"z ''\" bsaid\ntwo 	quotes\ncool ", s[1].predicateObjectList[1].objectList[1].value)
					   end)
					   it("support many quotes", function ()
							 local s = turtle.parse([[test:X a """string inside a string -> ""\"x""\"""".]])
							 assert_equal("string inside a string -> \"\"\"x\"\"\"", s[1].predicateObjectList[1].objectList[1].value)
					   end)
			end)

			context("long string specific tests", function ()
					   it("should support single quote long string in parser")
					   it("three quotes", function ()
							 local s = turtle.parse([[<s> <p> """ ""\" """ .]])
							 assert_equal(" \"\"\" ", s[1].predicateObjectList[1].objectList[1].value)
					   end)
					   it("should support unicode escapes in parser \\u0061 etc")
					   it("three quotes no space", function ()
							 local s = turtle.parse([[<s> <p> """""\"""" .]])
							 assert_equal("\"\"\"", s[1].predicateObjectList[1].objectList[1].value)
					   end)
			end)

			context("native-typed strings", function ()
					   it("should handle numeric types", function ()
							 local s = turtle.parse([[<s> <p> 1.0e0. # parses of double because of exponent
                                                      <s> <p> 1.
                                                      <s> <p> 1.0. # parses as decimal because of no exponent]])
							 assert_equal(3, #s)
							 assert_equal("1.0e0", s[1].predicateObjectList[1].objectList[1].value)
							 assert_equal('"1.0e0"^^xsd:double', tostring(s[1].predicateObjectList[1].objectList[1]))
							 assert_equal("1", s[2].predicateObjectList[1].objectList[1].value)
							 assert_equal('"1"^^xsd:integer', tostring(s[2].predicateObjectList[1].objectList[1]))
							 assert_equal("1.0", s[3].predicateObjectList[1].objectList[1].value)
							 assert_equal('"1.0"^^xsd:decimal', tostring(s[3].predicateObjectList[1].objectList[1]))
					   end)
			end)

			context("custom-typed strings", function ()
			end)

			-- language tags are recognized by the parser, but not
			-- included in the parse tree output
			context("language tags", function ()
					   it("should parse simple language tags", function ()
							 local s = turtle.parse([[:a :b "abc"@ru.]])
							 assert_equal("abc", s[1].predicateObjectList[1].objectList[1].value)
					   end)
					   it("should parse all language tags", function ()
							 -- fixed this issue on dc-1.1.ttl, which
							 -- uses en-US

							 -- the turtle grammar I used didn't
							 -- define the second part as supporting
							 -- uppercase letters
							 local s = turtle.parse([[:a :b "abcXYZ"@en-US.]])
							 assert_equal("abcXYZ", s[1].predicateObjectList[1].objectList[1].value)
					   end)
			end)

			-- basic collection support, this is not decoded in
			-- RDF-list style by the turtle parser
			context("collections", function ()
					   it("should parse basic collections", function ()
							 local s = turtle.parse([[:a :b ( "apple" "banana" ) .]])
							 assert_equal("Collection", s[1].predicateObjectList[1].objectList[1]:nodeType())
							 assert_equal(2, #s[1].predicateObjectList[1].objectList[1])
							 assert_equal("apple", s[1].predicateObjectList[1].objectList[1][1].value)
							 assert_equal("banana", s[1].predicateObjectList[1].objectList[1][2].value)
					   end)
					   it("should parse collections with prefixed names and irirefs", function ()
							 Massert_equal = assert_equal
							 local s = turtle.parse([[:a :b ( :apple "banana" <http://example.org/stuff/1.0/Pear> ) .]])
							 assert_equal("Collection", s[1].predicateObjectList[1].objectList[1]:nodeType())
							 assert_equal(3, #s[1].predicateObjectList[1].objectList[1])
							 testPrefixedName(s[1].predicateObjectList[1].objectList[1][1], "", "apple")
							 assert_equal("banana", s[1].predicateObjectList[1].objectList[1][2].value)
							 testIriRef(s[1].predicateObjectList[1].objectList[1][3], "http://example.org/stuff/1.0/Pear")
							 -- end
							 Massert_equal = nil
					   end)
			end)

			context("miscellaneous", function ()
					   it("should parse prefix-only prefixed names", function ()
							 Massert_equal = assert_equal
							 local s = turtle.parse([[rdf:type  rdfs:isDefinedBy rdf: .]])
							 assert_equal(1, #s)
							 assert_equal(1, #s[1].predicateObjectList)
							 assert_equal(1, #s[1].predicateObjectList[1].objectList)
							 testPrefixedName(s[1].subject, "rdf", "type")
							 testPrefixedName(s[1].predicateObjectList[1].predicate, "rdfs", "isDefinedBy")
							 testPrefixedName(s[1].predicateObjectList[1].objectList[1], "rdf", "")
							 -- end
							 Massert_equal = nil
					   end)
			end)
end)

describe("Serialization - SKIPPED", function ()
			-- TODO: serialization tests are very incomplete
			context("serialization", function ()
					   it("should serialize unlabeled bnodes", function ()
							 -- we just use the same string and test
							 -- the parse+serialization is identical
							 -- to the original
							 -- (needs the newline as the serializer
							 -- adds it)
							 -- same with all ending in ;
							 local ttl_string = 'bsbase:Clear bsbase:homepage [rdf:type bibo:Webpage;bibo:uri "http://frdcsa.org/frdcsa/internal/clear/"^^xsd:string;];.\n'
							 Massert_equal = assert_equal
							 testParseAndSerialize(ttl_string)
							 Massert_equal = nil
					   end)
					   it("should handle embedded quotes", function ()
							 local ttl_string = 'bstest:xyz skos:editorialNote "based on \\\"Heinz Steals the Drug\\\""^^xsd:string;.\n'
							 Massert_equal = assert_equal
							 testParseAndSerialize(ttl_string)
							 Massert_equal = nil
					   end)
					   it("should handle multiple objects per predicate", function ()
							 local ttl_string = ':xyz :has :a, :b, :c;.\n'
							 Massert_equal = assert_equal
							 testParseAndSerialize(ttl_string)
							 Massert_equal = nil
					   end)
					   it("should handle lists", function ()
							 local ttl_string = 'bstest:something bstest:hasThese ( bstest:a bstest:b bstest:c);.\n'
							 Massert_equal = assert_equal
							 testParseAndSerialize(ttl_string)
							 Massert_equal = nil
					   end)
					   it("should handle RDF-style lists (nested anonymous nodes)", function ()
							 local ttl_string = "bstest:something bstest:hasThese [rdf:first bstest:a;rdf:rest [rdf:first bstest:b;rdf:rest [rdf:first bstest:c;rdf:rest rdf:nil;];];];.\n"
							 Massert_equal = assert_equal
							 testParseAndSerialize(ttl_string)
							 Massert_equal = nil
					   end)
					   it("should use triple-quotes for multi-line strings", function ()
							 -- it comes out with three quotes because
							 -- of the embedded newlines, not because
							 -- it's parsed with three quotes
							 local ttl_string = 'bstest:something bstest:hasX """jess\nis\nhere"""^^xsd:string;.\n'
							 Massert_equal = assert_equal
							 testParseAndSerialize(ttl_string)
							 Massert_equal = nil
					   end)
			end)
end)
