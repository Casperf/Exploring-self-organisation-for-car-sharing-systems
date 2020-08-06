breed [companies company ]
breed [cars car]
breed [users user]

globals [
  market-price
  user-distance
  total-rules-violated
  number-of-sanctions
  bottom-price

]

patches-own [
  empty
]

turtles-own [
  company-id
]

companies-own [
  profit
  company-price
  satisfied-users
  unsatisfied-users
  rules-violated
  company-rules-violated
  company-sanctioned
  vote
  total
  costs
  no-parking
]

cars-own [
  available
  parked
]

users-own [
  walking
  driving
  origin-list
  destination
  direction
  reserved-car
  user-price
]

;; Setting up the model.

to setup
  clear-all
  ; random-seed 100 ;; For testing the model.
  setup-parking-spots
  setup-companies
  setup-cars
  reset-ticks
end

;; Setting up of parking spots.

to setup-parking-spots ;; All patches are parking spots.
  ask patches [
    set pcolor black
    set empty true      ;; All patches are empty when the model is initialised.
  ]
end

;; Setting up the companies.

to setup-companies
  create-companies number-of-companies [  ;; Number of companies is based on the slider number-of-companies.
    set shape "house"
    set color orange
    set size 2
    set company-price 1
    move-to one-of patches with [ count companies-here = 0 ]
  ]
  set bottom-price starting-bottom-price
end

;; Setting up the cars for every company individually. Each car is available and parked on a empty patch.

to setup-cars
  create-cars number-of-cars-company0 [
    set color green
    set shape "car"
    set size 1
    set available true
    setxy random-xcor random-ycor
    set company-id company 0
    set parked true
    move-to one-of patches with [ empty = true ]
    ask patch-here [  set empty false ]

  ]

  create-cars number-of-cars-company1 [
    set color green
    set shape "car"
    set size 1
    set available true
    setxy random-xcor random-ycor
    set company-id company 1
    set parked true
    move-to one-of patches with [ empty = true ]
    ask patch-here [  set empty false ]

  ]

  create-cars number-of-cars-company2 [
    set color green
    set shape "car"
    set size 1
    set available true
    setxy random-xcor random-ycor
    set company-id company 2
    set parked true
    move-to one-of patches with [ empty = true ]
    ask patch-here [  set empty false ]

  ]

end

;; Start of the go procedure.

to go
  set-market-price
  set-demand
  walk-users
  drive-users
  set-prices
  oppertunistic-behaviour
  new-cars 0
  new-cars 1
  new-cars 2
  if ticks >= 100000 [stop]
  tick
end

to set-market-price

  set market-price mean [ company-price ] of companies  ;; The market price is determined by the average price of all company prices.

end

to set-demand
  if ( random-float 1 < ( car-sharing-demand / 100 ) )  ;; A user is created if the random number that is created between 0 and 1 is smaller than the slider car-sharing-demand / 100.
  [
    create-users 1
    [
      start-shared-user
    ]
  ]
end

to-report price-of-company
  report company-price
end

to start-shared-user
  set color white
  set shape "person"
  set size 0.50
  setxy random-xcor random-ycor
  set origin-list [ ] ;; The original location of the user is saved.
  set origin-list fput xcor origin-list
  set origin-list lput ycor origin-list
  set company-id one-of companies ;; The user is assigned to a random company.

  let price 0
  ask company-id [ set price price-of-company ]

  set user-price price

  if user-price > market-price  [ unsatisfied-user ]  ;; If the market price is lower than the users price the users is unsatisfied.

  ifelse any? cars in-radius ( walking-radius ) with [ available and [ company-id ] of myself = company-id ]  ;; The user checks if there is a car in the radius that is avialable and has the same company-id.
  [
    set destination [ ] ; The user sets a destination.

    set destination fput random-xcor destination
    set destination lput random-ycor destination

    set user-distance ( sqrt    abs (  ( (  item 0 destination ) ^ 2 - (  item 0 origin-list ) ^ 2  ) + abs ( (  item 1 destination ) ^ 2 - (  item 1 origin-list ) ^ 2 ) ) ) ;; The distance that the user ig going to cover is calculated.

    set walking true ; The walking procedure is activated
    set driving false
    set reserved-car min-one-of cars with [ available and [ company-id ] of myself = company-id  ] [ distance myself ]     ; The user reserves the car with the same company-id that is closest.

    ask reserved-car
    [
      reserve-procedure

    ]

    face reserved-car

  ]
  [ unsatisfied-user ]
end

to reserve-procedure
  set color red
  set available false
  ask patch-here [ set empty true  ] ;; The patch that the car was parked on is now empty.
end

to unsatisfied-user ;; A user that is unsatisfied is counted and deleted.
  ask company-id [
    set unsatisfied-users ( unsatisfied-users + 1 )
  ]
  die
end

to walk-users  ;; The users walking procedure.
  ask users with [ walking ]
  [
    face reserved-car
    fd ( speed * 0.0002 ) ;; The speed is determined with a slider.
    if distance reserved-car <= 0.01 ;; If the user is close enough to the car, the use is started.
    [
      start-use
    ]
  ]
end

to start-use
  facexy ( item 0 destination ) ( item 1 destination ) ;; The user faces the destination patch.
  set direction heading
  set walking false ;; The user is not walking anymore.
  set driving true ;; The user is now driving.
  hide-turtle
end

to drive-users ;; The driving procedure.
  ask users with [ driving ]
  [
    fd ( speed * 0.001 ) ;; The speed is determined with a slider.
    ask reserved-car [ setxy [ xcor ] of myself [ ycor ] of myself ;; The reserved-car takes over the coordinates of the user.
      set parked false
    ]
    if (distancexy ( item 0 destination ) ( item 1 destination ) < 0.05 ) ;; If the car and the user are close enough to the destination the search-for-parkign procedure starts.
    [
      search-for-parking
    ]
  ]
end

to search-for-parking

  ask reserved-car [

    if any? patches in-radius ( walking-radius ) with [ empty = false ] ;; Cars can only parky on empty patches within the walking-radius.

    [ ask company-id [ set no-parking ( no-parking + 1 ) ]

      move-to min-one-of (patches with [not any? cars-here ]) [walking-radius]

    ]
  ]
  end-use

end


to end-use
  ask company-id [ ;;

    set profit ( profit + ( company-price * user-distance )) ;; The companies profit is the companies price times the distance the user has covered.
    set satisfied-users ( satisfied-users + 1 ) ;; The companies sataisfied users increases by 1.
  ]
  ask reserved-car [
    unreserve-procedure
  ]

  die
end

to unreserve-procedure
  set color green
  set available true
  set parked true
  ask patch-here [ set empty false ] ;; The patch is full.
end

