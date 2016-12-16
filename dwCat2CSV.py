import xml.sax
import csv
import sys

class XmlHandler ( xml.sax.ContentHandler):
    tree = []
    category = {}
    categories = []
    value = None
    lang = None
    custAttr = None
    cid = None

    def __init__( self):
        xml.sax.ContentHandler.__init__(self)

    def startElement ( self, name, attrs):   
        self.value = None
        self.lang = None
        self.custAttr = None
        if self.isInCatalog() and name == "category":
            self.category = {}
            for n in attrs.keys():
                self.category[n] = unicode(attrs.get(n)).encode('utf-8')
        
        self.cid = unicode(attrs.get("category-id")).encode('utf-8')
        if attrs.get("xml:lang") != 'x-default':
            self.lang = attrs.get("xml:lang")
        self.tree.append(name)
        if self.isCustomAttr():
            self.custAttr = attrs.get("attribute-id")
        return

    def endElement ( self, name):        
        if self.value != None and self.value.strip() != '' and self.tree[len(self.tree)-2] == "category":  
                self.category[name + ('-' + self.lang if self.lang != None else '')] = unicode(self.value).encode("utf-8")
        
        if self.value != None and self.value.strip() != '' and self.isCustomAttr() and self.custAttr != None:
            self.category['custom-' + self.custAttr] = unicode(self.value).encode("utf-8")

        if len(self.tree) > 1 and self.tree[len(self.tree)-2] == "catalog" and self.tree[len(self.tree)-1] == "category" :
            self.categories.append(self.category)

        self.cid = None
        self.value = None
        self.tree.pop()
        return

    def characters ( self, data):
        self.value = (self.value + data) if self.value != None else data
        return

    def isInCategory (self):
        return len(self.tree) > 2 and self.tree[len(self.tree)-3] == "catalog" and self.tree[len(self.tree)-2] == "category" 

    def isInCatalog (self):
        return len(self.tree) > 0 and self.tree[len(self.tree)-1] == "catalog" 

    def isCustomAttr (self):
        return len(self.tree) > 2 and self.tree[len(self.tree)-3] == "category" and self.tree[len(self.tree)-2] == "custom-attributes"         

if len(sys.argv) < 2:
    print "You're doing it wrong!  You need to include the path to a DW catalog XML file."
    sys.exit()

filename = sys.argv[1]
outputfile = sys.argv[2] if len(sys.argv) == 3 else None
handler = XmlHandler()
xml.sax.parse (filename, handler)
with open((outputfile if outputfile != None else 'categories.csv'), 'w') as csvfile:
    fieldnames = set([])
    for c in handler.categories:
        for key in c:
            fieldnames.add(key)

    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
    writer.writeheader()
    for c in handler.categories:
        writer.writerow(c)

print "Done."