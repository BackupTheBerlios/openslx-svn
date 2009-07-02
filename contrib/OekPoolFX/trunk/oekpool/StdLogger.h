/*
 * StdLogger.h
 *
 *  Created on: 02.07.2009
 *      Author: bw21
 */

#ifndef STDLOGGER_H_
#define STDLOGGER_H_

#include "ILogger.h"

class StdLogger : ILogger {
public:
	StdLogger();
	~StdLogger();

	void log(loglevel_t, std::string,const Client*);
};

#endif /* STDLOGGER_H_ */
