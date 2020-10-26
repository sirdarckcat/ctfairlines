// main.cpp

#include <iostream>

// include the most important entrance to the CAN Aerospace world
#include "receiver.h"

// include a threading helper, it will provide a platform-independant parallel execution
#include "scopedparallelexecutor.h"

// include all ids, so you don't have to look them up in the manual
#include "ids.h"


// pull SCS into the global namespace, if you like
using namespace SCS;

// state that the simulator is required to provide at least the SCS variables
// distribution in revision 2
const unsigned char required_sw_revision = 2;

// This is a callback to be executed when we receive a
// new position of the landing light switch
// Note that you use the Type that the ID specifies. This is convenient
// and statically type safe.
void handle_land_lights(LIGHT_LANDING_SWITCH::Type b)
{
    if (b)
        std::cout << "Land lights on" << std::endl;
    else
        std::cout << "Land lights off" << std::endl;
}

// This is a callback to be executed when we receive a
// new true heading
void handle_thdg(TRUE_HDG_DEG::Type thdg)
{
    std::cout << "hdg " << thdg << " deg TRUE" << std::endl;
}

// This is a callback to be executed when we receive a
// new frequency setting on the COM1 radio
void handle_com1_freq(COM1_FREQ_KHZ::Type freq)
{
    std::cout << "COM1 " << freq/1000.0 << std::endl;
}

// wait for the user to press enter before we kill the program
void wait()
{
    std::cin.clear();
    std::cin.ignore(std::cin.rdbuf()->in_avail());
    std::cin.get();
}

int main()
{
    // Create a Receiver instance
    Receiver my_receiver(required_sw_revision);
    
    // this variable will hold the landing light switch position
    LIGHT_LANDING_SWITCH::Type land_lights;
    
    // this variable will hold the com1 frequency
    COM1_FREQ_KHZ::Type com1_freq;

    // this variable will hold the true heading
    TRUE_HDG_DEG::Type true_hdg;
    
    // ask for the landing lights switch value on the bus
    // we want both the callback notified and the local variable updated
    my_receiver.requestData(LIGHT_LANDING_SWITCH::Id(), &handle_land_lights, &land_lights);
    
    // ask for the COM1 frequency on the bus.
    // we want both the callback notified and the local variable updated with COM1
    my_receiver.requestData(COM1_FREQ_KHZ::Id(), &handle_com1_freq, &com1_freq);
    
    // ask for the true heading on the bus.
    // we want only the callback to be notified
    my_receiver.requestData(TRUE_HDG_DEG::Id(), &handle_thdg, &true_hdg);
    
    // have the run function of Receiver called every 500ms in another thread
    // Of course, you can also write your own main loop and call my_receiver.run();
    ScopedParallelExecutor exec(boost::bind(&Receiver::run, &my_receiver, false), 500);
    
    
    // Okay, everything is running now, and when you change the COM1 in your
    // simulator, you will be notfied via the callback and also your local
    // variable will get updated.

    // Suppose you want to set the COM1 frequency now to 119.250
    std::cout << "Hit enter to turn on landing lights and set COM1 frequency!" << std::endl;
    wait();
    std::cout << "Setting COM1 to 119.25" << std::endl;
    
    // Note that the COM1 freq is in kHz, so
    // you set your local variable to 119250 kHz
    com1_freq = 119250;
    
    // and tell libcanaero to sync the bus to your value for the CAN id of COM1
    my_receiver.sendData(COM1_FREQ_KHZ::Id());
    
    
    std::cout << "Activating landing lights!" << std::endl;
    
    // same goes for the landing lights !
    land_lights = true;
    my_receiver.sendData(LIGHT_LANDING_SWITCH::Id());
    
    
    std::cout << "Hit enter again to quit" << std::endl;
    wait();
    return 0;
}
