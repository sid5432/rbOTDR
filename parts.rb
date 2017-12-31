#!/usr/bin/ruby
require 'crc'

module Parts
  def self.divider
    return "--------------------------------------------------------------------------------"
  end
  # speed of light
  @@SOL =299792.458/1.0e6 # = 0.299792458 km/usec
  
  def self.SOL
    return @@SOL
  end
  
  class Sorfile
    
    attr_reader :fh, :buffer, :cksum
    
    def digest
      # return @@cksum.hexdigest
      return @@cksum.crc
    end
    
    def initialize(filename)
      if $logger == nil then
	$logger = Logger.new(STDOUT)
      end
      
      @fh0 = File.open(filename,"rb")
      @buffer = ""
      
      # for calculating crc-sum
      @@crc = CRC.crc16_ccitt_false.new
      @@cksum = 0xFFFF # initial
    end
    
    def read(size)
      buf = @fh0.read(size)
      @@cksum = @@crc.update buf
      return buf
    end
    
    def seek(pos)
      @fh0.seek(pos)
      if pos == 0 then
	# rewind occurred; reset
	@@crc = CRC.crc16_ccitt_false.new
      end
    end
    
    def tell()
      return @fh0.tell()
    end
  end
  
  # -------------------------------------------------
  def self.get_string(fh)
    mystr = ""
    byte = fh.read(1)
    while byte != '' do
      if byte.ord() == 0 then
	break
      end
      mystr += byte
      byte = fh.read(1)
    end
    
    return mystr
  end
  
  # -------------------------------------------------
  def self.get_uint(fh, nbytes=2)
    word = fh.read(nbytes)
    if nbytes == 2 then
      # 16-bit unsigned, little-endian
      val = word.unpack('S<')
    elsif nbytes == 4 then
      # 32-bit unsigned, little-endian
      val = word.unpack('L<')
    else
      val = nil
      $logger.error "parts.get_unit(): Invalid number of bytes #{nbytes}"
    end
    
    return val[0]
  end

  # -----------------------------------------------------
  def self.get_signed(fh, nbytes=2)
    # get signed int (little endian), 2 bytes by default
    # (assume nbytes is positive)
    
    word = fh.read(nbytes)
    if nbytes == 2 then
      # unsigned short 16-bit
      val = word.unpack("s<")
    elsif nbytes == 4 then
      # unsigned int 32-bit
      val = word.unpack("l<");
    elsif nbytes == 8 then
      # unsigned long long 64-bit
      val = word.unpack("q<")
    else
      val = None
      $logger.info ("parts.get_signed(): Invalid number of bytes "+nbytes.to_s)
    end
    
    return val[0]
  end

  # -----------------------------------------------------
  def self.get_hex(fh, nbytes=1)
    # get nbyte bytes (1 by default)
    # and display as hexidecimal
    hstr = ""
    1.upto(nbytes) do |i|
      b = "%02X " % fh.read(1).ord()
      hstr += b
    end
    return hstr
  end
  
  # -----------------------------------------------------
  def self.slurp(fh, bname, results, debug=False)
    # fh: file handle;
    # results: dict for results;
    #
    # just read this block without processing
    status = 'nok'
    
    begin
      ref = results['blocks'][bname]
      startpos = ref[:pos]
      fh.seek( startpos )
    rescue
      $logger.info (pname+" "+bname+"block starting position unknown")
      return status
    end
    
    nn = ref[:size]
    # print "Block size ",nn
    
    fh.read(nn)
    
    status = 'ok'
    return status
  end
end
