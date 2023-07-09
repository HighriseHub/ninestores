var $busyindicator = document.getElementById('busy-indicator');
var $error = document.getElementById('hhub-error');
var $success = document.getElementById('hhub-success');
var  $formcustsignin = $(".form-custsignin"),  $formvendsignin = $(".form-vendorsignin");
var cartitemscount = 0;
// Create a generic JQuery AJAX function
var ajaxCallParams = {};
var ajaxDataParams = {}; 

$(document).ready(function(){
    cartitemscount = 0;
});


function countdowntimer (days, hours, minutes, seconds){ 
    // Set the date we're counting down to
    var countDownDate =  new Date().getTime(); 
    if (days > 0 ){
	countDownDate = countDownDate + 1000 * 60 * 60 * 24 * days;
    } 
    if (hours > 0) {
	countDownDate = countDownDate + 1000 * 60 * 60 * hours;
    }
    if (minutes > 0) {
	countDownDate += 1000 * 60 *  minutes; 
    }
    if (seconds > 0) {
	countDownDate += 1000 *  seconds ; 
    }
    // Update the count down every 1 second
    var x = setInterval(function() {
	// Get today's date and time
	var now = new Date().getTime();
	
	// Find the distance between now and the count down date
	var distance = countDownDate - now;
	
	// Time calculations for days, hours, minutes and seconds
	var days = Math.floor(distance / (1000 * 60 * 60 * 24));
	var hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
	var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
	var seconds = Math.floor((distance % (1000 * 60)) / 1000);
	
	// Output the result in an element with id="demo"
	if (days > 0 && hours >0){ 
	document.getElementById("withCountDownTimer").innerHTML = days + "d " + hours + "h "
		+ minutes + "m " + seconds + "s ";
	}
	else{
	    document.getElementById("withCountDownTimer").innerHTML =  minutes + "m " + seconds + "s ";
	}
	
	// If the count down is over, write some text 
	if (distance < 0) {
	    clearInterval(x);
	    document.getElementById("withCountDownTimerExpired").innerHTML = "SESSION EXPIRED";
	}
    }, 1000);
}

// General function for all ajax calls
function ajaxCall(callParams, dataParams, callback) {   
    $.ajax({
        type: callParams.Type,
        url: callParams.Url,
        quietMillis: 100,
        dataType: callParams.DataType,
        data: dataParams,
        cache: true,
	beforeSend: function(){
    	    $busyindicator.appendChild(spinner.el);
	},
	complete: function(){
   	    $busyindicator.removeChild(spinner.el);
	},
	success:function (response) {
            callback(response);
        },
        error: function (jqXHR, textStatus, errorThrown) {
            if (jqXHR.status > 400){
		displayError("#hhub-error", jqXHR.responseText);
		console.log("HTTP Error Code" + jqXHR.status);
		console.log("Error Status: "+ textStatus);
		console.log("Error Thrown: "+ errorThrown);
	    }}
    });
}


$(document).ready(function () {
    $.ajaxSetup({
    	beforeSend: function(){
    	    $busyindicator.appendChild(spinner.el);
	},
	complete: function(){
   	    $busyindicator.removeChild(spinner.el);
	}
    });
});

function goback (){
    window.onpageshow = function(event) {
	if (event.persisted) {
	    window.location.reload()
	}
    };
}

function pincodecheck (pincodefield, cityfield, statefield, areafield){
    var city = cityfield;
    var pincode = pincodefield.val();
    var state = statefield;
    var localarea = areafield;
    
    if (pincode.length  == 6){
	ajaxCallParams.Type = "GET"; 
	ajaxCallParams.Url = "/hhub/hhubpincodecheck";
	ajaxCallParams.DataType = "JSON"; // Return data type e-g Html, Json etc
	
	// Set Data parameters
	ajaxDataParams.pincode = pincode; 
        
	// Passing call and data parameters to general Ajax function
	ajaxCall(ajaxCallParams, ajaxDataParams, function (retdata) {
	   
	    if(retdata['success'] != 0){
		console.log(retdata);
		var data = retdata['result'];
		city.val(data[0].city);
		state.val(data[0].state);
		localarea.text(data[0].locality);
	    }
	    else
	    {
		city.val("");
		state.val("");
		localarea.text("");
	    }
		
	});
    }

}

