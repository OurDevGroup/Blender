import xml.sax
import csv

class XmlHandler ( xml.sax.ContentHandler):
    tree = []
    product = {}
    products = []
    value = None
    lang = None
    custAttr = None

    def __init__( self):
        xml.sax.ContentHandler.__init__(self)

    def startElement ( self, name, attrs):   
        self.value = None
        self.lang = None
        self.custAttr = None
        if self.isInCatalog() and name == "product":
            self.product = {}
            for n in attrs.keys():
                self.product[n] = attrs.get(n)
        
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

    def isInCatalog (self):
        return len(self.tree) > 0 and self.tree[len(self.tree)-1] == "catalog" 
       

filename = "miniCatalog.xml"
handler = XmlHandler()
xml.sax.parse (filename, handler)
with open('products.csv', 'w') as csvfile:
    fieldnames = set([])
    for p in handler.products:
        for key in p:
            fieldnames.add(key)
        
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
    writer.writeheader()
    for p in handler.products:
        writer.writerow(p)
