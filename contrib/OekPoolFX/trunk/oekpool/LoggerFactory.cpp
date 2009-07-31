/*
 * LoggerFactory.cpp
 *
 *  Created on: 16.07.2009
 *      Author: bw21
 */

#include "LoggerFactory.h"
#include "ILogger.h"
#include "StdLogger.h"
#include "FileLogger.h"

LoggerFactory::LoggerFactory() : _global(*(new Logger())) {
	_global.registerLogger((ILogger*)new StdLogger());
	_global.registerLogger((ILogger*)new FileLogger("output.log"));

}

LoggerFactory::~LoggerFactory() {
	delete &_global;
}

LoggerFactory* LoggerFactory::getInstance() {
	static LoggerFactory instance;

	return &instance;
}


Logger* LoggerFactory::getGlobalLogger() {
	return &_global;
}