to set-prices

  if collective-choice-arrangement = true ;; If collective choice is on, the companies have a bottom-price.
  [ ask companies [

    if company-price < market-price [  set vote 1 ]
    if company-price > market-price [ set vote  0 ]

    set total (sum [vote] of companies )

    if total >= 2 [ set bottom-price ( bottom-price + 0.001 ) ]
    if total <= 1 [ set bottom-price ( bottom-price - 0.001 ) ]



    set company-price (company-price + 0.001 * (satisfied-users  -  unsatisfied-users ))

    if company-price < bottom-price [set company-price bottom-price]]

  ]

  if collective-choice-arrangement = false ;; If the collective choice is off, companies determine their own prices.
  [ ask companies [

    set company-price (company-price + 0.001 * (satisfied-users  -  unsatisfied-users )) ;;, make the companies price dependend on the difference in profit. The companies-price changes by the difference between satisfied and unsatisfied users.
    ]
  ]
  ask companies [
    if company-price < 0
    [ set company-price 0.001 ]
  ]

end


to oppertunistic-behaviour ;; Companies behave oppertunistic by violating rules.
  ask companies [
    ifelse random 1000 < prob-of-violating-rules and company-price > market-price
    [ set rules-violated "yes" ]
    [ set rules-violated "no" ]

    if collective-choice-arrangement = true [ ;; If the collective choice is active this probability is half.
      ifelse random 2000 < prob-of-violating-rules and company-price > market-price  ;;
      [ set rules-violated "yes" ]
      [ set rules-violated "no" ]
    ]

    if rules-violated = "yes" [
      set total-rules-violated ( total-rules-violated + 1)
      set company-rules-violated ( company-rules-violated + 1)

      if graduated-sanctions = false [
        if random 100 < prob-of-sanctioning [
          set profit ( profit - ( sanctioning-multiple * abs company-price )) ;; The companies get sanctioned based on the sanctioning multiple and their own price.
          set number-of-sanctions ( number-of-sanctions + 1)
          set company-sanctioned ( company-sanctioned + 1)
        ]
      ]

      if graduated-sanctions = true [
        if random 100 < prob-of-sanctioning [
          set profit ( profit - (company-sanctioned * ( sanctioning-multiple * abs company-price ))) ;; The companies get sanctioned based on the sanctioning multiple and their own price.
          delete-cars (  company company-id )  ;
          set number-of-sanctions ( number-of-sanctions + 1)
          set company-sanctioned ( company-sanctioned + 1)

        ]
      ]
    ]
  ]
end

to delete-cars [ num ]
  ask one-of cars with [ available] ;; and ( company-id = company num )] ;; [ company-id ] of myself = company-id ]
  [
    die]

end

to new-cars [ num ];;

  if one-company = false [


    ask company num
    [ if  ( ( count cars with [ ( company-id = company num ) and available = false ] ) / ( count cars with [ company-id = company num ] ) ) > new-car-treshold   [ ;; If more than half of the cars are unavailable a new car is added to the fleet.
      hatch-cars 1 [
        set color green
        set shape "car"
        set size 1
        set available true
        setxy random-xcor random-ycor
        set company-id company num
        set parked true
        move-to one-of patches with [ empty = true ]
        ask patch-here [  set empty false ]
      ]

      ]
    ]
  ]

  if one-company = true
  [
    ask company 0
    [ if  ( ( count cars with [ ( company-id = company 0 ) and available = false ] ) / ( count cars with [ company-id = company 0 ] ) ) > new-car-treshold   [ ;; If more than half of the cars are unavailable a new car is added to the fleet.
      hatch-cars 1 [
        set color green
        set shape "car"
        set size 1
        set available true
        setxy random-xcor random-ycor
        set company-id company 0
        set parked true
        move-to one-of patches with [ empty = true ]
        ask patch-here [  set empty false ]
      ]

      ]
    ]
  ]



end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
1
10
1
1
1
0
0
0
1
0
32
0
32
0
0
1
ticks
30.0

INPUTBOX
0
237
155
297
walking-radius
3.0
1
0
Number

SLIDER
0
192
172
225
speed
speed
20
100
60.0
1
1
NIL
HORIZONTAL

BUTTON
0
85
87
118
Go
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

SLIDER
0
152
192
185
car-sharing-demand
car-sharing-demand
0
100
75.0
1
1
NIL
HORIZONTAL

BUTTON
0
10
67
43
Setup
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

TEXTBOX
223
459
373
477
Design principles\n
11
0.0
1

BUTTON
0
49
63
82
Go
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
655
10
771
55
number of users
count users
17
1
11

PLOT
654
62
909
212
Number of empty parking spots
ticks
users
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Available parking spots" 1.0 0 -16777216 true "" "plot count patches with [ empty = true ]"

INPUTBOX
1133
10
1282
70
number-of-cars-company0
200.0
1
0
Number

INPUTBOX
1134
72
1283
132
number-of-cars-company1
200.0
1
0
Number

INPUTBOX
1132
138
1281
198
number-of-cars-company2
200.0
1
0
Number

SLIDER
1085
10
1118
180
number-of-companies
number-of-companies
0
3
3.0
1
1
NIL
VERTICAL

PLOT
654
217
854
367
Company profit
Ticks
Profit
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Company 0" 1.0 0 -13840069 true "" "plot [ profit ] of company 0"
"Company 1" 1.0 0 -2674135 true "" "plot [ profit ] of company 1"
"Company 2" 1.0 0 -13345367 true "" "plot [ profit ] of company 2"

MONITOR
777
10
871
55
NIL
market-price
17
1
11

PLOT
864
217
1064
367
Satisfied Users - Unsatisfied Users
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Company 0" 1.0 0 -13840069 true "" "plot ( [ satisfied-users ] of company 0 ) - ( [ unsatisfied-users ] of company 0 ) "
"Company 1" 1.0 0 -2674135 true "" "plot ( [ satisfied-users ] of company 1 ) - ( [ unsatisfied-users ] of company 1 ) "
"Company 2" 1.0 0 -13345367 true "" "plot ( [ satisfied-users ] of company 2 ) - ( [ unsatisfied-users ] of company 2 ) "

MONITOR
1294
12
1448
57
NIL
[ profit ] of company 0
17
1
11

MONITOR
1296
74
1447
119
NIL
[ profit ] of company 1
17
1
11

MONITOR
1295
144
1446
189
NIL
[ profit ] of company 2
17
1
11

SWITCH
209
479
457
512
collective-choice-arrangement
collective-choice-arrangement
0
1
-1000

INPUTBOX
465
454
614
514
starting-bottom-price
10.0
1
0
Number

SLIDER
209
518
410
551
prob-of-violating-rules
prob-of-violating-rules
0
100
10.0
1
1
NIL
HORIZONTAL

SWITCH
208
561
395
594
graduated-sanctions
graduated-sanctions
0
1
-1000

SLIDER
404
562
586
595
prob-of-sanctioning
prob-of-sanctioning
0
100
20.0
1
1
NIL
HORIZONTAL

MONITOR
618
566
766
611
NIL
number-of-sanctions
17
1
11

MONITOR
617
516
751
561
NIL
total-rules-violated
17
1
11

PLOT
1075
216
1275
366
Number of cars
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -13840069 true "" "plot count cars with [ ( company-id = company 0 ) ]"
"pen-1" 1.0 0 -2674135 true "" "plot count cars with [ ( company-id = company 1 ) ]"
"pen-2" 1.0 0 -13345367 true "" "plot count cars with [ ( company-id = company 2 ) ]"

