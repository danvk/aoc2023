# Advent of Code 2023

This time in Zig?

I know about Zig because of Bun. Zig seems fast, I think it's a C (rather than C++) replacement.

## Day by day

## Day 25 (8738 / 5426)

sample: 15 components / 33 connections
input: 1453 components / 3236 connections

If there are 4+ independent connections between two components then they must be part of the same cluster.

There are a few of these in a simple form in the sample input but none in my puzzle input. Darn.

Plugging the sample graph into graphviz makes it pretty obvious what the clusters are! But this runs out of memory for my input.

New idea: find the shortest paths between all modules, count which paths they use. Maybe the top ~100 are the ones to consider?

Also maybe I should just switch to Python.
NetworkX has a `k_edge_components` that solves the problem. So I guess I should read about how that works?

https://dreampuf.github.io/GraphvizOnline/#graph%20G%20%7B%0A%20%20bvb%20--%20xhk%0A%20%20jqt%20--%20xhk%0A%20%20bvb%20--%20hfx%0A%20%20ntq%20--%20xhk%0A%20%20frs%20--%20qnr%0A%20%20lsr%20--%20rsh%0A%20%20lsr%20--%20rzs%0A%20%20hfx%20--%20rhn%0A%20%20qnr%20--%20rzs%0A%20%20cmg%20--%20nvd%0A%20%20nvd%20--%20pzl%0A%20%20frs%20--%20lhk%0A%20%20hfx%20--%20pzl%0A%20%20pzl%20--%20rsh%0A%20%20cmg%20--%20qnr%0A%20%20rsh%20--%20rzs%0A%20%20jqt%20--%20nvd%0A%20%20hfx%20--%20xhk%0A%20%20cmg%20--%20lhk%0A%20%20cmg%20--%20rzs%0A%20%20rhn%20--%20xhk%0A%20%20hfx%20--%20ntq%0A%20%20bvb%20--%20ntq%0A%20%20lsr%20--%20pzl%0A%20%20jqt%20--%20rhn%0A%20%20nvd%20--%20qnr%0A%20%20frs%20--%20rsh%0A%20%20lhk%20--%20lsr%0A%20%20frs%20--%20lsr%0A%20%20bvb%20--%20cmg%0A%20%20jqt%20--%20ntq%0A%20%20bvb%20--%20rhn%0A%20%20lhk%20--%20nvd%0A%7D

A few days later I implemented a direct solution in a Jupyter notebook. My idea earlier about "4+ independent connections" was the right way to do it. I just had to allow more complex connections than A -- (x) -- B, which was annoying to do in Zig. My Python code wound up being pretty simple: for each edge, repeatedly find the shortest path between the two nodes and remove the edges along that path. If you wind up with 4+ connections, then they're in the same cluster. You can represent this by adding a connection between them in a separate graph, which eventually has two components. Maybe I should try to implement this in Zig for completeness.

## Day 24 (7437 / 6407)

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

That t_1 / t_2 worked! In retrospect I didn't even need to fit a line or figure out t_2 since I assumed that the velocity components added up to zero.

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

## Day 23 (8738 / 5426)

Part 1: straightforward
Part 2: The search is bogging down, there seem to be many different ways to reach the end state in the same number of steps.

I'm at 2250 steps after ~5 minutes, and there are 9406 non-rock squares. But this seems to be getting slower (like a quadratic) so I'm not optimistic about it terminating.

5000 is too low.

One idea is that, from looking at the input, there aren't many squares where you have a choice. If I could fast-forward through the (unique) path between these, it might be a big speedup.

sample: n=211, forced: 204, choice: 6, junction: 1
input: n=9404, forced: 9370, choice: 18, junction: 16

For the sample there are only 9 interesting nodes. For the input there are 36. This should be feasible.

Sample: found 24 connections
Input: found 120 connections

- Start: 9:01 AM
- ⭐️: 9:39 AM
- ⭐️⭐️: 10:27 AM

## Day 22 (7437 / 6407)

Pretty straightforward today! The one trick was to sort by bottom z before dropping. I had an off-by-one on my "brick intersection" code that slowed me down, and it took some head scratching to figure out exactly what they wanted me to compute at the end of part 1. I was about to implement the "chain reaction" code for part 2 before realizing it was just part 1! I looped over the bricks, disintegrating each one in turn and calling my `fall1` function to see how many would drop. A bit slow but definitely correct.

I was happy that I skipped a few obvious optimizations today that proved unnecessary. My brick intersects just does an N^2 loop, for example. With an optimized build, I get both answers in ~25s. (Switching to an interval-based check drops the runtime to ~6s.)

- Start: 8:35 AM
- ⭐️: 9:44 AM
- ⭐️⭐️: 9:58 AM

Why is a void context `{}` and not `.{}`?

### Day 21 (12914 / 4624)

Part 1 was straightforward. The direct implementation for part 2 is slow as molasses. I don't think speeding up the direct implementation is worthwhile.

