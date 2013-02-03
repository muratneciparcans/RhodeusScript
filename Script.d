/*
Rhodeus Script (c) by Talha Zekeriya Durmuş

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/

module Script;
import library.dini, library.web;
import std.stdio, std.file;
import parser;
import errorHandling.errorHandler;
import interpreter;
import std.process;
import std.path;
import std.conv;
import pool;
import Commands;

version(Win32)
import std.c.windows.windows;
else version(OSX)
private extern(C) int _NSGetExecutablePath(char* buf, uint* bufsize);
else
import std.c.linux.linux;

string getExec(){
	auto file = new char[4*1024];
	size_t filenameLength;
	version (Win32) filenameLength = GetModuleFileNameA(null, file.ptr, file.length-1);
	else version(OSX){
		filenameLength = file.length-1;
		_NSGetExecutablePath(file.ptr, &filenameLength);
	}else filenameLength = readlink(toStringz(selfExeLink), file.ptr, file.length-1);

	//auto fp = new FilePath(file[0..filenameLength]);
	return to!string(file[0..filenameLength]);
	//      return getExecFilePath().toString().trim();
}




class Script{
	string workingdir;
	Ini ini;
	string language;
	Parser parser;
	_RhError error;
	string[string] envVars;
	string exedir;
	Interpreter interpreter;
	int curLine = 1;

	pool dataPool;

	this(string wd = getcwd()){
		this.dataPool = new pool();
		Commands.linkIt(dataPool);
		exedir = dirName(getExec())~dirSeparator;
		workingdir = wd;
		parser = new Parser(&curLine);
		string addr;
		if(exists("rhs.conf")) addr="rhs.conf";
		else addr = buildPath(exedir,"rhs.conf");
		try{
			ini = Ini.Parse(addr);
			language = ini["script"].getKey("language");
		}catch{
			throw new RhError(0,"Bad configuration file!");
		}
		interpreter = new Interpreter(workingdir, exedir, &curLine);
		bool[string] attrs;
		dataManagement pc = new dataManagement(interpreter.kdM);
//		pc["line"]=0;
//		pc["number"]=0;
		Variant* father;
		Variant[string] dl;
//		interpreter.kdM["Throwable"] = Variant( ["father": Variant(father),"fid": Variant(parser.iClass++),"type": Variant("CLASS"), "attr": Variant(attrs), "codes": Variant(pc), "name": Variant("Throwable"), "vars": Variant(dl)] );
		error = new _RhError(language, exedir,classid, null, &curLine); //interpreter.kdM.get("Throwable")
	}
	string execute(string file, ref Cgi cgi){
		auto session = new Session(cgi);
		scope(exit) session.commit();
		Variant[string] val;
		/*
		foreach(a;cgi.files.keys){
			if(cgi.files[a].contentInMemory==false){
				ulong size = getSize(cast(char[]) cgi.files[a].contentFilename);
				val[a] = Variant(
								 ["type": Variant("DICTIONARYC"), "value": Variant(
																				   ["name":Variant(["type": Variant("STRING"), "value": Variant(cgi.files[a].name)]), 
																				   "filename":Variant(["type": Variant("STRING"), "value": Variant(cgi.files[a].filename)]), 
																				   "contentType":Variant(["type": Variant("STRING"), "value": Variant(cgi.files[a].contentType)]),
																				   "tmpName":Variant(["type": Variant("STRING"), "value": Variant(cgi.files[a].contentFilename)]),
																				   "size":Variant(["type": Variant("STRING"), "value": Variant(text(size))])
																				   ])
								 ]);
			}else{
				string newn = getTempDirectory() ~ "rhs_uploaded_file_" ~ to!string(getUtcTime());
				std.file.write(newn, cgi.files[a].content);
				ulong size = getSize(cast(char[]) newn);
				val[a] = Variant(
								 ["type": Variant("DICTIONARYC"), "value": Variant(
																				   ["name":Variant(["type": Variant("STRING"), "value": Variant(cgi.files[a].name)]), 
																				   "filename":Variant(["type": Variant("STRING"), "value": Variant(cgi.files[a].filename)]), 
																				   "contentType":Variant(["type": Variant("STRING"), "value": Variant(cgi.files[a].contentType)]),
																				   "tmpName":Variant(["type": Variant("STRING"), "value": Variant(newn)]),
																				   "size":Variant(["type": Variant("STRING"), "value": Variant(text(size))])
																				   ])
								 ]);
			}
		}*/
//		interpreter.kdM["FILES"] = Variant(["type": Variant("DICTIONARYC"), "value": Variant(val)]);


//		interpreter.loadVars("SESSION", session.data);
//		interpreter.loadVars("GET", cgi.get);
//		interpreter.loadVars("POST", cgi.post);
//		interpreter.loadVars("COOKIES", cgi.cookies);
//		interpreter.loadVars("ENV", environment.toAA());
		/*if(exists("resources\\includes\\")){
			foreach (string name; dirEntries("resources\\includes", "*.{rhs}", SpanMode.breadth)) {
				parser.load(name);
				parser.parseIt();
				interpreter.main(parser.paraphrase());
			}
		}*/
		parser.loadFile(file);
		parser.parseIt();
		interpreter.main(parser.paraphrase());
		if(interpreter.kdM.hasKey("SESSION")){
			Variant aktiv = interpreter.kdM["SESSION"];
			if(aktiv["type"]=="DICTIONARYC"){
				foreach(string s; aktiv["value"].peek!(Variant[string]).keys){
//					session.set(s, interpreter.getText(aktiv["value"][s], interpreter.kdM));
				}
			}
		}

		foreach(x;interpreter.wcooks){
			bool x5;
			if(x[5]!="0" && x[5]!="false") x5=true;
			bool x6;
			if(x[6]!="0" && x[6]!="false") x6=true;

			cgi.setCookie(x[0], text(x[1]), to!long(text(x[2])), text(x[3]), text(x[4]), x5, x6);
		}
		shutAll(interpreter);
		return interpreter.output;
	}
	void shutAll(ref Interpreter interpreter){
		while(interpreter.shutIt.length>0){
			if (interpreter.shutIt[0][0]=="libs.mysql.Connecion") (*interpreter.shutIt[0][1].peek!(library.mysql.Connection)).close;
			interpreter.shutIt.popFront();
		}
	}
}