$(document).ready(function() {
    $('#shipzipcode').keyup(function(){
        pincodecheck($('#shipzipcode'),$('#shipcity'), $('#shipstate'), $('#areaname'));
    });
});


$(document).ready(function() {
    $('#cmpzipcode').keyup(function(){
        pincodecheck($('#cmpzipcode'), $('#cmpcity'), $('#cmpstate'), $('#areaname'));
    });
});



/*$pricingform.submit(function(e){
    var theForm = $(this);
    $(theForm).find("button[type='submit']").hide();
    ajaxCallParams.Type = "POST"; // POST type function 
    ajaxCallParams.Url = $(theForm).attr("action"); // Pass Complete end point Url e-g Payment Controller, Create Action
    ajaxCallParams.DataType = "HTML"; // Return data type e-g Html, Json etc
    
    // Set Data parameters
    ajaxDataParams = $(theForm).serialize();
    
    // Passing call and data parameters to general Ajax function
    ajaxCall(ajaxCallParams, ajaxDataParams, function (result) {
	window.location.replace("/hhub/hhubnewcompreqemailsent");
	displaySuccess("#hhub-success",result);
    });
    e.preventDefault();
});
*/



function displaybillingaddress (){
    if( document.getElementById('billsameasshipchecked').checked ){
	$('#billingaddressrow').hide();
	clearbilltoaddress();
    }else
    {
	//copyshiptobillto();
	$('#billingaddressrow').show();
    }
}

function displaygstdetails () {
    if( document.getElementById('claimitcchecked').checked ){
	$('#gstdetailsfororder').show();
    }else
    {
	$('#gstdetailsfororder').hide();
    }

}


function clearbilltoaddress(){
    var billaddress = document.getElementById("billaddress");
    var billzipcode = document.getElementById("billzipcode");
    var billcity = document.getElementById("billcity");
    var billstate = document.getElementById("billstate");
    billaddress.value = "";
    billzipcode.value = "";
    billcity.value = "";
    billstate.value = ""; 
}


function copyshiptobillto()
{
    var shipaddress  = document.getElementById("shipaddress");
    var billaddress = document.getElementById("billaddress");
    var shipzipcode = document.getElementById("shipzipcode");
    var billzipcode = document.getElementById("billzipcode");
    var shipcity = document.getElementById("shipcity");
    var billcity = document.getElementById("billcity");
    var shipstate = document.getElementById("shipstate");
    var billstate = document.getElementById("billstate");
    
    billaddress.value = shipaddress.value;
    billzipcode.value = shipzipcode.value;
    billcity.value = shipcity.value;
    billstate.value = shipstate.value;
    
}


$( ":text" ).each(function( index ) {
    $( this ).focusout(function() {
      var text = $(this).val();
      text = $.trim(text);
      $(this).val(text);
    });
});



function fallbackCopyTextToClipboard(text) {
  var textArea = document.createElement("textarea");
  textArea.value = text;
  
  // Avoid scrolling to bottom
  textArea.style.top = "0";
  textArea.style.left = "0";
  textArea.style.position = "fixed";

  document.body.appendChild(textArea);
  textArea.focus();
  textArea.select();

  try {
    var successful = document.execCommand('copy');
    var msg = successful ? 'successful' : 'unsuccessful';
    console.log('Fallback: Copying text command was ' + msg);
  } catch (err) {
    console.error('Fallback: Oops, unable to copy', err);
  }

  document.body.removeChild(textArea);
}