I noticed that the boundary of the tile was devoid of rocks. This made me think that there might be a pattern to how each tile behaves. I printed out the central tile for part 2 and noticed that both the sample (quickly) and my input (more slowly) eventually bounced back and forth between two states. Half the boundary squares are visited in each and it flips back and forth between which half.

I wrote some code to hash the state of a tile and used this to detect the periodicity (using part 1). After a tile _and its neighbors_ (this was tricky to realize) are in one of the terminal states, you can remove it from consideration. This turns a quadratic expansion of tiles from step to step into a linear one. This let me run the sample all the way to n=5000 and my input out to n=2000 in ~4 minutes.

But I needed n=26501365, so this clearly wasn't good enough. I copy/pasted the counts for each step from the sample into a spreadsheet and started looking at derivatives. Something stood out about the second derivative: every 11th step it was exactly 2. The other values in between varied, but only by small amounts. And these amounts were fixed. So the pattern is that the second derivative comprises 11 distinct linear sequences.

I pasted the counts for my input into the sheet and looked for a similar pattern. The number 4 appeared in the second derivative every 131 steps. So that was my sequence. It took a little fiddling to get the counts exactly right, but that gave me my answer. Woo!

Best finish so far this year, and at 11 AM. This must be a pretty tough one in the grand scheme of AoC puzzles.

In retrospect, my "frozen" optimization was totally unnecessary. I'm able to run >1000 steps on my input before it bogs down, and you only need a few hundred steps to see the pattern as I described it here.

- Start: 8:25 AM
- ⭐️: 8:44 AM
- ⭐️⭐️: 11:01 AM

Ideas:

- Look for a pattern in the deltas between steps
- Do the interior tiles eventually settle into a pattern?

There are no rocks on the edges, either in the sample input or in my input. I wonder if that's helpful? It can't be a coincidence. It means that eventually you'll get into a state where the edges are flip-flopping.

The central tile in the sample quickly (less than 20 steps) settles into a flip-flop pattern where half the border tiles are set on each step.

My input does the same thing, though it takes longer. What happens for other tiles? They start in a different state, but eventually they get to the same flip-flop pattern.

So maybe I should detect when a tile is "full" and freeze it. That way I'm only considering the fringe, which should be lower-dimensional.

sample:

13: day21.TileHash{ .hash = 17606044957879186035, .count = 42 }
14: day21.TileHash{ .hash = 18010981749530968007, .count = 39 }

input:

128: day21.TileHash{ .hash = 3360108315240557322, .count = 7577 }
129: day21.TileHash{ .hash = 7951923478988671822, .count = 7596 }

This may _still_ be too slow. I also can't entirely remove frozen tiles from the calculation since they can still affect non-frozen tiles around them.

There _is_ a clear pattern in the second derivative. So maybe I can extrapolate from this? Yep! That worked. The period for the sample is 11 whereas the period for my input is 131, but the structure is the same.

### Day 20 (10029 / 7219)

The first part was fine, just took some care. I wanted to set up pointers to "next" nodes, but in retrospect that was a waste of time. I should have just used a hash map, I wound up needing it anyway. I could have used a union type since the two types of modules are so different, but I wound up just mushing the two together in a struct.

Part 2 was extremely frustrating. My part 1 solution got to 30-40M button presses (optimized) before crashing. I realized this was because I was using an arena allocator and a `Queue`, so I was never deallocating anything. Switching to the GPA fixed the crash but made everything 5-10x slower. I changed to using an ArrayList instead and it was similarly slow. Then I gave the ArrayList a capacity of 1000 from the get-go and it was within a factor of 2x of the original. So there's an insight there I guess.

I let my code run through ~300M button presses but it didn't terminate. So I figured I needed to do something smarter. I looked at the input and saw that there was a single node leading into the output `rx` node. It had four inputs. So I printed all pulses leading into these. This quickly led to the realization that they usually got "low" pulses but got "high" signals periodically. I calculated the periods, plugged them into an LCM calculator and got out a number around 222 trillion.

AoC said this was too low, though. I tried adding one and doubling, it was still greater than N+1 but was less than 2N. I thought maybe there was a pattern to whether there were additional signals in the queue that might block the final low pulse. That does sometimes happen. I spent some time tracking down exactly when. It seemed to be something to do with evens and odds. But this would only ever double the number of cycles.

I was at a loss. I started drawing out the graph but it seemed really messy. I still had the LCM calculator open, and I noticed that one of the numbers didn't look right. Sure enough, I had a typo! I plugged the right numbers in and got my answer. So I'd wasted the previous ~hour. Grrr. Lesson learned: always copy/paste, never type!

- Start: 8:50 AM
- ⭐️: 9:58 AM
- ⭐️⭐️: 11:51 AM

crashed mysteriously after 30,731,000 iterations
or after 42,100,000

Using the raw (not arena) allocator is much slower:
1,000,000 17s

I guess because it's actually allocating and freeing memory? Setting an init capacity of 1000 for the ArrayList makes it go much, much faster:

