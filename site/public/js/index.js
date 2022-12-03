var availableDates = []; 


$(document).ready( function(){
    $.ajax({
        type: 'POST',
        url: "/hhub/dodmyorders", 
        data: "",
        success: function (response) {
	    availableDates = response; 
	   
        }
      });
});	


$(document).ready(function() {

  $(".datepicker").datepicker({
    prevText: '<i class="fa fa-fw fa-angle-left"></i>',
    nextText: '<i class="fa fa-fw fa-angle-right"></i>'
  });
});

$(document).ajaxComplete(function() {
   $('.datepicker').datepicker(); // setup picker here...
});

$(document).ready(function () {
$(".datepicker").datepicker({
    prevText: '<i class="fa fa-fw fa-angle-left"></i>',
    nextText: '<i class="fa fa-fw fa-angle-right"></i>',
    dateFormat: 'dd/mm/yy',
    minDate: new Date(), 
    beforeShowDay: function(d) {
        var dmy =""; 
	
	if(d.getDate()<10) 
	    dmy+="0"; 
            dmy+=d.getDate() + "/";
	
	if(d.getMonth()<9) 
            dmy= dmy + "0"; 
        dmy = dmy + (d.getMonth()+1); 
	dmy+= "/" + d.getFullYear();

        console.log(dmy + ' : '+($.inArray(dmy, availableDates)));

        if ($.inArray(dmy, availableDates) != -1) {
            return [true, "css-class-to-highlight","Available"]; 
        } else{
             return [false,"","unAvailable"]; 
        }
    }
    });
});

$(document).ready(function() {
$(".datepicker2")
    .datepicker({
      dateFormat: "dd/mm/yyyy",
      onSelect: function(dateText) {
        $(this).change();
      },

	beforeShowDay: function(date) {
      // check if date is in your array of dates
	    console.log("inside beforeshowday function");
	    if($.inArray(date, your_dates)) {
         // if it is return the following.
         return [true, 'css-class-to-highlight', 'tooltip text'];
      } else {
         // default
         return [true, '', ''];
      }
   }
	
    })
    .change(function() {
      window.location.href = "index.php?date=" + this.value;
    });
});


