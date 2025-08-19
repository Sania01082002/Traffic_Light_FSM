module traffic_light_fsm(
  input rst,
  input clk,
  output reg ns_green, ns_yellow, ns_red,
  output reg ew_green, ew_yellow, ew_red
);
  
  parameter NS_GREEN = 2'b00;
  parameter NS_YELLOW = 2'b01;
  parameter EW_GREEN = 2'b10;
  parameter EW_YELLOW = 2'b11;
  
  reg[1:0] current_state,next_state;
  reg[3:0] timer;
  
  always@(*) 
    begin
      case(current_state)
      NS_GREEN:begin
        if(timer==0)
          next_state = NS_YELLOW;
        else
          next_state = NS_GREEN;
      end
      
      NS_YELLOW:begin
        if(timer==0)
          next_state = EW_GREEN;
        else
          next_state = NS_YELLOW;
      end
          
      EW_GREEN:begin
        if(timer==0)
          next_state = EW_YELLOW;
        else
          next_state = EW_GREEN;
      end
          
      EW_YELLOW:begin
        if(timer==0)
          next_state = NS_GREEN;
        else
          next_state = EW_YELLOW;
      end
          
       default: next_state = NS_GREEN;   
    endcase
  end
        
        
  always@(posedge clk or posedge rst)
    begin
    if(rst) 
      begin
        current_state <= NS_GREEN;
        timer <= 10;
      end
     else
       begin
         current_state <= next_state;
         if(timer==0)
           begin
             case(next_state)
               NS_GREEN,EW_GREEN:timer <= 10;
               NS_YELLOW,EW_YELLOW:timer <= 3;
               default:timer <= 10;
             endcase
           end
         else
           begin
             timer <= timer-1;
           end
       end
      end
        
 always@(*) begin
   ns_green = 0; ns_yellow = 0; ns_red = 0;
   ew_green = 0; ew_yellow = 0; ew_red = 0;
   case(current_state)
     NS_GREEN:begin
       ns_green=1; ew_red=1;
     end
     NS_YELLOW:begin
       ns_yellow=1;ew_red=1;
     end
     EW_GREEN:begin
       ew_green=1; ns_red=1;
     end
     EW_YELLOW:begin
       ew_yellow=1; ns_red=1;
     end
   endcase
 end
endmodule