1,000,000 3s

Hopefully this will go faster since it's not leaking memory. My next option is to actually figure out what my sample is computing.

100,000,000 308s
305,000,000 950s

&kz -> rx

&sj -> kz
&qq -> kz
&ls -> kz
&bg -> kz

sj:
&hb -> sj, mr, rz, qg, pr

qq:
&hf -> rg, vl, tq, qq, mv, zz

ls:
&dl -> hn, pj, ls, mn, jg, sv

bg:
&lq -> bg, kk, dz, xr, lh, fm

the next level down there are flip-flop modules
one idea is to track whenever sj, qq, ls and bg send pulses and look for a pattern.

bg gets a low signal every 3739 presses
ls gets a low signal every 3797 presses
sj gets a low signal every 3919 presses
qq gets a low signal every 4003 presses
LCM = 222,377,836,299,437
LCM = 222377836299437

this is too low!

222377836299438 is also too low

222718819437131

... everything below this turns out to be irrelevant. I typed one of the four numbers incorrectly into the online LCM calculator and then wasted an hour trying to track down other patterns. Sigh.

    - 3739 3797 3913 4003
    + 3739 3797 3919 4003

I wonder if the "deliver a _single_ pulse" is relevant?

kz needs to send a low pulse to rx.
that happens when all its inputs are high.
i.e. sj, qq, ls and bg all send high

kz receives multiple pulses from each of those four inputs after each button press.
Maybe there's more structure here? Maybe each index of press has a period?

3739 12 0: bg high
3797 13 3: ls high
3919 14 1: sj high
4003 16 3: qq high

7478 12 0: bg high
7594 13 4: ls high
7838 16 1: sj high
8006 19 2: qq high

14196983: bg high, sj low, qq low, ls high

The order is always bg, sj, qq, ls, then some others

----

broadcaster -> xr, mr, rg, sv

There are tons of low pulses sent to sj, qq, ls and bg on every press.

I'm very confused. I can predict how many presses it will take to get any combination of bg, ls, sj and qq to activate. They're all set to high one after the other.

Maybe there's also a period to the number of pulses sent? If the fifth signal to kz arrives too early, it may not have a chance to process the signal itself before it gets reset to low.

444755672598874 (my guess times 2) is too high.

The previous paragraph seems correct, there's an interesting structure to whether there's more signals in the queue. So far as I can tell it sometimes flip/flops between "clear" and "more" with even/odd and sometimes it's just "more".

- It starts with odd=clear, even=more
- After the first high (3739 presses) there are always more
- This persists until after 4003, after which it resets to even=clear, odd=more
- After going through 7478 (3739*2) presses there are always more
- After 8006 (4003 * 2) it resets to odd=clear, even=more

So if (n-1) % 3739 < (n-1) % 4003 then it will be "more".
Otherwise if floor(n/4003) % 2 != n % 2 then it's "clear"

But this suggests that 444755672598874 is the answer, but it's too high.
It's also not 444755672598873.

I'm stumped. Maybe I need to draw out the network? 58 modules.

I've also been noticing (the past ~week) that zls sometimes gets very slow. Slow enough that I can see it process my typing character-by-character, slower than I type. And sometimes it's slow enough that I hit Cmd-S, go back to the terminal and run `zig build` before the Save command has actually committed. Restarting zls usually fixes this, at least for a bit.

I wish there were more options for the `{any}` formatter in Zig. Even just being able to print `[]const u8` as a string rather than an array of ASCII characters would be helpful.

... maybe you _can_ give types a printer? YES! This works great:

```zig
const Pulse = struct {
    from: []const u8,
    to: []const u8,
    val: PulseType,

    pub fn format(p: Pulse, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.fs.File.Writer) !void {
        _ = fmt;
        _ = options;
        try std.fmt.format(writer, "{s} -{s}-> {s}", .{ p.from, if (p.val == .low) "low" else "high", p.to });
    }
};
```

This is the _only_ mention I have ever seen of this:
https://github.com/ziglang/zig/blob/e7ac05e882fa4290af4a41e9cae63105bcacb283/lib/std/fmt.zig#L65

### Day 19 (14116 / 8346)

part 2: only values that appear in a rule are worth checking.
If I treat each of xmas distinctly, I have 3.4B combos to check. Probably OK!

Another way to do this would be to track the ranges of values that would go through each branch of each rule. I wonder if that would blow up more or less? Probably less!

For `<`: the result changes when you hit `num`.
For `>`: the result changes when you hit `num+1`.

This ran faster than I expected: ~4 minutes total, and just fast enough that I could submit my answer before my plane took off! The tricky part was the `num` vs. `num+1` thing above.

It seems like most people took the interval approach, which apparently is much faster. OK, I implemented that and yes, it is a cleaner and faster solution! You never wind up with more than a few hundred cubes to keep track of.

- Start: 7:30 AM?
- ⭐️: 7:55 AM
- ⭐️⭐️: 8:58 AM

### Day 18 (20160 / 15394)

