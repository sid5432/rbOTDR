#!/usr/bin/ruby

$:.push File.dirname(__FILE__)
require 'parts'

module Supparams
  def self.sep 
    return "    :"
  end
  
  def self.process(fh, results, debug=false)
    
    if $logger == nil then
      $logger = Logger.new(STDOUT)
    end
    
    bname = "SupParams"
    hsize = bname.length + 1 # include trailing '\0'
    pname = "Supparams::process():"
    ref = nil
    status = 'nok'
    
    begin
      ref = results['blocks'][bname]
      startpos = ref[:pos].to_i
      fh.seek( startpos )
    rescue
      $logger.info (pname+" "+bname+"block starting position unknown")
      return status
    end
    
    format = results['format']
    
    if format == 2 then
      mystr = fh.read(hsize).to_s[0..-2]
      if mystr != bname then
	$logger.info (pname+" incorrect header "+mystr)
	return status
      end
    end
    
    results[bname] = {}
    xref = results[bname]
    
    # version 1 and 2 are the same
    status = Supparams::process_genparam(fh, results, debug=debug)
    
    # read the rest of the block (just in case)
    endpos = (results['blocks'][bname][:pos].to_i) + (results['blocks'][bname][:size].to_i)
    fh.read( endpos - fh.tell() )
    return 'ok'
    
  end
  
  # ================================================================
  def self.process_genparam(fh, results, debug=false)
    # process SupParams fields
    bname = "SupParams"
    xref  = results[bname]
    
    fields = 
    [
    "supplier", # ............. 0
    "OTDR", # ................. 1
    "OTDR S/N", # ............. 2
    "module", # ............... 3
    "module S/N", # ........... 4
    "software", # ............. 5
    "other", # ................ 6
    ]
  
    count = 0
    fields.each do |field|
      xstr = Parts::get_string(fh)
      if debug then
	$logger.info ("%s %d. %s: %s" % [sep, count, field, xstr] )
      end        
      xref[field] = xstr
      count += 1
    end
    
    return 'ok'
  end
end
