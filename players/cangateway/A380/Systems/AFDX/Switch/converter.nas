# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
# Copyright (C) 2005  Ampere K. [Hardraade]
#
# This file is protected by the GNU Public License.  For more details, please see the text file COPYING.
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********
# converter.nas
# This Nasal script contains functions that convert values from one base to another.  The functions that
#  convert values from base10 to another base will only work on positive numbers.
# 
# Functions
#  asciiToDec(ascii)		- converts and returns the given value from base256 to base10.
#  baseToDec(val[], base) 	- given the vector from of a value of the specified base, converts the value to
#  				   base 10.
#  decToAscii(dec)		- converts and returns the given value from base10 to base256.
#  decToBase(dec, base) 	- converts the given value from base10 to the given base, and returns the 
#  				   result in a vector.
#  decToHex(dec)		- converts and returns the given value from base10 to base16.
#  hexToDec(hex)		- converts and returns the given value from base16 to base10.
# ********** ********** ********** ********** ********** ********** ********** ********** ********** ********** 

# Converts a string to a decimal value.
asciiToDec = func(ascii){
	BASE = 256;
	
	if (ascii == nil){
		# Invalid value.
		return nil;
	}
	if (size(ascii) > 4){
		# Value is too big for conversion.
		return nil;
	}
	
	
	out = 0;
	
	for (i = 0; i < size(ascii); i = i + 1){
		digit = strc(ascii, i);
		
		out = out * BASE + digit;
	}
	
	return out;
}

# Converts and returns the vector form of a value, from the specified base to base10.
baseToDec = func(val, base){
	if (val == nil){
		return nil;
	}
	if (base == nil or base <= 1){
		return nil;
	}
	
	out = 0;
	foreach (digit ; val){
		out = out * base + digit;
	}
	
	return out;
}

# Converts the given decimal value into a value of base256, and returns the string.
decToAscii = func(dec){
	BASE = 256;
	
	if (dec == nil or dec < 0){
		# Illegal value for conversion.
		return nil;
	}
	
	out = "";
	nominator = dec;
	
	while (nominator >= BASE){
		nominator = nominator / BASE;
		
		intValue = int(nominator);
		out = chr((nominator - intValue) * BASE) ~ out;
		nominator = intValue;
	}
	out = chr(nominator) ~ out;
	
	return out;
}

# Converts the given values in base10 to the specified base, and returns the result in a vector format.
decToBase = func(dec, base){
	if (dec == nil or dec < 0){
		# Illegal value for conversion.
		return nil;
	}
	if (base == nil or base <= 1){
		return nil;
	}
	
	out = [];
	nominator = dec;
	
	# Divide the value by base until it is smaller than base.  After each division, rip off the decimal
	#  part and multiply it by base.  The integer part is then saved in the value nominator.
	while (nominator >= base){
		nominator = nominator / base;
		
		intValue = int(nominator);
		append(out, substr(hex, (nominator - intValue) * base, 1));
		nominator = intValue;
	}
	append(out, nominator);
	
	# Swap values.
	for (i = 0; i < size(out) / 2; i = i + 1){
		tmp = out[i];
		out[i] = out[size(out) - i - 1];
		out[size(out) - i - 1] = tmp;
	}
	
	return out;
}

# Converts and returns the given value from base10 to base16.
decToHex = func(dec){
	BASE = 16;
	if (dec == nil or dec < 0){
		# Illegal value for conversion.
		return nil;
	}
	
	hex = "0123456789ABCDEF";
	out = "";
	nominator = dec;
	
	# Divide the value by 16 until it is smaller than 16.  After each division, rip off the 
	#  decimal part and multiply it by 16.  The integer part is then saved in the value nominator.
	while (nominator >= BASE){
		nominator = nominator / BASE;
		
		intValue = int(nominator);
		out = substr(hex, (nominator - intValue) * BASE, 1) ~ out;
		nominator = intValue;
	}
	out = substr(hex, nominator, 1) ~ out;
	
	return out;
}

# Converts the given hexadecimal value into decimal format, and returns the value.
hexToDec = func(hex){
	BASE = 16;
	
	if (hex == nil){
		return nil;
	}
	
	out = 0;
	for (i = 0; i < size(hex); i = i + 1){
		digit = strc(hex, i) - 48;
		if (digit <= 9){
			out = out * BASE + digit;
		}
		else {
			tmp = substr(hex, i, 1);
			if (tmp == "A" or tmp == "a"){
				out = out * BASE + 10;
			}
			elsif (tmp == "B" or tmp == "b"){
				out = out * BASE + 11;
			}
			elsif (tmp == "C" or tmp == "c"){
				out = out * BASE + 12;
			}
			elsif (tmp == "D" or tmp == "d"){
				out = out * BASE + 13;
			}
			elsif (tmp == "E" or tmp == "e"){
				out = out * BASE + 14;
			}
			elsif (tmp == "F" or tmp == "f"){
				out = out * BASE + 14;
			}
			else {
				return nil;
			}
		}
	}
	
	return out;
}
# ********** ********** ********** ********** ********** ********** ********** ********** ********** **********