CC:=clang
ARCH:=x86-64
OBJECTS_EPA=epapuller.m.o
OBJECTS_HPPLE:=TFHpple.m.o TFHppleElement.m.o XPathQuery.m.o
HPPLE_DIR:=./hpple
LDFLAGS_HPPLE=-lxml2.2 -dynamiclib
LDFLAGS_EPA=-L./ -lhpple
LDFLAGS=-framework Foundation
CFLAGS=-Wall -Werror -march=$(ARCH) -include "include.h" -I/usr/include/libxml2 -iquote$(HPPLE_DIR)
CFLAGS_HPPLE=-fobjc-arc
CFLAGS_EPA=

all: epapuller
	
.PHONY: all

#.PHONY: libhpple

#.PHONY: epapuller

libhpple.dylib: $(addprefix $(HPPLE_DIR)/,$(OBJECTS_HPPLE))
	$(CC) $^ -o $@ $(CFLAGS) $(LDFLAGS) $(LDFLAGS_HPPLE)

epapuller: libhpple.dylib $(OBJECTS_EPA)
	$(CC) $(OBJECTS_EPA) -o $@ $(CFLAGS) $(LDFLAGS) $(LDFLAGS_EPA)

%.m.o: %.m
	$(CC) -c $< -o $@ $(CFLAGS)

.PHONY: clean

clean:
	rm -rf $(OBJECTS_EPA) epapuller
	rm -rf $(addprefix $(HPPLE_DIR)/,$(OBJECTS_HPPLE)) libhpple.dylib

