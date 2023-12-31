# Extended Day 24 notes

For part 2 I guess this is just a really big system of equations?

Six variables to find: px, py, pz, vx, vy, vz

There are no zero velocities.
If there are parallel hailstones then that puts a constraint on us.
To go through parallel hailstones, your hailstone would need to be in the plane that those two hailstones define.

    p1 + v1*t1 = p0 + v0*t1
    p2 + v2*t2 = p0 + v0*t2
    p3 + v3*t3 = p0 + v0*t3
    p4 + v3*t4 = p0 + v0*t4

each equation introduces one new variable, so there are 6 + n free variables. Too many! What about for parallel lines?

    p1x + v1x*t1 = p0x + v0x*t1
    p2x + v1x*t2 = p0x + v0x*t2

    (p1x - p2x) / (v0x-vx1) = (t1-t2)

sample:
parallel hailstones:
A: 18,19,22 @ -1,-1,-2
B: 20,25,34 @ -2,-2,-4
  -> parallel because B's velocity is 2x A's

A plane is defined by:
ax + by + cz - d =0

solution:
24, 13, 10 @ -3, 1, 2

input:
parallel hailstones:
A: 416343629775116,253022765045891,491717629266329 @ -92,115,-118
B: 365714742138785,305827058151326,537426018413809 @ -44,55,-176

parallel hailstones:
A: 406438277711560,365452366481665,303153811346747 @ -99,-24,66
B: 344141964435022,343951825236361,384186561046085 @ -33,-8,-33

parallel hailstones:
A: 310857408788602,297796477288243,210531244259195 @ -31,-31,163
B: 298167626012347,343890784063423,423675682350779 @ 34,34,-34
B: 232442233530894,174047813539401,130419194940021 @ 95,95,411

parallel hailstones:
A: 280473885806842,315439639491991,204057564976545 @ -57,-342,160
B: 321267288021646,422961112834243,399808899121358 @ -29,-174,-103

parallel hailstones:
A: 331706243127232,320892065496394,412514267667047 @ -11,33,-50
B: 351655526618902,246087626101306,327110136190010 @ -37,111,39

parallel hailstones:
A: 297645490835688,299741689345597,267078364272051 @ -22,-66,57
B: 298704283508254,298263525225865,296679721125221 @ -8,-24,27

parallel hailstones:
A: 277029989037226,115116345756124,187440572334869 @ -89,309,220
B: 218075316045983,275317801447459,264760038336981 @ 178,-618,-228

The hailstone should be constrained to the intersection of these planes.

Presumably the hailstone won't hit my input at t=1, t=2, etc.?

The parallel paths define a plane. Find the formula for that plane and all the other hailstones will hit it at a specific time. A plane is defined by three points, which we can get from sampling the two parallel rays. We can derive the equation from these points.

sample:
p1: 18,19,22
p2: 17,18,20
p3: 20,25,34

22 = 18a + 19b + c
20 = 17a + 18b + c
34 = 20a + 25b + c

a = 0
b = 2
c = -16

z = 2y - 16

input:

p1: 298167626012347, 343890784063423, 423675682350779
p2: 298167626012381, 343890784063457, 423675682350745
p3: 232442233530894, 174047813539401, 130419194940021

I feel like I have the solution, there's just a lot of floating point crap.

