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

#let vstable = table.with(
	columns: (6em, auto),
	align: (x, y) => if x == 0 { left } else { right },
	inset: (x: 8pt, y: 4pt),
	stroke: (x, y) => {
		if x == 0 {
			(right: 0.5pt)
		}
		if y <= 1 {
			(top: 0.5pt)
		}
	},
	fill: (x, y) => if y > 0 and calc.rem(y, 2) == 0  { rgb("#efefef") },
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
From @s:spec we have $A_"v" >= 200$ and $V_"in,pp" = #qty(10, "mV")"pp"$. To account for tolerances
in the components, we use $A_"v" = 220$, which gives us:

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
$I_"out" = I_"out,max"$:

$
	P_("Q"_"Z","max")
		approx& P_("Q"_"Z","pos") \
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
by $V_"Z,CE" = V_"S" - V_"Z,E,Q" - V_"out,max"$, we get the smallest and largest possible current
draw of each transistor at the positive peak, which are #qty(105.36, "mA") and #qty(173.61, "mA"),
respectively. This gives us:

$
	Delta I_"Z,E" = I_"Z,E,pos,max" - I_"Z,E,pos,min" = #qty(68.25, "mA")
$

Then we can calculate the resistances of each emitter-balancing resistor @emitter-balancing:

$
	R_"Z,EB" = (Delta V_"Z,BE")/(Delta I_"Z,E") = #qty(732.6, "mO")
$

#qty(1, "O") resistors are much more common, so we instead use $R_"Z,EB" = #qty(1, "O")$. We can now
focus on the transistor bases. For each transistor, assuming equal current draw, we have:

$
	I_"Z,E,Q" = I_"Z,E,Q,total"/3 = #qty(77.52, "mA")
$

Then we can find the voltage drop of the emitter-balancing resistors:

$
	V_"Z,EB,Q" = I_"Z,E,Q" R_"Z,EB" = #qty(77.52, "mV")
$

Assuming that $I_"Z,C" >> I_"Z,B"$, we can use $I_"Z,C,Q" = I_"Z,E,Q"$. From the datasheet @2n4401,
this collector current corresponds to $V_"Z,BE,Q" = 0.75$ #footnote[The datasheet only provides
a $V_"BE"$ chart for $V_"CE" = #qty(10, "V")$, so this is an approximation.]. However, $beta$ is not
given for this particular current, so we use $beta_"Z" = 100$, which is the minimum $beta$ of the next test current above $I_"Z,C,Q"$. From this we can calculate the total base current:

$
	I_"Z,B,Q,total" = (3I_"Z,E,Q")/(beta_"Z" + 1) = #qty("2.30", "mA")
$

Finally, we can get the voltage at the base:

$
	V_"Z,B,Q" = V_"Z,E,Q" + V_"Z,EB,Q" + V_"Z,BE,Q" = #qty(3.93, "V")
$

== AC Analysis
For our small signal analysis, we will be assuming that $r_"Z,o"$ has a negligible effect on the
overall workings of the amplifier, for each stage. We will be using the hybrid-pi model. Firstly we
can calculate the transconductance and internal resistances of each parallel transistor at room
temperature, as well as the AC load at the output with the output coupling capacitor shorted:

$
	g_"Z,m" = I_"Z,C,Q"/V_"T" = #qty(3.02, "S") \
	r_"Z,e" = 1/g_"Z,m" = #qty(331.13, "mO") \
	r_("Z",pi) = beta_"Z" r_"Z,e" = #qty(33.11, "O") \
	R_"Z,L" = R_"Z,E" || R_"L" = #qty(5.00, "O")
$

Including the emitter-balancing resistors, and noting that each branch is in parallel, we have an
effective small-signal resistance at the emitter:

$
	R_"Z,eff" = (r_"Z,e" + R_"Z,EB")/3 = #qty(443.71, "mO")
$

Then the gain is approximately:

