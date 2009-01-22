/*
 * server/tree.h - Mechanism to store Datasets in binary trees.
 */


/*
 * This structure represents a Dataset along with its config file and
 * file descriptor. This type of items will be stored in a binary
 * tree.  The key to this structure is the Dataset's Volume-ID and
 * Release-ID (they must be unique in each server instance).
 */
typedef struct node {
	dataset_t *ds;
	char path[FILE_NAME_MAX];
	int fd;
	int servers;
	dnbd2_server_t server[ALT_SERVERS_MAX];
} node_t;


/*
 * Returns: 0 on success or -1 on failure.
 */
int tree_insert(node_t *data, void **tree);


/*
 * Returns: Pointer to item on search-hit or NULL on search-miss.
 */
node_t *tree_find(node_t *data, void **tree);


/*
 * Free all resources used by the tree.  Useful when reloading
 * datasets.
 */
void tree_destroy(void **tree);
