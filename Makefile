all: mod_webfw2 testfilter 

#APR_CONFIG   = /home/mthomas/sandbox/bin/apr-1-config
APR_CONFIG   =  /home/mthomas/sandboxes/sandbox-2.2.11/bin/apr-1-config
APR_INCLUDES = `$(APR_CONFIG) --includes`
APR_LIBS     = `$(APR_CONFIG) --libs`
APR_CFLAGS   = `$(APR_CONFIG) --cflags`
APR_LDFLAGS  = `$(APR_CONFIG) --ldflags`
APR_LINK     = `$(APR_CONFIG) --link-ld`
APXS_BIN     = /home/mthomas/sandboxes/sandbox-2.2.11/bin/apxs 

THRASHER     = -DWITH_THRASHER
DFLAGS       = -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 $(THRASHER)

libconfuse: 
	@if test -f confuse-2.5/src/libconfuse.la; then echo "[*] libconfuse already configured..."; else echo "[*] Configuring libconfuse..."; cd confuse-2.5 && ./configure CFLAGS=-fPIC --disable-nls 2>&1 >/dev/null; echo "[*] Making libconfuse";  make 2>&1 >/dev/null; fi

patricia.o: patricia.c 
	gcc $(DFLAGS) $(APR_INCLUDES) -c -o patricia.o patricia.c -ggdb -O0 

filter.o: filter.c 
	gcc $(DFLAGS) $(APR_INCLUDES) -I. -Iconfuse-2.5/src/ -c -o filter.o filter.c -ggdb -O0 

thrasher.o: thrasher.c thrasher.h
	gcc $(DFLAGS) $(APR_INCLUDES) -I. -c -o thrasher.o thrasher.c -ggdb -O0

callbacks.o:
	gcc $(DFLAGS) $(APR_INCLUDES) -I. -c -o callbacks.o callbacks.c -ggdb -O0

testfilter: testfilter.c filter.c filter.o patricia.o libconfuse archives
	gcc $(DFLAGS) -I. -L. $(APR_INCLUDES) $(APR_LIBS) -Iconfuse-2.5/src/ testfilter.c -o testfilter -lfilter -lapr-1 -ggdb -lpthread

filter: filter.c filter.o patricia.o libconfuse archives
	gcc  -DDEBUG -DTEST_FILTERCLOUD $(DFLAGS) -I. -L. $(APR_INCLUDES) $(APR_LIBS) -Iconfuse-2.5/src/ filter.c -o filter -lpatricia -lapr-1 -lconfuse -ggdb -O0
 
archives: filter.c patricia.c filter.o patricia.o libconfuse 
	ar rcs libfilter.a filter.o patricia.o confuse-2.5/src/lexer.o confuse-2.5/src/confuse.o 

mod_webfw2: filter.c mod_webfw2.c archives callbacks.o thrasher.o 
	${APXS_BIN} -c -I. $(DFLAGS) -Iconfuse-2.5/src/ -L. mod_webfw2.c callbacks.o thrasher.o -lfilter -ggdb -O0 2>&1 >/dev/null 
	${APXS_BIN} -i -a -n webfw2 mod_webfw2.la 2>&1 >/dev/null

distclean: clean
	cd confuse-2.5 && make distclean 2>&1 >/dev/null
	
clean:
	rm -rf *.o *.la *.slo *.lo *.a 
	rm -rf filter
	rm -rf testfilter
	rm -rf ./.libs/

scons:
	CFLAGS=-I../pchad-libs/confuse/src LDFLAGS=-L../pchad-libs/confuse/src/.libs scons
