// Semi-colons before closing braces
for (i = 0; i < 10; i++) {
  count += i;
  alert(count);
}


// Ternary conditionals
if (5 > 3) {
  result = "true";
}
else {
  result = "false"
}


// Array declarations
var a = new Array;

// Object declarations
var b = new Object;


// Partial evaluation
c = 4 * 2 + 12;
d = 34.3 + 23.78;
e = 1 + 2 + 3.0;
f = 'Hello' + ' World';
g = "Hello" + " World";
h = "He\"\"llo" + ' World';
i = 'Hello' + " World";
j = 4/3;


// Identifier shrinking
function test1(var1, var2) {
  var var3 = "hello";
  var4 = 3; // Global
  
  function test2(yay, yay1) { 
    return var3;
  }
  function test3(woo, woo1) { 
    return woo1 + var4;
  }
}

// Quote switching
r = "te'st\"in\"g";