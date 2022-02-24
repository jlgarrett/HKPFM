#pragma rtGlobals=1		// Use modern global access method and strict wave access.
//None of the functions displayed in the panel work yet
//This text will be updated as the functionality of the panel expands

Static constant nsweep = 2016 //The length of the voltage wave when measuring discretely
Static constant nruns = 600 //I don't remember what this is

//Static constant Num = 7//The number of different voltages in the discrete measurement scheme
//Static constant imax = 13//N is number of voltage measurements, imax = 2N -1
//I really need to go through and (re-)annotate this code - J 2015


Function initKPFManalyzer()
	NewDataFolder/O root:packages:KelvinVoltage
	SetDataFolder root:packages:KelvinVoltage
	String/G runname = "Default"
	
	Make/o/n=2 calibrations
	make/o/N=6 KPFM_parameters = {800,500,600000,1,1,4}
	make/o/n=6/t KPFM_labels = {"FM_fA", "PV_f", "H_fD", "V_AC","CounterBias","illPulse_voltage"}
	 dim_settern( KPFM_labels, 0, KPFM_parameters ) 
	
	Make/o Countwave= {-1,1,1,0}, Voltageparms = {0,3, 5}, Heightparms = {NaN, 1e-9, 1e-9}, ACampparms = {0,1,9}, Freqparms = {0,0,0} , Illuminationparms = {10}, Generalparms = {0,1,0,0,0,0}// number, seconds, # of secondary(0 if none) 
	make/o/n=(2,2) vars=0 //What is vars? {{total number to run of variable 1, number of variable 1 run thus far},{"" variable 2, "" variable 2 run thus far}}
	make/o/n=6/t to_measure = {"Arc.pipe.23.cypher.input.b", "Arc.pipe.22.cypher.input.a", "Arc.Lockin.1.i","Arc.Lockin.1.q","Arc.Lockin.DCOffset", "Arc.Output.C"}
	make/o/n=2/t outputs = {"Cypher.Lockin.B.0.i", "Cypher.Lockin.B.0.q"}
	String/G finalcallback = ""
	ClearWaves()
	
	td_ws("Cypher.pipehack.22","Lockin A0 i")
	td_ws("Cypher.pipehack.23","Lockin A0 q")
	td_ws("Cypher.pipehack.20","Lockin B1 i")
	td_ws("Cypher.pipehack.15","Lockin B0 r")
	
	InitializeHAMKPFM()
	execute("Operate_KPFMs()") 
	execute("KPFMVoltageAnalyzer()")
	
end

Function ClearWaves() //Clears the old data, should probably be cleaned up a little itself
	SetDataFolder root:packages:KelvinVoltage

	Wave countwave
	countwave[0] = -1
	 //Minimum and maximum Values for the AWAVE
	MakeDataWave()

end

//We want to include the storage of all data with the KPFMVoltageAnalyzer in its first rendtion
//The following function only includes the storage of preliminary data

Function MakeDataWave() //Makes a (new) wave to store data in. It may be worthwhile to try to make something more comprehensive
	Wave countwave
	
	SetDataFolder root:packages:KelvinVoltage
	
	String S_Value = ""
	variable duration = 1
	
	variable dlength = 5e3- Mod(5e3,32)
	countwave[3] = dlength
	//if there is not secondary variable
	controlinfo/W=KPFMVoltageAnalyzer Varying2

		Make/O/N = (7,1) prelims
		Make/O/N = (7,1,dlength) all1
	//if there is a secondary variable 

		Make/O/N = (7,countwave[2],1) prelims2nd
		
		Make/O/N = (7,countwave[2],1, dlength) all2

end

Window KPFMVoltageAnalyzer() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(2005,455,2801,914)
	ShowTools/A
	SetDrawLayer UserBack
	SetDrawEnv fname= "Georgia",fsize= 18
	DrawText 8,23,"KPFM and Voltage Analyzer"
	DrawText 21,50,"1st Variable"
	DrawText 293,50,"2nd Variable"
	DrawText 563,50,"Kelvin Probe"
	DrawText 23,136,"Height"
	DrawText 186,162,"Voltage"
	DrawText 23,228,"Illumination"
	DrawText 307,110,"Frequency"
	DrawText 178,275,"AC Voltage"
	DrawText 162,355,"LockinB Amplitude"
	DrawText 285,235,"LockinB Phase"
	PopupMenu Varying1,pos={21,52},size={71,22}
	PopupMenu Varying1,mode=6,popvalue="General",value= #"\"Height;Voltage;Illumination;AC Amplitude;LockinB Amplitude;General\""
	PopupMenu KelvinProbeType,pos={574,50},size={47,22}
	PopupMenu KelvinProbeType,mode=1,popvalue="Off",value= #"\"Off;Only Electrostatic;Simultaneous;Heterodyne\""
	PopupMenu Varying2,pos={304,52},size={58,22}
	PopupMenu Varying2,mode=1,popvalue="none",value= #"\"none;Frequency;AC amplitude;LockinB amplitude;LockinB phase;Voltage;General\""
	Button Illumination_set,pos={32,315},size={100,20},title="Illumination is set!"
	Button Illumination_set,fColor=(61440,61440,61440)
	SetVariable setvar0,pos={574,88},size={50,16}
	SetVariable setvar1,pos={574,126},size={50,16}
	SetVariable setvar2,pos={574,107},size={50,16}
	SetVariable Lockin_0_Filter_Freq,pos={632,51},size={153,18},bodyWidth=100,proc=FilterSetVarFunc,title="Lockin 0 "
	SetVariable Lockin_0_Filter_Freq,font="Arial",fSize=12,format="%.3W1PHz"
	SetVariable Lockin_0_Filter_Freq,fStyle=0
	SetVariable Lockin_0_Filter_Freq,limits={-inf,inf,100},value= root:packages:MFP3D:Main:Variables:FilterVariablesWave[%'Lockin.0.Filter.Freq'][%Value]
	SetVariable Lockin_1_Filter_Freq,pos={632,76},size={153,18},bodyWidth=100,proc=FilterSetVarFunc,title="Lockin 1 "
	SetVariable Lockin_1_Filter_Freq,font="Arial",fSize=12,format="%.3W1PHz"
	SetVariable Lockin_1_Filter_Freq,fStyle=0
	SetVariable Lockin_1_Filter_Freq,limits={-inf,inf,1000},value= root:packages:MFP3D:Main:Variables:FilterVariablesWave[%'Lockin.1.Filter.Freq'][%Value]
	SetVariable Max_Height,pos={5,178},size={84,16},bodyWidth=60,title="Max"
	SetVariable Max_Height,value= root:packages:KelvinVoltage:Heightparms[2]
	SetVariable Delta_Height,pos={2,158},size={89,16},bodyWidth=60,title="Delta"
	SetVariable Delta_Height,value= root:packages:KelvinVoltage:Heightparms[1]
	SetVariable genMin1,pos={390,287},size={81,16},bodyWidth=60,title="Min"
	SetVariable genMin1,value= root:packages:KelvinVoltage:Generalparms[0]
	SetVariable Duration,pos={138,52},size={104,16},bodyWidth=60,title="Duration"
	SetVariable Duration,value= root:packages:KelvinVoltage:Countwave[1]
	SetVariable GenMax1,pos={387,306},size={84,16},bodyWidth=60,title="Max"
	SetVariable GenMax1,value= root:packages:KelvinVoltage:Generalparms[1]
	Button button1,pos={22,78},size={60,20},title="Advance"
	Button button1,fColor=(61440,61440,61440)
	CheckBox AutoAdvance,pos={119,81},size={86,14},title="Auto Advance",value= 0
	ValDisplay Starting_Height,pos={6,140},size={86,14},bodyWidth=60,title="Start"
	ValDisplay Starting_Height,limits={0,0,0},barmisc={0,1000}
	ValDisplay Starting_Height,value= #"root:packages:KelvinVoltage:heightparms[0]"
	SetVariable V_Center,pos={139,167},size={95,16},bodyWidth=60,title="Center"
	SetVariable V_Center,value= root:packages:KelvinVoltage:Voltageparms[0]
	SetVariable Vwidth,pos={103,184},size={131,16},bodyWidth=60,title="Voltage Width"
	SetVariable Vwidth,value= root:packages:KelvinVoltage:Voltageparms[1]
	SetVariable V_num,pos={107,202},size={127,16},bodyWidth=60,title="# of Voltages"
	SetVariable V_num,value= root:packages:KelvinVoltage:Voltageparms[2]
	SetVariable Illumination_min,pos={0,236},size={105,16},bodyWidth=60,title="Minimum"
	SetVariable Illumination_number,pos={10,273},size={71,16},bodyWidth=60,title="#"
	SetVariable Illumination_Delta,pos={0,255},size={89,16},bodyWidth=60,title="Delta"
	ValDisplay valdisp1,pos={0,293},size={150,14},bodyWidth=60,title="Set Illumination to:"
	ValDisplay valdisp1,limits={0,0,0},barmisc={0,1000},value= #"0"
	SetVariable setvar12,pos={303,242},size={50,16}
	SetVariable setvar05,pos={303,280},size={50,16}
	SetVariable setvar13,pos={303,261},size={50,16}
	SetVariable setvar14,pos={152,276},size={107,16},bodyWidth=86,title="Min"
	SetVariable setvar14,value= root:packages:KelvinVoltage:ACampparms[0]
	SetVariable setvar06,pos={149,313},size={84,16},bodyWidth=60,title="Max"
	SetVariable setvar06,value= root:packages:KelvinVoltage:ACampparms[2]
	SetVariable setvar15,pos={144,295},size={89,16},bodyWidth=60,title="Delta"
	SetVariable setvar15,value= root:packages:KelvinVoltage:ACampparms[1]
	CheckBox check1,pos={28,103},size={123,14},disable=2,title="Two-step (if an option)"
	CheckBox check1,value= 1
	SetVariable setvar16,pos={183,359},size={50,16}
	SetVariable setvar07,pos={183,397},size={50,16}
	SetVariable setvar17,pos={183,378},size={50,16}
	CheckBox BF1,pos={104,126},size={136,14},title="Back and Forth (Voltage)"
	CheckBox BF1,help={"Only works for Voltage right now"},value= 0
	SetVariable Input0a,pos={633,247},size={145,16},bodyWidth=120,title="In0a"
	SetVariable Input0a,value= root:packages:KelvinVoltage:to_measure[0]
	SetVariable Input0b,pos={634,269},size={145,16},bodyWidth=120,title="In0b"
	SetVariable Input0b,value= root:packages:KelvinVoltage:to_measure[1]
	SetVariable Input1a,pos={632,288},size={145,16},bodyWidth=120,title="In1a"
	SetVariable Input1a,value= root:packages:KelvinVoltage:to_measure[2]
	SetVariable Input1b,pos={631,308},size={145,16},bodyWidth=120,title="In1b"
	SetVariable Input1b,value= root:packages:KelvinVoltage:to_measure[3]
	SetVariable Input2a,pos={633,331},size={145,16},bodyWidth=120,title="In2a"
	SetVariable Input2a,value= root:packages:KelvinVoltage:to_measure[4]
	SetVariable Input2b,pos={634,353},size={145,16},bodyWidth=120,title="In2b"
	SetVariable Input2b,value= root:packages:KelvinVoltage:to_measure[5]
	PopupMenu Voltage,pos={98,223},size={192,22},title="Where to apply voltage"
	PopupMenu Voltage,mode=1,popvalue="DCOffset",value= #"\"DCOffset;OutC Probe;OutC plate\""
	Button Return_Height,pos={27,194},size={50,20},title="Return"
	Button Return_Height,fColor=(61440,61440,61440)
	SetVariable GeneralOut1,pos={379,248},size={190,16},bodyWidth=120,title="General Out 1"
	SetVariable GeneralOut1,value= root:packages:KelvinVoltage:outputs[0]
	SetVariable Generalout2,pos={379,268},size={190,16},bodyWidth=120,title="General Out 2"
	SetVariable Generalout2,value= root:packages:KelvinVoltage:outputs[1]
	SetVariable Genmin2,pos={475,287},size={60,16},bodyWidth=60,title=" "
	SetVariable Genmin2,value= root:packages:KelvinVoltage:Generalparms[3]
	SetVariable Genmax2,pos={475,305},size={60,16},bodyWidth=60,title=" "
	SetVariable Genmax2,value= root:packages:KelvinVoltage:Generalparms[4]
	SetVariable FreqMin2,pos={275,111},size={81,16},bodyWidth=60,title="Min"
	SetVariable FreqMin2,value= root:packages:KelvinVoltage:Freqparms[0]
	SetVariable FreqMax2,pos={272,130},size={84,16},bodyWidth=60,title="Max"
	SetVariable FreqMax2,value= root:packages:KelvinVoltage:Freqparms[1]
	ValDisplay FrequencySteps2,pos={265,150},size={91,14},bodyWidth=60,title="Steps"
	ValDisplay FrequencySteps2,limits={0,0,0},barmisc={0,1000}
	ValDisplay FrequencySteps2,value= #"root:packages:KelvinVoltage:freqparms[2]"
	SetVariable Gensdelta1,pos={382,325},size={89,16},bodyWidth=60,title="Delta"
	SetVariable Gensdelta1,value= root:packages:KelvinVoltage:Generalparms[2]
	SetVariable GenDelta2,pos={475,324},size={60,16},bodyWidth=60,title=" "
	SetVariable GenDelta2,value= root:packages:KelvinVoltage:Generalparms[5]
	PopupMenu Frequency,pos={277,75},size={98,22},title="Frequency"
	PopupMenu Frequency,mode=1,popvalue="No",value= #"\"No;Yes;Heterodyne;B\""
	CheckBox Exponential,pos={386,350},size={78,14},title="exponential?",value= 0
EndMacro

Function FMAdvanceAuto_P() //Start a run
	//this gives us the current height
	SetDataFolder root:packages:KelvinVoltage
	variable height = td_rv("Zsensor")
	Wave Countwave, FDataWave, fmappwave
	string error
	//this sets up what we want to see on the sum and deflection meter:
	SetDataFolder root:packages:MFP3D:Meter:
	wave meterstatus, mastervariableswave
	Meterstatus[8] =2
	Meterstatus[10]=2
	UpdateMeterStatus(0)
	SetDataFolder root:packages:KelvinVoltage
	//mastervariableswave[17][0]*mastervariableswave[26][0]
	
	//countwave[1] = height //this seems to be a strange way to do things/should probably change it
	//fmappwave[0] = b
	
	StartOZ(height)
	prepscan()
end

Function PrepScan() //prepares each individual height measurement
	Wave countwave//, prelims2nd, FMappwave, minmaxw, MasterVariablesWave
	variable ZlvdtSens = GV("zlvdtsens")
	variable zpiezosens = GV("Zpiezosens")
	SetDataFolder root:packages:KelvinVoltage//should already be set?
	String S_value
	
	countwave[0] += 1
	
		varprep()
end

function varprep()
		SetDataFolder root:packages:KelvinVoltage
	
	String S_value=""
	wave vars
	vars = 0
	controlinfo/W=KPFMVoltageAnalyzer Varying1
	StrSwitch(S_Value)	
			
				case "Height":
				//print "madeit" 
					generateheightlist()
					//RampOZ(CountWave[1], "FixHeight()")
					
				break
				
				case "Voltage":
					generatevoltageinputs()
				break
				
				case "Illumination":
					print "Illumination is not yet an option"
				break
				
				case "AC Amplitude":
					generateACAMPinputs()
				break	
				
				case "General": 
					GenVarPrep()
				break
				
				case "LockinB Amplitude":
					//print "something is wrong with the variable selector"
				//break

				default:
				print "This operation is not yet available"
				
			endswitch
	
			controlinfo/W=KPFMVoltageAnalyzer Frequency
		strswitch(S_Value)
			case "Yes":
				generatefrequencies()
			break
		
			case "No":
			
			break
		
			case "Heterodyne":
		 		genheterodynefreq()
			break
			
			case "B":
			 	generateFrequencies()
			break
	endswitch
	//"Height;Voltage;Illumination;AC Amplitude;LockinB Amplitude"
	
		wave countwave
		wave duration
		variable dlength = 5e3*countwave[1]- Mod(5e3,32)
		print dlength
		Make/O/N = (7,1) prelims
		Make/O/N = (7,1,dlength) all1
	//if there is a secondary variable 
end

function GenVarPrep()
	controlinfo/W=KPFMVoltageAnalyzer Varying1
	Wave generalparms, vars
	
	if(cmpstr(S_Value,"General")==0)
		
		make/n=(generalparms[2])/o General1
		controlinfo/W=KPFMVoltageAnalyzer Exponential
		if(v_value)
			variable delta = (ln(generalparms[1]) - ln(generalparms[0]))/(generalparms[2]-1)
			print delta,exp(generalparms[2]*delta+ln(generalparms[0]))
			general1 = generalparms[0]*exp(p*delta)
		else
			delta = floor(generalparms[1] - generalparms[0])/(generalparms[2]-1)
			general1 = generalparms[0] + p*delta
		endif
		
		vars[0][1] = 0 
		vars[0][0] = generalparms[2]
	endif
	
	controlinfo/W=KPFMVoltageAnalyzer Varying2
	if(cmpstr(S_Value,"General")==0)
		variable numb2 = floor(generalparms[4] - generalparms[3])/generalparms[5]
		make/n=(numb2)/o General2
	
		general2 = generalparms[3] + p*generalparms[5]
		
		vars[1][1] = 0 
		vars[1][0] = numb2
	endif
end

function twovarprep()

end

function generateheightlist()
	Variable zsens = GV("zlvdtsens")
	Variable startheight = td_rv("Cypher.Lvdt.z")*zsens
	
	Wave Heightparms,vars
	Heightparms[0] = startheight
	
	Variable number = Floor((Heightparms[2] - heightparms[0]) / heightparms[1])
	
	Make/n=(number)/o Heights
	
	Heights = startheight + p*heightparms[1] //heightparms[1] = deltaheight
	
	vars[0][] = {number,0}
	
	controlinfo/W=KPFMVoltageAnalyzer Varying2
	StrSwitch(S_Value)
	
		case "none"://if height is the only variable
		//controlinfo/W=Approach_Panel KelvinProbeType
		//if(!cmpstr(S_Value, "Off")))
			vars[1][0] = -1
			//StartOZ( startheight )	
			//setupmeasurement( "gen_datasave()" )
			//elseif(!cmpstr(S_Value, "1st Harmonic")))
			//	RampOZ( heights[vars[0][1]], "setupheightKPFMmeasurement()")	
		
		break
		
		case "Voltage":
			//StartOZ( startheight )
			generatevoltageinputs()
	
		break
		
		case "Frequency":
			generatefrequencies()
		break
		
		case "Illumination":
			Illuminationprep()
		break
		
		default:
		
		print "This option is not yet operational"
	
	endswitch
end

function genheterodynefreq()
	variable hetfreq = td_rv("Cypher.LockinB.0.Freq")
	variable nfreq = td_rv("Arc.Lockin.0.Freq")
	variable passband = hetfreq + nfreq
	wave freqparms	
	Variable wlength = 5e3 - Mod(5e3, 32)
	freqparms[2] = wlength
	variable step = (freqparms[1] - freqparms[0]) / freqparms[2]
	variable step2 = 2 / freqparms[2]
	
	make/n=(wlength)/o ufrequencies, lfrequencies
	ufrequencies = hetfreq + p*step - step*wlength/2 //upper or upwards frequencies--interpret it however you like
	lfrequencies = passband - ufrequencies[p] //lower frequencies 
end

function generatevoltageinputs()
	Wave VoltageParms
	variable v0 = Voltageparms[0], vsweep = voltageparms[1]
	Wave vars
	controlinfo BF1
	if(V_Value)
		Variable imax= 2*voltageparms[2] - 1
		Make/o/N=(imax) Voltages
		variable num = voltageparms[2]
	
		Voltages[0,((num-1)/2)] = v0 - 2*p/(Num-1)*vsweep //The following three lines choose the voltages to measure
		Voltages[((num+1)/2), 3*(num-1)/2] = v0 - vsweep + 2*(p-(num-1)/2)/(Num-1)* vsweep //the voltages only switch between the closest neighbors to minimize the tendency of the feedback loops to jump
		Voltages[3*(num-1)/2+1,] = v0 + vsweep - vsweep*2*(p-3*(num-1)/2)/(num-1)
		num=imax //this is so the 'vars' setting code below works
	else
		num = voltageparms[2] 
		
		Make/o/N=(num) Voltages
		
		Voltages = v0 - vsweep/2 + vsweep*p/(num-1)
	
	endif
	
	controlinfo/W=KPFMVoltageAnalyzer Varying1
	if(!cmpstr(S_Value, "Voltage"))	
		
		vars[0][1] = 0 
		vars[0][0] = num
		
		controlinfo/W=KPFMVoltageAnalyzer Varying2
		if(!cmpstr(S_Value, "none"))
			controlinfo/W=KPFMVoltageAnalyzer KelvinProbeType
				if(!cmpstr(S_value, "Off"))
					//td_wv("Arc.Lockin.DCOffset", voltages[vars[0][1]])
					//setupmeasurement( "gen_datasave()" )
				else
					//td_wv("Arc.Output.C", voltages[vars[0][1]])
					//setupmeasurement( "gen_datasave()" )
				endif
			
		elseif(0)
		else
			secondvargen()
		endif
	else
		controlinfo/W=KPFMVoltageAnalyzer Varying2
		if(!cmpstr(S_Value, "Voltage"))	
			vars[1][1] = 0 
			vars[1][0] = num
		else
			print "something is wrong with the voltage code"
		endif
	endif
	controlinfo/W=KPFMVoltageAnalyzer Varying2
	if(!cmpstr(S_Value, "none"))//if voltage is the only variable
		//print td_wv("Arc.Lockin.DCoffset", voltages[0])
		//setupvoltagemeasurement() //eventually, this will go to two two different functions, depending on whether voltage is a 1st variable or 2nd variable
	elseif(!cmpstr(S_Value, "Voltage"))
		//This should run voltage as a second variable in a 2-variable system
	else
		//This should run voltage as the first variable in a 2-variable system
	endif
	
end

function generateACAmpinputs()
	wave acampparms, vars
	
	variable numb = floor(acampparms[2] - acampparms[0])/acampparms[1]
	
	make/n=(numb)/o ACamps
	
	ACamps = acampparms[0] + p*acampparms[1]
	
		controlinfo/W=KPFMVoltageAnalyzer Varying1
	if(!cmpstr(S_Value, "AC Amplitude"))	
		
		vars[0][1] = 0 
		vars[0][0] = numb
		
		controlinfo/W=KPFMVoltageAnalyzer Varying2
		if(!cmpstr(S_Value, "none"))
			controlinfo/W=KPFMVoltageAnalyzer KelvinProbeType
				if(!cmpstr(S_value, "Off"))
					//td_wv("Arc.Lockin.DCOffset", voltages[vars[0][1]])
					//setupmeasurement( "gen_datasave()" )
				else
					//td_wv("Arc.Output.C", voltages[vars[0][1]])
					//setupmeasurement( "gen_datasave()" )
				endif
			
		elseif(0)
		else
			secondvargen()
		endif
	else
		controlinfo/W=KPFMVoltageAnalyzer Varying2
		if(!cmpstr(S_Value, "AC Amplitude"))	
			vars[1][1] = 0 
			vars[1][0] = numb
		else
			print "something is wrong with the Amplitude set generation code"
		endif
	endif
	
end

function generateFrequencies()
	wave freqparms, countwave
	Variable wlength = countwave[1]*5e3 - Mod(5e3, 32)
	freqparms[2] = wlength
	variable step = (freqparms[1] - freqparms[0]) / freqparms[2]
	variable step2 = 2 / freqparms[2]
	
	make/n=(wlength)/o frequencies, poffsets
	frequencies = freqparms[0] + p*step
	poffsets = p*step2
end
	
Function Illuminationprep()
	PopupMenu  Varying2 mode=1, Win=KPFMVoltageAnalyzer
	Wave illuminationparms, vars
	
	vars[0][1] = 0 
	vars[0][0] = illuminationparms[0]
	
	vars[1][1] = 0 
	vars[1][0] = -1
	
end

function secondvargen()
		controlinfo/W=KPFMVoltageAnalyzer Varying2
		StrSwitch(S_Value)	
				
				case "Voltage": //2nd var voltage changes voltage on surface
					generatevoltageinputs()
				break
				
				case "AC Amplitude":
					generateACAmpinputs()
				break	
				
				case "Frequency":
					generateFrequencies()
				break
				
				case "General":
					GenVarPrep()
				break
				
				case "LockinB Amplitude":
					//print "something is wrong with the variable selector"
				//break

				default:
				print "This operation is not yet available"
				
		endswitch
end

function KV_advance()
	wave vars, countwave, prelims, prelims2nd, all1, all2
	string s_value = ""
	
	vars[][1] = 0
	controlinfo/W=KPFMVoltageAnalyzer Varying1
	StrSwitch(S_Value)	
			
				case "Height":
					wave heights
					variable zlvdtsens = GV("zlvdtsens")
				//print "madeit" 
					
					controlinfo/W=KPFMVoltageAnalyzer Varying2
					if(!cmpstr(S_Value,"none"))
						StartOZ(  heights[vars[0][1]]/zlvdtsens )
						setupmeasurement("gen_datasave()")
						Redimension/N=(-1,vars[0][0]) prelims
						Redimension/N=(-1,vars[0][0],-1) all1 
					elseif(!cmpstr(S_Value,"Frequency"))
						
						StartOZ(  heights[vars[0][1]]/zlvdtsens )
						wave freqparms
						Redimension/N=(-1,vars[0][0],freqparms[2]) prelims2nd
						Redimension/N=(-1,vars[0][0],freqparms[2],-1) all2
					else
						StartOZ( heights[vars[0][1]]/zlvdtsens )
						change2var()
						Redimension/N=(-1,vars[0][0],vars[1][0]) prelims2
						Redimension/N=(-1,vars[0][0],vars[1][0],-1) all2
					
					endif
					
					return 0
					
				break
				
				case "Voltage": //1st var voltage changes voltage on tip
					wave voltages
					print "voltage"
					controlinfo/W=KPFMVoltageAnalyzer KelvinProbeType
					if(!cmpstr(S_value, "Off"))
						td_wv("Arc.Lockin.DCoffset", voltages[vars[0][1]])
					else
						td_wv("Arc.Output.C", voltages[vars[0][1]])
					endif
					
				break
				
				case "Illumination":
					print "illumination number " + num2str(vars[0][1])
					ARCheckFunc("ARUserCallbackMasterCheck_1",1)
					ARCheckFunc("ARUserCallbackForceDoneCheck_1",1)
					ARCheckFunc("ARUserCallbackTuneCheck_1",1)
					//Wave root:packages:MFP3D:main:variables:Generalvariablesdescription[%ARUserCallbackTune][%Description] = "1"
					
					
					CantTuneFunc("DoTuneOnce_0")
					
					return 0 
				break
				
				case "General":
					wave general1
					wave/t outputs
					td_wv(outputs[0], general1[vars[0][1]])
				break
				
				case "AC Amplitude":
					wave ACamps
					td_wv("Arc.Lockin.0.Amp", ACamps[vars[0][1]])
					//print "something is wrong with the variable selector"
				break	
				
				case "LockinB Amplitude":
					//print "something is wrong with the variable selector"
				//break

				default:
				print "This operation is not yet available"
				
			endswitch
			
			print "first stop"
			
			controlinfo/W=KPFMVOLTAGEanalyzer Varying2
			strSwitch(S_value)
				case "none":
				
				Redimension/N=(-1,vars[0][0]) prelims
				Redimension/N=(-1,vars[0][0],-1) all1	
					
				setupmeasurement("gen_datasave()")
				
				break
				
				case "Frequency":
				wave freqparms
				
				Redimension/N=(-1,vars[0][0],freqparms[2]) prelims2nd
				Redimension/N=(-1,vars[0][0],freqparms[2],-1) all2
				
				setupfrequencymeasurement()	
			
				break
				
				default:
				print "stop2"
				Redimension/N=(-1,vars[0][0],vars[1][0]) prelims2nd
				Redimension/N=(-1,vars[0][0],vars[1][0],-1) all2	
				change2var()
				
				break
					
			endswitch



