-- Turtle - A module for working with Turtle (RDF) format data

-- * TODO resolve relative IRIs according to current base IRI

local turtle = {}

local lpeg = require('lpeg')
local re = require('re')

local P, R, S, V = lpeg.P, lpeg.R, lpeg.S, lpeg.V
local C, Cc, Cf, Cg, Cs, Ct, Cmt = lpeg.C, lpeg.Cc, lpeg.Cf, lpeg.Cg, lpeg.Cs, lpeg.Ct, lpeg.Cmt

-- optional, used for debugging
local _dump = require('pl.pretty').dump

-- http://www.w3.org/TR/turtle/
-- When tokenizing the input and choosing grammar rules, the longest match is chosen.

-- not defined in spec's EBNF. Any uses of this are added by me
-- [10]comment::='#' ( [^#xA#xD] )*
local comment = P"#"*(R"\x00\xff"-S"\r\n")^0

------------------
-- Internal API --
------------------
local RdfDoc = {classname="RdfDoc"}
local IriRef = {classname="IriRef"}
local Bnode = {classname="Bnode"}
local Prefix = {classname="Prefix"}
local SpoTriple = {classname="SpoTriple"}
local PrefixedName = {classname="PrefixedName"}
local PredicateObject = {classname="PredicateObject"}
local TypedString = {classname="TypedString"}
local Collection = {classname="Collection"}

local function _nodeType(obj)
   return getmetatable(obj).classname
end

local classes = {RdfDoc, IriRef, Bnode, Prefix, SpoTriple, PrefixedName, PredicateObject, TypedString, Collection}
for idx, class in ipairs(classes) do
   class.__index = class
   class.nodeType = _nodeType
   turtle[class.classname] = class
end

local function _newObject(class, base)
   setmetatable(base, class)
   return base
end

function RdfDoc._new(statements)
   return _newObject(RdfDoc, statements)
end

function RdfDoc:visit(visitor)
   visitor:visitRdfDocBegin(self)
   for _idx, node in ipairs(self) do
	  node:visit(visitor)
   end
   visitor:visitRdfDocEnd(self)
end

function IriRef._new(iri)
   return _newObject(IriRef, {iri=iri})
end

function IriRef:__tostring()
   return string.format("<%s>", self.iri)
end

function IriRef:visit(visitor)
   visitor:visitObject(self)
end

function Bnode._new(predicateObjectList)
   return _newObject(Bnode, {predicateObjectList=predicateObjectList})
end

function Bnode:visit(visitor)
   visitor:visitBnodeBegin(self)
   for _idx, predObj in ipairs(self.predicateObjectList) do
	  predObj:visit(visitor)
   end
   visitor:visitBnodeEnd(self)
end

function Prefix._new(prefix, iriRef)
   return _newObject(Prefix, {prefix=prefix, iriRef=iriRef})
end

function Prefix:visit(visitor)
   visitor:visitPrefix(self)
   -- prefix IriRefs are not visited separately
end

function SpoTriple._new(subject, predicateObjectList)
   return _newObject(SpoTriple, {subject=subject, predicateObjectList=predicateObjectList})
end

function SpoTriple:visit(visitor)
   visitor:visitSpoTripleBegin(self)
   visitor:visitSubject(self.subject)
   for _idx, predObj in ipairs(self.predicateObjectList) do
	  predObj:visit(visitor)
   end
   visitor:visitSpoTripleEnd(self)
end

function PrefixedName._new(prefix, name)
   -- name can be `nil' when the construct is something like
   -- "rdf:". We use the same parsing code for PNAME_NS as PNAME_LN
   return _newObject(PrefixedName, {prefix=prefix, name=name or ""})
end

function PrefixedName:__tostring()
   return string.format("%s:%s", self.prefix, self.name)
end

function PrefixedName:visit(visitor)
   visitor:visitObject(self)
end

function PredicateObject._new(predicate, objectList)
   return _newObject(PredicateObject, {predicate=predicate, objectList=objectList})
end

function PredicateObject:visit(visitor)
   visitor:visitPredicateObjectBegin(self)
   visitor:visitPredicate(self.predicate)
   for _idx, obj in ipairs(self.objectList) do
	  obj:visit(visitor)
   end
   visitor:visitPredicateObjectEnd(self)
end

function TypedString._getCtor(datatype)
   return function (value)
	  return TypedString._new(value, datatype)
   end
end

function TypedString._processStringEscapes(str)
   str = str:gsub([[\"]], '"'):gsub('\\t', "\x09"):gsub('\\n', "\x0a"):gsub('\\r', "\x0d")
   return str
end

function TypedString._new(value, datatype)
   if datatype == turtle.XsdStringName
   or (datatype.prefix == "xsd" and datatype.name == "string")
   or datatype.iri == "http://www.w3.org/2001/XMLSchema#string" then
	  value = TypedString._processStringEscapes(value)
   end
   return _newObject(TypedString, {value=value, datatype=datatype})
end

function TypedString:__tostring()
   local v = self.value:gsub('"', '\\"')
   local quote = '"'
   if v:find("\n") then
	  quote = '"""'
   end
   return string.format('%s%s%s^^%s',
						quote, v, quote, tostring(self.datatype))
end

function TypedString:visit(visitor)
   visitor:visitObject(self)
end

function Collection._new(values)
   -- the raw list is used as the collection - no k/v wrapper
   return _newObject(Collection, values)
end

function Collection:visit(visitor)
   visitor:visitCollectionBegin(self)
   for _idx, entry in ipairs(self) do
	  entry:visit(visitor)
   end
   visitor:visitCollectionEnd(self)
end

local function _setBase(iriRef)
   print("Setting base to ", iriRef.iri)
   error("NEED TO TEST THIS")
end

turtle.RdfTypeIri = IriRef._new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type")
turtle.XsdDecimalName = PrefixedName._new("xsd", "decimal")
turtle.XsdDoubleName = PrefixedName._new("xsd", "double")
turtle.XsdIntegerName = PrefixedName._new("xsd", "integer")
turtle.XsdStringName = PrefixedName._new("xsd", "string")

-------------------
-- Serialization --
-------------------
local SerializationVisitor = {}
SerializationVisitor.__index = SerializationVisitor

-- append line to output
function SerializationVisitor:appendLine(line)
   self.serialized = self.serialized .. line .. "\n"
end

function SerializationVisitor:appendString(str)
   self.serialized = self.serialized .. str
end

function SerializationVisitor:visitRdfDocBegin(doc)
end

function SerializationVisitor:visitRdfDocEnd(doc)
end

function SerializationVisitor:visitPrefix(prefix)
   self:appendLine(string.format("@prefix %s: <%s>.", prefix.prefix, prefix.iriRef.iri))
end

function SerializationVisitor:visitBnodeBegin(bnode)
   self:appendString("[")
end

function SerializationVisitor:visitBnodeEnd(bnode)
   self:appendString("]")
end

function SerializationVisitor:visitSpoTripleBegin(triple)
   assert(self.subject == nil)
end

function SerializationVisitor:visitSpoTripleEnd(triple)
   self.subject = nil
   self:appendLine(".")
end

function SerializationVisitor:visitSubject(subject)
   -- TODO bnode subject not supported in serialized yet
   assert(subject:nodeType() == "IriRef" or subject:nodeType() == "PrefixedName")
   self:appendString(tostring(subject) .. " ")
end

function SerializationVisitor:visitPredicateObjectBegin(predObj)
end

function SerializationVisitor:visitPredicateObjectEnd(predObj)
   self:appendString(";")
   self.previousObject = nil
end

function SerializationVisitor:visitPredicate(predicate)
   self:appendString(tostring(predicate) .. " ")
end

function SerializationVisitor:visitCollectionBegin(collection)
   self:appendString("(")
   -- we need to track this to use a different separator for object
   -- list serialization
   self.inCollection = true
end

function SerializationVisitor:visitCollectionEnd(collection)
   self:appendString(")")
   self.inCollection = false
end

function SerializationVisitor:visitObject(object)
   if self.inCollection then
	  self:appendString(" " .. tostring(object))
   elseif self.previousObject then
	  self:appendString(", " .. tostring(object))
   else
	  self:appendString(tostring(object))
	  self.previousObject = object
   end
end

local function _serialize(rdfDoc)
   local ser = {serialized=""}
   setmetatable(ser, SerializationVisitor)
   rdfDoc:visit(ser)
   return ser.serialized
end

-------------------------------
-- Productions for terminals --
-------------------------------

-- [172s]PN_LOCAL_ESC::='\' ('_' | '~' | '.' | '-' | '!' | '$' | '&' | "'" | '(' | ')' | '*' | '+' | ',' | ';' | '=' | '/' | '?' | '#' | '@' | '%')
local PN_LOCAL_ESC = P"\\"*S"_~.-!$&'()*+,;=/?#@%"

-- [171s]HEX::=[0-9] | [A-F] | [a-f]
local HEX = R"09"+R"AF"+R"af"

-- [170s]PERCENT::='%' HEX HEX
local PERCENT = P"%"*HEX*HEX

-- [169s]PLX::=PERCENT | PN_LOCAL_ESC
local PLX = PERCENT+PN_LOCAL_ESC

-- [163s]PN_CHARS_BASE::=[A-Z] | [a-z] | [#x00C0-#x00D6] | [#x00D8-#x00F6] | [#x00F8-#x02FF] | [#x0370-#x037D] | [#x037F-#x1FFF] | [#x200C-#x200D] | [#x2070-#x218F] | [#x2C00-#x2FEF] | [#x3001-#xD7FF] | [#xF900-#xFDCF] | [#xFDF0-#xFFFD] | [#x10000-#xEFFFF]
-- TODO higher range codepoints
local PN_CHARS_BASE = R"AZ"+R"az"+R"\xc0\xd6"+R"\xd8\xf6"

-- [164s]PN_CHARS_U::=PN_CHARS_BASE | '_'
local PN_CHARS_U = PN_CHARS_BASE+P"_"

-- [166s]PN_CHARS::=PN_CHARS_U | '-' | [0-9] | #x00B7 | [#x0300-#x036F] | [#x203F-#x2040]
-- TODO unicode
local PN_CHARS = PN_CHARS_U+P"-"+R"09"+P"\xb7"

-- [167s]PN_PREFIX::=PN_CHARS_BASE ((PN_CHARS | '.')* PN_CHARS)?
--local PN_PREFIX = PN_CHARS_BASE*((PN_CHARS+P".")^0*PN_CHARS)^-1
-- rewritten in PEG-style
local PN_PREFIX = PN_CHARS_BASE*(P"."^0*PN_CHARS)^0

-- [168s]PN_LOCAL::=(PN_CHARS_U | ':' | [0-9] | PLX) ((PN_CHARS | '.' | ':' | PLX)* (PN_CHARS | ':' | PLX))?
--local PN_LOCAL = (PN_CHARS_U+P":"+R"09"+PLX)*((PN_CHARS+P"."+P":"+PLX)^0*(PN_CHARS+P":"+PLX))^-1
-- rewritten in PEG-style
local PN_LOCAL = C((PN_CHARS_U+P":"+R"09"+PLX)*(P"."^0*(PN_CHARS+P":"+PLX))^0)

-- [26]UCHAR::='\u' HEX HEX HEX HEX | '\U' HEX HEX HEX HEX HEX HEX HEX HEX
local UCHAR = (P"\\u"*HEX*HEX*HEX*HEX)+(P"\\U"*HEX*HEX*HEX*HEX*HEX*HEX*HEX*HEX)

-- [159s]ECHAR::='\' [tbnrf"'\]
local ECHAR = P"\\"*S"tbnrf\"'\\"

-- [161s]WS::=#x20 | #x9 | #xD | #xA /* #x20=space #x9=character tabulation #xD=carriage return #xA=new line */
local WS = P" "+P"\t"+P"\r"+P"\n"+comment
local JBWS = WS^1 -- necessary whitespace in the grammar added by me
local JBWS0 = WS^0 -- optional whitespace in the grammar added by me

-- [162s]ANON::='[' WS* ']'
local ANON = P"["*WS^0*P"]"

-- [18]IRIREF::='<' ([^#x00-#x20<>"{}|^`\] | UCHAR)* '>' /* #x00=NULL #01-#x1F=control codes #x20=space */
local IRIREF = P"<"*((re.compile("[^\x00-\x20<>\"{}|^`\\]")+UCHAR)^0/IriRef._new)*P">"

