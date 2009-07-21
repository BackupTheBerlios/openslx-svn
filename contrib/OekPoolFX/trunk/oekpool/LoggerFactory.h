/*
 * LoggerFactory.h
 *
 *  Created on: 16.07.2009
 *      Author: bw21
 */

#ifndef LOGGERFACTORY_H_
#define LOGGERFACTORY_H_

#include "ILogger.h"
#include "Logger.h"

class LoggerFactory {

	Logger& _global;

	LoggerFactory();
	virtual ~LoggerFactory();

public:
	static LoggerFactory* getInstance();

	Logger* getGlobalLogger();
};

#endif /* LOGGERFACTORY_H_ */