end

function setupheightmeasurement()
	Wave voltages
	wave countwave
	td_stopinwavebank(-1)
	td_writestring("0%event", "clear")

	Variable NPPS = GV("NumPtsPerSec")
	
	Variable Decim = 1 //how many samples go into one datapoint?
	Variable wlength = 5e4*countwave[1] - Mod(5e4, 32)
	
	pv("LowNoise",1)
	
	make/o/n =(wlength) iamp, qamp, i2amp, q2amp, potential, s_voltage
	Decim =1 

	td_xsetoutwave(0, "0,0", "Arc.Lockin.0.freq", frequencies, decim)

	td_xsetinwavepair(2, "0,0", "Arc.Lockin.0.i", iamp, "Arc.Lockin.0.q", qamp, "Height_analysis()",decim)//set up our measurement
	td_xsetinwavepair(1, "0,0", "Arc.Lockin.1.i", i2amp , "Arc.Lockin.1.q", q2amp, "",decim)
	td_xsetinwavePair(0, "0,0", "Arc.output.c", s_voltage , "Potential", potential, "",Decim)
	td_writestring("0%event", "once") 
end

function setupmeasurement( callback )
	string callback
	Wave voltages, frequencies
	Wave/t to_measure
	wave countwave
	wave duration
	td_stopinwavebank(-1)
	td_writestring("0%event", "clear")
	wave freqparms
	
	//print "setupmeas"
	
	Variable NPPS = GV("NumPtsPerSec")
	
	Variable Decim = 10 //how many samples go into one datapoint?
	Variable wlength = (5e4*countwave[1])/Decim - Mod((5e4*countwave[1])/Decim, 32)
	
	pv("LowNoise",1)
	
	make/o/n =(wlength) tm0a, tm0b, tm1a, tm1b, tm2a, tm2b

	
	controlinfo/W=KPFMVoltageAnalyzer Frequency
	strswitch(S_Value)
		case "Yes":
			print td_xsetoutwave(1, "0,0", "Cypher.LockinB.1.Freq", frequencies, decim)
			td_ws("Cypher.outwave.status", "-1")
			//print "yes"
		break
		
		case "No":
			//print "no"
			
		break
		
		case "Heterodyne":
		 	wave lfrequencies, ufrequencies
		 	wavestats/q ufrequencies
		 	td_wv("Cypher.outwave.StartValue", V_min)
		 	td_wv("Cypher.outwave.endvalue", V_max)
		 	variable range = V_max - V_min
		 	td_wv("Cypher.outwave.ramprate", range)
		 	td_ws("Cypher.outwave.event", "0")
		 	td_ws("Cypher.outwave.status", "Once")
			td_xsetoutwave(1, "0,0", "Arc.Lockin.0.freq", lfrequencies, decim)
		break
		
		case "B":
			wave lfrequencies, ufrequencies
		 	//wavestats/q ufrequencies
		 	td_WriteString("Cypher.OutWave.Channel","LockinB.0.Freq")
		 	td_wv("Cypher.outwave.StartValue", freqparms[0])
		 	td_wv("Cypher.outwave.endvalue", freqparms[1])
		 	range = (freqparms[1]-freqparms[0])/countwave[1]
		 	td_wv("Cypher.outwave.ramprate", range)
		 	td_ws("Cypher.outwave.event", "0")
		 	td_ws("Cypher.outwave.status", "Always")
		break
	endswitch
	
	//print "waveset"
	td_xsetinwavepair(0, "0,0", to_measure[0] , tm0a ,to_measure[1], tm0b, callback,decim)//set up our measurement
	td_xsetinwavepair(1, "0,0", to_measure[2], tm1a , to_measure[3], tm1b, "",decim)
 	td_xsetinwavePair(2, "0,0", to_measure[4], tm2a , to_measure[5], tm2b, "",Decim)
	td_writestring("0%event", "once") 

end

Function/S SetupModTuneDrive(WhichEventStr)
	String WhichEventStr
	
	wave countwave
	wave freqparms
	
	Variable nop = DimSize(Frequency,0)
	String ErrorStr = ""
	//SVAR TuneEventString = root:Packages:MFP3D:Hardware:Clueless
	
	Variable RampTime, RampRate, NPPS
	//Variable FMModeTune = GV("FMModeTune")
	String DrivingString = ""
	//variable tuneLockin = GV("TuneLockin")
	

		DrivingString = "LockinB."+"1"+".Freq"
			
		RampTime = countwave[1]
		RampRate = (freqparms[1] - freqparms[0])/ramptime
		ErrorStr += num2str(td_WriteString("Cypher.OutWave.Channel",DrivingString))+","
		ErrorStr += num2str(td_writevalue("Cypher.OutWave.StartValue", freqparms[0]))+","
		ErrorStr += num2str(td_writevalue("Cypher.OutWave.EndValue", freqparms[1]))+","
		ErrorStr += num2str(td_writevalue("Cypher.OutWave.RampRate", RampRate))+","
		ErrorStr += num2str(td_writestring("Cypher.OutWave.Event", "0"))+","	// *checked*
		ErrorStr += num2str(td_ws("Cypher.OutWave.Status","Once"))+","
		//\\NPPS = cMasterSampleRate/abs(Decimation)
		//SetScale/P x,0,1/NPPS,"s",Frequency		//setup the scaling so that autotune can work.

	errorStr += num2str(td_WriteValue(DrivingString,freqparms[0]))+","
	sleep/T 10
//print Frequency[0],Frequency[nop-1]
	return(ErrorStr)
End //SetupTuneDrive


function setupfrequencymeasurement()
	Wave voltages, frequencies, poffsets
	wave/t to_measure
	wave countwave
	duplicate/o frequencies dfrequencies
	dfrequencies *= 2
	
	td_stopinwavebank(-1)
	td_writestring("0%event", "clear")
	
	Variable NPPS = GV("NumPtsPerSec")
	
	Variable Decim = 10 //how many samples go into one datapoint?
	Variable wlength = 5e3*countwave[1] - Mod(5e3, 32)
	
	pv("LowNoise",1)
	
	make/o/n =(wlength) tm0a, tm0b, tm1a, tm1b, tm2a, tm2b

	
	td_xsetoutwavepair(0, "0,0", "Arc.Lockin.0.freq", frequencies,"Arc.lockin.1.freq", dfrequencies, decim)
	td_xsetinwavepair(0, "0,0", to_measure[0] , tm0a ,to_measure[1], tm0b, "freq_analysis()",decim)//set up our measurement
	td_xsetinwavepair(1, "0,0", to_measure[2], tm1a , to_measure[3], tm1b, "",decim)
	td_xsetinwavePair(2, "0,0", to_measure[4], tm2a , to_measure[5], tm2b, "",Decim)
	td_writestring("0%event", "once") 
end

function gen_datasave()
	wave vars
	
	wave tm0a, tm0b, tm1a, tm1b, tm2a, tm2b
	Make/t/o wnames = {"tm0a", "tm0b", "tm1a", "tm1b", "tm2a", "tm2b"}
	Variable i = 0, imax = 6
	
	if(vars[1][0]<1) //If we only care about one variable
		for(i=0;i<imax;i+=1)
			wave  prelims, all1
 
			Duplicate/o $(wnames[i]) analyze
			Wavestats/q analyze
			prelims[i][vars[0][1]] = V_avg
			all1[i][vars[0][1]][] = analyze[r]
		endfor
		
		vars[0][1]+=1
		
		if(vars[0][0] > vars[0][1])
			change1var()
		elseif(vars[0][0]==vars[0][1])
				SVAR finalcallback
				Execute(finalcallback)
		endif
	else //if we are sweeping two variables
		for(i=0;i<imax;i+=1)
			wave prelims2nd, all2
			Duplicate/o $(wnames[i]) analyze
			Wavestats/Q analyze
			prelims2nd[i][vars[0][1]][vars[1][1]] = V_avg			
			all2[i][vars[0][1]][vars[1][1]][] = analyze[s]
		endfor
	
		vars[1][1]+=1
		
			
		if(vars[1][0] <= vars[1][1])
			vars[0][1] +=1
			vars[1][1] = 0

			if(vars[0][0] > vars[0][1])
				change1var()
			elseif(vars[0][0]==vars[0][1])
				SVAR finalcallback
				Execute(finalcallback)
			endif

		
		else
			change2var()
		endif
	endif

	

end

function freq_analysis()
		wave tm0a, tm0b, tm1a, tm1b, tm2a, tm2b
		Make/t/o wnames = {"tm0a", "tm0b", "tm1a", "tm1b", "tm2a", "tm2b"}
		Variable i = 0, imax = 6
		wave vars
	
		for(i=0;i<imax;i+=1)
			wave prelims2nd, all2
			Duplicate/o $(wnames[i]) analyze
			Wavestats/Q analyze		
			prelims2nd[i][vars[0][1]][] = analyze[r]
		endfor
			
		vars[0][1] +=1
			
		if(vars[0][0] > vars[0][1])
			change1var()
		else 
			SVAR finalcallback
			Execute(finalcallback)
		endif
end

function change1var()
	wave vars
	controlinfo/W=KPFMVoltageAnalyzer Varying1
	StrSwitch(S_Value)	
			
				case "Height":
					wave heights
				//print "madeit" 
					variable zlvdtsens = GV("ZLVDTsens")
					controlinfo/W=KPFMVOltageanalyzer Varying2
					if(!cmpstr(S_Value,"none"))
					
						RampOZ( heights[vars[0][1]]/zlvdtsens, "setupmeasurement(\"gen_datasave()\")")
						//RampOZ(CountWave[1], "FixHeight()")
					
					else
					
						RampOZ( heights[vars[0][1]]/zlvdtsens, "change2var()")
					
					endif
					
					return 0
					
				break
				
				case "Voltage": //1st var voltage changes voltage on tip
					wave voltages
					controlinfo/W=KPFMVoltageAnalyzer KelvinProbeType
					if(!cmpstr(S_value, "Off"))
						td_wv("Arc.Lockin.DCoffset", voltages[vars[0][1]])
					else
						td_wv("Arc.Output.C", voltages[vars[0][1]])
					endif
					
				break
				
				case "Illumination":
					//print "something is wrong with the variable selector"
				break
				
				case "General":
					wave general1
					wave/t outputs
					td_wv(outputs[0], general1[vars[0][1]])
				break
				
				case "AC Amplitude":
					wave ACamps
					td_wv("Arc.Lockin.0.Amp", ACamps[vars[0][1]])
				break	
				
				case "LockinB Amplitude":
					//print "something is wrong with the variable selector"
				break

				default:
				print "This operation is not yet available"
				
			endswitch
			
			controlinfo/W=KPFMVoltageAnalyzer Varying2
			strswitch(S_Value)
			
				case "none":
					
				setupmeasurement("gen_datasave()")
				//RampOZ(CountWave[1], "FixHeight()")
				
				break
				
				case "Frequency":
				
					setupfrequencymeasurement()
				
				break
				
				default:	
					
				change2var()
					
			endswitch

end

function change2var()
	wave vars
	variable i = vars[1][1]
	
	controlinfo/W=KPFMVoltageAnalyzer Varying2
	StrSwitch(S_Value)	
				
				case "Voltage": //2nd var voltage changes voltage on surface
					wave voltages
					controlinfo/W=KPFMVoltageAnalyzer KelvinProbeType
					if(!cmpstr(S_value, "Off"))
						td_wv("Arc.Lockin.DCoffset", voltages[vars[0][1]])
					else
						td_wv("Arc.Output.C", voltages[vars[0][1]])
					endif
					setupmeasurement("gen_datasave()")
				break
				
				case "General":
					wave general2
					wave/t outputs
					//print "chanign general"
					td_wv(outputs[1], general2[vars[1][1]])
					setupmeasurement("gen_datasave()")
				break
				
				case "Illumination":
					//print "something is wrong with the variable selector"
				//break
				
				case "AC Amplitude":
					//print "something is wrong with the variable selector"
				//break	
				
				case "LockinB Amplitude":
					//print "something is wrong with the variable selector"
				//break

				default:
				print "This operation is not yet available"
				
			endswitch
end

function setupvoltagemeasurement()
	Wave voltages,countwave

	
	td_stopinwavebank(-1)
	td_writestring("0%event", "clear")
	
	Variable NPPS = GV("NumPtsPerSec")
	
	
	Variable Decim = 1 //how many samples go into one datapoint?
	Variable wlength = 5e4*countwave[1] - Mod(5e4, 32)
	
	pv("LowNoise",1)
	
	make/o/n =(wlength) iamp, qamp, i2amp, q2amp
	Decim =1 

	

	td_xsetinwavepair(2, "0,0", "Arc.Lockin.0.i", iamp, "Arc.Lockin.0.q", qamp, "Voltage_analysis()",decim)//set up our measurement
	td_xsetinwavepair(1, "0,0", "Arc.Lockin.1.i", i2amp , "Arc.Lockin.1.q", q2amp, "",decim)
	//td_xsetinwavePair(0, "0,0", "Arc.Lockin.", DeflectionWaves , "Amplitude", AmpWaves, "",Decim)
	td_writestring("0%event", "once") 

end

function height_analysis()
	wave vars, prelims, all1, heights

	
	Wave iamp, qamp, i2amp, q2amp, s_voltage, potential
	Make/t wnames = {"iamp", "qamp", "i2amp", "q2amp", "s_voltage", "potential"}
	Variable i = 0, imax = 6

	for(i=0;i<imax;i+=1)
		Duplicate/o $(wnames[i]) analyze
		Wavestats/Q analyze
		prelims[i][vars[0][1]] = V_avg
		all1[i][vars[0][1]][] = analyze[q]
	endfor
	
	vars[0][1] += 1
	
	if(vars[0][1]<vars[0][0])
	
		RampOZ( heights[vars[0][1]], "setupheightmeasurement()")
	
	else
		return 0 
	endif
end

function Voltage_analysis()
	wave vars, prelims, all1, voltages

	
	Wave iamp, qamp, i2amp, q2amp
	Make/t wnames = {"iamp", "qamp", "i2amp", "q2amp"}
	Variable i = 0, imax = 4

	for(i=0;i<imax;i+=1)
		Duplicate/o $(wnames[i]) analyze
		Wavestats/Q analyze
		prelims[i][vars[0][1]] = V_avg
		all1[i][vars[0][1]][] = analyze[q]
	endfor
	
	vars[0][1] += 1
	
	if(vars[0][1]<vars[0][0])
	
		print td_wv("Arc.Lockin.DCoffset", voltages[vars[0][1]])
		setupvoltagemeasurement()
	
	else
		return 0 
	endif
	
end



Function FixHeight()
	Wave Fdatawave, Countwave
	Variable ZLVDTsens = GV("ZLvdtsens")
	Countwave[1] = td_rv("Zsensor")//Might want to change this back
	FDatawave[6][countwave[0]] = countwave[1]*Zlvdtsens
	//Countwave[2] += countwave[7] //Traveled Height+=distbetween

	//Here is one place where the type of measurement is important -- I need to call the drop-down menu

	Controlinfo/W=Approach_Panel method_tab0
		if(cmpstr(S_Value,"FM Static")==0)
			//Measurement_start(countwave[4], countwave[5])//FM1Scan_P()
			///print "made it!"
		elseif(cmpstr(S_Value,"FM Sweep")==0)
			FM1Scan_P()
			print "scan1"
		else
			AM_Measurement_Start()
		endif
End//FixHeight()

Function DataCallback()//does the data analysis for all measurements/needs to be cleaned up badly/need to have it generalized for different measurement types
	Wave Freqoffset, Voltagewave, W_Coef, DeflectionWave, AmpWave, latwave, savewave, pwave//Pwave is new as of run 13
	Wave W_Sigma, FDataWave, CountWave, retract, foffsets, fstddev, FMappwave
	variable i = Countwave[0], V_value, j = 0
	variable b = Dimsize(freqoffset,0), V_maxRowLoc
	variable ZpiezoSens = GV("Zpiezosens")
	td_wv("Output.c",0)
	//String FO = "fo", VW = "vw", Dis = "d"
	//display freqoffset vs voltagewave
	//Duplicate/O Freqoffset Freqoffsetdis $(FO + num2str(i))
	//Duplicate/O Voltagewave Voltagewavedis $(vw + num2str(i))
	//Duplicate/O DeflectionWave DWdis $(dis+num2str(i))
	//Duplicate/O AmpWave AWdis
	Make/O/N=(b,5) rawwave
	rawwave[][0] = Voltagewave[p]
	rawwave[][1]= deflectionwave[p]
	rawwave[][2] = Ampwave[p]
	rawwave[][3] = freqoffset[p]
	rawwave[][4] = pwave[p]
	savewave[i][][] = rawwave[r][q]
	//Save/P=SaveForce rawwave as ("sweep" + num2str(i)+ "data" + num2str(Countwave[9]) + ".ibw")
	Variable Zsens = GV("ZLvdtsens")
	//HeightWave *= Zsens
	//Duplicate/O HeightWave HWdis

	//StopFM()
	
	Controlinfo/W=Approach_Panel method_tab0
		if(cmpstr(S_Value,"FM Static")==0)
			CurveFit/M=2/W=2/Q poly 3, Freqoffset/X=VoltageWave/W=Fstddev /I=1 /D /F={0.683000, 4}//Neglect a few extreme points
		else
			CurveFit/M=2/W=2/Q poly 3, Freqoffset/X=VoltageWave /D//Neglect a few extreme points
			print "scan1"
		endif
	
	
	SetScale d 0,0,"Hz", Freqoffset
	pv("LowNoise",0)
	if(W_Coef[2] >= 0)
		print W_Coef[2]
	else
		Make/O/N=3 ffit 
		ffit = { - W_coef[2],  -(W_coef[1]/(2*W_coef[2])), -(W_coef[1]^2/(4*W_coef[2]) - W_Coef[0])}

		//ControlInfo/W=Approach_Panel retract0
		//if(V_Value)
			Countwave[5] = Min(10, sqrt(-Countwave[8]/W_coef[2]))
		//else
			//Wavestats/Q Freqoffset
			//Duplicate/O Freqoffset extremepoints
			//extremepoints = 1
			//For(j=0; j<b; j+=1)
				//if(Freqoffset[j] < (Freqoffset[V_maxRowLoc]-Countwave[8]))
					//Countwave[5] = Min( Countwave[5]+.001, abs(Voltagewave[j]-countwave[4]))
					//extremepoints[j] = NaN
				//endif
			//endfor	
		//endif
		
				
		FuncFit/NTHR=0/Q/W=2 ModPoly ffit  Freqoffset/X=VoltageWave/W=Fstddev /I=1 /D /F={0.683000, 4} //M=extremepoints
		Wave W_Sigma, FDataWave, CountWave, retract
		
		FDatawave[1][i] =ffit[1]
		
		if(abs(FDatawave[1][i]) < 5)
			Countwave[4] = FDatawave[1][i]
		endif
		
		//SetVoltage(FDatawave[1][i])//Do a Run at one Voltage
		
		fdatawave[18][i] = td_rv("ATC.Headtemp")
		fdatawave[19][i] = td_rv("ATC.Temp0")
		fdatawave[12][i] = td_rv("dissipation")
		
		FDatawave[0][i] = ffit[0]
		countwave[9] = sqrt(FMappwave[0]/fdatawave[0][i])
		setupNextMeasure()
		if(abs(FDatawave[1][i]) < 5)
			Countwave[4] = FDatawave[1][i]
		endif
		//counter, nheight, theight, height, vcenter, vsweep, scantime, distbtw
		FDatawave[2][i] =ffit[2]
		//print 3
		//print 4
			 
		
		//Countwave[5] = Min(10-abs(Countwave[4]),(10*FDatawave[0][i]^(-.39)+Countwave[5])/2)//vsweep
		//print 5
		//Countwave[6] =  Min(.05,(1*(FDatawave[0][i]^(-0.3)) + countwave[6])/2)//Scantime
		
		Countwave[7] = Min((40000*sqrt(fmappwave[0])*FDatawave[0][i]^(-.5)),.2)//Min((.08*FDatawave[0][i]^(-.6) + countwave[7])/2,0.06)//*Zpiezosens // These values were calculated using a fit 
		//.print (.04179*FDatawave[0][i]^(-.5))
		Wave twave 
		twave[0]= countwave[7]*ZSens//amount to move in meters
		twave[1]= 1/sqrt(fdatawave[0][i]/8.8e-12) //A way to estimate the distance using a prior calculated const and not offset
		FDatawave[3][i] = W_sigma[0]
		FDataWave[4][i]= W_sigma[1]
		FDataWave[5][i] = W_sigma[2]
		FDatawave[7][i] = countwave[5]
		FDatawave[8][i] = countwave[6]
		FDatawave[9][i] = countwave[7]
		
		CurveFit/M=2/W=2/Q poly 3, DeflectionWave/X=VoltageWave/D//Neglect a few extreme points
		FDatawave[15][i] = -(W_coef[1]/(2*W_coef[2]))
		FDatawave[14][i] =  - W_coef[2]
		FDatawave[16][i] = -(W_coef[1]^2/(4*W_coef[2]) - W_Coef[0])
		
		Wave runwave
		fdatawave[11][i]= datetime - runwave[1][0]
		
		Wavestats/Q Ampwave
		Fdatawave[17][i] = V_avg
		
	endif			
end //End Datacallback()

Function setupNextMeasure()	
	Variable V_Value, timestart, V_Flag
	//NVAR timestart = root:packages:FMscans:timestart
	Wave Fdatawave, countwave, minmaxw, runwave, FMappwave
	
	Variable i = countwave[0]
		
		if(i < nruns)
		string s_value
		//print "made it this far"
		controlInfo/W=Approach_Panel Keepscanning_tab0
			if(V_Value)//if keep scanning is checked
				controlinfo/W=Approach_Panel Variable_tab0	
				strSwitch(S_Value)
					
					case "Height (nm)": //For varying height, which is really the default case
					//print "here"
						ControlInfo/W=Approach_Panel retract_tab0
							if(V_Value)
								if((countwave[9]*1e9) < minmaxw[1])
									prepscan()
								else
									checkbox retract_tab0 value=0,  win=Approach_Panel
									prepscan()
								endif
							else
								if((countwave[9]*1e9) > minmaxw[0])
									prepscan()
								else
									checkbox retract_tab0 value=1,  win=Approach_Panel
									Lengthen(runwave)
									variable rsize = Dimsize(runwave, 1)
									runwave[0][rsize-1] = i
									runwave[1][rsize-1] = datetime
									prepscan()

								endif
							endif
					break
					
					default:
						prepscan()
					break
				endswitch
			else	//if keep scanning is not checked
			
			//This next bit is pointless, but has some code I may want to use later
			ControlInfo/W=Approach_Panel Keepscanning_tab0
				//print V_Value
				if(V_Value)
					if(fdatawave[0][i] < minmaxw[1])
						prepscan()
						//print "made it here"
					else
					endif	
				else
					return 0
				endif
			endif
		else
			 print "max runs"//td_SetRamp(1,"$outputZloop.setpoint",0,-2.5,"",0,0,"",0,0,"")
		endif
End



//The following Functions are part of the sweep measurement technique

Function FM1Scan_P()
	SetDataFolder root:packages:FMscans
	Wave Countwave
	variable error = 0
	
	error += td_stopinwavebank(-1)
	error += td_writestring("0%event", "clear")
	
	Variable NPPS = GV("NumPtsPerSec")
	Variable OutRate = nsweep/countwave[6] //Countwave[6] is now the number of seconds a measurement takes
	//print nop
	
	pv("LowNoise",1)
	
	make/o/n =(nsweep) VoltageWave, Freqoffset, Deflectionwave, AmpWave, HeightWave, Latwave, pwave
	//print 2, error
	//Latwave = 0
	//FreqOffset=0 
	//AmpWave = 0
	//DeflectionWave=0
	//pwave=0
	MakeVoltageWave(nsweep)
	
	Variable Decim = round(5e4/OutRate)//Scanrate
	
	//print 1, error
	//sleep/T 5
	error += td_xsetinwave(2, "0,0", "Cypher.Lockina.0.FreqOffset", FreqOffset , "DataCallback()",Decim)
	 td_xsetinwavePair(0, "0,0", "Deflection", DeflectionWave , "Amplitude", AmpWave, "",Decim)
	error +=td_xsetinwavepair(1, "0,0", "lateral", latwave,"Phase", Pwave, "",Decim)
	//print 2, error
	//print dimsize(freqoffset,0)
	error += td_xsetoutwave(0,"0,0", "C%Output", VoltageWave,Decim)
	//print 6, error
	//StartFM()
	 error += td_SetRamp(.1, "C%Output",0,VoltageWave[0],"",0,0,"",0,0,"VoltSetCallback()")
	if(error)
		print error
		//Abort 
	endif

End //DoDV

Function MakeVoltageWave(nop)
		Variable nop
		Wave Voltagewave, Countwave, FMappwave
		Variable vcenter =Countwave[4], vsweep = countwave[5] //numberofsweeps=FMappwave[2]
		variable i = 0, div = round(nop/4)
		//Make/O/N=(div) sweepup = Countwave[4] - countwave[5] + 2*numberofsweeps*p/nop * 2 *Countwave[5]
		//Make/O/N=(div) sweepdown = Countwave[4] + countwave[5] - 2*numberofsweeps*p/nop * 2 *Countwave[5]
			VoltageWave[0,div-1] = Countwave[4] - p/div*countwave[5]
			VoltageWave[div,(3*div-1)] = Countwave[4] + countwave[5]*(p/div -2)
			VoltageWave[(3*div),nop-1] = countwave[4] - countwave[5]*(p/div - 4)
		//Voltagewave[2* numberofsweeps * div,] = Voltagewave[2* numberofsweeps * div-1]
end

Function VoltSetCallback()
	variable error
	error += td_writestring("0%event", "once")
	return error
end

//The following Functions are part of the discrete measurement technique

Function SetVoltage2( Voltage ) //Ramps output.c to the appropriate voltage
	Variable Voltage
	td_SetRamp(.2, "C%Output",0,voltage,"",0,0,"",0,0,"SetVoltageCallback2()")
End

Function SetVoltageCallback2()
	Wave Countwave
	Variable duration = Countwave[6] //In seconds
	Variable Decim = 1 //how many samples go into one datapoint?
	Variable wlength = 5e4/decim*Duration
	wlength -= Mod(wlength, 32) //must modify the wavelength so that data transfer works
	Make/O/N=(wlength) Foffwave, pwaves, Voltmeas, deflectionwaves, ampwaves, latwaves //these waves receive the frequency offset, phase, voltage, deflection, amplitude, and lateral data, respectively
	//print "made it here"
	td_stopInwavebank(-1)//stop all incoming/outgoing waves
	td_stopoutwavebank(-1)
	//StartFM()
	td_xsetinwave(2, "0,0", "LockinA.0.FreqOffset", FOffwave , "Voltage_Done()",decim)//set up our measurement
	td_xsetinwavepair(1, "0,0", "LockinA.0.theta", pwaves , "lateral", latwaves, "",decim)
	td_xsetinwavePair(0, "0,0", "Deflection", DeflectionWaves , "Amplitude", AmpWaves, "",Decim)
	td_writestring("0%event", "once") //start the measurement
	//print "Made it here"
