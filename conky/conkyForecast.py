#!/usr/bin/python2
# -*- coding: utf-8 -*-
###############################################################################
# conkyForecast.py is a (not so) simple (anymore) python script to gather 
# details of the current weather for use in conky.
#
#  Author: Kaivalagi
# Created: 13/04/2008
# Modifications:
#	14/04/2008	Allow day ranges for forecast data
#	14/04/2008	Check for connectivity to xoap service
#	18/04/2008	Allow the setting of spaces for ranged output
#	18/04/2008	Allow Night and Day forecast output
#	18/04/2008	Support locale for condition code text "CC" option, awaiting spanish language translation
#	18/04/2008	Use pickling for class data rather than opening xml, this bypasses the need to interrogate cached data
#	19/04/2008	Added spanish condition text - Thanks Bruce M
#	19/04/2008	Added isnumeric check on all numeric output with units suffix
#	19/04/2008	Altered pickle file naming to include location code
#	19/04/2008	Added spanish week days conversion via locale
#	20/04/2008	Added decent command argument parser
#	20/04/2008	Added --shortweekday option, if given the day of week data type is shortened to 3 characters
#	21/04/2008	Fixed locale options for forecast output
#	21/04/2008	Added --template option to allow custom output using a single exec call :)
#	21/04/2008	Added --hideunits option to remove, for example, mph and C from output
#	23/04/2008	Removed --imperial option from template, this MUST be set as a standard option on the script call and not used in the template file. 
#	23/04/2008	Readded --imperial option to template, enabling metric or imperial values per datatype. Note when using templates command line option will not work.
#	23/04/2008	Added output notifying user if the location given is bad
#	24/04/2008	Added handling for no connectivity, will revert to cached data now (erroring if no cache exists). Tests by trying to open xoap.weather.com
#	24/04/2008	Fixed Celsius to fahrenheit conversion
#	06/05/2008	Updated url used after webservice was updated
#	09/05/2008	Consolidated current condition and forecast data fetch into one call
#	09/05/2008	Added Sunrise and sunset to datatypes, these are specific to both current conditions and forecast data
#	09/05/2008	Added moon phase, barometer reading and barometer description to datatypes, these are only specific to current conditions and so are N/A in forecasted output
#	09/05/2008	Added unit conversions for barometer from mb to inches (imperial)
#   09/05/2008  Updated spanish condition text - Thanks Bruce M
#   10/05/2008  Added french locale data - Thanks benpaka
#   12/05/2008  Added new BF (bearing font) datatype to provide an arrow character (use with Arrow.ttf font) instead of NSEW output from WD (wind direction)
#   12/05/2008  Updated WD output to be locale specific, currently supports default english and spanish - Thanks Bruce M
#	18/05/2008	Added new MF (moon font) datatype to provide a moon font character (characters incorrect and no dedicated font yet).
#	21/05/2008	For current conditions the --datatype=LT option now displays "feels like" temperature rather than the current temperature
#
# TODO:
# Consolidate pkl files into one file/class
# Add a weather font based moon phase output based on moon icon data
# ??? Any more requirements out there?

import sys, os, socket, urllib2, datetime, time
from xml.dom import minidom
from stat import *
from optparse import OptionParser
import locale
import gettext
import pickle
from math import *

APP="conkyForecast.py"
DIR=os.path.dirname (__file__) + '/locale'
gettext.bindtextdomain(APP, DIR)
gettext.textdomain(APP)
_ = gettext.gettext

class CommandLineParser:

	parser = None

	def __init__(self):

		self.parser = OptionParser()
		self.parser.add_option("-l","--location", dest="location", default="UKXX0103", type="string", metavar="CODE", help=u"location code for weather data [default: %default],Use the following url to determine your location code by city name: http://xoap.weather.com/search/search?where=Norwich")
		self.parser.add_option("-d","--datatype",dest="datatype", default="HT", type="string", metavar="DATATYPE", help=u"[default: %default] The data type options are: DW (Day Of Week), WF (Weather Font Output), LT (Forecast:Low Temp,Current:Feels Like Temp), HT (Forecast:High Temp,Current:Current Temp), CC (Current Conditions), CT (Conditions Text), PC (Precipitation Chance), HM (Humidity), WD (Wind Direction), WS (Wind Speed), WG (Wind Gusts), CN (City Name), SR (sunrise), SS (sunset), MP (moon phase), MF (moon font), BR (barometer reading), BD (barometer description). Not applicable at command line when using templates.")
		self.parser.add_option("-s","--startday",dest="startday", type="int", metavar="NUMBER", help=u"define the starting day number, if omitted current conditions are output. Not applicable at command line when using templates.")
		self.parser.add_option("-e","--endday",dest="endday", type="int", metavar="NUMBER", help=u"define the ending day number, if omitted only starting day data is output. Not applicable at command line when using templates.")
		self.parser.add_option("-S","--spaces",dest="spaces", type="int", default=1, metavar="NUMBER", help=u"[default: %default] Define the number of spaces between ranged output. Not applicable at command line when using templates.")
		self.parser.add_option("-t","--template",dest="template", type="string", metavar="FILE", help=u"define a template file to generate output in one call. A displayable item in the file is in the form {--datatype=HT --startday=1}. The following are possible options within each item: --datatype,--startday,--endday,--night,--shortweekday,--imperial,--hideunits,--spaces . Note that the short forms of the options are not currently supported! None of these options are applicable at command line when using templates.")
		self.parser.add_option("-L","--locale",dest="locale", type="string", help=u"override the system locale for language output (en=english, es=spanish, fr=french, more to come)")
		self.parser.add_option("-i","--imperial",dest="imperial", default=False, action="store_true", help=u"request imperial units, if omitted output is in metric. Not applicable at command line when using templates.")
		self.parser.add_option("-n","--night",dest="night", default=False, action="store_true", help=u"switch output to night data, if omitted day output will be output. Not applicable at command line when using templates.")
		self.parser.add_option("-w","--shortweekday",dest="shortweekday", default=False, action="store_true", help=u"Shorten the day of week data type to 3 characters. Not applicable at command line when using templates.")
		self.parser.add_option("-u","--hideunits",dest="hideunits", default=False, action="store_true", help=u"Hide units such as mph or C, degree symbols (°) are still shown. Not applicable at command line when using templates.")
		self.parser.add_option("-v","--verbose",dest="verbose", default=False, action="store_true", help=u"request verbose output, no a good idea when running through conky!")
		self.parser.add_option("-r","--refetch",dest="refetch", default=False, action="store_true", help=u"fetch data regardless of data expiry")

	def parse_args(self):
		(options, args) = self.parser.parse_args()
		return (options, args)

	def print_help(self):
		return self.parser.print_help()

