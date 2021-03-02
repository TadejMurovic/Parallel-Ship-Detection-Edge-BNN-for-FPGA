function BrainInput = evalbnn(Brain, BrainInput, L)
    for l = 1:L
       BrainInput = sum(~xor(BrainInput,Brain.l(l).w')')>=(Brain.l(l).th); 
    end
end