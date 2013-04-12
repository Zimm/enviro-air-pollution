#import <Foundation/Foundation.h>
#import "TFHpple.h"

@interface EmissionSource : NSObject {
}
@property (nonatomic, retain) NSString *address;
@property (nonatomic, retain) NSString *company;
@property (nonatomic, retain) NSString *emissionType;
@property (nonatomic, retain) NSString *issueDate;
@property (nonatomic, retain) NSString *expDate;
@property (nonatomic, retain) NSString *versionType;
@property (nonatomic, retain) NSString *sourceCat;
@property (nonatomic, retain) NSString *pdfLink;
@property (nonatomic, retain) NSString *geocodedAddress;
@end

@implementation EmissionSource
@synthesize address, company, emissionType, issueDate, expDate, versionType, sourceCat, pdfLink, geocodedAddress;
- (id)description {
    return [NSString stringWithFormat:@"<%p> [%@ address=%@ company=%@ emissionType=%@ issueDate=%@ expDate=%@ versionType=%@ sourceCat=%@ pdfLink=%@]", self, NSStringFromClass([self class]), self.address, self.company, self.emissionType, self.issueDate, self.expDate, self.versionType, self.sourceCat, self.pdfLink];
}
@end

@interface Table : NSObject {
    NSMutableArray *_rows;
}
@property (nonatomic, readonly) NSMutableArray *rows;
@end
@interface Row : NSObject {
    NSMutableArray *_columns;
}
@property (nonatomic, readonly) NSMutableArray *columns;
@end
@interface Column : NSObject {
    NSString *_text;
}
@property (nonatomic, retain) NSString *text;
@end
@implementation Table
@synthesize rows = _rows;
- (id)init {
    if ((self = [super init]) != nil) {
        _rows = [[NSMutableArray alloc] init];
    }
    return self;
}
- (void)dealloc {
    [_rows release];
    _rows = nil;
    [super dealloc];
}
@end
@implementation Row
@synthesize columns = _columns;
- (id)init {
    if ((self = [super init]) != nil) {
        _columns = [[NSMutableArray alloc] init];
    }
    return self;
}
- (void)dealloc {
    [_columns release];
    _columns = nil;
    [super dealloc];
}
@end
@implementation Column
@synthesize text = _text;
@end

NSString *recursiveFindText_internal(TFHppleElement *e, int log) {
    TFHppleElement *current = e;
    while (current.text.length == 0) {
        if (current.children.count)
            current = [current.children objectAtIndex:0];
        else
            break;
    }
    return current.text;
}


NSString *recursiveFindText(TFHppleElement *e) {
    return recursiveFindText_internal(e, 0);
}

TFHppleElement *recursiveFindTag(TFHppleElement *e, NSString *teg, NSString *supernode) {
    TFHppleElement *current = e;
    while (current && ![[current tagName] isEqualToString:teg]) {
        if ([current hasChildren]) {
            if (supernode) {
                current = [current firstChildWithTagName:supernode] ?: [current.children objectAtIndex:0];
            } else
                current = [current.children objectAtIndex:0];
        } else
            return NULL;
    }
    return current;
}

