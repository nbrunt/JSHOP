// This should be removed
var a = "This // should not be removed.";

/* This should
   be removed */
var b = "This /* should not be removed */";

/*@if (@_jscript_version >= 5)
  document.write("JScript Version 5.0+.");
  document.write("This should not be removed");
@else @*/

var a1 = b++ + c;

var                     time = d.getHours();