// $OpenLDAP: pkg/ldap/contrib/ldapc++/src/LDAPEntryList.cpp,v 1.3 2008/03/28 10:05:10 ralf Exp $
/*
 * Copyright 2000, OpenLDAP Foundation, All Rights Reserved.
 * COPYING RESTRICTIONS APPLY, see COPYRIGHT file
 */


#include "LDAPEntryList.h"
#include "LDAPEntry.h"

LDAPEntryList::LDAPEntryList(){
}

LDAPEntryList::LDAPEntryList(const LDAPEntryList& e){
    m_entries = e.m_entries;
}

LDAPEntryList::~LDAPEntryList(){
}

size_t LDAPEntryList::size() const{
    return m_entries.size();
}

bool LDAPEntryList::empty() const{
    return m_entries.empty();
}

LDAPEntryList::const_iterator LDAPEntryList::begin() const{
    return m_entries.begin();
}

LDAPEntryList::const_iterator LDAPEntryList::end() const{
    return m_entries.end();
}

void LDAPEntryList::addEntry(const LDAPEntry& e){
    m_entries.push_back(e);
}

