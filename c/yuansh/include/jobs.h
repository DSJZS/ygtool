#ifndef __JOBS_H__
#define __JOBS_H__

#include <sys/types.h>
#include "shell_config.h"

typedef enum job_state_t {
    JOB_UNDEF = 0,  // Undefined
    JOB_FG = 1,     // Running in foreground
    JOB_BG = 2,     // Running in background
    JOB_ST = 3      // Stopped
} job_state_t;

typedef struct job_t {
    pid_t pid;              // Job PID
    job_state_t state;      // Job state
    char cmdline[MAX_LINE];    // Command line，规定必须以 \n\0 结尾，不然会有显示错误
} job_t;

typedef int jid_t; // Job ID type

void jobs_init(void);
int jobs_add_job(pid_t pid, job_state_t state, const char* cmdline);
int jobs_delete_job_by_pid(pid_t pid);
int jobs_delete_job_by_jid(jid_t jid);
int jobs_get_pid_by_jid(jid_t jid);
int jobs_get_pid_by_cmdline(const char* cmdline);
int jobs_get_fg_pid(void);
void jobs_set_fg_pid(pid_t pid);
void jobs_set_status_by_pid(pid_t pid, job_state_t state);
void jobs_set_status_by_jid(jid_t jid, job_state_t state);
int jobs_is_fg_by_pid(pid_t pid);
void jobs_list(void);

#endif
