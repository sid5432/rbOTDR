clean:
	rm -f Makefile.bak *-trace.dat *~ test/*~ *-dump.json

realclean: clean
	rm -rf *.json

test1:
	./rbOTDR.rb data/demo_ab.sor
	
test2:
	./rbOTDR.rb data/sample1310_lowDR.sor
	
testall:
	echo "run tests in test/"
	./tests/runall.rb

