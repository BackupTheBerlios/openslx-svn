/*
 * FileLogger.h
 *
 *  Created on: 02.07.2009
 *      Author: bw21
 */

#ifndef FILELOGGER_H_
#define FILELOGGER_H_

#include "ILogger.h"
#include <string>
#include <fstream>

class FileLogger : ILogger {
	std::string filename;
	std::ofstream file;
public:
	FileLogger(std::string);
	~FileLogger();

	void log(loglevel_t lvl, std::string msg, const Client* client);
};

#endif /* FILELOGGER_H_ */
