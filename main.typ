#import "@preview/charged-ieee:0.1.4": ieee

#import "@preview/fletcher:0.5.8": diagram, node, edge
#import "@preview/unify:0.8.1": num, qty, qtyrange

#show: ieee.with(
	title: "Design of a Two-Stage Common-Emitter Amplifier",
	authors: (
		(
			name: "Nile Jocson",
			department: [Electrical and Electronics Engineering Institute],
			organization: [University of the Philippines Diliman],
			location: [Quezon City, Philippines],
			email: "nile.xavier.jocson@eee.upd.edu.ph",
		),
	),
	bibliography: bibliography("refs.yaml"),
	figure-supplement: [Fig.],
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

= Specifications
We are tasked with creating a two-stage common-emitter amplifier to drive an #qty(8, "O") speaker.
The target specifications of the amplifier are shown in @t:spec.

#figure(
	table(
		table.header[Specification][Value],
		[Voltage Gain]           , $>= #num(200)$,
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

= Emitter-Follower Stage
== Exact Resistor Values
We are going to be using a top-down approach to designing this amplifier, which is why we're
starting off with the final emitter-follower stage. The point of this stage is to supply enough
current to properly drive the #qty(8, "O") speaker. A general circuit diagram of this stage is shown
in @i:ef.

#figure(
	image("assets/ef.svg"),
	caption: [General circuit diagram of the emitter-follower stage.],
) <i:ef>

From @t:spec, we have a DC output voltage range #qtyrange(2.7, 3.5, "V"). I'll choose the midpoint
of this range as our target DC output voltage, so that we have the maximum amount of leeway in both
directions:

$
	V_"S3,out" = (2.7 + 3.5)/2 = #qty(3.1, "V")
$

Note that we include an output coupling capacitor here, so that the speaker will only see the AC
component of the signal, without the DC offset. From the specified voltage gain and input amplitude,
we can calculate the required output signal amplitude:

$
	V_"out,pp" = V_"in,pp" A_v = #qty(2, "V")"pp"
$

$
	V_"out,max" = V_"out,pp"/2 = #qty(1, "V")
$

Then we can calculate the maximum output current and average power delivered to the speaker:

$
	I_"out,max" = V_"out,max"/R_"out" = #qty(125, "mA")
$

$
	P_"out,ave" = V_"out,rms"^2/R_"out" = V_"out,max"^2/(2R_"out") = #qty(62.5, "mW")
$

From this we can choose an $I_"C,Q"$. Note that we will be using the 2N4401 for this stage, as it
supports higher collector currents when compared to the 2N3904, which is essential for driving the
speaker. The datasheet @2n4401 provides characteristics for $I_C = #qty(150, "mA")$, which is close
to our $I_"out,max"$ and gives some margin against cutoff, so let's use that for our $I_"C,Q"$.
However, checking the power dissipation of the transistor:

$
	V_"CE,Q" = V_S - V_"E,Q" = V_S - V_"S3,out" = #qty(2.9, "V")
$

$
	P_"Q" approx V_"CE,Q" I_"C,Q" = #qty(435, "mW")
$

The power dissipation of the transistor is close to the maximum power dissipation at ambient
temperature of the 2N4401, so in order to avoid overheating, we need to use two parallel
transistors here. Now, using a new $I_"C,Q" = #qty(75, "mA")$ for each transistor, we can refer to
the datasheet @2n4401 to find $V_"BE,Q" approx #qty(0.75, "V")$ #footnote([The 2N4401 datasheet
@2n4401 only provides a $V_"BE"$ vs. $I_"C"$ table for $V_"CE" = #qty(10, "V")$. However, since
$V_"BE"$ is dependent primarily on $I_"C"$ and not as much on $V_"CE"$ in forward-active mode, we
can use this approximation.]). We can then find the required base voltage:

$
	V_"B,Q" = V_"E,Q" + V_"BE,Q" = V_"S3,out" + V_"BE,Q" = #qty(3.85, "V")
$

Then we need to calculate the emitter current and resistance for each transistor. A $beta$ value at
our $I_"C,Q"$ is not given by the datasheet, so let's use the $beta = 80$ as an approximation, which
corresponds to the closest datasheet-specified collector current to our $I_"C,Q"$:

$
	I_"E,Q"
		=& I_"C,Q" + I_"B,Q" \
		=& I_"C,Q" + I_"C,Q"/beta \
		=& I_"C,Q" (1 + 1/beta) \
		=& #qty(75.9375, "mA")
$

$
	R_"E" = V_"E,Q"/I_"E,Q" = V_"S3,out"/I_"E,Q" approx #qty(40.82, "O")
$

Now, in order to design the base-biasing voltage divider, we need the total base current:

$
	I_"B,Q,total" = 2 I_"B,Q" = (2 I_"C,Q")/beta = #qty(1.875, "mA")
$

Using the rule that $I_"D2" = 10I_"B"$ to stabilize $V_"B"$ @biasing, we can solve for $R_"D1"$ and
$R_"D2"$. Doing KCL at the input node:

$
	I_"D1,Q"
		=& I_"B,Q,total" + I_"D2,Q" \
		=& 11I_"B,Q,total" \
		=& #qty(20.625, "mA")
$

$
	R_"D1" = (V_"S" - V_"B,Q")/I_"D1,Q" approx #qty(104.24, "O")
$