const copyToClipboard = text => {
  if (!navigator.clipboard) {
    fallbackCopyTextToClipboard(text);
    return;
  }
  navigator.clipboard.writeText(text).then(function() {
    console.log('Async: Copying to clipboard was successful!');
  }, function(err) {
    console.error('Async: Could not copy text: ', err);
  });
}





function getCookie(k)
{
    var v=document.cookie.match('(^|;) ?'+k+'=([^;]*)(;|$)');
    return v?v[2]:null
}



$(document).ready(function(){
    $busyindicator.removeChild(spinner.el);
});


$(document).ready(function() {
        $('[data-toggle="tooltip"]').tooltip({'placement': 'top'});
});


function plusbtnclick (id){
    var plusbutton = document.getElementById(id);
    var prdrowid = id.substring(id.indexOf("_") + 1);
    var elemname = "prdqtyfor_" + prdrowid; 
    var prdqtyelem = document.getElementById(elemname);
    prdqtyelem.value = parseInt(prdqtyelem.value) + 1; 
}

function minusbtnclick (id){
    var plusbutton = document.getElementById(id);
    var prdrowid = id.substring(id.indexOf("_") + 1);
    var elemname = "prdqtyfor_" + prdrowid; 
    var prdqtyelem = document.getElementById(elemname);
    if(prdqtyelem.value == 0) return false; 
    prdqtyelem.value = parseInt(prdqtyelem.value) - 1; 
}


$(document).ready (function(){
    $('.prdaddbtn').on('click',function(){
	$('.input-quantity').val(1);
    }); 
});

function countChar(val, maxchars){
var length = val.value.length; 
    if (length >= maxchars){
	val.value = val.value.substring(0, maxchars); 
    }else {
	$('#charcount').text (maxchars - length)
	}
}; 



$formcustsignin.submit ( function() {
    $formcustsignin.hide();
    $.ajax({
	type: "POST",
	url: $formcustsignin.attr("action"),
	data: $formscustignin.serialize(),
	error:function(){
	$error.show();
	},
   	success: function(response){
	    console.log("Customer Signin successful");
	    window.location = "/dodcustindex"; 
	    location.reload(); 

	}
    })
    return false;
    
})

$(document).ready(
    
    function() {
        $( "#required-on" ).datepicker({dateFormat: "dd/mm/yy", minDate: 1} ).attr("readonly", "true");
        }
);



$formvendsignin.submit ( function() {
    $formvendsignin.hide();
    $.ajax({
	type: "POST",
	url: $formsignin.attr("action"),
	data: $formvendsignin.serialize(),
	error:function(){
	$error.show();
	},
   	success: function(response){
	    console.log("Vendor Signin successful");
	    window.location = "/dodvendindex";  
	    location.reload(); 

	}
    })
    return false;
    
})

function displayError(elem, message, timeout) {
     $(elem).show().html('<div class="alert alert-danger alert-dismissible"><button type="button" class="closebtn" data-dismiss="alert" aria-hidden="true"><span aria-hidden="true">&times;</span></button><strong class="text-primary">Warning!&nbsp;&nbsp;</strong><span class="text-primary">'+message+'</span></div>');
    if (timeout || timeout === 0) {
    setTimeout(function() { 
      $(elem).alert('close');
    }, timeout);    
  }
};

function displaySuccess(elem, message, timeout) {
    $(elem).show().html('<div class="alert alert-success alert-dismissible"><button type="button" class="closebtn" data-dismiss="alert" aria-hidden="true"><span aria-hidden="true">&times;</span></button><strong class="text-primary">Success!&nbsp;&nbsp;</strong><span class="text-primary">'+message+'</span></div>');
    if (timeout || timeout === 0) {
    setTimeout(function() { 
	$(elem).alert('close');
	$(elem).hide();
	
    }, timeout);    
  }
};


