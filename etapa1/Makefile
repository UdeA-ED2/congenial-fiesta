CC = gcc
TARGET = bin/algorithm

SRCS = algorithm.c
OBJS = obj/algorithm.o

# Default
algorithm: $(TARGET)

$(TARGET): $(OBJS)
	@mkdir -p bin/
	$(CC) $(OBJS) -o $(TARGET)

obj/%.o: ./%.c
	@mkdir -p obj/
	$(CC) -c $< -o $@

clean:
	rm -rf bin/ obj/