-- [139s]PNAME_NS::=PN_PREFIX? ':'
local PNAME_NS = C(PN_PREFIX+P"")*P":"

-- [140s]PNAME_LN::=PNAME_NS PN_LOCAL
local PNAME_LN = PNAME_NS*PN_LOCAL

-- [141s]BLANK_NODE_LABEL::='_:' (PN_CHARS_U | [0-9]) ((PN_CHARS | '.')* PN_CHARS)?
--local BLANK_NODE_LABEL = P"_:"*(PN_CHARS_U+R"09")*((PN_CHARS+P".")^0*PN_CHARS)^-1
-- rewritten in PEG-style
local BLANK_NODE_LABEL = P"_:"*(PN_CHARS_U+R"09")*(P"."^0*PN_CHARS)^0

-- [144s]LANGTAG::='@' [a-zA-Z]+ ('-' [a-zA-Z0-9]+)*
local LANGTAG = P"@"*(R"az"+R"AZ")^1*(P"-"*(R"az"+R"AZ"+R"09")^1)^0

-- [19]INTEGER::=[+-]? [0-9]+
local INTEGER = C(S"+-"^-1*R"09"^1)*Cc(turtle.XsdIntegerName)/TypedString._new

-- [20]DECIMAL::=[+-]? [0-9]* '.' [0-9]+
local DECIMAL = C(S"+-"^-1*R"09"^0*P"."*R"09"^1)*Cc(turtle.XsdDecimalName)/TypedString._new