For part 2, the sample has coordinates that go 0-1186328.
Unless there's a corner with the given y-coordinate, it should contribute the same area as the previous row. Something similar holds for x-coordinates, though this might be a little trickier to pull off in practice since you care whether an unspecified square is `-` or `.`.

Area calculation is _very_ slow! ~30 rows/sec.

Pick's theorem for sample:

- Area of polygon = 42
- Perimeter = 38

A = i + b/2 - 1
=> i = A - b/2 + 1
=> i = 42 - 38/2 + 1
=> i = 42 - 19 + 1
=> i = 42 - 18
=> i = 24

So that works great! I have a ~30 minute process calculating the area that I think will work. I'm reluctant to build a new binary while that's running, but this is a great backup in case that gives me the wrong answer.

part 2: 199993750 + 97873903755970 = 97874103749720
./zig-out/bin/main day18 day18/input.txt  1979.20s user 7.37s system 99% cpu 33:10.91 total

97873903755970
count: 199993750
area: 289011596
i = 289011596 - 199993750 / 2 + 1

So that doesn't work at all!
My area calculation must be wrong, lots of people on reddit used this approach.

… I implemented this again the next day and got the right answer. So what was wrong before? I had to add some `@intCast`s to make it work, errors that I don't remember getting before. Looking at my diff, I think two things happened:

1. I built the shoelace version in optimized mode, so the integer overflow was not caught at runtime.
2. Somehow the Zig compiler wasn't able to detect the possible overflow when I inlined my loop, but _was_ able to detect it when I factored out a shoelace function.

The former is my fault but the latter seems like a Zig bug. In any case, the lack of an error probably cost me ~1 hour yesterday ☹️.

- Start: 7:00 PM
- ⭐️: 7:40 PM
- ⭐️⭐️: 9:07 PM

### Day 17

I wish I'd implemented a generic flood fill on a previous day. Oh well, now I mostly have it! My part 1 solution worked great for part 2.

I took this as a cue to write a generic Dijkstra implementation, since that's come in handy for many puzzles in the past. Since Zig doesn't have closures, the key to making this work is putting everything that would have been in your closure into a "context" parameter. I think this is equivalent to a closure, just more boilerplate. Why is Zig so anti-closures?

I used an ArrayList for my initial implementation, but swapping it out for a `std.PriorityQueue` cut the runtime by ~60% (12s->5s for both parts).

### Day 16

This is pretty confusing. Why am I segfaulting?

    Segmentation fault at address 0x104b7c024
    Panicked during a panic. Aborting.

I guess mutating an ArrayList as you iterate it is trouble. I suppose that makes sense -- appending might change what `arraylist.items` points to.

I had to introduce a cache (I think there's an infinite loop). The trick of removing array elements from the end (so that you don't invalidate indices) came in handy.

7264 is too low

I had a copy/paste bug in part 2 where I was setting the directions wrong for the left/right side. I also had an off-by-one where I was dropping the corners, but that probably didn't matter.

### Day 15 (29290 / 25436)

Today was straightforward. Part 2 wasn't hard and didn't require much thought, just care to follow the instructions.

Definitely convenient to read the whole file into memory and then represent strings as slices into that since you don't have to worry about allocating or freeing those strings.

- Start: 2:11 PM
- ⭐️: 2:18 PM
- ⭐️⭐️: 2:51 PM

### Day 14 (28144 / 21743)

Not too bad. You can rotate the grid clockwise to re-use your "shift" implementation from part 1. Then you just have to find a cycle on part 2.

- Start: 4:38 PM
- ⭐️: 4:51 PM
- ⭐️⭐️: 5:33 PM

Going at ~100,000 spins/sec for the sample. That would translate to 1000 second to get to 1B, not so bad! But there must be a pattern.

0 100982 65
1 100983 63
2 100984 68
3 100985 69
4 100986 69
5 100987 65
6 100988 64

period of length 7

My sample goes at ~1,000 spins/sec. So that would take a long time to get to one billion! Hopefully the cycle is shorter than 1000, which is all I'm printing out.

 0 100008 84239
 1 100009 84206
 2 100010 84202
 3 100011 84191
 4 100012 84210
 5 100013 84220
 6 100014 84237
 7 100015 84244
 8 100016 84276
 9 100017 84294
10 100018 84328
11 100019 84341
12 100020 84341
13 100021 84332
14 100022 84332
15 100023 84314
16 100024 84299
17 100025 84268

cycle length is 18

### Day 13 (23195 / 23061)

I found today incredibly annoying. Lots of off-by-ones and potential to misunderstand the problem (which I certainly did!). I should probably write a transpose function for grids.

44521 is too high
44507 is too high

I was looping from (0..maxX) instead of (0..maxX+1) so I found mirrors that shouldn't have been there and was confused about what to do when there was both a vertical and horizontal mirror.

Have some kind of problem with part 2 also. Interesting that my `printGrid` from day 22 in 2017 took an allocator. I definitely wouldn't do that now!

