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

class Logger {
private:
	loglevel_t loglevel;
public:
	Logger();
	virtual ~Logger();

	void log(std::string, loglevel_t);
};

#endif /* LOGGER_H_ */