-- [154s]EXPONENT::=[eE] [+-]? [0-9]+
local EXPONENT = S"eE"*S"+-"^-1*R"09"^1

-- [21]DOUBLE::=[+-]? ([0-9]+ '.' [0-9]* EXPONENT | '.' [0-9]+ EXPONENT | [0-9]+ EXPONENT)
local DOUBLE = C(S"+-"^-1*((R"09"^1*P"."*R"09"^0*EXPONENT)+(P"."*R"09"^1*EXPONENT)+(R"09"^1*EXPONENT)))*Cc(turtle.XsdDoubleName)/TypedString._new

-- [16]NumericLiteral::=INTEGER | DECIMAL | DOUBLE
local NumericLiteral = DOUBLE+DECIMAL+INTEGER

-- [22]STRING_LITERAL_QUOTE::='"' ([^#x22#x5C#xA#xD] | ECHAR | UCHAR)* '"' /* #x22=" #x5C=\ #xA=new line #xD=carriage return */
local STRING_LITERAL_QUOTE = P'"'*C((R"\x00\xff"-S"\x22\x5C\x0a\x0d"+ECHAR+UCHAR)^0)*P'"'

-- [23]STRING_LITERAL_SINGLE_QUOTE::="'" ([^#x27#x5C#xA#xD] | ECHAR | UCHAR)* "'" /* #x27=' #x5C=\ #xA=new line #xD=carriage return */
local STRING_LITERAL_SINGLE_QUOTE = P"'"*C((R"\x00\xff"-S"\x27\x5C\x0a\x0d"+ECHAR+UCHAR)^0)*P"'"

-- [24]STRING_LITERAL_LONG_SINGLE_QUOTE::="'''" (("'" | "''")? ([^'\] | ECHAR | UCHAR))* "'''"
local STRING_LITERAL_LONG_SINGLE_QUOTE = P"'''"*C((P"'"^-2*(re.compile("[^'\\]")+ECHAR+UCHAR))^0)*P"'''"

-- [25]STRING_LITERAL_LONG_QUOTE::='"""' (('"' | '""')? ([^"\] | ECHAR | UCHAR))* '"""'
local STRING_LITERAL_LONG_QUOTE = P'"""'*C((P'"'^-2*(re.compile('[^"\\]')+ECHAR+UCHAR))^0)*P'"""'

-- [17]String::=STRING_LITERAL_QUOTE | STRING_LITERAL_SINGLE_QUOTE | STRING_LITERAL_LONG_SINGLE_QUOTE | STRING_LITERAL_LONG_QUOTE
-- ***NOTE*** ORDER IS IMPORTANT HERE - long-quote forms have to come before single-quote forms
local String = STRING_LITERAL_LONG_SINGLE_QUOTE+STRING_LITERAL_LONG_QUOTE+STRING_LITERAL_QUOTE+STRING_LITERAL_SINGLE_QUOTE

-- [4]prefixID::='@prefix' PNAME_NS IRIREF '.'
local prefixID = P"@prefix"*JBWS*PNAME_NS*JBWS*IRIREF*JBWS0*P"."/Prefix._new

-- [5]base::='@base' IRIREF '.'
local base = P"@base"*JBWS*IRIREF*JBWS0*P"."/_setBase

-- [5s]sparqlBase::="BASE" IRIREF
local sparqlBase = P"BASE"*IRIREF/_setBase

-- [6s]sparqlPrefix::="PREFIX" PNAME_NS IRIREF
local sparqlPrefix = P"PREFIX"*PNAME_NS*IRIREF/Prefix._new

-- [136s]PrefixedName::=PNAME_LN | PNAME_NS
local PrefixedName = (PNAME_LN+PNAME_NS)/PrefixedName._new

-- [135s]iri::=IRIREF | PrefixedName
local iri = IRIREF+PrefixedName

-- [137s]BlankNode::=BLANK_NODE_LABEL | ANON
local BlankNode = BLANK_NODE_LABEL+ANON

-- [11]predicate::=iri
local predicate = iri

-- [9]verb::=predicate | 'a'
-- transforms a -> rdf:type
local verb = predicate+ (P"a"*Cc(turtle.RdfTypeIri))

-- [128s]RDFLiteral::=String (LANGTAG | '^^' iri)?
local RDFLiteral = String*(P"^^"*iri+(LANGTAG^-1*Cc(turtle.XsdStringName)))/TypedString._new

-- [133s]BooleanLiteral::='true' | 'false'
local BooleanLiteral = P"true"+P"false"

-- [13]literal::=RDFLiteral | NumericLiteral | BooleanLiteral
local literal = RDFLiteral+NumericLiteral+BooleanLiteral

local function makeGrammar(elem)
   return P{elem;
			-- [15]collection::='(' object* ')'
			collection = P"("*JBWS0*Ct((V"object"*JBWS0)^0)*P")"/Collection._new,

			-- [12]object::=iri | BlankNode | collection | blankNodePropertyList | literal
			object = iri+BlankNode+V"collection"+V"blankNodePropertyList"+literal,

			-- [14]blankNodePropertyList::='[' predicateObjectList ']'
			blankNodePropertyList = P"["*JBWS0*(V"predicateObjectList"/Bnode._new)*P"]",

			-- [7]predicateObjectList::=verb objectList (';' (verb objectList)?)*
			predicateObject = (verb*JBWS*V"objectList")/PredicateObject._new,
			predicateObjectList = Ct(V"predicateObject"*JBWS0*(P";"*JBWS0*(V"predicateObject"*JBWS0)^-1)^0),

			-- [8]objectList::=object (',' object)*
			objectList = Ct(V"object"*(JBWS0*P","*JBWS0*V"object")^0)
   }
end

local collection = makeGrammar("collection")
local object = makeGrammar("object")
local blankNodePropertyList = makeGrammar("blankNodePropertyList")
local predicateObjectList = makeGrammar("predicateObjectList")

local objectList = makeGrammar("objectList")

-- [10]subject::=iri | BlankNode | collection
local subject = iri+BlankNode+collection
-- TODO c.f. ex. 23+24 for collection as subject

-- [6]triples::=subject predicateObjectList | blankNodePropertyList predicateObjectList?
local triples = subject*JBWS*predicateObjectList/SpoTriple._new
+
-- TODO
blankNodePropertyList*JBWS0*predicateObjectList^-1

-- [3]directive::=prefixID | base | sparqlPrefix | sparqlBase
local directive = prefixID+base+sparqlPrefix+sparqlBase

-- [2]statement::=directive | triples '.'
local statement = directive+triples*JBWS0*P"."

-- [1]turtleDoc::=statement*
local turtleDoc = Ct((JBWS0*statement*JBWS0)^0*P(-1))/RdfDoc._new

----------------
-- Public API --
----------------
function turtle.parse(turtleString)
   return lpeg.match(turtleDoc, turtleString)
end

function turtle.serialize(rdfDoc)
   return _serialize(rdfDoc)
end

function turtle.parseFile(filename)
   local f = io.open(filename, "r")
   local content = f:read("*all")
   f:close()

   local s = turtle.parse(content)
   return s
end

if pcall(getfenv, 4) then
    --print("Library")
else
    --print("Main file")
   --turtle.parseFile("project.ttl")
end

return turtle
