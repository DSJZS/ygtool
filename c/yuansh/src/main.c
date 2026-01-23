#include <stdio.h>
#include <stdlib.h> 
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <string.h>
#include <signal.h>
#include <errno.h>
#include "shell_config.h"
#include "jobs.h"
#include "csapp.h"

void eval(char* cmdline);
int parseline(char* buf, char** argv);
int builtin_command(char** argv);
int parse_id(char* s);

void sigchld_handler(int sig);
void sigint_handler(int sig);
void sigtstp_handler(int sig);

int main() {
    char cmdline[MAX_LINE];

    if( signal(SIGCHLD, sigchld_handler) == SIG_ERR ) {
        perror("signal error\n");
        exit(1);
    }
    if( signal(SIGINT, sigint_handler) == SIG_ERR ) {
        perror("signal error\n");
        exit(1);
    }
    if( signal(SIGTSTP, sigtstp_handler) == SIG_ERR ) {
        perror("signal error\n");
        exit(1);
    }

    while (1) {
        printf("> ");
        fgets(cmdline, sizeof(cmdline), stdin);
        if (feof(stdin))
            exit(0);
        eval(cmdline);
    }
    return 0;
}

void eval(char* cmdline)
{
    char* argv[MAX_ARGS];
    char buf[MAX_LINE];
    int bg;
    pid_t pid;

    extern char **environ;

    strcpy(buf, cmdline);
    bg = parseline(buf, argv);
    if (argv[0] == NULL)
        return;

    if (!builtin_command(argv)) {
        /* 为了防止并发问题，这里要阻塞SIGCHLD信号，至少要到 job 被记录为止 */
        sigset_t mask_one, prev_one;
        sigemptyset(&mask_one);
        sigaddset(&mask_one, SIGCHLD);

        /* block signal child */
        sigprocmask(SIG_BLOCK, &mask_one, &prev_one);
        if ((pid = fork()) == 0) {
            /* unblock in child process */
            sigprocmask(SIG_SETMASK, &prev_one, NULL);
            /* 设置组ID与PID一致 */
            setpgid(0, 0);

            if (execve(argv[0], argv, environ)) {
                printf("%s: Command not found\n", argv[0]);
                exit(0);
            }
        }

        sigset_t mask_all, prev_all;
        sigfillset(&mask_all);
        // save job info
        sigprocmask(SIG_BLOCK, &mask_all, &prev_all);
        jid_t new_jid = jobs_add_job(pid, bg ? JOB_BG : JOB_FG, cmdline);
        sigprocmask(SIG_SETMASK, &prev_all, NULL);

        // Parent process
        if (!bg) {
            jobs_set_fg_pid(pid);
            while(jobs_get_fg_pid())
                sigsuspend(&prev_one);
        } else {
            // cmdline 以 \n\0 结尾，故这里不需要再加 \n
            printf("[%d] %d %s \t %s", new_jid, pid, "Running", cmdline);
        }

        /* unblock child signal */
        sigprocmask(SIG_SETMASK, &prev_one, NULL);
    }
}

int builtin_command(char** argv)
{
    if (strcmp(argv[0], "quit") == 0) {
        exit(0);
    } else if (strcmp(argv[0], "&") == 0) {
        return 1; // Ignore singleton &
    } else if (strcmp(argv[0], "jobs") == 0) {
        jobs_list();
        return 1;
    } else if (strcmp(argv[0], "bg") == 0) {
        int id = 0;
        if ((id = parse_id(argv[1])) != -1 && argv[2] == NULL) {
            pid_t pid = id;
            if(argv[1][0] == '%') {
                // jid
                pid = jobs_get_pid_by_jid(id);
            }
            if(pid != 0) {
                kill(pid, SIGCONT);
            } else {
                printf("No such job\n");
            }
        }
        return 1;
    } else if (strcmp(argv[0], "fg") == 0) {
        int id = 0;
        if ((id = parse_id(argv[1])) != -1 && argv[2] == NULL) {
            pid_t pid = id;
            if(argv[1][0] == '%') {
                // jid
                pid = jobs_get_pid_by_jid(id);
            }
            if(pid != 0) {
                sigset_t mask_one, prev_one;
                sigemptyset(&mask_one);
                sigaddset(&mask_one, SIGCHLD);
                sigprocmask(SIG_BLOCK, &mask_one, &prev_one);
                kill(pid, SIGCONT);
                jobs_set_fg_pid(pid);
                while(jobs_get_fg_pid())
                    sigsuspend(&prev_one);
                sigprocmask(SIG_SETMASK, &prev_one, NULL);
            } else {
                printf("No such job\n");
            }
        }
        return 1;
    }
    
    return 0; // Not a builtin command
}