End

Function Voltage_Done() //this sorts the raw data and places it in the respective storing waves
	//it just stores the averages for everything other than the frequency offset
	Wave Foffwave, statwave, pwave, latwave, deflectionwave, ampwave
	Wave pwaves, latwaves, deflectionwaves, ampwaves, Freqoffset, Voltagewave, voltages
	
	Wavestats/Q Foffwave
	//Print V_avg, V_sdev
	Wave Foffsets, Fstddev //the wave with the averages from each 
	Foffsets[statwave[0]] = V_avg
	Fstddev[statwave[0]] = V_sdev
	
	Wavestats/Q pwaves
	pwave[statwave[0]] = V_avg
	
	Wavestats/Q latwaves
	latwave[statwave[0]] = V_avg
	
	Wavestats/Q DeflectionWaves
	Deflectionwave[Statwave[0]] = V_avg
	
	Wavestats/Q AmpWaves
	Ampwave[statwave[0]] = V_avg
	
	
	statwave[0] +=1//statwave keeps track of the number of voltages measured
	//print "made it here"	
	Variable i=statwave[0]
	
end

Function AM_Measurement_start()//Starts the discrete mesurement
	setup_AM_run()
end
//The following functions set up the Zloop

Function setup_AM_run()
	Wave Countwave
	Variable duration = Countwave[6] //In seconds
	Variable Decim = 1 //how many samples go into one datapoint?
	Variable wlength = 5e4/decim*Duration
	wlength -= Mod(wlength, 32) //must modify the wavelength so that data transfer works
	//print "made it here"
	td_stopInwavebank(-1)//stop all incoming/outgoing waves
	td_stopoutwavebank(-1)
	//StartFM()
	Controlinfo/W=Approach_Panel method_tab0
	if(cmpstr(S_value, "AMFM Static")==0)
		Make/O/N=(wlength) Drivewave, deflwave, VoltageWave, Foffwave, Ampwave
		td_xsetinwave(2, "0,0", "Cypher.LockinA.0.FreqOffset", Foffwave , "AM_Measure_Done()",decim)
	else
		Make/O/N=(wlength) Iwave, Drivewave, deflwave, VoltageWave, Ampwave
		td_xsetinwave(2, "0,0", "Cypher.LockinB.0.i", Iwave , "AM_Measure_Done()",decim)//set up our measurement
	endif
	td_xsetinwavepair(1, "0,0", "Arc.Lockin.1.r", Ampwave , "Arc.Lockin.0.Amp", DriveWave, "",decim)
	td_xsetinwavePair(0, "0,0", "Deflection", Deflwave , "Output.C", VoltageWave, "",Decim)
	td_writestring("0%event", "once") //start the measurement
	//print "Made it here"
End

Function AM_Measure_Done()
	//print "madehere1"
	Wave fdatawave, countwave, FMappwave, twave
	Variable i = countwave[0]
	Variable V_avg, V_sdev
	Variable zsensor = GV("Zlvdtsens")
	Controlinfo/W=Approach_Panel method_tab0
	if(cmpstr(S_value, "AMFM Static")==0)
		Wave Drivewave, deflwave, VoltageWave, Foffwave, Ampwave
		Wavestats/Q Foffwave
		fdatawave[2][i] = V_avg
		fdatawave[5][i] = V_sdev
	else
		wave Iwave, Drivewave, deflwave, VoltageWave, Ampwave
		Wavestats/Q Iwave
		fdatawave[2][i] = V_avg
		fdatawave[5][i] = V_sdev
	endif

	//print "madehere"
	wavestats/Q Drivewave
	fdatawave[0][i] = V_Avg
	fdatawave[3][i] = V_sdev
	
	wavestats/Q Voltagewave
	fdatawave[1][i] = V_Avg
	fdatawave[4][i] = V_sdev
	
	Wavestats/Q Ampwave
	fdatawave[12][i] = V_avg
	fdatawave[13][i] = V_sdev
	
	Wavestats/Q Deflwave
	fdatawave[16][i] = V_avg
	fdatawave[15][i] = V_sdev
	
	fdatawave[17][i] = countwave[2]
	fdatawave[9][i] = countwave[3]

	countwave[9]=FMappwave[0]*Fdatawave[0][i]^2/countwave[2]
	Countwave[7] = Min(20000*countwave[9],.2)
	twave[0] = countwave[7]*Zsensor
	
	//print "tonext"
	setupNextMeasure()
	
end

Function StartOZ( Zsetpoint)
	Variable Zsetpoint
	//Startup XYZ closed loops all at the same time.

	Struct ARFeedbackStruct FB
	String ErrorStr = ""
	ARGetFeedbackParms(FB,"Zsensor")
	FB.StartEvent = "1"
	FB.StopEvent = "Never"
	FB.SetPoint = Zsetpoint
	ErrorStr += ir_writePIDSloop(FB)

	//now start them all up

	ErrorStr += num2str(td_WriteString("Event."+FB.StartEvent,"Set"))+","

	ARREportError(ErrorStr)

End//StartFM (loop)

Function RampOZ( Zsetpoint, Callback)
	Variable Zsetpoint
	String Callback
	String RampChannel
	
	
	RampChannel = "$outputZLoop.setpoint"
	td_SetRamp(.5,RampChannel, 0, Zsetpoint,"",0,0,"",0,0,Callback)

End//StartFM (loop)

//Start/Stop FM loop:

Function StartFM()
	//Startup XYZ closed loops all at the same time.

	Struct ARFeedbackStruct FB
	String ErrorStr = ""
	ARGetFeedbackParms(FB,"Frequency")
	FB.StartEvent = "1"
	FB.StopEvent = "Never"
	FB.OutputMin = -1e6
	FB.OutputMax = 1e6
	ErrorStr += ir_writePIDSloop(FB)


	//now start them all up

	ErrorStr += num2str(td_WriteString("Event."+FB.StartEvent,"Set"))+","

	ARREportError(ErrorStr)

End//StartFM (loop)


function StopFM()

	String ErrorStr = ""
	
	ErrorStr += num2str(ir_StopPISLoop(NaN,LoopName="FrequencyLoop"))+","
	
	ARReportError(ErrorStr)
	
End //StopFM (loop)
//The Following pertain the the development of the approach panel window:

Window Approach_Panel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1993,706,2506,1065)
	ModifyPanel frameStyle=1, frameInset=1
	ShowTools/A
	ShowInfo/W=Approach_Panel
	Button ZeroHeight_tab0,pos={118,194},size={80,20},proc=ApproachButton,title="Zero Height"
	Button ZeroHeight_tab0,fColor=(61440,61440,61440)
	SetVariable setrad_tab0,pos={25,36},size={134,16},bodyWidth=60,title="Sphere Radius"
	SetVariable setrad_tab0,font="MS Sans Serif",format="%.2W1Pm"
	SetVariable setrad_tab0,limits={-inf,inf,1e-07},value= root:packages:FMscans:FMappwave[1]
	SetVariable vcenter0_tab0,pos={7,114},size={110,20},bodyWidth=93,title="V\\B0"
	SetVariable vcenter0_tab0,format="%.2W1PV"
	SetVariable vcenter0_tab0,limits={-inf,inf,0.01},value= root:packages:FMscans:CountWave[4]
	SetVariable vsweep_tab0,pos={8,135},size={150,16},bodyWidth=82,title="Sweep Width"
	SetVariable vsweep_tab0,format="%.2W1PV"
	SetVariable vsweep_tab0,limits={-inf,inf,0.01},value= root:packages:FMscans:CountWave[5]
	SetVariable Scanrate_tab0,pos={8,153},size={135,16},bodyWidth=80,title="Scan Rate"
	SetVariable Scanrate_tab0,format="%.3W1Ps"
	SetVariable Scanrate_tab0,value= root:packages:FMscans:CountWave[6]
	SetVariable distbtw_tab0,pos={8,171},size={171,16},bodyWidth=80,title="Distance Between"
	SetVariable distbtw_tab0,format="%.3W1Pv"
	SetVariable distbtw_tab0,value= root:packages:FMscans:CountWave[7]
	CheckBox KeepScanning_tab0,pos={10,193},size={91,14},proc=KeepRunning,title="Keep Scanning"
	CheckBox KeepScanning_tab0,value= 0
	Button Approach_tab0,pos={119,216},size={60,20},proc=ApproachButton,title="Approach"
	Button Approach_tab0,fColor=(61440,61440,61440)
	Button ClearData_tab0,pos={203,194},size={80,20},proc=ApproachButton,title="Refresh Data"
	Button ClearData_tab0,fColor=(61440,61440,61440)
	Button ClearLastPoint_tab0,pos={203,216},size={80,20},proc=ApproachButton,title="Clear Last Run"
	Button ClearLastPoint_tab0,fColor=(61440,61440,61440)
	CheckBox Retract_tab0,pos={10,211},size={53,14},title="Retract",value= 0
	ValDisplay EstDisttoSurf_tab0,pos={320,31},size={179,14},bodyWidth=60,title="Est. Distance to Surface"
	ValDisplay EstDisttoSurf_tab0,format="%.2W1Pm",limits={0,0,0},barmisc={0,1000}
	ValDisplay EstDisttoSurf_tab0,value= #"root:packages:FMscans:countwave[9]"
	CheckBox CopySQ_tab0,pos={10,228},size={77,14},title="Duplicate Fit",value= 1
	ValDisplay distancetomove_tab0,pos={190,173},size={95,14},format="%.3W1Pm"
	ValDisplay distancetomove_tab0,limits={0,0,0},barmisc={0,1000}
	ValDisplay distancetomove_tab0,value= #"root:packages:fmscans:twave[0]"
	SetVariable Maxfreq_tab1,pos={12,33},size={142,16},bodyWidth=60,disable=1,title="Max Freq. Offset"
	SetVariable Maxfreq_tab1,format="%.0W1PHz"
	SetVariable Maxfreq_tab1,value= root:packages:FMscans:CountWave[8]
	SetVariable Maxvar_tab0,pos={106,299},size={84,16},bodyWidth=60,title="Max"
	SetVariable Maxvar_tab0,value= root:packages:FMscans:minmaxw[1]
	SetVariable MinVar_tab0,pos={13,299},size={81,16},bodyWidth=60,title="Min"
	SetVariable MinVar_tab0,value= root:packages:FMscans:minmaxw[0]
	TabControl Approaches,pos={8,5},size={500,20},proc=TabProc
	TabControl Approaches,tabLabel(0)="General Approach",tabLabel(1)="FM Approach"
	TabControl Approaches,tabLabel(2)="AM Approach",value= 0
	SetVariable DriveFrequencySetVar_tab0,pos={16,94},size={192,16},bodyWidth=110,proc=TuneSetVarFunc,title="Drive Frequency"
	SetVariable DriveFrequencySetVar_tab0,font="MS Sans Serif",fSize=12
	SetVariable DriveFrequencySetVar_tab0,format="%.3W1PHz"
	SetVariable DriveFrequencySetVar_tab0,limits={-inf,inf,400},value= root:packages:MFP3D:Main:Variables:MasterVariablesWave[%DriveFrequency][%Value]
	PopupMenu Method_tab0,pos={10,247},size={139,22},bodyWidth=100,proc=PopMenuProc,title="Method"
	PopupMenu Method_tab0,help={"Chooses which method to use"}
	PopupMenu Method_tab0,mode=1,popvalue="FM Static",value= #"\"FM Static;FM Sweep;AMFM Static;AM Static\""
	PopupMenu Variable_tab0,pos={11,272},size={135,22},title="Varying"
	PopupMenu Variable_tab0,mode=1,popvalue="Height (nm)",value= #"\"Height (nm);FM Igain;FM Pgain;Dis Igain;Dis Pgain;Offset (Hz);Time (s)\""
	SetVariable NumberofVoltages_tab1,pos={11,52},size={100,16},disable=1,title="Voltages"
	SetVariable NumberofVoltages_tab1,value= root:packages:FMscans:FMappwave[3]
	SetVariable Numruns_tab0,pos={13,318},size={161,16},bodyWidth=80,title="Number of Runs"
	CheckBox FreqGainOnBox_tab1,pos={10,73},size={110,15},disable=1,proc=FMCheckboxFunc,title="FM Feedback On"
	CheckBox FreqGainOnBox_tab1,font="Arial",fSize=12,value= 0
	SetVariable FreqIGainSetVar_tab1,pos={9,94},size={174,18},bodyWidth=110,disable=1,proc=FMSetVarFunc,title="Freq I Gain"
	SetVariable FreqIGainSetVar_tab1,font="Arial",fSize=12
	SetVariable FreqIGainSetVar_tab1,limits={-inf,inf,0.5},value= root:packages:MFP3D:Main:Variables:MasterVariablesWave[%FreqIGain][%Value]
	SetVariable FreqPGainSetVar_tab1,pos={4,117},size={179,18},bodyWidth=110,disable=1,proc=FMSetVarFunc,title="Freq P Gain"
	SetVariable FreqPGainSetVar_tab1,font="Arial",fSize=12
	SetVariable FreqPGainSetVar_tab1,limits={-inf,inf,0.5},value= root:packages:MFP3D:Main:Variables:MasterVariablesWave[%FreqPGain][%Value]
	SetVariable DriveIGainSetVar_tab1,pos={263,100},size={177,18},bodyWidth=110,disable=1,proc=FMSetVarFunc,title="Drive I Gain"
	SetVariable DriveIGainSetVar_tab1,font="Arial",fSize=12,format="%.2f "
	SetVariable DriveIGainSetVar_tab1,limits={-inf,inf,0.1},value= root:packages:MFP3D:Main:Variables:MasterVariablesWave[%DriveIGain][%Value]
	SetVariable DrivePGainSetVar_tab1,pos={258,125},size={182,18},bodyWidth=110,disable=1,proc=FMSetVarFunc,title="Drive P Gain"
	SetVariable DrivePGainSetVar_tab1,font="Arial",fSize=12,format="%.2f "
	SetVariable DrivePGainSetVar_tab1,limits={-inf,inf,0.1},value= root:packages:MFP3D:Main:Variables:MasterVariablesWave[%DrivePGain][%Value]
	SetVariable DissipationLimitHighSetVar_tab1,pos={239,150},size={201,18},bodyWidth=110,disable=1,proc=FMSetVarFunc,title="Drive Limit High"
	SetVariable DissipationLimitHighSetVar_tab1,font="Arial",fSize=12
	SetVariable DissipationLimitHighSetVar_tab1,format="%.2W1PV"
	SetVariable DissipationLimitHighSetVar_tab1,limits={-inf,inf,0.1},value= root:packages:MFP3D:Main:Variables:DigitalFMVariablesWave[%DissipationLimitHigh][%Value]
	SetVariable DissipationLimitLowSetVar_tab1,pos={242,175},size={198,18},bodyWidth=110,disable=1,proc=FMSetVarFunc,title="Drive Limit Low"
	SetVariable DissipationLimitLowSetVar_tab1,font="Arial",fSize=12,format="%g V"
	SetVariable DissipationLimitLowSetVar_tab1,limits={-inf,inf,0.1},value= root:packages:MFP3D:Main:Variables:DigitalFMVariablesWave[%DissipationLimitLow][%Value]
	SetVariable DriveLoopSetpointVoltsetva_tab1,pos={246,200},size={194,18},bodyWidth=110,disable=1,proc=FMSetVarFunc,title="Drive Set Point"
	SetVariable DriveLoopSetpointVoltsetva_tab1,font="Arial",fSize=12
	SetVariable DriveLoopSetpointVoltsetva_tab1,format="%.2W1PV"
	SetVariable DriveLoopSetpointVoltsetva_tab1,limits={-inf,inf,0.1},value= root:packages:MFP3D:Main:Variables:DigitalFMVariablesWave[%DriveLoopSetpointVolts][%Value]
	CheckBox DriveGainOnBox_tab1,pos={330,75},size={122,15},disable=1,proc=FMCheckboxFunc,title="Drive Feedback On"
	CheckBox DriveGainOnBox_tab1,font="Arial",fSize=12,value= 0
	SetVariable DisplaySpringConstantSetVa_tab0,pos={20,54},size={209,16},bodyWidth=130,proc=ForceSetVarFunc,title="Spring Constant"
	SetVariable DisplaySpringConstantSetVa_tab0,fSize=12,format="%.2W1PN/nm"
	SetVariable DisplaySpringConstantSetVa_tab0,limits={-inf,inf,2e-10},value= root:packages:MFP3D:Main:Variables:MasterVariablesWave[%DisplaySpringConstant][%Value]
	SetVariable PiezoDrive_tab2,pos={25,299},size={152,16},bodyWidth=60,disable=1,title="Piezo Drive Height"
	SetVariable PiezoDrive_tab2,format="%.2W1Pm"
	SetVariable PiezoDrive_tab2,limits={-inf,inf,1e-09},value= root:packages:FMscans:CountWave[3]
	SetVariable AMampset_tab2,pos={30,53},size={132,16},bodyWidth=60,disable=1,proc=SetVarProc_2,title="AM Amplitude "
	SetVariable AMampset_tab2,format="%.3W1Pv"
	SetVariable AMampset_tab2,limits={0,inf,0.001},value= root:packages:FMscans:CountWave[2]
	PopupMenu popup0_tab2,pos={18,108},size={147,22},disable=1,title="AM DDS"
	PopupMenu popup0_tab2,mode=1,popvalue="Cypher DDSB",value= #"\"Cypher DDSB\""
	SetVariable AMfreqset_tab2,pos={31,70},size={173,16},bodyWidth=100,disable=1,proc=SetVarProc_1,title="AM Frequency"
	SetVariable AMfreqset_tab2,format="%.3W1PHz"
	SetVariable AMfreqset_tab2,limits={0,inf,1},value= root:packages:FMscans:CountWave[15]
	SetVariable V_Igain_tab2,pos={292,75},size={92,16},bodyWidth=60,disable=1,proc=SetVarProc_2,title="I Gain"
	SetVariable V_Igain_tab2,value= root:packages:FMscans:CountWave[11]
	SetVariable D_Pgain_tab2,pos={284,226},size={96,16},bodyWidth=60,disable=1,proc=SetVarProc_2,title="P Gain"
	SetVariable D_Pgain_tab2,value= root:packages:FMscans:CountWave[14]
	SetVariable D_Igain_tab2,pos={287,207},size={92,16},bodyWidth=60,disable=1,proc=SetVarProc_2,title="I Gain"
	SetVariable D_Igain_tab2,value= root:packages:FMscans:CountWave[13]
	SetVariable V_Pgain_tab3,pos={291,95},size={96,16},bodyWidth=60,disable=1,proc=SetVoltage,title="P Gain"
	SetVariable V_Pgain_tab2,pos={287,96},size={96,16},bodyWidth=60,disable=1,proc=SetVarProc_2,title="P Gain"
	SetVariable V_Pgain_tab2,value= root:packages:FMscans:CountWave[12]
	Button SetVLoop_tab2,pos={281,122},size={100,20},disable=1,proc=VoltageLoop,title="Set Voltage Loop"
	Button StartVLoop_tab2,pos={282,146},size={100,20},disable=1,proc=VoltageLoop,title="Start Voltage Loop"
	Button StopVLoop_tab2,pos={283,168},size={100,20},disable=1,proc=VoltageLoop,title="Stop Voltage Loop"
	Button SetDLoot_tab2,pos={281,249},size={110,20},disable=1,proc=DissipationLoop,title="Set Dissipation Loop"
	Button StartDLoop_tab2,pos={281,272},size={110,20},disable=1,proc=DissipationLoop,title="Start Dissipation Loop"
	Button StopDLoot_tab2,pos={281,295},size={110,20},disable=1,proc=DissipationLoop,title="Stop Dissipation Loop"
	SetVariable AMfreqset2_tab2,pos={23,87},size={182,16},bodyWidth=100,disable=1,title="AM Frequency 2"
	SetVariable AMfreqset2_tab2,format="%.3W1PHz"
	SetVariable AMfreqset2_tab2,limits={0,inf,0},value= root:packages:FMscans:CountWave[10]
	SetVariable InvolsSetVar_tab0,pos={35,74},size={152,16},bodyWidth=90,proc=ForceSetVarFunc,title="Defl InvOLS"
	SetVariable InvolsSetVar_tab0,fSize=12,format="%.2W1Pm/V"
	SetVariable InvolsSetVar_tab0,limits={-inf,inf,1e-08},value= root:packages:MFP3D:Main:Variables:MasterVariablesWave[%InvOLS][%Value]
EndMacro

Function KeepRunning(ctrlName,run) : CheckBoxControl
	String ctrlName
	Variable run
End


//Functions for saving data:

Function ConvertFD( Wave1, suffix)
	Wave Wave1
	string suffix
	Make/T/O namestring = {"awave","owave","cwave","ErrA","Erro","ErrC","Hwave","vhalfw","scanrate","distw","Estpos","Timew","Frofavg", "Frofsdev","DefA","DefO","DefC","AvgAmp", "HTemp", "EnclTemp"}
	Variable size = Dimsize(Wave1,0)
	
	Variable i
	For(i=0;i<size;i+=1)
		Make/O/N=(Dimsize(Wave1, 1)) $(namestring[i]+suffix) = Wave1[i][p]
	endfor
	
	Variable oc = 3.14*10E-6*8.8E-12*60124/(2*0.95)//This variable must be calibrated correctly for numdist to make sense
	Make/O/N=(Dimsize(Wave1, 1)) $("locsd" + suffix) = wave1[11][p] - wave1[6][p]
	Make/O/N=(Dimsize(Wave1, 1)) $("osd" + suffix) = wave1[10][p] - wave1[6][p]
	Make/o/N=(Dimsize(Wave1, 1)) $("Numdist" + suffix) = 1/sqrt(wave1[0][p]/oc)
	Variable fpos = wave1[10][Dimsize(Wave1, 1)-10]
	Make/o/N=(Dimsize(Wave1, 1)) $("hrel" + suffix) = -(wave1[6][p] - fpos)
	Make/o/N=(Dimsize(Wave1, 1)) $("hadj" + suffix) = wave1[6][p] - wave1[16][p]*59.35*10^-9
End//ConvertfDatawave

Function ConvertWaves( suffix )
	String suffix
	String rrname = "runrec" + suffix
	Wave fdatawave, Runwave, savewave
	Variable rrl = Dimsize(runwave, 1)
	
	Save/P=SaveForce/O fdatawave as ("fdatawave" + suffix + ".ibw")
	Save/P=SaveForce/O Runwave as ("runwave" + suffix + ".ibw")
	Save/P=SaveForce/O savewave as ("savedwave" + suffix + ".ibw")
	
	ConvertFD(fdatawave, suffix)
	
	Duplicate/O runwave $rrname
	Redimension/N=(-1,(rrl-1)) $rrname
	
end

//Functions for calculating drift over many runs:

Function CalcDrift2( quantity, runrec )
	Wave quantity, runrec
	Variable reclength = Dimsize(runrec,1)-1
	
	Make/N=(2,reclength)/O qdrift=0
	
	Variable i = 0
	
	For(i=1;i<=reclength;i+=1)
		qdrift[0][i-1] = quantity[runrec[0][i]]-quantity[runrec[0][0]]//quantity spacing
		qdrift[1][i-1] = runrec[1][i]-runrec[1][0] //Time spacing
	endfor
	
	 //Note that qdrift looks at the change from the initial position
	 //To get a look at how things from one measurement to the next
	 //Regardless of the original position, one should only need to take a derivative
	
end

//Miscellaneous functions which are used in the above programs, but which I could find no better home for

Function Lengthen( thewave ) //increases the length of a wave by 1-designed for fdatawave
	Wave theWave
	variable spot = DimSize(theWave,1)
	
	InsertPoints/M=1 (spot), 1, theWave
	
end//Lengthen

Function RemoveLastScan() //pretty self-explanatory, but I don't like the fact that it exists
	//should not be used in any situation where the data matters, which should be all situations
	Wave Fdatawave, countwave
	Redimension/N=(20, DimSize(Fdatawave,1) -1) Fdatawave
	countwave[1] -= countwave[7]
	//countwave[2] -= countwave[7]
	//td_Wv("Output.z", countwave[1])
end

Function ModPoly(w,V) : FitFunc
	Wave w
	Variable V

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(V) = A*(V-O)^2+C
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ V
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w[0] = A
	//CurveFitDialog/ w[1] = O
	//CurveFitDialog/ w[2] = C

	return -w[0]*(V-w[1])^2+w[2]
End

Function RefreshSQFIT( dist)
	variable dist
	Wave sqfit
	sqfit = {2e-12,.1,dist}
end

Function Powlaw(w,Z) : FitFunc
	Wave w
	Variable Z

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(Z) = B*Abs(z-O)^A + C * Z + D
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ Z
	//CurveFitDialog/ Coefficients 5
	//CurveFitDialog/ w[0] = A
	//CurveFitDialog/ w[1] = B
	//CurveFitDialog/ w[2] = C
	//CurveFitDialog/ w[3] = D
	//CurveFitDialog/ w[4] = O

	return w[1]*Abs(z-w[4])^w[0] + w[2] * Z + w[3]
End

Function TabProc(tca) : TabControl //This controls the tabs/am using a structure so that it will be easier to modify later
	STRUCT WMTabControlAction &tca
			//print tca.tab
	switch( tca.eventcode )

		case 2: // mouse up
			Variable tab = tca.tab
			String controlsInATab= ControlNameList("",";","*_tab*")
			String curTabMatch= "*_tab"+num2istr(tab)
			String controlsInCurTab= ListMatch(controlsInATab, curTabMatch)
			String controlsInOtherTabs=ListMatch(controlsInATab,"!"+curTabMatch)
			ModifyControlList controlsInOtherTabs disable=1 // hide
			ModifyControlList controlsInCurTab disable=0 // show
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End




Function ApproachButton(ctrlName) : ButtonControl
	String ctrlName
	variable V_value
	
	if(cmpstr(ctrlName,"Approach_tab0") == 0)
		FMAdvanceAuto_P()
	elseif(cmpstr(ctrlName,"ZeroHeight_tab0") == 0)
		td_SetRamp(1,"$outputZloop.setpoint",0,-2.5,"",0,0,"",0,0,"")
	elseif(cmpstr(ctrlName,"CApproach_tab0") == 0)
		FMAdvanceAuto_P()
	elseif(cmpstr(ctrlName,"ClearData_tab0") == 0)
		ClearWaves()
	elseif(cmpstr(ctrlName,"Clearlastpoint_tab0") == 0)
		RemoveLastScan()
	endif

End

Function Tester()
	Wave MasterVariablesWave
	SetDataFolder root:packages:MFP3D:Main:Variables:
	MasterVariablesWave[%FreqIgain][%value]=5
end



