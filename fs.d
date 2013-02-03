/*
Rhodeus Script (c) by Talha Zekeriya Durmuş

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/
module parserizer.fs;
import errorHandling.errorHandler;
import parser;
import std.conv;
import parserizer.keywords;
import Commands;
import std.stdio;
class fs{
  Parser self;
  public Command delegate() [string] wordFunctions;
  this(ref Parser _self){
	  self = _self;
	  self.getItFunctions = ["WORD":&g_word, "STRING": &g_cwiths, "INT": &g_cwiths, "SYMBOL": &g_symbol];
	  new KeywordParser(this);
  }
  Command g_cwiths(Command x){
	  Command test;
	  string gsb;
	  int last;
	  while(last != self.i){
		  last =self.i;
		  test = getBrackets();
		  if (test !is null) x.subs ~= new getIndex(test);
		  gsb = getSubFunction();
		  if (gsb !is null) x.subs ~= new getSubF(gsb);
		  test = getParams();
		  if (test !is null) x.subs ~= test;
	  }
	  return x;
  }
  Command g_symbol(Command x){
	  if ( x.value=="["){
		  return new RhArray(getArray(1));
	  }else if ( x.value == "{"){
		  return new RhDictionary(getDictionary(1));
	  }/*else if ( x["value"]=="("){
		  Variant valu = getParams(1, 1, false)[0]["value"];
		  Variant[] subs = [];
		  int last;
		  while(last != self.i){
			  last =self.i;
			  test = getBrackets();
			  if (test!=false) subs ~= Variant(["type":Variant("getIndex"), "levels":Variant(test)]);
			  test = getSubFunction();
			  if (test!=false) subs ~= Variant(["type":Variant("getSubFunction"), "name":Variant(test)]);
			  test = getParams();
			  if (test!=false) subs ~= Variant(["type":Variant("getParams"), "value":Variant(test)]);
		  }
		  return Variant(["type": Variant("CALC"), "value": valu, "subs": Variant(subs)]);
	  }*/
	  return x;
  }
  Command g_word(Command x){
	  Command test;
	  dataPool.linetmp = x.line;
	  if(x.value in wordFunctions) return wordFunctions[x.value]();
	  Command[] subs;
	  Command equal;
	  int last;
	  string tlp;
	  Command[] cmds;
	  string gsb;
	  while(last != self.i){
		  last = self.i;
		  test = getBrackets();
		  if (test !is null) subs ~= new getIndex(test);
		  gsb = getSubFunction();
		  if (gsb !is null) subs ~= new getSubF(gsb);
		  if (getEqualVal(tlp, cmds)){
			  return new equalIt(self.yard(cmds), subs, x.value, tlp);
		  }
	  }
	  last=-1;
	  string testl;
	  while(last != self.i){
		  last =self.i;
		  test = getBrackets();
		  if (test!is null) subs ~= new getIndex(test);
		  gsb = getSubFunction();
		  if (gsb !is null) subs ~= new getSubF(gsb);
		  test = getParams();
		  if (test!is null) subs ~= test;
		  if (getPlusPlus(testl)) subs ~= new RhPlus(testl);
	  }
	  x.subs = subs;
	  return x;
  }

  string getSubFunction(){
	  int mod;
	  Command item;
	  while (self._isTrue()){
		  item = self._getIt();
		  if (mod == 0 && item.type == "SYMBOL" && item.value== "."){
			  mod = 1;
		  }else if (mod==1){
			  if(item.type == "WORD"){
				  return item.value;
				  mod = -1;
			  }else{
				  self.throwError(1001, item.type);
			  }
		  }else{
			  self.i--;
			  break;
		  }
	  }
	  return null;
  }
  bool getParacodes(out Command[] params){
	  int mod;
	  bool kama=false;//kama bekleniyor mu?
	  int eks;
	  Command item;
	  eks = self.i;
	  while (self._isTrue()){
		  item = self._getIt();
		  if (mod==0){
			  if(item.type =="SYMBOL" && item.value == "{") mod=1;
			  else if(item.type=="NEWLINE") continue;
			  else break;
		  }else if (mod==1 && item.type=="SYMBOL" && item.value== "}"){
			  mod=-1;
			  break;
		  }else if (mod==1){
			  if (item.type=="WORD" && item.value=="return"){
				  Command[] retVal;
				  while(self._isTrue()){
					  item = self._getIt();
					  if(item.type=="NEWLINE" || (item.type == "SYMBOL" && item.value==";")){
						  break;
					  }
					  retVal ~= self.getIt(item);
				  }
				  if (retVal.length==0){
					  params ~= new RhComsig("return", new RhNone());
				  }else{
					  params ~= new RhComsig("return", self.yard(retVal));
				  }
			  }else if (item.type == "WORD" && (item.value=="break" || item.value=="continue")){
				  while(self._isTrue()){
					  Command itemx = self._getIt();
					  if(itemx.type=="NEWLINE" || (itemx.type=="SYMBOL" && itemx.type==";")) break;
				  }
				  params ~= new RhComsig(item.value);
			  
			  }else if(item.type == "NEWLINE"){
				  (*self.curLine)++;
			  }else if(item.type == "SYMBOL" && item.value==";"){
			  }else{
				  params ~= self.getIt(item);
			  }
		  }else{
			  self.i = eks;
			  break;
		  }
	  }
	  if (mod == 0){
		  self.i = eks;
		  return false;
	  }else if(mod != -1){
		  self.throwError(1019);
	  }
	  return true;
  }

  bool getPlusPlus(out string testl){
	  Command item;
	  while (self._isTrue()){
		  item = self._getIt();
		  if (item.type == "EEQ"){
			  testl = item.value;
			  return true;
		  }else{
			  self.i--;
			  break;
		  }
	  }
	  return false;
  }
  Command getBrackets(int max=-1){
	  Command[] params ;
	  int mod;
	  Command item;
	  if(self._isTrue()){
		  item = self._getIt();
		  if (item.type=="SYMBOL" && item.value== "[") mod=1;
		  else self.i--;
	  }
	  if (mod == 0) return null;

	  while (self._isTrue()){
		  item = self._getIt();
		  if (item.type=="SYMBOL" && item.value== "]"){
			  mod=2;
			  break;
		  }else if(item.type == "NEWLINE"){
		  }else{
			  item=self.getIt(item);
			  if(item.typ > 0){
				  params ~= item;
			  }else{
				  self.throwError(1001, item.type);
			  }
		  }
	  }
	  if(params.length==0){
		  self.throwError(1046);
	  }
	  return self.yard(params);
  }
  /*
  */
  bool getEqualVal(out string tlp,out Command[] params,int mod=0){
	  Command item;
	  Command citem;
	  int ixilcek, eks;
	  while (self._isTrue()){
		  eks = self.i;
		  item = self._getIt();
		  if (mod == 0){
			  if (item.type=="EQ"){
				  tlp = item.value;
				  mod=1;
			  }else{
				  self.i = eks;
				  break;
			  }
			  }else if (mod==1){
			  citem = self.getIt(item);
			  if(citem.typ > 0){
				  params ~= citem;
			  }else{
				  mod = -1;
				  self.i = eks;
				  break;
			  }
		  }
	  }
	  if (mod != -1) return false;
	  else if(params==[]) self.throwError(1020);
	  return true;
  }
  Command[] getArray(int mod=0){
	  string[] ayrc=["[", "]"];
	  Command[] params = [];
	  Command[] temps = [];
	  bool kama=false;//kama bekleniyor mu?
	  Command item;
	  while (self._isTrue()){
		  item = self._getIt();
			if (mod==0 && item.type=="SYMBOL" && item.value == ayrc[0]){
				mod=1;
			}else if (mod==1 && item.type=="SYMBOL" && item.value == ayrc[1]){
				mod=-1;
				if(temps!=[]){
					params ~= self.yard(temps);
					temps=[];
				}
				break;
			}else if (mod==1){
				if(item.type=="SYMBOL" && item.value==","){
					if(!kama) self.throwError(1001, item.type);
					kama=false;
					params ~= self.yard(temps);
					temps=[];
					continue;
				}
				item = self.getIt(item);
				if(item.typ > 0){
					temps ~= item;
					kama=true;
				}else if(item.type == "NEWLINE"){
				}else{
					self.throwError(1001, item.type);
				}
			}else{
				self.i--;
				break;
			}
	  }

	  if (mod == 0){
		  return null;
	  }else if(mod != -1){
		  self.throwError(1019);
	  }
	  return params;
  }
  Command[][] getDictionary(int mod=0){
	  string[] ayrc=["{", "}"];
	  Command[][] params;
	  Command[] temps = [];
	  Command[] keyname = [];
	  bool kama=false;//kama bekleniyor mu?
	  int semicolon=0;
	  Command item;
	  Command yarded;
	  while (self._isTrue()){
		  item = self._getIt();
			if (mod==0 && item.type=="SYMBOL" && item.value== ayrc[0]){
				mod=1;
			}else if (mod==1 && item.type=="SYMBOL" && item.value== ayrc[1]){
				if(semicolon!=0) self.throwError(1038);
				mod=-1;
				if(temps!=[] && keyname!=[]){
					params ~= [self.yard(keyname), self.yard(temps)];
					temps=[];
					keyname=[];
				}
				break;
			}else if (mod==1){
				if(item.type=="SYMBOL" && item.value==","){
					if(!kama) self.throwError(1001, item.type);
					kama=false;
					params ~= [self.yard(keyname), self.yard(temps)];
					temps=[];
					keyname=[];
					continue;
				}else if(semicolon==1 && item.type=="SYMBOL" && item.value==":"){
					semicolon=2;
					continue;
				}
				item = self.getIt(item);
				if(item.typ>0){
					if(semicolon==2){
						temps ~= item;
						semicolon=0;
					}else{
						keyname ~= item;
						semicolon=1;
					}
					kama=true;
				}else if(item.type != "NEWLINE"){
					self.throwError(1001, item.type);
				}
			}else{
				self.i--;
				break;
			}
	  }
	  if (mod == 0){
		  return null;
	  }else if(mod != -1){
		  self.throwError(1019);
	  }
	  return params;
  }
  Command getParams(int mod=0, int param=-1, bool pc=true){
	  string[] ayrc=["(", ")"];
	  Command[] params = [];
	  Command[] temps = [];
	  bool kama=false;//kama bekleniyor mu?
	  Command item;
	  while (self._isTrue()){
		  item = self._getIt();
		  string itype = item.type;
		  if (mod==0 && itype=="SYMBOL" && item.value == ayrc[0]){
			  mod=1;
		  }else if (mod==1 && itype=="SYMBOL" && item.value == ayrc[1]){
			  mod=-1;
			  if(temps!=[]){
				  if(pc==true && temps[0].type == "equalIt") params ~= self.yard(temps);
				  else params ~= self.yard(temps);
				  temps=[];
			  }
			  break;
		  }else if (mod==1){
			  item = self.getIt(item);
			  itype = item.type;
			  if(itype=="SYMBOL" && item.value==","){
				  kama=false;
				  if (temps.length==0) self.throwError(1022);
				  else if(pc && temps[0].type == "WORD") params ~= self.yard(temps);
				  else params ~= self.yard(temps);
				  temps=[];
			  }else if(item.typ > 0){
				  temps ~= item;
				  kama = true;
			  }else if(itype == "NEWLINE"){
			  }else{
				  self.throwError(1001, itype);
			  }
		  }else{
			  self.i--;
			  break;
		  }
	  }
	  if (mod == 0) return null;
	  else if(mod != -1) self.throwError(1019);
	  if(pc){
		  Command[] test2;
		  if (fs.getParacodes(test2)) params ~= new RhCodeArea(test2);
	  }
	  return new callIt(params);
  }
/*  Command subReqs(){
	  Command test;
	  Command[] subs = [];
	  int last;
	  while(last != self.i){
		  last =self.i;
		  test = getBrackets();
		  if (test!=false) subs ~= Variant(["type":Variant("getIndex"), "levels":Variant(test)]);
		  test = getSubFunction();
		  if (test!=false) subs ~= Variant(["type":Variant("getSubFunction"), "name":Variant(test)]);
		  test = getParams();
		  if (test!=false) subs ~= Variant(["type":Variant("getParams"), "value":Variant(test)]);
	  }
	  return new locSub(subs);
  }
*/
}