//Oddity Function
//script Ver 2


set exalt to 50.7. //ship radar
set ldlim to 3. //touchdown speed
lock truealt to alt:radar - exalt.
local meco to false.
local boostbackturn to true.
set fairingjet to false.
set boostertank to ship:partstagged("BoosterTank")[0].
for res in boostertank:resources {
    if res:name = "LIQUIDFUEL" {
        set boosteramount to res.
        break.
    }
}

function startup {
    set ship:name to missionname.
    set runmode to 1.
    set role to core:part:getmodule("kOSProcessor"):tag.

    set terminal:width to 37.
    set terminal:height to 9.
    clearscreen.
    core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
    print "----------------------------------" at (2, 3).
    print "__________________________________" at (2, 8).

    if role = "orbit" {
        print "MISSION NAME: " + missionname at (2, 1).
        print "Press 1 to launch" at (3, 5).
        set rec to processor("Booster").
        set mecofuel to boosterfuel() * 0.4.
    }

    if role = "booster" {
        print "MISSION NAME: " + "Oddity Booster" at (2, 1).
        print "STANDBY" at (3, 5).

        set boostbackyaw to pidloop(0.7, 0.7, 10, -10, 10).
        set entryyaw to pidloop(13, 7, 175, -60, 60).
        set entrypitch to pidloop(13, 7, 175, -60, 60).
        set glidyaw to pidloop(25, 10, 5000, -90, 90).
        set glidpitch to pidloop(25, 10, 5000, -90, 90).
        set landyaw to pidloop(63, 57, 3000, -45, 45).
        set landpitch to pidloop(63, 57, 3000, -45, 45).
        set landth to pidloop(0.05, 0.1, 0.006, 0, 1).

        set boostbackyaw:setpoint to 0.
        set entryyaw:setpoint to 0.
        set entrypitch:setpoint to 0.
        set glidyaw:setpoint to 0.
        set glidpitch:setpoint to 0.
        set landyaw:setpoint to 0.
        set landpitch:setpoint to 0.
    }
}

function thrott {
    if role = "orbit" {
        if runmode = 1 {
            if countdowntime < 1 {
                return 1.
            }
            else {
                return 0.
            }
        }
        else if runmode = 2 {
            if meco = false {
                return ascentth.
            }
            else {
                return 0.
            }
        }
        else if runmode = 3 {
            if sestime < sessiontime {
                return 1.
            }
            else {
                return 0.5.
            }
        }
        else if runmode = 4 {
            return 0.
        }
    }

    else if role = "booster" {
        if runmode = 2 {
            if boostbackturn = true {
                return 0.
            }
            else {
                if errordiff() < 30000 {
                    return errordiff() / 30000.
                }
                else {
                    return 1.
                }
            }
        }
        else if runmode = 3 {
            if ship:altitude < 50000 {
                return entryth.
            }
        }
        else if runmode = 4 {
            return 0.
        }
        else if runmode = 5 {
            if landthpid() < - ldlim {
                set landth:setpoint to landthpid().
            }
            else {
                set landth:setpoint to - ldlim.
            }

            return landth:update(time:seconds, ship:verticalspeed).
        }
        else if runmode = 6 {
            return 0.
        }
    }
}

function steer {
    if role = "orbit" {
        if runmode = 1 {
            return heading(90, 90, 0).
        }
        if runmode = 2 {
            if ship:airspeed > 100 {
                if meco = false {
                    if pitchangle() > 10 {
                       return heading(90, 90 - (ship:apoapsis / 1000), 0).
                    }
                    else {
                        return heading(90, 10, 0).
                    }
                }
                else {
                    return mecosteer.
                }
            }
            else {
                return heading(90, 90, 0).
            }
        }
        else if runmode = 3 {
            if pitchangle() > 10 {
                return heading(90, 90 - (ship:apoapsis / 1000), 0).
            }
            else {
                return heading(90, 10, 0).
            }
        }
        else if runmode = 4 {
            return ship:srfprograde.
        }
    }

    else if role = "booster" {
        if runmode = 1 {
            return mecosteer.
        }
        else if runmode = 2 {
            if boostbackturn = true {
                if pitchangle() > 150 {
                    set boostbackturn to false.
                }
                if pitchangle() + 10 < 150 {
                    return heading(90, pitchangle() + 10, 0).
                }
                else {
                    return heading(90, 150, 0).
                }
            }
            else {
                return heading(90, 150, 0) - boostbackpid().
            }
        }
        else if runmode = 3 {
            if ship:altitude < 50000 {
                return heading(90, 87, 0) - entrypid().
            }
            else if ship:altitude < 70000 {
                return heading(90, 87, 0).
            }
            else {
                return heading(90, 90, 0).
            }
        }
        else if runmode = 4 {
            return ship:srfretrograde + glidpid().
        }
        else if runmode = 5 {
            if truealt > 500 {
                return ship:srfretrograde - landpid().
            }
            else {
                if truealt > 50 and ship:groundspeed > 0.1 {
                    set steeringmanager:maxstoppingtime to 0.5.
                    return ship:srfretrograde.
                }
                else {
                    return heading(90,90,0).
                }
            }
        }
    }
}

