#!/usr/bin/ruby
require 'test/unit'
require 'crc'
$:.push File.dirname(__FILE__)+"/.."

require 'cksum'
require 'read'

class CB_test_cksum < Test::Unit::TestCase
  # def setup
  # end
  
  # def teardown
  # end
  
  def crc16_ccitt(data)
    # Calculate the CRC16 CCITT checksum of *data*.
    crc = CRC.crc16_ccitt_false.new
    x = crc.update data
    digest = x.crc
    return digest
  end
  
  def test_cksum
    # sanity check algorithm
    digest = crc16_ccitt("123456789")
    
    assert digest == 0x29B1
    
    filename = __dir__+"/../data/demo_ab.sor"
    data = IO.binread(filename)
    
    assert data.length == 25708
    
    file_chk = data[-1].ord()*256 + data[-2].ord()
    
    assert file_chk == 38827
    
    newdata = data[0..-3]
    
    digest = crc16_ccitt(newdata)
    
    assert digest == file_chk
    
    $logger = Logger.new('/dev/null')
    sorparse = SORparse.new( filename )
    results = {}
    trace = []
    status = sorparse.run(results, trace, debug=true)
    
    assert results['Cksum']['checksum_ours'] == digest
    
    # SOR version 2
    filename = __dir__+"/../data/sample1310_lowDR.sor"
    sorparse = SORparse.new( filename )
    results = {}
    trace = []
    status = sorparse.run(results, trace, debug=true)
    
    assert results['Cksum']['checksum_ours'] == 62998
    assert results['Cksum']['checksum'] == 59892
    
    return
  end
end

=begin
require 'digest/crc16_ccitt'

crc = Digest::CRC16CCITT

x = crc.hexdigest '123456789'
puts "test "+x

filename = "../data/demo_ab.sor"
# filename = "../data/sample1310_lowDR.sor"

puts "reading file "+filename

# buffer = File.open(filename,'rb') { |io| io.read }
buffer = IO.binread(filename)

# remove last two bytes!
buffer = buffer[0..-3]

puts "file length "+buffer.length.to_s

x = crc.hexdigest buffer
puts "file "+x
=end

