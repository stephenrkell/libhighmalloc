default: libhighmalloc.so libhighmalloc.a

THIS_MAKEFILE ?= $(lastword $(MAKEFILE_LIST))

CFLAGS += -g 
CFLAGS += -Wall -Wno-unused-label -Wno-comment
CFLAGS += -O3
CFLAGS += -fPIC
CFLAGS += -ffreestanding

C_SRC := $(wildcard *.c) 

C_DEPS := $(patsubst %.c,.%.d,$(C_SRC))

DEPS := $(C_DEPS) $(CC_DEPS)
OBJS := $(patsubst %.c,%.o,$(C_SRC))

$(C_DEPS): .%.d: %.c
	$(CC) -MM $(CFLAGS) $+ > "$@" || rm -f "$@"

ifneq ($(MAKECMDGOALS),clean)
-include $(DEPS)
endif

# disable sbrk() in dlmalloc
dlmalloc.o: CFLAGS += -O3 -DHAVE_MORECORE=0
# We put dlmalloc in a library so that clients can build a .so that uses it for 
# its private malloc without overriding global malloc. Linking 
# --exclude-libs=ALL will hide its symbols in our output .so, so that they 
# don't override anything in the rest of the program.
libhighmalloc.a: dlmalloc.o
	$(AR) r "$@" $^
libhighmalloc.so: dlmalloc.o
	$(CC) -shared -o "$@" "$<" $(LDFLAGS)

.PHONY: clean
clean:
	rm -f *.so
	rm -f *.a
	rm -f *.o
	rm -f .*.d
