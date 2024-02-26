#include <unistd.h>
#include <time.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/syslimits.h>
#include <sys/event.h>
#include <mach-o/dyld.h>

#define TIMEOUT 10

char *get_shell() {
    uid_t uid = getuid();
    switch (getuid()) {
        #include "mappings"
        default: return "/bin/zsh";
    }
}

#define CHECK(cond) if ((cond) != 0) { return __LINE__; }

int main(int argc, char **argv) {
    char buf[PATH_MAX];
    uint32_t size = sizeof(buf);
    CHECK(_NSGetExecutablePath(buf, &size));

    struct stat st;
    CHECK(stat(buf, &st));
    if (st.st_uid != 0 || (st.st_mode & 0777) != 0755) {
        return __LINE__;
    }

    char *shell = get_shell();

    struct timespec start, now;
    if (access(shell, R_OK) != 0) {
        int kq = kqueue();
        clock_gettime(CLOCK_MONOTONIC, &start);
        struct kevent kev = {
            .ident = 0,
            .filter = EVFILT_FS,
            .flags = EV_ADD,
            .fflags = 0,
            .data = 0,
            .udata = 0,
        };
        if (kevent(kq, &kev, 1, NULL, 0, NULL) != 0) {
            return __LINE__;
        }
        do {
            switch (errno) {
                case ENOENT:
                case ENOTDIR:
                    clock_gettime(CLOCK_MONOTONIC, &now);
                    if (now.tv_sec - start.tv_sec > TIMEOUT) {
                        return __LINE__;
                    }
                    kevent(kq, NULL, 0, &kev, 1, NULL);
                    continue;
                default: return errno;
            }
        } while (access(shell, R_OK) != 0);
        close(kq);
    }

    argv[0] = shell;
    return execv(shell, argv);
}