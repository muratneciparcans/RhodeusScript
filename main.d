/*
Rhodeus Script (c) by Talha Zekeriya Durmuş

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/

module main;

import library.cgi,std.file : getcwd;
import Script;
import errorHandling.errorHandler;
import std.process: getenv, environment;

void handler(Cgi cgi){
	Script script;
	try{
		script = new Script();
	}catch(RhError re){
		cgi.setResponseStatus("503 Service Unavailable");
		cgi.write("Bad configuration file!");
		return;
	}
	string response;
	try{
		response = script.execute(getenv("PATH_TRANSLATED"), cgi);
	}catch(RhError x){
		response ~= "Hata: "~x.msg ~"<br>\nSatır: "~text(x.line);
	}catch(Throwable x){
		response ~= "Hata: "~x.msg;
	}
	cgi.write(response);
	std.stdio.stdin.readln();
}

mixin GenericMain!handler;