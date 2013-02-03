/*
Rhodeus Script (c) by Talha Zekeriya Durmuş

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/

module pool;

class pool{
	static string html;
	uint line = 1;
	uint linetmp;
	int delegate() getLine = &_getLine;
}