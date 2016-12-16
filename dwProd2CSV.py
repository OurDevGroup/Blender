import xml.sax
import csv
import sys

class XmlHandler ( xml.sax.ContentHandler):
    tree = []
    product = {}
    variants = {}
    products = []
    value = None
    lang = None
    custAttr = None
    pid = None

    def __init__( self):
        xml.sax.ContentHandler.__init__(self)

    def startElement ( self, name, attrs):   
        self.value = None
        self.lang = None
        self.custAttr = None
        if self.isInCatalog() and name == "product":
            self.product = {}
            for n in attrs.keys():
                self.product[n] = unicode(attrs.get(n)).encode('utf-8')
        
        self.pid = unicode(attrs.get("product-id")).encode('utf-8')
        if attrs.get("xml:lang") != 'x-default':
            self.lang = attrs.get("xml:lang")
        self.tree.append(name)
        if self.isCustomAttr():
            self.custAttr = attrs.get("attribute-id")
        return

    def endElement ( self, name):        
        if self.value != None and self.value.strip() != '' and self.tree[len(self.tree)-2] == "product":  
                self.product[name + ('-' + self.lang if self.lang != None else '')] = unicode(self.value).encode("utf-8")
        
        if self.value != None and self.value.strip() != '' and self.isCustomAttr() and self.custAttr != None:
            self.product['custom-' + self.custAttr] = unicode(self.value).encode("utf-8")
        
        if self.value != None and self.value.strip() != '' and self.isPageAttr():
            self.product[name] = unicode(self.value).encode("utf-8")

        if (self.isInProduct() and name == 'product'):
            self.products.append(self.product)

        if self.isVariantDef() and self.pid != None and self.product["product-id"] != None:
            self.variants[self.pid] = self.product["product-id"]

        self.pid = None
        self.value = None
        self.tree.pop()
        return

    def characters ( self, data):
        self.value = (self.value + data) if self.value != None else data
        return

    def isPageAttr (self):
        return len(self.tree) > 2 and self.tree[len(self.tree)-3] == "product" and self.tree[len(self.tree)-2] == "page-attributes" 

    def isCustomAttr (self):
        return len(self.tree) > 2 and self.tree[len(self.tree)-3] == "product" and self.tree[len(self.tree)-2] == "custom-attributes" 

    def isInProduct (self):        
        isProd = len(self.tree) > 1 and self.tree[len(self.tree)-2] == "catalog" and self.tree[len(self.tree)-1] == "product"        
        return isProd 

    def isVariantDef(self):
        return len(self.tree) > 2 and self.tree[len(self.tree)-3] == "variations" and self.tree[len(self.tree)-2] == "variants" 

    def isInCatalog (self):
        return len(self.tree) > 0 and self.tree[len(self.tree)-1] == "catalog" 

if len(sys.argv) < 2:
    print "You're doing it wrong!  You need to include the path to a DW catalog XML file."
    sys.exit()

filename = sys.argv[1]
outputfile = sys.argv[2] if len(sys.argv) == 3 else None
handler = XmlHandler()
xml.sax.parse (filename, handler)
with open((outputfile if outputfile != None else 'products.csv'), 'w') as csvfile:
    fieldnames = set([])
    for p in handler.products:
        for key in p:
            fieldnames.add(key)

    fieldnames.add('parent-product-id')    
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
    writer.writeheader()
    for p in handler.products:
        if p['product-id'] in handler.variants:
            p['parent-product-id'] = handler.variants[p['product-id']]
        writer.writerow(p)

print "Done."