$
	A_"Z,v" = R_"Z,L"/(R_"Z,L" + R_"Z,eff") = 0.92
$

Calculating the input impedance:

$
	R_"Z,in"
		=& r_("Z",pi)/3 + (beta_"Z" + 1)(R_"Z,EB"/3 + R_"Z,L") \
		=& #qty(549.70, "O")
$

We will only be able to calculate the output impedance after finalizing the second common-emitter
stage.

== Simulation
For the simulation, we use a #qty(2.4, "V")pp, #qty(3.93, "V") DC offset sine wave to simulate the
output of the second common-emitter stage, at #qty(500, "Hz") and #qty(10, "kHz"). These values were
found using $V_"Z,B,Q"$, $V_"out,pp"$ and the theoretical $A_"Z,v"$. We also use a placeholder
output coupling capacitor value of #qty(470, "uF").

At both frequencies, the simulated gain is #num(0.90). This corresponds to a #qty(-2.17, "%")
discrepancy between the theoretical and actual gain value, which is acceptable. This is the reason
why we are targeting a gain of #num(220), to account for these variances.

= Second Common-Emitter Stage
== DC Analysis
The initial circuit diagram for the second common-emitter stage is shown in @i:y1. Note that the
input coupling capacitor $C_"XY"$ is not shown here, but will be used. We will be using direct
coupling to connect the output of this stage to the input of Z, so we have $V_"Y,C,Q" = V_"Z,B,Q"$.
We are not using a voltage divider coupling since it will add more load to the common-emitter stage,
which will reduce its gain.

#figure(
	image("assets/y1.svg"),
	caption: [
		Initial circuit diagram of the second common-emitter stage.
	]
) <i:y1>

We want the gain of this stage to be as high as possible to remove some of the work from the first
common-emitter stage, which has to deal with the #qty(1000, "O") source impedance. Using the gain of
stage Z, we can calculate the required output voltage for this stage:

$
	V_"Y,C,pp" = V_"out,pp"/A_"Z,v" = #qty(2.39, "V")"pp" \
	V_"Y,C,min" = V_"Y,C,Q" - V_"Y,C,pp"/2 = #qty(2.73, "V") \
	V_"Y,C,max" = V_"Y,C,Q" + V_"Y,C,pp"/2 = #qty(5.12, "V")
$

Doing KCL on $V_"Y,C"$:

$
	I_"Y,C" = (V_"S" - V_"Y,C")/R_"Y,C" - I_"Z,B"
$

To avoid clipping, the transistor must never cut-off. This is at most risk of happening when
$V_"Y,C" = V_"Y,C,max"$, where $R_"Y,C"$ is passing the least amount of current, and most of it is
going into Z's transistor bases. At this point we have:

$
	I_"Z,E,total,max"
		=& (V_"Z,E,Q" + V_"out,pp"/2)/R_"Z,E" + I_"out,max"  \
		=& #qty(452.58, "mA")
$

$
	I_"Z,B,total,max" = I_"Z,E,total,max"/(beta_"Z" + 1) = #qty(4.48, "mA")
$

For no cut-off, we want $I_"Y,C" >= 0$ here:

$
	I_"Y,C" >=& 0 \
	(V_"S" - V_"Y,C")/R_"Y,C" - I_"Z,B" >=& 0 \
	(V_"S" - V_"Y,C,max")/R_"Y,C" >=& I_"Z,B,total,max" \
	R_"Y,C" <=& (V_"S" - V_"Y,C,max")/I_"Z,B,total,max" \
	R_"Y,C" <=& #qty(196.43, "O")
$

We can construct $R_"Y,C"$ using a #qty(150, "O") resistor. We want a large margin here so that we
can supply enough current to account for discrepancies in $beta_"Z"$. Then, we can find the
collector current:

$
	I_"Y,C,Q" = (V_"S" - V_"Y,C,Q")/R_"Y,C" - I_"Z,B,Q,total" = #qty("11.50", "mA")
