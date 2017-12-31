#!/usr/bin/ruby
require 'test/unit'
require 'json'

$:.push File.dirname(__FILE__)+"/.."

require 'parts'
require 'read'
require 'dump'

class CB_test_read < Test::Unit::TestCase
  def setup
    @@jsonfile = ""
  end
  
  def teardown
    # puts "* remove "+@@jsonfile
    File.delete @@jsonfile
  end
  
  def mycompare(sor_filename)
    
    filename = __dir__+"/../data/"+sor_filename
    fh = Parts::Sorfile.new(filename)
    assert( fh != nil, 'open file handler failed' )
    
    $logger = Logger.new('/dev/null')
    sorparse = SORparse.new( filename )
    results = {}
    trace = []
    status = sorparse.run(results, trace, debug=true)
    
    assert status == 'ok'
    
    # load and compare JSON file
    basefile = File.basename( filename, ".*" )
    newfile = basefile+"-dump2.json"
    Dump::jsonfile(results, newfile)
    
    # load expected (old) file
    oldfile = __dir__+"/../data/"+basefile+"-dump.json"
    
    # puts "* target "+oldfile
    # puts "* source "+newfile
    @@jsonfile = newfile

    newhash = JSON.parse( File.read(newfile) )
    oldhash = JSON.parse( File.read(oldfile) )

    assert newhash == oldhash
  end
  
  def test_read1
    mycompare "demo_ab.sor"
    return
  end
  
  def test_read2
    mycompare("sample1310_lowDR.sor")
    return
  end
  
  def test_read3
    mycompare("M200_Sample_005_S13.sor")
    return
  end
  
end
