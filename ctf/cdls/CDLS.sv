// keyboard matrix, width = 6 keys, height = 5 keys
parameter MATRIX_WIDTH = 6;
parameter MATRIX_HEIGHT = 5;
parameter MATRIX_WBITS = 3; //ceil(ln(MATRIX_WIDTH)/ln(2));
parameter MATRIX_HBITS = 3; //ceil(ln(MATRIX_HEIGHT)/ln(2));
parameter KEY_BITSZ = MATRIX_WBITS + MATRIX_HBITS;
parameter MAX_PW_LEN = 255;
`define DEBUG_DISPLAY(_args) $display("%s", $sformatf _args);
/* verilator tracing_off */
/* verilator lint_off DECLFILENAME */
module InputMatrix(
		   input logic [3:0] 	  mw,
		   input logic [3:0] 	  mh,
		   output logic 	  is_enter_pressed,
		   output logic [6 - 1:0] keycode);
   assign keycode = 5 * {2'b0, mw} + {2'b0, mh};
   assign is_enter_pressed = keycode == 1;
endmodule
module CircuitLocked(
		     input logic  password_was_set_up,
		     input logic  is_enter_pressed,
		     input logic  do_eval,
		     input logic  correct_password_entered,
		     output logic locked
		     );
   // Door is locked when a password is set up and the xor sum is not equal to zero (unless nothing has been entered so far, then it is always 0).
   always_comb begin
      locked = 0;
      // If the password was set up, check whether the current entered password is correct.
      if (password_was_set_up) 
        locked = (is_enter_pressed && do_eval) ? !correct_password_entered : 1;
      
   end
endmodule
module CircuitBitmask(
		      input wire [KEY_BITSZ - 1:0] input_,
		      input logic [31:0] 	   bitmask,
		      input logic 		   has_input,
		      input logic 		   is_enter_pressed,
		      output logic [31:0] 	   bitmask_n);
   // If enter was pressed, reset it to zero, otherwise check if new button is pressed and add it to the bitmask. Otherwise keep original state.
   always_comb begin
      bitmask_n = bitmask;
      if (has_input)
        if (is_enter_pressed)
          bitmask_n = 0;
        else
          bitmask_n = bitmask ^ (1 << input_);
   end
endmodule
module CircuitIndex(
		    input logic        has_input,
		    input logic        is_enter_pressed,
		    input logic [7:0]  current_idx,
		    output logic [7:0] current_idx_n);
   always_comb begin
      current_idx_n = current_idx;
      if (has_input) begin
         if (is_enter_pressed)
           // 'ENTER' pressed
           current_idx_n = 0;
         else if (!is_enter_pressed)
           // Some character pressed
           current_idx_n = current_idx + 1;
      end
   end
endmodule
/* verilator lint_on DECLFILENAME */
module CDLS(
	    input logic [MATRIX_WBITS:0] matrix_w,
	    input logic [MATRIX_HBITS:0] matrix_h,
	    // any button was just pressed
	    input logic 		 do_eval,
	    // reset
	    input logic 		 rst,
	    // door still locked?
	    output logic 		 locked,
	    output logic [31:0] 	 lights
	    );
   InputMatrix input_decoder(
			     .mw(matrix_w),
			     .mh(matrix_h),
			     .is_enter_pressed(is_enter_pressed),
			     .keycode(input_)
			     );
   logic [KEY_BITSZ - 1:0] 		 xor_sum;
   // Current index when entering the key
   logic [7:0] 				 current_idx;
   logic [7:0] 				 current_idx_n;
   // Bitmask containing
   logic [31:0] 			 bitmask;
   logic [31:0] 			 bitmask_n;
   assign lights = is_enter_pressed ? (bitmask != stored_bitmask ? (bitmask ^ stored_bitmask) : {26'b0, xor_sum}) : 0;
   // The password was signed up when a key is set
   wire 				 password_was_set_up;
   assign password_was_set_up = (stored_bitmask != 0);
   wire 				 is_enter_pressed;
   wire [KEY_BITSZ - 1:0] 		 input_;
   wire 				 has_input;
   assign has_input = input_ != 0;
   // Store bitmask key.
   logic [31:0] 			 stored_bitmask;
   logic [31:0] 			 stored_bitmask_n;
   // Store complete flag.
   logic 				 store_input;
   logic [KEY_BITSZ - 1:0] 		 inputs [MAX_PW_LEN - 1:0];
   // For comparing the inputs
   //logic [KEY_BITSZ - 1:0] xor_sum;
   logic [KEY_BITSZ - 1:0] 		 xor_sum_n;
   // Used for checking whether the door should open on ENTER.
   wire 				 correct_password_entered;
   assign correct_password_entered = stored_bitmask == bitmask && xor_sum == 0;
   CircuitIndex c_index(has_input, is_enter_pressed, current_idx, current_idx_n);
   CircuitBitmask c_bitmask(input_, bitmask, has_input, is_enter_pressed, bitmask_n);
   CircuitLocked c_locked(password_was_set_up, is_enter_pressed, do_eval, correct_password_entered, locked);
   always_comb begin
      xor_sum_n = xor_sum;
      stored_bitmask_n = stored_bitmask;
      store_input = 0;
      if (current_idx == 0)
        xor_sum_n = 0;
      if (has_input) begin
         if (is_enter_pressed) begin
            if (bitmask != 0) begin
               xor_sum_n = 0;
               if (password_was_set_up == 0) begin
                  // Store the password
                  stored_bitmask_n = bitmask;
               end else if (correct_password_entered) begin
                  // Password was correct, remove stored bitmask to indicate empty password
                  stored_bitmask_n = 0; 
               end
            end
         end else begin
            if (password_was_set_up == 0) begin
               // user is configuring the secret
               store_input = 1;
            end else begin
               // user is checking the secret
               xor_sum_n = xor_sum | (input_ ^ inputs[current_idx]);
            end
         end
      end
   end
   always_ff @(posedge do_eval) begin
      `DEBUG_DISPLAY(("locked = %b, passwort_set = %b | idx = %d | input = %b | bitmask = %b | stored_bitmask = %b | xorsum = %b", locked, password_was_set_up, current_idx, input_, bitmask, stored_bitmask, xor_sum));
      current_idx <= rst ? 0 : current_idx_n;
      bitmask <= rst ? 0 : bitmask_n;
      xor_sum <= rst ? 0 : xor_sum_n;
      stored_bitmask <= rst ? 0 : stored_bitmask_n;
      if (store_input)
        inputs[current_idx] <= input_;
   end
   
endmodule
/* verilator tracing_on */
