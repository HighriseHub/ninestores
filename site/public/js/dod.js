var $busyindicator = document.getElementById('busy-indicator');
var $error = document.getElementById('hhub-error');
var $success = document.getElementById('hhub-success');
var  $formcustsignin = $(".form-custsignin"),  $formvendsignin = $(".form-vendorsignin");
var cartitemscount = 0;
// Create a generic JQuery AJAX function
var ajaxCallParams = {};
var ajaxDataParams = {}; 
var slideindex =1;

const setRangeValue = (event)=>{
    
    const range = event.target;
    const id = event.target.id; 
    const prdrowid = id.substring(id.indexOf("_") + 1);
    const rangeV = document.querySelector('#rangeV_' + prdrowid);
    const
    newValue = Number( (range.value - range.min) * 100 / (range.max - range.min) ),
    newPosition = 10 - (newValue * 0.2);
    rangeV.innerHTML = `<span>${range.value}</span>`;
    rangeV.style.left = `calc(${newValue}% + (${newPosition}px))`;
    };

$(document).ready(function() {
  var $navbar = $("#hhubcustnavbar");
  
  StickyHeader(); // Incase the user loads the page from halfway down (or something);
  $(window).scroll(function() {
      StickyHeader();
  });
    
    function StickyHeader(){
	if ($(window).scrollTop() > 60) {
	    if (!$navbar.hasClass("navbar-fixed-top")) {
		$navbar.addClass("navbar-fixed-top");
	    }
	} else {
	    $navbar.removeClass("navbar-fixed-top");
	}
    }
});


$(document).ready(function(){
    cartitemscount = 0;
    var carouselcontainer = document.getElementById('carousel-container');
    if(carouselcontainer != null){
	//setInterval(performslideshow, 6000);
    }
});

function performslideshow(){
    var linkid, previouslinkid, link, previouslink;; 
    if(slideindex == 6)
    {
	previouslinkid = "#slidelink" + (slideindex -1);
	previouslink = document.querySelector(previouslinkid);
	previouslink.style = "background-color: white;"
	slideindex =1;
    }
    else
    {
	linkid = "#slidelink" + slideindex;
	link = document.querySelector(linkid);
	link.style = "background-color: grey;"
	
	    // We will click the button only if we are in the first 300 pixels
	if ($(window).scrollTop() < 300) {
	    link.click();
	}
	
	if(slideindex > 1){
	    previouslinkid = "#slidelink" + (slideindex -1);
	    previouslink = document.querySelector(previouslinkid);
	    previouslink.style = "background-color: white;"
	}
	slideindex++;
    }
    
}



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

/* This function displays the spinner on every link click. 

$("a").click(function(){
    var href = $(this).prop('href');
    if(href.endsWith("#") == false)
	$busyindicator.appendChild(spinner.el);
});*/

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

function pincodecheck (addressfield, pincodefield, cityfield, statefield, areafield){
    var city = cityfield;
    var pincode = pincodefield.val();
    var state = statefield;
    var localarea = areafield;
    var address = addressfield;
    var addressval = address.val();
    
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
		city.val(data[0].locality + ", " +  data[0].city)
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
        pincodecheck($('#shipaddress'),$('#shipzipcode'),$('#shipcity'), $('#shipstate'), $('#areaname'));
    });
});


