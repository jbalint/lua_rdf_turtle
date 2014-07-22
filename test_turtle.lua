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
							 --assert_equal(
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
