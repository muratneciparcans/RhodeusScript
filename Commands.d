/*
Rhodeus Script (c) by Talha Zekeriya Durmuş

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/

module Commands;
import pool;
import std.stdio;
import interpreter;
import std.conv;
import std.random ;
import std.string;
import std.array;
import std.format;
import std.algorithm;
import errorHandling.errorHandler;
public void setError(T...)(int ow, T args){
	throw new RhError(ow, args);
}

string[] sign; //loop i
int*[] sign1; //loop i
int[]  sign2; //loop max
int*[] sign3; //current command
int[]  sign4; //max command
Command*[] sign5;
pool dataPool;
void linkIt(pool _pool){
	dataPool = _pool;
}
class Command{
	Command[] subs;
	short typ;
	uint line;
	string type;
	string value;
	Command delegate  (Command[], Command, dataManagement)[string] functions;
	bool isIn(Command tl){ return 0;}
	void opSet(Command a, Command b, dataManagement dM){}

	this(string type){
		this.type = type;
		this.line = dataPool.line;
	}

	Command run(dataManagement dM){
		if (subs.length==0) return this;
		return locate(dM, this, subs);
	}
	override bool opEquals(Object T){
        if (cast(Command) T is null) throw new Exception("Kontrol sadece 2 RhObject arasında yapılabilir.");
        return false;
    }
	bool isEmpty(){return true;}
	Command getMethod(string m, dataManagement dM){
		throw new Exception(type ~ " veri türüne ait " ~ m ~ " alt fonksiyonu bulunmamaktadır.");
	}
	Command call(dataManagement dM, Command[] fonkParams){
		throw new Exception(type~" veri türünü çağıramazsınız!");
	}
	Command opIndex(Command o){
		throw new Exception(type~" veri türünün indeksine ulaşamazsınız.");
		return new RhNone();
	}
	Command opIndexAssign(Command value, Command field){
		throw new Exception(type~" veri türüne ait indexAssign bulunmamaktadır.");
	}
	override int opCmp(Object T){
		return 0;
	}
	Command op(string operator, Command rhs, dataManagement dM=null){
		final switch(operator){
			case "+":
				throw new Exception(type~" veri türünü "~rhs.type~" veri türüyle toplayamazsınız.");
			case "*":
				throw new Exception(type~" veri türünü "~rhs.type~" veri türüyle çarpamazsınız.");
			case "/":
				throw new Exception(type~" veri türünü "~rhs.type~" veri türüne bölemezsiniz.");
			case "-":
				throw new Exception(type~" veri türünü "~rhs.type~" veri türünden çıkartamazsınız.");
			case "%":
				throw new Exception(type~" veri türünü "~rhs.type~" veri türüne modunu alamazsınız.");
		}
	}
	void setWop(string operator, Command rhs, dataManagement dM=null){
		throw new Exception(type~" veri türü için "~operator~" operatörünü kullanamazsınız.");
	}

}

class spec : Command{
	this(string type, string value){
		switch(type){
			case "AO", "CO", "LO":
				this.typ = 3;
				break;
			default:
				break;
		}
		super(type);
		this.value = value;
	}
	override Command run(dataManagement dM){
		throw new Exception("Beklenmeyen karakter: '"~value~"'");
	}
}
class RhWhile : Command{
	Command condition;
	Command[] codes;
	this(Command condition, Command[] codes){
		super("RhWhile");
		this.condition = condition;
		this.codes = codes;
	}
	override Command run(dataManagement dM){
		int i;
		Command cond;
		sign ~= "while";
		sign3~=&i;
		sign4~=codes.length;
		sign5~=&condition;
		start:
		cond = condition.run(dM);
		if(cond	is null || cond.isEmpty()) goto end;
		for(i=0; i<codes.length; i++) codes[i].run(dM);
		goto start;
		end:
		sign.length--;
		sign3.length--;
		sign4.length--;
		sign5.length--;
		return new RhNone();
	}
}
class RhForeach : Command{
	Command getIt;
	string eqIt;
	Command[] codes;
	this(string eqIt, Command getIt, Command[] codes){
		this.eqIt = eqIt;
		this.getIt = getIt;
		this.codes = codes;
		super("RhForeach");
	}
	override Command run(dataManagement dM){
		int i, i2, len;
		Command ge = getIt.run(dM);
		len = (cast(RhArray) ge).value.length;
		start:
		if (i2>=len) return null;
			dM[eqIt] = (cast(RhArray) ge).value[i2];
			i=0;
			while(i<codes.length){
				codes[i].run(dM);
				i++;
			}
			i2++;
		goto start;
		return new RhNone();
	}
}
class RhIf : Command{
	RhIfS[] ifs;
	this(RhIfS[] ifs){
		this.ifs = ifs;
		this.typ = 2;
		super("RhIf");
	}
	override Command run(dataManagement dM){
		int ix;
		int i;
		Command ret = new RhNone();
		while(ix < ifs.length){
			if(ifs[ix].cond is null){
				i=0;
				while(i<ifs[ix].codes.length){
					ret = ifs[ix].codes[i].run(dM);
					i++;
				}break;
			}else if(!ifs[ix].cond.run(dM).isEmpty()){
				i=0;
				while(i<ifs[ix].codes.length){
					ret = ifs[ix].codes[i].run(dM);
					i++;
				}break;
			}
			ix++;
		}
		return ret;
	}
}

class RhFor : Command{
	Command a1, a2, a3;
	Command[] codes;
	this(Command a1,Command a2,Command a3, Command[] codes){
		this.a1 = a1;
		this.a2 = a2;
		this.a3 = a3;
		this.codes = codes;
		super("RhFor");
	}

	override Command run(dataManagement dM){
		int i;
		Command cond;
		a1.run(dM);
	start:
		cond = a2.run(dM);
		if(cond	is null || cond.isEmpty()) return null;
		i=0;
		while(i<codes.length){
			codes[i].run(dM);
			i++;
		}
		a3.run(dM);
		goto start;
		return new RhNone();
	}
}

class RhArray : Command{
	Command[] value;
	bool t = true;
	override bool isEmpty(){if(value.length==0) return true; else return false;}
	override bool opEquals(Object T){
        if (cast(RhArray) T is null) return false;
        else if ((cast(RhArray) T ).value != this.value) return false;
		return true;
    }

	override Command op(string operator, Command rhs, dataManagement dM=null){
		final switch(operator){
			case "+":
				if(rhs.type=="ARRAY") return new RhArray(this.value ~ (cast(RhArray) rhs).value);
				else throw new Exception(this.type~" veri türünü sadece ARRAY veri türüyle toplayabilirsiniz.");
			case "*":
				if(rhs.type=="INT") return new RhArray(this.value.replicate((cast(RhInt) rhs).value));
				else throw new Exception(this.type~" veri türünü sadece INT veri türüyle toplayabilirsiniz.");
			case "/":
				if(rhs.type!="INT") throw new Exception(this.type~" veri türünü sadece INT veri türüyle toplayabilirsiniz.");
				else if((cast(RhInt) rhs).value < 1) throw new Exception(this.type~" veri türünü 0 dan büyük bir rakama bölebilirsiniz.");
				Command[] list;
				for(int z; z<this.value.length; z+= (cast(RhInt) rhs).value)
					if(z+(cast(RhInt) rhs).value > this.value.length)
						list ~= new RhArray(this.value[z..$-1]);
					else
						list ~= new RhArray(this.value[z..z+(cast(RhInt) rhs).value]);
				return new RhArray(list);
			case "-":
				throw new Exception(type~" veri türünü "~rhs.type~" veri türünden çıkartamazsınız.");
			case "%":
				throw new Exception(type~" veri türünü "~rhs.type~" veri türüne modunu alamazsınız.");
		}
	}

	override int opCmp(Object T){
        if (cast(RhArray) T is null) throw new Exception(type~" veri türüyle sadece "~type ~" veri türünü karşılaştırabilirsiniz.");
		if(this.value > (cast(RhArray) T ).value) return 1;
		else if(this.value < (cast(RhArray) T ).value) return -1;
		return 0;
	}
	override Command opIndex(Command ri){
		if (ri.type != "INT") throw new Exception("Indeks değeri olarak bir tam sayı bekleniyordu "~ri.type~" geldi.");
		else if (value.length<=(cast(RhInt) ri).value) throw new Exception("Dizi uzunluğu: "~to!string(value.length)~". "~to!string((cast(RhInt) ri).value)~". indeksine ulaşamazsınız.");
		else if ((cast(RhInt) ri).value < 0 ) throw new Exception("Dizi indeksi sıfırdan küçük olamaz.");
		return this.value[(cast(RhInt) ri).value];
	}
	override Command opIndexAssign(Command value2, Command field){
		if(field.type!="INT") throw new Exception("Indeks değeri olarak bir tam sayı bekleniyordu "~field.type~" geldi.");
		else if (value.length<=(cast(RhInt) field).value) throw new Exception("Dizi uzunluğu: "~to!string(value.length)~". "~to!string((cast(RhInt) field).value)~". indeksine ulaşamazsınız.");
		else if ((cast(RhInt) field).value < 0 ) throw new Exception("Dizi indeksi sıfırdan küçük olamaz.");
		value[(cast(RhInt) field).value] = value2;
		return null;
	}
	this(Command[] value = null){
		this.functions = ["get": &get, "append": &append, "combine": &combine, "countValues": &countValues,
		"getRandom": &getRandom, "search": &search
		];
		this.typ = 2;
		this.value = value;
		super("ARRAY");
	}
	override string toString(){
		return to!string(value);
	}
	Command countValues(Command[] params,Command aktiv,dataManagement dM){
		if(params.length != 0) throw new Exception("countValues işlemi için 0 parametre bekleniyordu!");
		Command[string] temp;
		string st;
		for(int i = 0;i<(cast(RhArray)aktiv).value.length;i++){
			st = (cast(RhArray) aktiv).value[i].toString();
			if((st in temp) !is null)
				(cast(RhInt) temp[st]).value++;
			else
				temp[st] = new RhInt(1);
		}
		return new RhDictionary(temp);
	}
	Command search(Command[] params,Command aktiv,dataManagement dM){
		if(params.length != 1) throw new Exception("search işlemi için 1 parametre bekleniyordu!");
		Command[string] temp;
		Command t = params[0].run(dM);
		for(int i = 0;i < value.length;i++){
			if(params[0] == value[i])
				return new RhInt(i);
		}
		return new RhInt(-1);
	}
	Command get(Command[] params,Command aktiv,dataManagement dM){
		Command ri = params[0].run(dM);
		return aktiv[ri];
	}
	Command getRandom(Command[] params,Command aktiv,dataManagement dM){
		if(params.length > 1) throw new Exception("getRandom işlemi en fazla 1 parametre alabilir!");
		int cur = 1;
		if(params.length == 1){
			if(params[0].type != "INT") throw new Exception("getRandom işlemi için INT bekleniyordu "~params[0].type~" geldi.");
			else cur = (cast(RhInt) params[0]).value;
			if(cur < 1) throw new Exception("getRandom işlemi için INT 0 dan büyük olmalıdır!");
			else if(cur > (cast(RhArray) aktiv).value.length) throw new Exception("getRandom işlemi için INT dizi uzunluğundan büyük olamaz!");
		}
		Command[] liz;
		foreach(elm; randomSample((cast(RhArray) aktiv).value, cur))
			liz ~= elm;
		return new RhArray(liz);
	}
	Command combine(Command[] params,Command aktiv,dataManagement dM){
		if(params.length != 1) throw new Exception("combine işlemi için 1 parametre bekleniyordu!");
		params[0] = params[0].run(dM);
		if(params[0].type != "ARRAY") throw new Exception("combine işlemi için 1 parametre ARRAY türünde olmalıdır!");
		Command[string] temp;
		for(int i = 0;i < (cast(RhArray) aktiv).value.length;i++)
			temp[( (cast(RhArray) aktiv).value[i]).toString()] = (cast(RhArray) params[0]).value[i];

		return new RhDictionary(temp);
	}
	Command append(Command[] params,Command aktiv,dataManagement dM){
		if(aktiv.type != "ARRAY") throw new Exception("Append işlemini sadece diziler için yapabilirsiniz.");
		(cast(RhArray) aktiv).value ~= params[0].run(dM);
		return aktiv;
	}
	override Command getMethod(string m, dataManagement dM){
		switch(m){
			case "str": return new RhString(to!string(value));
			case "length": return new RhInt(value.length);
			case "reverse": reverse(value); return this;
			case "pop": value = value[0..$-1]; return value[$];
			case "shift": value = value[1..$]; return *(&value[0] - 1);
			default:
				if (m in functions) return new dFunction(functions[m], this);
				else throw new Exception(type ~ " tipine ait " ~ m ~ " alt fonksiyonu bulunmamaktadır.");
		}
		assert(0);
	}
	override Command run(dataManagement dM){
		if (t) {for(int i=0; i<value.length; i++)value[i]=value[i].run(dM); t=false;}
		return this;
	}
}



class RhDictionary : Command{
	Command[string] value;
	bool t;
	override bool isEmpty(){if(value.length==0) return true; else return false;}
	override Command opIndex(Command ri){
		if (ri.type != "STRING") throw new Exception("Anahtar değeri olarak bir metin bekleniyordu "~ri.type~" geldi.");
		else if ((ri.value in value) is null) throw new Exception("Dizi içerisinde "~ri.value~" anahtarı bulunamadı.");
		return this.value[ri.value];
	}
	override bool isIn(Command tl){
		if(tl.value in value) return true;
		return false;
	}
	override Command opIndexAssign(Command value2, Command field){
		value[field.toString()] = value2;
		return null;
	}
	this(Command[string] value = null){
		this.functions = ["get": &get, "changeKeyCase": &changeKeyCase];
		this.typ = 2;
		this.value = value;
		super("DICTIONARY");
	}
	
	Command[][] valueR;
	this(Command[][] value){
		this.functions = ["get": &get, "changeKeyCase": &changeKeyCase];
		this.typ = 2;
		super("DICTIONARY");
		this.valueR = value;
		this.t = true;
	}
	override string toString(){
		return "{"~to!string(value)[1..$-1]~"}";
	}
	Command get(Command[] params,Command aktiv,dataManagement dM){
		Command ri = params[0].run(dM);
		return aktiv[ri];
	}
	Command changeKeyCase(Command[] params,Command aktiv,dataManagement dM){
		if(params.length != 1) throw new Exception("changeKeyCase işlemi için 1 parametre bekleniyordu!");
		else if(params[0].type != "STRING") throw new Exception("changeKeyCase işlemi için 1 parametre STRING türünde olmalıdır!");
		Command[string] temp;
		switch(params[0].value.toLower()){
			case "upper": foreach(key, val;(cast(RhDictionary) aktiv).value) temp[key.toUpper()] = val; break;
			case "lower": foreach(key, val;(cast(RhDictionary) aktiv).value) temp[key.toLower()] = val; break;
			default: throw new Exception("changeKeyCase işlemi için sadece lower ve upper komutlarını kullanabilirsiniz!");
		}
		(cast(RhDictionary) aktiv).value = temp;
		return new RhBool(true);
	}
	override Command getMethod(string m, dataManagement dM){
		switch(m){
			case "str": return new RhString(to!string(value));
			case "length": return new RhInt(value.length);
			default:
				if (m in functions) return new dFunction(functions[m], this);
				else throw new Exception(type ~ " tipine ait " ~ m ~ " alt fonksiyonu bulunmamaktadır.");
		}
		assert(0);
	}
	override Command run(dataManagement dM){
		if (t) {
			foreach(valueL; valueR){
				value[valueL[0].run(dM).toString()]=valueL[1].run(dM);
			}
			t=false;
		}
		return this;
	}
}

class RhCodeArea : Command{
	Command[] value;
	dataManagement cdM;
	this(Command[] value){
		this.value = value;
		super("getParacodes");
		this.functions = ["define": &define];
		cdM = new dataManagement();
	}
	
	Command define(Command[] params,Command aktiv,dataManagement dM){
		cdM[params[0].run(dM).value] = params[1].run(dM);
		return this;
	}

	override Command getMethod(string m, dataManagement dM){
		switch(m){
			case "run":
				cdM._root = dM;
				foreach(val;value) val.run(cdM);
				return new RhNone();
			case "length": return new RhInt(value.length);
			default:
			if (m in functions) return new dFunction(functions[m], this);
			else throw new Exception(type ~ " tipine ait " ~ m ~ " alt fonksiyonu bulunmamaktadır.");
		}
		assert(0);
	}
	
	Command runTimes(int zz, int* z, dataManagement dM){
		start:
			if (*z == zz) goto end;
			foreach(val;value) val.run(dM);
			(*z)++;
		goto start;
		end:
			return null;
	}
}
class RhInt : Command{
	int value;
	override bool isEmpty(){if(value==0) return true; else return false;}
	override int opCmp(Object T){
        if (cast(RhInt) T is null) throw new Exception(type~" veri türüyle sadece "~type ~" veri türünü karşılaştırabilirsiniz.");
        return this.value - (cast(RhInt) T ).value;
	}
	override bool opEquals(Object T){
        if (cast(RhInt) T is null) return false;
        else if ((cast(RhInt) T ).value != this.value) return false;
		return true;
    }
	override Command getMethod(string m, dataManagement dM){
		switch(m){
			case "str": return new RhString(to!string(value));
			case "length": return new RhInt(to!string(value).length);
			default:
				if (m in functions) return new dFunction(functions[m], this);
				else throw new Exception(type ~ " tipine ait " ~ m ~ " alt fonksiyonu bulunmamaktadır.");
		}
		assert(0);
	}

	override void setWop(string operator, Command rhs, dataManagement dM=null){
		final switch(operator){
			case "-":
				if(rhs.type=="INT") this.value -= (cast(RhInt) rhs).value;
				else if(rhs.type=="FLOAT") this.value -= (cast(RhFloat) rhs).value;
				else throw new Exception(this.type~" veri türünü sadece Int veya Float türünden çıkartabilirsiniz.");
				break;
			case "+":
				if(rhs.type=="INT") this.value += (cast(RhInt) rhs).value;
				else if(rhs.type=="FLOAT") this.value += (cast(RhFloat) rhs).value;
				else throw new Exception(this.type~" veri türünü sadece Int veya Float türüyle toplayabilirsiniz.");
				break;
			case "/":
				if(rhs.type=="INT") this.value /= (cast(RhInt) rhs).value;
				else if(rhs.type=="FLOAT") this.value /= (cast(RhFloat) rhs).value;
				else throw new Exception(this.type~" veri türünü sadece Int veya Float türüne bölebilirsiniz.");
				break;
			case "*":
				if(rhs.type=="INT") this.value *= (cast(RhInt) rhs).value;
				else if(rhs.type=="FLOAT") this.value *= (cast(RhFloat) rhs).value;
				else throw new Exception(this.type~" veri türünü sadece Int veya Float türüyle çarpabilirsiniz.");
				break;
			case "%":
				if(rhs.type=="INT") this.value %= (cast(RhInt) rhs).value;
				else if(rhs.type=="FLOAT") this.value %= (cast(RhFloat) rhs).value;
				else throw new Exception(this.type~" veri türünü sadece Int veya Float türüne mod alabilirsiniz.");
				break;
		}
	}
	
	override Command op(string operator, Command rhs, dataManagement dM=null){
		final switch(operator){
			case "+":
				if(rhs.type=="INT") return new RhInt(this.value + (cast(RhInt) rhs).value);
				else if(rhs.type=="FLOAT") return new RhFloat(this.value + (cast(RhFloat) rhs).value);
				else throw new Exception(this.type~" veri türünü sadece Int veya Float türüyle toplayabilirsiniz.");
			case "*":
				if(rhs.type=="INT") return new RhInt(this.value * (cast(RhInt) rhs).value);
				else if(rhs.type=="FLOAT") return new RhFloat(this.value * (cast(RhFloat) rhs).value);
				else throw new Exception(this.type~" veri türünü sadece Int veya Float türüyle çarpabilirsiniz.");
			case "/":
				if(rhs.type=="INT") return new RhInt(this.value / (cast(RhInt) rhs).value );
				else if(rhs.type=="FLOAT") return new RhFloat(this.value/ (cast(RhFloat) rhs).value);
				else throw new Exception(this.type~" veri türünü sadece Int veya Float türüne bölebilirsiniz.");
			case "-":
				if(rhs.type=="INT") return new RhInt(this.value - (cast(RhInt) rhs).value);
				else if(rhs.type=="FLOAT") return new RhFloat(this.value - (cast(RhFloat) rhs).value);
				else throw new Exception(this.type~" veri türünü sadece Int veya Float türünden çıkartabilirsiniz.");
			case "%":
				if(rhs.type=="INT") return new RhInt(this.value % (cast(RhInt) rhs).value);
				else if(rhs.type=="FLOAT") return new RhFloat(this.value % (cast(RhFloat) rhs).value);
				else throw new Exception(this.type~" veri türünü sadece Int veya Float türüne modunu alabilirsiniz.");
		}
	}

	this(int value){
		this.typ = 1;
		this.value = value;
		super("INT");
		this.functions = ["times": &times];
	}
	Command times(Command[] params,Command aktiv,dataManagement dM){
		int zz = (cast(RhInt) aktiv).value;
		dM[params[0].value] = new RhInt(0);
		(cast(RhCodeArea) params[1]).runTimes(zz, &(cast(RhInt) dM[params[0].value]).value, dM);
		return null;
	}
	override string toString(){
		return to!string(value);
	}
}
class RhFloat : Command{
	float value;
	override int opCmp(Object T){
        if (cast(RhFloat) T is null) throw new Exception(type~" veri türüyle sadece "~type ~" veri türünü karşılaştırabilirsiniz.");
		if(this.value - (cast(RhFloat) T ).value > 0){
			return 1;
		}else if(this.value - (cast(RhFloat) T ).value < 0){
			return -1;
		}
        return 0;
	}
	override bool opEquals(Object T){
        if (cast(RhFloat) T is null) return false;
        else if ((cast(RhFloat) T ).value != this.value) return false;
		return true;
    }
	override bool isEmpty(){if(value==0) return true; else return false;}
	override string toString(){
		return to!string(value);
	}
	override Command op(string operator, Command rhs, dataManagement dM=null){
		final switch(operator){
			case "+":
				if(rhs.type=="INT") return new RhFloat(this.value + (cast(RhInt) rhs).value);
				else if(rhs.type=="FLOAT") return new RhFloat(this.value + (cast(RhFloat) rhs).value);
				else throw new Exception(this.type~" veri türünü sadece Int veya Float türüyle toplayabilirsiniz.");
			case "*":
				if(rhs.type=="INT") return new RhFloat(this.value * (cast(RhInt) rhs).value);
				else if(rhs.type=="FLOAT") return new RhFloat(this.value * (cast(RhFloat) rhs).value);
				else throw new Exception(this.type~" veri türünü sadece Int veya Float türüyle çarpabilirsiniz.");
			case "/":
				if(rhs.type=="INT") return new RhFloat(this.value / (cast(RhInt) rhs).value);
				else if(rhs.type=="FLOAT") return new RhFloat(this.value/ (cast(RhFloat) rhs).value);
				else throw new Exception(this.type~" veri türünü sadece Int veya Float türüne bölebilirsiniz.");
			case "-":
				if(rhs.type=="INT") return new RhFloat(this.value - (cast(RhInt) rhs).value);
				else if(rhs.type=="FLOAT") return new RhFloat(this.value - (cast(RhFloat) rhs).value);
				else throw new Exception(this.type~" veri türünü sadece Int veya Float türünden çıkartabilirsiniz.");
			case "%":
				if(rhs.type=="INT") return new RhFloat(this.value % (cast(RhInt) rhs).value);
				else if(rhs.type=="FLOAT") return new RhFloat(this.value % (cast(RhFloat) rhs).value);
				else throw new Exception(this.type~" veri türünü sadece Int veya Float türüne modunu alabilirsiniz.");
		}
	}

	this(float value){
		this.typ = 1;
		this.value = value;
		super("FLOAT");
	}
}
class RhString : Command{
	override bool isEmpty(){if(value.length==0) return true; else return false;}

	override void setWop(string operator, Command rhs, dataManagement dM=null){
		final switch(operator){
			case "+":
				if(cast(RhString) rhs is null) throw new Exception("String'i sadece String ile toplayabilirsiniz.");
				this.value ~= rhs.value;
				break;
			case "*":
				if(cast(RhInt) rhs is null) throw new Exception("String'i sadece Int ile çarpabilirsiniz.");
				this.value = std.array.replicate(this.value, (cast(RhInt) rhs).value);
				break;
			case "/":
				throw new Exception(type~" veri türünü "~rhs.type~" veri türüne bölemezsiniz.");
			case "-":
				throw new Exception(type~" veri türünü "~rhs.type~" veri türünden çıkartamazsınız.");
			case "%":
				throw new Exception(type~" veri türünü "~rhs.type~" veri türüne modunu alamazsınız.");
		}
	}


	override bool opEquals(Object T){
        if (cast(RhString) T is null) return false;
        else if ((cast(RhString) T ).value != this.value) return false;
		return true;
    }
	override string toString(){
		return value;
	}
	Command format(Command[] params,Command aktiv,dataManagement dM){
		//Ali Çehreli hocama teşekkürler 26.12.2012
		//http://ddili.org/forum/post/8379
		auto düzen = FormatSpec!char(aktiv.toString());
		auto yazıcı = appender!string;
		string[] strl;
		foreach(param; params){
			strl ~= param.run(dM).toString();
		}
		foreach (i, değer; strl) {
			if(!düzen.writeUpToNextSpec(yazıcı)) throw new Exception("Şu değer(ler) için belirteç bulunamadı:", text(strl[i..$]));
			formatValue(yazıcı, değer, düzen);
		}
		if(düzen.writeUpToNextSpec(yazıcı)){
			throw new Exception("Fazladan düzen belirteci bulundu");
		}
		return new RhString(yazıcı.data);
	}
	Command replace(Command[] params,Command aktiv,dataManagement dM){
		return new RhString(std.array.replace(aktiv.value, params[0].run(dM).toString(), params[1].run(dM).toString()));
	}

	Command indexOf(Command[] params,Command aktiv,dataManagement dM){
		if(params.length == 0) throw new Exception("indexOf fonksiyonu 2 parametre alıyor. (1 opsiyonel)");
		else if(params.length > 2) throw new Exception("indexOf fonksiyonu 2 parametreden fazla parametre alamaz.");
		CaseSensitive boo = CaseSensitive.yes;
		if (params.length == 2 && !(cast(RhBool) params[1].run(dM)).value) boo = CaseSensitive.no;
		return new RhInt(value.indexOf(params[0].run(dM).toString(), boo));
	}

	Command splitLines(Command[] params,Command aktiv,dataManagement dM){
		if(params.length > 1) throw new Exception("indexOf fonksiyonu 1 parametreden fazla parametre alamaz.");
		KeepTerminator boo = KeepTerminator.no;
		if (params.length == 1 && (cast(RhBool) params[1].run(dM)).value) boo = KeepTerminator.yes;
		Command list[];
		foreach(x;value.splitLines(boo)){
			list ~= new RhString(x);
		}
		return new RhArray(list);
	}
	
	Command lastIndexOf(Command[] params,Command aktiv,dataManagement dM){
		if(params.length == 0) throw new Exception("indexOf fonksiyonu 2 parametre alıyor. (1 opsiyonel)");
		else if(params.length > 2) throw new Exception("indexOf fonksiyonu 2 parametreden fazla parametre alamaz.");
		CaseSensitive boo = CaseSensitive.yes;
		if (params.length == 2 && !(cast(RhBool) params[1].run(dM)).value) boo = CaseSensitive.no;
		return new RhInt(value.lastIndexOf(params[0].run(dM).toString(), boo));
	}
	override Command getMethod(string m, dataManagement dM){
		switch(m){
			case "str": return this;
			case "length": return new RhInt(value.length);
			case "lower": return new RhString(value.toLower());
			case "upper": return new RhString(value.toUpper());
			case "capitalize": return new RhString(value.capitalize());
			case "strip": return new RhString(value.strip());
			case "stripLeft": return new RhString(value.stripLeft());
			case "stripRight": return new RhString(value.stripRight());
			default:
				if (m in functions) return new dFunction(functions[m], this);
				else throw new Exception(type ~ " tipine ait " ~ m ~ " alt fonksiyonu bulunmamaktadır.");
		}
		assert(0);
	}



	override Command op(string operator, Command rhs, dataManagement dM=null){
		final switch(operator){
			case "+":
				if(cast(RhString)rhs is null) throw new Exception("String'i sadece String ile toplayabilirsiniz.");
				return new RhString(this.value ~ rhs.value);
			case "*":
				if(cast(RhInt) rhs is null) throw new Exception("String'i sadece Int ile çarpabilirsiniz.");
				return new RhString(std.array.replicate(this.value, (cast(RhInt) rhs).value));
			case "/":
				throw new Exception(type~" veri türünü "~rhs.type~" veri türüne bölemezsiniz.");
			case "-":
				throw new Exception(type~" veri türünü "~rhs.type~" veri türünden çıkartamazsınız.");
			case "%":
				throw new Exception(type~" veri türünü "~rhs.type~" veri türüne modunu alamazsınız.");
		}
	}

	this(string value){
		this.functions = ["replace": &replace, "format": &format, "indexOf": &indexOf, "lastIndexOf": &lastIndexOf, "splitLines": &splitLines];
 		this.value = value;
		super("STRING");
		this.typ = 2;
	}
}
class htmlprint : Command{
	this(string html){
		super("TYPE");
		this.value = html;
	}
	public:
	override Command run(dataManagement dM){
		dataPool.html~= value;
		return null;
	}
}

Command _calc(Command[] rpn){
	if(rpn.length==1) return rpn[0];
	else return new calculate(rpn);
}

Command _calc2(Command[] rpn){
	if(rpn.length==1) return rpn[0];
	else return new calc(rpn);
}

class calculate : Command{//logic, comparing

	Command[] rpn;
	this(Command[] rpn){
		super("CALCULATE");
		this.rpn = rpn;
	}
	override Command run(dataManagement dM){
		if(rpn.length==1) return rpn[0].run(dM);
		Command rt1x = rpn[0].run(dM);
		Command rt2x;
		Command sonuc;
		RhBool boo = new RhBool(true);
		Command[] list;
		int ilm;
		bool wh = true;
		while(rpn.length>ilm+2 && wh){
			rt2x = rpn[ilm+2].run(dM);
			final switch(rpn[ilm+1].value){
				case "and":
					if(rt1x.isEmpty()){ sonuc=rt1x; wh = false;}
					else rt1x = sonuc= rpn[ilm+2].run(dM);
					break;
				case "or": 
					if(rt1x.isEmpty()) rt1x = sonuc= rpn[ilm+2].run(dM);
					else{sonuc=rt1x; wh = false;}
					break;
				case "==": wh = boo.value = rt1x == rt2x; sonuc=boo; break;
				case "!=": wh = boo.value = rt1x != rt2x; sonuc=boo; break;
				case ">":  wh = boo.value = rt1x >  rt2x; sonuc=boo; break;
				case "<":  wh = boo.value = rt1x <  rt2x; sonuc=boo; break;
				case "<=": wh = boo.value = rt1x <= rt2x; sonuc=boo; break;
				case ">=": wh = boo.value = rt1x >= rt2x; sonuc=boo; break;
				case "in": wh = boo.value = rt2x.isIn(rt1x); sonuc=boo; break;
			}
			ilm+=2;
		}
		return sonuc;
	}
}
class calc : Command{//Arithmetic
	Command[] rpn;
	this(Command[] rpn){
		super("CALC");
		this.rpn = rpn;
	}
	override Command run(dataManagement dM){
		if(rpn.length==1) return rpn[0].run(dM);
		Command[] list;
		foreach(rp; rpn){
			if (rp.type == "AO"){
				list[$-2] = list[$-2].run(dM).op(rp.value, list[$-1].run(dM), dM);
				list = list[0..$-1];
			}else list ~= rp;
		}
		return list[0];
	}
}
class dFunction : Command{
	Command delegate (Command[], Command, dataManagement) dF;
	Command sub;
	this(Command delegate (Command[], Command, dataManagement) dF, Command sub = null){
		this.sub = sub;
		super("dFunction");
		this.dF = dF;
	}
	override Command call(dataManagement dM, Command[] z){
		return dF(z, sub, dM);
	}
}
class word : Command{
	this(string name){
		this.value = name;
		this.typ = 2;
		super("WORD");
	}
	override Command run(dataManagement dM){
		if (subs.length==0) return dM.get(value, true);
		return locate(dM, dM.get(value, true), subs);
	}
}
Command locate(dataManagement dM, Command aktivp, Command[] locs){
	foreach(loc;locs){
		aktivp = (cast(subOrder) loc).run(aktivp,dM);
	}
	return aktivp;
}

class subOrder : Command{
	this(string type){
		super(type);
	}
	Command run(Command var, dataManagement dM){
		return var;
	}
}

class getSubF : subOrder{
	this(string value){
		super("getSubF");
		this.value = value;
	}

	override void opSet(Command a, Command b, dataManagement dM){
		(cast(RhClassC) a).codes[value] = b;
	}


	override Command run(Command var, dataManagement dM){
		return var.getMethod(value, dM);
	}
}
class getIndex : subOrder{
	Command value;
	this(Command value){
		super("getIndex");
		this.value = value;
	}
	override void opSet(Command z, Command h, dataManagement dM){
		z[value.run(dM)] = h;
	}

	override Command run(Command var, dataManagement dM){
		return var[value.run(dM)];
	}
}


class callIt : subOrder{
	Command[] params;
	this(Command[] params){
		super("CallIt");
		this.params = params;
	}
	override Command run(Command var, dataManagement dM){
		return (var).call(dM, params);
	}
}
class RhNone : Command{
	this(){
		super("NONE");
		this.typ = 2;
	}

	override string toString(){
		return "none";
	}
}
class RhBool : Command{
	bool value;
	this(bool value){
		super("BOOL");
		this.value = value;
		this.typ = 2;
	}
	Command set(bool value){
		this.value=value;
		return this;
	}
	override bool isEmpty(){return !value;}
	override string toString(){
		if (value) return "True"; else return "False";
	}
}

struct RhParameter{
	int lev;
	string variable;
	Command equal;
}

class RhClass : Command{
	override Command op(string operator, Command rhs, dataManagement dM=null){
		final switch(operator){
			case "+":
				throw new Exception(type~" veri türünü "~rhs.type~" veri türüyle toplayamazsınız.");
			case "*":
				throw new Exception(type~" veri türünü "~rhs.type~" veri türüyle çarpamazsınız.");
			case "/":
				throw new Exception(type~" veri türünü "~rhs.type~" veri türüne bölemezsiniz.");
			case "-":
				throw new Exception(type~" veri türünü "~rhs.type~" veri türünden çıkartamazsınız.");
			case "%":
				throw new Exception(type~" veri türünü "~rhs.type~" veri türüne modunu alamazsınız.");
		}
	}

	override string toString(){
		return "<"~value~" sınıfı>";
	}
	override Command opIndex(Command s){
		throw new Exception(value ~ " sınıfının indeksine ulaşamazsınız. Belki de opIndex kullanmak istiyorsunuzdur?");
	}

	this(string value, Command[string] codes, string fatherName = ""){
		this.fatherName = fatherName;
		this.codes=codes;
		this.value=value;
		super("RhClass");
	}
	override Command run(dataManagement dM){
		if(tanim== 0){
			if (dM.hasKey(value)) setError(1014, value);
			else if(fatherName!=""){
				if ((this.father = cast(RhClass) dM.get(fatherName)) is null){
					setError(1037);
				}
			}
			dM[value] = this;
			tanim++;
		}
		return null;
	}
	override Command getMethod(string m, dataManagement dM){
		switch(m){
			case "name": return new RhString(value);
			default:
				throw new Exception(type ~ " tipine ait " ~ m ~ " alt fonksiyonu bulunmamaktadır.");
		}
		assert(0);
	}
	override Command call(dataManagement dM, Command[] fonkParams){
		return new RhClassC(value, fonkParams, codes, father, dM);
	}
	public:
	string fatherName;
	Command[string] codes;

	int tanim;
	RhClass father;

}
class RhSuper : Command{
	bool callStatus = false;
	dataManagement codes;
	Command[string] vals;

	this(RhClass father, dataManagement codes){
		this.value = father.value;
		this.vals = father.codes;
		super("CLASS");
		setFather(father, codes);
	}
	void setFather(RhClass father, dataManagement codes){
		this.codes = new dataManagement(codes);
		if(father.father !is null) this.codes["super"] = new RhSuper(father.father, codes);
		foreach(a, b; father.codes) codes[a] = b;
	}
	override Command call(dataManagement dM, Command[] fonkParams){
		if(!callStatus) vals["this"].call(codes, fonkParams);
		else{
			if (codes.hasKey("opCall")) codes["opCall"].call(dM, fonkParams);
			else throw new Exception(value ~ " sınıfını çağıramazsınız. Belki de opCall kullanmak istiyorsunuzdur?");
		}
		return this;
	}
}

class RhClassC : Command{
	dataManagement codes;
	bool inherit = false;
	RhClassC father;
	

	this(string value,Command[] fonkParams, Command[string] codess, RhClass father,dataManagement dM){
		this.value = value;
		super("CLASS");
		codes = new dataManagement(dM);
		if (father !is null ){
//			codes = new dataManagement(setFather(dM, father));
			codes["super"] = new RhSuper(father, codes);
		}
		foreach(a, b; codess){
			codes[a] = b;
		}
		codes["self"] = this;
		Command aktivm;
		if (codes.hasKey("this")){
//			(cast(RhFunction) codes["this"]).self=codes;
			if ((aktivm = (cast(RhFunction) codes["this"]).call(codes, fonkParams)).type != "NONE") setError(1005, "this", "NONE");
		}
		this.type = "RhClass";
	}
	override Command op(string operator, Command rhs, dataManagement dM=null){
		dataManagement dM2 = new dataManagement(dM);
		final switch(operator){
			case "+":
				if (codes.hasKey("opAdd")) return codes["opAdd"].call(dM2, [rhs]);
				throw new Exception(type~" veri türünü "~rhs.type~" veri türüyle toplayamazsınız.");
			case "*":
				if (codes.hasKey("opMul")) return codes["opMul"].call(dM2, [rhs]);
				throw new Exception(type~" veri türünü "~rhs.type~" veri türüyle çarpamazsınız.");
			case "/":
				if (codes.hasKey("opDiv")) return codes["opDiv"].call(dM2, [rhs]);
				throw new Exception(type~" veri türünü "~rhs.type~" veri türüne bölemezsiniz.");
			case "-":
				if (codes.hasKey("opSub")) return codes["opSub"].call(dM2, [rhs]);
				throw new Exception(type~" veri türünü "~rhs.type~" veri türünden çıkartamazsınız.");
			case "%":
				if (codes.hasKey("opMod")) return codes["opMod"].call(dM2, [rhs]);
				throw new Exception(type~" veri türünü "~rhs.type~" veri türüne modunu alamazsınız.");
		}
	}

	override string toString(){
		if(codes.hasKey("toString")){
			return codes["toString"].call(codes, []).toString();
		}
		return "<"~value~" sınıfı>";//bura çıktı verilir print dersen ama value yi diğer sınıftan aldırtmadım o yüzden değeri yazmıyor
	}
	override Command opIndex(Command s){
		if(codes.hasKey("opIndex")){
			return codes["opIndex"].call(codes, [s]);
		}
		throw new Exception(value ~ " sınıfının indeksine ulaşamazsınız. Belki de opIndex kullanmak istiyorsunuzdur?");
	}
	override Command getMethod(string m, dataManagement dM){
		//		switch(m){
		//			case "str": return new RhString(to!string(value));
		//			case "length": return new RhInt(value.length);
		//			default:
		if (codes.hasKey(m)) return codes[m];
		else throw new Exception(type ~ " tipine ait " ~ m ~ " alt fonksiyonu bulunmamaktadır.");
		//		}
		assert(0);
	}
	override Command call(dataManagement dM, Command[] fonkParams){
		if (codes.hasKey("opCall")){
			codes["opCall"].call(dM, fonkParams);
		}else{
			throw new Exception(value ~ " sınıfını çağıramazsınız. Belki de opCall kullanmak istiyorsunuzdur?");
		}
		return this;
	}
}


class RhPlus : subOrder{
	this(string value){
		super("RhPlus");
		this.value = value;
	}
	override Command run(Command var, dataManagement dM){
		if(var.type=="INT") (cast(RhInt) var).value++;
		else if(var.type=="FLOAT") (cast(RhFloat) var).value++;
		else throw new Exception("Bu veri türü için ++ methodu kullanılamaz!");
		return var;
	}
}

class RhFunction : Command{
	this(string name, RhParameter[] parameters, Command[] codes){
		this.codes = codes;
		this.value = name;
		this.parameters = parameters;
		super("RhFunction");
		this.typ = 2;
	}
	Command[] codes;
	RhParameter[] parameters;
	override Command run(dataManagement dM){
		dM[value] = this;
		return null;
	}
	override Command getMethod(string m, dataManagement dM){
		switch(m){
			case "name": return new RhString(value);
			default:
//			if (codes.hasKey(m)) return codes[m];
//			else
				throw new Exception(type ~ " tipine ait " ~ m ~ " alt fonksiyonu bulunmamaktadır.");
		}
		assert(0);
	}
	override Command call(dataManagement dM, Command[] fonkParams){
		Command[string] defined;
		Command[string] defaults;
		Command[] ampersands ;
		standParams(parameters, fonkParams, defined, defaults, ampersands, dM);
		dataManagement dM3 = new dataManagement(dM);

		foreach(xxx;defaults.keys) if (defaults[xxx] !is null) dM3[xxx]= defaults[xxx].run(dM);
		foreach(xxx;defined.keys)  if (defined[xxx]  !is null) dM3[xxx]= defined[xxx].run(dM);

		Command aktivm = new RhNone();
		int i=0;
		sign  ~= "call";
		sign3 ~= &i;
		sign4 ~= codes.length;
		sign5 ~= &aktivm;
		while(i<codes.length){
			codes[i].run(dM3);
			i++;
		}
		sign.length--;
		sign3.length--;
		sign4.length--;
		sign5.length--;
		return aktivm;
	}
}
class RhComsig : Command{
	Command v1;
	this(string typ, Command v1 = null){
		super("SIGNAL");
		this.v1 = v1;
		this.value = typ;
	}
	override Command run(dataManagement dM){
		int z;
		start:
		z++;
		final switch(value){
			case "return":
				final switch(sign[$-z]){
					case "call": *(sign3[$-z])=sign4[$-z]; *(sign5[$-z])= v1.run(dM); goto end;
					case "while": *(sign3[$-z])=sign4[$-z];*(sign5[$-z]) = new RhNone(); goto start;
				}
				break;
			case "continue":
				final switch(sign[$-z]){
					case "while", "for", "foreach": *(sign3[$-z])=sign4[$-z]; goto end;
					case "call": throw new Exception("Burada continue kullanamazsınız!");
				}
		}
		goto start;
		end:
		return null;
	}
}
void standParams(RhParameter[] funcParams, Command[] userParams, out Command[string] defined, out Command[string] defaults, out Command[] ampersands, dataManagement dM){
	Command[string] requires;
	foreach(ab;funcParams){
		if(ab.lev==0){
			requires[ab.variable]=null;
		}else if(ab.lev==1){
			defaults[ab.variable]=ab.equal;
		}else if(ab.lev==2){
			defaults[ab.variable]=new RhArray();
		}else if(ab.lev==3){
			defaults[ab.variable]=new RhDictionary();
		}else if(ab.lev==4){
			requires[ab.variable]=null;
		}
	}
	int i, fi;
	while (i<userParams.length){
		if (fi >= funcParams.length){
			setError(1023);
		}else if(funcParams[fi].lev < 2){
			if (userParams[i].type == "equalIt"){
				if(userParams[i].value in defined){
					setError(1014, userParams[i].value);
				}else if(userParams[i].value in requires){
					requires.remove(userParams[i].value);
					defined[userParams[i].value] = (cast (equalIt) userParams[i]).eqVal;
				}else if(userParams[i].value in defaults){
					defaults.remove(userParams[i].value);
					defined[userParams[i].value] = (cast (equalIt) userParams[i]).eqVal;
				}else{
					setError(1024, userParams[i].value);
				}
				fi++;
				i++;
			}else if(userParams[i].type == "getParacodes"){
				fi++;
			}else{
				int emily=0;
				while (emily<funcParams.length){
					if (funcParams[emily].variable in defined){
						emily+=1;
						continue;
					}else if (funcParams[emily].variable in requires){
						requires.remove(funcParams[emily].variable);
						defined[funcParams[emily].variable]=userParams[i];
						break;
					}else if (funcParams[emily].variable in defaults){
						requires.remove(funcParams[emily].variable);
						defined[funcParams[emily].variable]=userParams[i];
						break;
					}else{
						setError(1025);
					}
				}
				fi++;
				i++;
			}
		}else if(funcParams[fi].lev == 2){
			Command[] xx2;
			while (i<userParams.length && !(userParams[i].type=="equalIt")){
				xx2 ~= userParams[i];
				i++;
			}
			if (funcParams[fi].variable in defined){
				setError(1014, funcParams[fi].variable);
			}
			defined[funcParams[fi].variable] = new RhArray(xx2);
			fi++;
		}else if(funcParams[fi].lev == 3){
			Command[string] xx2;
			while (i<userParams.length && (userParams[i].type=="equalIt")){
				xx2[userParams[i].value] = (cast(equalIt) userParams[i]).eqVal;
				i++;
			}
			if (funcParams[fi].variable in defined){
				setError(1014, funcParams[fi].variable);
			}
			defined[funcParams[fi].variable]=new RhDictionary(xx2);
			fi++;
		}else if(funcParams[fi].lev == 4){
			if(userParams.length==0) setError(1027);
			string var = funcParams[fi].variable;
			requires.remove(var);
			defined[var]=userParams[$-1];
			break;
		}else{
			setError(1026);
		}
	}
	if (requires.length!=0){
		setError(1027);
	}
}

class equalIt : Command{
	this(Command eqVal, Command[] subs, string name, string tlp){
		this.eqVal = eqVal;
		this.tlp = tlp;
		this.subs = subs;
		this.value = name;
		super("equalIt");
		this.typ = 2;
	}
public:
	string tlp;
	Command eqVal;
	override Command run(dataManagement dM){
		if(subs.length < 1 ){
			if(tlp=="=") dM[value] = eqVal.run(dM);
			else dM[value].setWop(tlp[0..1],eqVal.run(dM));
		}else{
			Command h = eqVal.run(dM);
			Command z = locate(dM, dM[value], subs[0..$-1]);
			subs[$-1].opSet(z, h, dM);
		}
		return new RhNone();
	}
}

struct RhIfS{
	Command cond;
	Command[] codes;
}