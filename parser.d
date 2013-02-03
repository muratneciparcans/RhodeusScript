/*
Rhodeus Script (c) by Talha Zekeriya Durmuş

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/
module parser;
import std.file, errorHandling.errorHandler, std.string, std.conv;
import std.ascii;
import std.string: repr = replace;
import std.stdio;
import Commands;
static import parserizer.fs;
class Parser{
	private char[] codes;
	private int size;
	private int wci;
	public int i;
	private char[char] chars;
	private char[char] charsR;

	private string[char] symbols;
	private string[string] keyVals;
	public int prec[string];
	public Command delegate (Command) [string] getItFunctions;
	public Command[] tokens;
	private string tmp;
	private int tmpf;
	private int im;
	private bool tmpl;
	private string tmpls;
	private bool fl1 = false;
	private char c;
	private string MOD;
	public int* curLine;
	parserizer.fs.fs fs;
	this(int* _curLine){
		this.curLine = _curLine;
		chars= ['n': '\n', 't': '\t', 'r': '\r', 'a': '\a','f': '\f', 'b': '\b', 'v': '\v', '\"': '\"','?': '?', '\\': '\\', '\'': '\''];
		charsR= ['n': '\n', 't': '\t', 'r': '\r', 'a': '\a','f': '\f', 'b': '\b', 'v': '\v'];
		keyVals = ["else": "W_else", "elif": "W_elif", "catch": "W_catch", "finally": "W_finally"];
		symbols = ['+': "AO",'^': "AO", '-': "AO", '*': "AO", '/': "AO", '>': "CO",'!': "CO", '<': "CO", '=': "EQ", '%':"AO"];
		prec =  ["!": 5,"%":4 ,"^":3 ,"*": 2, "/": 2, "+": 1, "-": 1];
		fs = new parserizer.fs.fs(this);
	}
	void load(string S){
		codes = cast(char[]) S;
		size = cast(int) codes.length;
		wci = 0;
		i=0;
	}
	void loadFile(string url){
		if(!exists(url)) this.throwError (101, url);
		codes = cast(char[]) read(url);
		size = cast(int) codes.length;
		wci = 0;
		i=0;
	}
	void throwError(T...)(int number, T args){
		throw new RhError(number, args);
	}
	void addTokenW(string val){
		this.tokens ~= new word(val);
	}
	void addToken(bool val){
		this.tokens ~= new RhBool(val);
	}

	void addToken(){
		this.tokens ~= new RhNone();
	}

	void addToken(string type, string val){
		this.tokens ~= new spec(type, val);
	}
	void addToken(string type, int val){
		this.tokens ~= new RhInt(val);
	}
	void addTokenS(string val){
		this.tokens ~= new RhString(val);
	}
	void addToken(string type, float val){
		this.tokens ~= new RhFloat(val);
	}
	void addToken(Command val){
		this.tokens ~= val;
	}

	void clear(){
		this.tokens = [];
	}

	void None(){
		while (wci<size){
			c = codes[wci];
			tmpl=false;
			if (isWhite(c)){
				if (c=='\n') {addToken("NEWLINE",text(c)); dataPool.line++;}
				wci++;
     		}else if (isAlpha(c) || (c>127 && c<168) || c=='_')
				Word();
			else if (isDigit(c))
				Digit();
			else if (c == '\"' || c == '\'')
				String();
			else{
				if (c=='-' && wci+1<size && isDigit(codes[wci+1])) {Digit(); continue;};
				if (c=='/' && wci+1<size && (codes[wci+1]=='/' || codes[wci+1]=='*')) Comment();
				else if (c=='|' && wci+1<size && (codes[wci+1]=='>')){
					wci+=2;
					im=indexOf(codes[wci..$], "<|");
					if (im==-1){
						if (codes[wci..$].length!=0) addToken(new htmlprint(text(codes[wci..$])));
						wci=size;
						fl1 = true;
					}else{
						if (codes[wci..wci+im].length!=0) addToken(new htmlprint(text(codes[wci..wci+im])));
						wci+=im+2;
						if(indexOf(codes[wci..$], "|>")==-1){
							this.throwError(1034);
						}
					}
				}
				else{
					wci++;
					if(c in symbols){
						if (symbols[c]=="AO"){
							if(wci<size){
								if(codes[wci]=='='){
									wci++;
									addToken("EQ",text(c)~"=");
									continue;
								}else if(codes[wci]=='+' && c=='+'){
									addToken("EEQ",text(c)~text(codes[wci]));
									wci++;
									continue;
								}else if(codes[wci]=='-' && c=='-'){
									addToken("EEQ",text(c)~text(codes[wci]));
									wci++;
									continue;
								}
							}
						}else if (symbols[c]=="CO"){
							if(wci<size){
								if(codes[wci]=='='){
									addToken("CO",text(c)~text(codes[wci]));
									wci++;
									continue;
								}else if(c=='!'){
									addToken("AO",text(c));
									continue;
								}
							}
						}else if (symbols[c]=="EQ"){
							if(wci<size){
								if(codes[wci]=='='){
									addToken("CO",text(c)~text(codes[wci]));
									wci++;
									continue;
								}
							}
						}
						addToken(symbols[c],text(c));
					}else{
						addToken("SYMBOL",text(c));
					}
				}
			}
		}
	}
	void Comment(){
		if (codes[wci..wci+2] == "//"){
			wci+=indexOf(codes[wci+2..$], "\n");
			wci+=2;
		}else if(codes[wci..wci+2] == "/*"){
			wci+=indexOf(codes[wci+2..$], "*/");
			wci+=4;
		}
	}
	void Word(){
		tmp = "";
		if (c=='r' && wci+1<size && (codes[wci+1]=='\'' || codes[wci+1]=='"' ) ){
			wci++;
			StringR();
			return;
 		}
		while (wci < size){
			c = codes[wci];
			if (isAlphaNum(c) || (c>127 && c<168) || c=='_'){
				tmp ~= c;
				wci++;
			}else
				break;
		}
		if (tmp=="and" || tmp=="or" || tmp=="in"){
			addToken("LO",tmp);
		}else if(tmp in keyVals){
			addToken(keyVals[tmp], tmp);
		}else if(tmp == "true"){
			addToken(true);
		}else if(tmp == "false"){
			addToken(false);
		}else if(tmp == "none"){
			addToken();
		}else{
			addTokenW(tmp);
		}
	}
	void String(){
		tmp = "";
		tmpf = 0;
		char wait = codes[wci];
		wci++;
	zipla:
		while (wci < size){
			c = codes[wci];
			if(tmpf == 0){
				if (c == wait){
					tmpf = -1;
					wci++;
					break;
				}
				else if (c == '\\') tmpf = 1;
				else tmp ~= c;
				wci++;
			}else{
				int ii = 0, iim = 3;
				if (c == 'u'){
					iim = 4;
					wci++;
				}
				else if (c == 'x'){
					iim = 2;
					wci++;
				}
				else if (c == 'U') { iim = 8; wci++; }
				else if (c in chars){
					tmpf = 0;
					tmp ~= chars[c];
					wci++;
					continue;
				}else{
					tmpf = 0;
 					wci++;
					tmp ~= c;
					goto zipla;
				}
				string tmp2 = "";
				while (wci < size && ii < iim){
					c = codes[wci];
					if (!isHexDigit(c)){
						goto zipla;
					}
					tmp2 ~= c;
					wci++;
					ii++;
				}
				if (ii != iim) this.throwError(1032, iim-ii);
				if (iim == 3) tmp ~= parse!int(tmp2, 8);
				else tmp ~= parse!int(tmp2, 16);
				tmpf = 0;
			}
		}
		if (tmpf != -1) this.throwError(1002, "\"");
		addTokenS(tmp); 
	}
	void StringR(){
		tmp = "";
		tmpf = 0;
		char wait = codes[wci];
		wci++;
	zipla:
		while (wci < size){
			c = codes[wci];
			if(tmpf == 0){
				if (c == wait){
					tmpf = -1;
					wci++;
					break;
				}
				else if (c == '\\'){
					tmp ~= c;
					tmpf = 1;
				}
				else
					tmp ~= c;
				wci++;
			}else{
				int ii = 0, iim = 3;
				if (c == 'u'){
					iim = 4;
					wci++;
				}
				else if (c == 'x'){
					iim = 2;
					wci++;
				}
				else if (c == 'U') { iim = 8; wci++; }
				else if (c in chars){
					tmpf = 0;
					tmp ~= c;
					wci++;
					continue;
				}else{
					tmpf = 0;
					wci++;
					tmp ~= c;
					goto zipla;
				}
				while (wci < size && ii < iim){
					c = codes[wci];
					if (!isHexDigit(c)){
						goto zipla;
					}
					tmp ~= c;
					wci++;
					ii++;
				}
				if (ii != iim){
					this.throwError(1032, iim-ii);
				}
				tmpf = 0;
			}
		}
		if (tmpf != -1){
			this.throwError(1002, wait);
		}
		foreach(ch1, ch2;charsR){
			tmp = tmp.repr(text(ch2),text("\\"~ch1));
		}
		addTokenS(tmp); 
	}
	void Digit(){
		MOD = "INT";
		tmp = "";
		tmpf = 0;
		if ((wci+1 < size) && codes[wci + 1] == 'x'){
			wci++;
			wci++;
			HexD();
			return;
		}else if(codes[wci]=='-'){
			tmp ~="-";
			wci++;
		}
		while (wci < size){
			c = codes[wci];
			if (isDigit(c)){
				tmp ~= c;
				wci++;
			}
			else if ('.' == c && tmpf == 0 && isDigit(codes[wci+1])){
				tmpf = 1;
				tmp ~= c;
				wci++;
				MOD = "FLOAT";
			}
			else if (c == 'e' && tmpf != 2){
				wci++;
				MOD = "FLOAT";
				tmpf = 2;
				tmp ~= c;
				if(codes[wci]=='-'){
					tmp ~= codes[wci];
					wci++;
				}
			}
			else break;
		}
		try{
		if(MOD=="INT"){
			addToken(MOD,parse!int(tmp));
		}else{
			addToken(MOD,parse!float(tmp));
		}
		}catch(Throwable x){
			this.throwError(1036, x.msg);
		}
	}
	void HexD(){
		MOD = "HEXD";
		tmp = "";
		while (wci < size){
			c = codes[wci];
			if (isHexDigit(c)){
				tmp ~= c;
				wci++;
			}else break;
		}
		try{
			addToken("INT",parse!int(tmp, 16));
		}catch(Throwable x){
			this.throwError(1036, x.msg);
		}
	}

	void parseIt(){
		int _getLine(){
			return -1;
		}
		tokens.clear();
		im=indexOf(codes[wci..$], "<|");
		if (im==-1){
			if (codes[wci..$].length!=0) addToken(new htmlprint(text(codes[wci..$])));
			wci=size;
		}else{
			if (codes[wci..wci+im].length!=0) addToken(new htmlprint(text(codes[wci..wci+im])));
			wci+=im+2;
			if(indexOf(codes[wci..$], "|>")==-1){
				this.throwError (102);
			}
		}
		None();
	}


	bool _isTrue(){
	  return i<tokens.length;
	}
	Command _getIt(){
	  i++;
	  return tokens[i-1];
	}

	Command getIt(Command x){
		if(x.type in getItFunctions) return getItFunctions[x.type](x);
		return x;
	}
	Command[] paraphrase(){
		Command[] datas;
		Command x;
		Command z;
		while (_isTrue()){
			x = _getIt();
			switch (x.type){
				case "NEWLINE":
					(*curLine)++;
					continue;
				case "SYMBOL":
					if(x.value==";") continue;
					goto default;
				default:
					datas ~= yard(getIt(x));
					break;
			}
		}
		return datas;
	}


 Command yard(Command token){
	  Command[] result;
	  Command[] rpn;
	  Command[] op_stack;
	  Command last;

	  bool w = false;
	  while (1){
		  if(token.typ == 1 || token.typ == 2) {
			  if (last !is null && (last.typ == 1 || last.typ == 2)) throwError(1021);
			  rpn ~= token;
			  w = true;
		  }else if(token.type=="CO" || token.type=="LO" ){
				  while(op_stack.length>0){
					  rpn ~= op_stack[$-1];
					  op_stack= op_stack[0..$-1];
				  }
				  result ~= _calc2(rpn);
				  result ~= token;
				  rpn = [];
		  }else if(token.type=="AO" && token.value in prec){
			  if (w == false) throwError(1045, token.value);
			  while( op_stack !=[] && prec[text(token.value)] <=  prec[text(op_stack[$-1].value)] ){
					  rpn ~= op_stack[$-1];
					  op_stack = op_stack[0..$-1];
				  }
			  w = false;
			  op_stack ~= token;
		  }else{
				  if (rpn.length==0){
					  if (op_stack.length!=0) throwError(1001,op_stack[0].value);
					  return token;
				  }
				  i--;
				  break;
			  }
		  last = token;
		  if (!_isTrue()) break;
		  token = getIt(_getIt());
	  }
	  if (w == false) throwError(1045, last.value);
	  while(op_stack.length>0){
		  rpn ~= op_stack[$-1];
		  op_stack= op_stack[0..$-1];
	  }
	  result ~= _calc2(rpn);
	  rpn = [];
	  return _calc(result);
  }
  Command yard(Command[] tokens){
	  Command[] result;
	  Command[] rpn;
	  Command[] op_stack;
	  Command last;
	  Command token;
	  int ixm;
	  if (tokens[0].type =="AO" && tokens[0].value=="!"){
		  op_stack ~= tokens[0];
		  ixm++;
	  }
	  int w = false;
	  while (ixm<tokens.length){
		  token = tokens[ixm];
		  if(token.typ == 1 || token.typ == 2) {
			  if (last !is null && (last.typ == 1 || last.typ == 2)) throwError(1021);
			  w = true;
			  rpn ~= token;
		  }else if(token.type=="CO" || token.type=="LO" ){
			  while(op_stack.length>0){
				  rpn ~= op_stack[$-1];
				  op_stack= op_stack[0..$-1];
			  }
			  result ~= _calc2(rpn);
			  result ~= token;
			  rpn = [];
		  }else if(token.type=="AO" && text(token.value) in prec){
			  if (w == false) throwError(1045, token.value);
			  while( op_stack !=[] && prec[text(token.value)] <=  prec[text(op_stack[$-1].value)] ){
				  rpn ~= op_stack[$-1];
				  op_stack = op_stack[0..$-1];
			  }
			  op_stack ~= token;
			  w = false;
		  }else{
			  break;
		  }
		  last = token;
		  ixm++;
	  }
	  if (w == false) throwError(1045, token.value);
	  while(op_stack.length>0){
		  rpn ~= op_stack[$-1];
		  op_stack= op_stack[0..$-1];
	  }
	  result ~= _calc2(rpn);
	  rpn = [];
	  return _calc(result);
  }
}
