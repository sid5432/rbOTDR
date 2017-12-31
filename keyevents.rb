#!/usr/bin/ruby
$:.push File.dirname(__FILE__)
require 'parts'

module Keyevents
  @@sep = "    :"
  
  def self.process(fh, results, debug=false)
    
    if $logger == nil then
      $logger = Logger.new(STDOUT)
    end
    
    bname = "KeyEvents"
    hsize = bname.length + 1 # include trailing '\0'
    pname = "Keyevents::process():"
    ref = nil
    status = 'nok'
    
    begin
      ref = results['blocks'][bname]
      startpos = ref[:pos]
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
    
    status = Keyevents::_process_keyevents(fh, format, results, debug=debug)
    
    # read the rest of the block (just in case)
    endpos = (results['blocks'][bname][:pos].to_i) + (results['blocks'][bname][:size].to_i)
    fh.read( endpos - fh.tell() )
    status = 'ok'
    return status
    
  end
  
  # ================================================================
  def self._process_keyevents(fh, format, results, debug=False)
    bname = "KeyEvents"
    xref  = results[bname]
    
    # number of events
    nev = Parts::get_uint(fh, 2)
    $logger.info ("%s %d events" % [@@sep, nev] )
    xref['num events'] = nev
    
    factor = 1e-4 * Parts.SOL / results['FxdParams']['index'].to_f
    
    pat = /(.)(.)9999LS/
    
    1.upto(nev) do |j|
      x2ref = xref[ ('event %d' % [j] )] = {};
      
      xid  = Parts::get_uint(fh, 2)             # 00-01: event number
      dist = Parts::get_uint(fh, 4) * factor    # 02-05: time-of-travel; need to convert to distance
      
      slope  = Parts::get_signed(fh, 2) * 0.001 # 06-07: slope
      splice = Parts::get_signed(fh, 2) * 0.001 # 08-09: splice loss
      refl   = Parts::get_signed(fh, 4) * 0.001 # 10-13: reflection loss
      
      xtype = fh.read(8)                       # 14-21: event type
      
      if pat.match( xtype ) then
	subtype = $1
	manual  = $2
	
	if manual == 'A' then
	  xtype += " {manual}"
	else
	  xtype += " {auto}"
	end
	
	if subtype == '1' then
	  xtype += " reflection"
	elsif subtype == '0' then
	  xtype += " loss/drop/gain"
	elsif subtype == '2' then
	  xtype += " multiple"
	else
	  xtype += " unknown '"+subtype+"'"
	end
      else
	xtype += " [unknown type "+xtype+"]"
      end
      
      if format == 2 then
        end_prev = Parts::get_uint(fh, 4) * factor    # 22-25: end of previous event
	start_curr = Parts::get_uint(fh, 4) * factor    # 26-29: start of current event
        end_curr   = Parts::get_uint(fh, 4) * factor    # 30-33: end of current event
	start_next = Parts::get_uint(fh, 4) * factor    # 34-37: start of next event
	pkpos      = Parts::get_uint(fh, 4) * factor    # 38-41: peak point of event
      end
      
      comments = Parts::get_string(fh)
      
      x2ref['type'] = xtype
      x2ref['distance'] = ("%.3f" % dist)
      x2ref['slope'] = ("%.3f" % slope)
      x2ref['splice loss'] = ("%.3f" % splice)
      x2ref['refl loss'] = ("%.3f" % refl)
      x2ref['comments'] = comments

      if format == 2 then
        x2ref['end of prev'] = ("%.3f" % end_prev)
        x2ref['start of curr'] = ("%.3f" % start_curr)
        x2ref['end of curr'] = ("%.3f" % end_curr)
        x2ref['start of next'] = ("%.3f" % start_next)
        x2ref['peak'] = ("%.3f" % pkpos)
      end

      if debug then
        $logger.info ("%s Event %d: type %s" % [@@sep,xid, xtype] )
        $logger.info ("%s%s distance: %.3f km" % [@@sep,@@sep,dist] )
        $logger.info ("%s%s slope: %.3f dB/km" % [@@sep,@@sep,slope] )
        $logger.info ("%s%s splice loss: %.3f dB" % [@@sep,@@sep,splice] )
        $logger.info ("%s%s refl loss: %.3f dB" % [@@sep,@@sep,refl] )
        
        # version 2
        if format == 2 then
          $logger.info("%s%s end of previous event: %.3f km" % [@@sep,@@sep,end_prev] )
          $logger.info("%s%s start of current event: %.3f km" % [@@sep,@@sep,start_curr] )
          $logger.info("%s%s end of current event: %.3f km" % [@@sep,@@sep,end_curr] )
          $logger.info("%s%s start of next event: %.3f km" % [@@sep,@@sep,start_next] )
          $logger.info("%s%s peak point of event: %.3f km" % [@@sep,@@sep,pkpos] )
        end

        # common
        $logger.info("%s%s comments: %s" % [@@sep,@@sep,comments] )
      end
    end
    
    # ...................................................
    total      = Parts::get_signed(fh, 4) * 0.001  # 00-03: total loss
    loss_start = Parts::get_signed(fh, 4) * factor # 04-07: loss start position
    loss_finish= Parts::get_uint(fh, 4) * factor   # 08-11: loss finish position
    orl        = Parts::get_uint(fh, 2) * 0.001    # 12-13: optical return loss (ORL)
    orl_start  = Parts::get_signed(fh, 4) * factor # 14-17: ORL start position
    orl_finish = Parts::get_uint(fh, 4) * factor   # 18-21: ORL finish position
    
    if debug then
      $logger.info("%s Summary:" % @@sep)
      $logger.info("%s%s total loss: %.3f dB" % [@@sep,@@sep,total])
      $logger.info("%s%s ORL: %.3f dB" % [@@sep,@@sep,orl])
      $logger.info("%s%s loss start: %f km" % [@@sep,@@sep,loss_start])
      $logger.info("%s%s loss end: %f km" % [@@sep,@@sep,loss_finish])
      $logger.info("%s%s ORL start: %f km" % [@@sep,@@sep,orl_start])
      $logger.info("%s%s ORL finish: %f km" % [@@sep,@@sep,orl_finish])
    end
    
    x3ref = xref["Summary"] = {}
    x3ref["total loss"] = ( "%.3f" % total).to_f
    x3ref["ORL"]        = ( "%.3f" % orl ).to_f
    x3ref["loss start"] = ( "%.6f" % loss_start ).to_f
    x3ref["loss end"]   = ( "%.6f" % loss_finish ).to_f
    x3ref["ORL start"]  = ( "%.6f" % orl_start ).to_f
    x3ref["ORL finish"] = ( "%.6f" % orl_finish ).to_f
    
    # ................
    status = 'ok'
    return status
  end
end
    