Function PopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	wave countwave

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
				XPTPopupFunc("OutZModPopup",17,"Off")
				XPTPopupFunc("PogoOutPopup",10,"Ground")
				XPTPopupFunc("ChipPopup",10,"Ground")
				XPTPopupFunc("CypherHolderOut0Popup",20,"ContChip")
				//td_ws("Cypher.pipehack.22","User A")
				td_wv("Arc.Lockin.0.Freq", 0)
				td_wv("Arc.Lockin.1.Freq", 0)
				td_wv("Arc.Lockin.0.Amp", 0)
				switch(popNum)
					case 4:
						XPTPopupFunc("OutZModPopup",12,"PogoIn0")
						XPTPopupFunc("CypherContPogoInPopup",33,"DDSB")
					case 3:
						XPTPopupFunc("ShakePopup",16,"DDS")
						XPTPopupFunc("CypherHolderOut0Popup",20,"ContShake")
						XPTPopupFunc("PogoOutPopup",3,"OutC")
						//td_ws("Cypher.pipehack.22","Lockin B0 q")
						td_wv("Arc.Lockin.0.Freq", countwave[9])
						td_wv("Arc.Lockin.1.Freq", countwave[10])
						td_wv("Arc.Lockin.0.Amp", 1e-2)
					break
					case 1:
					case 2:
						XPTPopupFunc("ChipPopup",3,"OutC")
					break
				endswitch
				 XPTButtonFunc("WriteXPT")
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function SetVoltageFeedback()
	//Startup XYZ closed loops all at the same time.

	String ErrorStr = ""
	Struct ARFeedbackStruct FB
	Wave parms = root:VoltageFeedback:VFparms
	wave countwave
	ARGetFeedbackParms(FB,"Potential")
	ARREportError(ErrorStr)
	FB.LoopName = "VoltageLoop"
	FB.Input="Arc.Lockin.0.q"
	FB.Output="ARC.Output.C"
	FB.Bank=5
	FB.OutputMin = -6
	FB.OutputMax= 6
	FB.IGain = Countwave[11]
	FB.PGain= Countwave[12]
	ARREportError(ErrorStr)
	FB.StartEvent = num2str(5)
	FB.StopEvent = "Never"
	ErrorStr += ir_writePIDSloop(FB)

	//now start them all up

	//ErrorStr += num2str(td_WriteString("Event."+FB.StartEvent,"Once"))+","
	ARREportError(ErrorStr)
End //Set_Voltage_Feedback

Function StartVoltageLoop()
	String ErrorSTR = ""

	Struct ARFeedbackStruct FB
	ARCLoadPIDSstruct( FB, 5)
	//print FB.StartEvent
	ErrorStr += num2str(td_WriteString("Event."+FB.StartEvent,"Once"))+","

end

Function StopVoltageLoop()
	ir_StopPISloop(NaN,LoopName="VoltageLoop")
	td_wv("output.c",0) //Sent the output tracking voltage back to zero
end

Function StartDissipationLoop()
	String ErrorSTR = ""
	Struct ARFeedbackstruct FB
	ARGetFeedbackParms(FB,"Drive",ImagingMode=2)
		SetTipProtectLimits()	// Make sure the limits are set
		FB.StartEvent = "Always"
		ErrorStr += ir_WritePIDSloop(FB)
end

