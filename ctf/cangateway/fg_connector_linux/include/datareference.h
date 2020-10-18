// Copyright (C) 2008,2009,2010 by Philipp Münzel. All rights reserved.
// Released under the terms of the license described in license.txt

#ifndef DATAREFERENCE_H
#define DATAREFERENCE_H

#include "dllexport.h"

#include <string>
#include <boost/date_time.hpp>
#include <boost/function.hpp>

#include "canaerometadata.h"

namespace SCS {

/**
  * @brief Interface to data received from the bus.
  *
  * If you need more customization in what should happen
  * when data is received, you should implement this interface
  * with template-classes.
  *
  * @author (c) 2009, 2010 by Philipp Münzel
  * @version 1.3
  */
class DLL_PUBLIC TypelessDataReference {
public:

    virtual ~TypelessDataReference() {}

    /**
      * Check if data has been update from the bus and sync application data.
      */
    virtual void update() = 0;

    /**
      * Read the actual value from incoming data, perform epsilon checks and
      * check for losses.
      */
    virtual void readFromCan(const CanAeroMetadata& meta, const can_t& can) = 0;

    /**
      * Take the value of application data and contruct a CAN message
      * (or an array of messsages) from it.
      */
    virtual std::vector<can_t> write(const CanAeroMetadata& meta) = 0;

    /**
      * @return true if value has not been received for longer than 20 seconds
      */
    virtual bool needRequest() const = 0;

    /**
      * Reset the internal timer when data was requested, but not yet received,
      * to prevent request-flooding.
      */
    virtual void requested() = 0;

    /**
      * @return true if the last receive changed the internal value
      */
    virtual bool hasChanged() const = 0;

    /**
      * @return true if this dataref is owned by this application
      */
    virtual bool isSelfPublished() const = 0;
};


/**
  * @brief Standard implementation of DataReference
  *
  * @author (c) 2009, 2010 by Philipp Münzel
  * @version 1.3
  */
template <typename T>
class DLL_PUBLIC DataReference : public TypelessDataReference
{
public:
    typedef boost::function<void (const T&)> func;

    /**
      * @param ptr ptr to value in application that will be update when data
      * arrives from the Bus.
      */
    DataReference(bool own, T* ptr);

    /**
      * @param func_ptr function to be invoked when data arrives from the bus
      */
    DataReference(bool own, func func_ptr);

    /**
      * @param func_ptr function to be invoked when data arrives from the bus
      * @param ptr ptr to value in application that will be update when data
      * arrives from the Bus.
      */
    DataReference(bool own, func func_ptr, T* ptr);

    /**
      * @see TypelessDataReference::update
      */
    void update();

    /**
      * @see TypelessDataReference::readFromCan
      */
    virtual void readFromCan(const CanAeroMetadata& meta, const can_t& can);

    /**
      * @see TypelessDataReference::write
      */
    std::vector<can_t> write(const CanAeroMetadata& meta);

    /**
      * @see TypelessDataReference::needRequest
      */
    bool needRequest() const;

    /**
      * @see TypelessDataReference::requested
      */
    void requested();

    /**
      * @see TypelessDataReference::hasChanged
      */
    bool hasChanged() const;

    /**
      * @see TypelessDataReference::isSelfPublished
      */
    bool isSelfPublished() const { return m_is_self_published; }

protected:
    unsigned long m_number_of_losses;
    T m_cached_value;
    T m_history_value;

private:
    void checkMessageCode(const CanAeroMetadata& meta, uint8_t msg_code);
    void received();
    std::vector<can_t> writeCan(const CanAeroMetadata& meta, const T&);
    void init();

private:
    T* m_ptr;
    func m_func_ptr;
    bool m_was_requested;
    bool m_has_changed;
    bool m_is_self_published;
    boost::posix_time::ptime m_last_received;

};



}
#endif // DATAREFERENCE_H
