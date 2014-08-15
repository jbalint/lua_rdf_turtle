-- convert turtle ontologies to F-Logic/Flora-2
-- NOTE: this is not necessarily complete and built empirically from
-- converting standard ontologies
local ttl2flr = {}

local turtle = require("turtle")

local _dump = require("pl.pretty").dump

-- no default prefix support in Flora-2, so we save it here and
-- substitute it upon encountering it
local _DEFAULT_PREFIX_IRI

-- prefix index necessary to expand Qnames with a prefix only and no
-- name
local _PREFIXES = {}

local print = print

local function _printPrefix(p)
   if p.prefix == "" then
	  _DEFAULT_PREFIX_IRI = p.iriRef.iri
   else
	  _PREFIXES[p.prefix] = p.iriRef.iri
	  print(string.format(":- iriprefix{%s='%s'}.", p.prefix, p.iriRef.iri))
   end
end

local bnodeContext = "<no bnode context assigned>"
local bnodeCount = 0
local function _setBnodeContext(x)
   bnodeContext = x
end

-- aligns with B.S./crate_turtle way of assigning Flora oids
local function _newBnodeName()
   local num = bnodeCount
   bnodeCount = bnodeCount + 1
   local bnodeName = string.format("urn:X-bnode:bnode_%s_%d", bnodeContext, num)
   return bnodeName
end

-- forward declaration
local _predobj2str

-- convert a resource (IriRef, Qname) string value for Flora-2
local function _rsrc2str(r)
   if r:nodeType() == "IriRef" then
	  return string.format("\"%s\"^^\\iri", r.iri)
   elseif r:nodeType() == "PrefixedName" then
	  local n = r.name
	  -- prefix only and no name
	  if n == "" then
		 assert(_PREFIXES[r.prefix], "Prefix must be defined: " .. r.prefix)
		 return string.format("\"%s\"^^\\iri", _PREFIXES[r.prefix])
	  -- dcterms has "dcterms:ISO639-2"
	  elseif n:find("-") then -- TODO make this more robustly handle forbidden chars in F-atoms
		 n = "'" .. n .. "'"
	  end
	  if r.prefix == "" then
		 assert(_DEFAULT_PREFIX_IRI, "Default prefix encountered, but none defined")
		 return string.format("\"%s%s\"^^\\iri", _DEFAULT_PREFIX_IRI, n)
	  end
	  return string.format("%s#%s", r.prefix, n)
   elseif r:nodeType() == "Bnode" then
	  local bnodeName = string.format('"%s"^^\\iri',  _newBnodeName())
	  for _idx, predobj in ipairs(r.predicateObjectList) do
		 _predobj2str(bnodeName, predobj)
	  end
	  return bnodeName
   else
	  _dump(r)
	  error("Unknown resource")
   end
end

-- convert an object (resource or literal (TypedString)) to a string
-- value for Flora-2
local function _obj2str(o)
   -- TODO need proper string processing
   if type(o) == "string" then
	  -- we should *ONLY* emit "string" objects, not charlist
	  return '"' .. o:gsub('"', '\\"') .. '"^^\\string'
   elseif o:nodeType() == "TypedString" then
	  local t
	  local v = o.value:gsub('"', '\\"')
	  if o.datatype:nodeType() == "IriRef" then
		 t = o.datatype.iri:gsub("http://www.w3.org/2001/XMLSchema", "xsd")
	  elseif o.datatype:nodeType() == "PrefixedName" then
		 t = string.format("%s#%s", o.datatype.prefix, o.datatype.name)
	  else
		 _dump(o)
		 error("Unknown datatype type")
	  end
	  -- Flora doesn't like Z at the end of dates
	  if t:match("#date$") then
		 v = v:gsub("Z$", "")
	  end
	  return string.format("\"%s\"^^%s", v, t)
   elseif o:nodeType() == "Collection" then
	  local strval = "{"
	  for idx, v in ipairs(o) do
		 local strv = _obj2str(v)
		 if strval == "{" then
			strval = strval .. strv
		 else
			strval = strval .. ", " .. strv
		 end
	  end
	  return strval .. "}"
   else
	  return _rsrc2str(o)
   end
end

function _predobj2str(sub, predobj)
   for _idx, obj in ipairs(predobj.objectList) do
	  print(string.format("%s[%s -> %s].",
						  sub,
						  _rsrc2str(predobj.predicate),
						  _obj2str(obj)))
   end
end

if not pcall(getfenv, 4) then
   -- run script
   local infile = arg[1]
   local outfile = arg[2]
   if not arg[1] or not arg[2] then
	  print("Turtle to Flora translator")
	  print("Argument 1: input file")
	  print("Argument 2: output file")
	  return
   end
   local f = io.open(infile, "r")
   local content = f:read("*all")
   f:close()

   local out = io.open(outfile, "w")
   print = function (x)
	  out:write(x)
	  out:write("\n")
   end

   local s = turtle.parse(content)
   -- use the filename to set the bnode context. remove the version
   -- number convention used in Nepomuk ontologies
   _setBnodeContext(outfile:gsub(".flr$", ""):gsub("%W", "_"):gsub("_v._.", ""))

   for idx, el in ipairs(s) do
	  if el:nodeType() == "Prefix" then
		 _printPrefix(el)
	  elseif el:nodeType() == "SpoTriple" then
		 print("")
		 local sub = _rsrc2str(el.subject)
		 for idx2, pred in ipairs(el.predicateObjectList) do
			_predobj2str(sub, pred)
		 end
	  end
   end
end

return ttl2flr
