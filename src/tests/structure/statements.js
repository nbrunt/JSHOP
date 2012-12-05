// Empty statement
;

// If statement
var x = 3,  y = 4;
if (x > y) x = 0;
  
if (x != y) {
  x = 0;
} else {
  y = 0;
}

// Iterative statements
do {
  x = 0;
} while (false);

while (false)
  x = 0;
  
for (i=0; i < 10; i++) {
  x = 0;
}

for (; i<10; i++) {
  x = 0;
}

for (i=0;; i++) {
  x = 0;
  break;
}

for (;; i++) {
  x = 0;
  break;
}

for (i=0; i < 10;) {
  x = 0;
  break;
}

for (; i < 10;) {
  x = 0;
  break;
}

for (i=0;;) {
  x = 0;
  break;
}

for (;;) {
  x = 0;
  break;
}

for (var i=0; i < 10; i++) {
  x = 0;
}

for (x in y) {
  x = 0;
  break;
}

// Expression statement
i++;

// Try statement
try {
  x = 0;
} catch (err) {
  y = 0;
}

try {
  x = 0;
} catch (err) {
  y = 0;
}

function myTest() {}

try {
   myTest(); 
} catch (e if e instanceof TypeError) {
   x = 0;
} catch (e if e instanceof RangeError) {
   x = 0;
} catch (e if e instanceof EvalError) {
   x = 0;
} catch (e) {
   x = 0;
}

try {
  x = 0;
} finally {
  y = 0;
}

try {
   myTest(); 
} catch (e if e instanceof TypeError) {
   x = 0;
} catch (e if e instanceof RangeError) {
   x = 0;
} catch (e if e instanceof EvalError) {
   x = 0;
} finally {
   y = 0;
}

// Switch statement
switch (x) {
  case 5: x = 0;
          break;
  case 7: y = 0;
          break;
}

switch (x) {
  case 5:  x = 0;
           break;
  case 7:  y = 0;
           break;
  default: y = 0;
}

switch (x) {
  case 5:  x = 0;
           break;
  case 7:  y = 0;
           break;
  default: y = 0;
           break;
  case 10: y = 1;
           break;
}

// Continue statement
while(false) continue;

a:
while (false) continue a;

// Break statement
while (false) break;

a:
break a;

// Return statement
function test_1() {return;}

function test_2(a) {return a;}

// With statement
with ({num: i}) {
  x = 0;
}

// Labelled statement
x : x = 0;

// Throw statement
// throw "Intentional error";