$

The 2N3904 is a good transistor for this stage, as it has a higher $beta$ and is more optimized for
lower currents than the 2N4401, and has a maximum collector current of #qty(200, "mA"). From the
datasheet @2n3904 and our $I_"Y,C,Q"$ we have $beta_"Y"$ ranging from 100 to 300. For our purposes,
we set $beta_"Y" = 200$, which is the midpoint of these values. We also have
$V_"Y,BE,Q" = #qty(0.7, "V")$ at this collector current #footnote[The datasheet only provides a
$V_"BE"$ chart for $V_"CE" = #qty(1, "V")$, so this is yet another approximation.]. We can then
calculate the base and emitter currents:

$
	I_"Y,B,Q" = I_"Y,C,Q"/beta_"Y" = #qty("57.50", "uA") \
	I_"Y,E,Q" = I_"Y,C,Q" + I_"Y,B,Q" = #qty(11.56, "mA")
$

Using $V_"Y,E,Q" = #qty(1, "V")$ @ce-amplifier, we can calculate the emitter resistance:

$
	R_"Y,E" = V_"Y,E,Q"/I_"Y,E,Q" = #qty(86.51, "O")
$

We can construct $R_"Y,E"$ using a #qty(150, "O") resistor in parallel with a #qty(200, "O")
resistor, giving us a total $R_"Y,E" = #qty(85.71, "O")$. We will need to recalculate $V_"Y,E,Q"$,
which yields $V_"Y,E,Q" = I_"Y,E,Q" R_"Y,E" = #qty(990.81, "mV")$. Then we have the base voltage
$V_"Y,B,Q" = V_"Y,E,Q" + V_"Y,BE,Q" = #qty(1.69, "V")$.

Next we compute for the values of the bias divider resistors. We want $I_"Y,D2,Q"$ to be ten times
the value of $I_"Y,B,Q"$, so:

$
	I_"Y,D2,Q" = 10I_"Y,B,Q" = #qty("575.00", "uA") \
	I_"Y,D1,Q" = I_"Y,D2,Q" + I_"Y,B,Q" = #qty("632.50", "uA")
$

Calculating the resistor values:

$
	R_"Y,D1" = (V_"S" - V_"Y,B,Q")/I_"Y,D1,Q" = #qty(6.81, "kO") \
	R_"Y,D2" = V_"Y,B,Q"/I_"Y,D2,Q" = #qty(2.94, "kO")
$

We can make $R_"Y,D1"$ using a single #qty(6.8, "kO") resistor, while $R_"Y,D2"$ can be made using a
#qty(2.2, "kO") resistor in series with a #qty(680, "O") resistor, giving us
$R_"Y,D1" = #qty(6.8, "kO")$ and $R_"Y,D2" = #qty(2.88, "kO")$.

Finally, approximating the power dissipation of the transistor, we have:

$
	P_"Q"_"Y"
		=& V_"Y,CE,Q" I_"Y,C,Q" \
		=& (V_"Y,C,Q" - V_"Y,E,Q") I_"Y,C,Q" \
		=& #qty("33.80", "mW")
$

This is well below the maximum power dissipation of the 2N3904 in ambient conditions @2n3904.

== AC Analysis
First we calculate the transconductance and internal resistances of the transistor at room
temperature, as well as the AC load seen by the collector:

$
	g_"Y,m" = I_"Y,C,Q"/V_"T" = #qty(447.47, "mS") \
	r_"Y,e" = 1/g_"Y,m" = #qty(2.23, "O") \
	r_("Y",pi) = beta_"Y" r_"Y,e" = #qty(446.96, "O") \
	R_"Y,L" = R_"Y,C" || R_"Z,in" = #qty(117.84, "O")
$

Because $R_"Y,E"$ is initially totally bypassed by $C_"Y,E"$, we have:

$
	A_"Y,v" = R_"Y,L"/r_"Y,e" = 52.84
