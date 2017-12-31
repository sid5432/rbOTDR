#!/usr/bin/ruby
require 'test/unit'

$:.push File.dirname(__FILE__)+"/.."

require 'parts'
require 'read'

class CB_test_map < Test::Unit::TestCase
  # def setup
  # end
  
  # def teardown
  # end
  
  def test_map
    filename = __dir__+"/../data/demo_ab.sor"
    fh = Parts::Sorfile.new(filename)
    assert( fh != nil, 'open file handler failed' )
    
    $logger = Logger.new('/dev/null')
    sorparse = SORparse.new( filename )
    results = {}
    trace = []
    status = sorparse.run(results, trace, debug=true)

    assert(status == 'ok', 'failed to run demo_ab.sor')
    
    # map block
    ref = results['blocks']
    assert( ref['Cksum'][:pos] == 25706, 'cksum pos error' )
    assert( ref['Cksum'][:version] == "1.00", 'cksum version error' )

    assert( ref['DataPts'][:pos] == 328, 'datapts pos error' )
    assert( ref['DataPts'][:size] == 23564, 'datapts size error' )

  end
  
end