... actually not. Because in the sample input there _are_ two parallel lines (including the z coordinates) but in my real input there are not. So back to square one :(

If two hailstones are parallel to each other in the XY-plane (part 1), does that place any constraint on the thrown hailstone? I don't think any special constraint.

Can I consider the problem on each axis independently? If it has a unique solution on one axis then it will have to work for the others.

    x = a + b*t

    p1x + v1x*t1 = a + b*t1
    p2x + v2x*t2 = a + b*t2

Let's assume that t1=0, so that a=p1x. That eliminates two variables!

… unfortunately you can't do this! It's all very time-dependent.

    p1x = a
    p2x + v2x * t2 - p1x = b*t2
    p3x + v3x * t3 - p1x = b*t3

So we still have three variables and two equations. The integer-ness puts some other constraints on the problem.

This equation:

    (v2x - b)*t2 = p1x - p2x

implies that the prime factorization of p1x - p2x is relevant. For the sample we have:

    a = p1x = 20
    t1 = 0

    (-2 - b)*t2 = 20 - 19
    (-2 - b)*t2 = 1

That implies that t2 = +/1 and b = -1 or b = -3. Pretty strong constraint!! (In fact b=-3 and t=1.)

    p1: 20, 25, 34 @ -2, -2, -4
    p2: 19, 13, 30 @ -2,  1, -2

    y = p1y + c*t2 = p2y + v2y*t2
    (c - v2y)*t2 = p2y - p1y
    (c - 1)*t2 = 13 - 25 = -12

    (v2x - b)*t2 = p1x - p2x
    (v2y - c)*t2 = p1y - p2y
    (1 - c)*t2 = 13 - 25
    (1 - c)*t2 = -12
    (c - 1)*t2 = 12

So either t2=1, c=13 or t2=-1, c=-11. This is wrong. What's the flaw?

Let's try for the input.

    a = p1x = 230027994633462

    (v2x - b)*t2 = p1x - p2x
    (184 - b)*t2 = 230027994633462 - 213762157019377
    (184 - b)*t2 = 5 * 41 * 79345549337

    (v3x - b)*t3 = p1x - p3x
    (15 - b)*t3 = 230027994633462 - 236440979253526
    (15 - b)*t3 = -6412984620064
    (15 - b)*t3 = -2^5 × 11 × 18218706307

    (v4x - b)*t4 = p1x - p4x
    (272 - b)*t4 = 230027994633462 - 150273374343556
    (272 - b)*t4 = 79754620289906
    (272 - b)*t4 = 2 × 233 × 509 × 1301 × 258449

    (123 - b)*t5 = 230027994633462 - 218468515688398 = 2^3 × 2767 × 522202699

    (-217 - b)*t6 = 230027994633462 - 338621759011922 = 2^2 × 5 × 179 × 691 × 43897907

    230027994633462 - 201589965927467 = 5 × 317 × 106331 × 168737

Start at

    183311641883655, 215117635553996, 110059988469764 @ 148, 155, 275
    183304099697746, 123137916295517, 255584306525969 @ 192, 257, 71

    a = p1x = 183311641883655

    (v2x - b)*t2 = p1x - p2x
    (192 - b)*t2 = 183311641883655 - 183304099697746
    (192 - b)*t2 = 7542185909
    (192 - b)*t2 = 853 × 8841953

So either:

    t2 = 1
    t2 = -1
    t2 = 853
    t2 = -853
    t2 = 8841953
    t2 = -8841953
    t2 = 7542185909
    t2 = -7542185909

    b = 192 - 7542185909 / t2
    192 - b = 7542185909 / t2

The same has to hold for the other axes. So:

    (v2y - c)*t2 = p1y - p2y
    (257 - c)*t2 = 215117635553996 - 215117635553996
    (257 - c)*t2 = 91979719258479
    (257 - c)*t2 = 3 × 13 × 17 × 61 × 12347 × 184199

    257 - c = -91979719258479 / t2
    c = 257 + 91979719258479

That would imply that t2=-1 or t2=+1. Did I really just get so lucky? I'm nervous.

    (71 - d)*1 = 255584306525969 - 110059988469764
    d = 71 - 145524318056205
    d = -145524318056134

If t2=+1:

  b = -7542185717
  c = 91979719258736
  d = -145524318056134

If t2=-1:

  b = 7542186101
  c = -91979719258222
  d = 145524318056276

Intersection for another one:

    px3 + t * vx3 = a + t * b
    t * (vx3 - b) = a - px3
    t = (a - px3) / (vx3 - b)

357365890932622, 177150333541705, 301288545637877 @ -71, 179, 45

    t = (183311641883655 - 357365890932622) / (-71 + 7542185717)

or

    t = (183311641883655 - 357365890932622) / (-71 - 7542186101)

neither is an integer, so something is wrong here.

Back to the equations…

    x = a + b*t

    p1x + v1x*t1 = ax + b*t1
    p2x + v2x*t2 = ax + b*t2

    (p2x - p1x) + v2x*t2 - v1x*t1 = b*(t2 - t1)
    (p2y - p1y) + v2y*t2 - v1y*t1 = c*(t2 - t1)
    (p2z - p1z) + v2z*t2 - v1z*t1 = d*(t2 - t1)
    (-12) + (-2)(3) + 4(4) = (2)*(3 - 4)
    -12 - 6 + 16 = -2 yes

eventually b=-3, c=1, d=2
p1: 20, 25, 34 @ -2, -2, -4  (evenually t1=4)
p2: 18, 19, 22 @ -1, -1, -2  (eventually t2=3)

    (18 - 20) + (-1)t2 - (-2)t1 = b*(t2 - t1)
    (19 - 25) + (-1)t2 - (-2)t1 = c*(t2 - t1)
    (22 - 34) + (-2)t2 - (-4)t1 = d*(t2 - t1)

    -2 - t2 + 2t1 = b*(t2 - t1)
    -6 - t2 + 2t1 = c*(t2 - t1)

    4 = (b-c)*(t2-t1)

This is still a great constraint!

    -12 - 2t2 + 4t1 = d*(t2 - t1)

So maybe the hailstones that are parallel in the xy-plane _are_ useful. We have a set of three here:

p1: 310857408788602,297796477288243,210531244259195 @ -31,-31,163
p2: 298167626012347,343890784063423,423675682350779 @ 34,34,-34
p3: 232442233530894,174047813539401,130419194940021 @ 95,95,411

That gives us:

    (p2x - p1x) + v2x*t2 - v1x*t1 = b*(t2 - t1)
    (p2y - p1y) + v2y*t2 - v1y*t1 = c*(t2 - t1)

    (-12689782776255) + 34*t2 + 31*t1 = b*(t2 - t1)
    46094306775180 + 34*t2 + 31*t1 = c*(t2 - t1)
    58784089551435 = (c-b)*(t2 - t1)
    3^5 × 5 × 47 × 857 × 1201171 = (c-b)*(t2 - t1)

    (p3x - p1x) + v3x*t3 - v1x*t1 = b*(t3 - t1)
    (p3y - p1y) + v3y*t3 - v1y*t1 = c*(t3 - t1)
    (-78415175257708) + 95*t3 + 31t1 = b*(t3 - t1)
    (-123748663748842) + 95*t3 + 31*t1 = c*(t3 - t1)
    -45333488491134 = (c - b) * (t3 - t1)
    -2 × 3 × 47 × 241 × 667041707 = (c - b) * (t3 - t1)

    (p3x - p2x) + v3x*t3 - v2x*t2 = b*(t3 - t2)
    (p3y - p2y) + v3y*t3 - v2y*t2 = c*(t3 - t2)
    (-65725392481453) + 95*t3 - 34*t2 = b*(t3 - t2)
    (-169842970524022) + 95*t3 - 34*t2 = c*(t3 - t2)
    -104117578042569 = (c - b) * (t3 - t2)
    -3 × 7^2 × 13 × 47 × 1159219057 = (c - b) * (t3 - t2)

So from all that we get:

    3^5 × 5 × 47 × 857 × 1201171    = (c - b) * (t2 - t1)
    -2 × 3 × 47 × 241 × 667041707   = (c - b) * (t3 - t1)
    -3 × 7^2 × 13 × 47 × 1159219057 = (c - b) * (t3 - t2)

    3^5 × 5 × 47 × 857 × 1201171    = (vy - vx) * (t2 - t1)
    -2 × 3 × 47 × 241 × 667041707   = (vy - vx) * (t3 - t1)
    -3 × 7^2 × 13 × 47 × 1159219057 = (vy - vx) * (t3 - t2)

The shared factors are 3 and 47, so there are only eight possibilities for (c - b). Each of these eight possibilities would imply values for t2-t1, t3-t1 and t3-t2. Do those imply specific values for t1, t2 and t3? Maybe?

    (p2z - p1z) + v2z*t2 - v1z*t1 = d*(t2 - t1)
    (p3z - p1z) + v3z*t3 - v1z*t1 = d*(t3 - t1)

    (p3z - p2z) + v3z*t3 - v2z*t2 = d*(t3 - t2)  // this is just the difference of the previous two

What if b + c + d = 0? So d = -(b + c). Given t1 we can find t2, t3, so perhaps we just need to find b and t1? And we have two equations?

    d = -(b+c)
    b + c = (c - b) + 2b
    d = -((c - b) + 2b)

    (p2z - p1z) + v2z*(t1 + (t2-t1)) - v1z*t1 = -((c - b) + 2b)*(t2 - t1)
    (p3z - p1z) + v3z*(t1 + (t3-t1)) - v1z*t1 = --((c - b) + 2b)*(t3 - t1)

Plainly we have to have t3 - t2 = (t3 - t2) + (t2 - t1), so maybe these aren't all independent?

     213144438091584  +  -34 *t_2 -  163 *t_1 =  -58784089551435.0 *d
     -80112049319174  +  411 *t_3 -  163 *t_1 =   45333488491134.0 *d

Is using another set of parallel hailstones helpful?

p4: 297645490835688,299741689345597,267078364272051 @ -22,-66,57
p5: 298704283508254,298263525225865,296679721125221 @ -8,-24,27

    (p5x - p4x) + v5x*t5 - v4x*t4 = b*(t5 - t4)
    (p5y - p4y) + v5y*t5 - v4y*t4 = c*(t5 - t4)

    1058792672566 + (-8)t5 - (-22)*t4 = b*(t5 - t4)
    -1478164119732 + (-24)t5 - (-66)*t4 = c*(t5 - t4)

    3176378017698 + (-24)t5 - (-66)*t4 = 3b*(t5 - t4)
    -1478164119732 + (-24)t5 - (-66)*t4 = c*(t5 - t4)

    4654542137430 = (3b - c)*(t5 - t4)
    2 × 3 × 5 × 19 × 127 × 907 × 70891 = (3b - c)*(t5 - t4)

That is another constraint, but it's a kinda complicated one! If I know b and c, though, I can get the specific times.

p4: 331706243127232,320892065496394,412514267667047 @ -11,33,-50
p5: 351655526618902,246087626101306,327110136190010 @ -37,111,39

    (p5x - p4x) + v5x*t5 - v4x*t4 = b*(t5 - t4)
    (p5y - p4y) + v5y*t5 - v4y*t4 = c*(t5 - t4)

    19949283491670 + (-37)t5 - (-11)t4 = b*(t5 - t4)
    -74804439395088 + (111)t5 - (33)t4 = c*(t5 - t4)

    59847850475010 + (-111)t5 - (-33)t4 = 3b*(t5 - t4)
    -74804439395088 + (111)t5 - (33)t4 = c*(t5 - t4)

    -14956588920078 = (3b + c)*(t7 - t6)
    2 × 3^2 × 13 × 23 × 179 × 15525151 = (3b + c) * (t7 - t6)

So we know:

    3b + c divides 2 × 3^2 × 13 × 23 × 179 × 15525151
    3b - c divides 2 × 3 × 5 × 19 × 127 × 907 × 70891
    b - c divides 3 * 47

If c-b=141 then c=b+141 and that would mean:

    (2b - 141) divides 2 × 3 × 5 × 19 × 127 × 907 × 70891
    (4b + 141) divides 2 × 3^2 × 13 × 23 × 179 × 15525151

I think this is a feasible number of possibilities to try, but it just feels kinda heinous.

    print(cMinB, t2t1, t3t1, t3t2, t3t2 + t2t1)
    141 416908436535.0 -321514102774.0 -738422539309.0 -321514102774.0
    ( 213144438091584 ) +  -34 * (t_1 +  416908436535.0 ) -  163 *t_1 = -( 141  + 2b)*( 416908436535.0 )
    ( -80112049319174 ) +  411 * (t_1 +  -321514102774.0 ) -  163 *t_1 = -( 141  + 2b)*( -321514102774.0 )

c + 164.5 = 141
c = -23.5

This gives:

    b = -164.5 and                t_1 = 612135863862
    c = -23.5
    t_2 = 416908436535 + 612135863862 = 1029044300397

That t_1 / t_2 worked! In retrospect I didn't even need to fit a line or figure out t_2 since I assumed that the velocity components added up to zero. The value for `b` can't be right (it should be an integer) but at least the value for `t_1` is good.

In the end we have:

px = 231279746486542
py = 131907658181641
pz = 195227847662645
b = vx = 99
c = vy = 240
d = vz = 188

So actually `vx + vy + vz != 0`! My assumption was wrong but still somehow led me to a correct solution.

The intersection times for the three hailstones that were parallel in the xy-plane are:

t1 = 612135863862
t2 = 1029044300397
t3 = 290621761088

t2 - t1 = 416908436535
t3 - t2 = -738422539309
t3 - t1 = -321514102774

In retrospect I'm curious why I dismissed the system-of-equations approach at the start. You start with six unknowns (position and velocity). As Jeremy said, each hailstone adds one unknown (the collision time) but introduces three constraints. So this should be determined with just three hailstones.

1: 7 unknowns, 3 constraints
2: 8 unknowns, 6 constraints
3: 9 unknowns, 9 constraints

Here's what the system of equations looks like:

    310857408788602 + -31*t_0 = p_x + v_x*t_0
    297796477288243 + -31*t_0 = p_y + v_y*t_0
    210531244259195 + 163*t_0 = p_z + v_z*t_0
    298167626012347 +  34*t_1 = p_x + v_x*t_1
    343890784063423 +  34*t_1 = p_y + v_y*t_1
    423675682350779 + -34*t_1 = p_z + v_z*t_1
    232442233530894 +  95*t_2 = p_x + v_x*t_2
    174047813539401 +  95*t_2 = p_y + v_y*t_2
    130419194940021 + 411*t_2 = p_z + v_z*t_2

So I guess it's not a _linear_ system of equations. I feel like Wolfram could solve this, but it's more than the max characters it will let you submit via the web form.

My logic for concluding that `(vy - vx) | 3*47` holds up in light of the true values (in reality `vy - vx = 3 * 47 = 141`). Given the values that this implies for `t2 - t1` and `t3 - t2`, can I figure out the actual times using the z-coordinates?

    p1z + t1 * v1z = pz + vz * t1
    p2z + t2 * v2z = pz + vz * t2

    p2z + (t1 + (t2 - t1)) * v2z = pz + vz * (t1 + (t2 - t1))
    p3z + (t1 + (t3 - t1)) * v2z = pz + vz * (t1 + (t3 - t1))

So in theory yes, but in practice these are nonlinear equations:

    p1z +               t1*v1z = pz +              vz * t1
    p2z + (t2-t1)*v2z + t1*v2z = pz + (t2-t1)*vz + vz * t1
    p3z + (t3-t1)*v3z + t1*v3z = pz + (t3-t1)*vz + vz * t1

    k1 = pz +              (vz - v1z) * t1
    k2 = pz + (t2-t1)*vz + (vz - v2z) * t1
    k3 = pz + (t3-t1)*vz + (vz - v3z) * t1

    k1 = pz +            - v1z*t1 + vz*t1
    k2 = pz + (t2-t1)*vz - v2z*t1 + vz*t1
    k3 = pz + (t3-t1)*vz - v3z*t1 + vz*t1

We know t2-t1, t3-t2, t3-t1, pXz and vXz, need to solve for `t1`, `vz` and `pz`. Or really just `t1`. Subtracting these equations gives:

    k2 - k1 = (t2-t1)*vz + (v1z-v2z)*t1
    k3 - k1 = (t3-t1)*vz + (v1z-v3z)*t1

Since we know `t2-t1` and `t3-t1`, these are just linear equations for `t1` and `vz`.

    (k2-k1)(t3-t1) = (t2-t1)(t3-t1)vz + (v1z-v2z)(t3-t1)t1
    (k3-k1)(t2-t1) = (t2-t1)(t3-t1)vz + (v1z-v3z)(t2-t1)t1

           (k2-k1)(t3-t1) - (k3-k1)(t2-t1)
    t1 = -----------------------------------
         (v1z-v2z)(t3-t1) - (v1z-v3z)(t2-t1)

    k1 = p1z
    k2 = p2z + (t2-t1)*v2z
    k3 = p3z + (t3-t1)*v3z

… this works perfectly (for both t1 and vz). So why did my approach from earlier with an incorrect assumption also work? I guess by shifting each equation the same amount it didn't change the collision time but did change the velocity? I still feel like I got lucky.

Another idea is to assume that vx/vy/vz are all small. If you assume that they're all less than 1000 (like the input) then that's only 8 billion possibilities to try. And each check should be very fast. … or maybe you can even check them independently?

If you know vx, vy, vz, how do you figure out px, py, pz, t1, t2, t3?

    p1z + v1z * t1 = pz + vz * t1
    p1y + v1y * t1 = py + vy * t1
    p2z + v2z * t2 = pz + vz * t2
    p2y + v2y * t2 = py + vy * t2

That's four equations, four variables, and it's linear. Can the hailstones that are parallel in the xy-plane simplify this? For those, v1x=v1y and v2x=v2y.

    p1x + v1x * t1 = px + vx * t1
    p1y + v1x * t1 = py + vy * t1
    p2x + v2x * t2 = px + vx * t2
    p2y + v2x * t2 = py + vy * t2

    p1x = px + (vx - v1x) * t1
    p1y = py + (vy - v1x) * t1
    p2x = px + (vx - v2x) * t2
    p2y = py + (vy - v2x) * t2

    p2y - p1y = (vy - v2y) * t2 - (vy - v1y) * t1
    p2x - p1x = (vx - v2x) * t2 - (vx - v1x) * t1

This is two equations in two variables! This doesn't depend at all on the hailstones being parallel. Solving it gives:

    (p2y-p1y)(vx-v1x) = (vy-v2y)(vx-v1x)t2 - (vx-v1x)(vy-v1y)t1
    (p2x-p1x)(vy-v1y) = (vx-v2x)(vy-v1y)t2 - (vy-v1y)(vx-v1x)t1

         (p2y-p1y)(vx-v1x) - (p2x-p1x)(vy-v1y)
    t2 = -------------------------------------
          (vy-v2y)(vx-v1x) - (vx-v2x)(vy-v1y)

    t1 = ((vy - v2y)*t2 - (p2y - p1y)) / (vy - v1y)

    px = p1x + (v1x - vx) * t1
    py = p1y + (v1y - vy) * t1
    vz = (p2z + t2*v2z - p1z - t1*v1z) / (t2 - t1)
    pz = p1z + (v1z - vz) * t1

If the times are both integers, then this is a candidate. To verify it, pick a third stone and check whether they collide. For boht the sample and my input, this was unique. Since you only need to search in the x/y plane, this is very fast: less than 0.1s for both parts in a debug build.
