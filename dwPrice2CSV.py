import xml.sax
import csv
import sys

class XmlHandler ( xml.sax.ContentHandler):
    tree = []
    price = {}
    prices = []
    value = None
    custAttr = None
    pricebook = None
    currency = None
    online = None
    lang = None

    def __init__( self):
        xml.sax.ContentHandler.__init__(self)

    def startElement ( self, name, attrs):   
        self.value = None
        self.lang = None
        self.custAttr = None
        if self.isInPricebooks() and name == "pricebook":
            self.price = {}
            self.prices = []
            self.pricebook = None
            
        if name == 'price-table':
            self.price = {}
            self.price['currency'] = self.currency
            self.price['online'] = self.online
            self.price['product-id'] = attrs.get('product-id')

        if name == 'header' and len(self.tree) == 2 and self.tree[len(self.tree)-1] == 'pricebook':
            self.pricebook = attrs.get('pricebook-id')
                    
        if self.isInPriceTable():
            for n in attrs.keys():
                self.price[n] = unicode(attrs.get(n)).encode('utf-8')       

        if attrs.get("xml:lang") != 'x-default':
            self.lang = attrs.get("xml:lang")  
        self.tree.append(name)
        if self.isCustomAttr():
            self.custAttr = attrs.get("attribute-id")
        return

    def endElement ( self, name):        
        if self.getValue() != None and self.tree[len(self.tree)-2] == "price-table":  
            self.price[name + ('-' + self.lang if self.lang != None else '')] = self.getValue()
        
        if self.getValue() != None and self.isCustomAttr() and self.custAttr != None and self.tree[len(self.tree)-3] == "price-table":
            self.price['custom-' + self.custAttr] = self.getValue()

        if self.isInHeader() and name == 'currency' and self.getValue() != None:
            self.currency = self.getValue()

        if self.isInHeader() and name == 'online-flag' and self.getValue() != None:
            self.online = self.getValue()

        if self.isInPriceTable() and name == 'price-table':
            self.prices.append(self.price)

        if name == 'pricebook':
            with open(((self.pricebook + '.csv') if self.pricebook != None else 'price.csv'), 'w') as csvfile:
                fieldnames = set([])
                for p in handler.prices:
                    for key in p:
                        fieldnames.add(key)

                writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
                writer.writeheader()
                for p in handler.prices:
                    writer.writerow(p)
            
            self.prices = []

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

    def isInPriceTable (self):
        return len(self.tree) > 2 and (self.tree[len(self.tree)-1] == "price-table" or self.tree[len(self.tree)-2] == "price-table")

    def isInPricebooks (self):
        return len(self.tree) > 2 and (self.tree[len(self.tree)-1] == "pricebooks" or self.tree[len(self.tree)-2] == "pricebooks")

    def isCustomAttr (self):
        return len(self.tree) > 3 and self.tree[len(self.tree)-2] == "custom-attributes"         

if len(sys.argv) < 2:
    print "You're doing it wrong!  You need to include the path to a DW pricebook XML file."
    sys.exit()

filename = sys.argv[1]
handler = XmlHandler()
xml.sax.parse (filename, handler)
print "Done."