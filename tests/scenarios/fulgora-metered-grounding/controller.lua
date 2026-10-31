-- Native combinators select binary banks from sampled offered power and demand.
-- Each bank changes at most once per sample, after the selection pipeline settles.
return function(sensor,place,wire,step,banks)
  local ids=defines.wire_connector_id
  local function sig(letter) return {type='virtual',name='signal-'..letter} end
  local count=0
  local function entity(name)
    count=count+1
    return place(name,430+(count-1)%8*3,24+math.floor((count-1)/8)*3,false)
  end
  local function arith(first,operation,constant,out)
    local e=entity('arithmetic-combinator')
    e.get_or_create_control_behavior().parameters={first_signal=sig(first),operation=operation,
      second_constant=constant,output_signal=sig(out)}
    return e
  end
  local function decider(conditions,out,constant,networks)
    local e=entity('decider-combinator')
    e.get_or_create_control_behavior().parameters={conditions=conditions,outputs={{signal=sig(out),
      copy_count_from_input=constant==nil,constant=constant,networks=networks}}}
    return e
  end
  local function condition(s,comparison,value,join)
    return {first_signal=sig(s),comparator=comparison,constant=value,compare_type=join}
  end
  local function red(a,b) wire(a,ids.combinator_output_red,b,ids.combinator_input_red) end
  local function green(a,b) wire(a,ids.combinator_output_green,b,ids.combinator_input_green) end
  -- T+1: three terms sum to Y = O - 2D + 2*step*h.
  local offered=arith('O','+',0,'Y')
  local demand=arith('D','*',-2,'Y')
  local bankload=arith('H','*',2*step,'Y')
  wire(sensor,ids.circuit_red,offered,ids.combinator_input_red)
  wire(sensor,ids.circuit_red,demand,ids.combinator_input_red)
  local numerator=arith('Y','+',2*step+1,'W')
  red(offered,numerator);red(demand,numerator);red(bankload,numerator)
  local positive=decider({condition('W','>',0)},'W')
  local divide=arith('W','/',2*step,'N')
  red(numerator,positive);red(positive,divide)
  local maximum=2^banks-1
  local small=decider({condition('N','≤',maximum)},'N')
  local large=decider({condition('N','>',maximum)},'N',maximum)
  red(divide,small);red(divide,large)
  local candidate=arith('N','+',0,'H')
  red(small,candidate);red(large,candidate)
  -- T+2: one pulse if O or D changes. Five delays align it after candidate T+6.
  local oldO=arith('O','*',-1,'O')
  local oldD=arith('D','*',-1,'D')
  wire(sensor,ids.circuit_red,oldO,ids.combinator_input_red)
  wire(sensor,ids.circuit_red,oldD,ids.combinator_input_red)
  local edge=decider({condition('O','≠',0),condition('D','≠',0,'or')},'E',1)
  wire(sensor,ids.circuit_red,edge,ids.combinator_input_red)
  green(oldO,edge);green(oldD,edge)
  for _=1,5 do local delay=arith('E','+',0,'E');red(edge,delay);edge=delay end
  local hold=decider({condition('E','=',0)},'H',nil,{red=false,green=true})
  local set=decider({condition('E','>',0)},'H',nil,{red=true,green=false})
  red(edge,hold);red(edge,set);red(candidate,set)
  green(hold,hold);green(set,hold)
  green(hold,bankload)
  local outputs={}
  for i=1,banks do
    outputs[i]=arith('H','AND',2^(i-1),'S')
    green(hold,outputs[i])
  end
  return outputs,hold
end
