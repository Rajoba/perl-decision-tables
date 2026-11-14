# perl-decision-tables

A small Perl tool for **decision tables** (German: *Entscheidungstabellen*) that checks its own rules. I started it in 2004 and have kept coming back to it since.

You describe conditions, actions and rules as data. The tool then:

- **finds missing rules**, meaning condition combinations that no rule covers;
- **ignores impossible combinations**, so you don't get flooded with false gaps. That covers direct ones like `x == y` together with `x > y`, and chained ones like `DBx == x`, `DBy == y`, `x < y` together with `DBx > DBy`;
- **finds overlapping rules** and lists the exact cases where two rules both apply;
- **finds duplicate and redundant rules**, where one rule is fully covered by another with the same actions;
- **compiles the table into a Perl sub** that you can call with real values.

The output is in German. A small glossary is at the end.

## Quick start

```sh
cpanm --installdeps .     # only needs Class::Accessor
perl et_check.pl
prove t/
```

## A table

The table is defined at the end of `et_check.pl`. This example decides the grain direction of a sheet (`lfr`, *Laufrichtung*: `SB` = *Schmalbahn*, short grain; `BB` = *Breitbahn*, long grain):

```perl
my $rt = RegTable->new({
    Bedingungen => [            # conditions
        'x == y',
        'x > y',
        'abs(px2 - px1) > abs(py2 - py1)',
        'DBx > DBy',
        'DBx == x',
        'DBy == y',
    ],
    Aktionen => [               # actions
        'lfr = "--"',
        'lfr = "SB"',
        'lfr = "BB"',
        '&::swap(\DBx, \DBy)',
        'DBx = x',
        'DBy = y',
    ],
    sets => [                   # [conditions] => [actions]
        [[qw(- - - - 0 -)], [qw(- - - - 1 -)]],
        [[qw(- - - - - 0)], [qw(- - - - - 1)]],
      # [[qw(0 0 0 - - -)], [qw(- 1 - - - -)]],   # commented out on purpose
        [[qw(0 1 1 - - -)], [qw(- 1 - 1 - -)]],
        [[qw(0 1 0 - - -)], [qw(- - 1 - - -)]],
        [[qw(0 0 1 - - -)], [qw(- - 1 1 - -)]],
    ],
    else => [qw(1 - - 1 -)],    # actions when no rule applies
});
$rt->report;
```

In each rule, the first list holds the conditions: `1` = yes, `0` = no, `-` = don't care. The second list holds the actions: `1` = do it, `-` = don't.

When a condition is `0`, it is negated exactly. `x > y` becomes `x <= y`, `x < y` becomes `x >= y`, and `x == y` becomes `x != y`. Anything that isn't a single comparison `a OP b` (with spaces around the operator) becomes `!(...)`. A `#` in a text condition becomes `nicht` (not), for example `'wenn # PK'`.

## What the report shows

The full output is in [`examples/output.txt`](examples/output.txt). Because one rule is commented out, the check finds the gap:

```
Fehlende Regeln:
--------------------------------------------------
...
Regel Nr.: 9 NNNNYY
x != y
x <= y
abs(px2 - px1) <= abs(py2 - py1)
DBx <= DBy
DBx == x
DBy == y
-------------
lfr = "--"
&::swap(\DBx, \DBy)
```

The listed actions are the `else` actions, so they show what would happen today in that case. Rules 7 and 8 (not shown) are the two `x == y` cases: no rule handles `x == y`, so only `else` covers it.

The row `NNNYYY` (the same as above but with `DBx > DBy`) is not reported, because it can't happen: `DBx == x`, `DBy == y` and `x < y` imply `DBx < DBy`.

Overlaps are listed per rule pair, with the cases they share:

```
Regel 5 (NYN---) und 6 (N--Y--) überkreuzen sich in 4 Fällen:
    NYNYNN
    NYNYNY
    NYNYYN
    NYNYYY
```

All matching rules fire, not just the first one. Some overlaps are therefore intended. In the example, rules 2 and 3 (`DBx = x`, `DBy = y`) are meant to combine with the others. The report shows these overlaps anyway, and you decide whether one is a conflict.

Duplicate and covered rules:

```
Regel Nr.5 (NYN---) == Regel Nr. 6 (NYN---)
Regel Nr.5 (NYN---) <  Regel Nr. 7 (NY----)
```

## Running the table

```perl
do './et_check.pl';                 # loads the code, does not run the example
my $rt = example_table();

my $cd = $rt->Code([qw(x y px1 py1 px2 py2 DBx DBy)],   # parameters
                   [qw(lfr DBx DBy)]);                  # results
my $r = $cd->(100, 70, 20, 20, 300, 3000, 70, 100);
# $r = { lfr => 'BB', DBx => 100, DBy => 70 }
```