NSString *escape(NSString *in) {
    return [in stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
}

NSString *URLescape(NSString *in) {
    return (NSString *)CFURLCreateStringByAddingPercentEscapes(
    NULL,
   (CFStringRef)in,
    NULL,
    CFSTR("!*'();:@&=+$,/?%#[]"),
    kCFStringEncodingUTF8);
}

int main(int argc, char *argv[]) {
    NSAutoreleasePool *bigpool = [[NSAutoreleasePool alloc] init];
    NSError *err = NULL;
    NSString *dd = [[NSString alloc] initWithContentsOfFile:@"/Users/Dan/Dropbox/PersonalDev/enviro/la2.html" encoding:NSUTF8StringEncoding error:&err];
    TFHpple *h = [[TFHpple hppleWithHTMLData:[dd dataUsingEncoding:NSUTF8StringEncoding]] retain];
    NSArray *arr = [h searchWithXPathQuery:@"//tr//td//b//font//a"];
    NSMutableArray *emissionSources = [NSMutableArray array];
    if (arr) {
        for (int i = 0;i < [arr count]; i++) {
            TFHppleElement *elem = [arr objectAtIndex:i];
            NSLog(@"%@", [elem text]);
            EmissionSource *es = [[EmissionSource alloc] init];
            [emissionSources addObject:es];
            NSData *d = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://yosemite.epa.gov%@",[[elem attributes] objectForKey:@"href"]]]];
            TFHpple *subdoc = [[TFHpple hppleWithHTMLData:d] retain];
            NSArray *tables = [subdoc searchWithXPathQuery:@"/html/body//table"];
            NSMutableArray *tableObjects = [[NSMutableArray alloc] initWithCapacity:[tables count]];
            for (int j=0;j<[tables count];j++) {
                TFHppleElement *tab = [tables objectAtIndex:j];
                Table *t = [[Table alloc] init];
                [tableObjects addObject:t];
                NSArray *rows = [tab children];
                for(int k=0;k<[rows count];k++) {
                    TFHppleElement *rowelem = [rows objectAtIndex:k];
                    NSArray *columns = [rowelem childrenWithTagName:@"td"];
                    Row *arow = [[Row alloc] init];
                    [t.rows addObject:arow];
                    if ([columns count] == 2) {
                        NSString *txt = [recursiveFindText([columns objectAtIndex:0]) lowercaseString];
                        if ([txt rangeOfString:@"facility name:"].location != NSNotFound) {
                            es.company = recursiveFindText([columns objectAtIndex:1]);
                        } else if ([txt rangeOfString:@"address:"].location != NSNotFound) {
                            TFHppleElement *tmp = recursiveFindTag([columns objectAtIndex:1], @"font", @"b");
                            es.address = tmp.text;
                        } else if ([txt rangeOfString:@"city, state, zip:"].location != NSNotFound) {
                            NSError *terr = NULL;
                            NSArray *bchilds = [[columns objectAtIndex:1] childrenWithTagName:@"b"];
                            NSString *adder = [NSString stringWithFormat:@" %@%@%@", [[[bchilds objectAtIndex:0] firstChildWithTagName:@"font"] text], [[[bchilds objectAtIndex:1] firstChildWithTagName:@"font"] text], [[[bchilds objectAtIndex:2] firstChildWithTagName:@"font"] text]];
                            es.address = [es.address?:@"" stringByAppendingString:adder];
                            NSString *geodata = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.datasciencetoolkit.org/maps/api/geocode/json?address=%@&sensor=false", URLescape(es.address)]] encoding:NSUTF8StringEncoding error:&terr];
                            // NSLog(@"Got geodata: %@", geodata);
                            if ([geodata rangeOfString:@"<h1>"].location == NSNotFound)
                                es.geocodedAddress = geodata;
                            else {
                                es.geocodedAddress = "{}";
                            }
                            [geodata release];
                        } else if ([txt rangeOfString:@"source category:"].location != NSNotFound) {
                            TFHppleElement *tmp = [[[columns objectAtIndex:1] firstChildWithTagName:@"b"] firstChildWithTagName:@"font"];
                            es.sourceCat = tmp.text;
                        }
                    } else if ([columns count] == 4) {
                        NSString *txt = [recursiveFindText([columns objectAtIndex:0]) lowercaseString];
                        if ([txt rangeOfString:@"version type:"].location != NSNotFound) {
                            es.versionType = recursiveFindText([columns objectAtIndex:1]);
                        } else if ([txt rangeOfString:@"final permit issued date:"].location != NSNotFound) {
                            //NSError *terr = NULL;
                            es.issueDate = recursiveFindText([columns objectAtIndex:1]);
                            TFHppleElement *pdfa = recursiveFindTag([columns objectAtIndex:2], @"a", NULL);
                            es.pdfLink = [[pdfa attributes] objectForKey:@"href"];
                            /*
                            NSData *pdfd = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://yosemite.epa.gov%@", es.pdfLink]]];
                            [pdfd writeToFile:@"_tmp_pdf.pdf" atomically:YES];
                            system("pdftotext _tmp_pdf.pdf _tmp_txt.txt");
                            NSString *txtd = [[NSString alloc] initWithContentsOfFile:@"_tmp_txt.txt" encoding:NSASCIIStringEncoding error:&terr];
                            if (terr)
                                NSLog(@"Err reading pdf %@", terr);
                            NSRange r511 = [txtd rangeOfString:@"5.1.1"];
                            NSLog(@"Found 511: %@", NSStringFromRange(r511));
                            NSLog(@"NSNotFound is %ld", NSNotFound);
                            NSRange r52 = [txtd rangeOfString:@"5.2" options:0 range:NSMakeRange(r511.location, [txtd length] - r511.location)];
                            NSString *sub511 = [txtd substringWithRange:NSMakeRange(r511.location, r52.location - r511.location)];
                            NSLog(@"Found goodies: %@", sub511);
                            [pdfd release];
                            [txtd release];
                            */
                        } else if ([txt rangeOfString:@"permit expiration date:"].location != NSNotFound) {
                            es.expDate = recursiveFindText([columns objectAtIndex:1]);
                        }
                    }
                }
            }
            // NSLog(@"Found emission source: %@", es);
        }
    }
    NSLog(@"\t\tSaving data...");
    NSMutableString *result = [[NSMutableString alloc] initWithString:@""];
    [result appendString:
        @"var EPASource = function(addr, comp, emt, idat, exdat, vtype, scat, plink, gdata) { this.address = addr; this.company = comp; this.emissionType = emt; this.issueDate = idat; this.expDate = exdat; this.versionType = vtype; this.sourceCat = scat; this.pdfLink = plink; this.geocodedAddress = gdata; };\nvar sources = [];\n"
        ];
    for (EmissionSource *es in emissionSources) {
        [result appendFormat:@"sources.push( new EPASource( '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', %@ ) );\n", escape(es.address), escape(es.company), escape(es.emissionType), escape(es.issueDate), escape(es.expDate), escape(es.versionType), escape(es.sourceCat), escape(es.pdfLink), escape(es.geocodedAddress)];
    }
    NSError *aerr = NULL;
    [result writeToFile:@"website/databank.js" atomically:YES encoding:NSUTF8StringEncoding error:&aerr];
    if (aerr) {
        NSLog(@"Failed to save D:");
    }
    NSLog(@"Done!");
    [result release];
    [h release];
    [dd release];
    [bigpool drain];
	return 0;
}

