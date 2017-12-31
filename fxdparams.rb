#!/usr/bin/ruby
require 'date'

$:.push File.dirname(__FILE__)
require 'parts'

module Fxdparams
  @@sep = "    :"
  
  @@unit_map = \
  {
    "mt" => " (meters)",
    "km" => " (kilometers)",
    "mi" => " (miles)",
    "kf" => " (kilo-ft)"
  };
  
  @@tracetype = \
  {
    'ST' => "[standard trace]",
    'RT' => "[reverse trace]",
    'DT' => "[difference trace]",
    'RF' => "[reference]",
  };
  
  def self.process(fh, results, debug=false)
    
    if $logger == nil then
      $logger = Logger.new(STDOUT)
    end
    
    bname = "FxdParams"
    hsize = bname.length + 1 # include trailing '\0'
    pname = "FxdParams::process():"
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
    
    if format == 1 then
        plist =	[   # name, start-pos, length (bytes), type, multiplier, precision, units
	            # type: display type: 'v' (value) or 'h' (hexidecimal) or 's' (string)
	    ["date/time",0,4,'v','','',''], # ............... 0-3 seconds in Unix time
	    ["unit",4,2,'s','','',''], # .................... 4-5 distance units, 2 char (km,mt,ft,kf,mi)
	    ["wavelength",6,2,'v',0.1,1,'nm'], # ............ 6-7 wavelength (nm)
	    
	    # from Andrew Jones
	    ["acquisition offset",8,4,'i','','',''], # .............. 8-11 acquisition offset; units?
	    ["number of pulse width entries",12,2,'v','','',''], # .. 12-13 number of pulse width entries
	    
	    ["pulse width",14,2,'v','',0,'ns'],  # .......... 14-15 pulse width (ns)
	    ["sample spacing", 16,4,'v',1e-8,'','usec'], # .. 16-19 sample spacing (in usec)
	    ["num data points", 20,4,'v','','',''], # ....... 20-23 number of data points
	    ["index", 24,4,'v',1e-5,6,''], # ................ 24-27 index of refraction
	    ["BC", 28,2,'v',-0.1,2,'dB'], # ................. 28-29 backscattering coeff
	    ["num averages", 30,4,'v','','',''], # .......... 30-33 number of averages
	    ["range", 34,4,'v',2e-5,6,'km'], # .............. 34-37 range (km)
	    
	    # from Andrew Jones
	    ["front panel offset",38,4,'i','','',''], # ................ 38-41
	    ["noise floor level",42,2,'v','','',''], # ................. 42-43 unsigned
	    ["noise floor scaling factor",44,2,'i','','',''], # ........ 44-45
	    ["power offset first point",46,2,'v','','',''], # .......... 46-47 unsigned
	    
	    ["loss thr", 48,2,'v',0.001,3,'dB'], # .......... 48-49 loss threshold
	    ["refl thr", 50,2,'v',-0.001,3,'dB'], # ......... 50-51 reflection threshold
	    ["EOT thr",52,2,'v',0.001,3,'dB'], # ............ 52-53 end-of-transmission threshold
      ]
    else
      plist = [  # name, start-pos, length (bytes), type, multiplier, precision, units
                 # type: display type: 'v' (value) or 'h' (hexidecimal) or 's' (string)
            ["date/time",0,4,'v','','',''], # ............... 0-3 seconds in Unix time
	    ["unit",4,2,'s','','',''], # .................... 4-5 distance units, 2 char (km,mt,ft,kf,mi)
	    ["wavelength",6,2,'v',0.1,1,'nm'], # ............ 6-7 wavelength (nm)
	    
	    # from Andrew Jones
	    ["acquisition offset",8,4,'i','','',''], # .............. 8-11 acquisition offset; units?
	    ["acquisition offset distance",12,4,'i','','',''], # .... 12-15 acquisition offset distance; units?
	    ["number of pulse width entries",16,2,'v','','',''], # .. 16-17 number of pulse width entries
	    
	    ["pulse width",18,2,'v','',0,'ns'],  # .......... 18-19 pulse width (ns)
	    ["sample spacing", 20,4,'v',1e-8,'','usec'], # .. 20-23 sample spacing (usec)
	    ["num data points", 24,4,'v','','',''], # ....... 24-27 number of data points
	    ["index", 28,4,'v',1e-5,6,''], # ................ 28-31 index of refraction
	    ["BC", 32,2,'v',-0.1,2,'dB'], # ................. 32-33 backscattering coeff
	    
	    ["num averages", 34,4,'v','','',''], # .......... 34-37 number of averages
	    
	    # from Dmitry Vaygant:
	    ["averaging time", 38,2,'v',0.1,0,'sec'], # ..... 38-39 averaging time in seconds
	    
	    ["range", 40,4,'v',2e-5,6,'km'], # .............. 40-43 range (km); note x2
	    
	    # from Andrew Jones
	    ["acquisition range distance",44,4,'i','','',''], # ........ 44-47
	    ["front panel offset",48,4,'i','','',''], # ................ 48-51
	    ["noise floor level",52,2,'v','','',''], # ................. 52-53 unsigned
	    ["noise floor scaling factor",54,2,'i','','',''], # ........ 54-55
	    ["power offset first point",56,2,'v','','',''], # .......... 56-57 unsigned
	    
	    ["loss thr", 58,2,'v',0.001,3,'dB'], # .......... 58-59 loss threshold
	    ["refl thr", 60,2,'v',-0.001,3,'dB'], # ......... 60-61 reflection threshold
	    ["EOT thr",62,2,'v',0.001,3,'dB'], # ............ 62-63 end-of-transmission threshold
	    ["trace type",64,2,'s','','',''], # ............. 64-65 trace type (ST,RT,DT, or RF)
	    
	    # from Andrew Jones
	    ["X1",66,4,'i','','',''], # ............. 66-69
	    ["Y1",70,4,'i','','',''], # ............. 70-73
	    ["X2",74,4,'i','','',''], # ............. 74-77
	    ["Y2",78,4,'i','','',''], # ............. 78-81
      ]
    end
    
    status= Fxdparams::_process_fields(fh, plist, results, debug=debug)
    
    # read the rest of the block (just in case)
    endpos = (results['blocks'][bname][:pos].to_i) + (results['blocks'][bname][:size].to_i)
    fh.read( endpos - fh.tell() )
    return status
    
  end
  
  # ================================================================
  def self._process_fields(fh, plist, results, debug=False)
    bname = "FxdParams"
    xref  = results[bname]
    
    # functions to use
    # 'h': get_hexstring
    # 'v': get_uint
    # 's': get_string
    # 'i': get_signed
    count = 0
    
    plist.each do |field|
      name  = field[0]
      fsize = field[2]
      ftype = field[3]
      scale = field[4]
      dgt   = field[5]
      unit  = field[6]
      xstr  = ""
      
      if ftype == 'i' then
	val = Parts::get_signed(fh, fsize)
	xstr = val
      elsif ftype == 'v' then
	val = Parts::get_uint(fh, fsize)
	if scale != '' then
	  val *= scale
	end
	if dgt != '' then
	  fmt = "%%.%df" % dgt
	  xstr = fmt % val
	else
	  xstr = val
	end
      elsif ftype == 'h' then
	xstr = Parts::get_hex(fh, fsize)
      elsif ftype == 's' then
	xstr = fh.read( fsize )
      else
	val = fh.read(fsize)
	xstr = val
      end
      
      # .................................
      if name == 'date/time' then
	# xstr = str(datetime.datetime.fromtimestamp(val))+(" (%d sec)" % val)
	xstr = Time.at(val).to_datetime
	xstr = xstr.strftime("%a %b %d %H:%M:%S %Y")
	xstr = xstr.to_s + (" (%d sec)" % [val.to_i])
      elsif name == 'unit' then
	xstr += @@unit_map[ xstr ]
      elsif name == 'trace type' then
	begin
	  xstr += @@tracetype[ xstr ]
	rescue
	  # do nothing
	end
      end
      
      # don't bother even trying if there are multiple pulse width entries; too lazy
      # to restructure code to handle this case
      if name == 'number of pulse width entries' and val.to_i > 1 then
	$logger.info ("WARNING!!!: Cannot handle multiple pulse width entries (%d); aborting" % val)
	abort("WARNING!!!: Cannot handle multiple pulse width entries (%d); aborting" % val)
      end
      
      # .................................
      if debug then
	$logger.info ("%s %d. %s: %s %s" % [@@sep, count, name, xstr, unit] )
      end
      if unit=="" then
	xref[name] = xstr
      else 
	xref[name] = xstr.to_s+" "+unit.to_s
      end
      count += 1
    end
    
    # corrrections/adjustment:
    ior = xref['index'].to_f
    ss  = xref['sample spacing'].split(' ')[0]
    dx  = ss.to_f * Parts.SOL / ior
    xref['range'] = dx * xref['num data points'].to_i
    xref['resolution'] = dx * 1000.0 # in meters
    
    if debug then
      $logger.info ""
      $logger.info ("%s [adjusted for refractive index]" % @@sep)
      $logger.info("%s resolution = %.14f m" % [@@sep, xref['resolution']] )
      $logger.info("%s range      = %.13f km" % [@@sep,xref['range']] )
    end
    status = 'ok'
    
    return status
  end
  
end
