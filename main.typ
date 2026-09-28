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

= Output Values
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
