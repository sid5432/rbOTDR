#!/usr/bin/ruby
require 'test/unit'

$:.push File.dirname(__FILE__)+"/.."

require 'parts'
require 'read'

class CB_test_part < Test::Unit::TestCase
  # def setup
  # end
  
  # def teardown
  # end
  
  def file1
    # SOR version 1 file
    filename = __dir__+"/../data/demo_ab.sor"
    return filename
  end
  
  def file2
    # SOR version 2 file
    filename = __dir__+"/../data/sample1310_lowDR.sor"
    return filename
  end
  
  # -------------------------------------------------------
  def test_get_string
    # test get_string
    filename = file2
    fh = Parts::Sorfile.new( filename )
    assert( fh != nil )
    
    mystr = Parts::get_string(fh)
    assert( mystr == 'Map' )
    
    assert( fh.tell() == 4 )
    
    return
  end
  
  # -------------------------------------------------------
  def test_get_uint
    # test get_unsigned int (2 or 4)
    filename = file1
    fh = Parts::Sorfile.new( filename )
    assert( fh != nil )
    
    val = Parts::get_uint(fh,2)
    assert( val == 100 )
    assert( fh.tell() == 2 )

    val = Parts::get_uint(fh,4)
    assert( val == 148 )
    assert( fh.tell() == 6 )
    
    return
  end

  # -------------------------------------------------------
  def test_get_hex
    # test hex conversion
    filename = file1
    fh = Parts::Sorfile.new( filename )
    assert( fh != nil )
    
    hstr = Parts::get_hex(fh, 8)
    assert( hstr == "64 00 94 00 00 00 0A 00 " )
    return
  end
  
  # -------------------------------------------------------
  def test_get_signed
    # test signed integer conversion
    filename = file2
    fh = Parts::Sorfile.new( filename )
    assert( fh != nil )
    
    fh.seek(461)
    fstr = Parts::get_signed(fh,2)
    assert( fstr == 343 )
    
    fstr = Parts::get_signed(fh,2)
    assert fstr == 22820
    
    fstr = Parts::get_signed(fh,4)
    assert fstr == -38395
    
    fstr = Parts::get_signed(fh,8)
    assert fstr == 6002235321314002225
    
    return
  end
  
end