$(document).ready(function() {
    $('#cmpzipcode').keyup(function(){
        pincodecheck($('#cmpaddress'),$('#cmpzipcode'), $('#cmpcity'), $('#cmpstate'), $('#areaname'));
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

function togglecheckboxvalueyn(id){
    const checkboxtoggle  = document.getElementById(id);
    if(checkboxtoggle.checked ){
         checkboxtoggle.value = "Y";
    }else
    {
         checkboxtoggle.value = "N";
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
    displaySuccess("#hhub-success","Copied To Clipboard");   
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


function addtocartclick (id){
    event.preventDefault();

    const addtocartbtn = document.querySelector("#"+id);
    const prdrowid = id.substring(id.indexOf("_") + 1);

    const range = document.querySelector('#range_' + prdrowid);
    const rangeV = document.querySelector('#rangeV_' + prdrowid);
    range.addEventListener('input', setRangeValue);

    const
    newValue = Number( (range.value - range.min) * 100 / (range.max - range.min) ),
    newPosition = 10 - (newValue * 0.2);
    rangeV.innerHTML = `<span>${range.value}</span>`;
    rangeV.style.left = `calc(${newValue}% + (${newPosition}px))`;

}


function orderitemeditclick (id){                                                                                                                                              
    event.preventDefault();
    const editorderitembtn = document.querySelector("#"+id);
    const prdrowid = id.substring(id.indexOf("_") + 1);
    const range = document.querySelector('#range_' + prdrowid);
    const rangeV = document.querySelector('#rangeV_' + prdrowid);
    range.addEventListener('input', setRangeValue);
    const
    newValue = Number( (range.value - range.min) * 100 / (range.max - range.min) ),
    newPosition = 10 - (newValue * 0.2);
    rangeV.innerHTML = `<span>${range.value}</span>`;
    rangeV.style.left = `calc(${newValue}% + (${newPosition}px))`;
}


function plusbtnclick (id){
    event.preventDefault();
    const plusbutton = document.querySelector("#"+id);
    const  prdrowid = id.substring(id.indexOf("_") + 1);
    const  elemname = "#prdqtyfor_" + prdrowid; 
    const  prdqtyelem = document.querySelector(elemname);
    prdqtyelem.valueAsNumber++;
}

function minusbtnclick (id){
    event.preventDefault();
    const plusbutton = document.querySelector("#"+id);
    const prdrowid = id.substring(id.indexOf("_") + 1);
    const elemname = "#prdqtyfor_" + prdrowid; 
    const prdqtyelem = document.querySelector(elemname);
    if(prdqtyelem.value == 0) return false; 
    prdqtyelem.valueAsNumber--;
}




function countChar (divid, val, maxchars ) {
    event.preventDefault();
    var charcountdiv = document.getElementById(divid);
    var length = val.value.length; 
    if (length >= maxchars+1){
	val.value = val.value.substring(0, maxchars);
	charcountdiv.textContent = "Length Exceeded beyond - " + maxchars; 
    }else {
	charcountdiv.textContent = maxchars - length;
    }
}



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

//We are using event delegation here. #searchresult is 

/*$(document).ready(function() {
    registerforsubmitformevent ("#hhubmaincontent");
});*/


$(document).ready(function() {
    registerforsubmitformevent ("#prdlivesearchresult");
});


$(document).ready(function() {
    registerforsubmitformevent ("#idsingle-product-card");
});


$(document).ready(function() {
    registerforsubmitformevent ("#idprd-catg-container");
});

$(document).ready(function() {
    registerforsubmitformevent ("#idstdcustcodcontainer");
});


function submitonkeyupevent (event){
    event.preventDefault();
    let tergetform = event.target;
    searchformsubmit(targetform, resultelem); 
}

const registeronkeyupevent = (component, resultelem) => {
    const element = document.querySelector(component);
    if (null != element){
	element.addEventListener('keyup', (e) => {
	    e.preventDefault();
	    let targetform = e.target;
	    searchformsubmit(targetform, resultelem);
	});
    }
};


const registerforsubmitformevent = (component) => {
    const element = document.querySelector(component);
    if (null != element){
	element.addEventListener('submit', (e) => {
	    e.preventDefault();
	    let targetform = e.target;
	    submitformandredirect(targetform);
	});
    }
};


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

function searchformsubmit (theForm, resultdiv){
    $(theForm).find("button[type='submit']").hide();
    ajaxCallParams.Type = "POST";
    ajaxCallParams.Cache = false;
    ajaxCallParams.Url = $(theForm).attr("action");
    ajaxCallParams.DataType = "HTML"; // Return data type e-g Html, Json etc                                                                                                                                    
    ajaxDataParams = $(theForm).serialize();
    ajaxCall(ajaxCallParams, ajaxDataParams, function (data) { 
	console.log("Search Form submitted");
	$(resultdiv).html(data);
    });
}



$(".form-shopcart").on('submit', function (e){
    e.preventDefault();
    var theForm = $(this);
    submitformandredirect (theForm);
});

	

function goBack (){
    window.history.back();
}



function CancelConfirm (){
    return confirm("Do you really want to Cancel?");
}

function DeleteConfirm (){
    return confirm("Do you really want to Delete?");
}




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


function searchformevent(idBindElement, searchresultid) {
    var theForm = event.target.form;
    var element = document.querySelector(idBindElement);
    return element.value.length === 3 ||
	element.value.length === 5 ||
	element.value.length === 8 ||
	element.value.length === 13 ||
	element.value.length === 21 ? searchformsubmit(theForm, searchresultid) : null;
}

