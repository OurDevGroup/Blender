import xml.sax
import csv
import sys

class XmlHandler ( xml.sax.ContentHandler):
    tree = []
    assignments = []

    def __init__( self):
        xml.sax.ContentHandler.__init__(self)

    def startElement ( self, name, attrs):   
        if name == "category-assignment":
            assignment = {}
            assignment["category-id"] = unicode(attrs.get("category-id")).encode('utf-8')
            assignment["product-id"] = unicode(attrs.get("product-id")).encode('utf-8')
            self.assignments.append(assignment)
        
        self.tree.append(name)
        return
    
    def endElement ( self, name):        
        return

    def characters ( self, data):
        return

if len(sys.argv) < 2:
    print "You're doing it wrong!  You need to include the path to a DW catalog XML file."
    sys.exit()

filename = sys.argv[1]
outputfile = sys.argv[2] if len(sys.argv) == 3 else None
handler = XmlHandler()
xml.sax.parse (filename, handler)
with open((outputfile if outputfile != None else 'assignments.csv'), 'w') as csvfile:
    fieldnames = set([])
    for a in handler.assignments:
        for key in a:
            fieldnames.add(key)

    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
    writer.writeheader()
    for a in handler.assignments:
        writer.writerow(a)

print "Done."