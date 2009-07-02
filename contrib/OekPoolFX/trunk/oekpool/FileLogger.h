/*
 * FileLogger.h
 *
 *  Created on: 02.07.2009
 *      Author: bw21
 */

#ifndef FILELOGGER_H_
#define FILELOGGER_H_

#include "ILogger.h"

class FileLogger : ILogger {
public:
	FileLogger();
	~FileLogger();
};

#endif /* FILELOGGER_H_ */
