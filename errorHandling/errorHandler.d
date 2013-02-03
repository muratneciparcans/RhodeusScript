/*
Rhodeus Script (c) by Talha Zekeriya Durmuş

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/

module errorHandling.errorHandler;
import library.dini, std.string, std.conv;
import std.stdio;
import interpreter;
import std.variant;
import Commands;
string language;
string exedir;
int classid;
Command _throwable;
class _RhError{
	RhError setError;
	this(string _language, string _exedir, ref int _classid, Command throwabl, int* curLine){
		language = _language;
		exedir = _exedir;
		classid = _classid;
		_throwable = throwabl;
	}
}
class RhError : Throwable { 
	Variant val;
	int line;
	this(T...)(string message, Variant val){
		(*val["codes"].peek!(dataManagement))["msg"] = message;
		this.val = val;
		super(message);
	}
	this(T...)(int number, T args){
		string message;
		if(number==0 && args.length>0) message = text(args);
		else{
			Ini errcodes ;
			try{
				errcodes = Ini.Parse(exedir~"resources/lang/"~language~"/errors.conf");
				message = format(errcodes.getKey(text(number)), args);
			}catch{
				throw new RhError (0,"Error file cannot be found.");
			}
		}
		line = dataPool.getLine();
		auto dM2 = new dataManagement();
/*		dM2["line"] = *_curLine;
		dM2["number"] = number;
		dM2["msg"] =  message;*/
		bool[string] attr;
//		this.val = Variant(["father": Variant(_throwable),"name": Variant("Throwable"),"attr": Variant(attr),"type": Variant("CLASSC"), "codes": Variant(dM2), "cid": Variant(classid++)]);
		super(message);

	}
}