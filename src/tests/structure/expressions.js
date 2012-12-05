// Assignment
var a = 10;

a = 10;

var a;

a;

var a = 10, b = 20, c = 30;

// Assignment operators
a *= 10;

a /= 10;

a %= 10;

a += 10;

a -= 1;

// Conditional expressions
var age = 10;
var a = (age >= 18) ? "adult" : "minor";

// New expression
var a = new Object();

// Call expression
var a = { get: function() {}};
a.get();

var x = a[0];

// Primary expressions

// Literals
var a = true;
var b = false;
var c = null;
var d = 10;
var e = 0xFF;
var f = 0X11;
var g = 044;
var h = 55.789;
var i = .123;
var j = .5e-45;

var k = "test string";

var l = a;

function testThis() {
  var a = this.a;
}

var re = /ab+c/;

var re = new RegExp("ab+c");

var a = "Hello World";
a.replace(/[?|^&(){}\[\]+\-*\/\.]/g, "\\$&");

var coffees = ["French Roast", "Colombian", "Kona"];

//var fish = ["Lion", , "Angel"];

var car = { myCar: "Saturn", getCar: "Honda" };

// Logical operators
var a = true || false;

var b = a && b;

var c = a | b;

var d = a ^ b;

var e = a & b;

// Equality operators
if (a == b) ;

if (a != b) ;

if (a === b) ;

if (a !== b) ;

// Relational operators
if (a < b) ;

if (a > b) ;

if (a <= b) ;

if (a >= b) ;

if (a instanceof String) ;

if (a in car) ;

// Shift operators
x = 9<<2;

x = 9>>2;

x = 9>>>2;

// Additive operators
x = 1 + 2;

x = 2 - 1;

// Multiplicative operators
x = a * b;

x = a / b;

x = a % b;
 
// Unary operators
delete a;

void a;

var b = typeof a;

var b = ++a;

var b = --a;

var b = +a;

var b = -a;

var b = !a;

var b = ~a;

// Post fix
a++;

a--;