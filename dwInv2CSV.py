import xml.sax
import csv
import sys

class XmlHandler ( xml.sax.ContentHandler):
    tree = []
    inv = {}
    invs = []
    value = None
    custAttr = None
    Inventory = None
    online = None
    lang = None

    def __init__( self):
        xml.sax.ContentHandler.__init__(self)

    def startElement ( self, name, attrs):   
        self.value = None
        self.lang = None
        self.custAttr = None
        if self.isInInventory() and name == "inventory":
            self.inv = {}
            self.invs = []
            self.Inventory = None
            
        if name == 'record':
            self.inv = {}
            self.inv['online'] = self.online
            self.inv['product-id'] = attrs.get('product-id')

        if name == 'header':
            self.Inventory = attrs.get('list-id')
                    
        if self.isInRecord():
            for n in attrs.keys():
                self.inv[n] = unicode(attrs.get(n)).encode('utf-8')       

        if attrs.get("xml:lang") != 'x-default':
            self.lang = attrs.get("xml:lang")  
        self.tree.append(name)
        if self.isCustomAttr():
            self.custAttr = attrs.get("attribute-id")
        return

    def endElement ( self, name):        
        if self.getValue() != None and self.tree[len(self.tree)-2] == "record":  
            self.inv[name + ('-' + self.lang if self.lang != None else '')] = self.getValue()
        
        if self.getValue() != None and self.isCustomAttr() and self.custAttr != None and self.tree[len(self.tree)-3] == "record":
            self.inv['custom-' + self.custAttr] = self.getValue()

        if self.isInHeader() and name == 'currency' and self.getValue() != None:
            self.currency = self.getValue()

        if self.isInHeader() and name == 'online-flag' and self.getValue() != None:
            self.online = self.getValue()

        if self.isInRecord() and name == 'record':
            self.invs.append(self.inv)

        if name == 'inventory-list':
            with open(((self.Inventory + '.csv') if self.Inventory != None else 'inventory.csv'), 'w') as csvfile:
                fieldnames = set([])
                for p in handler.invs:
                    for key in p:
                        fieldnames.add(key)

                writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
                writer.writeheader()
                for p in handler.invs:
                    writer.writerow(p)

        self.value = None
        self.tree.pop()
        return

    def characters ( self, data):
        self.value = (self.value + data) if self.value != None else data
        return

    def getValue(self):
        if self.value != None and self.value.strip() != '':
             return unicode(self.value.strip()).encode("utf-8")
        else:
            return None

    def isInHeader (self):
        return len(self.tree) > 2 and (self.tree[len(self.tree)-1] == "header" or self.tree[len(self.tree)-2] == "header")

    def isInRecord (self):
        return len(self.tree) > 2 and (self.tree[len(self.tree)-1] == "record" or self.tree[len(self.tree)-2] == "record")

    def isInInventory (self):
        return len(self.tree) > 2 and (self.tree[len(self.tree)-1] == "inventory" or self.tree[len(self.tree)-2] == "inventory")

    def isCustomAttr (self):
        return len(self.tree) > 3 and self.tree[len(self.tree)-2] == "custom-attributes"         

if len(sys.argv) < 2:
    print "You're doing it wrong!  You need to include the path to a DW Inventory XML file."
    sys.exit()

filename = sys.argv[1]
handler = XmlHandler()
xml.sax.parse (filename, handler)
print "Done."