int parseline(char* buf, char** argv)
{
    char* delim;
    int argc;
    int bg;

    buf[strlen(buf) - 1] = ' '; // Replace trailing '\n' with space
    while (*buf && (*buf == ' ')) // Ignore leading spaces
        buf++;

    argc = 0;
    while ((delim = strchr(buf, ' '))) {
        argv[argc++] = buf;
        *delim = '\0';
        buf = delim + 1;
        while (*buf && (*buf == ' ')) // Ignore spaces
            buf++;
    }
    argv[argc] = NULL;

    if( argc == 0 ) // Ignore blank line
        return 1;
    
    if((bg = (*argv[argc-1] == '&')) != 0)
        argv[--argc] = NULL;

    return bg;
}

static int is_number_str(char* s) {
  int len = strlen(s);
  for (int i = 0; i < len; i++)
    if (!isdigit(s[i]))
      return 0;

  return 1;
}

int parse_id(char* s) {
  int error = -1;
  if (s == NULL)
    return error;

  /* format: %ddddd */
  if (s[0] == '%') {
    if (!is_number_str(s+1))
      return error;

    return atoi(s+1);
  }
  /* format: dddddd */
  if (is_number_str(s))
    return atoi(s);

  /* not right */
  return error;
}

void sigchld_handler(int sig) {
    int old_errno = errno;
    int status;
    pid_t pid;

    sigset_t mask_all, prev_all;
    sigfillset(&mask_all);

    /* exit or be stopped or continue */
    while ((pid = waitpid(-1, &status, WNOHANG | WUNTRACED | WCONTINUED)) > 0) {
        /* exit normally */
        if (WIFEXITED(status) || WIFSIGNALED(status)) {
            sigprocmask(SIG_BLOCK, &mask_all, &prev_all);
            if (jobs_is_fg_by_pid(pid)) {
                jobs_set_fg_pid(0);
            } else {
                Sio_puts("pid "); Sio_putl(pid); Sio_puts(" terminates\n");
            }
            jobs_delete_job_by_pid(pid);
            sigprocmask(SIG_SETMASK, &prev_all, NULL);
        }

        /* be stopped */
        if (WIFSTOPPED(status)) {
            sigprocmask(SIG_BLOCK, &mask_all, &prev_all);
            if (jobs_is_fg_by_pid(pid)) {
                jobs_set_fg_pid(0);
            }
            // set pid status stopped
            jobs_set_status_by_pid(pid, JOB_ST);
            sigprocmask(SIG_SETMASK, &prev_all, NULL);
            Sio_puts("pid "); Sio_putl(pid); Sio_puts(" be stopped\n");
        }

        /* continue */
        if(WIFCONTINUED(status)) {
            job_state_t job_status;
            sigprocmask(SIG_BLOCK, &mask_all, &prev_all);
            // set pid status running
            job_status = jobs_is_fg_by_pid(pid) ? JOB_FG : JOB_BG;
            jobs_set_status_by_pid(pid, job_status);
            sigprocmask(SIG_SETMASK, &prev_all, NULL);

            Sio_puts("pid "); Sio_putl(pid); Sio_puts(" continue\n");
        }
    }
    errno = old_errno;
}

void sigint_handler(int sig) {
    int old_errno = errno;
    pid_t fg_pid = jobs_get_fg_pid();
    if (fg_pid != 0) {
        kill(-fg_pid, SIGINT); 
    } else {
        // exit(0);
        signal(SIGINT, SIG_DFL);
        kill(getpid(), SIGINT);
    }
    errno = old_errno;
}

void sigtstp_handler(int sig) {
    int old_errno = errno;
    pid_t fg_pid = jobs_get_fg_pid();
    if (fg_pid != 0) {
        kill(-fg_pid, SIGTSTP); 
    } else {
        signal(SIGTSTP, SIG_DFL);
        kill(getpid(), SIGTSTP);
    }
    errno = old_errno;
}