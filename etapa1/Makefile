CC = gcc
TARGET = out/algorithm

SRCS = algorithm.c
OBJS = obj/algorithm.o

# Default
algorithm: $(TARGET);

$(TARGET): $(OBJS)
	@mkdir -p out/
	$(CC) $(OBJS) -o $(TARGET)

obj/%.o: ./%.c
	@mkdir -p obj/
	$(CC) -c $< -o $@

clean:
	rm -rf out/ obj/
