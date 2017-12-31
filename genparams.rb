#!/usr/bin/ruby
$:.push File.dirname(__FILE__)
require 'parts'

module Genparams
  @@sep = "    :"
  
  def self.process(fh, results, debug=false)
    
    if $logger == nil then
      $logger = Logger.new(STDOUT)
    end
    
    bname = "GenParams"
    hsize = bname.length + 1 # include trailing '\0'
    pname = "Genparam::process():"
    ref = nil
    status = 'nok'
    
    begin
      ref = results['blocks'][bname]
      startpos = ref[:pos].to_i
      fh.seek( startpos )
    rescue
      $logger.info ( pname+" "+bname+"block starting position unknown")
      return status
    end
    
    format = results['format']
    
    if format == 2 then
      mystr = fh.read(hsize).to_s[0..-2]
      if mystr != bname then
	$logger.info (pname + " incorrect header '" +mystr+"' vs '"+bname+"'")
	return status
      end
    end
    
    results[bname] = {}
    xref = results[bname]
    
    if format == 1 then
      status = Genparams::process1(fh, results, debug=debug)
    else
      status = Genparams::process2(fh, results, debug=debug)
    end
    # read the rest of the block (just in case)
    endpos = (results['blocks'][bname][:pos].to_i) + (results['blocks'][bname][:size].to_i)
    fh.read( endpos - fh.tell() )
    
    return status
  end
  
  # ================================================================
  def self.build_condition(bcstr)
    # decode build condition
    if bcstr == 'BC' then
      bcstr += " (as-built)"
    elsif bcstr == 'CC' then
      bcstr+= " (as-current)"
    elsif bcstr == 'RC' then
      bcstr+= " (as-repaired)"
    elsif bcstr == 'OT' then
      bcstr+= " (other)"
    else
      bcstr+= " (unknown)"
    end
    
    return bcstr
  end
  
  # ================================================================
  def self.fiber_type(val)
    # decode fiber type 
    # REF: http://www.ciscopress.com/articles/article.asp?p=170740&seqNum=7
    #
    if val == 651 then # ITU-T G.651
      fstr = "G.651 (50um core multimode)"
    elsif val == 652 then # standard nondispersion-shifted
      fstr = "G.652 (standard SMF)"
      # G.652.C low Water Peak Nondispersion-Shifted Fiber            
    elsif val == 653 then
      fstr = "G.653 (dispersion-shifted fiber)"
    elsif val == 654 then
      fstr = "G.654 (1550nm loss-minimzed fiber)"
    elsif val == 655 then
      fstr = "G.655 (nonzero dispersion-shifted fiber)"
    else
      fstr = "%d (unknown)" % [val]
    end
    
    return fstr
  end
  
  # ================================================================
  def self.process1(fh, results, debug=false)
    # process version 1 format
    bname = "GenParams"
    xref  = results[bname]
    
    lang = fh.read(2)
    xref['language'] = lang
    if debug then
      $logger.info ("%s  language: '%s', next pos %d" % [@@sep, lang, fh.tell()] )
    end
    
    fields = 
    [
    "cable ID",    # ........... 0
    "fiber ID",    # ........... 1
    "wavelength",  # ............2: fixed 2 bytes value
    
    "location A", # ............ 3
    "location B", # ............ 4
    "cable code/fiber type", # ............ 5
    "build condition", # ....... 6: fixed 2 bytes char/string
    "user offset", # ........... 7: fixed 4 bytes (Andrew Jones)
    "operator",    # ........... 8
    "comments",    # ........... 9
    ]
    
    count = 0
    fields.each do |field|
      if field == 'build condition' then
	xstr = Genparams::build_condition( fh.read(2) )
      elsif field == 'wavelength' then
	val = Parts::get_uint(fh, 2)
	xstr = "%d nm" % val
      elsif field == "user offset" then
	val = Parts::get_signed(fh, 4)
	xstr = "%d" % val
      else
	xstr = Parts::get_string(fh)
      end
      
      if debug then
	$logger.info ( "%s %d. %s: %s" % [@@sep, count, field, xstr] )
      end        
      
      xref[field] = xstr
      count += 1
    end
    
    return 'ok'
  end
  
  # ================================================================
  def self.process2(fh, results, debug=False)
    # process version 2 format
    bname = "GenParams"
    xref  = results[bname]
    
    lang = fh.read(2)
    xref['language'] = lang
    if debug then
      $logger.info ("%s  language: '%s', next pos %d" % [@@sep, lang, fh.tell()] )
    end
    
    fields = 
    [
    "cable ID",    # ........... 0
    "fiber ID",    # ........... 1
    
    "fiber type",  # ........... 2: fixed 2 bytes value
    "wavelength",  # ............3: fixed 2 bytes value
    
    "location A", # ............ 4
    "location B", # ............ 5
    "cable code/fiber type", # ............ 6
    "build condition", # ....... 7: fixed 2 bytes char/string
    "user offset", # ........... 8: fixed 4 bytes int (Andrew Jones)
    "user offset distance", # .. 9: fixed 4 bytes int (Andrew Jones)
    "operator",    # ........... 10
    "comments",    # ........... 11
    ]
    
    count = 0
    fields.each do |field|
      if field == 'build condition' then
	xstr = Genparams::build_condition( fh.read(2) )
      elsif field == 'fiber type' then
	val = Parts::get_uint(fh, 2)
	xstr = Genparams::fiber_type( val )
      elsif field == 'wavelength' then
	val = Parts::get_uint(fh, 2)
	xstr = "%d nm" % val
      elsif field == "user offset" or field == "user offset distance" then
	val = Parts::get_signed(fh, 4)
	xstr = "%d" % val
      else
	xstr = Parts::get_string(fh)
      end
      
      if debug then
	$logger.info ("%s %d. %s: %s" % [@@sep, count, field, xstr] )
      end
      xref[field] = xstr
      count += 1
    end
    
    return 'ok'
  end
  
end
