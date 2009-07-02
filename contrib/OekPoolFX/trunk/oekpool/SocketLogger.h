/*
 * SocketLogger.h
 *
 *  Created on: 02.07.2009
 *      Author: bw21
 */

#ifndef SOCKETLOGGER_H_
#define SOCKETLOGGER_H_


#include "ILogger.h"


class SocketLogger : ILogger {
public:
	SocketLogger();
	~SocketLogger();
};

#endif /* SOCKETLOGGER_H_ */
