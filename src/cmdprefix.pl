perl -i -0pe 's/let rec fuzzLoopAux fuel st favored discards favored_queue discard_queue gen0 fuzz0 print prop =\n  \(fun fO fS n -> if n=0 then fO \(\) else fS \(n-1\)\)\n    \(fun _ -> giveUp st\)\n    \(fun fuel\047 ->/let rec fuzzLoopAux fuel st favored discards favored_queue discard_queue gen0 fuzz0 print prop =\n  if fuel = 0 then giveUp st else let fuel\047 = fuel - 1 in/' $1