Function VoltageLoop(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			//print ba.ctrlname
				strswitch(ba.ctrlname)
					case "SetVLoop_tab2":
						SetVoltageFeedback()
					break
					case "StartVLoop_tab2":
						StartVoltageLoop()
					break
					case "StopVLoop_tab2":
						StopVoltageLoop()
					break
			// click code here
			endswitch
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ARCLoadPIDSstruct( pidstruct, bank)
	Variable Bank
	Struct ARFeedbackstruct &pidstruct
	String path = "Arc.PIDSloop."+num2str(bank) +"."

	pidstruct.setpoint = td_rv(path + "Setpoint")
	pidstruct.Setpointoffset = td_rv(path + "Setpointoffset")
	pidstruct.Dgain = td_rv(path + "Dgain")
	pidstruct.Igain = td_rv(path + "Igain")
	pidstruct.Pgain = td_rv(path + "Pgain")
	pidstruct.Sgain = td_rv(path + "Sgain")
	pidstruct.Outputmin = td_rv(path + "Outputmin")
	pidstruct.Outputmax = td_rv(path + "Outputmax")
	pidstruct.StartEvent= td_rs(path + "StartEvent")
	pidstruct.StopEvent= td_rs(path + "StopEvent")
	//pidstruct.InputChannel = td_rs(path+"InputChannel")
	//pidstruct.OutputChannel = td_rs(path+"OutputChannel")

end


Function SetDissipationFeedback()
	//Startup XYZ closed loops all at the same time.

	String ErrorStr = ""
	Struct ARFeedbackStruct FB
	Wave parms = root:VoltageFeedback:VFparms
	wave countwave
	ARGetFeedbackParms(FB,"DriveLoop")
	ARREportError(ErrorStr)
	FB.LoopName = "DriveLoop2"
	FB.Input="Arc.Lockin.1.r"
	FB.Output="ARC.Lockin.0.Amp"
	FB.Bank=0
	FB.Setpoint=countwave[2]
	FB.OutputMin = 0
	FB.OutputMax= 5
	FB.IGain = Countwave[13]
	FB.PGain= Countwave[14]
	ARREportError(ErrorStr)
	FB.StartEvent = num2str(6)
	FB.StopEvent = "Never"
	ErrorStr += ir_writePIDSloop(FB)

	//now start them all up

	//ErrorStr += num2str(td_WriteString("Event."+FB.StartEvent,"Once"))+","
	ARREportError(ErrorStr)
End //Set_Voltage_Feedback


Function DissipationLoop(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			strswitch(ba.ctrlname)
				case "SetDLoot_tab2":
					SetDissipationFeedback()
				break
				case "StartDLoop_tab2":
					StartDiLoop()
				break
				case "StopDLoot_tab2":
					StopDLoop()
				break
			endswitch
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function StopDLoop()
	ir_StopPISloop(NaN,LoopName="DriveLoop2")
	td_wv("Arc.Lockin.0.Amp",1e-3)
end

Function StartDiLoop()
	String ErrorSTR = ""

	Struct ARFeedbackStruct FB
	ARCLoadPIDSstruct( FB, 0)
	//print FB.StartEvent
	ErrorStr += num2str(td_WriteString("Event."+FB.StartEvent,"Once"))+","

end



Function SetVarProc_1(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	Wave countwave
	Controlinfo/W=Approach_panel	 Method_tab0 
	
	If(!(cmpstr(S_value,"AMFM Static")) || !(cmpstr(S_value,"AM Static")))	
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			Countwave[15] = sva.dval
			Countwave[10] = 2*sva.dval
			td_wv("Arc.Lockin.0.Freq", countwave[15])
			td_wv("Arc.Lockin.1.Freq", countwave[10])	
			
			break
		case -1: // control being killed
			break
	endswitch
	else
		countwave[15]=0
		countwave[10]=0
	endif

	return 0
End


Function CalcCasForce()
	Wave countwave,  w1
end

//The Calibrator

//The automated portion
//This first function only sets the phase for the ARCDDS. The LockinB seems more difficult to set, and will require a different method
Function Start_autocal(seconds)
	variable seconds	
	Wave countwave
	variable desiredphase0 = 90
	variable desiredphase1 = 90
	variable counts = 0
	Variable tolerance = .0001
	Make/n=4/o calparms =  {counts, desiredphase0, desiredphase1, seconds, tolerance}
	Make/n=(6,2)/o calrecord = 0
	Make/n=(2,2)/o thetas = 0
	
	Variable l0, l1
	l0 = td_rv("Arc.Lockin.0.Freq")
	l1 = td_rv("Arc.Lockin.1.Freq")
	
		DDS_ground_cal()
end

//This function sets the input of the ARCDDS to ground and runs/records a scan 
Function DDS_ground_cal()
	Wave calparms
	XPTPopupFunc("InFastPopup",10,"Ground")
	XPTButtonFunc("WriteXPT")
	
	STRUCT WMButtonAction bc
	bc.eventcode=2
	bc.ctrlName = "StopVLoop_tab2"
	VoltageLoop(bc)
	bc.ctrlName = "StopDLoop_tab2"
	DissipationLoop(bc)
	
	td_wv("Arc.Lockin.0.Amp",0)
	td_wv("Arc.Lockin.1.Amp",0)
	td_wv("Arc.Lockin.DCOffset",0)
	
	calibrator_start(calparms[3], 1, "DDS_noamp_cal()")
	
end

Function DDS_interp()
	Wave calwave, calrecord, calparms, thetas
	//print "here"
	//print calparms[0]
	//make/n=6/o practice
	//practice = calwave[p][0][0]
	//print calwave[0][0][0]
	calrecord[][calparms[0]] =calwave[p][0][0]
	thetas[0][calparms[0]] =  td_rv("Arc.Lockin.0.phaseoffset")
	thetas[1][calparms[0]] =  td_rv("Arc.Lockin.1.phaseoffset")
	
end

//With a callback to this function, the inputs are set to Defl again, but the feedback loops are turned off, and the excitation is zeroed
Function DDS_noamp_cal()
	Wave calparms, calibrations, calrecord
	
	
	DDS_interp()
	XPTPopupFunc("InFastPopup",4,"Defl")
	XPTButtonFunc("WriteXPT")

	calibrations = {calrecord[0][0], calrecord[2][0]}
	
	calibrator_start(calparms[3], 1, "DDS_on()")
	
end

function DDS_on()
	wave calparms 
	
	calparms[0] += 1
	DDS_interp()
	
	td_wv("Arc.Lockin.0.Amp",3)
	td_wv("Arc.Lockin.DCOffset",3)

	
	DDS_cal()
end

//Now the excitation and constant offset are both set to 3 V
//calibrator is run again, theta is calculated 
Function DDS_cal()
	Wave calparms, calrecord, thetas
	
	Lengthen(calrecord)
	Lengthen(thetas)

	calibrator_start(calparms[3], 1, "Set_theta()")
end

//This is the callback from calculating theta
//the phase offset is set and the calibration is run again
Function Set_theta()
	Wave calparms, calrecord
		
	if(calparms[0] == 1)
		make/o/n=1 th0est, th1est
	else
		wave th0est, th1est
		redimension/n=(calparms[0]-1) th0est, th1est
	endif
	
	calparms[0] += 1
	DDS_interp()

	Variable offset0i=calrecord[0][0], offset0q=calrecord[1][0],offset1i=calrecord[2][0], offset1q=calrecord[3][0]

	Variable amplitude0i = calrecord[0][calparms[0]]
	Variable amplitude0q = calrecord[1][calparms[0]]

	Variable amplitude1i = calrecord[2][calparms[0]]
	Variable amplitude1q = calrecord[3][calparms[0]]	
	
	Variable angle0, angle1
	
	Variable resid0i = amplitude0i - offset0i
	Variable resid0q = amplitude0q - offset0q
	
	Variable resid1i = amplitude1i - offset1i
	Variable resid1q = amplitude1q - offset1q
	
	angle0 = 180/pi*atan2(resid0q,resid0i)
	angle1 = 180/pi*atan2(resid1q,resid1i)
	
	Variable dangle0 = (calparms[1] - angle0)
	Variable dangle1 = (calparms[2] - angle1)
	
	print dangle0
	
	//print angletoset0
	//print angletoset1

	if( ((abs(resid0i) < calparms[4]) && resid0q >0) )//&& ((abs(resid1i) < calparms[4]) && resid1q >0) )
		print "Calibration complete"
		return 0
	elseif(1)
	
		variable angletoset0 = dangle0 + td_rv("Arc.Lockin.0.PhaseOffset") 
		angletoset0 = Mod(angletoset0+360, 360)
		if(angletoset0 >180)
			angletoset0 -= 360
		endif
		th0est[calparms[0]-3] = angletoset0
		//print calparms[0]
		//print dimsize(th0est,0)
		wavestats/q th0est
		//print V_avg
		variable act_set =  V_avg + dangle0/2
		td_wv("Arc.Lockin.0.PhaseOffset", act_set)
		//print angletoset0

		
		variable angletoset1 = dangle1 + td_rv("Arc.Lockin.1.PhaseOffset") 
		angletoset1 = Mod(angletoset1+360, 360)
		if(angletoset1 >180)
			angletoset1 -= 360
		endif
		td_wv("Arc.Lockin.1.PhaseOffset", angletoset1)
		
		DDS_cal() 
	endif 
	
end


//The manual version
function calibrator_start( duration, number, callback)
	variable duration, number
	string callback
	make/o/n=3 ccwave = {0, number, duration} //will include number of runs and duration(in seconds) 
	make/o/n=(6,number,2) calwave = 0
	make/o/n=6/t strings_to_read = {"Arc.Lockin.0.i","Arc.Lockin.0.q","Arc.Lockin.1.i","Arc.Lockin.1.q","Arc.pipe.22.cypher.input.a","Arc.pipe.23.cypher.input.b"}	
	
	cal_set(callback)
	
end //calibrator

function cal_set(callback)
	String callback
	Wave/t strings_to_read
	Wave ccwave
	Variable duration = ccwave[2]
	Variable Decim = 1 //how many samples go into one datapoint?
	Variable wlength = 5e4/decim*Duration
	wlength -= Mod(wlength, 32) //must modify the wavelength so that data transfer works

	td_stopInwavebank(-1)//stop all incoming/outgoing waves
	td_stopoutwavebank(-1)

	
	Make/O/N=(wlength) cal0,cal1,cal2,cal3,cal4,cal5

	td_xsetinwavepair(2, "0,0",strings_to_read[0], cal0 ,strings_to_read[1], cal1, "cal_callback(\""+callback+"\")",decim)//set up our measurement
	td_xsetinwavepair(1, "0,0", strings_to_read[2], cal2 ,strings_to_read[3], cal3, "" ,decim)
	td_xsetinwavePair(0, "0,0",strings_to_read[4], cal4 ,strings_to_read[5], cal5, "",Decim) 
	td_writestring("0%event", "once") //start the measurement
	
	return 0
	
end

function cal_callback( callback )
	string callback
	wave cal0,cal1,cal2,cal3,cal4,cal5
	wave ccwave, calwave
	variable j = ccwave[0]
	variable i
	
	duplicate/o cal0 caldisplay
	
	for(i=0;i<6;i+=1)
	wavestats/Q $("cal" + num2str(i))
	calwave[i][j][0] = V_avg
	calwave[i][j][1] = V_sdev
	
	endfor
	
	ccwave[0]+=1
	if(ccwave[0]<ccwave[1])
		cal_set("")
	else
		//print "done"
	endif
	
	Execute(callback)
	
	return 0
	
end

function calc_angles( cala, calb, callback )
	string callback
	wave cala, calb
	duplicate/o cala angles
	variable i,l = Dimsize(cala, 0)
	
	angles = 180/pi*sign(calb[p]) * atan(calb[p]/cala[p])
	
	Execute(callback)
	
	return 0
	
end

function manyangles()
	variable/G counter = 0
	make/n=36/o angles
	angles = -180+p*10

	td_wv("Arc.lockin.0.phaseoffset", angles[0])
	KV_advance()

end

function nextangle()
	Variable/G counter
	string na = "a2_"
	wave prelims2nd, angles
	
	duplicate/o prelims2nd $(na + num2str(180+angles[counter]))
	
	counter +=1 
	td_wv("Arc.lockin.0.phaseoffset", angles[counter])
	
	if(counter < 36)
		KV_advance()
	endif
	
end

Window Graph1() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:packages:KelvinVoltage:
	Display /W=(111,380,505.5,588.5) prelims2nd[0][0][*] vs frequencies
	AppendToGraph prelims2nd[0][1][*] vs frequencies
	AppendToGraph prelims2nd[0][2][*] vs frequencies
	AppendToGraph prelims2nd[0][3][*] vs frequencies
	AppendToGraph prelims2nd[0][4][*] vs frequencies
	SetDataFolder fldrSav0
	ModifyGraph rgb(prelims2nd#2)=(0,0,0)
EndMacro

Window Graph900() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:packages:KelvinVoltage:
	Display /W=(111,380,505.5,588.5) prelims2nd[1][0][*] vs frequencies
	AppendToGraph prelims2nd[1][1][*] vs frequencies
	AppendToGraph prelims2nd[1][2][*] vs frequencies
	AppendToGraph prelims2nd[1][3][*] vs frequencies
	AppendToGraph prelims2nd[1][4][*] vs frequencies
	SetDataFolder fldrSav0
	ModifyGraph rgb(prelims2nd#2)=(0,0,0)
EndMacro

function Graphplots( mywave ) : Graph
	string mywave
	duplicate/o $(mywave) mw
	wave frequencies
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:packages:KelvinVoltage:
	Display /W=(111,380,505.5,588.5) $(mywave)[0][0][*] vs frequencies
	AppendToGraph $(mywave)[0][1][*] vs frequencies
	AppendToGraph $(mywave)[0][2][*] vs frequencies
	AppendToGraph $(mywave)[0][3][*] vs frequencies
	AppendToGraph $(mywave)[0][4][*] vs frequencies
	SetDataFolder fldrSav0
	string modwave = mywave + "#2" 
	ModifyGraph rgb($(modwave))=(0,0,0)
	TextBox/C/N=text0/A=MC/X=-30.00/Y=-10 mywave
	ModifyGraph nticks(left)=0
	ModifyGraph nticks=0,sep(bottom)=1,manTick=0
	ModifyGraph sep=5;DelayUpdate
	Label left "\\u#2";DelayUpdate
	Label bottom "\\u#2"
End

function plotall()
	string na = "angle"
	Wave angles
	string name = ""
	variable i = 0
	
	for(i=0;i<36;i+=1)
	name = (na + num2str(180+angles[i]))
	Graphplots( name )
	endfor

end

Window Outofphase() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:packages:KelvinVoltage:
	Display /W=(35.25,41.75,429.75,250.25) all1[0][0][*] vs frequencies
	AppendToGraph all1[0][1][*] vs frequencies
	AppendToGraph all1[0][2][*] vs frequencies
	AppendToGraph all1[0][3][*] vs frequencies
	AppendToGraph all1[0][4][*] vs frequencies
	AppendToGraph all1[0][5][*] vs frequencies
	AppendToGraph all1[0][6][*] vs frequencies
	AppendToGraph all1[0][7][*] vs frequencies
	AppendToGraph all1[0][8][*] vs frequencies
	AppendToGraph all1[0][9][*] vs frequencies
	SetDataFolder fldrSav0
EndMacro



Window inphase() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:packages:KelvinVoltage:
	Display /W=(36.75,273.5,431.25,482) all1[1][0][*] vs frequencies
	AppendToGraph all1[1][1][*] vs frequencies
	AppendToGraph all1[1][2][*] vs frequencies
	AppendToGraph all1[1][3][*] vs frequencies
	AppendToGraph all1[1][4][*] vs frequencies
	AppendToGraph all1[1][5][*] vs frequencies
	AppendToGraph all1[1][6][*] vs frequencies
	AppendToGraph all1[1][7][*] vs frequencies
	AppendToGraph all1[1][8][*] vs frequencies
	AppendToGraph all1[1][9][*] vs frequencies
	SetDataFolder fldrSav0
	ModifyGraph rgb(all1#5)=(0,52224,0)
EndMacro

//The following code has been designed for the setup of Heterodyne KPFM

function Tune_bandpass_frequency() //we will use this function
	
	SetDataFolder root:packages:KelvinVoltage
	wave bandpass
	variable fbp = bandpass[0]
	
	SetDataFolder root:packages:MFP3D:main:variables:
	wave mastervariableswave
	TuneBoxFunc("PiezoDriveBox_3",1)
	mastervariableswave[%DriveFrequency][%value] = fbp
	mastervariableswave[%DriveAmplitude][%value] = 0.5
	mastervariableswave[%SweepWidth][%value] = fbp*.1
	SetDataFolder root:packages:KelvinVoltage
	
	
	TunePanelPopupFunc("TuneLockInPopup_3",1,"ARC")
	
	XPTPopupFunc("CypherContPogoIn1Popup",2,"OutA") 
	XPTPopupFunc("BNCout1Popup",13,"PogoIn1") 
	XPTPopupFunc("BNCout0Popup",16,"DDS") 
	XPTPopupFunc("InFastPopup",7,"BncIn0") 
	XPTPopupFunc("ShakePopup",10,"Ground") 
	XPTButtonFunc("WriteXPT")
	ARCheckFunc("DontChangeXPTCheck",1)
	
	print td_wv("Cypher.Output.A",0.5)
	ARCheckFunc("ARUserCallbackTuneCheck_1",0)
end

function Tune_bandpass_amplitude()

	SetDataFolder root:packages:KelvinVoltage
	wave bandpass
	wave eigenmodes
	variable f0 = eigenmodes[0][0]
	variable fbp = bandpass[0]
	print f0
	
	SetDataFolder root:packages:MFP3D:main:variables:
	wave mastervariableswave
	//TuneBoxFunc("PiezoDriveBox_3",1)
	//mastervariableswave[%DriveFrequency][%value] = fbp
	//mastervariableswave[%DriveAmplitude][%value] = 0.5
	SetDataFolder root:packages:KelvinVoltage

	ARCheckFunc("DontChangeXPTCheck",0)
	TunePanelPopupFunc("TuneLockInPopup_3",2,"CypherA")
	TuneBoxFunc("BlueDriveOnBox_3",1)
	
	SetDataFolder root:packages:MFP3D:main:variables:
	wave mastervariableswave
	mastervariableswave[%DriveFrequency][%value] = f0
	TuneSetVarFunc("AutoTuneLowSetVar_3",(f0-2000),"","")	
	TuneSetVarFunc("AutoTuneHighSetVar_3",(f0+2000),"","")	
	TuneSetVarFunc("TargetVoltageSetVar_3", 1 ,"","")	
	
	ARCheckFunc("ARUserCallbackMasterCheck_1",1)
	ARCheckFunc("ARUserCallbackTuneCheck_1",1)
	wave/T generalvariablesdescription
	generalvariablesdescription[%ARUserCallbackTune][%description] = "TBA2()"
	CantTuneFunc("DoTuneAuto_3")	

	
	
end

function TBA2() //Tune bandpass amplitude II, not to be announced
	SetDataFolder root:packages:MFP3D:main:variables:
	variable DCOffset = td_rv("Cypher.LockinA.DCOffset")
	wave mastervariableswave
	
	variable f0 = mastervariableswave[%DriveFrequency][%value]
	
	td_wv("Cypher.Output.A", DCOffset) //7/9/14 I just tested this code, and it does seem to work
	XPTPopupFunc("CypherMath2Popup",32,"DDSA") 
	XPTPopupFunc("CypherMath3Popup",2,"OutA") 
	XPTPopupFunc("CypherContPogoIn1Popup",28,"M2-M3") 
	XPTPopupFunc("BNCout1Popup",13,"PogoIn1") 
	XPTPopupFunc("BNCout0Popup",16,"DDS") 
	XPTPopupFunc("InFastPopup",7,"BncIn0")
	
	XPTButtonFunc("WriteXPT")
	ARCheckFunc("DontChangeXPTCheck",1)
	
	SetDataFolder root:packages:KelvinVoltage	
	wave eigenmodes, bandpass
	eigenmodes[0][0] = f0
	
	variable f1 =  eigenmodes[1][0]
	variable fbp = bandpass[0]
	td_wv("Arc.Lockin.0.Freq", f1)
	td_wv("Arc.Lockin.0.Amp", 0.1)
	td_wv("Arc.Lockin.1.Freq", fbp)
	
	variable counter = 0
	ARCheckFunc("ARUserCallbackTuneCheck_1",0)

end

function AmpTune( )
	variable counter
	td_stopinwavebank(-1)
	td_writestring("0%event", "clear")
	
	Variable NPPS = GV("NumPtsPerSec")
	
	Variable Decim = 1 //how many samples go into one datapoint?
	Variable wlength = 5e4 - Mod(5e4, 32)
	
	pv("LowNoise",1)
	
	make/o/n =(wlength) Amp
	Decim =1 
	
	SetDataFolder root:packages:KelvinVoltage	
	wave eigenmodes, bandpass
	variable f1 = eigenmodes[1][0]
	td_wv("Arc.Lockin.0.Freq", f1)
	

	td_xsetinwave(2, "0,0", "Arc.Lockin.1.r", Amp , "AmpTuneCallback()",decim)//set up our measurement
	
	td_writestring("0%event", "once") 
	
end

function AmpTuneCallback( )

	wave Amp
	wavestats/q Amp
	variable Set = 1 //The desired VAC in volts
	variable tolerance = 0.05 //The maximum difference between the desired VAC and the VAC we have
	
	print abs(V_avg-Set)
	
	if(abs(V_avg-Set) < tolerance)
		print "tune done"
		return 0
	else
		variable oldAMP = td_rv("Arc.Lockin.0.amp")
		variable newamp = oldAmp - (V_avg-Set)*.1
		td_wv("Arc.Lockin.0.Amp", newamp)
		//AmpTune()
		print "need more tunes"
		
	endif
	
end

function Setup_V_excitation()
	XPTPopupFunc("CypherMath0Popup",19,"ContPogoOut") 
	XPTPopupFunc("CypherMath1Popup",20,"ContChip") 
	XPTPopupFunc("PogoOutPopup",3,"OutC") 
	XPTPopupFunc("ChipPopup", 7, "BncIn0")
	XPTPopupFunc("CypherSamplePopup",18,"Ground") 
	XPTPopupFunc("CypherHolderOut0Popup",27,"M0+M1") 
	XPTPopupFunc("CypherInFastBPopup",20,"ContChip")
	SetDataFolder root:packages:KelvinVoltage	
	wave bandpass
	variable fbp = bandpass[0]
	
	td_wv("Cypher.LockinB.0.Freq", fbp)
	XPTPopupFunc("InFastPopup",4,"Defl") 
	XPTButtonFunc("WriteXPT")
	ARCheckFunc("DontChangeXPTCheck",1)
	
	td_wv("Cypher.LockinB.0.Filter.Freq", 10000)
	NapPopupFunc("NapModePopup_0",1,"Off")

end

function Setup_Napping_excitation()
	XPTPopupFunc("CypherMath0Popup",19,"ContPogoOut") 
	XPTPopupFunc("CypherMath1Popup",20,"ContChip") 
	XPTPopupFunc("PogoOutPopup",3,"OutC") 
	XPTPopupFunc("ChipPopup", 7, "BncIn0")
	XPTPopupFunc("CypherSamplePopup",18,"Ground") 
	XPTPopupFunc("CypherHolderOut0Popup",27,"M0+M1") 
	XPTPopupFunc("CypherInFastBPopup",6,"ACDefl")
	SetDataFolder root:packages:KelvinVoltage	
	wave bandpass
	variable fbp = bandpass[0]
	
	td_wv("Cypher.LockinB.0.Freq", fbp)
	XPTPopupFunc("InFastPopup",4,"Defl") 
	XPTButtonFunc("WriteXPT")
	ARCheckFunc("DontChangeXPTCheck",1)
	
	td_wv("Cypher.LockinB.0.Filter.Freq", 10000)
	NapPopupFunc("NapModePopup_0",1,"Off")

end


function Setup_data_collection()
	setdatafolder root:packages:MFP3D:Hardware
	wave/T hackalias
	Redimension/N=3 HackAlias
	setdimlabel 0,0, 'UserIn0', hackalias
	setdimlabel 0,1, 'UserIn1', hackalias
	setdimlabel 0,2, 'UserIn2', hackalias
	hackalias = {"Arc.pipe.22.cypher.input.a", "Arc.Output.C","Arc.pipe.23.cypher.input.b"}
	AliasButtonFunc("WriteAliasButton_0")
	
end




Function InitializeHAMKPFM()
	SetDataFolder root:packages:KelvinVoltage
	Make/o/n=(5,2) eigenmodes	
	make/o/n=1 bandpass //0: bandpass frequncy
	Setup_data_collection()
	TunePanelPopupFunc("TuneLockInPopup_3",3,"CypherB")
end

//Right now, everything works with an upper and a lower frequency. In the future, I would like to set up the code so that it automatically chooses which frequencies to use in order to maximize voltage sensitivity


Window HAMKPFM() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(2054,295,2521,710)
	ShowTools/A
	SetDrawLayer UserBack
	DrawText 135,18,"FM-KPFM"
	DrawText 298,20,"H-KPFM"
	DrawText 161,185,"PVFM"
	SetVariable ftop,pos={2,6},size={100,20},title="f\\BT",format="%.3W1PHz"
	SetVariable ftop,limits={-inf,inf,0},value= root:packages:MFP3D:Main:Variables:MasterVariablesWave[%DriveFrequency][%Value],noedit= 1
	SetVariable fA,pos={116,20},size={90,20},title="f\\BA",format="%.3W1PHz"
	SetVariable fA,limits={-inf,inf,10},value= root:packages:KelvinVoltage:KPFM_parameters[%FM_fA]
	PopupMenu BandPass,pos={127,75},size={70,22},title="F\\BD"
	PopupMenu BandPass,mode=2,popvalue="ft-fa",value= #"\"ft+fa;ft-fa\""
	Button Set_Frequencies,pos={15,340},size={150,20},proc=ButtonProc,title="Set frequencies"
	Button Set_Frequencies,fColor=(0,52224,0)
	SetVariable fD,pos={274,23},size={90,20},title="f\\BD",format="%.3W1PHz"
	SetVariable fD,limits={-inf,inf,10},value= root:packages:KelvinVoltage:KPFM_parameters[%H_fD]
	Button Calibrate_2f_phase,pos={102,148},size={150,20},proc=ButtonProc,title="Calibrate 2f phase (FM, PVFM)"
	Button Calibrate_2f_phase,fColor=(52224,52224,52224)
	Button calibrate_LIAAphase,pos={188,124},size={150,20},proc=ButtonProc,title="Calibrate Lockin A Phase"
	Button calibrate_LIAAphase,fColor=(52224,52224,52224)
	SetVariable fi,pos={129,193},size={90,20},title="f\\Bi",format="%.3W1PHz"
	SetVariable fi,limits={-inf,inf,10},value= root:packages:KelvinVoltage:KPFM_parameters[%PV_f]
	Button FM_KPFM_filters,pos={96,50},size={150,20},proc=ButtonProc,title="Set FM-KPFM filters"
	Button FM_KPFM_filters,fColor=(52224,52224,52224)
	Button Set_PVFM_filters,pos={99,215},size={150,20},proc=ButtonProc,title="Set PVFM filters"
	Button Set_PVFM_filters,fColor=(52224,52224,52224)
	Button H_KPFM_filters,pos={263,50},size={150,20},proc=ButtonProc,title="Set H-KPFM filters"
	Button H_KPFM_filters,fColor=(52224,52224,52224)
	PopupMenu BandPass1,pos={279,75},size={73,22},bodyWidth=60,title="f\\BA"
	PopupMenu BandPass1,mode=2,popvalue="|fT-fD|",value= #"\"fT+fD;|fT-fD|\" "
	Button Crosspoint_KPFM,pos={188,102},size={150,20},proc=ButtonProc,title="Set H/FM-KPFM crosspoint"
	Button Crosspoint_KPFM,fColor=(52224,52224,52224)
	Button Crosspoint_PVFM,pos={99,275},size={150,20},proc=ButtonProc,title="SET PVFM crosspoint"
	Button Crosspoint_PVFM,fColor=(52224,52224,52224)
	SetVariable ftop1,pos={121,257},size={100,16},title="illPulse voltage"
	SetVariable ftop1,format="%.3W1PHz"
	SetVariable ftop1,limits={-inf,inf,0},value= root:packages:MFP3D:Main:Variables:MasterVariablesWave[%DriveFrequency][%Value],noedit= 1
	SetVariable bpfreq2,pos={116,238},size={105,16},title="PVFM Counter bias"
	SetVariable bpfreq2,format="%.3W1PHz"
	SetVariable bpfreq2,limits={-inf,inf,0},value= root:packages:KelvinVoltage:bandpass[0]
	SetVariable bpfreq3,pos={10,29},size={91,16},title="Vac",format="%.3W1PV"
	SetVariable bpfreq3,limits={-inf,inf,0},value= root:packages:KelvinVoltage:KPFM_parameters[%V_AC]
	PopupMenu NapModePopup_0,pos={268,275},size={169,22},bodyWidth=110,proc=NapPopupFunc,title="Nap Mode"
	PopupMenu NapModePopup_0,help={"Sets the manner of the interleaved scanning"}
	PopupMenu NapModePopup_0,font="Arial",fSize=12
	PopupMenu NapModePopup_0,mode=1,popvalue="Off",value= #"\"Off;Nap;Parm Swap;Snap;\""
	PopupMenu Choose_mode,pos={29,312},size={108,22},title="Mode"
	PopupMenu Choose_mode,mode=1,popvalue="FM-KPFM",value= #"\"FM-KPFM;PVFM;H-KPFM\""
EndMacro

Window AMliftoutofphase() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:packages:KelvinVoltage:
	Display /W=(846,32,1161.75,224.75) amliftsigall1[0][1][*] vs amliftfreq
	AppendToGraph amliftsigall1[0][3][*] vs amliftfreq
	AppendToGraph amliftsigall1[0][5][*] vs amliftfreq
	AppendToGraph amliftsigall1[0][7][*] vs amliftfreq
	AppendToGraph amliftsigall1[0][9][*] vs amliftfreq
	SetDataFolder fldrSav0
	ModifyGraph margin(left)=40,margin(bottom)=40,margin(top)=20,margin(right)=20
	ModifyGraph rgb=(0,0,0)
	ModifyGraph tick=2
	ModifyGraph mirror=1
	Label left "\\u#2Out of phase lockin signal (mV)"
	Label bottom "\\u#2 Frequency (kHz)"
	TextBox/C/N=text0/F=0/B=1/A=MC/X=16.60/Y=40.76 "0.6 V"
	TextBox/C/N=text1/F=0/B=1/A=MC/X=7.55/Y=29.94 "0.8 V"
	TextBox/C/N=text2/F=0/B=1/A=MC/X=7.55/Y=7.64 "1.1 V"
	TextBox/C/N=text3/F=0/B=1/A=MC/X=7.55/Y=-10.83 "1.3 V"
	TextBox/C/N=text4/F=0/B=1/A=MC/X=7.55/Y=-28.66 "1.5 V"
EndMacro

Window AMliftinphase() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:packages:KelvinVoltage:
	Display /W=(846,230.75,1161.75,423.5) amliftsigall1[1][1][*] vs amliftfreq
	AppendToGraph amliftsigall1[1][3][*] vs amliftfreq
	AppendToGraph amliftsigall1[1][5][*] vs amliftfreq
	AppendToGraph amliftsigall1[1][7][*] vs amliftfreq
	AppendToGraph amliftsigall1[1][9][*] vs amliftfreq
	SetDataFolder fldrSav0
	ModifyGraph margin(left)=40,margin(bottom)=40,margin(top)=20,margin(right)=20
	ModifyGraph rgb=(0,0,0)
	ModifyGraph tick=2
	ModifyGraph mirror=1
	ModifyGraph noLabel(bottom)=2
	ModifyGraph manTick(left)={0,50,-3,0},manMinor(left)={0,50}
	Label left "\\u#2In phase lockin signal (mV)"
	Label bottom "\\u#2"
	TextBox/C/N=text0/F=0/B=1/A=MC/X=7.55/Y=-40.31 "0.6 V"
	TextBox/C/N=text1/F=0/B=1/A=MC/X=-0.31/Y=-12.04 "0.8 V"
	TextBox/C/N=text2/F=0/B=1/A=MC/X=-1.57/Y=4.19 "1.1 V"
	TextBox/C/N=text3/F=0/B=1/A=MC/X=-0.81/Y=27.92 "1.3 V"
	TextBox/C/N=text4/F=0/B=1/A=MC/X=-7.86/Y=39.27 "1.5 V"
EndMacro

Window AMfmoutofphase() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:packages:KelvinVoltage:
	Display /W=(464.25,67.25,780,260) amsigall3[0][0][*] vs amfreq
	AppendToGraph amsigall3[0][2][*] vs amfreq
	AppendToGraph amsigall3[0][3][*] vs amfreq
	AppendToGraph amsigall3[0][5][*] vs amfreq
	AppendToGraph amsigall3[0][9][*] vs amfreq
	SetDataFolder fldrSav0
	ModifyGraph margin(left)=40,margin(bottom)=40,margin(top)=20,margin(right)=20
	ModifyGraph rgb=(0,0,0)
	ModifyGraph tick=2
	ModifyGraph mirror=1
	Label left "\\u#2Out of phase lockin signal (mV)"
	Label bottom "\\u#2 Frequency (kHz)"
	TextBox/C/N=text0/F=0/B=1/A=MC/X=44.44/Y=41.57 "-0.6 V"
	TextBox/C/N=text1/F=0/B=1/A=MC/X=35.96/Y=29.21 "0.1 V"
	TextBox/C/N=text2/F=0/B=1/A=MC/X=26.32/Y=17.42 "0.4 V"
	TextBox/C/N=text3/F=0/B=1/A=MC/X=26.61/Y=2.25 "1.1 V"
	TextBox/C/N=text4/F=0/B=1/A=MC/X=29.53/Y=-12.36 "2.4 V"
EndMacro

Window AMFMinphase() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:packages:KelvinVoltage:
	Display /W=(819.75,242.75,1135.5,435.5) amsigall3[1][0][*] vs amfreq
	AppendToGraph amsigall3[1][2][*] vs amfreq
	AppendToGraph amsigall3[1][3][*] vs amfreq
	AppendToGraph amsigall3[1][5][*] vs amfreq
	AppendToGraph amsigall3[1][9][*] vs amfreq
	SetDataFolder fldrSav0
	ModifyGraph margin(left)=40,margin(bottom)=40,margin(top)=20,margin(right)=20
	ModifyGraph rgb=(0,0,0)
	ModifyGraph tick=2
	ModifyGraph mirror=1
	ModifyGraph noLabel(bottom)=2
	Label left "\\u#2In phase lockin signal (mV)"
	Label bottom "\\u#2"
	TextBox/C/N=text0/F=0/B=1/A=MC/X=-2.63/Y=-16.85 "-0.6 V"
	TextBox/C/N=text1/F=0/B=1/A=MC/X=-2.05/Y=0.56 "0.1 V"
	TextBox/C/N=text2/F=0/B=1/A=MC/X=-1.17/Y=15.73 "0.4 V"
	TextBox/C/N=text3/F=0/B=1/A=MC/X=-0.58/Y=34.83 "1.1 V"
	TextBox/C/N=text4/F=0/B=1/A=MC/X=-7.60/Y=46.63 "2.4 V"
EndMacro

Window HAMoutofphase() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:packages:KelvinVoltage:
	Display /W=(464.25,67.25,780,260) hamsigall3[0][0][*] vs hamfreq
	AppendToGraph hamsigall3[0][4][*] vs hamfreq
	AppendToGraph hamsigall3[0][5][*] vs hamfreq
	AppendToGraph hamsigall3[0][8][*] vs hamfreq
	SetDataFolder fldrSav0
	ModifyGraph margin(left)=40,margin(bottom)=40,margin(top)=20,margin(right)=20
	ModifyGraph rgb=(0,0,0)
	ModifyGraph tick=2
	ModifyGraph mirror=1
	Label left "\\u#2Out of phase lockin signal (mV)"
	Label bottom "\\u#2 Frequency (kHz)"
	TextBox/C/N=text0/F=0/B=1/A=MC/X=-25.15/Y=37.08 "1.2 V"
	TextBox/C/N=text1/F=0/B=1/A=MC/X=-19.30/Y=-5.06 "-0.2 V"
	TextBox/C/N=text2/F=0/B=1/A=MC/X=40.35/Y=33.71 "-1.5 V"
	TextBox/C/N=text3/F=0/B=1/A=MC/X=23.39/Y=2.81 "0.2V"
EndMacro

Window HAMinphase() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:packages:KelvinVoltage:
	Display /W=(187.5,250.25,503.25,443) hamsigall3[1][0][*] vs hamfreq
	AppendToGraph hamsigall3[1][4][*] vs hamfreq
	AppendToGraph hamsigall3[1][5][*] vs hamfreq
	AppendToGraph hamsigall3[1][8][*] vs hamfreq
	SetDataFolder fldrSav0
	ModifyGraph margin(left)=40,margin(bottom)=40,margin(top)=20,margin(right)=20
	ModifyGraph rgb=(0,0,0)
	ModifyGraph tick=2
	ModifyGraph mirror=1
	ModifyGraph noLabel(bottom)=2
	Label left "\\u#2In phase lockin signal (mV)"
	Label bottom "\\u#2"
	TextBox/C/N=text0/F=0/B=1/A=MC/X=14.04/Y=41.57 "1.2 V"
	TextBox/C/N=text1/F=0/B=1/A=MC/X=4.39/Y=-7.30 "-0.2 V"
	TextBox/C/N=text2/F=0/B=1/A=MC/X=16.37/Y=-39.89 "-1.5 V"
	TextBox/C/N=text3/F=0/B=1/A=MC/X=4.68/Y=17.98 "0.2 V"
EndMacro

Window HAMinphase_smth() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:packages:KelvinVoltage:
	Display /W=(819.75,242.75,1135.5,435.5) hamsigall3_smth[1][0][*] vs hamfreq
	AppendToGraph hamsigall3_smth[1][4][*] vs hamfreq
	AppendToGraph hamsigall3_smth[1][5][*] vs hamfreq
	AppendToGraph hamsigall3_smth[1][6][*] vs hamfreq
	AppendToGraph hamsigall3_smth[1][8][*] vs hamfreq
	SetDataFolder fldrSav0
	ModifyGraph margin(left)=40,margin(bottom)=40,margin(top)=20,margin(right)=20
	ModifyGraph rgb=(0,0,0)
	ModifyGraph tick=2
	ModifyGraph mirror=1
	ModifyGraph noLabel=2
	Label left "\\u#2"
	Label bottom "\\u#2"
	TextBox/C/N=text0/F=0/B=1/A=MC/X=15.50/Y=40.45 "0.4 V"
	TextBox/C/N=text1/F=0/B=1/A=MC/X=3.51/Y=-7.87 "-0.1 V"
	TextBox/C/N=text2/F=0/B=1/A=MC/X=19.88/Y=-37.08 "-0.5 V"
	TextBox/C/N=text3/F=0/B=1/A=MC/X=4.68/Y=20.22 "0.1V"
	TextBox/C/N=text4/F=0/B=1/A=MC/X=4.39/Y=37.64 "0.2 V"
EndMacro

Window HAMoutofphase_smth() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:packages:KelvinVoltage:
	Display /W=(464.25,67.25,780,260) hamsigall3_smth[0][0][*] vs hamfreq
	AppendToGraph hamsigall3_smth[0][4][*] vs hamfreq
	AppendToGraph hamsigall3_smth[0][5][*] vs hamfreq
	AppendToGraph hamsigall3_smth[0][6][*] vs hamfreq
	AppendToGraph hamsigall3_smth[0][8][*] vs hamfreq
	SetDataFolder fldrSav0
	ModifyGraph margin(left)=40,margin(bottom)=40,margin(top)=20,margin(right)=20
	ModifyGraph rgb=(0,0,0)
	ModifyGraph tick=2
	ModifyGraph mirror=1
	Label left "\\u#2Out of phase lockin signal (mV)"
	Label bottom "\\u#2 Frequency (kHz)"
	TextBox/C/N=text0/F=0/B=1/A=MC/X=-41.23/Y=29.78 "0.4 V"
	TextBox/C/N=text1/F=0/B=1/A=MC/X=-19.30/Y=-5.06 "-0.1 V"
	TextBox/C/N=text2/F=0/B=1/A=MC/X=41.81/Y=35.96 "-0.5 V"
	TextBox/C/N=text3/F=0/B=1/A=MC/X=23.39/Y=2.81 "0.1V"
	TextBox/C/N=text4/F=0/B=1/A=MC/X=30.12/Y=-15.17 "0.2 V"
EndMacro

Window VoltageOffsets() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:packages:KelvinVoltage:
	Display /W=(560.25,42.5,834.75,221.75) hamoffsetprelims[5][*] vs hpadjust
	AppendToGraph amliftprelims[5][*] vs alpadjust
	AppendToGraph amopreadjusst[5][*] vs apadjust
	SetDataFolder fldrSav0
	ModifyGraph rgb=(0,0,0)
	ModifyGraph tick=2
	ModifyGraph mirror=1
	Label left "Voltage Offset (V)"
	Label bottom "Relative phase of Lockin Amplifier (°)"
	SetAxis left -2.0000005,1.98
	SetAxis bottom -100,100
	TextBox/C/N=text0/F=0/B=1/A=MC/X=-9.82/Y=30.82 "AM-KPFM lift mode"
	TextBox/C/N=text1/F=0/B=1/A=MC/X=-29.82/Y=-17.61 "Simultaneous\r\\JCAM-KPFM\r\r"
	TextBox/C/N=text2/F=0/B=1/A=MC/X=-29.12/Y=8.18 "HAM-KPFM"
	ShowTools/A
	ModifyGraph margin(left)=40,margin(bottom)=40,margin(top)=20,margin(right)=20
EndMacro

Window HAM_AMdist() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:ForceCurves:SubFolders:X140722:
	Display /W=(560.25,245.75,1120.5,439.25) hampot vs hamdist
	AppendToGraph/R amlpot vs amldist
	SetDataFolder fldrSav0
	ModifyGraph rgb(amlpot)=(0,0,39168)
	ModifyGraph tick=2
	ModifyGraph mirror(bottom)=1
	Label left "HAM-KPFM offset Voltage (V)"
	Label bottom "Distance to closest approach"
	Label right "AM offset voltage (mV)\\u#2"
	SetAxis left -0.3,0.6
	SetAxis bottom 0,1e-07
	SetAxis right 0.0573719,0.064375401
	Cursor/P A amlpot 91849
	ShowTools/A
	SetDrawLayer UserFront
EndMacro

Window Residuals() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:packages:KelvinVoltage:
	Display /W=(560.25,42.5,834.75,221.75)/R HAMresid vs hpadjust
	AppendToGraph/R AMresid vs apadjust
	AppendToGraph/R AMLresid vs alpadjust
	SetDataFolder fldrSav0
	ModifyGraph margin(left)=20,margin(bottom)=40,margin(top)=20,margin(right)=40
	ModifyGraph rgb=(0,0,0)
	ModifyGraph log(right)=1
	ModifyGraph tick=2
	ModifyGraph mirror(right)=1
	Label right "Residual Signal (V)"
	Label bottom "Relative phase of Lockin Amplifier (°)"
	SetAxis bottom -100,100
	TextBox/C/N=text0/F=0/B=1/A=MC/X=-18.12/Y=-2.37 "AM-KPFM lift mode"
	TextBox/C/N=text1/F=0/B=1/A=MC/X=16.38/Y=23.75 "Simultaneous\\JC\rAM-KPFM"
	TextBox/C/N=text2/F=0/B=1/A=MC/X=-2.82/Y=-30.33 "HAM-KPFM"
EndMacro

//Today's new code 9/30/14
//right now, all the code is designed to work with 10 voltages

function setup_HKPFM_datacollect()
	SetDataFolder root:packages:KelvinVoltage
	wave eigenmodes	
	wave bandpass //0: bandpass frequncy
	wave freqparms, eigenmodes, voltageparms
	
	PopupMenu Varying1 win=KPFMVoltageAnalyzer, mode=2
	PopupMenu Varying2 win=KPFMVoltageAnalyzer, mode=1
	PopupMenu Frequency win=KPFMVoltageAnalyzer, mode=2
	PopupMenu KelvinProbeType win=KPFMVoltageAnalyzer, mode=2
	
	freqparms[0] = eigenmodes[1][0] - 4992
	freqparms[1] = eigenmodes[1][0] + 4992
	
	voltageparms[1] = 1
	voltageparms[2] = 10
	
	varprep()
	
end

function gen_practice_data(amp, theta, freq0, q, c)
	variable amp, theta, freq0, q, c
	
	make/n=3000/o freq, data1, data2, denom, mag
	freq = p;
	denom = (freq[p]^2 - freq0^2)^2 + freq[p]^2*freq0^2/q^2
	data1 = amp*((freq[p]^2 - freq0^2)*cos(theta) + freq[p]*freq0/q*sin(theta))/denom[p] + c
	data2 = amp*((freq[p]^2 - freq0^2)*sin(theta) - freq[p]*freq0/q*cos(theta))/denom[p] +c
	mag = sqrt(data1[p]^2 + data2[p]^2)
end

function gen_practice_data2(amp, theta, freq0, qt, c, v0)
	variable amp, theta, freq0, qt, c, v0
	
	make/n=(3000,10)/o data1, data2, denom, mag
	make/n = 3000/o freq, denom
	make/n = 10/o Volt
	freq = p;
	volt = p-5
	denom = (freq[p]^2 - freq0^2)^2 + freq[p]^2*freq0^2/qt^2
	data1 = amp*(volt[q]-v0)*((freq[p]^2 - freq0^2)*cos(theta) + freq[p]*freq0/qt*sin(theta))/denom[p] + c 
	data2 = amp*(volt[q]-v0)*((freq[p]^2 - freq0^2)*sin(theta) - freq[p]*freq0/qt*cos(theta))/denom[p] +c
	mag = sqrt(data1[p]^2 + data2[p]^2)
end

function gen_practice_data3(amp, theta, freq0, qt, c, v0)
	variable amp, theta, freq0, qt, c, v0
	
	make/n=(4992,10)/o data1, data2, denom, mag
	make/n = 4992/o freq, denom
	make/n = 10/o Volt
	freq = p;
	volt = p-5
	denom = (freq[p]^2 - freq0^2)^2 + freq[p]^2*freq0^2/qt^2
	data1 = amp*(volt[q]-v0)*((freq[p]^2 - freq0^2)*cos(theta) + freq[p]*freq0/qt*sin(theta))/denom[p] + c +gnoise(.01)
	data2 = amp*(volt[q]-v0)*((freq[p]^2 - freq0^2)*sin(theta) - freq[p]*freq0/qt*cos(theta))/denom[p] +c +gnoise(.01)
	mag = sqrt(data1[p]^2 + data2[p]^2)
end

function gen_practice_data4(amp, theta, freq0, q, c, sig)
	variable amp, theta, freq0, q, c, sig
	
	make/n=4992/o freq, data1, data2, denom, mag
	freq = p;
	denom = (freq[p]^2 - freq0^2)^2 + freq[p]^2*freq0^2/q^2
	data1 = amp*((freq[p]^2 - freq0^2)*cos(theta) + freq[p]*freq0/q*sin(theta))/denom[p] + c + gnoise(sig)
	data2 = amp*((freq[p]^2 - freq0^2)*sin(theta) - freq[p]*freq0/q*cos(theta))/denom[p] +c + gnoise(sig)
	mag = sqrt(data1[p]^2 + data2[p]^2)
end

function detection_in_noise(amp, theta, freq0, q, c)
	variable amp, theta, freq0, q, c
	
	make/o/n=10 sig
	sig = 2^(-p)
	wave freq, data1
	wave trial1
	variable L = dimsize(trial1, 0)
	make/o/n=(10,L) results
	
	
	variable i = 0
	variable j = 0
	
	for(i=0;i<10;i = i+1)
	trial1[0] = 50000;trial1[1] = 1500;trial1[2] = 100;trial1[3] = .1;trial1[4] = 3.14
	gen_practice_data4(amp, theta, freq0, q, c, sig[i])
	FuncFit/X=1/NTHR=0 oopfit trial1  data1 /X=freq /D 
	
	print trial1
		for(j=0;j<5;j=j+1)
	
			results[i][j]= trial1[j]
	
		endfor
	endfor
	
	
end

function find_c() //seems to work well enough, but should go back and check eventually
	wave all1, frequencies, voltages
	
	make/o/n=(10,40) all_tails
	all_tails[][0,9] = all1[0][p][q]
	all_tails[][10,19] = all1[0][p][4991-q+10]
	all_tails[][20,29] = all1[1][p][q+20]
	all_tails[][30,39] = all1[0][p][4991-q+30]
	
	wavestats all_tails
end

function find_theta(c)
	variable c
	
	wave all1, frequencies
	make/o/n=8 to_sum
	
	//For lowest V: (we assume A < 0)
	to_sum = all1[0][0][2492+p]
	variable oopn = sum(to_sum)/8 - c //out of phase, negative, etc
	to_sum = all1[1][0][2492+p]
	variable ipn = sum(to_sum)/8 - c
	variable thetaprelim = atan(oopn/ipn)
	variable addpi_ipn = (ipn < 0)
	variable estthetan = addpi_ipn*pi+thetaprelim
	print estthetan, addpi_ipn, thetaprelim
	
	//For highest V: (we assume A > 0 ) 
	to_sum = all1[0][9][2492+p]
	variable oopp = sum(to_sum)/8 - c
	to_sum = all1[1][9][2492+p]
	variable ipp = sum(to_sum)/8 - c
	thetaprelim = atan(oopp/ipp)
	variable addpi_ipp = (ipp > 0)
	variable estthetap = addpi_ipp*pi+thetaprelim
	print estthetap, addpi_ipp, thetaprelim
	
	return estthetan/2 + estthetap/2

end

function fitting_extremes(theta, c, f0)
	variable theta, c, f0
	
	wave trial1, all1, frequencies
	make/n=(4,5)/o record //where we will store the data from the fittings
	
	trial1[0] = 5e6; trial1[1] = f0 ;trial1[2] = 500;trial1[3] = c;trial1[4] =theta
	
	//for most negative V:
	make/n=4992/o data1
	data1 = all1[0][0][p]
	FuncFit/X=1/NTHR=0 noopfit trial1  data1 /X=frequencies /D
	trial1[0] = -abs(trial1[0])
	trial1[4] = Mod(trial1[4],2*pi)
	record[0][] = trial1[q]
	
	data1 = all1[1][0][p]
	trial1[0] = 5e6; trial1[1] = f0 ;trial1[2] = 500;trial1[3] = c;trial1[4] =Mod(theta + pi/2,2*pi)
	FuncFit/X=1/NTHR=0 noopfit trial1  data1 /X=frequencies /D 
	trial1[0] = -abs(trial1[0])
	trial1[4] = Mod(trial1[4],2*pi)-pi/2
	record[1][] = trial1[q]
	
	//for most postive V:
	trial1[0] = 5e6; trial1[1] = f0 ;trial1[2] = 500;trial1[3] = c;trial1[4] =theta
	data1 = all1[0][9][p]
	FuncFit/X=1/NTHR=0 oopfit trial1  data1 /X=frequencies /D 
	trial1[0] = abs(trial1[0])
	trial1[4] = Mod(trial1[4],2*pi)
	record[2][] = trial1[q]
	
	trial1[0] = 5e6; trial1[1] = f0 ;trial1[2] = 500;trial1[3] = c;trial1[4] =Mod(theta + pi/2,2*pi)
	data1 = all1[1][9][p]
	FuncFit/X=1/NTHR=0 oopfit trial1  data1 /X=frequencies /D 
	trial1[0] = abs(trial1[0])
	trial1[4] = Mod(trial1[4],2*pi)-pi/2
	record[3][] = trial1[q]
end

function fit_all_separately(all1, frequencies, theta, c, f0)
	wave all1, frequencies
	variable theta, c, f0
	
	wave trial1, W_sigma
	variable leng = dimsize(all1, 2), i=0
	make/n=(20,5)/o record, sigmas //where we will store the data from the fittings
	make/n=20/o noises
	make/n=4950/o lowresid
	make/n=(leng)/o res_data1_fft, res_data1
	trial1[0] = 5e7; trial1[1] = f0 ;trial1[2] = 500;trial1[3] = c;trial1[4] =theta
	wave res_data1
	
	//for most negative V:
	make/n=(leng)/o data1
	for(i=0;i<10;i+=1)
	data1 = all1[0][i][p]
	trial1[2] =600
	trial1[0] = 5e6; trial1[1] = f0 ;trial1[2] = 700;trial1[3] = c;trial1[4] =trial1[4]
	FuncFit/X=1/NTHR=0/Q noopfit trial1  data1 /X=frequencies /D /R=Res_data1 
	FFT/OUT=3/PAD={24992}/WINF=Hanning/DEST=Res_data1_FFT Res_data1
	res_data1_fft /=leng
	lowresid = res_data1_fft[p+49]
	wavestats/q lowresid
	noises[2*i] = V_avg
	trial1[0] = -abs(trial1[0])
	trial1[4] = Mod(trial1[4],2*pi)
	record[2*i][] = trial1[q]
	sigmas[2*i][] = W_sigma[q]
	data1 = all1[1][i][p]
	trial1[0] = 5e6; trial1[1] = f0 ;trial1[2] = 700;trial1[3] = c;trial1[4] =Mod(trial1[4] + pi/2,2*pi)
	FuncFit/X=1/NTHR=0 noopfit trial1  data1 /X=frequencies /D /R=Res_data1 
	FFT/OUT=3/PAD={24992}/WINF=Hanning/DEST=Res_data1_FFT Res_data1
	res_data1_fft /=leng
	lowresid = res_data1_fft[p+49]
	wavestats/q lowresid
	noises[2*i+1] = V_avg
	trial1[0] = -abs(trial1[0])
	trial1[4] = Mod(trial1[4],2*pi)-pi/2
	record[2*i+1][] = trial1[q]
	sigmas[2*i+1][] = W_sigma[q]
	endfor
end


function fitToV()
	wave voltages, record, W_coef, sigmas, noises
	make/n=2/o signal_and_noise
	make/o/n=(20) volts, amps, amps2, amps3, maskwave
	volts = voltages[floor(p/2)]
	amps = record[p][0]
	amps2 = record[p][0]*record[p][2]
	maskwave =abs(record[p][2])>2000
	amps3 = -record[p][0]*abs(record[p][2])/sign(cos(record[p][4]))/record[p][1]^2
	make/n=20/o errors2=sqrt(record[p][2]^2*sigmas[p][0]^2/record[p][1]^4+ record[p][0]^2*sigmas[p][2]^2/record[p][1]^4+ record[p][0]^2*record[p][2]^2*sigmas[p][1]^2/record[p][1]^6)
	CurveFit/X=1/NTHR=0 line amps3 /X=volts /M=amps2 /W=errors2 /I=1 /D 
	signal_and_noise[0] =W_coef[1]
	
	wavestats/q noises
	
	signal_and_noise[1] = v_avg
	
	
	return v_avg
	
end

function dv_one_run( all1_names, frequencies, theta, c, f0 )
	wave/t all1_names
	wave frequencies
	variable  theta, c, f0
	
	variable leng = dimsize(all1_names,0)
	
	variable i = 0
	wave record, noises, signal_and_noise
	
	make/n=(leng,2)/o all_sig_noise
	
	
	for(i=0;i<leng;i+=1)
		print all1_names[i]
		fit_all_separately($(all1_names[i]), frequencies, theta, c, f0)
		fitToV()
		print signal_and_noise
		all_sig_noise[i][0] = signal_and_noise[0]
		all_sig_noise[i][1] = signal_and_noise[1]
	endfor
	
end

function fit_alldata(amp, f0, q, c, theta, v0)
	variable amp, f0, q, c, theta, v0
	
	make/n=6/o vfits = {amp, f0, q, c, theta, v0}
end

Function oopfit(w,freq) : FitFunc
	Wave w
	Variable freq

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(freq) = -A*((f0^2-freq^2) *cos(theta) + freq*f0/abs(q)*sin(theta))/((f0^2-freq^2)^2+(freq*f0/abs(q))^2)+c
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ freq
	//CurveFitDialog/ Coefficients 5
	//CurveFitDialog/ w[0] = A
	//CurveFitDialog/ w[1] = f0
	//CurveFitDialog/ w[2] = q
	//CurveFitDialog/ w[3] = c
	//CurveFitDialog/ w[4] = theta

	return -w[0]*((w[1]^2-freq^2) *cos(w[4]) + freq*w[1]/abs(w[2])*sin(w[4]))/((w[1]^2-freq^2)^2+(freq*w[1]/abs(w[2]))^2)+w[3]
End

Function noopfit(w,freq) : FitFunc
	Wave w
	Variable freq

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(freq) = abs(A)*((f0^2-freq^2) *cos(theta) + freq*f0/abs(q)*sin(theta))/((f0^2-freq^2)^2+(freq*f0/abs(q))^2)+c
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ freq
	//CurveFitDialog/ Coefficients 5
	//CurveFitDialog/ w[0] = A
	//CurveFitDialog/ w[1] = f0
	//CurveFitDialog/ w[2] = q
	//CurveFitDialog/ w[3] = c
	//CurveFitDialog/ w[4] = theta

	return abs(w[0])*((w[1]^2-freq^2) *cos(w[4]) + freq*w[1]/abs(w[2])*sin(w[4]))/((w[1]^2-freq^2)^2+(freq*w[1]/abs(w[2]))^2)+w[3]
End

Function oopfitV(w,freq,v) : FitFunc
	Wave w
	Variable freq
	Variable v

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(freq,v) = abs(A)*(v-v0)*((f0^2-freq^2) *cos(theta) + freq*f0/abs(q)*sin(theta))/((f0^2-freq^2)^2+(freq*f0/abs(q))^2)+c
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 2
	//CurveFitDialog/ freq
	//CurveFitDialog/ v
	//CurveFitDialog/ Coefficients 6
	//CurveFitDialog/ w[0] = A
	//CurveFitDialog/ w[1] = f0
	//CurveFitDialog/ w[2] = q
	//CurveFitDialog/ w[3] = c
	//CurveFitDialog/ w[4] = theta
	//CurveFitDialog/ w[5] = v0

	return abs(w[0])*(v-w[5])*((w[1]^2-freq^2) *cos(w[4]) + freq*w[1]/abs(w[2])*sin(w[4]))/((w[1]^2-freq^2)^2+(freq*w[1]/abs(w[2]))^2)+w[3]
End

function Voltage_jump_measurements()
	wave/t to_measure
	wave countwave
	td_stopinwavebank(-1)
	td_writestring("0%event", "clear")
	
	Variable NPPS = GV("NumPtsPerSec")
	
	Variable Decim = 1 //how many samples go into one datapoint?
	Variable wlength =5e4*countwave[1] - Mod(5e4, 32)
	
	pv("LowNoise",1)
	
	print wlength
	
	make/o/n =(wlength) tm0a, tm0b, tm1a, tm1b, tm2a, tm2b, v_jump
	v_jump[0,floor(wlength/2)] = 0
	v_jump[floor(wlength/2)+1,] = 2
	td_wv("arc.output.b",0)
	
	print td_xsetoutwave (0, "1,0", "Arc.Output.b", v_jump, decim)
	td_xsetinwavepair(0, "1,0", to_measure[0] , tm0a ,to_measure[1], tm0b, "Voltage_jump_callback()",decim)//set up our measurement
	td_xsetinwavepair(1, "1,0", to_measure[2], tm1a , to_measure[3], tm1b, "",decim)
	td_xsetinwavePair(2, "1,0", to_measure[4], tm2a , to_measure[5], tm2b, "",Decim)
	td_writestring("1%event", "once") 
end

function Voltage_jump_callback()
	wave countwave
	Variable wlength =countwave[1]*5e4 - Mod(5e4, 32)
	wave tm0a, tm0b, tm1a, tm1b, tm2a, tm2b, v_jump
	
	make/o/n=(6,wlength) jumpdata

	SetScale/P x 0,2e-05,"s", jumpdata;DelayUpdate
	SetScale d -20,20,"V", jumpdata
	SetScale/P y 0,2e-05,"s", jumpdata

	jumpdata[0][] = tm0a[q]
	jumpdata[1][] = tm0b[q]
	jumpdata[2][] = tm1a[q]
	jumpdata[3][] = tm1b[q]
	jumpdata[4][] = tm2a[q]
	jumpdata[5][] = tm2b[q]

end

//Code for pointmap

function SPV_Set_detection_parameters()
end

function SPV_Start_Function()//For right now, always start from an engaged position with z-feedback running
	SimpleEngageMe("SimpleEngageButton_0")
	
	SetDataFolder root:VoltageFeedback
	VFButtons("SetVLoop")
	VFButtons("StartVLoop")
	Wave vfparms
	SetVFProc("VIGain",VFparms[3][0],"","")
	SetVFProc("VPGain",VFParms[4][0],"","")
	variable points, lines, depth
	//initially, we'll have to put the points and lines in by hand, but in the end we should be able to have it automatic
	
	td_wv("Arc.lockin.0.filter.freq",5000)
	SetDataFolder root:packages:MFP3d:main:variables
	
	Wave ForceVariablesWave
	
	points = ForceVariablesWave[%FMapScanPoints][%value]
	lines = ForceVariablesWave[%FMapScanlines][%value]
	depth = 3
	
	print points, lines
	
	make/o/n=(points, lines, 2*depth) datawave
	
//need to make sure z-loop is on

end

function SPV_Point_function()
	
	
	SetDataFolder root:packages:MFP3d:main:variables
	
	
	td_WriteString("Arc.event.17","Once")
	//"what now"
	 //td_Wv("Arc.events.set",17)
	//sleep 00:00:04
	//print td_WriteString("Arc.event.4","set")
	
	variable sized = 5120 //Can adjust if we need more time, but this is divisible by three, so I'm ok
	make/n=(sized)/o blank1, blank0, v_jump
	v_jump[0,floor(sized/5)-1] = 0
	v_jump[floor(sized/5),3*floor(sized/5)-1] = 1
	v_jump[3*floor(sized/5),] = 5
	td_wv("output.b",0)
	td_xsetoutwave (1, "2,1", "Arc.Output.b", v_jump, 1)
	td_xsetinwavepair(1, "2,1","Arc.pipe.2.Cypher.lvdt.z" , blank0, "Arc.Output.c", blank1, "SPV_Point_callback_function()",1)
	td_writestring("1%event", "once") 
	td_writestring("2%event", "once") 
	//Voltage_jump_measurements2()
	
end

function Voltage_jump_measurements2()
		
	td_stopinwavebank(-1)
	td_writestring("0%event", "clear")
	//td_writestring("1%event", "clear")
	
	Variable NPPS = GV("NumPtsPerSec")
	
	Variable Decim = 1 //how many samples go into one datapoint?
	
	pv("LowNoise",1)
	
	
	variable sized = 4992 //Can adjust if we need more time, but this is divisible by three, so I'm ok
	make/n=(sized)/o blank1, blank0, v_jump
	v_jump[0,floor(sized/3)] = 0
	v_jump[floor(sized/3)+1,] = -2
	td_wv("arc.output.b",0)
	
	td_xsetoutwave (2, "1,0", "Arc.Output.b", v_jump, decim)//The "pointmap" function takes up the wavebank of 0
	td_xsetinwavepair(0, "1,0","Arc.pipe.2.Cypher.lvdt.z" , blank0 ,"Arc.Output.b", blank1, "SPV_Point_callback_function()",decim)//set up our measurement
	td_writestring("1%event", "once") 
end


function SPV_Point_callback_function()
	wave  no, blank1, blank2
	duplicate/o blank1 blank1process
	duplicate/o blank0 blank0process
	wave ForceVariablesWave
	variable i = forcevariableswave[%FMapCounter][%value]-1
	Execute "td_WriteString(\"Arc.event.17\",\"Once\")"
	variable points = forcevariableswave[%FMapScanPoints][%value]
	
	
	
	wave datawave
	variable l = dimsize(blank0process, 0)
	make/n=(l/5)/o b0_a, b0_b,b0_c,b1_a, b1_b,b1_c
	b0_a = blank0process[p]
	b0_b = blank0process[p+2*(l/5)]
	b0_c = blank0process[p+4*(l/5)]
	wavestats/q b0_a
	datawave[Mod(i,points)][(i-Mod(i,points))/points][0] = V_avg
	//print i,Mod(i,points),(i-Mod(i,points))/points
	wavestats/q b0_b
	datawave[Mod(i,points)][(i-Mod(i,points))/points][2] = V_avg //Even - z (or 0), odd - V (or 1)
	wavestats/q b0_c
	datawave[Mod(i,points)][(i-Mod(i,points))/points][4] = V_avg
	b1_a = blank1process[p]
	b1_b = blank1process[p+2*(l/5)]
	b1_c = blank1process[p+4*(l/5)]
	wavestats/q b1_a
	datawave[Mod(i,points)][(i-Mod(i,points))/points][1] = V_avg
	wavestats/q b1_b
	datawave[Mod(i,points)][(i-Mod(i,points))/points][3] = V_avg
	wavestats/q b1_c
	datawave[Mod(i,points)][(i-Mod(i,points))/points][5] = V_avg
	//here we do the processing
	//td_writestring("1%event", "once") 
end

function SPV_Ramp_function()//We don't actually need this
	print td_WriteString("Arc.event.17","Once")
end

function SPV_Stop_function()
end

function SPV_Save_function()
end


function Convert_all1_to_Prelims( all1_saved)
	wave all1_saved
	wave vars
	variable i = 0, imax = 0
	wave/t wnames
	
	variable num_variables = dimsize(all1_saved, 0)
	variable num_voltages = dimsize(all1_saved, 1)
	variable acquisition_length = dimsize(all1_saved,2)
	
	make/n=(num_variables, num_voltages) prelims

	if(vars[1][0]<1)
		for(i=0;i<imax;i+=1)
			wave  prelims, all1
 
			Duplicate/o $(wnames[i]) analyze
			Wavestats/Q analyze
			prelims[i][vars[0][1]] = V_avg
			all1[i][vars[0][1]][] = analyze[r]
		endfor
		
		vars[0][1]+=1
		
		if(vars[0][0] > vars[0][1])
			change1var()
		endif
	else
		for(i=0;i<imax;i+=1)
			wave prelims2nd, all2
			Duplicate/o $(wnames[i]) analyze
			Wavestats/Q analyze
			prelims2nd[i][vars[0][1]][vars[1][1]] = V_avg			
			all2[i][vars[0][1]][vars[1][1]][] = analyze[s]
		endfor
	
		vars[1][1]+=1
		
			
		if(vars[1][0] <= vars[1][1])
			vars[0][1] +=1
			vars[1][1] = 0

			if(vars[0][0] > vars[0][1])
				change1var()
			else	
				SVAR finalcallback
				Execute(finalcallback)
			endif

		
		else
			change2var()
		endif
	endif

	

end

//The following functions are for automating the collection of data through the Kelvin Voltage Analyzer panel
//Multiple tunes can either vary the setpoint of the topographic loop or the lift height (through a force curve)



function multipletunes(str)
	string str
	wave multunes
	
	if(cmpstr(str,"setpoint")==0)
			wave setpoints
			duplicate all2 $("a2_H12_" + num2str(1000*setpoints[multunes[0]])+"mv")
			duplicate prelims2nd $("p2_H12_" + num2str(1000*setpoints[multunes[0]])+"mv")
			multunes[0] = multunes[0]+1
			
			if(multunes[0]<multunes[1])
				MainSetpointSetVarFunc("SetpointSetVar_0",setpoints[multunes[0]],"V","*Amplitude*")
				varprep()
				kv_advance()
			endif
			
	elseif(cmpstr(str,"lift")==0)
		wave lifts
		duplicate/o all2 $("a2_FM2k_16nm_" + num2str(1e9*lifts[multunes[0]])+"nm_lift")
		duplicate/o prelims2nd $("p2_FM2k_16nm_" + num2str(1e9*lifts[multunes[0]])+"nm_lift")
		multunes[0] = multunes[0]+1
		
		if(multunes[0]<multunes[1])
			PV("ForceDist",lifts[multunes[0]])
			ForceDistFunc(lifts[multunes[0]])
			varprep()
			DoForceFunc("SingleForce_2")
		else
			DoScanFunc("Withdraw_2")
			
		endif
	endif


end

function forcedone()
	varprep()
	kv_advance()
end

function start_mult_tunes(str)
	string str
	
	
	if(cmpstr(str,"setpoint")==0)
		wave setpoints
		make/n=2/o multunes={0,dimsize(setpoints,0)}
		MainSetpointSetVarFunc("SetpointSetVar_0",setpoints[multunes[0]],"V","*Amplitude*")
		varprep()
		kv_advance()
	elseif(cmpstr(str,"lift")==0)
		wave lifts
		make/n=2/o multunes={0,dimsize(lifts,0)}
		PV("ForceDist",lifts[multunes[0]])
		ForceDistFunc(lifts[multunes[0]])
		SVAR finalcallback
		finalcallback = "multipletunes(\"lift\")"
		varprep()
		DoForceFunc("SingleForce_2")
		
	endif
end

function start_mult_delta_height_scans()
	wave lifts
	make/n=2/o multscans = {0,dimsize(lifts,0)}
	
	NapSetVarFunc("NapHeightSetVar_0",lifts[0],"","NapHeight")
	DoScanFunc("DoScan_0")

end

function scandone()
	MainSetpointSetVarFunc("SetpointSetVar_0",2.43,"V","*Amplitude*")
	BaseNameSetVarFunc("BaseNameSetVar_0",0,"FM60nm_sp2430","")
	SetVFProc("VIGain",2000,"","")
	SetVFProc("VPGain",.1,"","")
end

function liftscans()
	wave manyscans
	wave gains
	Make/o/n=4 lifts = {5e-09,1e-08,5e-08,1e-07}
	
	if((manyscans[0]+1)<manyscans[1])
		manyscans[0] = manyscans[0]+1
		NapSetVarFunc("NapHeightSetVar_0",lifts[manyscans[0]],num2str(1e9*lifts[manyscans[0]])+" nm","NapVariablesWave[%NapHeight][%Value]")
		BaseNameSetVarFunc("BaseNameSetVar_0",0,"FM40_"+num2str(1e9*lifts[manyscans[0]])+"nm_L","")
		SetVFProc("VIGain",gains[manyscans[0]][0],"","")
		SetVFProc("VPGain",gains[manyscans[0]][1],"","")
		if((manyscans[0]+1)==manyscans[1])
			DoScanFunc("LastScan_0")
		endif
	else
		DoScanFunc("LastScan_0")
	endif
		
end

//Calculation of Minimum Voltage from phase curves
//all2calculation

function From_all2_to_Vm( a2_names, p2_names, volt_names, phase_names, index, bandwidth) //This function is will call the others listed below in order to assure an organized 
	wave/t a2_names, p2_names, volt_names, phase_names
	variable index, bandwidth
	
	variable names_length = dimsize(a2_names,0), W_chisq
	print names_length
	make/n=(names_length)/o Vm, each_noise, each_amp, chisq, Vm_err
	
	variable amplitude
	wave amps_of_phase
	
	variable i = 0
	for(i=0;i<names_length;i = i+1)
		Wave r_and_err, noise, new2
		Calculate_nd( $(a2_names[i]), index)
		duplicate/o new2 $("FFT_of_"+a2_names[i])
		each_noise[i] = noise[0]
		print (p2_names[i]), (phase_names[i]),(volt_names[i])
		calculate_Sv(  $(p2_names[i]),$(phase_names[i]), $(volt_names[i]))
		print r_and_err
		each_amp[i] = r_and_err[0]
	
		Vm[i] = Calculate_Vm( each_noise[i], bandwidth, each_amp[i])
	
		Vm_err[i] = Vm[i]*sqrt((r_and_err[1]/r_and_err[0])^2+(noise[1])^2)
	
	endfor

end


function Calculate_nd( all2, index_number) //We calculate the noise first, in order to better estimate what the noise on each individual point is
	wave all2
	variable index_number
	
	//Define the relevant lengths
	variable Num_index = dimsize(all2,0),Num_volt = dimsize(all2,1), Num_phase = dimsize(all2,2), pointsampled = dimsize(all2,3)
	
	//The way we've been saving data is not good for FFTs--it must be rewritten!
	Wave all2_rearranged_fft
	make/n=(pointsampled, (num_volt*num_phase))/o all2_rearranged
	all2_rearranged[][] = all2[index_number][Mod(q,num_volt)][(q-Mod(q,num_volt))/(num_volt)][p];
	SetScale/I x 0,0.999999999999999,"s", all2_rearranged
	
	FFT/Cols/DEST=all2_rearranged_FFT all2_rearranged
	MatrixOp/o new2 = sumrows(mag(all2_rearranged_fft))
	new2/=(pointsampled*num_phase*num_volt)
	
	make/n=190/o nearlyflat
	nearlyflat = new2[10+p]
	wavestats/q nearlyflat
	
	make/n=2/o noise
	print noise
	noise[0]=V_avg
	noise[1] = V_sdev
	return 0
end

function find_nH( twave )
	wave/t twave
	make/n=(dimsize(twave,0))/o nHs
	
	variable startindex = 0//4+strsearch(note(test36nm0_p2),"nH",0)
	variable i
	string wnote
	
	for(i=0;i<dimsize(twave,0);i=i+1)
		wnote = note($(twave[i]))
		///print wnote
		startindex = 4+strsearch((wnote),"nH",0)
		nHs[i] =  str2num(wnote[startindex, startindex+1])
	endfor
	
	return 0
end

function calculate_amplitude( prelims2, phases, index) //The function that was originally used to calculate the amplitude
	wave prelims2, phases
	variable index
	variable num_voltages = dimsize(prelims2,1), num_phases = dimsize(prelims2, 2) //The number of voltages
	make/n=(num_voltages,4)/o Amps_of_phase
	duplicate/o phases noises
	noises = 1e-4 //Still need to incorporate an honest accounting of the noise
	
	variable i=0
	wave W_coef,W_sigma
	for(i=0;i<num_voltages;i=i+1)
		duplicate/o phases circlex, circley, signals
		circlex=prelims2[0][i][p]
		circley=prelims2[1][i][p]
		//signals =prelims2[index][i][p]
		Duplicate/o circlex, circleYFit, circleXFit
		wavestats/Q circlex
		K0 = -1e-3;K1 = V_max/2;K2 = pi/180;K3 = 1;
		Make/D/O circleCoefs={V_max/4, -1e-6, -1e-6}
		print "here"
		FuncFit/ODR=3/NTHR=0/q/w=2 FitCircle, circleCoefs /X={circleX, circleY}/XD={circleXFit,circleYFit}
		
		//uncomment this and change 
		CurveFit/G/H="0010"/NTHR=0/q/w=2 sin  circlex /X=phases /D
		Amps_of_phase[i][2] = Mod(W_coef[3]+8*pi,2*pi)//pi
		CurveFit/G/H="0010"/NTHR=0/q/w=2 sin  circley /X=phases /D
		
		Amps_of_phase[i][0] = circleCoefs[0] //W_coef[0]
		Amps_of_phase[i][1] = W_sigma[1]
		Amps_of_phase[i][3] = Mod(W_coef[3]+8*pi,2*pi)//pi
	endfor
end

function Calculate_Signalpervolt( amps_of_phase , voltages)//Another function used in the original calculation of Vm, now replaced
	wave amps_of_phase, voltages
	variable Lengt = Dimsize(amps_of_phase,0)
	wave W_coef
	
	Make/o/n=(Lengt) aop2, aop, noises, signs
	
	aop2 = amps_of_phase[p][0]^2
	aop = amps_of_phase[p][0]*sign(1-2*round(abs(Mod(amps_of_phase[Lengt-1][2]+2000*pi,2*pi)-Mod(amps_of_phase[p][2]+2000*pi,2*pi))/pi))
	signs = sign(1-2*round(abs(Mod(amps_of_phase[Lengt-1][2]+2*pi,2*pi)-Mod(amps_of_phase[p][2]+2*pi,2*pi)/pi)))
	noises = amps_of_phase[p][1]
	wavestats/q aop2
	//print dimsize(voltages,0),dimsize(aop,0)
	
	if(dimsize(voltages,0)>5)	
		CurveFit/NTHR=0/q/w=2 line  aop[V_minloc-1,V_minloc+1] /X=voltages /I=1 /D 
	else
		CurveFit/NTHR=0/q/w=2 line  aop /X=voltages /I=1 /D 
	endif
	//print W_coef[1];
	return (W_coef[1])

end

function calculate_Sv( prelims2, phases, voltages) //What is now used to calculate the signal
	wave voltages, phases, prelims2
	variable index
	variable num_voltages = dimsize(voltages,0), num_phases = dimsize(prelims2, 2) //The number of voltages
	make/n=(num_voltages)/o signal
	duplicate/o phases, slopesx, slopesy,slopesxerr,slopesyerr
	//print num_phases
	
	variable i=0
	wave W_coef,W_sigma
	
	for(i=0;i<num_phases;i=i+1)
		signal = prelims2[0][p][i]
		CurveFit/NTHR=0/q/w=2 line  signal /X=voltages /I=1 /D 
		slopesx[i] = W_coef[1]
		slopesxerr[i] =  min(W_sigma[1],1e-5)
		//print W_sigma,W_coef
		signal = prelims2[1][p][i]
		CurveFit/NTHR=0/q/w=2 line  signal /X=voltages /I=1 /D 
		slopesy[i] = W_coef[1]
		slopesyerr[i] =  min(W_sigma[1],5e-5)
		print "print not",slopesxerr[i],slopesyerr[i]
		//print i
	endfor
	
	//Now, we fit to a circle
		duplicate/o phases circlex, circley, signals
		circlex=slopesx[p]
		circley=slopesy[p]
		//signals =prelims2[index][i][p]
		Duplicate/o  circlex, circleYFit, circleXFit
		wavestats/Q circlex
		K0 = -1e-3;K1 = V_max/2;K2 = pi/180;K3 = 1;
		Make/D/O circleCoefs={V_max/4, 1e-5, 1e-5}
		Redimension/D circlex, circley,  circleYFit, circleXFit, slopesxerr, slopesyerr
		//We have to do this to prevent a singular matrix error (ie convert everything to mV instead of V), once about ~ 10 doesn't seem to have an affect other than linear scaling
		variable times=1
		circleCoefs *= times
		slopesxerr *=  times;
		slopesyerr *= times;
		circlex*= times;
		circley*= times;
		string err
		FuncFit/ODR=3/NTHR=0/w=2/q FitCircle, circleCoefs /X={circleX, circleY} /XD={circleXFit,circleYFit} /I=1 /xW={slopesxerr,slopesyerr} //w=2
		W_sigma /= times
		Circlecoefs/= times
		//print W_sigma, Circlecoefs
	
	make/o/n=2 R_and_err = {circleCoefs[0],W_sigma[0]}
	return 0
	
end

function chirality(xpoints, ypoints)
	wave xpoints, ypoints
//FuncFit/ODR=3/NTHR=0/w=2/q FitCircle, circleCoefs /X={xpoints, ypoints} /XD={circleXFit,circleYFit} /I=1 //w=2
end

function to_theta(x,y)
	variable x, y 
	variable r = sqrt(x^2+y^2)
	
	if(x>0)
		return asin(y/r)/pi*180
	elseif(x<=0)
		return (pi-asin(y/r))/pi*180
	endif
end

function Calculate_Vm( noise_density, bandwidth, amplitude)
	variable noise_density, bandwidth,amplitude
	
	variable Vm 
	
	Vm = abs(noise_density*sqrt(bandwidth)/amplitude)
	
	return Vm
end

Function PrintAllWaveNames()
	String objName
	Variable index = 0
	DFREF dfr = GetDataFolderDFR()	// Reference to current data folder
	do
		objName = GetIndexedObjNameDFR(dfr, 1, index)
		print objName
		if (stringmatch(objName, "a2*")||stringmatch(objName, "*a2"))
			Print objName
		endif
		//Print objName
		index += 1
		
		if (strlen(objName) == 0)
			break
		endif
		while(1)
End

Function add_a2_names(a2names)
	wave/t a2names
	String objName
	Variable index = 0, jindex=0, size
	DFREF dfr = GetDataFolderDFR()	// Reference to current data folder
	do
		objName = GetIndexedObjNameDFR(dfr, 1, index)
		if (stringmatch(objName, "*a2"))
			Print objName
			
			size = dimsize(a2names,0)
			if(jindex==size)
				Redimension/N=(size+1) a2names
			endif
			a2names[jindex] = objName
			jindex +=1
			
			
		endif
		//Print objName
		index += 1
		
		if (strlen(objName) == 0)
			break
		endif
		while(1)
End

Function add_p2_names(p2names)
	wave/t p2names
	String objName
	Variable index = 0, jindex=0, size
	DFREF dfr = GetDataFolderDFR()	// Reference to current data folder
	do
		objName = GetIndexedObjNameDFR(dfr, 1, index)
		if (stringmatch(objName, "*p2"))
			Print objName
			
			size = dimsize(p2names,0)
			if(jindex==size)
				Redimension/N=(size+1) p2names
			endif
			p2names[jindex] = objName
			jindex +=1
			
			
		endif
		//Print objName
		index += 1
		
		if (strlen(objName) == 0)
			break
		endif
		while(1)
End

Function FitCircle(w,x,y) : FitFunc
	Wave w
	Variable x
	Variable y

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x,y) = ((x-w_1)/w_0)^2 + ((y-w_2)/w_0)^2 - 1
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 2
	//CurveFitDialog/ x
	//CurveFitDialog/ y
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w[0] = w_0
	//CurveFitDialog/ w[1] = w_1
	//CurveFitDialog/ w[2] = w_2

	return ((x-w[1])/w[0])^2 + ((y-w[2])/w[0])^2 - 1
End


function savedark()
	wave prelims, dark_and_light
	dark_and_light[0] = prelims[5][0]	
end

function savelight()
	wave prelims, dark_and_light
	dark_and_light[1] = prelims[5][0]	
end


function tune_feedback_setpoint()
	nvar tuning_counts
	
	wave setpoints_to_test
	
	setdatafolder root:packages:mfp3d:force
	wave phase1
	duplicate/o phase1 mask
	mask = 0
	mask = abs( phase1[p]-phase1[0]) < 5
	CurveFit/NTHR=0 line,  UserIn1Volts /X=ZSensor /M=mask /D 
	wave W_coef
	setpoints_to_test[tuning_counts][1][0] = W_coef[1]
	tuning_counts = tuning_counts+1
	setdatafolder root:packages:Kelvinvoltage
	td_wv("Arc.PIDS Loop.5.Setpoint", setpoints_to_test[tuning_counts][0][0])
	print tuning_counts
	
	nvar number_o_tunes
	if(tuning_counts < number_o_tunes)
		doforcefunc("SingleForce_2")
	endif
	
end

function finish_illPulse_calibration()
	wave prelims, general1
	variable l = dimsize(prelims,1)
	make/o/n = (l) thetas
	thetas = prelims[3][p]
	
	wavestats/q thetas
	
	
	
	Make/D/O/N=4 New_FitCoefficients2
	New_FitCoefficients2[0] = {-1e-4,2e-3,-pi/180,general1[V_maxloc]/180*pi+pi/2}
	•Make/O/T/N=6 T_Constraints
	T_Constraints[0] = {"K0 > -1","K0 < 1","K1 > 1e-5","K1 < 1"}
	CurveFit/G/H="0010"/NTHR=0/Q sin kwCWave=New_FitCoefficients2,  thetas /X=General1 /D
	variable set_phase = -(Mod(180*(-Mod(New_fitcoefficients2[3],2*pi)/pi +1/2)+180,360)-180)
	//print set_phase 
	td_wv("Arc.lockin.0.phaseoffset",set_phase)
	
	
	setdatafolder root:packages:MFP3D:Hardware
	wave/T hackalias
	Redimension/N=3 HackAlias
	hackalias = {"Arc.pipe.22.cypher.input.a", "Arc.Lockin.0.i","Arc.pipe.23.cypher.input.b"}
	setdimlabel 0,0, 'UserIn0', hackalias
	setdimlabel 0,1, 'UserIn1', hackalias
	setdimlabel 0,2, 'UserIn2', hackalias
	
	AliasButtonFunc("WriteAliasButton_0")
	
	print "liaARC done"
end

function finish_LIAA_calibration()
	wave prelims, general1
	variable l = dimsize(prelims,1)
	make/o/n = (l) thetas
	thetas = prelims[0][p]
	
	wavestats/q thetas
	
	
	
	Make/D/O/N=4 New_FitCoefficients2
	New_FitCoefficients2[0] = {-1e-4,2e-3,-pi/180,general1[V_maxloc]/180*pi+pi/2}
	//Make/O/T/N=6 T_Constraints
	//T_Constraints[0] = {"K0 > -1","K0 < 1","K1 > 1e-5","K1 < 1","K3 > -11"}
	//Print T_Constraints
	CurveFit/G/H="0010"/NTHR=0/Q sin kwCWave=New_FitCoefficients2,  thetas /X=General1 /D 
	variable set_phase = -(Mod(180*(-Mod(New_fitcoefficients2[3],2*pi)/pi +1/2)+180,360)-180)
	//print set_phase 
	td_wv("Cypher.lockina.0.phaseoffset",set_phase)
	
	SVAR finalcallback
	finalcallback =""
	
	setup_user_variables()
	
	print "Liaa done"
	

end

function finish_LIAB1_calibration() 

	wave prelims, general1
	variable l = dimsize(prelims,1)
	make/o/n = (l) thetas
	thetas = prelims[2][p]
	
	wavestats/q thetas
	
	
	
	Make/D/O/N=4 New_FitCoefficients2
	New_FitCoefficients2[0] = {-1e-4,2e-3,-pi/180,general1[V_maxloc]/180*pi+pi/2}
	CurveFit/G/H="0010"/NTHR=0 sin kwCWave=New_FitCoefficients2,  thetas /X=General1 /D 
	variable set_phase = -(Mod(180*(-Mod(New_fitcoefficients2[3],2*pi)/pi +1/2)+180,360)-180)
	//print set_phase 
	td_wv("Cypher.lockinb.1.phaseoffset",set_phase)
	
	setdatafolder root:packages:MFP3D:main:variables:
	wave mastervariableswave
	mastervariableswave[%phaseoffset1][%value] = set_phase
	SetDataFolder root:packages:KelvinVoltage
	print "LIAB1 done"
end

function update_setpoint()
	td_wv("Arc.PIDS Loop.3.setpoint",3e-4)
end

Window Operate_KPFMs() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(2560,94,3028,430)
	ShowTools/A
	ShowInfo/W=Operate_KPFMs
	SetDrawLayer UserBack
	DrawText 135,18,"FM-KPFM"
	DrawText 298,16,"H-KPFM"
	DrawText 148,162,"PVFM"
	SetVariable ftop,pos={2,6},size={100,20},title="f\\BT",format="%.3W1PHz"
	SetVariable ftop,limits={-inf,inf,0},value= root:packages:MFP3D:Main:Variables:MasterVariablesWave[%DriveFrequency][%Value],noedit= 1
	SetVariable fA,pos={116,20},size={90,20},title="f\\BA",format="%.3W1PHz"
	SetVariable fA,limits={-inf,inf,10},value= root:packages:KelvinVoltage:KPFM_parameters[0]
	PopupMenu FMChoose_sideband,pos={127,47},size={70,22},title="F\\BD"
	PopupMenu FMChoose_sideband,mode=2,popvalue="ft-fa",value= #"\"ft+fa;ft-fa\""
	Button Set_Frequencies,pos={148,306},size={150,20},proc=KPFMButtonProc,title="Set frequencies"
	Button Set_Frequencies,fColor=(0,52224,0)
	SetVariable fD,pos={273,14},size={90,20},title="f\\BD",format="%.3W1PHz"
	SetVariable fD,limits={-inf,inf,10},value= root:packages:KelvinVoltage:KPFM_parameters[2]
	Button Calibrate_2f_phase,pos={100,121},size={150,20},proc=KPFMButtonProc,title="Calibrate 2f phase (FM, PVFM)"
	Button Calibrate_2f_phase,fColor=(52224,52224,52224)
	Button calibrate_LIAAphase,pos={168,100},size={200,20},proc=KPFMButtonProc,title="Calibrate Lockin A Phase (engage first)"
	Button calibrate_LIAAphase,fColor=(65535,65535,65535),valueColor=(39168,0,0)
	SetVariable fi,pos={116,170},size={90,20},title="f\\Bi",format="%.3W1PHz"
	SetVariable fi,limits={-inf,inf,10},value= root:packages:KelvinVoltage:KPFM_parameters[1]
	PopupMenu HChoose_sideband,pos={287,33},size={73,22},bodyWidth=60,title="f\\BA"
	PopupMenu HChoose_sideband,mode=1,popvalue="fT+fD",value= #"\"fT+fD;|fT-fD|\" "
	Button Crosspoint_KPFM,pos={167,77},size={150,20},proc=KPFMButtonProc,title="Set H/FM-KPFM crosspoint"
	Button Crosspoint_KPFM,fColor=(52224,52224,52224)
	Button Crosspoint_PVFM,pos={84,229},size={150,20},proc=KPFMButtonProc,title="SET PVFM crosspoint"
	Button Crosspoint_PVFM,fColor=(52224,52224,52224)
	SetVariable bpfreq2,pos={83,193},size={155,16},bodyWidth=60,title="PVFM Counter bias"
	SetVariable bpfreq2,format="%.3W1PV"
	SetVariable bpfreq2,limits={-inf,inf,0.1},value= root:packages:KelvinVoltage:KPFM_parameters[4]
	SetVariable bpfreq3,pos={9,69},size={111,20},bodyWidth=80,title="Vac",fSize=14
	SetVariable bpfreq3,format="%.3W1PV",fStyle=1,fColor=(52224,0,0)
	SetVariable bpfreq3,limits={-inf,inf,0.1},value= root:packages:KelvinVoltage:KPFM_parameters[3],styledText= 1
	PopupMenu NapModePopup_0,pos={269,167},size={169,22},bodyWidth=110,proc=NapPopupFunc,title="Nap Mode"
	PopupMenu NapModePopup_0,help={"Sets the manner of the interleaved scanning"}
	PopupMenu NapModePopup_0,font="Arial",fSize=12
	PopupMenu NapModePopup_0,mode=2,popvalue="Nap",value= #"\"Off;Nap;Parm Swap;Snap;\""
	PopupMenu Choose_mode,pos={304,138},size={101,22},title="Mode"
	PopupMenu Choose_mode,mode=3,popvalue="H-KPFM",value= #"\"FM-KPFM;PVFM;H-KPFM\""
	SetVariable Lockin_0_Filter_Freq,pos={293,210},size={153,18},bodyWidth=100,proc=FilterSetVarFunc,title="Lockin 0 "
	SetVariable Lockin_0_Filter_Freq,help={"The filter on the first frequency AC component of the Fast ADC in the controller."}
	SetVariable Lockin_0_Filter_Freq,font="Arial",fSize=12,format="%.3W1PHz"
	SetVariable Lockin_0_Filter_Freq,fStyle=0
	SetVariable Lockin_0_Filter_Freq,limits={-inf,inf,100},value= root:packages:MFP3D:Main:Variables:FilterVariablesWave[%'Lockin.0.Filter.Freq'][%Value]
	SetVariable Cypher_LockinA_0_Filter_Freq8,pos={244,232},size={202,18},bodyWidth=100,proc=FilterSetVarFunc,title="Cypher LockinA 0 "
	SetVariable Cypher_LockinA_0_Filter_Freq8,help={"The filter on the first frequency AC component of the Fast A ADC in the Cypher."}
	SetVariable Cypher_LockinA_0_Filter_Freq8,font="Arial",fSize=12
	SetVariable Cypher_LockinA_0_Filter_Freq8,format="%.3W1PHz",fStyle=0
	SetVariable Cypher_LockinA_0_Filter_Freq8,limits={-inf,inf,1000},value= root:packages:MFP3D:Main:Variables:FilterVariablesWave[%'Cypher.LockinA.0.Filter.Freq'][%Value]
	SetVariable Cypher_LockinB_1_Filter_Freq,pos={243,254},size={203,18},bodyWidth=100,proc=FilterSetVarFunc,title="Cypher LockinB 1 "
	SetVariable Cypher_LockinB_1_Filter_Freq,help={"The filter on the second frequency AC component of the Fast B ADC in the Cypher."}
	SetVariable Cypher_LockinB_1_Filter_Freq,font="Arial",fSize=12,format="%.3W1PHz"
	SetVariable Cypher_LockinB_1_Filter_Freq,fStyle=0
	SetVariable Cypher_LockinB_1_Filter_Freq,limits={-inf,inf,1000},value= root:packages:MFP3D:Main:Variables:FilterVariablesWave[%'Cypher.LockinB.1.Filter.Freq'][%Value]
	CheckBox ForceFilterBox,pos={265,281},size={170,15},proc=FilterBoxFunc,title="Always Use Standby Values"
	CheckBox ForceFilterBox,help={"When this is checked the filters are not changed from the default values."}
	CheckBox ForceFilterBox,font="Arial",fSize=12,value= 0
	CheckBox Tuning,pos={74,104},size={81,14},title="Tuning/no lift",value= 1
	SetVariable bpfreq4,pos={103,211},size={134,16},bodyWidth=60,title="illPulse voltage"
	SetVariable bpfreq4,format="%.3W1PV"
	SetVariable bpfreq4,limits={-inf,inf,0.1},value= root:packages:KelvinVoltage:KPFM_parameters[5]
	Button Calibrate_illpulse_phase,pos={86,273},size={150,20},proc=KPFMButtonProc,title="Calibrate illPulse phase"
	Button Calibrate_illpulse_phase,fColor=(52224,52224,52224)
	Button Tune_Feedback_Setpoint,pos={0,142},size={130,20},proc=KPFMButtonProc,title="Tune Feedback Setpoint"
	Button Tune_Feedback_Setpoint,fColor=(52224,52224,52224)
	Button Calibrate_illuminated,pos={175,250},size={59,19},proc=KPFMButtonProc,title="Cal. ill."
	Button Calibrate_illuminated,fColor=(65280,65280,0)
	Button calibrate_dark,pos={85,251},size={58,18},proc=KPFMButtonProc,title="Cal. Dark"
	Button calibrate_dark,fColor=(4352,4352,4352)
	CheckBox use2f,pos={227,55},size={180,14},title="Use 2f signal/relative capacitance"
	CheckBox use2f,value= 0
	PopupMenu nH_parameter,pos={374,29},size={57,22},title="nH:"
	PopupMenu nH_parameter,mode=7,popvalue="6",value= #"\"0;1;2;3;4;5;6;7;8;9;10\""
	SetVariable Openloopplus,pos={359,72},size={98,16},title="OL+"
	SetVariable Openloopplus,limits={-inf,inf,0},value= root:packages:KelvinVoltage:openloop_options[0],noedit= 1
	SetVariable Openloopminus,pos={361,92},size={96,16},title="OL-"
	SetVariable Openloopminus,limits={-inf,inf,0},value= root:packages:KelvinVoltage:openloop_options[1],noedit= 1
	PopupMenu Choose_2f,pos={337,113},size={85,22},title="Choose 2f"
	PopupMenu Choose_2f,mode=3,popvalue="-",value= #"\"None;+;-\""
EndMacro

function calibrateLIAA_phase( callback )
	string callback
	PopupMenu Varying1 win=KPFMVoltageanalyzer, mode=6
	PopupMenu Varying2 win=KPFMVoltageanalyzer, mode=1
	wave generalparms
	wave/t outputs
	outputs[0] = "cypher.lockina.0.phaseoffset"
	generalparms[0] = -180
	generalparms[1] = 180
	generalparms[2] = 20
	checkbox  exponential Win=KPFMVoltageanalyzer, value=0
	wave/t to_measure
	to_measure[0] = "Arc.pipe.23.cypher.input.b"
	varprep()
	controlinfo/W=Operate_KPFMs use2f
	if(V_Value)
		td_wv("Output.c",0)
	else
		td_wv("Output.c",3)
	endif
		//td_wv("Output.c",3)
	td_wv("Cypher.lockina.dcoffset",0)
	kv_advance()
	SVAR finalcallback	
	finalcallback = callback
	
end

		

Function KPFMButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	SetDataFolder root:packages:KelvinVoltage
	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			//print ba.Ctrlname
			strswitch( ba.ctrlname )
//				case "read_f0":
				//	SetDataFolder root:packages:MFP3D:main:variables:
				//	wave thermalvariableswave
				//	variable f = thermalvariableswave[%thermalfrequency][%value]
				//	variable q =  thermalvariableswave[%thermalQ][%value]
//
//					SetDataFolder root:packages:KelvinVoltage
//					wave eigenmodes
//					eigenmodes[0][0] = f
//					eigenmodes[0][1] = q
//				break
				
//				case "read_f1":
//				SetDataFolder root:packages:MFP3D:main:variables:
//					wave thermalvariableswave
//					f = thermalvariableswave[%thermalfrequency][%value]
//					q =  thermalvariableswave[%thermalQ][%value]
//					
//					print f
//					SetDataFolder root:packages:KelvinVoltage
//					wave eigenmodes
//					eigenmodes[1][0] = f
//					eigenmodes[1][1] = q
//				break
				
//				case "read_f2":
//				SetDataFolder root:packages:MFP3D:main:variables:
//					wave thermalvariableswave
//					f = thermalvariableswave[%thermalfrequency][%value]
//					
//					print f
//					SetDataFolder root:packages:KelvinVoltage
//					wave eigenmodes
//					eigenmodes[2][0] = f
//					eigenmodes[2][1] = 2
//				break
				
//				case "Calcbandpass":
//					
//					SetDataFolder root:packages:MFP3D:main:variables:
//					wave MasterVariablesWave
//					variable ftopography = mastervariableswave[%DriveFrequency][%Value]
//					print ftopography
//					SetDataFolder root:packages:KelvinVoltage
//					wave eigenmodes, bandpass
//					
//					bandpass[0] =   ftopography+eigenmodes[1][0] //later on I want more options: and I also want to account for df
//					
//				break
				
				case "Set_Frequencies":
				
					 set_frequencies() //It's easier just to lop this function on in here
				break
				
				case "Crosspoint_PVFM":
				
				Wave KPFM_parameters
				
				td_wv("Output.C",KPFM_Parameters[4])
				td_wv("Output.B",KPFM_parameters[5])
				td_wv("Arc.lockin.0.amp",1)
				
				XPTPopupFunc("BNCOut0Popup",13, "PogoIn1") 
				XPTPopupFunc("BNCOut1Popup",16, "DDS") 
				XPTPopupFunc("BNCOut2Popup",2, "OutB") 
				XPTPopupFunc("ShakePopup",6, "BNCIn0") 
				XPTPopupFunc("CypherBNCOut0Popup",27, "M2-M3") 
				XPTPopupFunc("CypherContPogoIn1Popup",33,"DDSB") 
				XPTPopupFunc("CypherMath2Popup",21,"ContShake") 
				XPTPopupFunc("CypherMath3Popup",1,"OutA") 
				XPTBoxFunc("XPTLock10Box_0",1)
				XPTBoxFunc("XPTLock11Box_0",1)
				XPTBoxFunc("XPTLock12Box_0",1)
				XPTBoxFunc("CypherXPTLock17Box_0",1)
				
				case "crosspoint_KPFM":
				Wave KPFM_parameters
				td_wv("Cypher.lockina.1.amp",KPFM_Parameters[3])
				td_wv("Cypher.lockina.0.amp",0)
				
				XPTBoxFunc("PogoOutBox",1)
				XPTBoxFunc("ChipBox",1)
				
				SetDataTypePopupFunc("Channel1DataTypePopup_1",0,"amplitude1")
				SetDataTypePopupFunc("Channel2DataTypePopup_2",0,"amplitude2")
				SetDataTypePopupFunc("Channel5DataTypePopup_5",0,"userin1")
				SetDataTypePopupFunc("Channel6DataTypePopup_6",0,"userin2")
				
				controlinfo/W=Operate_KPFMs tuning
				if(V_Value ==1)
					XPTPopupFunc("PogoOutPopup",3,"OutC") 
					XPTPopupFunc("ChipPopup", 12, "PogoIn0")
					 ShowWhatPopupFunc("Channel2CapturePopup_2",4,"")	
					 ShowWhatPopupFunc("Channel5CapturePopup_5",4,"")	
					 ShowWhatPopupFunc("Channel6CapturePopup_6",4,"")	
				else
					XPTPopupFunc("PogoOutPopup",10,"Ground") 
					XPTPopupFunc("ChipPopup", 10, "Ground")
					ShowWhatPopupFunc("NapChannel2CapturePopup_2",4,"")	
					ShowWhatPopupFunc("NapChannel5CapturePopup_5",4,"")	
					ShowWhatPopupFunc("NapChannel6CapturePopup_6",4,"")	
				endif
				
				XPTPopupFunc("CypherContPogoIn0Popup",32,"DDSA") 
				XPTPopupFunc("CypherMath0Popup",19,"ContPogoOut") 
				XPTPopupFunc("CypherMath1Popup",20,"ContChip") 
				XPTPopupFunc("PogoOutSwapPopup",3,"OutC") 
				XPTPopupFunc("ChipSwapPopup", 12, "PogoIn0")
				XPTPopupFunc("CypherSamplePopup",18,"Ground") 
				XPTPopupFunc("CypherHolderOut0Popup",27,"M0+M1") 
				XPTPopupFunc("CypherInFastBPopup",6,"ACDefl")
				XPTPopupFunc("CypherInFastAPopup",5,"Defl")
				XPTPopupFunc("InFastPopup",4,"Defl") 
				
				XPTButtonFunc("WriteXPT")
				ARCheckFunc("DontChangeXPTCheck",1)
				
				XPTBoxFunc("CypherXPTLock3Box_0",1)
				XPTBoxFunc("CypherXPTLock4Box_0",1)
				XPTBoxFunc("CypherXPTLock16Box_0",1)
				XPTBoxFunc("CypherXPTLock22Box_0",1)
				XPTBoxFunc("CypherXPTLock23Box_0",1)
				XPTBoxFunc("CypherXPTLock28Box_0",1)
				XPTBoxFunc("CypherXPTLock29Box_0",1)
				
				XPTBoxFunc("XPTLock13Box_0",1)
				XPTBoxFunc("XPTLock14Box_0",1)

				
				break
				
				case "calibrate_LIAAphase":
					PopupMenu Varying1 win=KPFMVoltageanalyzer, mode=6
					PopupMenu Varying2 win=KPFMVoltageanalyzer, mode=1
					wave generalparms
					wave/t outputs
					outputs[0] = "cypher.lockina.0.phaseoffset"
					generalparms[0] = -180
					generalparms[1] = 180
					generalparms[2] = 20
					checkbox  exponential Win=KPFMVoltageanalyzer, value=0
					wave/t to_measure
					to_measure[0] = "Arc.pipe.23.cypher.input.b"
					varprep()
					controlinfo/W=Operate_KPFMs use2f
					if(V_Value)
						td_wv("Output.c",0)
					else
						td_wv("Output.c",3)
					endif
					//td_wv("Output.c",3)
					td_wv("Cypher.lockina.dcoffset",0)
					kv_advance()
					SVAR finalcallback
					finalcallback = "finish_LIAA_calibration()"
					
					
					
				break
				
				case "Calibrate_2f_phase":
					PopupMenu Varying1 win=KPFMVoltageanalyzer, mode=6
					wave generalparms
					wave/t outputs
					outputs[0] = "cypher.lockinb.1.phaseoffset"
					generalparms[0] = -180
					generalparms[1] = 180
					generalparms[2] = 20
					checkbox  exponential Win=KPFMVoltageanalyzer, value=0
					wave/t to_measure
					to_measure[2] = "Arc.pipe.20.cypher.lockinb.1.r" // this is actually the i component due to earlier changes
					varprep()
					kv_advance()
					SVAR finalcallback
					finalcallback = "finish_LIAB1_calibration()"
				break
				
				case "Tune_Feedback_Setpoint":
					variable/G number_o_tunes = 3
					make/n=(number_o_tunes,2,1)/o setpoints_to_test 
					setpoints_to_test[][0][0] = {4e-4,0,-4e-4}
					variable/G tuning_counts =0
					
					
					ForceSetVarFunc("ForceDistSetVar_2",100e-9,"1 nm","")
					ForceSetVarFunc("ForceScanRateSetVar_2",.1,".1hz","")
					 VFButtons("SetVLoop")
					 VFButtons("StartVLoop")
					 td_wv("Arc.PIDS Loop.5.Setpoint", setpoints_to_test[0][0][0])
					 setdatafolder root:voltagefeedback; 
					 wave VFparms
					 SetVFProc("VIGain",vfparms[3][0],"","")
					 SetVFProc("VpGain",vfparms[4][0],"","")
					
					 ARCheckFunc("ARUserCallbackMasterCheck_1",1)
					 ARCheckFunc("ARUserCallbackForceDoneCheck_1",1)
					 BaseNameSetVarFunc("BaseNameSetVar_2",0,"tuning","")
					 setdatafolder  root:packages:Mfp3d:main:variables:
					wave/t generalvariablesdescription
					generalvariablesdescription[%ARUserCallbackForceDone][%description] = "tune_feedback_setpoint()"
					ARCallbackSetVarFunc("ARUserCallbackForceDoneSetVar_1",0,"tune_feedback_setpoint()","ok")
					 wave mastervariableswave
					 SetDataFolder root:packages:KelvinVoltage
					 string/g force_name = "tuning" + num2str(mastervariableswave[%basesuffix][%value])
					 ForceChannelBoxFunc("UserIn1SaveBox_0",1)
					 doforcefunc("SingleForce_2")
					
				break
				
				case "calibrate_dark":
					make/n=2/o dark_and_light
					popupmenu Varying1 popmatch = "General", Win=KPFMVoltageAnalyzer
					wave/t outputs
					outputs[0] = ""
					wave generalparms
					generalparms[0] = 0
					generalparms[1] = 1
					generalparms[2] = 1
					wave/t to_measure
					to_measure[5] = "Arc.Output.C"
					varprep()
					kv_advance()
					svar finalcallback 
					finalcallback = "savedark()"
				break
				
				case "Calibrate_illuminated":
					make/n=2/o dark_and_light
					popupmenu Varying1 popmatch = "General", Win=KPFMVoltageAnalyzer
					wave/t outputs
					outputs[0] = ""
					wave generalparms
					generalparms[0] = 0
					generalparms[1] = 1
					generalparms[2] = 1
					wave/t to_measure
					to_measure[5] = "Arc.Output.C"
					varprep()
					kv_advance()
					svar finalcallback 
					finalcallback = "savelight()"
				break
				
				case "Calibrate_illpulse_phase":
					wave dark_and_light
					popupmenu Varying1 popmatch = "General", Win=KPFMVoltageAnalyzer
					
					VFButtons("SetVLoop")
					if(dark_and_light[0] < dark_and_light[1])
						td_wv("output.c",2)
					else
						td_wv("output.c",-4)
					endif
					
					PopupMenu Varying1 win=KPFMVoltageanalyzer, mode=6
					wave generalparms
					wave/t outputs
					outputs[0] = "Arc.lockin.0.phaseoffset"
					generalparms[0] = -180
					generalparms[1] = 180
					generalparms[2] = 20
					checkbox  exponential Win=KPFMVoltageanalyzer, value=0
					wave/t to_measure
					to_measure[3] = "Arc.lockin.0.i" 
					varprep()
					kv_advance()
					SVAR finalcallback
					finalcallback = "finish_illPulse_calibration()"
				
				default:
				
				break
			
			endswitch
			
			break
		case -1: // control being killed
			break
	endswitch

	setup_user_variables()

	return 0
End

function dim_settern( textwave, dim, to_label ) // writing many 'setdimlabel's by hand takes forever. This will speed it up. 
	wave/t textwave
	wave to_label
	variable dim
	
	variable L = dimsize(textwave, 0), i
	variable L2 = dimsize(to_label,dim)
	variable Max_i = min(L, L2)
	
	for(i=0;i<Max_i;i=i+1)
		setdimlabel dim, i, $(textwave[i]), to_label
	endfor


end

function dim_settert( textwave, dim, to_label ) // writing many 'setdimlabel's by hand takes forever. This will speed it up. 
	wave/t textwave
	wave/t to_label
	variable dim
	
	variable L = dimsize(textwave, 0), i
	variable L2 = dimsize(to_label,dim)
	variable Max_i = min(L, L2)
	
	for(i=0;i<Max_i;i=i+1)
		setdimlabel dim, i, $(textwave[i]), to_label
		print textwave[i]
	endfor

	print "now"

end


Function SetVarProc_2(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.ctrlname
				strswitch(sval)
					case "V_Igain_tab2":
						td_wv("Arc.PIDSloop.5.Igain",dval)
					break
					case "V_Pgain_tab2":
						td_wv("Arc.PIDSloop.5.Pgain",dval)
					break
					case "D_Igain_tab2":
						td_wv("Arc.PIDSloop.0.Igain",dval)
					break
					case "D_Pgain_tab2":
						td_wv("Arc.PIDSloop.0.Pgain",dval)
					break
					case "AMampset_tab2":
						td_wv("Arc.PIDSloop.0.Setpoint",dval)
					break
					case "VAC_amp":
						//setamp()
					break
				endswitch
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function setamp()
	wave kpfm_parameters
	td_wv("Cypher.lockin.1.amp", kpfm_parameters[3])
	setup_user_variables()
end

function setup_user_variables()
	setdatafolder root:packages:KelvinVoltage
	wave kpfm_parameters
	setdatafolder root:packages:MFP3D:Main:Variables:
	wave uservariableswave
	wave/t uservariablesdescription
	
	Redimension/N=(8,-1) UserVariablesDescription
	Redimension/N=(8,-1) UserVariablesWave
	
	setdimlabel 0, 0, VAC ,UserVariablesDescription
	setdimlabel 0, 0, VAC ,UserVariablesWave
	UserVariablesdescription[0] = "AppliedVoltage"
	UserVariableswave[0][%value] = kpfm_parameters[3]
	//setdatafolder root:packages:KelvinVoltage
	
	setdimlabel 0, 1, H_freq ,UserVariablesDescription
	setdimlabel 0, 1, H_freq ,UserVariablesWave
	UserVariablesdescription[1] = "Heterodyning Frequency"
	UserVariableswave[1][%value] = kpfm_parameters[2]
	//setdatafolder root:packages:KelvinVoltage
	
	setdimlabel 0, 2, f_A ,UserVariablesDescription
	setdimlabel 0, 2, f_A ,UserVariablesWave
	UserVariablesdescription[2] = "Frequency applied"
	UserVariableswave[2][%value] = td_rv("cypher.lockina.1.freq")
	
	setdimlabel 0, 3, nH ,UserVariablesDescription
	setdimlabel 0, 3, nH ,UserVariablesWave
	UserVariablesdescription[3] = "Heterodyne number"
	controlinfo/w=operate_kpfms nH_parameter
	UserVariableswave[3][%value] = str2num(s_value)
	
	setdimlabel 0, 4, FM_freq ,UserVariablesDescription
	setdimlabel 0, 4, FM_freq ,UserVariablesWave
	UserVariablesdescription[4] = "FM Frequency"
	UserVariableswave[4][%value] = kpfm_parameters[0]
	//setdatafolder root:packages:KelvinVoltage
	
	setdimlabel 0, 5, MethodUsed ,UserVariablesDescription
	setdimlabel 0, 5, MethodUsed ,UserVariablesWave
	UserVariablesdescription[5] = "FM-1,PV-2,H-3"
	controlinfo/w=Operate_KPFMs Choose_mode
	UserVariableswave[5][%value] = V_Value
	//setdatafolder root:packages:KelvinVoltage
	
	setdimlabel 0, 6, Igain ,UserVariablesDescription
	setdimlabel 0, 6, Igain ,UserVariablesWave
	UserVariablesdescription[6] = "Igain (unitless)"
	UserVariableswave[6][%value] = td_rv("Arc.PIDS Loop.5.Igain")
	//setdatafolder root:packages:KelvinVoltage
	
	setdimlabel 0, 7, MethodUsed ,UserVariablesDescription
	setdimlabel 0, 7, MethodUsed ,UserVariablesWave
	UserVariablesdescription[7] = "Pgain (unitless)"
	UserVariableswave[7][%value] = td_rv("Arc.PIDS Loop.5.Igain")
	setdatafolder root:packages:KelvinVoltage
end

//Earlier iterations of the KPFM frequency setter have been deterministic, which was reasonable because the frequencies being set were fairly simple. 
//However, now that we are including the 'n' different modes of H-KPFM, this becomes somewhat more complicated

function choose_frequencies()
	variable V_value
	variable epsilon
				controlinfo/W=Operate_KPFMs Choose_mode
				variable mode = v_value
				
				SetDataFolder root:packages:KelvinVoltage
				wave KPFM_parameters, openloop_options
				
				if((mode == 1)||(mode==2))
					controlinfo/W=Operate_KPFMs FMchoose_sideband
					make/o/n=2 epsilon_wave
					if(V_Value == 1)
						print td_wv("Cypher.lockina.1.freq", KPFM_parameters[0])			
						variable dw =  td_rv("cypher.lockinb.0.freq")+td_rv("Cypher.lockina.1.freq")
						td_wv("Cypher.lockina.0.freq",dw)
						epsilon_wave[0] = td_rv("Cypher.lockina.0.freq")-dw
						variable dw2 = 2 * td_rv("Cypher.lockina.1.freq") + td_rv("cypher.lockinb.0.freq") 
						
						epsilon_wave[1] = td_rv("Cypher.lockinb.1.freq")-dw2
					else
						print td_wv("Cypher.lockina.1.freq", KPFM_parameters[0])			
						dw =  td_rv("cypher.lockinb.0.freq")-td_rv("Cypher.lockina.1.freq")
						td_wv("Cypher.lockina.0.freq",dw)
						dw2 = -2 * td_rv("Cypher.lockina.1.freq") + td_rv("cypher.lockinb.0.freq") 
						
					endif
					//print dw2
					td_wv("Cypher.lockinb.1.freq",dw2)
					epsilon_wave = {abs(td_rv("Cypher.lockina.0.freq")-dw),abs( td_rv("Cypher.lockinb.1.freq")-dw2)}
					
					setdatafolder root:packages:MFP3D:main:variables
				
					wave mastervariableswave
					mastervariableswave[%drivefrequency1][%value] = dw2
					mastervariableswave[%driveamplitude1][%value] = 0
				
					td_wv("Cypher.lockina.0.notch.freq",KPFM_parameters[0])
					td_wv("Cypher.lockina.0.notch.bandwidth", 40)
					if(mode == 2)
						td_wv("Arc.lockin.0.freq", (-1)^(1+V_Value)*KPFM_parameters[1] + td_rv("cypher.lockinb.0.freq"))
						td_wv("Arc.lockin.0.filter.notch", KPFM_parameters[1])
					endif
					
					epsilon = sum(epsilon_wave)
				elseif( mode == 3)
					controlinfo/W=Operate_KPFMs Hchoose_sideband
					variable sidebands = V_Value
					controlinfo/w=Operate_KPFMs nH_parameter
					variable nH = str2num(s_value)
					variable fa
					make/n=2/o epsilon_wave
					
					if(sidebands==1)
							//td_wv("Cypher.lockina.0.freq", KPFM_parameters[2])			
							fa =  nH*td_rv("cypher.lockinb.0.freq")+ KPFM_parameters[2]
							print fa
							//td_wv("Cypher.lockina.1.freq",dw)
					elseif(sidebands ==2)
							//td_wv("Cypher.lockina.0.freq", KPFM_parameters[2])			
							fa =  nH*td_rv("cypher.lockinb.0.freq")-KPFM_parameters[2]
							variable siggn = fa/(abs(fa))
							fa = abs(fa)
							print fa, siggn
							//td_wv("Cypher.lockina.1.freq",dw)
					endif
					controlinfo/W=Operate_KPFMs use2f
					
					variable fd 
					
					if(V_value)
						fa /=2
						td_wv("Cypher.lockina.1.freq",fa)
						openloop_options = NaN
						if(sidebands==2)
							fd = nH*td_rv("cypher.lockinb.0.freq") + 2*td_rv("Cypher.lockina.1.freq")
						elseif(sidebands==1)
							fd = abs(nH*td_rv("cypher.lockinb.0.freq") - 2*td_rv("Cypher.lockina.1.freq"))
						endif
						
					else
						td_wv("Cypher.lockina.1.freq",abs(fa))
						openloop_options[0] = 2*td_rv("Cypher.lockina.1.freq")+nH*td_rv("cypher.lockinb.0.freq")
						openloop_options[1] = 2*td_rv("Cypher.lockina.1.freq")-nH*td_rv("cypher.lockinb.0.freq")
						if(sidebands==2)
							fd = nH*td_rv("cypher.lockinb.0.freq") - siggn*td_rv("Cypher.lockina.1.freq")
						elseif(sidebands==1)
							fd = abs(nH*td_rv("cypher.lockinb.0.freq") -td_rv("Cypher.lockina.1.freq"))
						endif
						controlinfo/w=MasterPanel DualACModeBox_3
						variable dualAC=V_value
						controlinfo/w=Operate_KPFMs choose_2f
						print "2f", v_value, "DualAC", dualAC, (!V_value)&&dualAC
						if((V_value>1)&&dualAC)
							setdatafolder root:packages:MFP3D:main:variables
							print "inside"
							wave mastervariableswave
							if(V_Value == 2)
								//mastervariableswave[%drivefrequency1][%value] =  2*td_rv("Cypher.lockina.1.freq")+nH*td_rv("cypher.lockinb.0.freq")
								td_wv("Cypher.lockinb.1.freq", ( 2*td_rv("Cypher.lockina.1.freq")+nH*td_rv("cypher.lockinb.0.freq")))
								epsilon_wave[1] = td_rv("Cypher.lockinb.1.freq")- ( 2*td_rv("Cypher.lockina.1.freq")+nH*td_rv("cypher.lockinb.0.freq"))
							else
								//mastervariableswave[%drivefrequency1][%value] =  2*td_rv("Cypher.lockina.1.freq")-nH*td_rv("cypher.lockinb.0.freq")
								td_wv("Cypher.lockinb.1.freq", ( 2*td_rv("Cypher.lockina.1.freq")-+nH*td_rv("cypher.lockinb.0.freq")))
								epsilon_wave[1] = td_rv("Cypher.lockinb.1.freq")-( 2*td_rv("Cypher.lockina.1.freq")-nH*td_rv("cypher.lockinb.0.freq"))
							endif 
							print  2*td_rv("Cypher.lockina.1.freq")+nH*td_rv("cypher.lockinb.0.freq"),td_rv("Cypher.lockinb.1.freq")
							mastervariableswave[%driveamplitude1][%value] = 0
							//dw2 = td_rv("Cypher.lockinb.1.freq")
						else
							epsilon_wave[1] = 0
						endif
						
						
						
					endif
						td_wv("Cypher.lockina.0.freq",fd)
						epsilon_wave[0] = td_rv("Cypher.lockina.0.freq") - fd
						epsilon_wave = abs(epsilon_wave[p])
						//td_wv("Cypher.lockina.1.freq",fa)
						//print fa
						epsilon = sum(epsilon_wave)
					
					
					//td_wv("Cypher.lockina.0.freq",fd)
					print fa,fd
				endif
				
				SetDataFolder root:packages:KelvinVoltage
				
				//For the final safety check -- should eventuallly be moved 
				NapCheckBoxFunc("NapDriveAmplitudeBox_0",0)
				NapCheckBoxFunc("NapDriveFrequencyBox_0",0)
				NapCheckBoxFunc("NapPhaseOffsetBox_0",0)
				NapCheckBoxFunc("NapTipVoltageBox_0",0)
				NapCheckBoxFunc("NapSurfaceVoltageBox_0",0)
				NapCheckBoxFunc("NapUser0VoltageBox_0",0)
				NapCheckBoxFunc("NapUser1VoltageBox_0",0)
				print "epsilon:", epsilon_wave
				return epsilon
end

function set_fa()

end

function add_wavestats2prelimwavenote()
	wave prelims
	wave general1
	string add_2_wavenote =""
	
	Note/k prelims,  ("f_A: " +num2str( td_rv("Cypher.lockina.1.freq"))+ " Hz")
	Note prelims,  ("f_D: " +num2str( td_rv("Cypher.lockina.0.freq"))+ " Hz")
	Note prelims,  ("f_T: " +num2str( td_rv("Cypher.lockinb.0.freq"))+ " Hz")
	Note prelims,  ("V_AC: " +num2str( td_rv("Cypher.lockina.1.amp"))+ " V")
	
	controlinfo/w=Operate_KPFMs nH_parameter
	variable nH = v_value
	Note prelims,  ("nH: " +s_value)
	
	controlinfo/w=Operate_KPFMs HChoose_sideband
	Note prelims,  ("f_A option: " + s_value)
	
	SetScale/P y -180,(general1[1]-general1[0]),"degrees", prelims
end

function add_params_2all_prelims()
	wave prelims2nd
	wave all2, countwave
	wave general1, voltages
	string add_2_wavenote =""
	
	Note/k prelims2nd,  ("f_A: " +num2istr( td_rv("Cypher.lockina.1.freq"))+ " Hz")
	Note prelims2nd,  ("f_D: " +num2istr( td_rv("Cypher.lockina.0.freq"))+ " Hz")
	Note prelims2nd,  ("f_T: " +num2istr( td_rv("Cypher.lockinb.0.freq"))+ " Hz")
	Note prelims2nd,  ("V_AC: " +num2istr( td_rv("Cypher.lockina.1.amp"))+ " V")
	
	controlinfo/w=Operate_KPFMs nH_parameter
	//variable nH = v_value
	Note prelims2nd,  ("nH: " +s_value)
	
	controlinfo/w=Operate_KPFMs HChoose_sideband
	Note prelims2nd,  ("f_A option: " + s_value)
	note/k all2, note(prelims2nd)
	
	//had recorded y, z wrong on some data from 7/21
	SetScale/P z -180,(general1[1]-general1[0]),"degrees", prelims2nd
	SetScale/P y voltages[0],(voltages[1]-voltages[0]),"V", prelims2nd
	SetScale/P z -180,(general1[1]-general1[0]),"degrees", all2
	SetScale/P y voltages[0],(voltages[1]-voltages[0]),"V", all2
	SetScale/I t 0,countwave[1],"s", all2
end

//We have some code that was written earlier to enable doing multiple tunes or scans
//The intention here is to make the code more 'modifiable' so that we can run multiple settings with the same code
//I would like this code to work for both the spatial scans and the sensitivity calibrations
//For that the code will be setup in three parts
//prep_runs() will generate run_info wave which will include the names of the data, the code to run for each data point: to set the parameters, to run the measurement, and any callback
//prep_runs() will also generate and zero and iterator for the measurement, to keep track of where we are in the run_info wave




function prep_runs( callback )//This code will actually need to be manually edited each time a different set of measurements are to be taken 
	string callback
	make/o/n=1 giter = 0
	variable num_params = 5
	variable num_runs = 7
	
	make/o/t/n=(num_params, num_runs) run_info
	make/o/t/n=(num_params) param_labels
	param_labels = {"name", "setting_parameters","prepping_command", "running_command", "saving_command"}
	make/o/t/n=(num_runs) run_labels
	
	dim_settert( param_labels, 0, run_info )
	dim_settert( run_labels, 1, run_info )
	
	variable i=0
	for(i=0;i<num_params;i=i+1)
		run_info[%$(param_labels[i])][]=run_genfunc(q, param_labels[i])
	endfor
	
	setup_phasesweep( 20 )
	setup_voltagesweep()
	
	execute(callback)
	
	return 0

end

//the name, naming_command, prepping_command, prepping_callback, setting_parameters, running_command, callback, and saving_command must all be explicitly stated in a way that they will run when executed
//in Python, these could all be a class that acts on external data, but here, we'll actually have to hard-code the procedures each time. Still, I think that this gives us the most flexibility available in Igor
function/s run_genfunc(iter, name)
	variable iter
	string name
	
	string/G gstring = ""
	execute("gstring = gen2_" +name +"("+num2istr(iter) +")") //get rid of the '2' to go back to sensitivity measurements
	
	return gstring

end

function/s gen2_name( iter )
	variable iter
	string name = "bigscan36nm"
	//name += num2istr(iter)

	return name
end

function/s gen2_setting_parameters( iter )
	variable iter
	string setting_parameters=  ""// "print "  + num2istr(iter) + ";"
	setting_parameters += "PopupMenu nH_parameter mode=" +num2istr(mod(iter,7)+1)+", win=Operate_KPFMs;"
	setting_parameters += "PopupMenu HChoose_sideband mode=" +num2istr(ceil(iter/7+0.01))+", win=Operate_KPFMs;"
	setting_parameters += "set_frequencies();"
	setting_parameters += "execute(run_info[%prepping_command]["+num2istr(iter)+"]);"
	return setting_parameters
end

function/s gen2_prepping_command( iter )
	variable iter
	string prepping_command= ""
	prepping_command += "SimpleEngageMe(\"SimpleEngageButton_0\");"
	prepping_command += "varprep();"
	prepping_command += "root:voltagefeedback:vfparms[3][0] = " + num2str(6000+5000*mod(iter,7)^2)+"; root:voltagefeedback:vfparms[4][0] = " + num2istr(20+50*mod(iter,7)^2) +";"//set feedback
	prepping_command+= "Set_Voltage_Feedback();"
	prepping_command += "calibrateLIAA_phase( \"finish_LIAA_calibration();execute(run_info[%running_command]["+num2istr(iter)+"])\");"
	//prepping_command += "print \"prepping_command\";"
	//prepping_command += "execute(run_info[%running_command]["+num2istr(iter)+"])"
	return prepping_command
end

function/s gen2_running_command( iter )
	variable iter
	string running_command= ""
	running_command +="StartVLoop();" // turn on feedback
	//running_command +="SimpleEngageMe(\"SimpleEngageButton_0\");"//	string running_subcommand = ""
	running_command += "DoScanFunc(\"DoScan_0\");"
	running_command += "DoScanFunc(\"LastScan_0\");"
	running_command += "BaseNameSetVarFunc(\"BaseNameSetVar_0\",0, run_info[%name]["+num2istr(iter)+"],\"\");"
	//this set of running commands is just to show that the measurement is working
	//running_command += "print_v_value( \"nH_parameter\");"
	//running_command += "print_v_value( \"HChoose_sideband\");"
	//running_command += "print \"running command\";"
	//running_command += "print \"running_command\";"
	//running_command += "start_KV_set_callback(\"execute(run_info[%saving_command]["+num2istr(iter)+"])\" );"
	
	//running_command += "execute(run_info[%saving_command]["+num2istr(iter)+"])"
	
	return running_command
end

function/s gen2_saving_command( iter )
	variable iter
	string saving_command= ""
	//saving_command +=  "print \"saving_command\";"
	//saving_command += "add_params_2all_prelims();"
	//saving_command += "execute(\"saveall2prelims( run_info[%name]["+num2istr(iter)+"] )\");"
	//saving_command += "KVcallback_off(  );"
	saving_command += "execute(\"next_run()\")"
	return saving_command
end

function/s gen_name( iter )
	variable iter
	string name = "test12nmp40"
	name += num2istr(iter)

	return name
end

function/s gen_naming_command( iter )
	variable iter
	string naming_command= ""

	return naming_command
end

function/s gen_prepping_command( iter )
	variable iter
	string prepping_command= ""
	prepping_command += "varprep();"
	prepping_command += "print \"prepping_command\";"
	prepping_command += "execute(run_info[%running_command]["+num2istr(iter)+"])"
	return prepping_command
end

function/s gen_prepping_callback( iter )
	variable iter
	string prepping_callback= ""

	return prepping_callback
end

function/s gen_setting_parameters( iter )
	variable iter
	string setting_parameters=  ""// "print "  + num2istr(iter) + ";"
	setting_parameters += "PopupMenu nH_parameter mode=" +num2istr(mod(iter,7)+1)+", win=Operate_KPFMs;"
	setting_parameters += "PopupMenu HChoose_sideband mode=" +num2istr(ceil(iter/7+0.01))+", win=Operate_KPFMs;"
	setting_parameters += "set_frequencies();"
	setting_parameters += "execute(run_info[%prepping_command]["+num2istr(iter)+"]);"
	return setting_parameters
end

function/s gen_running_command( iter )
	variable iter
	string running_command= ""
	//string running_subcommand = ""
	//this set of running commands is just to show that the measurement is working
	//running_command += "print_v_value( \"nH_parameter\");"
	//running_command += "print_v_value( \"HChoose_sideband\");"
	//running_command += "print \"running command\";"
	running_command += "print \"running_command\";"
	running_command += "start_KV_set_callback(\"execute(run_info[%saving_command]["+num2istr(iter)+"])\" );"
	
	//running_command += "execute(run_info[%saving_command]["+num2istr(iter)+"])"
	
	return running_command
end

function/s gen_callback( iter )
	variable iter
	string prepping_callback= ""

	return prepping_callback
end

function/s gen_saving_command( iter )
	variable iter
	string saving_command= ""
	saving_command +=  "print \"saving_command\";"
	saving_command += "add_params_2all_prelims();"
	saving_command += "execute(\"saveall2prelims( run_info[%name]["+num2istr(iter)+"] )\");"
	saving_command += "KVcallback_off(  );"
	saving_command += "execute(\"next_run()\")"
	return saving_command
end

//here are a few functions that I found necessary because I coded this measurement in what has turned out to be a very odd manner

function saving_function()
	wave giter
	wave/t run_info
	execute(run_info[%saving_command][giter[0]])
end

function saveall2prelims( name )
	string name
	wave all2, prelims2nd
	
	duplicate all2 $(name +"_a2")
	duplicate prelims2nd $(name+ "_p2")
	return 0
	
end

function set_frequencies()
	SetDataFolder root:packages:KelvinVoltage
	variable eps
	variable breakout = 500
	variable N=0
	wave kpfm_parameters
					
	do
		eps = choose_frequencies()
		if(eps>0)
			//If the chosen frequencies are incompatible with the DDS, then we choose new frequencies
			//we don't worry about whether we are using FM of H-KPFM
			//Because we want to keep the topography loop constant, we vary the detection frequency
			kpfm_parameters[0] += 1
			kpfm_parameters[2] += 1
		endif
		N += 1
	while((eps>0)&&(N<breakout))
end

function print_v_value( name_of_menu_item)
	string name_of_menu_item
	controlinfo/w=Operate_KPFMs $name_of_menu_item
	print (name_of_menu_item+": "),v_value
	return v_value
end

function start_runs()
	wave/t run_info
	SetDataFolder root:packages:KelvinVoltage
	prep_runs( "execute(run_info[%setting_parameters][0])" )
end

function next_run()
	wave giter
	wave/t run_info
	giter += 1
	variable flag = (giter[0]<dimsize(run_info,1))
	print "flag:", flag
	
	if(flag)
		execute(run_info[%setting_parameters][giter[0]])
	else
		//uncomment these if you want this to be the last scan
		//TuneBoxFunc("PiezoDriveBox_3",1)
		//td_ws("Arc.LaserRelay","Open")
	endif
	//flag = (giter[0]<dimsize(run_info,1))
	//print "flag:", flag
	//print giter[0], dimsize(run_info,1)
	//giter += 1
	//flag = (giter[0]<dimsize(run_info,1))
	//print "flag:", flag
	return 0
end

function setup_phasesweep( num_pts )
	variable num_pts
	SetDataFolder root:packages:KelvinVoltage
	PopupMenu Varying1 win=KPFMVoltageanalyzer, mode=2
	wave generalparms
	wave/t outputs
	outputs[1] = "cypher.lockina.0.phaseoffset"
	generalparms[3] = -180
	generalparms[4] = 180
	generalparms[5] = ceil(num_pts)
	checkbox  exponential Win=KPFMVoltageanalyzer, value=0
	wave/t to_measure
	to_measure[0] = "Arc.pipe.23.cypher.input.b"
	to_measure[1] = "Arc.pipe.22.cypher.input.a"
	//varprep()
	//controlinfo/W=Operate_KPFMs use2f
	//if(V_Value)
	//	td_wv("Output.c",0)
	//else
	//	td_wv("Output.c",3)
	//endif
	//td_wv("Output.c",3)
	//td_wv("Cypher.lockina.dcoffset",0)
	//kv_advance()
	//SVAR finalcallback
	//finalcallback = "finish_LIAA_calibration()"
end

function setup_voltagesweep()
	SetDataFolder root:packages:KelvinVoltage
	PopupMenu Varying2 win=KPFMVoltageanalyzer, mode=7 //this gives voltage
	PopupMenu KelvinProbeType win=KPFMVoltageanalyzer, mode=2
	wave voltageparms
	voltageparms[0] = 0
	voltageparms[1] = 3
	voltageparms[2]=  5
end

function start_KV_set_callback( callback )
	string callback
	kv_advance()
	SVAR finalcallback
	finalcallback = callback
	print finalcallback
end

function KVcallback_off(  )
	SVAR finalcallback
	finalcallback = ""
end