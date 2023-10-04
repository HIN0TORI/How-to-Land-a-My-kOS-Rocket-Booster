//Oddity
//script Ver 2


//user setting
set missionname to "Oddity Test Flight". //mission name
set tgalt to 150000. //target altitude
set countdowntime to 0. //countdown time
//set LZ to latlng(-0.117877, -74.548558). //LZ1
//set LZ to latlng(-0.097208, -59.999999). //DroneShip1
set LZ to latlng(-0.117876, -73.999997). //DroneShip2

//file loading
runoncepath("0:/Oddity_Function_Ver2.ks").


//main script
lock truealt to alt:radar - exalt.
stage.
startup().

if role = "orbit" {
    wait until ag1.
    lock throttle to thrott().
    lock steering to steer().
    screen().

    until runmode = 0 {
        print shiptime() + "     " at (17, 5).
        print shipspeed() + " (km/h)     " at (17, 6).
        print shipaltitude() + " (km)     " at (17, 7).
        print shiprunmode() at (17, 4).

        if runmode = 1 { //countdown
            if countdowntime = 0 {
                stage.
                set nowtime to sessiontime.
                set ascentth to (17.9 / acc()).
                set runmode to 2.
                set steeringmanager:rollts to 50.
            }
            else {
                set countdowntime to countdowntime - 1.
                wait 1.
            }
        }
        else if runmode = 2 { //ascent
            if boosterfuel() < mecofuel {
                set meco to true.
                set sestime to sessiontime + 2.
                set mecosteer to ship:facing.
                rec:connection:sendmessage(nowtime).
                stage.
                rcs on.
                set runmode to 3.
            }
        }
        else if runmode = 3 { //orbit
            if ship:apoapsis > tgalt {
                set runmode to 4.
            }
        }
        else if runmode = 4 {
        }

        if ship:altitude > 50000 and fairingjet = false {
            fairing().
            set fairingjet to true.
        }
    }
}

else if role = "booster" {
    wait until not core:messages:empty.
    set nowtime to core:messages:pop:content.
    set bestime to sessiontime + 3.
    set steeringmanager:rollts to 50.
    lock throttle to thrott().
    lock steering to steer().
    set mecosteer to ship:facing.
    screen().

    until runmode = 0 {
        print shiptime() + "     " at (17, 5).
        print shipspeed() + " (km/h)     " at (17, 6).
        print shipaltitude() + " (km)     " at (17, 7).
        print shiprunmode() at (17, 4).

        if runmode = 1 { //boost back
            if bestime < sessiontime {
                brakes on.
                set ship:name to "Odditly Booster".
                set runmode to 2.
                //set steeringmanager:rollts to 50.
                //lock throttle to thrott().
                //lock steering to steer().
            }
        }
        else if runmode = 2 { //boostback
            if errordiff() < 50 {
                set entryth to (55.2 / acc()).
                set runmode to 3.
            }
        }
        else if runmode = 3 { //entry
            if ship:altitude < 50000 and ship:verticalspeed > -300 {
                ag2 on.
                set runmode to 4.
            }
        }
        else if runmode = 4 { //gliding
            if ship:altitude < 30000 and rcs {
                rcs off.
            }
            if alt:radar < 4000 {
                set runmode to 5.
            }
        }
        else if runmode = 5 { //landing
            if not gear and truealt < 100 {
                gear on.
            }
            if ship:verticalspeed > - 300 and throttle < 0.35 {
                ag3 on.
            }
            if ship:status = "landed" or ship:status = "splashed" {
                set runmode to 6.
            }
        }
        else if runmode = 6 { //touch down
            unlock steering.
        }
    }
}