class WeatherData:
	def __init__(self, day_of_week, low, high, condition_code, condition_text, precip, humidity, wind_dir, wind_speed, wind_gusts, city, sunrise, sunset, moon_phase, moon_icon, bar_read, bar_desc):
		self.day_of_week = u""+day_of_week
		self.low = u""+low
		self.high = u""+high
		self.condition_code = u""+condition_code
		self.condition_text = u""+condition_text
		self.precip = u""+precip
		self.humidity = u""+humidity
		self.wind_dir = u""+wind_dir
		self.wind_speed = u""+wind_speed
		self.wind_gusts = u""+wind_gusts
		self.city = u""+city
		self.sunrise = u""+sunrise
		self.sunset = u""+sunset
		self.moon_phase = u""+moon_phase
		self.moon_icon = u""+moon_icon		
		self.bar_read = u""+bar_read
		self.bar_desc = u""+bar_desc


class WeatherText:

	conditions_text = {
		"0": _(u"Tornado"),
		"1": _(u"Tropical Storm"),
		"2": _(u"Hurricane"),
		"3": _(u"Severe Thunderstorms"),
		"4": _(u"Thunderstorms"),
		"5": _(u"Mixed Rain and Snow"),
		"6": _(u"Mixed Rain and Sleet"),
		"7": _(u"Mixed Precipitation"),
		"8": _(u"Freezing Drizzle"),
		"9": _(u"Drizzle"),
		"10": _(u"Freezing Rain"),
		"11": _(u"Showers"),
		"12": _(u"Showers"),
		"13": _(u"Snow Flurries"),
		"14": _(u"Light Snow Showers"),
		"15": _(u"Blowing Snow"),
		"16": _(u"Snow"),
		"17": _(u"Hail"),
		"18": _(u"Sleet"),
		"19": _(u"Dust"),
		"20": _(u"Fog"),
		"21": _(u"Haze"),
		"22": _(u"Smoke"),
		"23": _(u"Blustery"), 
		"24": _(u"Windy"),
		"25": _(u"Cold"),
		"26": _(u"Cloudy"),
		"27": _(u"Mostly Cloudy"),
		"28": _(u"Mostly Cloudy"),
		"29": _(u"Partly Cloudy"),
		"30": _(u"Partly Cloudy"),
		"31": _(u"Clear"),
		"32": _(u"Clear"),
		"33": _(u"Fair"),
		"34": _(u"Fair"),
		"35": _(u"Mixed Rain and Hail"),
		"36": _(u"Hot"),
		"37": _(u"Isolated Thunderstorms"),
		"38": _(u"Scattered Thunderstorms"),
		"39": _(u"Scattered Thunderstorms"),
		"40": _(u"Scattered Showers"),
		"41": _(u"Heavy Snow"),
		"42": _(u"Scattered Snow Showers"),
		"43": _(u"Heavy Snow"),
		"44": _(u"Partly Cloudy"),
		"45": _(u"Thunder Showers"),
		"46": _(u"Snow Showers"),
		"47": _(u"Isolated Thunderstorms"),
		"na": _(u"N/A"),
		"-": _(u"N/A")
	}

	conditions_text_es = {
        "0": _(u"Tornado"),
        "1": _(u"Tormenta Tropical"),
        "2": _(u"Huracá¡n"),
        "3": _(u"Tormentas Fuertes"),
        "4": _(u"Tormentas"),
        "5": _(u"Lluvia y Nieve Mezclada"),
        "6": _(u"Lluvia y Aguanieve Mezclada"),
        "7": _(u"Aguanieve"),
        "8": _(u"Llovizna Helada"),
        "9": _(u"Llovizna"),
        "10": _(u"Lluvia Engelante"), # o lluvia helada
        "11": _(u"Chaparrones"),
        "12": _(u"Chaparrones"),
        "13": _(u"Nieve Ligera"),
        "14": _(u"Nieve Ligera"),
        "15": _(u"Ventisca de Nieve"),
        "16": _(u"Nieve"),
        "17": _(u"Granizo"),
        "18": _(u"Aguanieve"),
        "19": _(u"Polvo"),
        "20": _(u"Niebla"),
        "21": _(u"Bruma"),
        "22": _(u"Humo"),
        "23": _(u"Tempestad"),
        "24": _(u"Ventoso"),
        "25": _(u"Fráo"),
        "26": _(u"Muy Nublado"),
        "27": _(u"Principalmente Nublado"),
        "28": _(u"Principalmente Nublado"),
        "29": _(u"Parcialmente Nublado"),
        "30": _(u"Parcialmente Nublado"),
        "31": _(u"Despejado"),
        "32": _(u"Despejado"),
        "33": _(u"Algo Nublado"),
        "34": _(u"Algo Nublado"),
        "35": _(u"Lluvia con Granizo"),
        "36": _(u"Calor"),
        "37": _(u"Tormentas Aisladas"),
        "38": _(u"Tormentas Dispersas"),
        "39": _(u"Tormentas Dispersas"),
        "40": _(u"Chubascos Dispersos"),
        "41": _(u"Nieve Pesada"),
        "42": _(u"Nevadas Débiles y Dispersas"),
        "43": _(u"Nevada Intensa"),
        "44": _(u"Nubes Dispersas"),
        "45": _(u"Tormentas"),
        "46": _(u"Nevadas Dispersas"),
        "47": _(u"Tormentas Aisladas"),
        "na": _(u"N/A"),
        "-": _(u"N/A")
    }

	conditions_text_fr = {
        "0": _(u"Tornade"),
        "1": _(u"Tempête Tropicale"),
        "2": _(u"Ouragan"),
        "3": _(u"Orages Violents"),
        "4": _(u"Orageux"),
        "5": _(u"Pluie et Neige"),
        "6": _(u"Pluie et Neige Mouillée"),
        "7": _(u"Variable avec averses"),
        "8": _(u"Bruine Givrante"),
        "9": _(u"Bruine"),
        "10": _(u"Pluie Glacante"),
        "11": _(u"Averses"),
        "12": _(u"Averses"),
        "13": _(u"Légère Neige"),
        "14": _(u"Forte Neige"),
        "15": _(u"Tempête de Neige"),
        "16": _(u"Neige"),
        "17": _(u"Grêle"),
        "18": _(u"Pluie/Neige"),
        "19": _(u"Nuage de poussière"),
        "20": _(u"Brouillard"),
        "21": _(u"Brume"),
        "22": _(u"Fumée"),
        "23": _(u"Tres Venteux"),
        "24": _(u"Venteux"),
        "25": _(u"Froid"),
        "26": _(u"Nuageux"),
        "27": _(u"Tres Nuageux"),
        "28": _(u"Tres Nuageux"),
        "29": _(u"Nuages Disséminés"),
        "30": _(u"Nuages Disséminés"),
        "31": _(u"Beau"),
        "32": _(u"Beau"),
        "33": _(u"Belles Éclaircies"),
        "34": _(u"Belles Éclaircies"),
        "35": _(u"Pluie avec Grêle"),
        "36": _(u"Chaleur"),
        "37": _(u"Orages Isolés"),
        "38": _(u"Orages Localisés"),
        "39": _(u"Orages Localisés"),
        "40": _(u"Averses Localisées"),
        "41": _(u"Neige Lourde"),
        "42": _(u"Tempête de Neige Localisées"),
        "43": _(u"Neige Lourde"),
        "44": _(u"Nuages Disséminés"),
        "45": _(u"Orages"),
        "46": _(u"Tempête de Neige"),
        "47": _(u"Orages Isolés"),
        "na": _(u"N/A"),
        "-": _(u"N/A")
	}
	
	conditions_weather_font = {
		"0": _(u"W"),
		"1": _(u"V"),
		"2": _(u"W"),
		"3": _(u"s"),
		"4": _(u"p"),
		"5": _(u"k"),
		"6": _(u"k"),
		"7": _(u"g"),
		"8": _(u"g"),
		"9": _(u"g"),
		"10": _(u"h"),
		"11": _(u"g"),
		"12": _(u"g"),
		"13": _(u"k"),
		"14": _(u"k"),
		"15": _(u"k"),
		"16": _(u"k"),
		"17": _(u"k"),
		"18": _(u"k"),
		"19": _(u"e"),
		"20": _(u"e"),
		"21": _(u"a"),
		"22": _(u"d"),
		"23": _(u"d"), 
		"24": _(u"d"),
		"25": _(u"d"),
		"26": _(u"e"),
		"27": _(u"e"),
		"28": _(u"e"),
		"29": _(u"c"),
		"30": _(u"c"),
		"31": _(u"a"),
		"32": _(u"a"),
		"33": _(u"b"),
		"34": _(u"b"),
		"35": _(u"k"),
		"36": _(u"a"),
		"37": _(u"f"),
		"38": _(u"f"),
		"39": _(u"f"),
		"40": _(u"g"),
		"41": _(u"k"),
		"42": _(u"k"),
		"43": _(u"k"),
		"44": _(u"b"),
		"45": _(u"g"),
		"46": _(u"k"),
		"47": _(u"f"),
		"na": _(u""),
		"-": _(u"")
	}

	conditions_moon_font = {
		"0": _(u"0"),
		"1": _(u"1"),
		"2": _(u"2"),
		"3": _(u"3"),
		"4": _(u"4"),
		"5": _(u"5"),
		"6": _(u"6"),
		"7": _(u"7"),
		"8": _(u"8"),
		"9": _(u"9"),
		"10": _(u"10"),
		"11": _(u"11"),
		"12": _(u"12"),
		"13": _(u"13"),
		"14": _(u"14"),
		"15": _(u"15"),
		"16": _(u"16"),
		"17": _(u"17"),
		"18": _(u"18"),
		"19": _(u"19"),
		"20": _(u"20"),
		"21": _(u"21"),
		"22": _(u"22"),
		"23": _(u"23"), 
		"24": _(u"24"),
		"25": _(u"25"),
		"na": _(u""),
		"-": _(u"")
	}
		
	day_of_week = {
		"Today": _(u"Today"),
		"Monday": _(u"Monday"),
		"Tuesday": _(u"Tuesday"),
		"Wednesday": _(u"Wednesday"),
		"Thursday": _(u"Thursday"),
		"Friday": _(u"Friday"),
		"Saturday": _(u"Saturday"),
		"Sunday": _(u"Sunday")
	}

	day_of_week_short = {
		"Today": _(u"Now"),
		"Monday": _(u"Mon"),
		"Tuesday": _(u"Tue"),
		"Wednesday": _(u"Wed"),
		"Thursday": _(u"Thu"),
		"Friday": _(u"Fri"),
		"Saturday": _(u"Sat"),
		"Sunday": _(u"Sun")
	}

	day_of_week_es = {
		"Today": _(u"hoy"),
		"Monday": _(u"lunes"),
		"Tuesday": _(u"martes"),
		"Wednesday": _(u"miércoles"),
		"Thursday": _(u"jueves"),
		"Friday": _(u"viernes"),
		"Saturday": _(u"sábado"),
		"Sunday": _(u"domingo")
	}

	day_of_week_short_es = {
		"Today": _(u"hoy"),
		"Monday": _(u"lun"),
		"Tuesday": _(u"mar"),
		"Wednesday": _(u"mié"),
		"Thursday": _(u"jue"),
		"Friday": _(u"vie"),
		"Saturday": _(u"sáb"),
		"Sunday": _(u"dom")
	}

	day_of_week_fr = {
		"Today": _(u"Aujourd'hui"),
		"Monday": _(u"Lundi"),
		"Tuesday": _(u"Mardi"),
		"Wednesday": _(u"Mercredi"),
		"Thursday": _(u"Jeudi"),
		"Friday": _(u"Vendredi"),
		"Saturday": _(u"Samedi"),
		"Sunday": _(u"Dimanche")
	}

	day_of_week_short_fr = {
		"Today": _(u"Auj"),
		"Monday": _(u"Lun"),
		"Tuesday": _(u"Mar"),
		"Wednesday": _(u"Mer"),
		"Thursday": _(u"Jeu"),
		"Friday": _(u"Ven"),
		"Saturday": _(u"Sam"),
		"Sunday": _(u"Dim")
	}

	bearing_arrow_font = {
		"N": _(u"i"),
		"NNE": _(u"j"),
		"NE": _(u"k"),
		"ENE": _(u"l"),
		"E": _(u"m"),
		"ESE": _(u"n"),
		"SE": _(u"o"),
		"SSE": _(u"p"),
		"S": _(u"a"),
		"SSW": _(u"b"),
		"SW": _(u"c"),
		"WSW": _(u"d"),
		"W": _(u"e"),
		"WNW": _(u"f"),
		"NW": _(u"g"),
		"NNW": _(u"h"),
		"N/A": _(u" ")
	}

	bearing_text_es = {
		"N": _(u"N"),
		"NNE": _(u"NNE"),
		"NE": _(u"NE"),
		"ENE": _(u"ENE"),
		"E": _(u"E"),
		"ESE": _(u"ESE"),
		"SE": _(u"SE"),
		"SSE": _(u"SSE"),
		"S": _(u"S"),
		"SSW": _(u"SSO"),
		"SW": _(u"SO"),
		"WSW": _(u"WOW"),
		"W": _(u"O"),
		"WNW": _(u"ONO"),
		"NW": _(u"NO"),
		"NNW": _(u"NNO"),
		"N/A": _(u"N\A")
	}

	bearing_text_fr = {
		"N": _(u"N"),
		"NNE": _(u"NNE"),
		"NE": _(u"NE"),
		"ENE": _(u"ENE"),
		"E": _(u"E"),
		"ESE": _(u"ESE"),
		"SE": _(u"SE"),
		"SSE": _(u"SSE"),
		"S": _(u"S"),
		"SSW": _(u"SSO"),
		"SW": _(u"SO"),
		"WSW": _(u"WOW"),
		"W": _(u"O"),
		"WNW": _(u"ONO"),
		"NW": _(u"NO"),
		"NNW": _(u"NNO"),
		"N/A": _(u"N\A")		
	}
			  
