/*
 * server/file.h - Functions to work with files.
 */


/*
 * Open a file and test it with stat.
 *
 * Returns: File descriptor on success or -1 on failure.
 */
int file_open(char *filename);


/*
 * Store in @size the size in bytes of the file pointed to by @fd.
 *
 * Returns: 0 on success -1 on failure;
 *
 */
int file_getsize(int fd, off_t *size);


/*
 * Copy @size bytes of @fd, starting at @pos, into @buf.
 *
 * Returns: 0 on success -1 on failure.
 */
int file_read(int fd, void *buf, size_t size, off_t pos);
