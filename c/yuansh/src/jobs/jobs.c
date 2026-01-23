#include "jobs.h"
#include <signal.h>
#include <string.h>
#include <stdio.h>

static struct jobs_manager {
    job_t jobs[MAX_JOBS];   // job数组，下标加一后为该job的jid
    volatile sig_atomic_t fg_pid;
} jobs_manager;

void jobs_init(void)
{
    size_t i;
    for( i = 0; i < MAX_JOBS ; i++) {
        jobs_manager.jobs[i].pid = 0;
        jobs_manager.jobs[i].state = JOB_UNDEF;
        jobs_manager.jobs[i].cmdline[0] = '\0';
    }
    jobs_manager.fg_pid = 0;
}

int jobs_add_job(pid_t pid, job_state_t state, const char* cmdline)
{
    size_t i;
    if( pid < 1 )
        return 0;
    
    for( i = 0; i < MAX_JOBS ; i++ ) {
        if( jobs_manager.jobs[i].pid == 0 ) {
            jobs_manager.jobs[i].pid = pid;
            jobs_manager.jobs[i].state = state;
            strncpy(jobs_manager.jobs[i].cmdline, cmdline, MAX_LINE-1);
            jobs_manager.jobs[i].cmdline[MAX_LINE-1] = '\0';
            if( state == JOB_FG )
                jobs_manager.fg_pid = pid;
            return 1;
        }
    }
    return 0; // Job list full
}

int jobs_delete_job_by_pid(pid_t pid)
{
    size_t i;
    if( pid < 1 )
        return 0;
    
    for( i = 0; i < MAX_JOBS ; i++ ) {
        if( jobs_manager.jobs[i].pid == pid ) {
            jobs_manager.jobs[i].pid = 0;
            jobs_manager.jobs[i].state = JOB_UNDEF;
            jobs_manager.jobs[i].cmdline[0] = '\0';
            if( jobs_manager.fg_pid == pid )
                jobs_manager.fg_pid = 0;
            return 1;
        }
    }
    return 0; // Job not found
}

int jobs_delete_job_by_jid(jid_t jid)
{
    return jobs_delete_job_by_pid(jobs_get_pid_by_jid(jid));
}

int jobs_get_pid_by_jid(jid_t jid)
{
    if( jid < 1 || jid > MAX_JOBS )
        return 0;
    return jobs_manager.jobs[jid - 1].pid;
}

int jobs_get_pid_by_cmdline(const char* cmdline)
{
    size_t i;
    for( i = 0; i < MAX_JOBS ; i++ ) {
        if( jobs_manager.jobs[i].pid != 0 &&
            strcmp(jobs_manager.jobs[i].cmdline, cmdline) == 0 ) {
            return jobs_manager.jobs[i].pid;
        }
    }
    return 0; // Job not found
}

int jobs_get_fg_pid(void)
{
    return jobs_manager.fg_pid;
}

void jobs_set_fg_pid(pid_t pid)
{
    jobs_manager.fg_pid = pid;
}

void jobs_set_status_by_pid(pid_t pid, job_state_t state)
{
    size_t i;
    for( i = 0; i < MAX_JOBS ; i++ ) {
        if( jobs_manager.jobs[i].pid == pid ) {
            jobs_manager.jobs[i].state = state;
            return;
        }
    }
}

void jobs_set_status_by_jid(jid_t jid, job_state_t state)
{
    pid_t pid = jobs_get_pid_by_jid(jid);
    jobs_set_status_by_pid(pid, state);
}

int jobs_is_fg_by_pid(pid_t pid)
{
    return jobs_manager.fg_pid == pid;
}

void jobs_list(void)
{
    size_t i;
    for (i = 0; i < MAX_JOBS; i++) {
        if (jobs_manager.jobs[i].pid != 0) {
            const char* state_str = (jobs_manager.jobs[i].state == JOB_FG) ? "Running" :
                                (jobs_manager.jobs[i].state == JOB_BG) ? "Running" :
                                (jobs_manager.jobs[i].state == JOB_ST) ? "Stopped" : "Undefined";

            // jobs_manager.jobs[i].cmdline 以 \n\0 结尾，故这里不需要再加 \n
            printf("[%lu] %d %s \t %s", i + 1, jobs_manager.jobs[i].pid,
                state_str, jobs_manager.jobs[i].cmdline);
        }
    }
}