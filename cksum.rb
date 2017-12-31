#!/usr/bin/ruby
$:.push File.dirname(__FILE__)
require 'parts'

module Cksum
  @@sep = "    :"
  
  def self.process(fh, results, debug=false)
    
    if $logger == nil then
      $logger = Logger.new(STDOUT)
    end

    bname = "Cksum"
    hsize = bname.length + 1 # include trailing '\0'
    pname = "Cksum::process():"
    ref = nil
    status = 'nok'
    
    begin
      ref = results['blocks'][bname]
      startpos = ref[:pos]
      fh.seek( startpos )
    rescue
      $logger.info(pname+" "+bname+"block starting position unknown")
      return status
    end
    
    format = results['format']
    
    if format == 2 then
      mystr = fh.read(hsize).to_s[0..-2]
      if mystr != bname then
	$logger.info(pname+" incorrect header "+ mystr)
	return status
      end
    end
    
    results[bname] = {}
    xref = results[bname]
    
    # before reading the (file) checksum, get the cumulative checksum
    xref['checksum_ours'] = digest = fh.digest()
    csum = xref['checksum'] = Parts::get_uint(fh, 2)
    
    if digest == csum then
      xref['match'] = true
      verdict = "MATCHES!"
    else
      xref['match'] = false
      verdict = "DOES NOT MATCH!"
    end
    
    if debug then
      $logger.info("%s checksum from file %d (0x%X)" % [@@sep, csum, csum])
      $logger.info("%s checksum calculated %d (0x%X) %s" % [@@sep, digest, digest, verdict])
    end
    
    status = 'ok'
    return status
  end
end
