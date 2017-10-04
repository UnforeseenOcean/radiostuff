#!/usr/bin/env ruby

## Fetches and caches repeaterbook lookups and formats the data
## for a FT-70D import into the bundled programming software

require 'digest'
require 'open-uri'
require 'csv'


CACHE_THRESHOLD=60*60*24*5

def fetch_rr(location, distance, band1,band2=nil, type=nil, cache=15)
	cachename = Digest::SHA256.hexdigest("#{location}_#{distance}_#{band1}_#{band2}_#{type}")
	if File.exist?(cachename) && (Time.now - File.mtime(cachename) < CACHE_THRESHOLD)
		return IO.read(cachename)
	else
		url="https://www.repeaterbook.com/repeaters/downloads/RT.php?func=proxX&city=#{location}&type=&distance=#{distance}&Dunit=m&freq=&band1=#{band1}&use=OPEN&status_id=1"
		url += "&band2=#{band2}" if band2
		url += "&type=#{type}" if type #ysf
		url += "&call=&use=OPEN&status_id=1"

		result = download = open(url).read
		File.open(cachename, 'w') { |file| file.write(result) }
		return result
	end
end

def parse_csv(csv)
	CSV.parse(csv, headers: true)
end

OFF = "OFF"
ON = "ON"

def format_row_for_ft70D(repeaterbook_row, channel_num=0, digital=false)
	# Channel Number,Receive Frequency,Transmit Frequency,Offset Direction,Name,Tone Mode,CTCSS,Rx CTCSS,DCS,RX DCS,Comment,
	# 1,145.15000,144.55000,-,W6PW,D Code,88.5,88.5,664,664,Daly City Sutro Tower,
	# / 
	return "" if repeaterbook_row['Offset Direction'] == "s"

	data = []
	data << channel_num.to_s #ChannelNo
	data << OFF #PriorityCH
	data << repeaterbook_row['Receive Frequency'] #ReceiveFrequency
	data << repeaterbook_row['Transmit Frequency'] #TransmitFrequency
	data << (repeaterbook_row['Receive Frequency'].to_f-repeaterbook_row['Transmit Frequency'].to_f).abs.round(1) #OffsetFrequency
	data << repeaterbook_row['Offset Direction']+"RPT" #OffsetDirection
	data << ON #AutoMode
	data << 'FM' #OperatingMode(FM/AM)
	data << ON #AMS
	data << (digital ? 'DN' : 'ANALOG') #DIG/Analog
	data << '"' + (repeaterbook_row['Name'].empty? ? repeaterbook_row['Receive Frequency'].gsub('.', '')[0..5] : repeaterbook_row['Name']) + '"' #Name(6char)
	data << case repeaterbook_row['Tone Mode'].downcase.strip
	when "tone"
		"TONE"
	when "t sql"
		"TONE SQL"
	when "none"
		"OFF"
	when "d code"
		"DCS"
	when "dcs"
		"DCS"
	when ""
		"OFF"
	else
		"OFF"
	end #ToneMode - DCS/TONE/OFF/TONE SQL/REV TONE/PR FREQ/PAGER
	data << repeaterbook_row['CTCSS'] + " Hz"#CTCSS Frequency
	data << repeaterbook_row['DCS'] #DCS Code
	data << 'RX Normal TX Normal' #DCS Polarity
	data << '1600' + " Hz" #UserCTCSS
	data << 'HIGH' #TxPower
	data << OFF #Skip
	data << ON #AUTO Step
	data << '5.0KHz' #Step
	data << ON #TAG
	data << OFF #Memory Mask
	data << OFF #ATT
	data << OFF #S-Meter SQL
	data << OFF #Bell
	data << OFF #Half DEV
	data << OFF #Clock Shift
	data << OFF #Bank1
	data << OFF #Bank2
	data << OFF #Bank3
	data << OFF #Bank4
	data << OFF #Bank5
	data << OFF #Bank6
	data << OFF #Bank7
	data << OFF #Bank8
	data << OFF #Bank9
	data << OFF #Bank10
	data << OFF #Bank11
	data << OFF #Bank12
	data << OFF #Bank13
	data << OFF #Bank14
	data << OFF #Bank15
	data << OFF #Bank16
	data << OFF #Bank17
	data << OFF #Bank18
	data << OFF #Bank19
	data << OFF #Bank20
	data << OFF #Bank21
	data << OFF #Bank22
	data << OFF #Bank23
	data << OFF #Bank24
	data << '"'+repeaterbook_row['Comment']+'"' #Comment
	data << 0
	return data.join(",")


end

@counter = 0
def countme
	@counter +=1
	@counter
end


def fetch_repeaters_for_ft70D(location, distance)
	output = []

	CSV.parse(fetch_rr(location,distance,14,4,'YSF'), headers: true) do |thing|
		a = format_row_for_ft70D(thing, countme(),true)
		if a != ""
			output << a 
		else
			@counter -= 1
		end
	end
	CSV.parse(fetch_rr(location,distance,14,4), headers: true) do |thing|
		a = format_row_for_ft70D(thing, countme())
		if a != ""
			output << a 
		else
			@counter -= 1
		end
	end


	while @counter < 900
		output << countme.to_s + ",,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,0"

	end
	puts output.join("\r\n")
end


fetch_repeaters_for_ft70D("94104", 500)

