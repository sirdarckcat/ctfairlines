# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
# Copyright (C) 2005  Ampere K. [Hardraade]
#
# This file is protected by the GNU Public License.  For more details, please see the text file COPYING.
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
# tree.nas
# This is an implementation of a binary tree using Nasal.
#
# Class:
#  BinaryTree
#  	Methods:
#  	 new()			- Creates a new binary tree object.
#  	 getLeft(v)		- Returns the left child of v.
#  	 getRight(v)		- Returns the right child of v.
#  	 getParent(v)		- Returns the parent of v.
#  	 hasLeft(v)		- Returns whether v has a left child.
#  	 hasRight(v)		- Returns whether v has a right child.
#  	 insertLeft(v, e)	- Creates a left child at v, holding object e.
#  	 insertRight(v, e)	- Creates a right child at v, holding object e.
#  	 isEmpty()		- Returns whether the tree is empty.
#  	 isExternal(v)		- Returns whether v is a leaf.
#  	 isInternal(v)		- Returns whether v is not a leaf.
#  	 isRoot(v)		- Returns whether v is a root.
#  	 root()			- Returns the root if there is one.
#  	 remove(v)		- Remove v from the tree provided that v only has one child.
#  	 replace(v, o)		- Replace the element being stored at v with o.
#  	 setRoot(e)		- Makes a root that contains e as an element.
#  	 size()			- Returns the amount of nodes.
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
BinaryTree = {
# Sub-class:
	Position : {
		# Create a new instance of the node object.
		new : func(element, parent, left, right){
			obj = {};
			obj.parents = [BinaryTree.Position];
			
			# Instance variables:
			obj._element = element;
			obj._left = left;
			obj._parent = parent;
			obj._right = right;
			
			return obj;
		},
		
		# Acessors:
		element : func{
			return me._element;
		},
		
		getLeft : func{
			return me._left;
		},
		
		getParent : func{
			return me._parent;
		},
		
		getRight : func{
			return me._right;
		},
		
		# Modifiers:
		setElement : func(e){
			me._element = e;
		},
		
		setLeft : func(left){
			me._left = left;
		},
		
		setParent : func(p){
			me._parent = p;
		},
		
		setRight : func(right){
			me._right = right;
		}
	},
	
# Methods:
	# Create a new instance of a binary tree.
	new : func{
		obj = {};
		obj.parents = [BinaryTree];
		
		# Instance variables:
		obj._root = nil;
		obj._size = 0;
		
		return obj;
	},
	
	# Query:
	
	# Determines whether the specified node has a left child.
	hasLeft : func(v){
		return ((v.getLeft() == nil) == 0);
	},
	
	# Determines whether the specified node has a right child.
	hasRight : func(v){
		return ((v.getRight() == nil) == 0);
	},
	
	# Check whether the tree is empty.
	isEmpty : func{
		if (me._size == 0){
			return 1;
		}
		else{
			return 0;
		}
	},
	
	# Returns whether the specified node is external.
	isExternal : func(v){
		return (me.isInternal(v) == 0);
	},
	
	# Returns whether the specified node is internal.
	isInternal : func(v){
		return (me.hasLeft(v) or me.hasRight(v));
	},
	
	# Returns whether the specified node is root.
	isRoot : func(v){
		return (me._root == v);
	},
	
	# Return the number of nodes stored in the tree.
	size : func{
		return me._size;
	},
	
	# Accessors:
	
	# Returns an iterator of the children of the node.
	children : func(v){
		# Not implemented.
	},
	
	# Returns an iterator of elements stored at the nodes.
	elements : func{
		# Not implemented.
	},
	
	# Returns the left child of the specified node.
	getLeft : func(v){
		if (me.hasLeft(v)){
			return v.getLeft();
		}
		else {
			# Force an error.  DO NOT REMOVE!
			die ("node has no left child.");
			return nil;
		}
	},
	
	# Returns the right child of the specified node.
	getRight : func(v){
		if (me.hasRight(v)){
			return v.getRight();
		}
		else {
			# Force an error.  DO NOT REMOVE!
			die ("node has no right child.");
			return nil;
		}
	},
	
	# Returns the parent of the specified node.
	getParent : func(v){
		if (me.isRoot(v)){
			# Force an error.  DO NOT REMOVE!
			die ("cannot obtain parent from root.");
			return nil;
		}
		return v.getParent();
	},
	
	# Returns an iterator of the position of the tree.
	positions : func{
		# Not implemented.
	},
	
	# Returns the root of the tree.
	root : func{
		return me._root;
	},
	
	# Modifiers:
	
	# Inserts a left child at the specified node.
	insertLeft : func(v, e){
		if (me.hasLeft(v)){
			# Force an error.  DO NOT REMOVE!
			die ("cannot left child when one is already exists.");
			return nil;
		}
		
		# Create a new node and place it under v.
		n = me.Position.new(e, v, nil, nil);
		v.setLeft(n);
		
		me._size = me._size + 1;
		
		return n;
	},
	
	# Inserts a right child at the specified node.
	insertRight : func(v, e){
		if (me.hasRight(v)){
			# Force an error.  DO NOT REMOVE!
			die ("cannot insert right child when one is already exists.");
			return nil;
		}
		
		# Create a new node and place it under v.
		n = me.Position.new(e, v, nil, nil);
		v.setRight(n);
		
		me._size = me._size + 1;
		
		return n;
	},
	
	# Removes the specified node from the tree if it only has one child.
	remove : func(v){
		if (v == nil){
			return nil;
		}
		if (me.hasLeft(v) and me.hasRight(v)){
			# Remove operation can't be performed if both children exist.
			# Force an error.  DO NOT REMOVE!
			die ("cannot remove node when both its children exist.");
			return nil;
		}
		
		# Get child of v.
		c = nil;
		if (me.hasLeft(v)){
			c = me.getLeft(v);
		}
		elsif (me.hasRight(v)){
			c = me.getRight(v);
		}
		else {
			c = nil;
		}
		
		# Get parent of v.
		p = nil;
		if (v == me.root()){
			# Special case, where the root is being removed.
			if (c == nil){
				# Last node being removed.
				me._root = nil;
			}
			else {
				# Set c as root.
				c.setParent(nil);
				me._root = c;
			}
		}
		else {
			p = me.getParent(v);
			if (me.hasLeft(v) and v == me.getLeft(p)){
				p.setLeft(c);
			}
			elsif (me.hasRight(v) and v == me.getRight(p)) {
				p.setRight(c);
			}
		}
		
		# Set parent for c if c exists.
		if (c == nil){}
		else {
			c.setParent(p);
		}
		
		# Deduct tally.
		me._size = me._size - 1;
		
		return v.element();
	},
	
	# Replaces an element inside a node.
	replace : func(v, o){
		# Swap out the element being stored by v with o.
		tmp = v.element();
		v.setElement(o);
		
		return tmp;
	},
	
	# Specify the root of the tree.
	setRoot : func(e){
		if (me._root == nil){
			# Count as new node.
			me._size = me._size + 1;
			
			me._root = me.Position.new(e, nil, nil, nil);
			
			return me._root;
		}
		else {
			# Force an error.  DO NOT REMOVE!
			die ("root has already been set.");
			return nil;
		}
	},
	
	# Returns the number of nodes on the tree.
	size : func{
		return me._size;
	}
};