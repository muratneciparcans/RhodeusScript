/*
Rhodeus Script (c) by Talha Zekeriya Durmuş

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/
module parserizer.keywords;
import parser;
static import parserizer.fs;
import std.stdio;
import interpreter: dataManagement;
import Commands;
class KeywordParser{
	parserizer.fs.fs fs;
	Parser self;
	this(ref parserizer.fs.fs _fs){
		fs = _fs;
		self = _fs.self;
		fs.wordFunctions = ["while": &p_while, "if": &p_if,"for": &p_for, "foreach": &p_foreach, "Function": &p_function, "Class":&p_class];
//		fs.wordFunctions = ["try": &p_try]; "throw": &p_throw,
	}

	Command p_class(){
		string name;
		Command test;
		bool[string] attrs;
		while (self._isTrue()){
			test = self._getIt();
			if (test.type=="WORD") name = test.value;
			else if (test.type=="NEWLINE") {(*self.curLine)++;continue;}
			break;
		}
		if (name=="") self.throwError(1002, "Sınıf ismi");

		string father;
		while(self._isTrue()){
		  test = self._getIt();
		  if(test.type=="SYMBOL" && test.value==":"){
			  if(self._isTrue()){
				  test = self._getIt();
				  if (test.type=="WORD") father = test.value;
				  else self.i--;
			  }
			  if (father=="") self.throwError(1036, "");
			  break;
		  }else if (test.type!="WORD"){
			  self.i--;
			  break;
		  }else if(test.value=="throwable"){
			  if (test.value in attrs) self.throwError(1029, test.value);
			  attrs[test.value] = 1;
		  }
		}

		int mod;
		Command[string] pc;
		bool kama=false;//kama bekleniyor mu?
		Command item;
		Command retVal;
		while (self._isTrue()){
			item = self._getIt();
			if (mod==0 && item.type=="SYMBOL" && item.value== "{"){
				mod=1;
			}else if (mod==1 && item.type=="SYMBOL" && item.value== "}"){
				mod=-1;
				break;
			}else if (mod==1){
				item = self.getIt(item);
				if (item.type=="RhFunction"){
					pc[item.value] = item;
				}else if(item.type=="RhClass"){
					pc[item.value] = item;
				}else if(item.type=="equalIt"){
					pc[item.value] = (cast(equalIt) item).eqVal;
				}else if(item.type=="NEWLINE"){
					(*self.curLine)++;
				}else if((item.type=="SYMBOL" && item.value==";")){
				}else{
					self.throwError(1035, item.type);
				}
			}else{
				self.i--;
				break;
			}
		}
		if (mod == 0) self.throwError(1002, "{");
		else if(mod != -1) self.throwError(1002, "}");
		return new RhClass(name, pc, father);
	}

	Command p_foreach(){
		Command[string] params;
		Command[] temps = [];
		int mod;
		Command item;
		Command getIt;
		string eqIt;
		if(self._isTrue()){
			item = self._getIt();
			if (item.type=="SYMBOL" && item.value == "("){
				item = self._getIt();
				if(item.type=="WORD") eqIt = item.value;
				else self.throwError(1004, "WORD",item.type);
				item = self._getIt();
				if(item.type!="SYMBOL" || item.value!=";") self.throwError(1004, "WORD",item.type);
				while (self._isTrue()){
					item = self._getIt();
					if(item.type=="SYMBOL" && item.value==")"){
						mod=-1;
						break;
					}
					item = self.getIt(item);
					if(item.typ > 0) temps ~= item;
					else self.throwError(1001, item.type);
				}
				getIt = self.yard(temps);
			}else{
				self.i--;
			}
		}
		if (mod == 0) self.throwError(1015, "");
		else if(mod != -1) self.throwError(1019, "");
		Command[] test2;
		if (!fs.getParacodes(test2)) self.throwError(1002, "{");
		return new RhForeach(eqIt, getIt,test2);
	}

	Command p_for(){
		Command[string] params;
		Command[] temps;
		int mod;
		Command a1, a2, a3;
		Command item;
		if(self._isTrue()){
			item = self._getIt();
			if (item.type=="SYMBOL" && item.value == "("){
				while (self._isTrue()){
					item = self._getIt();
					if(item.type=="SYMBOL" && item.value==";"){
						mod=-1;
						break;
					}
					item = self.getIt(item);
					if(item.typ > 0) temps ~= item;
					else self.throwError(1001, item.type);
				}
				a1 = temps ==[] ? null : self.yard(temps);
				temps=[];
				while (self._isTrue()){
					item = self._getIt();
					if(item.type=="SYMBOL" && item.value==";"){
						mod=-1;
						break;
					}
					item = self.getIt(item);
					if(item.typ > 0) temps ~= item;
					else self.throwError(1001, item.type);
				}
				a2 = temps ==[] ? null : self.yard(temps);
				temps=[];
				while (self._isTrue()){
					item = self._getIt();
					if(item.type=="SYMBOL" && item.value==")"){
						mod=-1;
						break;
					}
					item = self.getIt(item);
					if(item.typ > 0) temps ~= item;
					else self.throwError(1001, item.type);
				}
				a3 = temps ==[] ? null : self.yard(temps);
			}else{
				self.i--;
			}
		}

		if (mod == 0) self.throwError(1015, "");
		else if(mod != -1) self.throwError(1019, "");
		Command[] test2;
		if (!fs.getParacodes(test2)) self.throwError(1002, "{");
		return new RhFor(a1,a2,a3, test2);
	}

	Command p_function(){
		Command test;
		string name;
		while (self._isTrue()){
			test = self._getIt();
			if (test.type=="WORD") name = test.value;
			else if (test.type=="NEWLINE"){(*self.curLine)++;continue;}
			break;
		}
		if (name=="") self.throwError(1002, "Fonksiyon ismi");
		if (self._isTrue()) test = self._getIt();
		if(test.type!="SYMBOL" || test.value!="(") self.throwError(1004, "'('",test.type);
		bool kama=false;
		int[string] tevars;
		string defIt;
		int lev;
		int asteriks;
		int lastlevel;
		RhParameter[] parameters;
		while(self._isTrue()){
			test = self._getIt();
			if(kama==false && test.type == "WORD"){
				int lev2;
				string tlp;
				Command[] equalVal;
				if(asteriks==0){
					if (fs.getEqualVal(tlp, equalVal)){
						if(tlp != "=") self.throwError(1002, "=");
						lev2=1;
					}
				}else if(asteriks<4) lev2=asteriks+1;
				else lev2=asteriks+1;
				if ((lastlevel>1 && lastlevel>=lev2) || (lastlevel==1 && lev2==0)) self.throwError(1017, "");
				else if (test.value in tevars) self.throwError(1014, test.value);
				tevars[test.value]=0;
				if(lev2 == 1){
					if(tlp!="=") self.throwError(1002, "=");
					parameters ~= RhParameter(lev2, test.value, _calc(equalVal));
				}else{
					parameters ~= RhParameter(lev2, test.value, null);
				}
				lev=lev2;
				kama=true;
			}else if(kama==false && test.type == "AO" && test.value=="*") asteriks++;
			else if (test.type=="SYMBOL" && test.value==")") break;
			else if(kama == true && test.type=="SYMBOL" && test.value=="," ){
				kama = false;
				asteriks=0;
			}else self.throwError(1001, test.type);
		}
		Command[] pc;
		if (!fs.getParacodes(pc)) self.throwError(1002, "{");
		Command ret = new RhFunction(name, parameters, pc);
		ret.line = dataPool.linetmp;
		return ret;
	}
	
	Command p_if(){
		RhIfS[] ifs;
		Command test;
		Command[] test2;
		test = fs.getParams(0,1,false);
		if (test is null || (cast(callIt) test).params.length == 0) self.throwError(1015, "");
		if (!fs.getParacodes(test2)) self.throwError(1002, "{");
		ifs ~= RhIfS((cast(callIt) test).params[0], test2);
		int eks;
		while(self._isTrue()){
			test = self._getIt();
			if (test.type=="W_elif"){
				test = fs.getParams(0,1,false);
				if (test is null || (cast(callIt) test).params.length == 0) self.throwError(1015, "");
				if (!fs.getParacodes(test2)) self.throwError(1002, "{");
				ifs ~= RhIfS((cast(callIt) test).params[0], test2);
				eks=0;
			}else if (test.type=="W_else"){
				if (!fs.getParacodes(test2)) self.throwError(1002, "{");
				ifs ~= RhIfS(null, test2);
				eks=0;
				break;
			}else if(test.type=="NEWLINE"){
				(*self.curLine)++;
				eks++;
				continue;
			}else{
				eks++;
				self.i-=eks; break;
			}
		}
		return new RhIf(ifs);
	}
	
//	Variant p_throw(){
//		return Variant( ["type": Variant("THROW"), "value": Variant(fs.getEqualVal(1)[1])] );
//	}
	/*
	Variant p_try(){
		Variant[string] ifs;
		Variant test2, test;
		test2 = fs.getParacodes();
		if (test2==false) self.throwError(1002, "{");
		ifs["try"] = test2;
		Variant[][] catchs;
		int delC;
		bool breakIt=false;
		while(self._isTrue()){
			test = self._getIt();
			if (test.type=="W_catch"){
				delC = 0;
				Variant[string] params;
				Variant item;
				if(self._isTrue()){
					item = self._getIt();
					if (item.type=="SYMBOL" && item.value== "("){
						item = self.getIt(self._getIt());
						if(item.type=="WORD") params["tyIt"] = item;
						else self.throwError(1004, "WORD",item.type);
						item = self.getIt(self._getIt());
						if(item.type=="SYMBOL" && item.value==")"){
							params["valIt"] = params["tyIt"];
							params["tyIt"] = null;
							breakIt=true;
						}else{
							if(item.type=="WORD") params["valIt"] = item;
							else self.throwError(1004, "WORD",item.type);
							item = self._getIt();
							if(item.type!="SYMBOL" || item.value!=")") self.throwError(1004, "WORD",item.type);
						}
					}else{
						self.i--;
					}
				}
				test2 = fs.getParacodes();
				if (test2==false) self.throwError(1002, "{");
				if (test==false || test.length == 0){
					catchs ~= [Variant(false), test2];
					break;
				}else if(breakIt){
					catchs ~= [Variant(params), test2];
					break;
				}else{
					catchs ~= [Variant(params), test2];
				}
			}/*else if (test.type=="W_finally"){
				test2 = fs.getParacodes();
				if (test2==false){
					self.throwError(1002, "{");
				}
				ifs["finally"] = [Variant(false), test2];
				break;
			}*//*
			else if(test.type=="NEWLINE"){
				(*self.curLine)++;
				delC++;
			}else{
				self.i-=delC;
				(*self.curLine)-=delC;
				self.i--; break;
			}
		}
		ifs["catch"]=Variant(catchs);
		return Variant( ["type": Variant("TRY"), "value": Variant(ifs)] );
	}
	*/
	Command p_while(){
		Command params = fs.getParams(0, -1, false);
		if (params is null || (cast(callIt) params).params.length == 0) self.throwError(1020, "while");
		Command[] codes;
		if (!fs.getParacodes(codes)) self.throwError(1002, "{");
		return new RhWhile((cast(callIt) params).params[0], codes);
	}
}