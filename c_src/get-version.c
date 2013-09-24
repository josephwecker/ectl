#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <sys/param.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <time.h>
#include <sys/time.h>
#include <errno.h>
#define GCC_VERSION (__GNUC__ * 10000 \
                               + __GNUC_MINOR__ * 100 \
                               + __GNUC_PATCHLEVEL__)
#if GCC_VERSION >= 40500
#define _unreachable()  __builtin_unreachable()
#else
#define _unreachable() do { abort(); } while(0)
#endif
#define xstr(N)  #N
#define str(N)   xstr(N)
#define perr()   perror("ERROR [line " str(__LINE__) "]")
#define snap()   {perr(); exit(1);}
#define $(EXPR)  if((EXPR) == -1) snap()
#define $j(EXPR) if((EXPR) == -1) {perr(); goto err;}

size_t quick_run(char **argv, char *buf, size_t max_len) {
    int pfildes[2];
    $( pipe(pfildes) );
    int pid = vfork();
    if(!pid) {
        close (pfildes[0]);
        dup2  (pfildes[1],1);
        close (pfildes[1]);
        execvp(argv[0], argv);
        perr();
        _exit(1);
    } else $( pid );
    close(pfildes[1]);
    ssize_t size = read(pfildes[0], buf, max_len - 1);
    $( size );
    buf[size] = '\0';
    close(pfildes[0]);
    return (size_t)size;
}
#if 0
// Safer version of quick_run if I ever run into trouble...
size_t quick_run(const char *cmd) {
    FILE   *proc = popen(cmd, "r");
    size_t  size = fread(proc_output, sizeof(proc_output)-1, sizeof(char), proc);
    proc_output[size-1] = '\0';
    pclose(proc);
    return size;
}
#endif


void get_last_dirty_modification_stamp(char *buf, size_t max_size) {
    int cwd;
    cwd = 0;
    char *cmd_gitroot [] = {"git", "rev-parse", "--show-toplevel", NULL};
    char *cmd_gitdirty[] = {"git", "status", "--porcelain", "-uno", "-z", NULL};
    int pfildes[2];
    $j( pipe(pfildes) );
    int pid = fork();
    if(!pid) {
        close (pfildes[0]);
        dup2  (pfildes[1],1);
        close (pfildes[1]);
        execvp(cmd_gitdirty[0], cmd_gitdirty);
        perr  ( );
        _exit (1);
        _unreachable();
    } else $j( pid );
    close(pfildes[1]);

    char pathbuf[MAXPATHLEN + 5];
    $j(cwd = open(".", O_RDONLY));
    size_t pathlen = quick_run(cmd_gitroot, pathbuf, sizeof(pathbuf));
    pathbuf[pathlen - 1] = '\0'; // chomp
    $j(chdir(pathbuf));

    FILE *cmd_res = fdopen(pfildes[0], "r");
    if(cmd_res == NULL) $j(-1);

    char    *line = pathbuf;
    size_t   linecap = MAXPATHLEN + 5;
    ssize_t  linelen;
    int      ignore_one = 0;
    time_t   newest_change = 0;
    while( (linelen = getdelim(&line, &linecap, 0, cmd_res)) > 0) {
        if(ignore_one) {
            ignore_one = 0;
            continue;
        }
        if(linelen > 3) {
            if     (line[1] == 'M' || line[0] == 'M' ||
                    line[1] == 'A' || line[0] == 'A' ||
                    line[1] == 'R' || line[0] == 'R' ||
                    line[1] == 'C' || line[0] == 'C' ||
                    line[1] == 'U' || line[0] == 'U' ||
                    line[1] == 'S' || line[0] == 'S' ||
                    line[1] == '?' || line[0] == '?') {
                // git never uses 'S'- but without it there is no... Marcus?
                ignore_one = (line[1] == 'R' || line[0] == 'R');
                struct stat fst;
                if(stat(&(line[3]), &fst) == -1) {
                    if(errno == ENOENT) continue;
                    $j(-1);
                }
#ifdef __linux__
                if(fst.st_mtime > newest_change) newest_change = fst.st_mtime;
#else
                if(fst.st_mtimespec.tv_sec > newest_change) newest_change = fst.st_mtimespec.tv_sec;
#endif
            }
        }
    }

    if(newest_change < 0) {
        struct timeval tp;
        gettimeofday(&tp, NULL);
        newest_change = tp.tv_sec;
    }
    struct tm tmval;
    gmtime_r(&(newest_change), &tmval);
    strftime(buf, max_size-1, "d.%Y%m%d.%H%M%S",&tmval);

    if(fchdir(cwd)){};
    close(cwd);
    fclose(cmd_res);
    return;

err:
    if(cwd) {
        if(fchdir(cwd)){}
        close(cwd);
    }
    exit(1);
}


