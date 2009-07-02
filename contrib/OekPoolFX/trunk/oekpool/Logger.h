/*
 * Logger.h
 *
 *  Created on: 18.06.2009
 *      Author: bw21
 */

#ifndef LOGGER_H_
#define LOGGER_H_


#include <StdLog.h> // from libSocket
#include <string>
#include <vector>

#include "ILogger.h"
#include "types.h"

class Logger : ILogger {
private:
	loglevel_t loglevel;
	std::vector<ILogger*> vecLogger;

public:
	Logger();
	virtual ~Logger();

	void registerLogger(const ILogger*);
	void removeLogger(const ILogger*);

	void log(loglevel_t, std::string, const Client*);
};

#endif /* LOGGER_H_ */
