/*
Rhodeus Script (c) by Talha Zekeriya Durmuş

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/

module modules.main;
import interpreter;
import std.conv;
import std.array;
import parser;
import std.path;
import std.process;
import std.datetime;
static import library.mysql;
import std.string;
import std.stdio;
import std.math;
import std.format;
import std.file;
import std.ascii;
static import std.regex;
import Commands;
class _Main{
	Interpreter self;
	this( Interpreter x){
		this.self = x;
		self.kdM["print"] = &print;
		self.kdM["apptime"] = &apptime;
	}
	Command print(Command[] params,Command aktiv, dataManagement dM){
		foreach(para; params){
			self.output ~= para.run(dM).toString();
		}
		return new RhNone();
	}
	Command apptime(Command[] params,Command aktiv, dataManagement dM){
		return new RhInt(to!int(Clock.currAppTick().usecs()));
	}

}
version(Windows) {
	import core.sys.windows.windows;
	extern(Windows) DWORD GetTempPathW(DWORD, LPWSTR);
	alias GetTempPathW GetTempPath;
}
version(Posix) {
	static import linux = std.c.linux.linux;
}
string getTempDirectory() {
	string path;
	version(Windows) {
		wchar[1024] buffer;
		auto len = GetTempPath(1024, buffer.ptr);
		if(len == 0)
			throw new Exception("couldn't find a temporary path");

		auto b = buffer[0 .. len];

		path = to!string(b);
	} else
		path = "/tmp/";

	return path;
}
long sysTimeToDTime(in SysTime sysTime) {
    return convert!("hnsecs", "msecs")(sysTime.stdTime - 621355968000000000L);
}
long dateTimeToDTime(in DateTime dt) {
	return sysTimeToDTime(cast(SysTime) dt);
}
long getUtcTime() {
	return sysTimeToDTime(Clock.currTime(UTC()));
}