class GlobalWeather:

	current_conditions = []
	day_forecast = []
	night_forecast = []

	locale = "en"

	options = None
	weatherxmldoc = ""

 	TEMP_FILEPATH_CURRENT = "/tmp/conkyForecast-c-LOCATION.pkl"
	TEMP_FILEPATH_DAYFORECAST = "/tmp/conkyForecast-df-LOCATION.pkl"
	TEMP_FILEPATH_NIGHTFORECAST = "/tmp/conkyForecast-nf-LOCATION.pkl"
 	EXPIRY_MINUTES = 30
	DEFAULT_SPACING = u" "
		

	def __init__(self,options):

		self.options = options
		
		if self.options.locale == None:
			try:
				self.locale = locale.getdefaultlocale()[0][0:2]
				#self.locale = "es" #uncomment this line to force Spanish locale
				#self.locale = "fr" #uncomment this line to force French locale				
			except:
				print "locale not set"
		else:
			self.locale = self.options.locale
			#self.locale = "es" #uncomment this line to force Spanish locale
			#self.locale = "fr" #uncomment this line to force French locale	

		if self.options.verbose == True:
			print >> sys.stdout, "locale set to ",self.locale

	def getText(self,nodelist):
		rc = ""
		for node in nodelist:
			if node.nodeType == node.TEXT_NODE:
				rc = rc + node.data
		return rc


	def getSpaces(self,spaces):
		string = u""
		if spaces == None:
			string = self.DEFAULT_SPACING
		else:
			for i in range(0, spaces+1):
				string = string + u" "
		return string


	def isNumeric(self,string):
		try:
			dummy = float(string)
			return True
		except:
			return False

	def isConnectionAvailable(self):
		# ensure we can access weather.com's server by opening the url
		try:
			usock = urllib2.urlopen('http://xoap.weather.com')
			usock.close()
			return True
		except:
			return False

	def getBearingText(self,bearing):
		bearing = float(bearing)
		if bearing < 11.25:
			return u"N"
		elif bearing < 33.75:
			return u"NNE"
		elif bearing < 56.25:
			return u"NE"
		elif bearing < 78.75:
			return u"ENE"
		elif bearing < 101.25:
			return u"E"
		elif bearing < 123.75:
			return u"ESE"
		elif bearing < 146.25:
			return u"SE"
		elif bearing < 168.75:
			return u"SSE"
		elif bearing < 191.25:
			return u"S"
		elif bearing < 213.75:
			return u"SSW"
		elif bearing < 236.25:
			return u"SW"
		elif bearing < 258.75:
			return u"WSW"
		elif bearing < 281.25:
			return u"W"
		elif bearing < 303.75:
			return u"WNW"
		elif bearing < 326.25:
			return u"NW"
		elif bearing < 348.75:
			return u"NNW"
		else:
			return "N/A"

	def convertCelsiusToFahrenheit(self,temp):
		return str(int(floor(((float(temp)*9.0)/5.0)+32)))

	def convertKilometresToMiles(self,dist):
		return str(int(floor(float(dist)*0.621371192)))

	def convertMillibarsToInches(self,mb):
		return str(int(floor(float(mb)/33.8582)))

	def getTemplateList(self,template):

		templatelist = []
	
		for template_part in template.split("{"):
			if template_part != "":
				for template_part in template_part.split("}"):
					if template_part != "":
						templatelist.append(u""+template_part)

		return templatelist


	def getOutputText(self,datatype,startday,endday,night,shortweekday,imperial,hideunits,spaces):
		#try:
			output = u""
		
			# define current units for output
			if hideunits == False:
				if imperial == False:
					tempunit = u"C"
					speedunit = u"kph"
					pressureunit = u"mb"
				else:
					tempunit = u"F"
					speedunit = u"mph"
					pressureunit = u"in"
			else:
				tempunit = u""
				speedunit = u""
				pressureunit = u""

			if startday == None: # current conditions

				if datatype == "DW":
					if self.locale == "es":
						if shortweekday == True:
							output = WeatherText.day_of_week_short_es[self.current_conditions[0].day_of_week]
						else:
							output = WeatherText.day_of_week_es[self.current_conditions[0].day_of_week]
					elif self.locale == "fr":
						if shortweekday == True:
							output = WeatherText.day_of_week_short_fr[self.current_conditions[0].day_of_week]
						else:
							output = WeatherText.day_of_week_fr[self.current_conditions[0].day_of_week]							
					else:
						if shortweekday == True:
							output = WeatherText.day_of_week_short[self.current_conditions[0].day_of_week]
						else:
							output = WeatherText.day_of_week[self.current_conditions[0].day_of_week]
				elif datatype == "WF": # weather font
					output = WeatherText.conditions_weather_font[self.current_conditions[0].condition_code]
				elif datatype == "LT":
					string = self.current_conditions[0].low
					if self.isNumeric(string) == True:
						if imperial == True:
							string = self.convertCelsiusToFahrenheit(string)
						string = string + tempunit
					output = string
				elif datatype == "HT":
					string = self.current_conditions[0].high
					if self.isNumeric(string) == True:
						if imperial == True:
							string = self.convertCelsiusToFahrenheit(string)
						string = string + tempunit
					output = string
				elif datatype == "CC":
					if self.locale == "es":
						output = WeatherText.conditions_text_es[self.current_conditions[0].condition_code]
					elif self.locale == "fr":
						output = WeatherText.conditions_text_fr[self.current_conditions[0].condition_code]						
					else:
						output = WeatherText.conditions_text[self.current_conditions[0].condition_code] 
				elif datatype == "CT":
					output = self.current_conditions[0].condition_text
				elif datatype == "PC":
					string = self.current_conditions[0].precip
					if self.isNumeric(string) == True:
						string = string + u"%"
					output = string
				elif datatype == "HM":
					string = self.current_conditions[0].humidity
					if self.isNumeric(string) == True:
						string = string + u"%"
					output = string
				elif datatype == "WD":
					string = self.current_conditions[0].wind_dir
					if self.isNumeric(string) == True:
						string = self.getBearingText(string)
						
					if self.locale == "es":
						output = WeatherText.bearing_text_es[string]
					elif self.locale == "fr":
						output = WeatherText.bearing_text_fr[string]
					else:
						output = string
											
				elif datatype == "BF":
					string = self.current_conditions[0].wind_dir
					if self.isNumeric(string) == True:
						string = WeatherText.bearing_arrow_font[self.getBearingText(string)]
					output = string					
				elif datatype == "WS":
					string = self.current_conditions[0].wind_speed
					if self.isNumeric(string) == True:
						if imperial == True:
							string = self.convertKilometresToMiles(string)
						string = string + speedunit
					output = string
				elif datatype == "WG":
					string = self.current_conditions[0].wind_gusts
					if self.isNumeric(string) == True:
						if imperial == True:
							string = self.convertKilometresToMiles(string)
						string = string + speedunit
					output = string
				elif datatype == "CN":
					output = self.current_conditions[0].city
				elif datatype == "SR":
					output = self.current_conditions[0].sunrise
				elif datatype == "SS":
					output = self.current_conditions[0].sunset
				elif datatype == "MP":
					output = self.current_conditions[0].moon_phase
				elif datatype == "MF":
					output = WeatherText.conditions_moon_font[self.current_conditions[0].moon_icon]							
				elif datatype == "BR":
					string = self.current_conditions[0].bar_read
					if self.isNumeric(string) == True:
						if imperial == True:
							string = self.convertMillibarsToInches(string)
						string = string + pressureunit
					output = string
				elif datatype == "BD":
					output = self.current_conditions[0].bar_desc
				else:
					output = "\nERROR:Unknown data type requested"

			else: # forecast data

				if endday == None: # if no endday was set use startday
					endday = startday

				if night == True: # night forecast required

					for day_number in range(startday, endday+1):

						if datatype == "DW":
							if self.locale == "es":
								if shortweekday == True:
									output = output + self.getSpaces(spaces) + WeatherText.day_of_week_short_es[self.night_forecast[day_number].day_of_week]
								else:
									output = output + self.getSpaces(spaces) + WeatherText.day_of_week_es[self.night_forecast[day_number].day_of_week]
							elif self.locale == "fr":
								if shortweekday == True:
									output = output + self.getSpaces(spaces) + WeatherText.day_of_week_short_fr[self.night_forecast[day_number].day_of_week]
								else:
									output = output + self.getSpaces(spaces) + WeatherText.day_of_week_fr[self.night_forecast[day_number].day_of_week]
							else:
								if shortweekday == True:
									output = output + self.getSpaces(spaces) + WeatherText.day_of_week_short[self.night_forecast[day_number].day_of_week]
								else:
									output = output + self.getSpaces(spaces) + WeatherText.day_of_week[self.night_forecast[day_number].day_of_week]
						elif datatype == "WF": # weather font
							output = output + self.getSpaces(spaces) + WeatherText.conditions_weather_font[self.night_forecast[day_number].condition_code]
						elif datatype == "LT":
							string = self.night_forecast[day_number].low
							if self.isNumeric(string) == True:
								if imperial == True:
									string = self.convertCelsiusToFahrenheit(string)
								string = string + tempunit
							output = output + self.getSpaces(spaces) + string

						elif datatype == "HT":
							string = self.night_forecast[day_number].high
							if self.isNumeric(string) == True:
								if imperial == True:
									string = self.convertCelsiusToFahrenheit(string)
								string = string + tempunit
							output = output + self.getSpaces(spaces) + string
						elif datatype == "CC":
							if self.locale == "es":
								output = output + self.getSpaces(spaces) + WeatherText.conditions_text_es[self.night_forecast[day_number].condition_code]
							elif self.locale == "fr":
								output = output + self.getSpaces(spaces) + WeatherText.conditions_text_fr[self.night_forecast[day_number].condition_code]
							else:
								output = output + self.getSpaces(spaces) + WeatherText.conditions_text[self.night_forecast[day_number].condition_code]
						elif datatype == "CT":
							output = output + self.getSpaces(spaces) + self.night_forecast[day_number].condition_text
						elif datatype == "PC":
							string = self.night_forecast[day_number].precip
							if self.isNumeric(string) == True:
								string = string + u"%"
							output = output + self.getSpaces(spaces) + string
						elif datatype == "HM":
							string = self.night_forecast[day_number].humidity
							if self.isNumeric(string) == True:
								string = string + u"%"
							output = output + self.getSpaces(spaces) + string
						elif datatype == "WD":
							string = self.night_forecast[day_number].wind_dir
							if self.locale == "es":
								output = output + self.getSpaces(spaces) + WeatherText.bearing_text_es[string]
							elif self.locale == "fr":
								output = output + self.getSpaces(spaces) + WeatherText.bearing_text_fr[string]
							else:
								output = output + self.getSpaces(spaces) + string
                            
						elif datatype == "BF":
							output = output + self.getSpaces(spaces) + WeatherText.bearing_arrow_font[self.night_forecast[day_number].wind_dir]
						elif datatype == "WS":
							string = self.night_forecast[day_number].wind_speed
							if self.isNumeric(string) == True:
								if imperial == True:
									string = self.convertKilometresToMiles(string)
								string = string + speedunit
							output = output + self.getSpaces(spaces) + string
						elif datatype == "WG":
							string = self.night_forecast[day_number].wind_gusts
							if self.isNumeric(string) == True:
								if imperial == True:
									string = self.convertKilometresToMiles(string)
								string = string + speedunit
							output = output + self.getSpaces(spaces) + string
						elif datatype == "CN":
							output = output + self.getSpaces(spaces) + self.night_forecast[day_number].city
						elif datatype == "SR":
							output = output + self.getSpaces(spaces) + self.night_forecast[day_number].sunrise
						elif datatype == "SS":
							output = output + self.getSpaces(spaces) + self.night_forecast[day_number].sunset
						elif datatype == "MP":
							output = output + self.getSpaces(spaces) + self.night_forecast[day_number].moon_phase
						elif datatype == "MF":
							output = output + self.getSpaces(spaces) + WeatherText.conditions_moon_font[self.night_forecast[day_number].moon_icon]
						elif datatype == "BR":
							output = output + self.getSpaces(spaces) + self.night_forecast[day_number].bar_read
						elif datatype == "BD":
							output = output + self.getSpaces(spaces) + self.night_forecast[day_number].bar_desc
						else:
							output = "\nERROR:Unknown data type requested"
							break

				else: # day forecast wanted

					for day_number in range(startday, endday+1):

						if datatype == "DW":
							if self.locale == "es":
								if shortweekday == True:
									output = output + self.getSpaces(spaces) + WeatherText.day_of_week_short_es[self.day_forecast[day_number].day_of_week]
								else:
									output = output + self.getSpaces(spaces) + WeatherText.day_of_week_es[self.day_forecast[day_number].day_of_week]
							elif self.locale == "fr":
								if shortweekday == True:
									output = output + self.getSpaces(spaces) + WeatherText.day_of_week_short_fr[self.day_forecast[day_number].day_of_week]
								else:
									output = output + self.getSpaces(spaces) + WeatherText.day_of_week_fr[self.day_forecast[day_number].day_of_week]									
							else:
								if shortweekday == True:
									output = output + self.getSpaces(spaces) + WeatherText.day_of_week_short[self.day_forecast[day_number].day_of_week]
								else:
									output = output + self.getSpaces(spaces) + WeatherText.day_of_week[self.day_forecast[day_number].day_of_week]
						elif datatype == "WF": # weather font
							output = output + self.getSpaces(spaces) + WeatherText.conditions_weather_font[self.day_forecast[day_number].condition_code]
						elif datatype == "LT":
							string = self.day_forecast[day_number].low
							if self.isNumeric(string) == True:
								if imperial == True:
									string = self.convertCelsiusToFahrenheit(string)
								string = string + tempunit
							output = output + self.getSpaces(spaces) + string
						elif datatype == "HT":
							string = self.day_forecast[day_number].high
							if self.isNumeric(string) == True:
								if imperial == True:
									string = self.convertCelsiusToFahrenheit(string)
								string = string + tempunit
							output = output + self.getSpaces(spaces) + string
						elif datatype == "CC":
							if self.locale == "es":
								output = output + self.getSpaces(spaces) + WeatherText.conditions_text_es[self.day_forecast[day_number].condition_code]
							elif self.locale == "fr":
								output = output + self.getSpaces(spaces) + WeatherText.conditions_text_fr[self.day_forecast[day_number].condition_code]
							else:
								output = output + self.getSpaces(spaces) + WeatherText.conditions_text[self.day_forecast[day_number].condition_code]
						elif datatype == "CT":
							output = output + self.getSpaces(spaces) + self.day_forecast[day_number].condition_text
						elif datatype == "PC":
							string = self.day_forecast[day_number].precip
							if self.isNumeric(string) == True:
								string = string + u"%"
							output = output + self.getSpaces(spaces) + string
						elif datatype == "HM":
							string = self.day_forecast[day_number].humidity
							if self.isNumeric(string) == True:
								string = string + u"%"
							output = output + self.getSpaces(spaces) + string
						elif datatype == "WD":
							string = self.day_forecast[day_number].wind_dir
							
							if self.locale == "es":
								output = output + self.getSpaces(spaces) + WeatherText.bearing_text_es[string]
							elif self.locale == "fr":
								output = output + self.getSpaces(spaces) + WeatherText.bearing_text_fr[string]
							else:
								output = output + self.getSpaces(spaces) + string	

						elif datatype == "BF":
							output = output + self.getSpaces(spaces) + WeatherText.bearing_arrow_font[self.day_forecast[day_number].wind_dir]
						elif datatype == "WS":
							string = self.day_forecast[day_number].wind_speed
							if self.isNumeric(string) == True:
								if imperial == True:
									string = self.convertKilometresToMiles(string)
								string = string + speedunit
							output = output + self.getSpaces(spaces) + string
						elif datatype == "WG":
							string = self.day_forecast[day_number].wind_gusts
							if self.isNumeric(string) == True:
								if imperial == True:
									string = self.convertKilometresToMiles(string)
								string = string + speedunit
							output = output + self.getSpaces(spaces) + string
						elif datatype == "CN":
							output = output + self.getSpaces(spaces) + self.day_forecast[day_number].city
						elif datatype == "SR":
							output = output + self.getSpaces(spaces) + self.day_forecast[day_number].sunrise
						elif datatype == "SS":
							output = output + self.getSpaces(spaces) + self.day_forecast[day_number].sunset
						elif datatype == "MP":
							output = output + self.getSpaces(spaces) + self.day_forecast[day_number].moon_phase
						elif datatype == "MF":
							output = output + self.getSpaces(spaces) + WeatherText.conditions_moon_font[self.day_forecast[day_number].moon_icon]
						elif datatype == "BR":
							output = output + self.getSpaces(spaces) + self.day_forecast[day_number].bar_read
						elif datatype == "BD":
							output = output + self.getSpaces(spaces) + self.day_forecast[day_number].bar_desc
						else:
							output = u"\nERROR:Unknown data type requested"
							break

			output = u""+output.strip(u" ") # lose leading/trailing spaces
			return output

		#except:
			#print "getOutputText:Unexpected error: ", sys.exc_info()[0]


	def getOutputTextFromTemplate(self,template):
		#try:

			# keys to template data
			DATATYPE_KEY = "--datatype="
			STARTDAY_KEY = "--startday="
			ENDDAY_KEY = "--endday="
			NIGHT_KEY = "--night"
			SHORTWEEKDAY_KEY = "--shortweekday"
			IMPERIAL_KEY = "--imperial"
			HIDEUNITS_KEY = "--hideunits"
			SPACES_KEY = "--spaces="

			output = u""

			optionfound = False

			#load the file
			try:
				fileinput = open(self.options.template)
				template = fileinput.read()
				fileinput.close()
			except:
				output = u"Template file no found!"

			templatelist = self.getTemplateList(template)

			# lets walk through the template list and determine the output for each item found
			for i in range(0,len(templatelist)-1):

				pos = templatelist[i].find(DATATYPE_KEY)
				if pos != -1:
					optionfound = True
					pos = pos + len(DATATYPE_KEY)
					datatype = templatelist[i][pos:pos+4].strip("}").strip("{").strip("-").strip(" ")
				else:
					datatype = None

				pos = templatelist[i].find(STARTDAY_KEY)
				if pos != -1:
					optionfound = True
					pos = pos + len(STARTDAY_KEY)
					startday = int(templatelist[i][pos:pos+4].strip("}").strip("{").strip("-").strip(" "))
				else:
					startday = None

				pos = templatelist[i].find(ENDDAY_KEY)
				if pos != -1:
					optionfound = True
					pos = pos + len(ENDDAY_KEY)
					endday = int(templatelist[i][pos:pos+4].strip("}").strip("{").strip("-").strip(" "))
				else:
					endday = None

				pos = templatelist[i].find(NIGHT_KEY)
				if pos != -1:
					optionfound = True
					night = True
				else:
					night = False

				pos = templatelist[i].find(SHORTWEEKDAY_KEY)
				if pos != -1:
					optionfound = True
					shortweekday = True
				else:
					shortweekday = False

				pos = templatelist[i].find(IMPERIAL_KEY)
				if pos != -1:
					optionfound = True
					imperial = True
				else:
					imperial = False

				pos = templatelist[i].find(HIDEUNITS_KEY)
				if pos != -1:
					optionfound = True
					hideunits = True
				else:
					hideunits = False

				pos = templatelist[i].find(SPACES_KEY)
				if pos != -1:
					optionfound = True
					pos = pos + len(SPACES_KEY)
					spaces = int(templatelist[i][pos:pos+4].strip("}").strip("{").strip("-").strip(" "))
				else:
					spaces = 1

				if optionfound == True:
					templatelist[i] = self.getOutputText(datatype,startday,endday,night,shortweekday,imperial,hideunits,spaces)
					optionfound = False

			# go through the list concatenating the output now that it's been populated
			for item in templatelist:
				output = output + item

			return output

		#except:
			#print "getOutputTextFromTemplate:Unexpected error: ", sys.exc_info()[0]


	def fetchData(self):

		# always fetch metric data, use conversation functions on this data
		file_path_current = self.TEMP_FILEPATH_CURRENT.replace("LOCATION",self.options.location)
		file_path_dayforecast = self.TEMP_FILEPATH_DAYFORECAST.replace("LOCATION",self.options.location)
		file_path_nightforecast = self.TEMP_FILEPATH_NIGHTFORECAST.replace("LOCATION",self.options.location)

		if self.isConnectionAvailable() == False:
			if os.path.exists(file_path_current):
				RefetchData = False
			else: # no connection, no cache, bang!
				print "No internet connection is available and no cached weather data exists."
		elif self.options.refetch == True:
			RefetchData = True
		else:
	 		# does the data need retrieving again?
	 		if os.path.exists(file_path_current):
	 			lastmodDate = time.localtime(os.stat(file_path_current)[ST_MTIME])
				expiryDate = (datetime.datetime.today() - datetime.timedelta(minutes=self.EXPIRY_MINUTES)).timetuple()

				if expiryDate > lastmodDate:
					RefetchData = True
				else:
					RefetchData = False
			else:
				RefetchData = True


                # fetch the current conditions data, either from the website or by 'unpickling'
 		if RefetchData == True:

			# obtain current conditions data from xoap service
			try:

				# http://xoap.weather.com/weather/local/UKXX0103?cc=*&dayf=5&link=xoap&prod=xoap&par=1061785028&key=e374effbfd74930b

				url = 'http://xoap.weather.com/weather/local/' + self.options.location + '?cc=*&dayf=8&link=xoap&prod=xoap&par=1061785028&key=e374effbfd74930b&unit=m'
				if self.options.verbose == True:
					print >> sys.stdout, "fetching weather data from ",url

				usock = urllib2.urlopen(url)
				xml = usock.read()
				usock.close()
				self.weatherxmldoc = minidom.parseString(xml)
			except:
				print "fetchData:Unexpected error: ", sys.exc_info()[0]
				print "Unable to contact weather source for current conditions"

			# tell the user if the location is bad...
			found = xml.find("Invalid location provided")
			if found != -1:
				print "Invalid location provided"

			# interrogate weather data, load into class structure and pickle it
			try:

				# prepare weather data lists
				self.current_conditions = []
				self.day_forecast = []
				self.night_forecast = []

				# collect general data
				weather_n = self.weatherxmldoc.documentElement
				location_n = weather_n.getElementsByTagName('loc')[0]
				city_n = location_n.getElementsByTagName('dnam')[0]
				city = self.getText(city_n.childNodes)

				# collect current conditions data
				day_of_week = u"Today"
				precip = u"N/A"
				sunrise_n = location_n.getElementsByTagName('sunr')[0]
				sunrise = self.getText(sunrise_n.childNodes)
				sunset_n = location_n.getElementsByTagName('suns')[0]
				sunset = self.getText(sunset_n.childNodes)
				current_condition_n = weather_n.getElementsByTagName('cc')[0]
				current_desc_n = current_condition_n.getElementsByTagName('t')[0]
				current_desc = self.getText(current_desc_n.childNodes)
				current_code_n = current_condition_n.getElementsByTagName('icon')[0]
				current_code = self.getText(current_code_n.childNodes)
				current_temp_n = current_condition_n.getElementsByTagName('tmp')[0]
				current_temp = self.getText(current_temp_n.childNodes)
				current_temp_feels_n = current_condition_n.getElementsByTagName('flik')[0]
				current_temp_feels = self.getText(current_temp_feels_n.childNodes)
				bar_n = current_condition_n.getElementsByTagName('bar')[0]
				bar_read_n = bar_n.getElementsByTagName('r')[0]
				bar_read = self.getText(bar_read_n.childNodes)
				bar_desc_n = bar_n.getElementsByTagName('d')[0]
				bar_desc = self.getText(bar_desc_n.childNodes)
				wind_n = current_condition_n.getElementsByTagName('wind')[0]
				wind_speed_n = wind_n.getElementsByTagName('s')[0]
				wind_speed = self.getText(wind_speed_n.childNodes)
				wind_gust_n = wind_n.getElementsByTagName('gust')[0]
				wind_gusts = self.getText(wind_gust_n.childNodes)
				wind_dir_n = wind_n.getElementsByTagName('d')[0]
				wind_direction = self.getText(wind_dir_n.childNodes)
				humidity_n = current_condition_n.getElementsByTagName('hmid')[0]
				humidity = self.getText(humidity_n.childNodes)
				moon_n = current_condition_n.getElementsByTagName('moon')[0]
				moon_icon_n = moon_n.getElementsByTagName('icon')[0]
				moon_icon = self.getText(moon_icon_n.childNodes)
				moon_phase_n = moon_n.getElementsByTagName('t')[0]
				moon_phase = self.getText(moon_phase_n.childNodes)
				current_conditions_data = WeatherData(day_of_week, current_temp_feels, current_temp, current_code, current_desc, precip, humidity, wind_direction, wind_speed, wind_gusts, city, sunrise, sunset, moon_phase, moon_icon, bar_read, bar_desc)
				self.current_conditions.append(current_conditions_data)

				# collect forecast data
				bar_read = u"N/A"
				bar_desc = u"N/A"
				moon_phase = u"N/A"
				moon_icon = u"na"
				forecast_n = weather_n.getElementsByTagName('dayf')[0]
				day_nodes = forecast_n.getElementsByTagName('day')
	
				for day in day_nodes:
					day_of_week = day.getAttribute('t')
					day_of_year = day.getAttribute('dt')
					high_temp_n = day.getElementsByTagName('hi')[0]
					high_temp = self.getText(high_temp_n.childNodes)
					low_temp_n = day.getElementsByTagName('low')[0]
					low_temp = self.getText(low_temp_n.childNodes)

					sunrise_n = day.getElementsByTagName('sunr')[0]
					sunrise = self.getText(sunrise_n.childNodes)
					sunset_n = day.getElementsByTagName('suns')[0]
					sunset = self.getText(sunset_n.childNodes)

					# day forecast specific data
					daytime_n = day.getElementsByTagName('part')[0] # day
					condition_code_n = daytime_n.getElementsByTagName('icon')[0]
					condition_code = self.getText(condition_code_n.childNodes)
					condition_n = daytime_n.getElementsByTagName('t')[0]
					condition = self.getText(condition_n.childNodes)
					precip_n = daytime_n.getElementsByTagName('ppcp')[0]
					precip = self.getText(precip_n.childNodes)
					humidity_n = daytime_n.getElementsByTagName('hmid')[0]
					humidity = self.getText(humidity_n.childNodes)
					wind_n = daytime_n.getElementsByTagName('wind')[0]
					wind_speed_n = wind_n.getElementsByTagName('s')[0]
					wind_speed = self.getText(wind_speed_n.childNodes)
					wind_direction_n = wind_n.getElementsByTagName('t')[0]
					wind_direction = self.getText(wind_direction_n.childNodes)
					wind_gusts_n = wind_n.getElementsByTagName('gust')[0]
					wind_gusts = self.getText(wind_gusts_n.childNodes)
					day_forecast_data = WeatherData(day_of_week, low_temp, high_temp, condition_code, condition, precip, humidity, wind_direction, wind_speed, wind_gusts, city, sunrise, sunset, moon_phase, moon_icon, bar_read, bar_desc)
					self.day_forecast.append(day_forecast_data) 	

					# night forecast specific data
					daytime_n = day.getElementsByTagName('part')[1] # night
					condition_code_n = daytime_n.getElementsByTagName('icon')[0]
					condition_code = self.getText(condition_code_n.childNodes)
					condition_n = daytime_n.getElementsByTagName('t')[0]
					condition = self.getText(condition_n.childNodes)
					precip_n = daytime_n.getElementsByTagName('ppcp')[0]
					precip = self.getText(precip_n.childNodes)
					humidity_n = daytime_n.getElementsByTagName('hmid')[0]
					humidity = self.getText(humidity_n.childNodes)
					wind_n = daytime_n.getElementsByTagName('wind')[0]
					wind_speed_n = wind_n.getElementsByTagName('s')[0]
					wind_speed = self.getText(wind_speed_n.childNodes)
					wind_direction_n = wind_n.getElementsByTagName('t')[0]
					wind_direction = self.getText(wind_direction_n.childNodes)
					wind_gusts_n = wind_n.getElementsByTagName('gust')[0]
					wind_gusts = self.getText(wind_gusts_n.childNodes)
					night_forecast_data = WeatherData(day_of_week, low_temp, high_temp, condition_code, condition, precip, humidity, wind_direction, wind_speed, wind_gusts, city, sunrise, sunset, moon_phase, moon_icon, bar_read, bar_desc)
					self.night_forecast.append(night_forecast_data) 


				# pickle the data for next time!
				fileoutput = open(file_path_current, 'w')
 				pickle.dump(self.current_conditions,fileoutput)
		 		fileoutput.close()

				fileoutput = open(file_path_dayforecast, 'w')
 				pickle.dump(self.day_forecast,fileoutput)
		 		fileoutput.close()

				fileoutput = open(file_path_nightforecast, 'w')
 				pickle.dump(self.night_forecast,fileoutput)
		 		fileoutput.close()
		
			except:
				print "fetchData:Unexpected error: ", sys.exc_info()[0]
				print "Unable to interrogate the weather data"

		else: # fetch weather data from pickled class files
			if self.options.verbose == True:
				print >> sys.stdout, "fetching weather data from file: ",file_path_current

 			fileinput = open(file_path_current, 'r')
			self.current_conditions = pickle.load(fileinput)
			fileinput.close()

			if self.options.verbose == True:
				print >> sys.stdout, "fetching day forecast data from files: ",file_path_dayforecast, file_path_nightforecast

 			fileinput = open(file_path_dayforecast, 'r')
			self.day_forecast = pickle.load(fileinput)
			fileinput.close()

			if self.options.verbose == True:
				print >> sys.stdout, "fetching day forecast data from files: ",file_path_nightforecast, file_path_nightforecast

 			fileinput = open(file_path_nightforecast, 'r')
			self.night_forecast = pickle.load(fileinput)
			fileinput.close()

	def outputData(self):
		#try:

			if self.options.template != None:

				output = self.getOutputTextFromTemplate(self.options.template)

			else:

				output = self.getOutputText(self.options.datatype,self.options.startday,self.options.endday,self.options.night,self.options.shortweekday,self.options.imperial,self.options.hideunits,self.options.spaces)


			print output.encode("utf-8")

		#except:
			#print "outputData:Unexpected error: ", sys.exc_info()[0]

if __name__ == "__main__":

	parser = CommandLineParser()
	(options, args) = parser.parse_args()

	if options.verbose == True:
		print >> sys.stdout, "location:",options.location
		print >> sys.stdout, "imperial:",options.imperial
		print >> sys.stdout, "datatype:",options.datatype
		print >> sys.stdout, "night:",options.night
		print >> sys.stdout, "start day:",options.startday
		print >> sys.stdout, "end day:",options.endday
		print >> sys.stdout, "spaces:",options.spaces
		print >> sys.stdout, "verbose:",options.verbose
		print >> sys.stdout, "refetch:",options.refetch

	# create new global weather object
	weather = GlobalWeather(options)
	weather.fetchData()
	weather.outputData()