SWITCH
912
10
1075
43
One-company
One-company
1
1
-1000

SLIDER
31
410
203
443
new-car-treshold
new-car-treshold
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
413
604
595
637
sanctioning-multiple
sanctioning-multiple
0
100
20.0
1
1
NIL
HORIZONTAL

MONITOR
746
443
842
488
NIL
bottom-price
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment 1: Base scenario" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>[ satisfied-users ] of company 0</metric>
    <metric>[ unsatisfied-users ] of company 0</metric>
    <metric>[ satisfied-users ] of company 1</metric>
    <metric>[ unsatisfied-users ] of company 1</metric>
    <metric>[ satisfied-users ] of company 2</metric>
    <metric>[ unsatisfied-users ] of company 2</metric>
    <metric>[ company-rules-violated ] of company 0</metric>
    <metric>[ company-rules-violated ] of company 1</metric>
    <metric>[ company-rules-violated ] of company 2</metric>
    <metric>[ company-sanctioned ] of company 0</metric>
    <metric>[ company-sanctioned ] of company 1</metric>
    <metric>[ company-sanctioned ] of company 2</metric>
    <metric>[ vote ] of company 0</metric>
    <metric>[ vote ] of company 1</metric>
    <metric>[ vote ] of company 2</metric>
    <metric>[ company-price ] of company 0</metric>
    <metric>[ company-price ] of company 1</metric>
    <metric>[ company-price ] of company 2</metric>
    <metric>[ profit ] of company 0</metric>
    <metric>[ profit ] of company 1</metric>
    <metric>[ profit ] of company 2</metric>
    <metric>count cars with [ ( company-id = company 0 ) ]</metric>
    <metric>count cars with [ ( company-id = company 1 ) ]</metric>
    <metric>count cars with [ ( company-id = company 2 ) ]</metric>
    <metric>count users</metric>
    <metric>market-price</metric>
    <metric>bottom-price</metric>
    <metric>count cars with [ available = true ]</metric>
    <metric>count patches with [ empty = true ]</metric>
    <metric>[ no-parking ] of company 0</metric>
    <metric>[ no-parking ] of company 1</metric>
    <metric>[ no-parking ] of company 2</metric>
    <enumeratedValueSet variable="walking-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-violating-rules">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-car-treshold">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company0">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="graduated-sanctions">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-sharing-demand">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-companies">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collective-choice-arrangement">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="One-company">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company1">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanctioning-multiple">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company2">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-sanctioning">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-bottom-price">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 2" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>[ satisfied-users ] of company 0</metric>
    <metric>[ unsatisfied-users ] of company 0</metric>
    <metric>[ satisfied-users ] of company 1</metric>
    <metric>[ unsatisfied-users ] of company 1</metric>
    <metric>[ satisfied-users ] of company 2</metric>
    <metric>[ unsatisfied-users ] of company 2</metric>
    <metric>[ company-rules-violated ] of company 0</metric>
    <metric>[ company-rules-violated ] of company 1</metric>
    <metric>[ company-rules-violated ] of company 2</metric>
    <metric>[ company-sanctioned ] of company 0</metric>
    <metric>[ company-sanctioned ] of company 1</metric>
    <metric>[ company-sanctioned ] of company 2</metric>
    <metric>[ vote ] of company 0</metric>
    <metric>[ vote ] of company 1</metric>
    <metric>[ vote ] of company 2</metric>
    <metric>[ company-price ] of company 0</metric>
    <metric>[ company-price ] of company 1</metric>
    <metric>[ company-price ] of company 2</metric>
    <metric>[ profit ] of company 0</metric>
    <metric>[ profit ] of company 1</metric>
    <metric>[ profit ] of company 2</metric>
    <metric>count cars with [ ( company-id = company 0 ) ]</metric>
    <metric>count cars with [ ( company-id = company 1 ) ]</metric>
    <metric>count cars with [ ( company-id = company 2 ) ]</metric>
    <metric>count users</metric>
    <metric>market-price</metric>
    <metric>bottom-price</metric>
    <metric>count cars with [ available = true ]</metric>
    <metric>count patches with [ empty = true ]</metric>
    <metric>[ no-parking ] of company 0</metric>
    <metric>[ no-parking ] of company 1</metric>
    <metric>[ no-parking ] of company 2</metric>
    <enumeratedValueSet variable="walking-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-violating-rules">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-car-treshold">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company0">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="graduated-sanctions">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-sharing-demand">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-companies">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collective-choice-arrangement">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="One-company">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company1">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanctioning-multiple">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company2">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-sanctioning">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-bottom-price">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 3" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>[ satisfied-users ] of company 0</metric>
    <metric>[ unsatisfied-users ] of company 0</metric>
    <metric>[ satisfied-users ] of company 1</metric>
    <metric>[ unsatisfied-users ] of company 1</metric>
    <metric>[ satisfied-users ] of company 2</metric>
    <metric>[ unsatisfied-users ] of company 2</metric>
    <metric>[ company-rules-violated ] of company 0</metric>
    <metric>[ company-rules-violated ] of company 1</metric>
    <metric>[ company-rules-violated ] of company 2</metric>
    <metric>[ company-sanctioned ] of company 0</metric>
    <metric>[ company-sanctioned ] of company 1</metric>
    <metric>[ company-sanctioned ] of company 2</metric>
    <metric>[ vote ] of company 0</metric>
    <metric>[ vote ] of company 1</metric>
    <metric>[ vote ] of company 2</metric>
    <metric>[ company-price ] of company 0</metric>
    <metric>[ company-price ] of company 1</metric>
    <metric>[ company-price ] of company 2</metric>
    <metric>[ profit ] of company 0</metric>
    <metric>[ profit ] of company 1</metric>
    <metric>[ profit ] of company 2</metric>
    <metric>count cars with [ ( company-id = company 0 ) ]</metric>
    <metric>count cars with [ ( company-id = company 1 ) ]</metric>
    <metric>count cars with [ ( company-id = company 2 ) ]</metric>
    <metric>count users</metric>
    <metric>market-price</metric>
    <metric>bottom-price</metric>
    <metric>count cars with [ available = true ]</metric>
    <metric>count patches with [ empty = true ]</metric>
    <metric>[ no-parking ] of company 0</metric>
    <metric>[ no-parking ] of company 1</metric>
    <metric>[ no-parking ] of company 2</metric>
    <enumeratedValueSet variable="walking-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-violating-rules">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-car-treshold">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company0">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="graduated-sanctions">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-sharing-demand">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-companies">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collective-choice-arrangement">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="One-company">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company1">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanctioning-multiple">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company2">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-sanctioning">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-bottom-price">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 4" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>[ satisfied-users ] of company 0</metric>
    <metric>[ unsatisfied-users ] of company 0</metric>
    <metric>[ satisfied-users ] of company 1</metric>
    <metric>[ unsatisfied-users ] of company 1</metric>
    <metric>[ satisfied-users ] of company 2</metric>
    <metric>[ unsatisfied-users ] of company 2</metric>
    <metric>[ company-rules-violated ] of company 0</metric>
    <metric>[ company-rules-violated ] of company 1</metric>
    <metric>[ company-rules-violated ] of company 2</metric>
    <metric>[ company-sanctioned ] of company 0</metric>
    <metric>[ company-sanctioned ] of company 1</metric>
    <metric>[ company-sanctioned ] of company 2</metric>
    <metric>[ vote ] of company 0</metric>
    <metric>[ vote ] of company 1</metric>
    <metric>[ vote ] of company 2</metric>
    <metric>[ company-price ] of company 0</metric>
    <metric>[ company-price ] of company 1</metric>
    <metric>[ company-price ] of company 2</metric>
    <metric>[ profit ] of company 0</metric>
    <metric>[ profit ] of company 1</metric>
    <metric>[ profit ] of company 2</metric>
    <metric>count cars with [ ( company-id = company 0 ) ]</metric>
    <metric>count cars with [ ( company-id = company 1 ) ]</metric>
    <metric>count cars with [ ( company-id = company 2 ) ]</metric>
    <metric>count users</metric>
    <metric>market-price</metric>
    <metric>bottom-price</metric>
    <metric>count cars with [ available = true ]</metric>
    <metric>count patches with [ empty = true ]</metric>
    <metric>[ no-parking ] of company 0</metric>
    <metric>[ no-parking ] of company 1</metric>
    <metric>[ no-parking ] of company 2</metric>
    <enumeratedValueSet variable="walking-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-violating-rules">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-car-treshold">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company0">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="graduated-sanctions">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-sharing-demand">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-companies">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collective-choice-arrangement">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="One-company">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company1">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanctioning-multiple">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company2">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-sanctioning">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-bottom-price">
      <value value="5"/>
      <value value="15"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 5" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>[ satisfied-users ] of company 0</metric>
    <metric>[ unsatisfied-users ] of company 0</metric>
    <metric>[ satisfied-users ] of company 1</metric>
    <metric>[ unsatisfied-users ] of company 1</metric>
    <metric>[ satisfied-users ] of company 2</metric>
    <metric>[ unsatisfied-users ] of company 2</metric>
    <metric>[ company-rules-violated ] of company 0</metric>
    <metric>[ company-rules-violated ] of company 1</metric>
    <metric>[ company-rules-violated ] of company 2</metric>
    <metric>[ company-sanctioned ] of company 0</metric>
    <metric>[ company-sanctioned ] of company 1</metric>
    <metric>[ company-sanctioned ] of company 2</metric>
    <metric>[ vote ] of company 0</metric>
    <metric>[ vote ] of company 1</metric>
    <metric>[ vote ] of company 2</metric>
    <metric>[ company-price ] of company 0</metric>
    <metric>[ company-price ] of company 1</metric>
    <metric>[ company-price ] of company 2</metric>
    <metric>[ profit ] of company 0</metric>
    <metric>[ profit ] of company 1</metric>
    <metric>[ profit ] of company 2</metric>
    <metric>count cars with [ ( company-id = company 0 ) ]</metric>
    <metric>count cars with [ ( company-id = company 1 ) ]</metric>
    <metric>count cars with [ ( company-id = company 2 ) ]</metric>
    <metric>count users</metric>
    <metric>market-price</metric>
    <metric>bottom-price</metric>
    <metric>count cars with [ available = true ]</metric>
    <metric>count patches with [ empty = true ]</metric>
    <metric>[ no-parking ] of company 0</metric>
    <metric>[ no-parking ] of company 1</metric>
    <metric>[ no-parking ] of company 2</metric>
    <enumeratedValueSet variable="walking-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-violating-rules">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-car-treshold">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company0">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="graduated-sanctions">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-sharing-demand">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-companies">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collective-choice-arrangement">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="One-company">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company1">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanctioning-multiple">
      <value value="10"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company2">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-sanctioning">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-bottom-price">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 6" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>[ satisfied-users ] of company 0</metric>
    <metric>[ unsatisfied-users ] of company 0</metric>
    <metric>[ satisfied-users ] of company 1</metric>
    <metric>[ unsatisfied-users ] of company 1</metric>
    <metric>[ satisfied-users ] of company 2</metric>
    <metric>[ unsatisfied-users ] of company 2</metric>
    <metric>[ company-rules-violated ] of company 0</metric>
    <metric>[ company-rules-violated ] of company 1</metric>
    <metric>[ company-rules-violated ] of company 2</metric>
    <metric>[ company-sanctioned ] of company 0</metric>
    <metric>[ company-sanctioned ] of company 1</metric>
    <metric>[ company-sanctioned ] of company 2</metric>
    <metric>[ vote ] of company 0</metric>
    <metric>[ vote ] of company 1</metric>
    <metric>[ vote ] of company 2</metric>
    <metric>[ company-price ] of company 0</metric>
    <metric>[ company-price ] of company 1</metric>
    <metric>[ company-price ] of company 2</metric>
    <metric>[ profit ] of company 0</metric>
    <metric>[ profit ] of company 1</metric>
    <metric>[ profit ] of company 2</metric>
    <metric>count cars with [ ( company-id = company 0 ) ]</metric>
    <metric>count cars with [ ( company-id = company 1 ) ]</metric>
    <metric>count cars with [ ( company-id = company 2 ) ]</metric>
    <metric>count users</metric>
    <metric>market-price</metric>
    <metric>bottom-price</metric>
    <metric>count cars with [ available = true ]</metric>
    <metric>count patches with [ empty = true ]</metric>
    <metric>[ no-parking ] of company 0</metric>
    <metric>[ no-parking ] of company 1</metric>
    <metric>[ no-parking ] of company 2</metric>
    <enumeratedValueSet variable="walking-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-violating-rules">
      <value value="5"/>
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-car-treshold">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company0">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="graduated-sanctions">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-sharing-demand">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-companies">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collective-choice-arrangement">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="One-company">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company1">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanctioning-multiple">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company2">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-sanctioning">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-bottom-price">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 7" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>[ satisfied-users ] of company 0</metric>
    <metric>[ unsatisfied-users ] of company 0</metric>
    <metric>[ satisfied-users ] of company 1</metric>
    <metric>[ unsatisfied-users ] of company 1</metric>
    <metric>[ satisfied-users ] of company 2</metric>
    <metric>[ unsatisfied-users ] of company 2</metric>
    <metric>[ company-rules-violated ] of company 0</metric>
    <metric>[ company-rules-violated ] of company 1</metric>
    <metric>[ company-rules-violated ] of company 2</metric>
    <metric>[ company-sanctioned ] of company 0</metric>
    <metric>[ company-sanctioned ] of company 1</metric>
    <metric>[ company-sanctioned ] of company 2</metric>
    <metric>[ vote ] of company 0</metric>
    <metric>[ vote ] of company 1</metric>
    <metric>[ vote ] of company 2</metric>
    <metric>[ company-price ] of company 0</metric>
    <metric>[ company-price ] of company 1</metric>
    <metric>[ company-price ] of company 2</metric>
    <metric>[ profit ] of company 0</metric>
    <metric>[ profit ] of company 1</metric>
    <metric>[ profit ] of company 2</metric>
    <metric>count cars with [ ( company-id = company 0 ) ]</metric>
    <metric>count cars with [ ( company-id = company 1 ) ]</metric>
    <metric>count cars with [ ( company-id = company 2 ) ]</metric>
    <metric>count users</metric>
    <metric>market-price</metric>
    <metric>bottom-price</metric>
    <metric>count cars with [ available = true ]</metric>
    <metric>count patches with [ empty = true ]</metric>
    <metric>[ no-parking ] of company 0</metric>
    <metric>[ no-parking ] of company 1</metric>
    <metric>[ no-parking ] of company 2</metric>
    <enumeratedValueSet variable="walking-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-violating-rules">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-car-treshold">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company0">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="graduated-sanctions">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-sharing-demand">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-companies">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collective-choice-arrangement">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="One-company">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company1">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanctioning-multiple">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company2">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-sanctioning">
      <value value="10"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-bottom-price">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 1 Base scenario table" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>[ satisfied-users ] of company 0</metric>
    <metric>[ unsatisfied-users ] of company 0</metric>
    <metric>[ satisfied-users ] of company 1</metric>
    <metric>[ unsatisfied-users ] of company 1</metric>
    <metric>[ satisfied-users ] of company 2</metric>
    <metric>[ unsatisfied-users ] of company 2</metric>
    <metric>[ company-rules-violated ] of company 0</metric>
    <metric>[ company-rules-violated ] of company 1</metric>
    <metric>[ company-rules-violated ] of company 2</metric>
    <metric>[ company-sanctioned ] of company 0</metric>
    <metric>[ company-sanctioned ] of company 1</metric>
    <metric>[ company-sanctioned ] of company 2</metric>
    <metric>[ vote ] of company 0</metric>
    <metric>[ vote ] of company 1</metric>
    <metric>[ vote ] of company 2</metric>
    <metric>[ company-price ] of company 0</metric>
    <metric>[ company-price ] of company 1</metric>
    <metric>[ company-price ] of company 2</metric>
    <metric>[ profit ] of company 0</metric>
    <metric>[ profit ] of company 1</metric>
    <metric>[ profit ] of company 2</metric>
    <metric>count cars with [ ( company-id = company 0 ) ]</metric>
    <metric>count cars with [ ( company-id = company 1 ) ]</metric>
    <metric>count cars with [ ( company-id = company 2 ) ]</metric>
    <metric>count users</metric>
    <metric>market-price</metric>
    <metric>bottom-price</metric>
    <metric>count cars with [ available = true ]</metric>
    <metric>count patches with [ empty = true ]</metric>
    <metric>[ no-parking ] of company 0</metric>
    <metric>[ no-parking ] of company 1</metric>
    <metric>[ no-parking ] of company 2</metric>
    <enumeratedValueSet variable="walking-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-violating-rules">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-car-treshold">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company0">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="graduated-sanctions">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-sharing-demand">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-companies">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collective-choice-arrangement">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="One-company">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company1">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanctioning-multiple">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company2">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-sanctioning">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-bottom-price">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 2 table" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>[ satisfied-users ] of company 0</metric>
    <metric>[ unsatisfied-users ] of company 0</metric>
    <metric>[ satisfied-users ] of company 1</metric>
    <metric>[ unsatisfied-users ] of company 1</metric>
    <metric>[ satisfied-users ] of company 2</metric>
    <metric>[ unsatisfied-users ] of company 2</metric>
    <metric>[ company-rules-violated ] of company 0</metric>
    <metric>[ company-rules-violated ] of company 1</metric>
    <metric>[ company-rules-violated ] of company 2</metric>
    <metric>[ company-sanctioned ] of company 0</metric>
    <metric>[ company-sanctioned ] of company 1</metric>
    <metric>[ company-sanctioned ] of company 2</metric>
    <metric>[ vote ] of company 0</metric>
    <metric>[ vote ] of company 1</metric>
    <metric>[ vote ] of company 2</metric>
    <metric>[ company-price ] of company 0</metric>
    <metric>[ company-price ] of company 1</metric>
    <metric>[ company-price ] of company 2</metric>
    <metric>[ profit ] of company 0</metric>
    <metric>[ profit ] of company 1</metric>
    <metric>[ profit ] of company 2</metric>
    <metric>count cars with [ ( company-id = company 0 ) ]</metric>
    <metric>count cars with [ ( company-id = company 1 ) ]</metric>
    <metric>count cars with [ ( company-id = company 2 ) ]</metric>
    <metric>count users</metric>
    <metric>market-price</metric>
    <metric>bottom-price</metric>
    <metric>count cars with [ available = true ]</metric>
    <metric>count patches with [ empty = true ]</metric>
    <metric>[ no-parking ] of company 0</metric>
    <metric>[ no-parking ] of company 1</metric>
    <metric>[ no-parking ] of company 2</metric>
    <enumeratedValueSet variable="walking-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-violating-rules">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-car-treshold">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company0">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="graduated-sanctions">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-sharing-demand">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-companies">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collective-choice-arrangement">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="One-company">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company1">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanctioning-multiple">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company2">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-sanctioning">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-bottom-price">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 3 table" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>[ satisfied-users ] of company 0</metric>
    <metric>[ unsatisfied-users ] of company 0</metric>
    <metric>[ satisfied-users ] of company 1</metric>
    <metric>[ unsatisfied-users ] of company 1</metric>
    <metric>[ satisfied-users ] of company 2</metric>
    <metric>[ unsatisfied-users ] of company 2</metric>
    <metric>[ company-rules-violated ] of company 0</metric>
    <metric>[ company-rules-violated ] of company 1</metric>
    <metric>[ company-rules-violated ] of company 2</metric>
    <metric>[ company-sanctioned ] of company 0</metric>
    <metric>[ company-sanctioned ] of company 1</metric>
    <metric>[ company-sanctioned ] of company 2</metric>
    <metric>[ vote ] of company 0</metric>
    <metric>[ vote ] of company 1</metric>
    <metric>[ vote ] of company 2</metric>
    <metric>[ company-price ] of company 0</metric>
    <metric>[ company-price ] of company 1</metric>
    <metric>[ company-price ] of company 2</metric>
    <metric>[ profit ] of company 0</metric>
    <metric>[ profit ] of company 1</metric>
    <metric>[ profit ] of company 2</metric>
    <metric>count cars with [ ( company-id = company 0 ) ]</metric>
    <metric>count cars with [ ( company-id = company 1 ) ]</metric>
    <metric>count cars with [ ( company-id = company 2 ) ]</metric>
    <metric>count users</metric>
    <metric>market-price</metric>
    <metric>bottom-price</metric>
    <metric>count cars with [ available = true ]</metric>
    <metric>count patches with [ empty = true ]</metric>
    <metric>[ no-parking ] of company 0</metric>
    <metric>[ no-parking ] of company 1</metric>
    <metric>[ no-parking ] of company 2</metric>
    <enumeratedValueSet variable="walking-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-violating-rules">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-car-treshold">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company0">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="graduated-sanctions">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-sharing-demand">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-companies">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collective-choice-arrangement">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="One-company">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company1">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanctioning-multiple">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company2">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-sanctioning">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-bottom-price">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 4 table" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>[ satisfied-users ] of company 0</metric>
    <metric>[ unsatisfied-users ] of company 0</metric>
    <metric>[ satisfied-users ] of company 1</metric>
    <metric>[ unsatisfied-users ] of company 1</metric>
    <metric>[ satisfied-users ] of company 2</metric>
    <metric>[ unsatisfied-users ] of company 2</metric>
    <metric>[ company-rules-violated ] of company 0</metric>
    <metric>[ company-rules-violated ] of company 1</metric>
    <metric>[ company-rules-violated ] of company 2</metric>
    <metric>[ company-sanctioned ] of company 0</metric>
    <metric>[ company-sanctioned ] of company 1</metric>
    <metric>[ company-sanctioned ] of company 2</metric>
    <metric>[ vote ] of company 0</metric>
    <metric>[ vote ] of company 1</metric>
    <metric>[ vote ] of company 2</metric>
    <metric>[ company-price ] of company 0</metric>
    <metric>[ company-price ] of company 1</metric>
    <metric>[ company-price ] of company 2</metric>
    <metric>[ profit ] of company 0</metric>
    <metric>[ profit ] of company 1</metric>
    <metric>[ profit ] of company 2</metric>
    <metric>count cars with [ ( company-id = company 0 ) ]</metric>
    <metric>count cars with [ ( company-id = company 1 ) ]</metric>
    <metric>count cars with [ ( company-id = company 2 ) ]</metric>
    <metric>count users</metric>
    <metric>market-price</metric>
    <metric>bottom-price</metric>
    <metric>count cars with [ available = true ]</metric>
    <metric>count patches with [ empty = true ]</metric>
    <metric>[ no-parking ] of company 0</metric>
    <metric>[ no-parking ] of company 1</metric>
    <metric>[ no-parking ] of company 2</metric>
    <enumeratedValueSet variable="walking-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-violating-rules">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-car-treshold">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company0">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="graduated-sanctions">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-sharing-demand">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-companies">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collective-choice-arrangement">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="One-company">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company1">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanctioning-multiple">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company2">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-sanctioning">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-bottom-price">
      <value value="5"/>
      <value value="15"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 5 table" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>[ satisfied-users ] of company 0</metric>
    <metric>[ unsatisfied-users ] of company 0</metric>
    <metric>[ satisfied-users ] of company 1</metric>
    <metric>[ unsatisfied-users ] of company 1</metric>
    <metric>[ satisfied-users ] of company 2</metric>
    <metric>[ unsatisfied-users ] of company 2</metric>
    <metric>[ company-rules-violated ] of company 0</metric>
    <metric>[ company-rules-violated ] of company 1</metric>
    <metric>[ company-rules-violated ] of company 2</metric>
    <metric>[ company-sanctioned ] of company 0</metric>
    <metric>[ company-sanctioned ] of company 1</metric>
    <metric>[ company-sanctioned ] of company 2</metric>
    <metric>[ vote ] of company 0</metric>
    <metric>[ vote ] of company 1</metric>
    <metric>[ vote ] of company 2</metric>
    <metric>[ company-price ] of company 0</metric>
    <metric>[ company-price ] of company 1</metric>
    <metric>[ company-price ] of company 2</metric>
    <metric>[ profit ] of company 0</metric>
    <metric>[ profit ] of company 1</metric>
    <metric>[ profit ] of company 2</metric>
    <metric>count cars with [ ( company-id = company 0 ) ]</metric>
    <metric>count cars with [ ( company-id = company 1 ) ]</metric>
    <metric>count cars with [ ( company-id = company 2 ) ]</metric>
    <metric>count users</metric>
    <metric>market-price</metric>
    <metric>bottom-price</metric>
    <metric>count cars with [ available = true ]</metric>
    <metric>count patches with [ empty = true ]</metric>
    <metric>[ no-parking ] of company 0</metric>
    <metric>[ no-parking ] of company 1</metric>
    <metric>[ no-parking ] of company 2</metric>
    <enumeratedValueSet variable="walking-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-violating-rules">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-car-treshold">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company0">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="graduated-sanctions">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-sharing-demand">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-companies">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collective-choice-arrangement">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="One-company">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company1">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanctioning-multiple">
      <value value="10"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company2">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-sanctioning">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-bottom-price">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 6 TABLE" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>[ satisfied-users ] of company 0</metric>
    <metric>[ unsatisfied-users ] of company 0</metric>
    <metric>[ satisfied-users ] of company 1</metric>
    <metric>[ unsatisfied-users ] of company 1</metric>
    <metric>[ satisfied-users ] of company 2</metric>
    <metric>[ unsatisfied-users ] of company 2</metric>
    <metric>[ company-rules-violated ] of company 0</metric>
    <metric>[ company-rules-violated ] of company 1</metric>
    <metric>[ company-rules-violated ] of company 2</metric>
    <metric>[ company-sanctioned ] of company 0</metric>
    <metric>[ company-sanctioned ] of company 1</metric>
    <metric>[ company-sanctioned ] of company 2</metric>
    <metric>[ vote ] of company 0</metric>
    <metric>[ vote ] of company 1</metric>
    <metric>[ vote ] of company 2</metric>
    <metric>[ company-price ] of company 0</metric>
    <metric>[ company-price ] of company 1</metric>
    <metric>[ company-price ] of company 2</metric>
    <metric>[ profit ] of company 0</metric>
    <metric>[ profit ] of company 1</metric>
    <metric>[ profit ] of company 2</metric>
    <metric>count cars with [ ( company-id = company 0 ) ]</metric>
    <metric>count cars with [ ( company-id = company 1 ) ]</metric>
    <metric>count cars with [ ( company-id = company 2 ) ]</metric>
    <metric>count users</metric>
    <metric>market-price</metric>
    <metric>bottom-price</metric>
    <metric>count cars with [ available = true ]</metric>
    <metric>count patches with [ empty = true ]</metric>
    <metric>[ no-parking ] of company 0</metric>
    <metric>[ no-parking ] of company 1</metric>
    <metric>[ no-parking ] of company 2</metric>
    <enumeratedValueSet variable="walking-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-violating-rules">
      <value value="5"/>
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-car-treshold">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company0">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="graduated-sanctions">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-sharing-demand">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-companies">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collective-choice-arrangement">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="One-company">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company1">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanctioning-multiple">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company2">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-sanctioning">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-bottom-price">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 7 table" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>[ satisfied-users ] of company 0</metric>
    <metric>[ unsatisfied-users ] of company 0</metric>
    <metric>[ satisfied-users ] of company 1</metric>
    <metric>[ unsatisfied-users ] of company 1</metric>
    <metric>[ satisfied-users ] of company 2</metric>
    <metric>[ unsatisfied-users ] of company 2</metric>
    <metric>[ company-rules-violated ] of company 0</metric>
    <metric>[ company-rules-violated ] of company 1</metric>
    <metric>[ company-rules-violated ] of company 2</metric>
    <metric>[ company-sanctioned ] of company 0</metric>
    <metric>[ company-sanctioned ] of company 1</metric>
    <metric>[ company-sanctioned ] of company 2</metric>
    <metric>[ vote ] of company 0</metric>
    <metric>[ vote ] of company 1</metric>
    <metric>[ vote ] of company 2</metric>
    <metric>[ company-price ] of company 0</metric>
    <metric>[ company-price ] of company 1</metric>
    <metric>[ company-price ] of company 2</metric>
    <metric>[ profit ] of company 0</metric>
    <metric>[ profit ] of company 1</metric>
    <metric>[ profit ] of company 2</metric>
    <metric>count cars with [ ( company-id = company 0 ) ]</metric>
    <metric>count cars with [ ( company-id = company 1 ) ]</metric>
    <metric>count cars with [ ( company-id = company 2 ) ]</metric>
    <metric>count users</metric>
    <metric>market-price</metric>
    <metric>bottom-price</metric>
    <metric>count cars with [ available = true ]</metric>
    <metric>count patches with [ empty = true ]</metric>
    <metric>[ no-parking ] of company 0</metric>
    <metric>[ no-parking ] of company 1</metric>
    <metric>[ no-parking ] of company 2</metric>
    <enumeratedValueSet variable="walking-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-violating-rules">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-car-treshold">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company0">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="graduated-sanctions">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-sharing-demand">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-companies">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collective-choice-arrangement">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="One-company">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company1">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanctioning-multiple">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company2">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-sanctioning">
      <value value="10"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-bottom-price">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="New car sensi" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>[ satisfied-users ] of company 0</metric>
    <metric>[ unsatisfied-users ] of company 0</metric>
    <metric>[ satisfied-users ] of company 1</metric>
    <metric>[ unsatisfied-users ] of company 1</metric>
    <metric>[ satisfied-users ] of company 2</metric>
    <metric>[ unsatisfied-users ] of company 2</metric>
    <metric>[ company-rules-violated ] of company 0</metric>
    <metric>[ company-rules-violated ] of company 1</metric>
    <metric>[ company-rules-violated ] of company 2</metric>
    <metric>[ company-sanctioned ] of company 0</metric>
    <metric>[ company-sanctioned ] of company 1</metric>
    <metric>[ company-sanctioned ] of company 2</metric>
    <metric>[ vote ] of company 0</metric>
    <metric>[ vote ] of company 1</metric>
    <metric>[ vote ] of company 2</metric>
    <metric>[ company-price ] of company 0</metric>
    <metric>[ company-price ] of company 1</metric>
    <metric>[ company-price ] of company 2</metric>
    <metric>[ profit ] of company 0</metric>
    <metric>[ profit ] of company 1</metric>
    <metric>[ profit ] of company 2</metric>
    <metric>count cars with [ ( company-id = company 0 ) ]</metric>
    <metric>count cars with [ ( company-id = company 1 ) ]</metric>
    <metric>count cars with [ ( company-id = company 2 ) ]</metric>
    <metric>count users</metric>
    <metric>market-price</metric>
    <metric>bottom-price</metric>
    <metric>count cars with [ available = true ]</metric>
    <metric>count patches with [ empty = true ]</metric>
    <metric>[ no-parking ] of company 0</metric>
    <metric>[ no-parking ] of company 1</metric>
    <metric>[ no-parking ] of company 2</metric>
    <enumeratedValueSet variable="walking-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-violating-rules">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-car-treshold">
      <value value="0.3"/>
      <value value="0.5"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company0">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="graduated-sanctions">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-sharing-demand">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-companies">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collective-choice-arrangement">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="One-company">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company1">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanctioning-multiple">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company2">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-sanctioning">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-bottom-price">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Walk sensi" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>[ satisfied-users ] of company 0</metric>
    <metric>[ unsatisfied-users ] of company 0</metric>
    <metric>[ satisfied-users ] of company 1</metric>
    <metric>[ unsatisfied-users ] of company 1</metric>
    <metric>[ satisfied-users ] of company 2</metric>
    <metric>[ unsatisfied-users ] of company 2</metric>
    <metric>[ company-rules-violated ] of company 0</metric>
    <metric>[ company-rules-violated ] of company 1</metric>
    <metric>[ company-rules-violated ] of company 2</metric>
    <metric>[ company-sanctioned ] of company 0</metric>
    <metric>[ company-sanctioned ] of company 1</metric>
    <metric>[ company-sanctioned ] of company 2</metric>
    <metric>[ vote ] of company 0</metric>
    <metric>[ vote ] of company 1</metric>
    <metric>[ vote ] of company 2</metric>
    <metric>[ company-price ] of company 0</metric>
    <metric>[ company-price ] of company 1</metric>
    <metric>[ company-price ] of company 2</metric>
    <metric>[ profit ] of company 0</metric>
    <metric>[ profit ] of company 1</metric>
    <metric>[ profit ] of company 2</metric>
    <metric>count cars with [ ( company-id = company 0 ) ]</metric>
    <metric>count cars with [ ( company-id = company 1 ) ]</metric>
    <metric>count cars with [ ( company-id = company 2 ) ]</metric>
    <metric>count users</metric>
    <metric>market-price</metric>
    <metric>bottom-price</metric>
    <metric>count cars with [ available = true ]</metric>
    <metric>count patches with [ empty = true ]</metric>
    <metric>[ no-parking ] of company 0</metric>
    <metric>[ no-parking ] of company 1</metric>
    <metric>[ no-parking ] of company 2</metric>
    <enumeratedValueSet variable="walking-radius">
      <value value="1"/>
      <value value="3"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-violating-rules">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-car-treshold">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company0">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="graduated-sanctions">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-sharing-demand">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-companies">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collective-choice-arrangement">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="One-company">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company1">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanctioning-multiple">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company2">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-sanctioning">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-bottom-price">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Speed sensi" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>[ satisfied-users ] of company 0</metric>
    <metric>[ unsatisfied-users ] of company 0</metric>
    <metric>[ satisfied-users ] of company 1</metric>
    <metric>[ unsatisfied-users ] of company 1</metric>
    <metric>[ satisfied-users ] of company 2</metric>
    <metric>[ unsatisfied-users ] of company 2</metric>
    <metric>[ company-rules-violated ] of company 0</metric>
    <metric>[ company-rules-violated ] of company 1</metric>
    <metric>[ company-rules-violated ] of company 2</metric>
    <metric>[ company-sanctioned ] of company 0</metric>
    <metric>[ company-sanctioned ] of company 1</metric>
    <metric>[ company-sanctioned ] of company 2</metric>
    <metric>[ vote ] of company 0</metric>
    <metric>[ vote ] of company 1</metric>
    <metric>[ vote ] of company 2</metric>
    <metric>[ company-price ] of company 0</metric>
    <metric>[ company-price ] of company 1</metric>
    <metric>[ company-price ] of company 2</metric>
    <metric>[ profit ] of company 0</metric>
    <metric>[ profit ] of company 1</metric>
    <metric>[ profit ] of company 2</metric>
    <metric>count cars with [ ( company-id = company 0 ) ]</metric>
    <metric>count cars with [ ( company-id = company 1 ) ]</metric>
    <metric>count cars with [ ( company-id = company 2 ) ]</metric>
    <metric>count users</metric>
    <metric>market-price</metric>
    <metric>bottom-price</metric>
    <metric>count cars with [ available = true ]</metric>
    <metric>count patches with [ empty = true ]</metric>
    <metric>[ no-parking ] of company 0</metric>
    <metric>[ no-parking ] of company 1</metric>
    <metric>[ no-parking ] of company 2</metric>
    <enumeratedValueSet variable="walking-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-violating-rules">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-car-treshold">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company0">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="graduated-sanctions">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-sharing-demand">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-companies">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collective-choice-arrangement">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="One-company">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company1">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanctioning-multiple">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company2">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-sanctioning">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-bottom-price">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Prob of rules violation sensi" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>[ satisfied-users ] of company 0</metric>
    <metric>[ unsatisfied-users ] of company 0</metric>
    <metric>[ satisfied-users ] of company 1</metric>
    <metric>[ unsatisfied-users ] of company 1</metric>
    <metric>[ satisfied-users ] of company 2</metric>
    <metric>[ unsatisfied-users ] of company 2</metric>
    <metric>[ company-rules-violated ] of company 0</metric>
    <metric>[ company-rules-violated ] of company 1</metric>
    <metric>[ company-rules-violated ] of company 2</metric>
    <metric>[ company-sanctioned ] of company 0</metric>
    <metric>[ company-sanctioned ] of company 1</metric>
    <metric>[ company-sanctioned ] of company 2</metric>
    <metric>[ vote ] of company 0</metric>
    <metric>[ vote ] of company 1</metric>
    <metric>[ vote ] of company 2</metric>
    <metric>[ company-price ] of company 0</metric>
    <metric>[ company-price ] of company 1</metric>
    <metric>[ company-price ] of company 2</metric>
    <metric>[ profit ] of company 0</metric>
    <metric>[ profit ] of company 1</metric>
    <metric>[ profit ] of company 2</metric>
    <metric>count cars with [ ( company-id = company 0 ) ]</metric>
    <metric>count cars with [ ( company-id = company 1 ) ]</metric>
    <metric>count cars with [ ( company-id = company 2 ) ]</metric>
    <metric>count users</metric>
    <metric>market-price</metric>
    <metric>bottom-price</metric>
    <metric>count cars with [ available = true ]</metric>
    <metric>count patches with [ empty = true ]</metric>
    <metric>[ no-parking ] of company 0</metric>
    <metric>[ no-parking ] of company 1</metric>
    <metric>[ no-parking ] of company 2</metric>
    <enumeratedValueSet variable="walking-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-violating-rules">
      <value value="10"/>
      <value value="30"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-car-treshold">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company0">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="graduated-sanctions">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-sharing-demand">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-companies">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collective-choice-arrangement">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="One-company">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company1">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanctioning-multiple">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company2">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-sanctioning">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-bottom-price">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Prob of sanctioning sensi" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>[ satisfied-users ] of company 0</metric>
    <metric>[ unsatisfied-users ] of company 0</metric>
    <metric>[ satisfied-users ] of company 1</metric>
    <metric>[ unsatisfied-users ] of company 1</metric>
    <metric>[ satisfied-users ] of company 2</metric>
    <metric>[ unsatisfied-users ] of company 2</metric>
    <metric>[ company-rules-violated ] of company 0</metric>
    <metric>[ company-rules-violated ] of company 1</metric>
    <metric>[ company-rules-violated ] of company 2</metric>
    <metric>[ company-sanctioned ] of company 0</metric>
    <metric>[ company-sanctioned ] of company 1</metric>
    <metric>[ company-sanctioned ] of company 2</metric>
    <metric>[ vote ] of company 0</metric>
    <metric>[ vote ] of company 1</metric>
    <metric>[ vote ] of company 2</metric>
    <metric>[ company-price ] of company 0</metric>
    <metric>[ company-price ] of company 1</metric>
    <metric>[ company-price ] of company 2</metric>
    <metric>[ profit ] of company 0</metric>
    <metric>[ profit ] of company 1</metric>
    <metric>[ profit ] of company 2</metric>
    <metric>count cars with [ ( company-id = company 0 ) ]</metric>
    <metric>count cars with [ ( company-id = company 1 ) ]</metric>
    <metric>count cars with [ ( company-id = company 2 ) ]</metric>
    <metric>count users</metric>
    <metric>market-price</metric>
    <metric>bottom-price</metric>
    <metric>count cars with [ available = true ]</metric>
    <metric>count patches with [ empty = true ]</metric>
    <metric>[ no-parking ] of company 0</metric>
    <metric>[ no-parking ] of company 1</metric>
    <metric>[ no-parking ] of company 2</metric>
    <enumeratedValueSet variable="walking-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-violating-rules">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-car-treshold">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company0">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="graduated-sanctions">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-sharing-demand">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-companies">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collective-choice-arrangement">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="One-company">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company1">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanctioning-multiple">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company2">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-sanctioning">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-bottom-price">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="demand sensi" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>[ satisfied-users ] of company 0</metric>
    <metric>[ unsatisfied-users ] of company 0</metric>
    <metric>[ satisfied-users ] of company 1</metric>
    <metric>[ unsatisfied-users ] of company 1</metric>
    <metric>[ satisfied-users ] of company 2</metric>
    <metric>[ unsatisfied-users ] of company 2</metric>
    <metric>[ company-rules-violated ] of company 0</metric>
    <metric>[ company-rules-violated ] of company 1</metric>
    <metric>[ company-rules-violated ] of company 2</metric>
    <metric>[ company-sanctioned ] of company 0</metric>
    <metric>[ company-sanctioned ] of company 1</metric>
    <metric>[ company-sanctioned ] of company 2</metric>
    <metric>[ vote ] of company 0</metric>
    <metric>[ vote ] of company 1</metric>
    <metric>[ vote ] of company 2</metric>
    <metric>[ company-price ] of company 0</metric>
    <metric>[ company-price ] of company 1</metric>
    <metric>[ company-price ] of company 2</metric>
    <metric>[ profit ] of company 0</metric>
    <metric>[ profit ] of company 1</metric>
    <metric>[ profit ] of company 2</metric>
    <metric>count cars with [ ( company-id = company 0 ) ]</metric>
    <metric>count cars with [ ( company-id = company 1 ) ]</metric>
    <metric>count cars with [ ( company-id = company 2 ) ]</metric>
    <metric>count users</metric>
    <metric>market-price</metric>
    <metric>bottom-price</metric>
    <metric>count cars with [ available = true ]</metric>
    <metric>count patches with [ empty = true ]</metric>
    <metric>[ no-parking ] of company 0</metric>
    <metric>[ no-parking ] of company 1</metric>
    <metric>[ no-parking ] of company 2</metric>
    <enumeratedValueSet variable="walking-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-violating-rules">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-car-treshold">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company0">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="graduated-sanctions">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-sharing-demand">
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-companies">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collective-choice-arrangement">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="One-company">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company1">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sanctioning-multiple">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars-company2">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-sanctioning">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-bottom-price">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
