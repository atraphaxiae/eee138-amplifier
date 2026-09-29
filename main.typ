#import "@preview/charged-ieee:0.1.4": ieee

#import "@preview/fletcher:0.5.8": diagram, node, edge
#import "@preview/unify:0.8.1": num, qty, qtyrange

#show: ieee.with(
	title: "Two-Stage Common-Emitter Amplifier Design",
	authors: (
		(
			name: "Nile Jocson",
			department: [Electrical and Electronics Engineering Institute],
			organization: [University of the Philippines Diliman],
			location: [Quezon City, Philippines],
			email: "nile.xavier.jocson@eee.upd.edu.ph",
		),
	),
	figure-supplement: [Fig.],
	bibliography: bibliography("refs.yaml")
)

#set figure(placement: top)

#set table(
	columns: (auto, auto),
	align: (left, right),
	inset: (x: 8pt, y: 4pt),
	stroke: (x, y) => if y <= 1 { (top: 0.5pt) },
	fill: (x, y) => if y > 0 and calc.rem(y, 2) == 0 { rgb("#efefef") },
)

= Source
The Git repository for this project is located at https://github.com/atraphaxiae/eee138-amplifier.
The repository contains the license, source code, image assets, and LTSpice files.

= Specifications <s:spec>
We are tasked with creating a two-stage common-emitter amplifier to drive an #qty(8, "O") speaker.
The target specifications of the amplifier are shown in @t:spec.

#figure(
	table(
		table.header[Specification][Value],
		[Voltage Gain]           , $>= 200$,
		[DC Output Voltage]      , qtyrange(2.7, 3.5, "V"),
		[Source Impedance]       , qty(1000, "O"),
		[Output Impedance]       , $< #qty(100, "O")$,
		[Supply Voltage]         , [#qty(6, "V"), single supply],
		[Total Power Dissipation], $< #qty(2, "W")$,
	),
	caption: [Specifications of the Amplifier]
) <t:spec>

In addition, the amplifier must also be able to amplify a #qty(10, "mV")pp,
#qtyrange(500, 10000, "Hz") sine wave input with no clipping. Since low output resistance is
specified, we need to include an emitter-follower stage after the second common-emitter stage.

We may only use 2N4401, 2N4403, 2N3904, and 2N3906 transistors, as well as any reasonably common set
of resistors and capacitors. To avoid overheating, we may use parallel transistors.

= Output Values <s:ov>
We will be using a top-down approach in designing this amplifier, as the input impedance of each
stage is the load on the stage before it. To reduce confusion, each stage will be denoted by a
letter. The first stage is X, the second stage is Y, and the final stage is Z.

The first step is to calculate the expected output signal.
From @s:spec we have that $A_"v" >= 200$ and $V_"in,pp" = #qty(10, "mV")"pp"$. To account for
tolerances in the components, we use $A_"v" = 220$, which gives us:

$
	V_"out,pp" = A_"v" V_"in,pp" = #qty(2.2, "V")"pp" \
	V_"out,max" = V_"out,pp"/2 = #qty(1.1, "V")
$

Then we can calculate the peak current at the load:

$
	I_"out,max" = V_"out,max"/R_"L" = #qty(137.5, "mA")
$

For our target DC output voltage, we use the midpoint of the specified DC output voltage range for
maximum leeway on both sides:

$
	V_"Z,E,Q" = (2.7 + 3.5)/2 = #qty(3.1, "V")
$

Finally, we can calculate the maximum supply current into the amplifier, as allowed by the total
power dissipation specification:

$
	I_"S,max" = P_"max"/V_"S" = #qty(333.33, "mA")
$

= Final Emitter-Follower Stage
== DC Analysis
The initial circuit diagram of the final emitter-follower stage is shown in @i:z1. Note that we
assume direct coupling to the second common-emitter stage for now. Also note that the load is
connected to $V_"Z,E"$ via a coupling capacitor, but is not shown here.

#figure(
	image("assets/z1.svg"),
	caption: [Initial circuit diagram of the final emitter-follower stage.]
) <i:z1>

From @s:ov we already have $V_"Z,E,Q" = #qty(3.1, "V")$. Next we need to find $R_"Z,E"$ and
$I_"Z,E,Q"$. KCL on the emitter node gives:

$
	I_"Z,E"
		=& I_"R"_"Z,E" + I_"out" \
		=& V_"Z,E"/R_"Z,E" + V_"out"/R_"L"
$

We want no clipping to occur, so the transistor must never reach cut-off. Cut-off is at most risk of
happening at the negative peak where $V_"Z,E" = V_"Z,E,Q" - V_"out,max"$ and
$V_"out" = -V_"out,max"$, so we analyze there, requiring that $I_"Z,E" >= 0$:

