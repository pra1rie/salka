module salka;
import std.stdio : stderr, writeln;
import std.algorithm : each, canFind;
import std.array : split;
import std.conv : to;
import std.file : exists, isDir, readText;
import core.stdc.stdlib : exit;

// Better than JSON lmao
// TODO: perhaps add record/struct types

bool isNumber(string str)
{
	if (str == "") return false;
	string digits = "0123456789.";

	foreach (n; str) {
		if (!digits.canFind(n))
			return false;
	}
	return true;
}

void fail(string err)
{
	stderr.writeln("FAIL: " ~ err);
	exit(1);
}

enum ObjType
{
	NIL,
	STRING,
	INTEGER,
	FLOAT,
	LIST,
}

struct Obj
{
	ObjType type;
	string base;
	Obj[] list;

	this(long value)
	{
		type = ObjType.INTEGER;
		base = to!string(value);
	}

	this(double value)
	{
		type = ObjType.FLOAT;
		base = to!string(value);
	}

	this(string value)
	{
		type = (value == "")? ObjType.NIL : ObjType.STRING;
		base = value;
	}

	this(Obj[] value)
	{
		type = ObjType.LIST;
		list = value;
	}
}

string[] tokenize(string file)
{
	string ignored = "\t\r\n;";
	string separators = ",:![]\"";
	string[] toks;
	string text;

	bool isString, isComment;
	string toString;

	foreach (letter; file) {
		if (letter == '#' && !isString) {
			isComment = !isComment;
			continue;
		}
		if (isComment) continue;

		if (letter == '\"' && !isComment)
			isString = !isString;

		if (isString && letter == ' ') text ~= " \rspace\r ";
		if ((ignored ~ separators).canFind(letter))
			text ~= " " ~ letter ~ " ";
		else
			text ~= letter;
	}

	isString = false;
	toString = "";

	foreach (word; text.split(" ")) {
		if (word == "\"") {
			isString = !isString;
			if (!isString) {
				toks ~= "\"" ~ toString ~ "\"";
				toString = "";
			}
			continue;
		}
		if (isString) {
			if (word == "\rspace\r")
				toString ~= " ";
			else
				toString ~= word;
			continue;
		}

		if (word == "" || ignored.canFind(word)) continue;
		toks ~= word;
	}

	return toks;
}

final class Parser
{
public:
	Obj[string] vars;

private:
	string[] toks;
	size_t pos;

public:
	this(string file)
	{
		toks = tokenize(file);
		pos = 0;
	}

	void parse()
	{
		while (pos < toks.length) {
			parseExpr();
		}
	}

private:
	Obj parseExpr()
	{
		if (toks[pos].isNumber())
			return parseNumber();

		switch (toks[pos][0]) {
			case '\"':
				return parseString();
			case '[':
				return parseList();
			case ']':
			case ':':
			case '!':
			case ',':
				fail("Unexpected token: " ~ toks[pos]);
				assert(false, "Unreachable");
			default:
				return parseName();
		}
	}
	
	Obj parseNumber()
	{
		auto num = toks[pos++];
		if (num.canFind('.'))
			return Obj(to!double(num));
		return Obj(to!long(num));
	}

	Obj parseString()
	{
		auto str = toks[pos++][1..$-1];
		return Obj(str);
	}

	Obj parseList()
	{
		Obj[] list;
		++pos; // [
		list ~= parseExpr();

		while (pos < toks.length && toks[pos] == ",") {
			++pos;
			if (toks[pos] == "]") break;
			list ~= parseExpr();
		}

		if (pos >= toks.length)
			fail("Unexpected EOF");

		if (toks[pos] != "]")
			fail("Expected ']', but found '" ~ toks[pos] ~ "'");
		++pos; // ]
		return Obj(list);
	}

	Obj parseName()
	{
		auto name = toks[pos++];
		if (pos < toks.length && toks[pos] == ":") {
			++pos;
			auto expr = parseExpr();
			vars[name] = expr;
			return expr;
		}

		if (!(name in vars))
			fail("Variable does not exist: " ~ name);

		Obj var = vars[name];

		if (pos < toks.length && toks[pos] == "!") {
			return parseListIndex(var);
		}

		return var;
	}

	Obj parseListIndex(Obj var)
	{
		++pos;
		auto expr = parseExpr();
		
		if (var.type != ObjType.LIST)
			fail("Expected list, but found: " ~ var.getObj);

		if (expr.type != ObjType.INTEGER)
			fail("Expected integer, but found: " ~ expr.getObj);

		auto num = to!ulong(expr.base);
		if (num >= var.list.length)
			fail("List index out of range: " ~ expr.getObj);

		Obj obj = var.list[num];
		if (pos < toks.length && toks[pos] == "!") {
			return parseListIndex(obj);
		}

		return obj;
	}
}

string getObj(Obj obj)
{
	switch (obj.type) {
		case ObjType.NIL:
			return "nil";
		case ObjType.STRING:
			return "\"" ~ obj.base ~ "\"";
		case ObjType.LIST:
			string s = "[";
			foreach (o; obj.list)
				s ~= o.getObj ~ ", ";
			return s[0..$-2] ~ "]";
		default:
			return obj.base;
	}
}

Obj[string] loadConfig(string path)
{
	if (!path.exists || path.isDir)
		fail("Could not open file: " ~ path);

	Parser cfg = new Parser(readText(path));
	cfg.parse();

	return cfg.vars;
}
