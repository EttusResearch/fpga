// Simulate an NxM switch configuration
localparam NUM_INPUTS = `N_DIMENSION;
localparam NUM_OUTPUTS = `M_DIMENSION;

//initial $dumpfile("axi_crossbar_tb.vcd");
//initial $dumpvars(0,axi_crossbar_tb);

reg [15:0] x;
//reg [31:0] seq_i0, seq_i1, seq_i2, seq_i3, seq_o0, seq_o1, seq_o2, seq_o3, seq_i4, seq_o4;
reg [31:0] seq_i [0:NUM_INPUTS];
reg [31:0] seq_o [0:NUM_OUTPUTS];


reg sync_flag0, sync_flag1;

integer input_port_in , output_port_in;
integer input_port_out , output_port_out;


/////////////////////////////////////////////
//
// Control and input data thread.
//
/////////////////////////////////////////////
initial
  begin
     // Flags to synchronise test bench threads
     sync_flag0 <= 0;
     sync_flag1 <= 0;

     @(posedge clk);
     reset <= 1;
     repeat (5) @(posedge clk);
     @(posedge clk);
     reset <= 0;
     @(posedge clk);
     // NxM Switch. Populate TCAM so that 4 SID LSB's correspond to output ports.
     // Unused ports will default to egress via port 0.
     // Local crossbar address is 2.
     // Non local packets will egress via port 0.
     // All unprogrammed locations default to value 0.
     //
     // Local Addr = 2
     write_setting_bus(512,2);
     
     // Initialize TCAM for remote addresses
     for (output_port_in = 0; output_port_in < 256; output_port_in = output_port_in + 1) begin
	// Host Addr X.M goes to Slave 0...
	write_setting_bus(output_port_in,0); // x.x goes to Port 0
     end
     // Initialize TCAM for local addresses
     for (output_port_in = 0; output_port_in < 256; output_port_in = output_port_in + 1) begin
	// Host Addr 2.M goes to Slave 0...
	write_setting_bus(256+output_port_in,0); // 2.0 goes to Port 0
     end

     for (output_port_in = 0; output_port_in < NUM_OUTPUTS; output_port_in = output_port_in + 1) begin
	// Host Addr 2.M goes to Slave M...
	write_setting_bus(256+output_port_in,output_port_in); // 2.0 goes to Port 0
     end
     
     // Network Addr 0.x & 1.x go to Slave 0.
     write_setting_bus(0,0);   // 0.X goes to Port 0
     write_setting_bus(1,0);   // 1.X goes to Port 0


     //
     // Begin pushing CHDR packets sequentially into the input ports of the switch.
     // Start with the lowest input port and push one packet in for each of the available output ports.
     // Then move to the next input port until all input ports have been tested.
     // Each of these packets is addressed local to the switch has a non-default match.
    
     @(posedge clk)
       begin
	  for (input_port_in = 0 ; input_port_in < NUM_INPUTS ; input_port_in = input_port_in + 1)
	    for (output_port_in = 0; output_port_in < NUM_OUTPUTS ; output_port_in = output_port_in + 1) begin
	       enqueue_chdr_pkt_count(input_port_in,0/*SEQID*/,32+input_port_in/*SIZE*/,1/*HAS_TIME*/,
				      'h12345678+input_port_in*100/*TIME*/,0/*IS_EXTENSION*/,0/*IS_EOB*/,
				      `SID(0,0,2,output_port_in));
	       @(posedge clk);	       
	    end
       end

     // Spin here and wait on synchronization from receiver process.
     while (sync_flag0 !== 1'b1)
       @(posedge clk);

     //
     // Test "default" forwarding behavior.
     // All these packets should egress via Port0
     //
     @(posedge clk)
       begin
	  for (input_port_in = 0 ; input_port_in < NUM_INPUTS ; input_port_in = input_port_in + 1)
	    enqueue_chdr_pkt_count(input_port_in,0/*SEQID*/,64+input_port_in/*SIZE*/,1/*HAS_TIME*/,
				   'h12345678+input_port_in*100/*TIME*/,0/*IS_EXTENSION*/,0/*IS_EOB*/,
				   `SID(0,0,1,input_port_in));
	  @(posedge clk);	       
       end
     
    @(posedge clk)
       begin
	  for (input_port_in = 0 ; input_port_in < NUM_INPUTS ; input_port_in = input_port_in + 1)
	    enqueue_chdr_pkt_count(input_port_in,0/*SEQID*/,64+input_port_in/*SIZE*/,1/*HAS_TIME*/,
				   'h12345678+input_port_in*100/*TIME*/,0/*IS_EXTENSION*/,0/*IS_EOB*/,
				   `SID(0,0,2,input_port_in+16));
	  @(posedge clk);	       
       end
    
     // Spin here and wait on synchronization from receiver process.
     while (sync_flag1 !== 1'b1)
       @(posedge clk);

/* -----\/----- EXCLUDED -----\/-----

 
     @(posedge clk);
     fork
	begin
	   // Master0 Sender Thread.
	   //
	   // addr 2.3 to Slave3
	   for (seq_i0 = 0; seq_i0 < 10; seq_i0=seq_i0 + 1)
	     enqueue_chdr_pkt_count(0,seq_i0,32+seq_i0,1,'h12345678+seq_i0*100,0,0,`SID(0,0,2,3));

	   while (sync_flag0 !== 1'b1)
	     @(posedge clk);

	   //
	   // addr 2.0 to Slave0
//	   for (seq_i0 = 30; seq_i0 < 40; seq_i0=seq_i0 + 1)
//	     enqueue_chdr_pkt_count(0,seq_i0,32+seq_i0,1,'h45678901+seq_i0*100,0,0,`SID(0,0,2,0));

	end
	begin
	   // Master1 Sender Thread.
	   //
	   // addr 2.2 to Slave2
	   for (seq_i1 = 10; seq_i1 < 20; seq_i1=seq_i1 + 1)
	     enqueue_chdr_pkt_count(1,seq_i1,32+seq_i1,1,'h23456789+seq_i1*100,0,0,`SID(0,0,2,2));


	   while (sync_flag1 !== 1'b1)
	     @(posedge clk);

	   //
	   // addr 2.1 to Slave1
	   for (seq_i1 = 20; seq_i1 < 30; seq_i1=seq_i1 + 1)
	     enqueue_chdr_pkt_count(1,seq_i1,32+seq_i1,1,'h34567890+seq_i1*100,0,0,`SID(0,0,2,1));
	end
	begin
	   // Master2 Sender Thread.
	   //
	   // addr 2.1 to Slave1
	   for (seq_i2 = 20; seq_i2 < 30; seq_i2=seq_i2 + 1)
	     enqueue_chdr_pkt_count(2,seq_i2,32+seq_i2,1,'h34567890+seq_i2*100,0,0,`SID(0,0,2,1));

	   //
	   // addr 2.2 to Slave2
	   for (seq_i2 = 10; seq_i2 < 20; seq_i2=seq_i2 + 1)
	     enqueue_chdr_pkt_count(2,seq_i2,32+seq_i2,1,'h23456789+seq_i2*100,0,0,`SID(0,0,2,2));
	end
	begin
	   // Master3 Sender Thread.
	   //
	   // addr 2.4 to Slave4
	   for (seq_i3 = 30; seq_i3 < 40; seq_i3=seq_i3 + 1)
	     enqueue_chdr_pkt_count(3,seq_i3,32+seq_i3,1,'h56789012+seq_i3*100,0,0,`SID(0,0,2,4));

	   //
	   // addr 2.3 to Slave3
	   for (seq_i3 = 0; seq_i3 < 10; seq_i3=seq_i3 + 1)
	     enqueue_chdr_pkt_count(3,seq_i3,32+seq_i3,1,'h12345678+seq_i3*100,0,0,`SID(0,0,2,3));
	end
	begin
	   // Master4 Sender Thread.
	   //
	   // addr 2.0 to Slave0
//	   for (seq_i4 = 30; seq_i4 < 40; seq_i4=seq_i4 + 1)
//	     enqueue_chdr_pkt_count(4,seq_i4,32+seq_i4,1,'h45678901+seq_i4*100,0,0,`SID(0,0,2,0));

	   //
	   // addr 2.4 to Slave4
//	   for (seq_i4 = 0; seq_i4 < 10; seq_i4=seq_i4 + 1)
//	     enqueue_chdr_pkt_count(4,seq_i4,32+seq_i4,1,'h5678912+seq_i4*100,0,0,`SID(0,0,2,4));
	end

     join
 -----/\----- EXCLUDED -----/\----- */
     
     repeat (1000) @(posedge clk);


  end // initial begin



   /////////////////////////////////////////////
   //
   // Control and input data thread.
   //
   /////////////////////////////////////////////
   
   initial
     begin
	// Wait for reset to go high
	while (reset!==1'b1)
	  @(posedge clk);
	// Wait for reset to go low
	while (reset!==1'b0)
	  @(posedge clk);
	//
	// Sequential output checkers run iteratively for all M egress ports, for N iterations
	//
	for (input_port_out = 0; input_port_out < NUM_INPUTS ; input_port_out = input_port_out + 1)
	  for (output_port_out = 0; output_port_out < NUM_OUTPUTS; output_port_out = output_port_out + 1) begin
	     dequeue_chdr_pkt_count(output_port_out,0/*SEQID*/,32+input_port_out/*SIZE*/,1/*HAS_TIME*/,
				    'h12345678+input_port_out*100/*TIME*/,0/*IS_EXTENSION*/,0/*IS_EOB*/,
				    `SID(0,0,2,output_port_out));

	  end
	// Synchoronize with input test pattern
	$display("Sequential packet routing test complete");
	
	sync_flag0 <= 1'b1;

	//
	// Sequential output checkers run iteratively for all M egress ports, for N iterations
	//
	for (input_port_out = 0; input_port_out < NUM_INPUTS ; input_port_out = input_port_out + 1) begin	   
	   dequeue_chdr_pkt_count(0,0/*SEQID*/,64+input_port_out/*SIZE*/,1/*HAS_TIME*/,
				  'h12345678+input_port_out*100/*TIME*/,0/*IS_EXTENSION*/,0/*IS_EOB*/,
				  `SID(0,0,1,input_port_out));
	end
	for (input_port_out = 0; input_port_out < NUM_INPUTS ; input_port_out = input_port_out + 1) begin	   
	   dequeue_chdr_pkt_count(0,0/*SEQID*/,64+input_port_out/*SIZE*/,1/*HAS_TIME*/,
				  'h12345678+input_port_out*100/*TIME*/,0/*IS_EXTENSION*/,0/*IS_EOB*/,
				  `SID(0,0,2,input_port_out+16));
	end
	// Synchoronize with input test pattern
	$display("Default routing test complete");
		
	sync_flag1 <= 1'b1;

/* -----\/----- EXCLUDED -----\/-----

	
	fork
	  
	   begin
	      // Slave0 Recevier thread.
	      //
	      // addr 2.0 to Slave0
	      for (seq_o0 = 30; seq_o0 < 40; seq_o0=seq_o0 + 1)
		dequeue_chdr_pkt_count(0,seq_o0,32+seq_o0,1,'h45678901+seq_o0*100,0,0,`SID(0,0,2,0));

	      sync_flag0 <= 1'b1;

	      //
	      // addr 2.0 to Slave0
	      for (seq_o0 = 30; seq_o0 < 40; seq_o0=seq_o0 + 1)
		dequeue_chdr_pkt_count(0,seq_o0,32+seq_o0,1,'h45678901+seq_o0*100,0,0,`SID(0,0,2,0));
	   end

	   begin
	      // Slave1 Recevier thread.
	      //
	      // addr 2.1 to Slave1
	      for (seq_o1 = 20; seq_o1 < 30; seq_o1=seq_o1 + 1)
		dequeue_chdr_pkt_count(1,seq_o1,32+seq_o1,1,'h34567890+seq_o1*100,0,0,`SID(0,0,2,1));

	      sync_flag1 <= 1'b1;

	      //
	      // addr 2.1 to Slave1
	      for (seq_o1 = 20; seq_o1 < 30; seq_o1=seq_o1 + 1)
		dequeue_chdr_pkt_count(1,seq_o1,32+seq_o1,1,'h34567890+seq_o1*100,0,0,`SID(0,0,2,1));
	   end

	   begin
	      // Slave2 Recevier thread.
	      //
	      // addr 2.2 to Slave2
	      for (seq_o2 = 10; seq_o2 < 20; seq_o2=seq_o2 + 1)
		dequeue_chdr_pkt_count(2,seq_o2,32+seq_o2,1,'h23456789+seq_o2*100,0,0,`SID(0,0,2,2));
	      //
	      // addr 2.2 to Slave2
	      for (seq_o2 = 10; seq_o2 < 20; seq_o2=seq_o2 + 1)
		dequeue_chdr_pkt_count(2,seq_o2,32+seq_o2,1,'h23456789+seq_o2*100,0,0,`SID(0,0,2,2));
	   end

	   begin
	      // Slave3 Recevier thread.
	      //
	      // addr 2.3 to Slave3
	      for (seq_o3 = 0; seq_o3 < 10; seq_o3=seq_o3 + 1)
		dequeue_chdr_pkt_count(3,seq_o3,32+seq_o3,1,'h12345678+seq_o3*100,0,0,`SID(0,0,2,3));
	      //
	      // addr 2.3 to Slave3
	      for (seq_o3 = 0; seq_o3 < 10; seq_o3=seq_o3 + 1)
		dequeue_chdr_pkt_count(3,seq_o3,32+seq_o3,1,'h12345678+seq_o3*100,0,0,`SID(0,0,2,3));
	   end // fork branch
	   
	   begin
	      // Slave4 Recevier thread.
	      //
	      // addr 2.4 to Slave4
	      for (seq_o4 = 30; seq_o4 < 40; seq_o4=seq_o4 + 1)
		dequeue_chdr_pkt_count(4,seq_o4,32+seq_o4,1,'h56789012+seq_o4*100,0,0,`SID(0,0,2,4));
	      //
	      // addr 2.4 to Slave4
	      for (seq_o4 = 0; seq_o4 < 10; seq_o4=seq_o4 + 1)
		dequeue_chdr_pkt_count(4,seq_o4,32+seq_o4,1,'h56789012+seq_o4*100,0,0,`SID(0,0,2,4));
	   end


	join
 -----/\----- EXCLUDED -----/\----- */

	repeat (1000) @(posedge clk);
	$finish;
     end // initial begin

   // Watchdog timer in case simulation goes bad. (96uS at 125MHz)
   initial
     begin
	repeat (12000) @(posedge clk);
	$display("FAILED: Simulation Watchdog Timeout @ 12000 clk cycles");
	$finish;
     end 
