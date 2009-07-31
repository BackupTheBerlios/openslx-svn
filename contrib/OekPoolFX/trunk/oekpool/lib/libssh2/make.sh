g++ -c -ggdb -o test.o test.cpp
g++ -ggdb test.o ../libssh2.a -lcrypto -lz -ldl -lpthread -o test
#strip test
./test
