/*!
 * sdfsd
*/

var d = new Date();
var                     time = d.getHours();
// comment 1
if (time < 10) {
  document.write("<b>Good morning</b>");
} else {
  /* comment 2 */
  document.write("<b>Good day</b>");
}

test1 = "sdfsdf /*This should not be removed*/";
// This should be removed
test2 = "sdfsdf\" //This should not be removed";

test3 = 'sdfsdf /*This should not be removed*/';
// This should be removed
test4 =             'sdfsdf\' //This should not be removed';

/* this should
// be removed */

/*@if (@_jscript_version >= 5)
  document.write("JScript Version 5.0+.");
  document.write("This should not be removed");
@else @*/

// Example of regular expression
var patt=/(a|my)?string/gim;

var a = b++ + c;

var test = test++      +    test;

function something() {
  var              $test = "Hello World";
  var    $    = "meh";
  return                       $test;
}

alert(12 .toFixed(2));

for (  ;    ;  ) {
  alert("Hello");
}

