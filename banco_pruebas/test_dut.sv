interface fifo#(parameter depth = 16,parameter bits = 32)(input bit clk);
logic [bits-1:0] D_in;
logic [bits-1:0] D_out;
logic push;
logic pop;
logic full;
logic pndgn;
logic rst;
endinterface

class transaction#(parameter depth = 16,parameter bits = 32);
rand bit [bits-1:0] D_in;
bit [bits-1:0] D_out;
rand bit push;
rand bit pop;
bit full;
bit pndgn;
endclass

class generator;
event drv_done;
mailbox drv_box;
int num=20;

task run();
for(int i=0; i<num; i++)begin
transaction t=new();
t.randomize();
$display("[%t][generator] transaccion numero %d",$time, i);
drv_box.put(t);
@(drv_done);
end
$display("[%t][Generator] generation done of %0d items",$time,num);
endtask
endclass

class driver#(parameter bits=32, depth=16);
event drv_done;
mailbox drv_box;
virtual fifo vif;
int counter;
bit [bits-1:0] queue [$:depth];
bit condicion;

task run();
$display("[%0t] [Driver] starting", $time);
@(posedge vif.clk);
$display("[%0t] [Driver] waiting for item", $time);

forever begin
transaction t;
drv_box.get(t);
vif.D_in <= t.D_in;
vif.push <= t.push;
vif.pop <= t.pop;
condicion= {vif.push,vif.pop};
assert(vif.rst)begin
queue.delete();
end
assert(condicion==2'b10)begin
queue.push_back(vif.D_in);
counter=counter+1;
end
assert(condicion==2'b01)begin
vif.D_out=queue.pop_front();
counter=counter+1;
end
assert(condicion==2'b00 || condicion==2'b11)begin
counter=counter;
end
assign vif.pndgn=(counter==0)?1'b1:1'b0;
assign vif.full=(counter==depth)?1'b1:1'b0;
@(posedge vif.clk)
->drv_done;
end
endtask
endclass
