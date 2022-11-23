import std.stdio;
import core.stdc.stdlib : exit;
import salka;


void usage(string program)
{
	writeln("Usage:");
	writeln("  ", program, " <file>");
	exit(0);
}

void main(string[] args)
{
	if (args.length < 2)
		usage(args[0]);
	auto path = args[1];

	auto vars = loadConfig(path);
	foreach (var; vars.byKeyValue) {
		writeln(var.key, ": ", var.value.getObj());
	}
}