$
	R_"D2" = V_"B,Q"/I_"D2,Q" = V_"B,Q"/(10I_"B,Q,total") approx #qty(205.33, "O")
$

== Standard Resistor Values
Picking standard resistor values, we can use two #qty(22, "O") resistors for the two $R_"E"$, one
#qty(100, "O") for $R_"D1"$, and one #qty(200, "O") for $R_"D2"$. So our new standardized values
are:

$
	R_E    =& #qty(44, "O") \
	R_"D1" =& #qty(100, "O") \
	R_"D2" =& #qty(200, "O")
$

We can use $V_"BE,Q" = #qty(0.75, "V")$ since $V_"BE" approx #qty(0.75, "V")$ for current values
around $I_C = #qty(75, "mA")$. We can also use $beta = 80$ for the same reasons. To simplify
analysis, we can turn the voltage divider network into its Thevenin equivalent:

$
	V_"Th" = V_"S" ((R_"D2")/(R_"D1" + R_"D2")) = #qty(4, "V")
$

$
	R_"Th" = R_"D1" || R_"D2" approx #qty(66.67, "O")
$

Then doing a KVL from $V_"Th"$ to the transistor base to ground:

$
	0
		=& V_"Th" - I_"B,Q,total" R_"Th" - V_"BE,Q" - I_"E,Q" R_"E" \
		=& V_"Th" - 2 I_"B,Q" R_"Th" - V_"BE,Q" - I_"E,Q" R_"E" \
		=& V_"Th" - ((2 I_"C,Q")/beta) R_"Th" - V_"BE,Q" - (1 + 1/beta) I_"C,Q" R_"E"
$

Solving this we get $I_"C,Q" approx #qty(70.32, "mA")$ and therefore
$I_"E,Q" approx #qty(71.20, "mA")$. Then, solving for needed voltages:

$
	V_"E,Q" = I_"E,Q" R_"E" approx #qty(3.13, "V")
$

$
	V_"B,Q" = V_"E,Q" + V_"BE,Q" approx #qty(3.88, "V")
$

$
	V_"CE,Q" = V_"C,Q" - V_"E,Q" = V_"S" - V_"E,Q" approx #qty(2.87, "V")
$

$V_"E,Q"$ is still in the range of the DC output voltage specification, and this also verifies that
the transistors are in forward-active because $V_"C,Q" > V_"B,Q" > V_"E,Q"$. Finally, calculating
the power dissipation of each transistor:

$
	P_"Q" approx V_"CE,Q" I_"C,Q" = #qty(201.82, "mW")
$

Which is safely below the maximum power dissipation of a 2N4401 at ambient temperature.

== Small Signal Analysis
First off we need to select an output coupling capacitor. The output capacitor and speaker form what
is essentially a passive first-order high-pass filter. Note that we want #qty(500, "Hz") signals to
be as unattenuated as possible, so we need to have a cut-off frequency much lower than that.

Using the magnitude of the transfer function, we can solve for an appropriate cut-off frequency. Say
that we want #qty(500, "Hz") signals to be no more than #qty(1, "%") attenuated, so
$|H(500)| >= 0.99$ must be satisfied. Solving for the maximum allowable cut-off frequency:

$
	|H(500)| = 0.99 = 500/sqrt(500^2 + f_c^2) \
	f_c approx #qty(71.25, "Hz")
$

Then, solving for the minimum capacitance:

$
	C = 1/(2pi R_"L" f_"c") approx #qty(279.23, "uF")
$

Finally, selecting a standard value:

$
	C = #qty(330, "uF")
$

Then we can actually start the small-signal analysis. Replacing the capacitor with a short, we get
a new resistance $R_"E,ac"$:

$
	R_"E,ac" = R_"E" || R_"E" || R_"L" approx #qty(5.87, "O")
$

Calculating $g_m$ and $r_pi$ for each transistor using $V_T approx #qty(25.85, "mV")$:

$
	g_m = I_"C,Q"/V_T approx #qty(2.72, "S")
$

$
	r_pi = beta/g_m approx #qty(29.41, "O")
$

Then, calculating the voltage gain of the emitter-follower:

$
	A_v = (g_m R_"E,ac")/(g_m R_"E,ac" + 1) approx #num(0.94)
$

We also need to calculate the input resistance of the emitter-follower. We have two parallel
transistors which correspond to two parallel base input resistances, which are also in parallel to
the two voltage divider resistors:

$
	R_"in"
		=& R_"in,B" || R_"in,B" || R_"D1" || R_"D2" \
		=& R_"in,B"/2 || R_"D1" || R_"D2" \
		=& (r_pi + (beta + 1)R_"E,ac")/2 || R_"D1" || R_"D2" \
		approx& #qty(52.74, "O")
$

Finally, solving for the output resistance using the resistance reflection rule @rrr. Note that the
BJT output resistances are also in parallel with the emitter resistors, and $R_"B"$ consists of the
voltage divier resistors, in parallel as well:

$
	R_"out"
		=& R_"out,bjt" || R_"out,bjt" || R_"E" | R_"E" \
		=& R_"out,bjt"/2 || R_"E"/2 \
		=& (r_pi + R_"B")/(2(beta + 1)) || R_"E"/2 \
		=& (r_pi + R_"D1" || R_"D2")/(2(beta + 1)) || R_"E"/2 \
		=& #qty(577.50, "mO")
$

Which is way below the maximum output impedance of #qty(100, "O").