$
	I_"Z,E" >=& 0 \
	V_"Z,E"/R_"Z,E" + V_"out"/R_"L" >=& 0 \
	(V_"Z,E,Q" - V_"out,max")/R_"Z,E" >=& V_"out,max"/R_"L" \
	R_"Z,E" <=& (R_"L" (V_"Z,E,Q" - V_"out,max"))/V_"out,max" \
	R_"Z,E" <=& #qty(14.55, "O")
$

We can construct $R_"Z,E"$ using a #qty(10, "O") resistor in series with three parallel
#qty(10, "O") resistors, for a total $R_"Z,E" = #qty(13.33, "O")$, which is less than the maximum
allowable value. From this we can calculate the quiescent emitter current:

$
	I_"Z,E,Q" = V_"Z,E,Q"/R_"Z,E" = #qty(232.56, "mA")
$

The 2N4401 is a suitable transistor for this stage as it can pass currents of up to #qty(600, "mA")
@2n4401. To provide a safety margin against overheating, we want to limit the maximum power
dissipation of each transistor to half of its rated power dissipation. For the 2N4401 under ambient
conditions, this gives a maximum power dissipation limit of #qty(312.5, "mW").

In order to calculate the maximum power dissipation, we can use the power dissipation at the
positive peak as an approximation, where $V_"Z,E" = V_"Z,E,Q" + V_"out,max"$ and
$I_"out"$:

$
	P_("Q"_"Z"",max")
		approx& P_("Q"_"Z"",pos") \
		=& V_"Z,CE" I_"Z,E" \
		=& (V_"S" - V_"Z,E")(I_"R"_"Z,E" + I_"out") \
		=& (V_"S" - V_"Z,E,Q" - V_"out,max") \
			& dot ((V_"Z,E,Q" + V_"out,max")/R_"Z,E" + I_"out,max") \
		=& #qty(814.64, "mW")
$

This dissipation is way above the ratings of the 2N4401, so we will need parallel transistors. With
three parallel transistors equally sharing current, we reduce the dissipation to #qty(271.55, "mW")
for each transistor, which is safely within our half-rated-power limit. Note that to equally share
current between the three transistors, we will need emitter-balancing resistors. The updated circuit
diagram for this stage is shown in @i:z2.

#figure(
	image("assets/z2.svg"),
	caption: [
		Updated circuit diagram of the final emitter-follower stage with parallel transistors.
	]
) <i:z2>

In order to calculate the values of the emitter-balancing resistors, we need to calculate the
allowable spreads $Delta V_"Z,BE"$ and $Delta I_"Z,E"$ @emitter-balancing #footnote[The formula in
the thread uses $Delta I_"C"$, but we can use $Delta I_"E"$ as an approximation.]. We can reasonably
assume $Delta V_"Z,BE" = #qty(50,"mV")$, but $Delta I_"Z,E"$ will need to be calculated from our
maximum power values.

Recall that the three transistors dissipate a maximum of #qty(814.64, "mW"), and each transistor
must dissipate at most #qty(312.5, "mW"). Then, the smallest and largest possible maximum power
dissipation of each transistor are #qty(189.64, "mW") and #qty(312.5, "mW"), respectively. Dividing
by $V_"Z,CE" = V_"S" - V_"Z,E,Q" - V_"out,max"$ (remember that we are at the positive peak) we get
the smallest and largest possible current draw of each transistor, which are #qty(105.36, "mA") and
#qty(173.61, "mA"), respectively. This gives us:

$
	Delta I_"Z,E" = I_"Z,E,pos,max" - I_"Z,E,pos,min" = #qty(68.25, "mA")
$

Then we can calculate the resistances of each emitter-balancing resistor @emitter-balancing:

$
	R_"Z,EB" = (Delta V_"Z,CE")/(Delta I_"Z,E") = #qty(732.6, "mO")
$

#qty(1, "O") resistors are much more common, so we instead use $R_"Z,EB" = #qty(1, "O")$. We can now
focus on the transistor bases. For each transistor, assuming equal current draw, we have:

$
	I_"Z,E,Q" = I_"Z,E,Q,total"/3 = #qty(77.52, "mA")
$

Assuming that $I_"Z,C" >> I_"Z,B"$, we can use $I_"Z,C,Q" = I_"Z,E,Q"$. From the datasheet @2n4401,
this collector current corresponds to $V_"Z,BE" = 0.75$ #footnote[The datasheet only provides
a $V_"BE"$ chart for $V_"CE" = #qty(10, "V")$, so this is an approximation.]. However, $beta$ is not
given for this particular current, so we use $beta = 100$, which corresponds to the next test
current above $I_"Z,C,Q"$. From this we can calculate the total base current:

$
	I_"Z,B,Q,total" = (3I_"Z,E,Q")/(beta + 1) = #qty(2.30, "mA")
$
