/*
Rhodeus Script (c) by Talha Zekeriya Durmuş

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/

module interpreter;
public import std.variant;
import std.conv;
import std.process;
import std.math;
import std.string;
import std.datetime;
import std.stdio;
import library.dini;
import errorHandling.errorHandler;
import Commands;
class Interpreter{
	string[][] wcooks;
	string exedir;

	public void setError(T...)(int ow, T args){
		throw new RhError(ow, args);
	}

	string output;

	public _Data data;

	Variant[] shutIt;
	dataManagement kdM;

	subManagement sM;

	string workingdir;
	dataManagement dM;
	int* curLine;
	this(string wd, string exedir, int *_curLine){
		this.curLine = _curLine;
		this.exedir = exedir;
		workingdir=wd;
		kdM = new dataManagement();
		dM = new dataManagement(kdM);
		sM = new subManagement();
		import modules.main;
		new _Main(this);
		this.data = new _Data();
	}
	void loadVars(string vn, string[string] x){
		/*
		Variant[string] val;
		foreach(a;x.keys){
			val[a] = Variant(["type": Variant("STRING"), "value": Variant(x[a])]);
		}
		kdM[vn]=Variant(["type": Variant("DICTIONARYC"), "value": Variant(val)]);*/
		//fix this
	}
	void loadVars(string vn, immutable char[][string] x){
		/*
		Variant[string] val;
		foreach(a;x.keys){
			val[a] = Variant(["type": Variant("STRING"), "value": Variant(text(x[a]))]);
		}
		kdM[vn]=Variant(["type": Variant("DICTIONARYC"), "value": Variant(val)]);
		*///Fix this
	}
	class _Data{
		bool array_append(Variant* aktiv, Variant value){
			*(*aktiv.peek!(Variant[string]))["value"].peek!(Variant[]) ~= value;
			return true;
		}
		bool array_prepend(Variant* aktiv, Variant value){
			*(*aktiv.peek!(Variant[string]))["value"].peek!(Variant[]) = [value] ~ *(*aktiv.peek!(Variant[string]))["value"].peek!(Variant[]);
			return true;
		}
		Variant string_find(Variant* aktiv, Variant value){
			return (*aktiv.peek!(Variant[string]))["value"];
		}
	}
	void main(Command[] yrms, dataManagement dM = null){
		if (dM is null) dM = this.dM;
		bool n=false;
		//writeln("Running...");
		//long z = Clock.currSystemTick().usecs();

		int i;
		int getLine(){ return yrms[i].line;}
		dataPool.getLine = &getLine;
		for(;i<yrms.length;i++){
			yrms[i].run(dM);
		}
		//long y = Clock.currSystemTick().usecs();
		//writeln("Elapsed time: ",y-z);
	}
}

class dataManagement{
    public dataManagement _root;
	public int[string] _data;
	private int _a;
	public Command[int] _address;
	private bool[string] globs;
	Command opIndex(string key){
		return get(key, true);
	}
/*	void copyTo( dataManagement d){
		d._data=_data;
		d._a = _a;
		d._address=_address;
		d.globs = globs;
	}*/
	/*
	void extend( dataManagement d, bool muula){
		foreach(a; _data.keys){
			if((a in d._data) is null ){
				d[a] = this[a];
			}
		}
		foreach(a; globs.keys){
			d.globs[a]=globs[a];
		}
	}
	void extend( dataManagement d){
		foreach(a; _data.keys){
			d[a] = this[a];
		}
		foreach(a; globs.keys){
			d.globs[a]=globs[a];
		}
	}*/
	protected int addressIt(string field){
		if(field in _data){
			return _data[field];
		}else{
			_a++;
			return _a;
		}
	}
	void set(string var, Command val){
		if (var in globs && _root !is null && _root.hasKey(var)){_root.set(var, val);return;}
		int addr=addressIt(var);
		_data[var]=addr;
		_address[addr]=val;
	}
	Command get(string var, bool b=false){
		if(!hasKey(var)){
			if (b && _root !is null && _root.hasKey(var, true)) return _root.get(var, true);
			else throw new Exception(var~" değişkeni bulunamadı!");
		}
		return _address[_data[var]];
	}
	void opIndexAssign(Command delegate(Command[] params,Command aktiv, dataManagement dM) value, string field){
		set(field, new dFunction(value));
	}
	void opIndexAssign(Command value, string field) {
		set(field, value);
	}
	/*
	void opIndexAssign(short value, string field){
		set(field, Variant(["type": Variant("INT"), "value": Variant(value)]));
	}
	void opIndexAssign(int value, string field){
		set(field, Variant(["type": Variant("INT"), "value": Variant(value)]));
	}
	void opIndexAssign(string value, string field){
		set(field, Variant(["type": Variant("STRING"), "value": Variant(value)]));
	}
*/
	bool hasKey(string key, bool p=false){
		if(key in _data) return true;
		if(p && _root !is null && _root.hasKey(key, true)) return true;
		return false;
	}
    public this(){
        _root = null;
    }
	public this( dataManagement root){
        _root = root;
    }

}


class subManagement{
	private int[string][string] _data;
	private int _a;
	private Variant[int] _address;
	Variant opIndex(string key, string key2){
		return *get(key,key2, true);
	}
	protected int addressIt(string field, string field2){
		if(field in _data && field2 in _data[field]){
			return _data[field][field2];
		}else{
			_a++;
			return _a;
		}
	}
	void set(string var,string var2, Variant val){
		int addr=addressIt(var, var2);
		_data[var][var2]=addr;
		_address[addr]=val;
	}
	Variant* get(string var,string var2, bool b=false){
		if(!hasKey(var, var2)){
			throw new Exception("Değişken bulunamadı!");
		}
		return &_address[_data[var][var2]];
	}
	void opIndexAssign(Variant value, string field, string field2) {
		set(field,field2, value);
	}
	void opIndexAssign(VariantN!(20u) delegate (VariantN!(20u),VariantN!(20u),  dataManagement) value, string field, string field2){
		set(field,field2, Variant(["type": Variant("dFunction"), "value": Variant(value)]));
	}
	void opIndexAssign(short value, string field, string field2){
		set(field,field2, Variant(["type": Variant("INT"), "value": Variant(text(value))]));
	}
	bool hasKey(string key, string key2){
		if(key in _data && key2 in _data[key]) return true;
		return false;
	}

}


bool isIn(t...)(t a){
	foreach(l; a[1]){
		if (l==a[0]) return true;
	}
	return false;
}