$(".form-vendordercomplete").on('submit', function (e) {
    var theForm = $(this);
    $(theForm).find("button[type='submit']").hide(); //prop('disabled',true);
      $.ajax({
            type: 'POST',
          url: $(theForm).attr("action"), 
            data: $(theForm).serialize(),
	  error: function (jqXHR, textStatus, errorThrown) {
                  if (jqXHR.status == 500) {
		      displayError("#hhub-error", jqXHR.responseText);
		  }
	      else{
                      alert('Unexpected error.');
                  }},
	  success: function (response) {
		console.log("Completing the Order "); 
		location.reload();
            }
      });
      e.preventDefault();});

$(".form-addproduct").on('submit', function (e) {
    // Stop form from submitting normally
    e.preventDefault();
    var theForm = $(this);
    
    $(theForm).find("button[type='submit']").hide();
    ajaxCallParams.Type = "POST";
    ajaxCallParams.Url = $(theForm).attr("action");
    ajaxCallParams.DataType = "HTML"; // Return data type e-g Html, Json etc                                                                                                                                    
    ajaxDataParams = $(theForm).serialize();
    ajaxCall(ajaxCallParams, ajaxDataParams, function (data) { 
	console.log("Added product to cart");
	cartitemscount++;
	location.reload();});
});

$(".placeorderform").on('submit', function (e){
    e.preventDefault();
    var theForm = $(this);
    submitformandredirect(theForm);
});

function submitformandredirect (theForm){
    $(theForm).find("button[type='submit']").hide();
    ajaxCallParams.Type = "POST";
    ajaxCallParams.Url = $(theForm).attr("action");
    ajaxCallParams.DataType = "HTML"; // Return data type e-g Html, Json etc                                                                                                                                    
    ajaxDataParams = $(theForm).serialize();
    ajaxCall(ajaxCallParams, ajaxDataParams, function (data) { 
	console.log("Form submitted");
	location.replace(data);});
}


$(".form-shopcart").on('submit', function (e) {
    var theForm = $(this);
    $(theForm).find("button[type='submit']").hide(); //prop('disabled',true);
      $.ajax({
            type: 'POST',
          url: $(theForm).attr("action"), 
            data: $(theForm).serialize(),
            success: function (response) {
		console.log("Updated shopping cart");
		location.reload();

            }
      });
      e.preventDefault();});	
	

function goBack (){
    window.history.back();
}



function CancelConfirm (){
    return confirm("Do you really want to Cancel?");
}

function DeleteConfirm (){
    return confirm("Do you really want to Delete?");
}





$(document).ready(function(){
    $("#livesearch").keyup(function(){
	if (($("#livesearch").val().length ==3) || 
	    ($("#livesearch").val().length == 5)||
	    ($("#livesearch").val().length == 8)||
	    ($("#livesearch").val().length == 13)||
	    ($("#livesearch").val().length == 21)){
	    $.ajax({
		type: "post", 
		cache: false,
		url: $(theForm).attr("action"), 
		data: $(theForm).serialize(),
		success: function(response){
		  
		   //document.getElementById("livesearch").innerHTML=this.responseText;
		//document.getElementById("livesearch").style.border="1px solid #A5ACB2";
			$("#searchresult").html(response); 
		//	$("#finalResult").style.border = "1px solid #a5acb2";
		}, 
		error: function(){      
		    alert('Error while request..');
		}
	    });
	}
	return  false;
    });
});
	


$(document).ready (function(){
    var btn = $('#scrollup');
    
    $(window).scroll(function() {
	if ($(window).scrollTop() > 300) {
	    btn.addClass('show');
	} else {
	    btn.removeClass('show');
	}
    });
    
    btn.on('click', function(e) {
	e.preventDefault();
	$('html, body').animate({scrollTop:0}, '300');
    });
}); 

$(document).ready (function(){
    var floatingbtn = $('#floatingcheckoutbutton');
    
    $(window).scroll(function() {
	if ($(window).scrollTop() > 300) {
	    floatingbtn.addClass('show');
	} else {
	    floatingbtn.removeClass('show');
	}
    });
    
    floatingbtn.on('click', function(e) {
	//e.preventDefault();
	//$('html, body').animate({scrollTop:0}, '300');
    });
}); 
