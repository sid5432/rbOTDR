#!/usr/bin/ruby
$:.push File.dirname(__FILE__)
require 'parts'

module Datapts
  @@sep = "    :"
  
  def self.process(fh, results, tracedata, debug=false)
    
    if $logger == nil then
      $logger = Logger.new(STDOUT)
    end
    
    bname = "DataPts"
    hsize = bname.length + 1 # include trailing '\0'
    pname = "Datapts::process():"
    ref = nil
    status = 'nok'

    begin
      ref = results['blocks'][bname]
      startpos = ref[:pos]
      fh.seek( startpos )
    rescue
      $logger.info (pname+ " "+ bname+ "block starting position unknown")
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
    
    # extra parameters
    xref['_datapts_params'] = { 'xscaling'=> 1, 'offset'=> 'STV' }
    # method used by STV: minimum reading shifted to zero
    # method used by AFL/Noyes Trace.Net: maximum reading shifted to zero (approx)
    
    status = Datapts::_process_data(fh, results, tracedata, debug=debug)
    
    # read the rest of the block (just in case)
    endpos = results['blocks'][bname][:pos].to_i + results['blocks'][bname][:size].to_i
    fh.read( endpos - fh.tell() )
    
    return status
  end
  
  # ================================================================
  def self._process_data(fh, results, tracedata, debug=false)
    bname = "DataPts"
    xref  = results[bname]
    
    begin
      # we assume SupParams block already processed
      model = results['SupParams']['OTDR']
    rescue
      model = ""
    end
    
    # special case:
    # old Noyes/AFL OFL250 model is off by factor of 10
    if model == 'OFL250' then
      xref['_datapts_params']['xscaling'] = 0.1
    end
    
    if debug then
      $logger.info ("%s [initial 12 byte header follows]" % @@sep)
    end
    
    xN = Parts::get_uint(fh, 4)
    # confirm xN equal to FxdParams num data points
    if xN != results['FxdParams']['num data points'] then
      $logger.info ("!!! WARNING !!! block says number of data points "+
        "is "+xN+" instead of "+results['FxdParams']['num data points'])
    end
    
    xref['num data points'] = xN
    if debug then
      $logger.info ("%s num data points = %d" % [@@sep,xN] )
    end
    
    val = Parts::get_signed(fh, 2)
    xref['num traces'] = val
    if debug then
      $logger.info ("%s number of traces = %d" % [@@sep,val] )
    end
    
    if val > 1 then
      $logger.info ("WARNING!!!: Cannot handle multiple traces (%d); aborting" % val)
      abort("WARNING!!!: Cannot handle multiple traces (%d); aborting" % val)
    end
    
    val = Parts::get_uint(fh, 4)
    xref['num data points 2'] = val
    if debug then
      $logger.info ("%s num data points again = %d" % [@@sep,val] )
    end
    
    val = Parts::get_uint(fh, 2)
    scaling_factor = val / 1000.0
    xref['scaling factor'] = scaling_factor
    if debug then
      $logger.info ("%s scaling factor = %f" % [@@sep,scaling_factor] )
    end
    
    # .....................................
    # adjusted resolution
    dx = results['FxdParams']['resolution']
    dlist = []
    1.upto(xN) { |i|
      val = Parts::get_uint(fh, 2)
      dlist.push(val)
    }
    
    ymax = dlist.max
    ymin = dlist.min
    fs = 0.001* scaling_factor
    disp_min = "%.3f" % [ymin * fs]
    disp_max = "%.3f" % [ymax * fs]
    xref['max before offset'] = disp_max.to_f
    xref['min before offset'] = disp_min.to_f
    
    if debug then
      $logger.info ("%s before applying offset: max %s dB, min %s dB" % [@@sep, disp_max, disp_min] )
    end
    
    # .........................................
    # save to file
    offset = xref['_datapts_params']['offset']
    xscaling = xref['_datapts_params']['xscaling']
    
    # convert/scale to dB
    if offset == 'STV' then
      nlist = dlist.map { |x| (ymax - x )*fs }
    elsif offset == 'AFL' then
      nlist = dlist.map { |x| (ymin - x )*fs }
    else # invert
      nlist = dlist.map { |x| -x*fs }
    end
    
    0.upto(xN-1) do |i|
      # more work but (maybe) less rounding issues
      x = dx*i*xscaling / 1000.0 # output in kkm
      tracedata.push( "%f\t%f" % [x, nlist[i]] )
    end

    # .........................................
    status = 'ok'
    
    return status
  end
  
end