function pitchangle {
    return 90 - arctan2(vdot(vcrs(ship:up:vector, ship:north:vector), facing:forevector), vdot(ship:up:vector, facing:forevector)).
}

function impactpoint {
    if addons:tr:hasimpact {
        return addons:tr:impactpos.
    }
    else {
        return ship:geoposition.
    }
}

function lngerror {
    return impactpoint():lng - LZ:lng.
}

function laterror {
    return impactpoint():lat - LZ:lat.
}

function errorvector {
    return impactpoint():position - LZ:position.
}

function errordiff {
    return sqrt((errorvector():x) ^ 2 + (errorvector():z) ^ 2).
}

function boostbackpid {
    return r(boostbackyaw:update(time:seconds, laterror()), 0, 0).
}

function entrypid {
    return r(entryyaw:update(time:seconds, laterror()), entrypitch:update(time:seconds, lngerror()), 0).
}

function glidpid {
    return r(glidyaw:update(time:seconds, laterror()), glidpitch:update(time:seconds, lngerror()), 0).
}

function landpid {
    return r(landyaw:update(time:seconds, laterror()), landpitch:update(time:seconds, lngerror()), 0).
}

function landthpid {
    if truealt < 0 {
        return 0.
    }
    else {
        return - ((abs(truealt) ) / (sqrt(abs(ship:verticalspeed)))).
    }
}

function acc {
    return ship:maxthrust / ship:mass.
}

function boosterfuel {
    return boosteramount:amount.
}

function fairing {
    for decoupler in ship:partstagged("fairing") {
        decoupler:getmodule("proceduralfairingdecoupler"):doevent("jettison fairing").
    }
}

function screen {
    print "MISSION NAME: " + missionname at (2, 1).
    print "----------------------------------" at (2, 3).
    print "RUNMODE: "at (3, 4).
    print "MISSION TIME: " at (3, 5).
    print "SPEED: " at (3, 6).
    print "ALTITUDE: " at (3, 7).
    print "__________________________________" at (2, 8).
}

function shiptime {
    if runmode = 1 {
        set cdhour to floor(countdowntime / 3600).
            if cdhour < 10 {
                set print_cdhour to "0" + cdhour.
            }
            else {
                set print_cdhour to cdhour.
            }
        set cdminute to floor((countdowntime - cdhour * 3600) / 60).
            if cdminute < 10 {
                set print_cdminute to "0" + cdminute.
            }
            else {
                set print_cdminute to cdminute.
            }
        set cdsecond to floor(countdowntime - (cdhour * 3600 + cdminute * 60)).
            if cdsecond < 10 {
                set print_cdsecond to "0" + cdsecond.
            }
            else {
               set print_cdsecond to cdsecond.
            }
        return "T- " + print_cdhour + ":" + print_cdminute + ":" + print_cdsecond.
    }

    else if runmode > 1 {
        set ship_missiontime to sessiontime - nowtime.
        set hour to floor(ship_missiontime / 3600).
        if hour < 10 {
                set print_hour to "0" + hour.
            }
        else {
            set print_hour to hour.
        }
        set minute to floor((ship_missiontime - hour * 3600) / 60).
        if minute < 10 {
            set print_minute to "0" + minute.
        }
        else {
            set print_minute to minute.
        }
        set second to floor(ship_missiontime - (hour * 3600 + minute * 60)).
        if second < 10 {
            set print_second to "0" + second.
        }
        else {
            set print_second to second.
        }
        return "T+ " + print_hour + ":"+ print_minute + ":" + print_second.
    }
}

function shipspeed {
    return round(ship:airspeed * 3.6).
}

function shipaltitude {
    if ship:altitude / 1000 >= 100 {
        return floor(ship:altitude / 1000).
    }
    else {
        set ship_altitude to floor(ship:altitude / 1000, 1).
        set few to (ship_altitude - floor(ship:altitude / 1000)).
        if few = 0 {
            return ship_altitude + ".0".
        }
        else {
            return ship_altitude.
        }
    }
}

function shiprunmode {
    if role = "orbit" {
        if runmode = 1 {
            return "1: COUNTDOWN".
        }
        else if runmode = 2 {
            return "2: ASCENT   ".
        }
        else if runmode = 3 {
            return "3: ORBIT".
        }
    }

    else if role = "booster" {
        if runmode = 1 {
            return "1: BOOST BACK".
        }
        else if runmode = 2 {
            return "1: BOOST BACK".
        }
        else if runmode = 3 {
            return "2: ENTRY     ".
        }
        else if runmode = 4 {
            return "3: GLIDING".
        }
        else if runmode = 5 {
            return "4: LANDING".
        }
        else if runmode = 6 {
            return "5: TOUCH DOWN".
        }
    }
}