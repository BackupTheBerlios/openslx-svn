/*
 * Configuration.h
 *
 *  Created on: 20.05.2009
 *      Author: bastian
 */

#include <string>
#include <map>

#ifndef CONFIGURATION_H_
#define CONFIGURATION_H_

class Configuration {

private:
    Configuration();
    std::map<std::string, std::string> vals;

public:
    /**
     * Singleton wrapper for this class
     */
    static Configuration& getInstance();
    virtual ~Configuration();
    std::string getString(std::string name);
    int getInt(std::string name);

};

#endif /* CONFIGURATION_H_ */
