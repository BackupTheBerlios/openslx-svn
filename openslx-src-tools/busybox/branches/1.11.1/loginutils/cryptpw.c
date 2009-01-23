/* vi: set sw=4 ts=4: */
/*
 * cryptpw.c
 *
 * Cooked from passwd.c by Thomas Lundquist <thomasez@zelow.no>
 */

#include "libbb.h"

#define TESTING 0

/*
set TESTING to 1 and pipe some file through this script
if you played with bbox's crypt implementation.

while read line; do
	n=`./busybox cryptpw -a des -- "$line"`
	o=`./busybox_org cryptpw -a des -- "$line"`
	test "$n" != "$o" && {
		echo n="$n"
		echo o="$o"
		exit
	}
	n=`./busybox cryptpw -- "$line"`
	o=`./busybox_org cryptpw -- "$line"`
	test "$n" != "$o" && {
		echo n="$n"
		echo o="$o"
		exit
	}
done
 */

int cryptpw_main(int argc, char **argv) MAIN_EXTERNALLY_VISIBLE;
int cryptpw_main(int argc ATTRIBUTE_UNUSED, char **argv)
{
    char salt[sizeof("$2a$10$1234567890123456789012X")];
	char *opt_a;

    if (!getopt32(argv, "a:", NULL)
    || (argv[optind - 1][0] != 'b' && argv[optind - 1][0] != 'd')) {
        /* md5 */
		salt[0] = '$';
		salt[1] = '1';
		salt[2] = '$';
		crypt_make_salt(salt + 3, 4, 0); /* md5 */
#if ENABLE_FEATURE_CRYPTPW_BLOWFISH
    } else if (argv[optind - 1][0] == 'b') {
        /* blowfish */
        strcpy(salt, "$2a$10$");
        crypt_make_salt(salt + 7, 11, 0);
#endif 
#if TESTING
		strcpy(salt + 3, "ajg./bcf");
#endif
	} else {
		/* des */
		crypt_make_salt(salt, 1, 0);
#if TESTING
		strcpy(salt, "a.");
#endif
	}

	puts(pw_encrypt(argv[optind] ? argv[optind] : xmalloc_fgetline(stdin), salt, 1));

	return 0;
}
