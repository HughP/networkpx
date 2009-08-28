#!/opt/local/bin/python3.0
#
# appids.py ... Obtain bundle IDs for AppStore apps
# 
# Copyright (C) 2009  KennyTM~
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

from urllib.request import Request, urlopen;
from urllib.parse import quote;
import sys;
import re;
from xml.dom.minidom import parseString, Element;

if len(sys.argv) < 2:
	print('Usage: appids.py <search-term>\n');
else:
	# Pretend to be iTunes and search for the specified search term.
	req = Request('http://ax.search.itunes.apple.com/WebObjects/MZSearch.woa/wa/search?submit=edit&term=' + quote(sys.argv[1]));
	req.add_header('User-agent', 'iTunes/8.2.1 (Macintosh; Intel Mac OS X 10.5.8)');
	
	# The result should be an XML file. Eliminate white-space-only text nodes to make parsing easier.
	xml = re.compile(b'>\\s+<').sub(b'><', urlopen(req).read());
	dom = parseString(xml);
	
	# Analyze the property list object from the "track list", which contains the bundle IDs.
	plist = dom.getElementsByTagName('TrackList')[0].getElementsByTagName('plist')[0];
	
	items = [n.nextSibling for n in plist.getElementsByTagName('key') if n.firstChild.data == 'items'][0];
	assert(items.tagName == 'array');
	
	for dict in items.childNodes:
		content = {n.firstChild.data: n.nextSibling.firstChild.data for n in dict.getElementsByTagName('key') if n.firstChild.data in frozenset(('itemName', 'softwareVersionBundleId', 'url'))};
		if 'softwareVersionBundleId' in content:
			print('{0:40} {1:20} :: {2}'.format(content['softwareVersionBundleId'], content['itemName'], content['url']));
	
	dom.unlink();
