# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
# Copyright (C) 2005  Ampere K. [Hardraade]
#
# This file is protected by the GNU Public License.  For more details, please see the text file COPYING.
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
# binarysearchtree.nas
# This is an implementation of a binary search tree using Nasal.  This class inherits the BinaryTree object.
# 
# Class:
#  BinarySearchTree
#  	Methods:
#  	 new(c) 		- creates and returns a new instance of the binary search tree object.
#  	 find(k)		- returns the entry with the given key.
#  	 insert(k, e)		- inserts the element and associate it with the given key.
#  	 removeEntry(entry)	- removes the specified entry from the binary search tree.
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
Comparator = {
	# An empty comparator
	compare : func(key1, key2){
	}
};

BinarySearchTree = {
# Sub-class:
	Entry : {
		# Creates a new entry.
		new : func(key, value, position){
			obj = {};
			obj.parents = [BinarySearchTree.Entry];
			
			# Instance variables:
			obj._key = key;
			obj._position = position;
			obj._value = value;
			
			return obj;
		},
		
		# Accessors:
		key : func{
			return me._key;
		},
		
		position : func{
			return me._position;
		},
		
		value : func{
			return me._value;
		}
	},

# Methods:
	new : func(c){
		obj = {};
		obj.parents = [BinaryTree, BinarySearchTree];
		
		# Instance variables:
		obj._c = c;	# Comparator.
		obj._entries = 0;
		obj._root = nil;
		obj._size = 0;
				
		return obj;
	},
	
	# Auxiliary methods:
	
	# Returns the entry of the specified tree node.
	entry : func(pos){
		return pos.element();
	},
	
	# Returns the key of the specified tree node.
	key : func(pos){
		return pos.element().key();
	},
	
	# Returns the value of the specified tree node.
	value : func(pos){
		return pos.element().value();
	},
	
	# Inserts an entry at v external node, then expands v to be an internal node.
	insertAtExternal : func(v, e){
		if (v == nil or e == nil){
			# Illegal argument(s).
			# Force an error.  DO NOT REMOVE!
			die ("node or element cannot be null.");
			return ni;
		}
		
		if (me.isInternal(v)){
			# Force an error.  DO NOT REMOVE!
			die ("cannot insert v, as it is not an external node.");
			return nil;
		}
		
		# Make v internal by adding external nodes.
		me.insertLeft(v, nil);
		me.insertRight(v, nil);
		me.replace(v, e);
		
		# Increase nodes tally.
		me._entries = me._entries + 1;
		
		return e;
	},
	
	# From the given node, performs a search down the tree and returns the node containing the given key.
	search : func(k, v){
		if (k == nil or v == nil){
			# Illegal argument(s).
			# Force an error.  DO NOT REMOVE!
			die ("illegal argument(s).");
			return nil;
		}
		
		if (me.isExternal(v)){
			# No node with the given key is found, so return the external node.
			return v;
		}
		else {
			key = me.key(v);
			tmp = me._c.compare(k, key);
			
			if (tmp < 0){
				return me.search(k, me.getLeft(v));
			}
			elsif (tmp > 0){
				return me.search(k, me.getRight(v));
			}
			return v;
		}
	},
	
	# Accessors:
	
	# Finds and returns the entry with the given key.
	find : func(k){
		if (k == nil){
			# Force an error.  DO NOT REMOVE!
			die ("invalid key.");
			return nil;
		}
		if (me.root() == nil){
			# Root has not been initialized.  Abort.
			return nil;
		}
			
		v = me.search(k, me._root);
		
		if (v == nil){
			# Error was encountered during search.
			return nil;
		}
		
		if (me.isExternal(v)){
			# Nothing found.
			return nil;
		}
		else {
			# Return the entry.
			return v.element();
		}
	},
	
	# Returns the key of the specified entry.
	getKey : func(entry){
		return entry.key();
	},
	
	# Returns the node where the entry is contained.
	getPosition : func(entry){
		return entry.position();
	},
	
	# Returns the value stored in the given entry.
	getValue : func(entry){
		return entry.value();
	},
	
	# Modifiers:
	
	# Using the key, inserts an element in the correct position on the tree.
	insert : func(k, e){
		if (k == nil or e == nil){
			# Illegal argument(s).
			# Force an error.  DO NOT REMOVE!
			die ("key or object cannot be null.");
			return nil;
		}
		if (me.root() == nil){
			# Root has not been initialized.  Abort.
			return nil;
		}
		
		# Search for the correct external node.
		v = me.search(k, me.root());
		
		if (v == nil){
			# Error encountered during search.
			return nil;
		}
		elsif ((v.element() == nil) == 0){ 
			if (me._c.compare(v.element().key(), k) == 0){
				# Entry already exists.  Update the node and return the result.
				entry = me.Entry.new(k, e, v);
				return me.replace(v, entry);
			}
		}
		
		# Create and insert a new entry.
		while (me.isInternal(v)){
			v = me.search(k, me.getRight(v));
		}
		
		entry = me.Entry.new(k, e, v);
		return (me.insertAtExternal(v, entry)); 
	},
	
	# Removes the node with the given entry.
	removeEntry : func(entry){
		if (entry == nil){
			# Illegal argument.
			# Force an error.  DO NOT REMOVE!
			die ("cannot remove null entry.");
			return nil;
		}
		
		v = me.getPosition(entry);
		
		if (me.isExternal(v)){
			# No node with key entry.key().
			return nil;
		}
		
		rmNode = nil;
		if (me.hasLeft(v) and me.isExternal(me.getLeft(v)) == 1){
			# The left child of v is external.
			# Remove v's external child, then use the standard remove function to remove v.
			me.remove(me.getLeft(v));
		}
		elsif (me.hasRight(v) and me.isExternal(me.getRight(v)) == 1){
			# The right child of v is external.
			# Remove v's external child, then use the standard remove function to remove v.
			me.remove(me.getRight(v));
		}
		else {	# Both children of v are internal nodes.
			# Get the right child of v, then iterate through all the left child until we hit a 
			#  node with an external children.
			swap = me.getRight(v);
			l = me.getLeft(swap);
			while (me.isInternal(l)){
				l = me.getLeft(l);
			}
			# Replace r with l's parent.
			tmp = l.getParent();
			me.replace(swap, tmp.element());
			
			# Remove l using standard remove.
			me.remove(l);
			
			# Remove l's parent.
#			me.remove(tmp);
		}
		me._entries = me._entries - 1;
		
		return v;
	}
};