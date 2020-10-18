# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
# Copyright (C) 2005  Ampere K. [Hardraade]
#
# This file is protected by the GNU Public License.  For more details, please see the text file COPYING.
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
# queue.nas
# This is a Nasal implementation of a Queue using a linked-list.  All the Queue's functions and subroutines
#  have a running time of O(1).
#  
# Class:
#  Queue
#  	Methods:
#  	 new() 		-- creates a new instance of the queue object.
#  	 enqueue(obj) 	-- inserts an object at the rear of the queue.
#  	 dequeue() 	-- removes an object from the front of the queue.
#  	 front() 	-- takes a peak at the object at the front of the queue.
#  	 isEmpty() 	-- returns 0 if the queue is empty; 1 otherwise.
#  	 size() 	-- returns the amount of elements being queued.
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
Queue = {
# Sub-class:
	Node : {
		# Creates a new node with the given element and next node.
		new : func(e, n){
			obj = {};
			obj.parents = [Queue.Node];
			
			# Instance variables:
			obj.element = e;
			obj.next = n;
			
			return obj;
		},
		
		# Accessors:
		getElement : func{
			return me.element;
		},
		
		getNext : func{
			return me.next;
		},
		
		# Modifiers:
		setElement : func(e){
			me.element = e;
		},
		
		setNext : func(n){
			me.next = n;
		}
	},
	
# Methods:
	# Creates a new instance of the queue object.
	new : func{
		obj = {};
		obj.parents = [Queue];
		
		# Instance variables:
		obj.elements = 0;
		obj.head = nil;
		obj.tail = nil;
		
		return obj;
	},
	
	# Inserts an object at the rear of the queue.
	enqueue : func(obj){
		# Set up a new node.
		node = me.Node.new(obj, nil);
		
		if (me.head == nil){
			# Special case where the queue is empty.
			
			# Point head as well as tail to this node.
			me.head = node;
			me.tail = node;
		}
		else {
			# Queue is not empty.
			
			# Set up the next reference of the tail.
			me.tail.setNext(node);
			# Advance tail.
			me.tail = node;
		}
		
		# Update the info on the current size.
		me.elements = me.elements + 1;
	},
	
	# Removes an object from the front of the queue.
	dequeue : func{
		if (me.head == nil){
			return nil;
		}
		else {
			# Advance the head pointer.
			tmp = me.head;
			me.head = me.head.getNext();
			
			# Update the info on the current size.
			me.elements = me.elements - 1;
			
			# Return the actual object being stored, not the node object.
			return tmp.getElement();
		}
	},
	
	# Takes a peek at the object at the front of the queue.
	front : func{
		# Returns the actual object being stored, not the node object.
		if (me.head == nil){
			return nil;
		}
		return me.head.getElement();
	},
	
	# Returns a boolean value indicating whether the queue is empty.
	isEmpty : func{
		return (me.head == nil);
	},
	
	# Returns the number of objects in the queue.
	size : func{
		return me.elements;
	}
};