The sub returns a hashref with the result variables. With `$rt->Code(..., ..., { verbose => 1 })` it also prints which conditions matched and which actions ran.

### Several tables, and tables calling tables

Each table keeps its own conditions, actions and rule numbers, so you can create as many as you like. An action can call another table's compiled sub, which gives you simple nesting:

```perl
our $inner = $small_table->Code([qw(a b)], [qw(r)]);
my $outer  = RegTable->new({
    Bedingungen => ['n > 0'],
    Aktionen    => ['out = $::inner->(n, 3)->{r}'],
    sets        => [ [[qw(1)], [qw(1)]] ],
    else        => [qw(-)],
});
```

The gap check doesn't look inside the called table yet. It treats the call like any other action.

### Gaps at runtime

The report finds missing rules before you run anything. Without extra options, an input that falls into a gap at runtime just runs `else`, silently. With `on_gap` it makes itself known:

```perl
my $cd = $rt->Code(\@params, \@results, { on_gap => 'warn' });   # warn, then run else
my $cd = $rt->Code(\@params, \@results, { on_gap => 'die'  });   # die instead
my $cd = $rt->Code(\@params, \@results, { on_gap => sub {      # your own handler, then else
    my ($pattern, $values) = @_;   # 'NNNNYY', { x => 1, y => 2, ... }
}});
```

```
keine Regel für NNNNYY (x=1, y=2, px1=0, py1=0, px2=1, py2=1, DBx=1, DBy=2)
```

The pattern is the Y/N combination of the conditions for this input, the same notation as in the report. `on_gap` fires exactly when `else` would run, that is, when no rule set an `else` variable (see Limits). So it also fires for inputs where only rules 2/3 matched (e.g. `NNNNNN`): those rows are covered in the report, but nothing in them decides `lfr`.

To check the table itself without running it, use `$rt->Fehlende_Regeln`. It returns the missing rows as arrays of 1/0.

Strictly speaking, `Code()` interprets the table rather than generating Perl source. Each call substitutes the parameters into the condition and action strings and `eval`s them. All matching rules fire, in table order.

## Limits

- This is a single script, not a CPAN module. To use your own table, change the `RegTable->new(...)` call at the end of `et_check.pl`. More examples (traffic offences, foreign losses under §2a EStG) are commented out right above it.
- All 2^n combinations are generated. That is fine up to about 15 conditions, but above that you need a SAT solver or a rules engine.
- Conditions and actions are strings evaluated with `eval`, so only use tables you trust.
- The check for impossible combinations only understands single comparisons (`a == b`, `a < b`, ...) between terms that are written the same way. It doesn't know arithmetic, so `abs(a) >= 0` or `x + 1 > x` are just two unrelated terms to it.
- Rule numbers in the report start at 2.
- In `Code()`, the `else` actions run when no matching rule assigned any of the variables the `else` actions assign. In the example, `else` sets `lfr`. Rules 2 and 3 only set `DBx`/`DBy`, so they don't prevent `else` from running. If the `else` actions assign nothing (only function calls), `else` runs when no rule matched at all.

## Tests

```sh
prove t/
```

- `t/example.t`: the example finds the three missing rules, skips the impossible ones, and the compiled sub returns `BB`.
- `t/conflict.t`: an added contradicting rule is reported as an overlap.
- `t/redundant.t`: a duplicate rule and a covered rule are detected.
- `t/code.t`: the compiled sub returns the right result for every branch of the table, including the gap and `x == y` (also when rules 2/3 fire at the same time), and prints nothing by default. A second small table checks that `else` runs only when no rule matched.
- `t/two_tables.t`: several tables at once and a table calling another one, with the results and reports of each table unaffected.
- `t/on_gap.t`: silent by default, `warn`, `die` and a handler, with the pattern and input values in the message.
- `t/negation.t`: exact negation (`>` → `<=`, `<` → `>=`, ...), contradictions across variables, and the boundary `|dx| == |dy|`, both in the report and in the compiled sub.

## Glossary

| German | English |
|---|---|
| Bedingungen | conditions |
| Aktionen | actions |
| Regel | rule |
| Fehlende Regeln | missing rules |
| überkreuzen sich | overlap |
| sonst | else |
| Laufrichtung (SB/BB) | grain direction (short/long grain) |

## License

Copyright (c) 2004–2026 Ralf-Jochen Bartel. Free software, available under the same terms as Perl itself. See [LICENSE](LICENSE).
