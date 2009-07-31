

#include <iostream>
#include <string>
#include <vector>

#include "include/libssh2.h"

#include <arpa/inet.h>

#include <pthread.h>
#include <signal.h>
#include <time.h>
#include <stdlib.h>

using namespace std;

pair<void*,time_t> timeCheck;
pthread_mutex_t timermutex;
pthread_t timerThread;

struct timerArgs {
    void* client;
    time_t timeout;
} globTimer;

void* timer_main(void* argp) {
    timerArgs* ta = (timerArgs*) argp;
    time_t now;
    while(true) {
        pthread_mutex_lock(&timermutex);
        if(timeCheck.first == ta->client) {
            time(&now);
            if((now - timeCheck.second) > ta->timeout) {
                cerr << "Detected timeout!" << endl;
                exit(1);
            }
            else {
                cerr << "Not timeout detected! Waiting" << endl;
            }
        }
        pthread_mutex_unlock(&timermutex);
        sleep(1);
    }
}


void set_next_time(void* argp) {
    pthread_mutex_lock(&timermutex);
    timeCheck.first = argp;
    time(&(timeCheck.second));
    pthread_mutex_unlock(&timermutex);
}

void timer_start(void* argp) {
    globTimer.client = argp;
    globTimer.timeout = 5;
    pthread_create(&timerThread, NULL,timer_main,&globTimer);
}

void timer_stop(void* argp) {
    int ret = pthread_kill(timerThread, SIGTERM);
    if(!ret) {
        cerr << "Could not kill timer process!" << endl;
//        exit(1);
    }
}

int main(int argc, char* argv[]) {
    int MAX_LENGTH = 255;
    char buf[MAX_LENGTH];

    string username = "root";
    string password = "2009..p00l";


    pthread_mutex_init(&timermutex,NULL);

    unsigned long hostaddr = inet_addr("132.230.4.26");

    int i, auth_pw = 0, sock = 0, retval = 0, error = 0, bsize= 1;
    string output;

    sock = socket(AF_INET, SOCK_STREAM, 0);
    struct sockaddr_in sin;
    const char *fingerprint;
    char *userauthlist;

    LIBSSH2_SESSION *session;
    LIBSSH2_CHANNEL *channel;

    sin.sin_family = AF_INET;
    sin.sin_port = htons(22);
    sin.sin_addr.s_addr = hostaddr;

    if(connect(sock, (const sockaddr*)&sin,sizeof(struct sockaddr_in)) != 0) {
        cout << "Could not connect!" << endl;
        return 1;
    }

    set_next_time(NULL);
    timer_start(NULL);
    session = libssh2_session_init();
    timer_stop(NULL);

    cout << "session_startup(session,sock)\n";
    set_next_time(NULL);
    timer_start(NULL);
    if(libssh2_session_startup(session,sock)) {
        cout << "Failure establishing SSH session" << endl;
        return 1;
    }

    cout << "session_userauth_list(session,username)\n";
    set_next_time(NULL);
    userauthlist = libssh2_userauth_list(session, username.c_str(), username.size());
    cout << "Authentication methods:" << userauthlist << endl;

    if(strstr(userauthlist, "password") != NULL) {
        cout << "session_userauth_password(session,username,password)\n";
        set_next_time(NULL);
        if(libssh2_userauth_password(session, username.c_str(), password.c_str())) {
            cout << "Authentication by password failed! Probably wrong password!" << endl;
            return 1;
        }
        else {
            cout << "Authentication by password succeeded!" << endl;
        }
    }

    
    while(true) {
        cout << "channel_open_session(session)\n";
        set_next_time(NULL);
        channel = libssh2_channel_open_session(session);
        if(!channel) {
            cout << "Could not open channel!" << endl;
            break;
        }

        cout << "Running command 'ls -ahl ~'" << endl;
        string cmd = "ls -ahl ~";
        cout << "channel_exec(channel, cmd)\n";
        set_next_time(NULL);
        retval = libssh2_channel_exec(channel, cmd.c_str() );
        if(retval == -1) {
            set_next_time(NULL);
            error = libssh2_session_last_error(session,0,0,0);
            switch(error) {
            case LIBSSH2_ERROR_SOCKET_SEND:
                cout << "Could not send command!" << endl;
                break;
            case LIBSSH2_ERROR_ALLOC:
                cout << "Some memory problem!" << endl;
                break;
            default:
                cout << "Some unknown error occurred running the SSH command!" << endl;
                cout << "Error code is " << error << endl;
                break;
            }
            break; // while
        }

        cout << "channel_read(channel, buf, MAX_LENGTH)\n";
        set_next_time(NULL);
        bsize = libssh2_channel_read(channel, buf, MAX_LENGTH);
        while( bsize != 0 ) {
            if(bsize < 0) {
                cout << "ERROR running command!" << endl;
                return 1;
            }
            cout << string(buf,bsize);
            cout << "channel_read(channel, buf, MAX_LENGTH)\n";
            set_next_time(NULL);
            bsize = libssh2_channel_read(channel, buf, MAX_LENGTH);
        }
        cout << endl;

        cout << "channel_close(channel)\n";
        set_next_time(NULL);
        libssh2_channel_close(channel);
        cout << "channel_wait_closed(channel)\n";
        set_next_time(NULL);
        if(!libssh2_channel_wait_closed(channel)) {
            cout << "channel_free(channel)\n";
            set_next_time(NULL);
            libssh2_channel_free(channel);
            channel = NULL;

        }
        sleep(2);
    }


    cout << "session_disconnect(session,msg)\n";
            set_next_time(NULL);
    libssh2_session_disconnect(session, "Normal Shutdown - CU");
    cout << "session_free(session)\n";
            set_next_time(NULL);
    libssh2_session_free(session);
    sleep(1);
    close(sock);
}
