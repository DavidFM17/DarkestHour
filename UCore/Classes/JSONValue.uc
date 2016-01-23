//==============================================================================
// Darklight Games (c) 2008-2015
//==============================================================================

class JSONValue extends Object
    abstract;

function bool IsString() { return false; }
function bool IsNull() { return false; }
function bool IsNumber() { return false; }
function bool IsBoolean() { return false; }
function bool IsObject() { return false; }
function bool IsList() { return false; }

function string AsString() { return ""; }
function JSONNumber AsNumber() { return none; }
function int AsInteger() { return 0; }
function float AsFloat() { return 0.0; }
function JSONObject AsObject() { return none; }
function JSONArray AsList() { return none; }

function string Encode() { return "null"; }