$

Calculating the input impedance:

$
	R_"Y,in" = R_"Y,D1" || R_"Y,D2" || r_("Y",pi) = #qty(366.08, "O")
$

Now we can finally calculate the output impedance of Z, and in turn, the value of its output
coupling capacitor, assuming $R_"Y,out" approx R_"Y,C"$:

$
	R_"Z,out"
		=& R_"Z,E" || [R_"Z,EB"/3 + (R_"Y,out" + r_("Z",pi)/3)/(beta_"Z" + 1)] \
		=& #qty(1.68, "O")
$

Which is much less than the output impedance limit from the specification. We can then calculate the
output coupling capacitor, noting that it forms a high-pass filter. In order to find the cut-off
frequency, we need to set a limit for the attenuation of the lower-bound frequency. In our case, we
want #qty(500, "Hz") signal to be attenuated no more than #qty(1, "%"). Calculating the cut-off
frequency using this criterion:

$
	|H(f)| = 1 - 0.01 = 0.99 = f/sqrt(f^2 + f_"c"^2) \
	f_"c" = #qty(71.25, "Hz")
$ <f:fc>

Then finally calculating the output coupling capacitor:

$
	C_"out" = 1/(2pi (R_"Z,out" + R_"L") f_"c") = #qty(230.76, "uF")
$

We can use a standard value of $C_"out" = #qty(330, "uF")$ instead, rounding up since a higher value
gives a lower attenuation. Finally, to calculate the value of the bypass capacitor, we want its
reactance to be at least ten times smaller than $R_"Y,E"$ at the lower-bound frequency
@ce-amplifier. Using the $f = f_"c"$ from @f:fc, we have:

$
	C_"Y,E"
		=& 1/(2pi X_"C"_"Y,E" f_"c") \
		=& 1/(2pi (R_"Y,E"/10) f_"c") \
		=& #qty(260.62, "uF")
$

We can use a standard value of $C_"Y,E" = #qty(330, "uF")$ instead, rounding up for the same reasons
as above.

== Simulation
For the simulation, we use a #qty(45.26, "mV")pp, #qty(1.69, "V") DC offset sine wave at
#qty(500, "Hz") and #qty(10, "kHz"), to simulate the output of the first common-emitter stage after
the coupling capacitor. These values were found using $V_"Y,B,Q"$, $V_"out,pp"$ and the combined
gain of $A_"Y,v"$ and $A_"Z,v"$.

We get a simulated gain of #num(50.36) for #qty(500, "Hz") and #num(55.35) for #qty(10, "kHz"),
however we see a significant distortion in the waveform of $V_"Y,C"$, with flat tops and sharper
bottoms. To reduce this distortion, we can instead use a partially-bypassed common-emitter topology.
The updated circuit diagram is shown in @i:y2.

#figure(
	image("assets/y2.svg"),
	caption: [
		Updated circuit diagram of the second common-emitter stage with the unbypassed emitter
		resistor.
	]
) <i:y2>

Using $R_"Y,E1" = #qty(3, "O")$ effectively removes the distortion, but it reduces the gain to
#num(25.59) at #qty(500, "Hz") and #num(26.21) at #qty(10, "kHz"). We will need to update $A_"Y,v"$
since the simulated values are very different from the theoretical values:

$
	A_"Y,v" = R_"Y,L"/(r_"Y,e" + R_"Y,E1") = 22.53
$

Using this new theoretical gain, the simulated gains are #qtyrange(13.58, 16.33, "%") higher than
the theoretical gain, for #qty(500, "Hz") and #qty(10, "kHz"), respectively. We also need to
recalculate the input impedance:

$
	R_"Y,in"
		=& R_"Y,D1" || R_"Y,D2" || [r_("Y",pi) + (beta_"Y" + 1) R_"Y,E1"] \
		=& #qty(694.74, "O")
$

= First Common-Emitter Stage
== DC Analysis
