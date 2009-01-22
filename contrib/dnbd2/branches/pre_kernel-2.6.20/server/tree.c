/*
 * server/tree.c
 */


#include <search.h>
#include <stdlib.h>
#include <inttypes.h>
#include "dnbd2.h"
#include "tree.h"


int compare_node(const void *node1, const void *node2)
{

	dataset_t *ds1 = ((node_t *) node1)->ds;
	dataset_t *ds2 = ((node_t *) node2)->ds;

	int diff = ds1->vid - ds2->vid;
	if (diff != 0)
		return diff;

	return ds1->rid - ds2->rid;
}


void destroy_node(void *node)
{
	free(((node_t *) node)->ds);
	free((node_t *) node);
}


int tree_insert(node_t *data, void **tree)
{
	void *tmp = tsearch((void *)data, tree, compare_node);
	if (!tmp)
		return -1;

	node_t *ret = *(node_t **) tmp;

	/* Check if there is another item
	   in the tree with the same key. */
	if (ret != data)
		return -1;

	return 0;
}


node_t *tree_find(node_t *data, void **tree)
{
	void *tmp = tfind((void *)data, tree, compare_node);

	if (!tmp)
		return NULL;

	node_t *ret = *(node_t **) tmp;

	return ret;
}


void tree_destroy(void **tree)
{
	tdestroy(tree, &destroy_node);
}
