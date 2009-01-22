/*
 * server/query.h
 */


/*
 * Builds a @reply based on @request, using the datasets stored in
 * @tree.
 *
 * Returns: 0 on success or -1 on failure.
 */
int handle_query(dnbd2_data_request_t *request,
		 dnbd2_data_reply_t *reply,
		 void **tree);