#define adv(PCHR)    while(*(PCHR) != '\0' && *(PCHR) != '-' && *(PCHR) != '\n'){(PCHR)++;} (PCHR)[0]='\0';(PCHR)++
#define pr(CONSTR)   $(write(STDOUT_FILENO, CONSTR, sizeof(CONSTR)-1))
#define prs(BUF)     $(write(STDOUT_FILENO, BUF, strnlen(BUF, 256)))
#define prl(BUF,LEN) $(write(STDOUT_FILENO, BUF, LEN))

int main(int argc, char **argv) {
    int   i;
    int   is_dirty;

    // Commands
    char *cmd_gitdesc[] = {"git","describe", "--match", "v[0-9.]*", "--dirty", "--long", "--always", NULL};

    // Some constants and buffers
    char  describe_res  [256] = {0};
    char  default_vmajor[]    = "v0.0.0";
    char  default_vnumc []    = "0";
    char  unknown_vnumc []    = "u";
    char  dirty_is_true [32]  = {0};
    char  dirty_is_false[]    = "c";

    // Destination strings for various pieces.
    char *vhash               = NULL;
    char *vmajor              = NULL;
    char *vdirty              = dirty_is_false;
    char *vnum_commits        = unknown_vnumc;

    quick_run(cmd_gitdesc, describe_res, sizeof(describe_res) - 5); // -5 for padding for parser below
    char *p = describe_res;
    if(*p == 'v') {
        vmajor = p++; // Got git tag w/ version
        adv(p); // Advance past & terminate vmajor
        // Next will be either num_commits or hash
        char *pstart = p;
        while(1) {
            if(*p == '-') {
                vnum_commits = pstart;
                adv(p);
                vhash = p++;
                break;
            } else if(*p < '0' || *p > '9') {
                vhash = pstart;
                vnum_commits = default_vnumc;
                break;
            }
            p++;
        }
    } else {
        vmajor = default_vmajor; // No git tag with a version
        vhash = describe_res;    // But we've got the vhash- skip to dirty-check
        // TODO: calculate vnum_commits. In Ruby I was doing it like this:
        //       >    plus_commits = `git shortlog -s`.scan(/\d+/) # should cut name off first
        //       >    plus_commits = plus_commits.map{|p| p.to_i}.reduce(:+)
    }

    adv(p); // Advance to the end of and terminate the vhash
    is_dirty = p[1] == 'i';

    if(is_dirty) {
        vdirty = dirty_is_true;
        get_last_dirty_modification_stamp(vdirty, sizeof(dirty_is_true));
    }

    if(argc == 1) {
        // Strictly the version
        prs(vmajor);
        if(is_dirty || vnum_commits[0]!='0') {
            //pr ("+build.");
            pr ("+");
            prs(vnum_commits); pr (".");
            prs(vdirty);       pr (".");
            if(vhash[0] != 'g')     pr ("g");
            prs(vhash);
        }
        pr("\n");
    } else {
        char *cmd_gitbranch[] = {"git", "rev-parse", "--abbrev-ref", "HEAD", NULL};
        char  gitbr[256];
        size_t gitbr_size = quick_run(cmd_gitbranch, gitbr, sizeof(gitbr));
        gitbr[gitbr_size - 1] = '\0'; // chomp
        for(i=1; i<argc; i++) {
            int j=0;
            while(argv[i][j] != 0) {
                if(argv[i][j] > 0x60 && argv[i][j] < 0x7B) argv[i][j] -= 0x20;
                j++;
            }
            // Define statements
            pr("#define "); prl(argv[i],j); pr("_VERSION_MAJOR_STR \""); prs(vmajor); pr("\"\n");
            pr("#define "); prl(argv[i],j); pr("_VERSION_BUILD_STR \"");
            if(is_dirty || vnum_commits[0]!='0') {
                //pr("+build.");
                pr("+"); prs(vnum_commits); pr("."); prs(vdirty); pr(".");
                if(vhash[0] != 'g') pr("g"); prs(vhash);
            }
            pr("\"\n");
            pr("#define "); prl(argv[i],j); pr("_VERSION_DETAILS_STR_BRANCH \""); prs(gitbr); pr("\"\n");
            pr("#define "); prl(argv[i],j); pr("_VERSION_DETAILS_STR_COMMIT \"");
            (vhash[0] == 'g') ? ({prs(&(vhash[1]))}) : ({prs(vhash)});
            pr("\"\n");
        }
    }

    return 0;
}
