/* vi: set sw=4 ts=4: */
/*
 * Utility routines.
 *
 * Copyright (C) 2006 Gabriel Somlo <somlo at cmu.edu>
 *
 * Licensed under GPLv2 or later, see file LICENSE in this tarball for details.
 */

#include "libbb.h"

/* check if path points to an executable file;
 * return 1 if found;
 * return 0 otherwise;
 */
int execable_file(const char *name)
{
	struct stat s;
	return (!access(name, X_OK) && !stat(name, &s) && S_ISREG(s.st_mode));
}

/* search (*PATHp) for an executable file;
 * return allocated string containing full path if found;
 *  PATHp points to the component after the one where it was found
 *  (or NULL),
 *  you may call find_execable again with this PATHp to continue
 *  (if it's not NULL).
 * return NULL otherwise; (PATHp is undefined)
 * in all cases (*PATHp) contents will be trashed (s/:/NUL/).
 */
char *find_execable(const char *filename, char **PATHp)
{
	char *p, *n;

	p = *PATHp;
	while (p) {
		n = strchr(p, ':');
		if (n)
			*n++ = '\0';
		if (*p != '\0') { /* it's not a PATH="foo::bar" situation */
			p = concat_path_file(p, filename);
			if (execable_file(p)) {
				*PATHp = n;
				return p;
			}
			free(p);
		}
		p = n;
	} /* on loop exit p == NULL */
	return p;
}

/* search $PATH for an executable file;
 * return 1 if found;
 * return 0 otherwise;
 */
int exists_execable(const char *filename)
{
	char *path = xstrdup(getenv("PATH"));
	char *tmp = path;
	char *ret = find_execable(filename, &tmp);
	free(path);
	if (ret) {
		free(ret);
		return 1;
	}
	return 0;
}

#if ENABLE_FEATURE_PREFER_APPLETS
/* just like the real execvp, but try to launch an applet named 'file' first
 */
int bb_execvp(const char *file, char *const argv[])
{
	return execvp(find_applet_by_name(file) >= 0 ? bb_busybox_exec_path : file,
					argv);
}
#endif