Ah, I think I need to specifically exclude the previous mirror?

That gets me the right answer for the sample, but gives me 23236 for my input which is too low. It looks like I'm not finding a smudge correction for some inputs.

-> I think I need to exclude the original flip at a lower level than I am.

### Day 12 (17515 / 9282)

Part 1: brute force (try both possibilities for ?). I did this by enumerating all the numbers from 0..2^n and using bit operations, one of my favorite tricks. There were at most 18 `?` chars and 2^18 isn't that many.

Part 2: That clearly wasn't going to work. I tried going recursively character by character but this was too slow (in retrospect it may have worked if I added memoization). Instead I split the list of numbers in half and tried each possibility for the split point in the pattern (by setting those two characters to . and #, as the pattern allowed). I initially just set the middle character to `.` but this results in double-counting. Once you'd picked a split, you can recur and multiply the left and right counts. The beauty of this is that you don't have to enumerate every possible solutions.

Definitely the trickiest so far and my best finish so far. I hopped on the in-flight WiFi to submit my answer for part 2 (we're over the Caribbean on our way to Costa Rica).

It looks like my initial solution to part 2 was just fine, I only needed to memoize it. That's what the #1 solution did (in TypeScript!): https://gist.github.com/Nathan-Fenner/781285b77244f06cf3248a04869e7161 I'm pretty proud of coming up with what seems like an unusual but good solution for part 2.

- Start: 8:32 AM
- ⭐️: 9:02 AM
- ⭐️⭐️: 11:35 AM

Some notes from debugging follow…

`???????#??.?#????##? { 1, 2, 3, 3, 2 }`

I guess another way to parameterize this is where you put each `.###.` There's more flexibility in each of those, but maybe fewer of them than `?`s? There are at most 6 numbers, which would become 30 after expansion.

This could be done recursively: if you have a contradiction at the start then you're done and you return zero. If you have a `?` then either you make it a `#` or a `.`, and reduce the number by one. Hopefully the number sequence is enough to prune the search space dramatically.

4,1,1,4,1,1,4,1,1,4,1,1,4,1,1
????.#...#...????.#...#...????.#...#...????.#...#...????.#...#...

OHH! Separate by `?`. Yuck! Even messier.

My recursive implementation works great, but it still seems a little bit too slow on my input. This is the first really problematic one:

    .#??????????????????.#??????????????????.#??????????????????.#??????????????????.#????????????????? { 1, 4, 3, 2, 2, 1, 4, 3, 2, 2, 1, 4, 3, 2, 2, 1, 4, 3, 2, 2, 1, 4, 3, 2, 2 }

Maybe if I implement one of the filters, it will help prune the search space enough?

If not, another option would be to split the list of ints in half. You know a minimum length for each half and they must have a `.` in between. So try each possibility. The beauty here is that you split the string in half and you can _multiply_ the number of possibilities in each half. So you can get a big number out without having to actually try each possibility one-by-one.

That is enough to get by that particular example. Now I'm stuck on:

     ????????##????????????????##????????????????##????????????????##????????????????##??????? { 2, 1, 5, 2, 2, 1, 5, 2, 2, 1, 5, 2, 2, 1, 5, 2, 2, 1, 5, 2 }

This went for ~4 minutes without finishing in an optimized build.  I'm pretty enamored of my split-in-half solution, so I think I'm going to implement that.

???.###????.###?? ? ?.###????.###????.###

???.###????.###??|?.###????.###????.###
???.###????.###???|.###????.###????.###

  ###??? / { 3, 1 }

  3:### / { 3 } -> 1
  3:?? / { 1 } -> 2

    ### . .#
    ### . #.

  4:###? / { 3 } -> 1
  4:? / { 1 } -> 1
  5:###?? / { 3 } -> 1

So there's some double-counting here. Can I say that the splits must end/start with a `#`? Maybe we can say that the right one must start with a `#`. YES!

Is there a canonical way to memoize a function in Zig?

### Day 11 (22119 / 19890)

This was a welcome reprieve after yesterday. The trick is just to shift the coordinates of the galaxies, rather than trying to construct an enormous grid. The distance is just manhattan distance, regardless of how the AoC site chooses to display it. I had an off-by-one error on part 2: you add 999,999 to the coordinates, not 1,000,000.

- Start: 7:05 AM
- ⭐️: 7:19 AM
- ⭐️⭐️: 7:22 AM

### Day 10 (20029 / 10351)

Definitely the most finnicky so far. Part 1 just required some care and careful reading of the instructions. Part 2 was very finnicky. I never came up with a way to tell which direction to move around the loop, I just figured out which neighbor to start with for each sample and my input.

I'd hoped I wouldn't have to look at the corner pieces. And I'd hoped I wouldn't have to do flood fill in addition to finding the fringe, but no dice.

Zig note: you use `std.meta.eql` to compare structs, not `==`.

- Start: 6:19 AM
- ⭐️: 7:00 AM
- ⭐️⭐️: 8:00 AM

Looking over the reddit solutions, the clever way to do part 2 is to count parity across a row as you cross pipes. If you cross once, you're in, twice you're out, etc. The tricky bit is that L---7 and F---J should also count as crossings. Some people also blew up the grid 2-3x so that the interior was completely connected. I like how part 2 inspired so many different solutions.

I asked about extracting the min/max value from a hash map generically in Zig: https://stackoverflow.com/q/77636941/388951

### Day 9 (44665 / 43697)

This was wildly easy compared to yesterday. I wonder if Eric is being nice to us on the weekend? My instinct to recursively extrapolate the next number worked great on part 1 and then part 2 just requires reversing the list and using your solution from part 1.

- Start: 4:37 PM
- ⭐️: 4:45 PM
- ⭐️⭐️: 4:47 PM

### Day 8 (35164 / 26872)

Using a hash map was a real mistake for part 2 -- I assumed there would be some fanout of ghosts, but really you'll always have a fixed number of ghosts and using hash maps in Zig complicates absolutely everything.

Killed after 110,440,000 steps.
In optimized mode, it ended with "killed" after 744,400,000 steps. I don't know what that means.

There are six starting ghosts. There are 790 nodes, so they must wind up in cycles. Maybe I should just try to find the cycles.

Something is wrong. It seems my ghosts enter cycles that never hit an end state (ending with a Z)?

... it's that a "cycle" also requires you to be at the same position in the R/L line.

Printing out the number of steps to each end state for each ghost shows that they're all in perfect cycles. Calculating the LCM for all those cycle lengths gives the answer, which was around 21B. So my program would have had to run for a pretty long time to find it!

This one required more thought than I was expecting for day 8!

With a more efficient brute force algorithm for part 2, I can do 687,000,000 steps in 60s, so it would take ~30 minutes for my program to find the answer directly.

Zig thought: maybe reading the whole input and splitting is better than reading line-by-line since then you have one canonical place where each string slice is stored that will never go away for the life of the program (so less copying).

### Day 7

- How do I write a literal `[5]u8`?

### Day 6 (61931 / 60637)

Very easy compared to yesterday. I guess if you don't write the closed-form solution for part 1 then part 2 might be slow / intractable. Once again, I had to `s/u32/u64/g` for part 2. Nice that this just works!

We did a birding trip in Miami today starting at 6 AM so I wasn't able to do Advent of Code until after we got back home.

- Start: 5:41 PM
- ⭐️: 5:51 PM
- ⭐️⭐️: 5:56 PM

### Day 5 (33605 / 15495)

1.8B seeds for part 2… maybe that's doable? Yes! Took ~2.5 minutes to run with `-Doptimize=ReleaseFast`. Thanks, Zig!

I reworked my solution to use an Interval class. It's kinda hairy but does at least run really fast: 79ms vs. 2.5 minutes.

In retrospect it might have been easier to split the number line into disjoint intervals. You only have to care about numbers that actually appear somewhere in the input, and there are only at most a thousand or so of those. But hopefully my `Interval` type will be useful on some future day.

TODO: look at r/adventofcode, is there a more clever, simple solution?

- Start: 7:28 AM
- ⭐️: 7:43 AM
- ⭐️⭐️: 7:52 AM

### Day 4 (48615 / 38383)

No point in using a hash map for such a small number of winning numbers on each card. Part 2 was more interesting, I like the pattern of using a slice view of a fixed-length buffer as a poor man's queue.

I factored out a `splitAnyIntoBuf` helper that can split strings along multiple delimiters. I feel like that's come up a few times already.

- Start: 7:28 AM
- ⭐️: 7:35 AM
- ⭐️⭐️: 7:47 AM

### Day 3 (45310 / 36647)

These continue to be more involved than I'd expect from the first week. In part 2 I looked in each of the eight directions from each `*`. A possible issue I had to avoid was double-counting, i.e. if the same number were both north and northwest of a `*`. I was worried about boundary conditions until I realized I could completely avoid them by padding the input.

The lack of closures and the attention you have to pay to allocation and errors definitely rule out certain ways of separating concerns that I'd otherwise reach for. For example fetching all the neighbors for a cell, or mapping over them.

- Start: 9:35 AM
- ⭐️: 9:59 AM
- ⭐️⭐️: 10:14 AM

### Day 2 (49232 / 45787)

My `splitIntoBuf` and `extractIntsIntoBuf` helpers continue to be very efficient at parsing AoC input. I'm intrigued by the suggestion (on r/adventofcode) that the inputs and problem phrasing will be more convoluted this year in an attempt to throw off AI solvers.

### Day 1 (64698 / 40279)

I forgot it was December! I reused my 2017 setup (pretended that today was a 26th day of 2017) to get an answer, then cleaned up after. Part 2 was definitely a curveball. I checked for each of the nine digit strings at each position with `std.mem.eql`.

Actually taking time to read through the prompt, I realized that I hadn't considered the case that there was only one digit in an input line. But my code just happened to do the right thing (that one digit is both first and last). Ryan pointed out that he got tripped up by "twone", which wasn't even something I'd considered.

Also `std.mem.startsWith` is slightly simpler than `std.mem.eql` here.

## Other Ziggers

- https://github.com/LukeMinnich/advent-of-code-2023
- https://github.com/ManDeJan/advent-of-code/tree/master/src/2023
- https://github.com/iskyd/aoc-zig
- https://github.com/LeperGnome/AoC2023

## Questions I still have about Zig

- Is there anything like upper bounds on `anytype`? Is this C++-style "substitution failure is not an error"?
- Is `zls` just known to be really bad?
- You need an `Allocator` to allocate memory. But what's the underlying mechanism here? Is `Allocator` special? How is `GeneralPurposeAllocator` implemented?
- Zig has lots of numeric types that don't correspond to anything in hardware, e.g. `u5`. How do these work?
- Why are they so opposed to destructuring assignment? It seems like it would really encourage consistent naming, especially with imports.

Nitty gritty questions:

- Why is it `expectEqual(expected, actual)` when the other way around works so much better from a type inference perspective?

## Observations

- An Arena allocator has some similarities to Rust-style lifetime annotations.
- The pattern of passing allocators (which usually implies `try`) pushes you towards allocator-free patterns, e.g. for parsing.
- `comptime` makes a lot of sense. Why have a separate language for metaprogramming?
- Inferred error return types mostly let you not think about errors. But this doesn't really feel that different than exceptions.
- "Detectable undefined behavior" or whatever seems like a useful concept.
- Slices are nice. Especially in the context of strings, they feel like a revival of the "Pascal string" as opposed to the null-terminated C string.
- Understanding that everything is passed by value and copied (including structs) was the key insight for understanding Zig. A slice is a struct with a len and a ptr, and these are copied when you assign to a slice. I think I had a similar insight about either Go or Rust in the past.
- Hash maps are just hard to use in Zig since you have to think about who owns the keys.
- It's interesting that structs can have private functions but not private fields. I guess this makes some sense since you have to be able to copy the bytes of a struct to use it.

## References

- https://avestura.dev/blog/problems-of-c-and-how-zig-addresses-them
- https://www.huy.rocks/everyday/12-11-2022-zig-using-zig-for-advent-of-code#splitting-a-string
- https://www.forrestthewoods.com/blog/failing-to-learn-zig-via-advent-of-code/
- https://cohost.org/strangebroadcasts/post/542139-also-failing-to-lear

## Zig Docs notes

You can zero-initialize a buffer like this. Also news to me that you can copy a slice this way, though I guess it makes sense.

    var buffer = [_]u8{0}**256;
    const home_dir = "C:/Users/root";
    buffer[0..home_dir.len].* = home_dir.*;

In Debug mode, Zig writes 0xaa bytes to undefined memory to help debugging (i.e. by catching use of `undefined`).

If you use `@This()` at file scope, it refers to some sort of file struct.

You can go all the way up to `u65535`!

> Zig supports arbitrary bit-width integers, referenced by using an identifier of i or u followed by digits. For example, the identifier i7 refers to a signed 7-bit integer. The maximum allowed bit-width of an integer type is 65535. For signed integer types, Zig uses a two's complement representation.

You can use `std.math.minInt` and `maxInt` to get the min/max values for a type.

So maybe there isn't a way to use `"hello"` for array literals:

    // array literal
    const message = [_]u8{ 'h', 'e', 'l', 'l', 'o' };

This is how you modify an array in a loop without going through the index:

    for (slice) |*item| {
        item.* = whatever;
    }

Pointers:

- `*T`: pointer to a single item
- `[*]T`: pointer to many (unknown number) of items
- `*[N]T`: pointer to N items
- `[*:x]T`: pointer to a number of items determined by a sentinel
- `[]T`: slice, has a pointer of type `[*]T` and a `len`.

> In Zig, we generally prefer Slices rather than Sentinel-Terminated Pointers.

Both arrays and slices have a `len`, which is comptime-known in arrays but runtime-known in slices.

This is a trick for "slice by length" and allows more optimizations than `runtime_start + length`:

    const array_ptr_len = array[runtime_start..][0..length];

A `packed struct` guarantees that a `u5` will use exactly 5 bits of memory, and a `bool` will use exactly 1.

## Warmup

Following:
https://ziglang.org/learn/getting-started/

Install with homebrew:

    brew install zig

This puts me on Zig 0.11.

VS Code integration requires an extension. I got errors about not being able to find zig or zls in my PATH. I wound up installing it via the VS Code extension.

The thing about types being values looks interesting and kinda crazy.

## Tutorial

https://ziglearn.org/

### Chapter 1

- Uses `const` and `var`. That makes a lot more sense than `let` if `var` isn't already taken.
- Types may be omitted if they can be inferred from values.
- `undefined` may be assigned to any value. How does this work?
- There is no concept of truthy or falsy values.
- There's a built-in test runner.
- You can use `if` statements as expressions.
- while loops have a "continue" clause that lets them act like C-style `for(;;)` loops.
- `for` loops are specifically for iterating over containers. You iterate over value, index.
- Values must be used, you can assign to `_` to ignore them explicitly.
- `defer` can be used to execute a statement when you exit a block.
- Errors are defined via `error{}`, which creates an enum of errors. There are no exceptions.
- You can return a value or error with something like `AllocationError!u16`.
- You can add a `catch` clause after a function call that returns an error union.
- `switch` is an expression and must be exhaustive.
- Some types of illegal behavior (e.g. out-of-bounds array access) are caught when you enable "runtime safety" (at a performance cost)
- You can use `unreachable` in places that shouldn't be reached (e.g. in a `switch`)
- Zig has pointers (`*T`) but no null pointers. It also has const pointers (`*const T`)
- Zig has slices (`[]T`). Conceptually they are a pair `([*]T, usize)`.
  - String literals coerce to `[]const u8`
  - `x[n..m]` creates a slice from an array. The interval is half-open.
- Zig has enums. enums can have methods attached to them.
- You define structs with `struct` and initialize them with `T{.k=v}`.
  - struct fields may have default values.
  - structs may have methods
  - You can access a field on a pointer to a struct without `*`.
- Zig has unions. They always have a tag.
- `@setFloatMode(.Optimized)` is equivalent to `-ffast-math`.
- You can return a value from a block and use a block as an expression.
- You can also use loops as expressions (it seems that everything is an expression!)
- `?T` is an optional.
  - You can assign `null` to it.
  - You can use `x orelse 0` to "unwrap" the optional
  - You can use `x orelse unreachable` as a non-null assertion
  - You can write `if (b) |value|` to extract the value via "payload capturing"
- You can execute blocks at compile time using `comptime`.
  - Numeric constants have a distinct comptime type
  - You can declare that a function parameter is `comptime`. This is useful for type generators.
  - I don't follow what `@This()` is doing.
- Captures and function parameters are immutable. You can capture a pointer for mutability.
- An anonymous struct without field names is a tuple! You can iterate over these.
- There is a special syntax for "sentinel-terminated" containers: `[N:t]T`, `[:t]T`, and `[*:t]T`
- There's a special `@Vector` syntax for SIMD vectors

### Chapter 2

- Memory allocators seem to be more of a thing in Zig than I'm used to.
- There is a `GeneralPurposeAllocator` that's a reasonable default.
- You often use `defer allocator.free(bytes)` to free memory.
- `std.ArrayList(T)` is similar to a C++ `std::vector<T>`. It can be used as a stack.
- You use `{d} {s}` for string formatting, or `{}` or `{any}` (`std.fmt`)
- There's built-in JSON parsing (`std.json`) and stringifying. You need to supply a parse type.
- `std.AutoHashMap` is the built-in hash map. There's also `std.StringHashMap`.

Questions:

- Who makes Zig? Where did it come from? Why?
  - It's been around since 2016. I'm surprised no one did AoC in it last year!
  - This is the mission statement: https://andrewkelley.me/post/intro-to-zig.html
  - I see a lot of signal processing work
  - Andrew Kelley used to work at OkC and has some JS background: https://andrewkelley.me/post/do-not-use-bodyparser-with-express-js.html
- Is it annoying to use in practice? (I found Rust quite annoying!)
- Is Zig a good language for targeting WASM?

## Advent of Code 2017

### Day 1

- Had to Google how to read a file line-by-line in Zig.
- I'm not getting autocomplete or quickinfo in VS Code. Is this expected or broken?
  - Opening VS Code in the root directory for the day made it work as expected.
  - There's syntax highlighting but no language service from the root aoc directory
- I was surprised that `std.debug.print` takes a tuple as its second arg. Are there no varargs in Zig?
- I had a bug where I was adding the `u8` ASCII values of the digits, not the numeric values.
- You can do `zig run src/main.zig -- input.txt` to pass args to the program, but it doesn't cache between builds.
- Second star was very speedy after all the setup for the first!

### Day 2

I'm not sure what the best way to set up the Zig build system for multi-day AoC is. I made `src/day1.zig` and `src/day2.zig` and updated `build.zig` to use a for loop. This produces two output binaries. I think this works, but maybe I should have a single binary that takes "day" as an argument? Do I have to change `build.zig` every time I add a source file? This is a part of C that I don't love.

Concatenating strings was kinda painful! You need an allocator to do it, which I guess makes sense. I'm not sure why my first attempt with `std.fmt.bufPrint` failed.

I had a `null` vs. `undefined` bug! You have to initialize optionals to `null` rather than `undefined`.

For part 2 I'm implementing `readInts` using an `ArrayList`. Zig found a memory leak (I forgot to deallocate the ArrayList). Pretty cool!

Zig error handling is interesting. If your function returns `!void`, then you can just stick `try` in front of any statement that could error and its error returns will be added to your error returns.

... continues in [2017/README.md](/aoc2017/README.md).
