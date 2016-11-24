
`timescale 1ns/1ns

module fp_add__tb();

	integer i, j, result_err, bit_err;

	reg [31:0] a, b, s, data[0:30000];
	
	initial begin

		bit_err = 0;
		result_err = 0;

		$readmemh("fp.hex", data);

		for(i=0; i<9998; i=i+1) begin

			a = data[i*3+0];
			b = data[i*3+1];
			s = data[i*3+2];
			#10;

			if(uut.s != s) begin
				result_err = result_err + 1;
			end

			for(j=0; j<32; j=j+1)
				if(s[j] != uut.s[j])
					bit_err = bit_err + 1;
			
		end

		if(result_err) begin
			$write("\n\nTotal Errors in the Results: %4d\n", result_err);
			$write("Total Bit Mismatches in the Results: %d\n", bit_err);
		end
		else
			$write("Waw!! NO ERROR Found. Great Job\n");
	
	end

	fp_adder uut( .a(a), .b(b), .s() );

endmodule



